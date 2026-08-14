import Foundation
@preconcurrency import CoreBluetooth

@MainActor
final class BookooScaleDriver: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
    struct Device: Equatable {
        let id: String
        let name: String
        let modelName: String
    }

    var onDevicesChanged: (([Device]) -> Void)?
    var onScanFinished: (() -> Void)?
    var onConnecting: ((String) -> Void)?
    var onConnected: ((String) -> Void)?
    var onDisconnected: (() -> Void)?
    var onError: ((String) -> Void)?
    var onTelemetry: ((_ weightGrams: Double, _ flowGramsPerSecond: Double, _ timerSeconds: Int) -> Void)?

    private static let serviceUUID = CBUUID(string: "0FFE")
    private static let weightCharacteristicUUID = CBUUID(string: "FF11")
    private static let commandCharacteristicUUID = CBUUID(string: "FF12")

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
            self?.finishScanning()
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
            onError?("The BOOKOO scale is no longer available. Scan again.")
            return
        }
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        onConnecting?(devicesByID[id]?.name ?? peripheral.name ?? "BOOKOO Scale")
        centralManager.connect(peripheral)
    }

    func disconnect() {
        guard let connectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(connectedPeripheral)
    }

    func tare() {
        sendCommand(0x01)
    }

    func startTimer() {
        sendCommand(0x04)
    }

    func pauseTimer() {
        sendCommand(0x05)
    }

    func stopTimer() {
        sendCommand(0x05)
        sendCommand(0x06)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            beginScanningIfReady()
        case .poweredOff:
            reportBluetoothUnavailable("Bluetooth is off. Turn it on to connect a BOOKOO scale.")
        case .unauthorized:
            reportBluetoothUnavailable("Bluetooth access is required to connect a BOOKOO scale.")
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
        guard let rawName = advertisedName ?? peripheral.name else { return }
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isBookooScaleName(name) else { return }

        let id = peripheral.identifier.uuidString
        peripheralsByID[id] = peripheral
        devicesByID[id] = Device(id: id, name: name, modelName: modelName(for: name))
        onDevicesChanged?(sortedDevices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        clearConnection()
        onError?(error?.localizedDescription ?? "Could not connect to the BOOKOO scale.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if failureDisconnectID == peripheral.identifier {
            failureDisconnectID = nil
            clearConnection()
            return
        }
        clearConnection()
        if let error {
            onError?("BOOKOO disconnected: \(error.localizedDescription)")
        } else {
            onDisconnected?()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            failConnection("Could not read BOOKOO services: \(error.localizedDescription)")
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            failConnection("This BOOKOO device does not expose the supported scale service.")
            return
        }
        peripheral.discoverCharacteristics(
            [Self.weightCharacteristicUUID, Self.commandCharacteristicUUID],
            for: service
        )
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            failConnection("Could not read BOOKOO scale controls: \(error.localizedDescription)")
            return
        }

        let characteristics = service.characteristics ?? []
        guard
            let weight = characteristics.first(where: { $0.uuid == Self.weightCharacteristicUUID }),
            let command = characteristics.first(where: { $0.uuid == Self.commandCharacteristicUUID })
        else {
            failConnection("This BOOKOO scale uses an unsupported Bluetooth profile.")
            return
        }

        commandCharacteristic = command
        peripheral.setNotifyValue(true, for: weight)
        let name = devicesByID[peripheral.identifier.uuidString]?.name ?? peripheral.name ?? "BOOKOO Scale"
        onConnected?(name)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, characteristic.uuid == Self.weightCharacteristicUUID,
              let data = characteristic.value else { return }
        parseTelemetry(data)
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

    private func finishScanning() {
        scanTask = nil
        shouldStartScanning = false
        centralManager?.stopScan()
        onScanFinished?()
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

    private func sendCommand(_ command: UInt8) {
        guard let connectedPeripheral, let commandCharacteristic else { return }
        var bytes: [UInt8] = [0x03, 0x0A, command, 0x00, 0x00]
        bytes.append(bytes.reduce(0, ^))
        let writeType: CBCharacteristicWriteType = commandCharacteristic.properties.contains(.write)
            ? .withResponse
            : .withoutResponse
        connectedPeripheral.writeValue(Data(bytes), for: commandCharacteristic, type: writeType)
    }

    private func parseTelemetry(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count == 20, bytes[0] == 0x03, bytes[1] == 0x0B else { return }
        guard bytes.dropLast().reduce(0, ^) == bytes[19] else { return }

        let milliseconds = unsigned24(bytes[2], bytes[3], bytes[4])
        let rawWeight = unsigned24(bytes[7], bytes[8], bytes[9])
        let rawFlow = (Int(bytes[11]) << 8) | Int(bytes[12])
        let weightSign = isNegativeSign(bytes[6]) ? -1.0 : 1.0
        let flowSign = isNegativeSign(bytes[10]) ? -1.0 : 1.0
        let unitMultiplier = bytes[5] == 2 ? 28.349_523_125 : 1.0
        let weight = weightSign * (Double(rawWeight) / 100) * unitMultiplier
        let flow = flowSign * (Double(rawFlow) / 100) * unitMultiplier

        onTelemetry?(weight, flow, milliseconds / 1_000)
    }

    private func unsigned24(_ high: UInt8, _ middle: UInt8, _ low: UInt8) -> Int {
        (Int(high) << 16) | (Int(middle) << 8) | Int(low)
    }

    private func isNegativeSign(_ byte: UInt8) -> Bool {
        byte == 1 || byte == 0x2D
    }

    private func modelName(for name: String) -> String {
        let normalized = Self.normalizedDeviceName(name)
        if normalized.contains("ultra") || normalized.hasPrefix("bookoo_sc_u_") {
            return "BOOKOO Themis Ultra"
        }
        if normalized.contains("mini") || normalized.hasPrefix("bookoo_sc_") {
            return "BOOKOO Themis Mini"
        }
        return "BOOKOO Scale"
    }

    private static func isBookooScaleName(_ name: String) -> Bool {
        normalizedDeviceName(name).hasPrefix("bookoo_sc_")
    }

    private static func normalizedDeviceName(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: "_")
    }
}
