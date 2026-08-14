import Foundation
@preconcurrency import CoreBluetooth

@MainActor
final class GinaScaleDriver: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
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

    private static let scaleServiceUUID = CBUUID(string: "91341521-BAC2-42D9-BBB3-942F7A10976C")
    private static let weightCharacteristicUUID = CBUUID(string: "91341522-BAC2-42D9-BBB3-942F7A10976C")

    private var centralManager: CBCentralManager?
    private var peripheralsByID: [String: CBPeripheral] = [:]
    private var devicesByID: [String: Device] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var scanTask: Task<Void, Never>?
    private var shouldStartScanning = false
    private var failureDisconnectID: UUID?
    private var latestRawWeightGrams = 0.0
    private var tareOffsetGrams: Double?

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
            onError?("GINA is no longer available. Scan again.")
            return
        }
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        let name = devicesByID[id]?.name ?? displayName(for: peripheral.name)
        onConnecting?(name)
        centralManager.connect(peripheral)
    }

    func disconnect() {
        guard let connectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(connectedPeripheral)
    }

    func tare() {
        tareOffsetGrams = latestRawWeightGrams
        onWeightChanged?(0)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            beginScanningIfReady()
        case .poweredOff:
            reportBluetoothUnavailable("Bluetooth is off. Turn it on to connect GINA.")
        case .unauthorized:
            reportBluetoothUnavailable("Bluetooth access is required to connect GINA.")
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
        let id = peripheral.identifier.uuidString
        let name = displayName(for: advertisedName ?? peripheral.name)
        peripheralsByID[id] = peripheral
        devicesByID[id] = Device(id: id, name: name, modelName: "GOAT STORY GINA")
        onDevicesChanged?(sortedDevices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        tareOffsetGrams = nil
        latestRawWeightGrams = 0
        peripheral.discoverServices([Self.scaleServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        clearConnection()
        onError?(error?.localizedDescription ?? "Could not connect to GINA.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if failureDisconnectID == peripheral.identifier {
            failureDisconnectID = nil
            clearConnection()
            return
        }
        clearConnection()
        if let error {
            onError?("GINA disconnected: \(error.localizedDescription)")
        } else {
            onDisconnected?()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            failConnection("Could not read GINA services: \(error.localizedDescription)")
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.scaleServiceUUID }) else {
            failConnection("This device does not expose the supported GINA scale service.")
            return
        }
        peripheral.discoverCharacteristics([Self.weightCharacteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            failConnection("Could not read GINA scale data: \(error.localizedDescription)")
            return
        }
        guard let weight = service.characteristics?.first(where: { $0.uuid == Self.weightCharacteristicUUID }) else {
            failConnection("This GINA uses an unsupported Bluetooth profile.")
            return
        }

        peripheral.setNotifyValue(true, for: weight)
        let id = peripheral.identifier.uuidString
        let name = devicesByID[id]?.name ?? displayName(for: peripheral.name)
        onConnected?(name)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, characteristic.uuid == Self.weightCharacteristicUUID,
              let data = characteristic.value, data.count >= 4 else { return }

        let rawTenths = data.withUnsafeBytes { bytes in
            UInt32(littleEndian: bytes.loadUnaligned(as: UInt32.self))
        }
        latestRawWeightGrams = Double(rawTenths) / 10

        if tareOffsetGrams == nil {
            tareOffsetGrams = latestRawWeightGrams
        }
        onWeightChanged?(latestRawWeightGrams - (tareOffsetGrams ?? 0))
    }

    private var sortedDevices: [Device] {
        devicesByID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func beginScanningIfReady() {
        guard shouldStartScanning, let centralManager, centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: [Self.scaleServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
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
        latestRawWeightGrams = 0
        tareOffsetGrams = nil
    }

    private func displayName(for rawName: String?) -> String {
        let name = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return "GOAT STORY GINA" }
        return name.localizedCaseInsensitiveContains("gina") ? name : "GINA \(name)"
    }
}
