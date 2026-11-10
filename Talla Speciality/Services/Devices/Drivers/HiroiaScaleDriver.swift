import Foundation
@preconcurrency import CoreBluetooth

@MainActor
final class HiroiaScaleDriver: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
    struct Device: Equatable {
        let id: String
        let name: String
        let modelName: String
    }

    var onDevicesChanged: (([Device]) -> Void)?
    var onConnecting: ((String) -> Void)?
    var onConnected: ((String) -> Void)?
    var onDisconnected: (() -> Void)?
    var onError: ((String) -> Void)?
    var onWeightChanged: ((Double) -> Void)?

    private static let serviceUUID = CBUUID(string: "06C31822-8682-4744-9211-FEBC93E3BECE")
    private static let writeCharacteristicUUID = CBUUID(string: "06C31823-8682-4744-9211-FEBC93E3BECE")
    private static let readCharacteristicUUID = CBUUID(string: "06C31824-8682-4744-9211-FEBC93E3BECE")

    private var centralManager: CBCentralManager?
    private var peripheralsByID: [String: CBPeripheral] = [:]
    private var devicesByID: [String: Device] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var scanTask: Task<Void, Never>?
    private var shouldStartScanning = false
    private var failureDisconnectID: UUID?
    private var unitCommandPending = false
    private var modeCommandPending = false

    deinit {
        scanTask?.cancel()
    }

    func scan(duration: TimeInterval = 5) {
        scanTask?.cancel()
        devicesByID = [:]
        peripheralsByID = [:]
        onDevicesChanged?([])
        shouldStartScanning = true

        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: .main)
        } else {
            beginScanningIfReady()
        }

        scanTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.stopScanning()
        }
    }

    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        shouldStartScanning = false
        centralManager?.stopScan()
    }

    func connect(to id: String) {
        guard let peripheral = peripheralsByID[id], let centralManager else {
            onError?("The HIROIA JIMMY scale is no longer available. Scan again.")
            return
        }
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        onConnecting?(devicesByID[id]?.name ?? "HIROIA JIMMY")
        centralManager.connect(peripheral)
    }

    func disconnect() {
        guard let connectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(connectedPeripheral)
    }

    func tare() {
        sendCommand([0x07, 0x00])
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            self?.sendCommand([0x07, 0x00])
        }
        onWeightChanged?(0)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            beginScanningIfReady()
        case .poweredOff:
            reportBluetoothUnavailable("Bluetooth is off. Turn it on to connect HIROIA JIMMY.")
        case .unauthorized:
            reportBluetoothUnavailable("Bluetooth access is required to connect HIROIA JIMMY.")
        case .unsupported:
            reportBluetoothUnavailable("This device does not support Bluetooth Low Energy.")
        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? ""
        let advertisedServices = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        guard name.lowercased().hasPrefix("hiroia") || advertisedServices.contains(Self.serviceUUID) else { return }

        let id = peripheral.identifier.uuidString
        peripheralsByID[id] = peripheral
        devicesByID[id] = Device(id: id, name: displayName(for: name), modelName: "HIROIA JIMMY")
        onDevicesChanged?(sortedDevices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        unitCommandPending = false
        modeCommandPending = false
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        clearConnection()
        onError?(error?.localizedDescription ?? "Could not connect to HIROIA JIMMY.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if failureDisconnectID == peripheral.identifier {
            failureDisconnectID = nil
            clearConnection()
            return
        }
        clearConnection()
        if let error {
            onError?("HIROIA JIMMY disconnected: \(error.localizedDescription)")
        } else {
            onDisconnected?()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            failConnection("Could not read HIROIA JIMMY services: \(error.localizedDescription)")
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            failConnection("This HIROIA device does not expose the supported JIMMY scale service.")
            return
        }
        peripheral.discoverCharacteristics(
            [Self.writeCharacteristicUUID, Self.readCharacteristicUUID],
            for: service
        )
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            failConnection("Could not read HIROIA JIMMY controls: \(error.localizedDescription)")
            return
        }
        let characteristics = service.characteristics ?? []
        guard
            let write = characteristics.first(where: { $0.uuid == Self.writeCharacteristicUUID }),
            let read = characteristics.first(where: { $0.uuid == Self.readCharacteristicUUID })
        else {
            failConnection("This HIROIA JIMMY uses an unsupported Bluetooth profile.")
            return
        }

        writeCharacteristic = write
        peripheral.setNotifyValue(true, for: read)
        let name = devicesByID[peripheral.identifier.uuidString]?.name ?? displayName(for: peripheral.name ?? "")
        onConnected?(name)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, characteristic.uuid == Self.readCharacteristicUUID,
              let data = characteristic.value else { return }
        parseStatus(data)
    }

    private var sortedDevices: [Device] {
        devicesByID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func beginScanningIfReady() {
        guard shouldStartScanning, let centralManager, centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    private func parseStatus(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 7 else { return }

        let rawMode = Int(bytes[0])
        let isOunce = rawMode > 0x08
        let mode = isOunce ? rawMode - 0x08 : rawMode
        var rawWeight = (Int(bytes[5]) << 8) | Int(bytes[4])
        if bytes[6] == 0xFF {
            rawWeight = -(65_536 - rawWeight)
        }

        let weightGrams = isOunce
            ? (Double(rawWeight) / 1_000) * 28.349_523_125
            : Double(rawWeight) / 10
        onWeightChanged?(weightGrams)

        if isOunce, !unitCommandPending {
            unitCommandPending = true
            sendCommand([0x0B, 0x00])
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(300))
                self?.unitCommandPending = false
            }
        }
        if mode != 0x01, !modeCommandPending {
            modeCommandPending = true
            sendCommand([0x04, 0x00])
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(300))
                self?.modeCommandPending = false
            }
        }
    }

    private func sendCommand(_ bytes: [UInt8]) {
        guard let connectedPeripheral, let writeCharacteristic else { return }
        let writeType: CBCharacteristicWriteType = writeCharacteristic.properties.contains(.write)
            ? .withResponse
            : .withoutResponse
        connectedPeripheral.writeValue(Data(bytes), for: writeCharacteristic, type: writeType)
    }

    private func failConnection(_ message: String) {
        if let connectedPeripheral {
            failureDisconnectID = connectedPeripheral.identifier
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
        }
        clearConnection()
        onError?(message)
    }

    private func reportBluetoothUnavailable(_ message: String) {
        stopScanning()
        onError?(message)
    }

    private func clearConnection() {
        connectedPeripheral = nil
        writeCharacteristic = nil
        unitCommandPending = false
        modeCommandPending = false
    }

    private func displayName(for rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "HIROIA JIMMY" }
        if name.localizedCaseInsensitiveContains("jimmy") { return name }
        return "HIROIA JIMMY"
    }
}
