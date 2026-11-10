import Foundation
@preconcurrency import CoreBluetooth

@MainActor
final class MantabrewScaleDriver: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
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

    private static let serviceUUID = CBUUID(string: "FFF0")
    private static let commandCharacteristicUUID = CBUUID(string: "FFF1")
    private static let weightCharacteristicUUID = CBUUID(string: "FFF4")

    private var centralManager: CBCentralManager?
    private var peripheralsByID: [String: CBPeripheral] = [:]
    private var devicesByID: [String: Device] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private var scanTask: Task<Void, Never>?
    private var shouldStartScanning = false
    private var failureDisconnectID: UUID?

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
            onError?("The MANTABREW scale is no longer available. Scan again.")
            return
        }
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        onConnecting?(devicesByID[id]?.name ?? "MANTABREW WeighMaster 2.0")
        centralManager.connect(peripheral)
    }

    func disconnect() {
        guard let connectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(connectedPeripheral)
    }

    func tare() {
        sendCommand([0x02])
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.sendCommand([0x05, 0x00])
        }
        onWeightChanged?(0)
    }

    func startTimer() {
        sendCommand([0x52, 0x0B, 0x01, 0x00, 0x00, 0x00, 0x00])
    }

    func pauseTimer() {
        sendCommand([0x52, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00])
    }

    func stopTimer() {
        sendCommand([0x52, 0x0B, 0x02, 0x00, 0x00, 0x00, 0x00])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            beginScanningIfReady()
        case .poweredOff:
            reportBluetoothUnavailable("Bluetooth is off. Turn it on to connect MANTABREW.")
        case .unauthorized:
            reportBluetoothUnavailable("Bluetooth access is required to connect MANTABREW.")
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
        let rawName = advertisedName ?? peripheral.name ?? ""
        let normalizedName = rawName.lowercased()
        guard normalizedName.contains("weighmaster") || normalizedName.contains("mantabrew") else { return }

        let id = peripheral.identifier.uuidString
        peripheralsByID[id] = peripheral
        devicesByID[id] = Device(
            id: id,
            name: displayName(for: rawName),
            modelName: "MANTABREW WeighMaster 2.0"
        )
        onDevicesChanged?(sortedDevices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        clearConnection()
        onError?(error?.localizedDescription ?? "Could not connect to MANTABREW.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if failureDisconnectID == peripheral.identifier {
            failureDisconnectID = nil
            clearConnection()
            return
        }
        clearConnection()
        if let error {
            onError?("MANTABREW disconnected: \(error.localizedDescription)")
        } else {
            onDisconnected?()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            failConnection("Could not read MANTABREW services: \(error.localizedDescription)")
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            failConnection("This device does not expose the supported WeighMaster 2.0 service.")
            return
        }
        peripheral.discoverCharacteristics(
            [Self.commandCharacteristicUUID, Self.weightCharacteristicUUID],
            for: service
        )
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            failConnection("Could not read MANTABREW controls: \(error.localizedDescription)")
            return
        }
        let characteristics = service.characteristics ?? []
        guard
            let command = characteristics.first(where: { $0.uuid == Self.commandCharacteristicUUID }),
            let weight = characteristics.first(where: { $0.uuid == Self.weightCharacteristicUUID })
        else {
            failConnection("This MANTABREW scale uses an unsupported Bluetooth profile.")
            return
        }

        commandCharacteristic = command
        peripheral.setNotifyValue(true, for: weight)
        let name = devicesByID[peripheral.identifier.uuidString]?.name ?? displayName(for: peripheral.name ?? "")
        onConnected?(name)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, characteristic.uuid == Self.weightCharacteristicUUID,
              let data = characteristic.value else { return }
        parseWeight(data)
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

    private func parseWeight(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 7, bytes[0] == 0x01, bytes[1] == 0x02 else { return }

        let isNegative = (bytes[3] & 0x10) != 0
        let rawWeight = (Int(bytes[4]) << 16) | (Int(bytes[5]) << 8) | Int(bytes[6])
        let weightGrams = Double(isNegative ? -rawWeight : rawWeight) / 10
        onWeightChanged?(weightGrams)
    }

    private func sendCommand(_ bytes: [UInt8]) {
        guard let connectedPeripheral, let commandCharacteristic else { return }
        let writeType: CBCharacteristicWriteType = commandCharacteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        connectedPeripheral.writeValue(Data(bytes), for: commandCharacteristic, type: writeType)
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
        commandCharacteristic = nil
    }

    private func displayName(for rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "MANTABREW WeighMaster 2.0" : name
    }
}
