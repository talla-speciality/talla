import Foundation
@preconcurrency import CoreBluetooth

/// Bluetooth support for TIMEMORE Dot and compatible smart scales that expose
/// TIMEMORE's FFF0/FFF1/FFF2 profile.
@MainActor
final class TimemoreScaleDriver: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
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
    private static let notifyCharacteristicUUID = CBUUID(string: "FFF1")
    private static let writeCharacteristicUUID = CBUUID(string: "FFF2")

    private static let pollCommand = Data([0xA5, 0x5A, 0x02, 0x08, 0x00, 0x00, 0x00, 0x00])
    private static let enableStreamingCommand = Data([0xA5, 0x5A, 0x03, 0x08, 0x00, 0x02, 0x01, 0x00, 0x00, 0x00, 0x25])
    private static let tareCommand = Data([0xA5, 0x5A, 0x03, 0x0D, 0x00, 0x02, 0x00, 0x00, 0x00, 0x71])
    private static let startTimerCommand = Data([0xA5, 0x5A, 0x03, 0x02, 0x00, 0x01, 0x01, 0x00, 0x20])
    private static let stopTimerCommand = Data([0xA5, 0x5A, 0x03, 0x02, 0x00, 0x01, 0x02, 0x00, 0xFF, 0xD0])
    private static let resetTimerCommand = Data([0xA5, 0x5A, 0x03, 0x02, 0x00, 0x01, 0x03, 0x00, 0xFF, 0x81])
    private static let initializationCommands = [
        Data([0xA5, 0x5A, 0x02, 0x13, 0x00, 0x00, 0x00, 0x00]),
        pollCommand,
        Data([0xA5, 0x5A, 0x02, 0x05, 0x00, 0x00, 0x00, 0x00]),
        Data([0xA5, 0x5A, 0x02, 0x02, 0x00, 0x00, 0x00, 0x00]),
        Data([0xA5, 0x5A, 0x02, 0x06, 0x00, 0x00, 0x00, 0x00]),
        Data([0xA5, 0x5A, 0x02, 0x0C, 0x00, 0x00, 0x00, 0x00])
    ]

    private var centralManager: CBCentralManager?
    private var peripheralsByID: [String: CBPeripheral] = [:]
    private var devicesByID: [String: Device] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var notifyCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    private var scanTask: Task<Void, Never>?
    private var protocolTask: Task<Void, Never>?
    private var commandTask: Task<Void, Never>?
    private var shouldStartScanning = false
    private var failureDisconnectID: UUID?

    deinit {
        scanTask?.cancel()
        protocolTask?.cancel()
        commandTask?.cancel()
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
            onError?("The TIMEMORE scale is no longer available. Scan again.")
            return
        }
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        onConnecting?(devicesByID[id]?.name ?? "TIMEMORE Dot")
        centralManager.connect(peripheral)
    }

    func disconnect() {
        protocolTask?.cancel()
        commandTask?.cancel()
        guard let connectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(connectedPeripheral)
    }

    func tare() {
        send(Self.pollCommand)
        commandTask?.cancel()
        commandTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            self?.send(Self.tareCommand)
        }
        onWeightChanged?(0)
    }

    func startTimer() { send(Self.startTimerCommand) }
    func pauseTimer() { send(Self.stopTimerCommand) }

    func stopTimer() {
        send(Self.stopTimerCommand)
        commandTask?.cancel()
        commandTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            self?.send(Self.resetTimerCommand)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            beginScanningIfReady()
        case .poweredOff:
            reportBluetoothUnavailable("Bluetooth is off. Turn it on to connect TIMEMORE.")
        case .unauthorized:
            reportBluetoothUnavailable("Bluetooth access is required to connect TIMEMORE.")
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
        guard rawName.range(of: "TIMEMORE", options: .caseInsensitive) != nil else { return }

        let id = peripheral.identifier.uuidString
        peripheralsByID[id] = peripheral
        devicesByID[id] = Device(
            id: id,
            name: displayName(for: rawName),
            modelName: modelName(for: rawName)
        )
        onDevicesChanged?(sortedDevices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        clearConnection()
        onError?(error?.localizedDescription ?? "Could not connect to TIMEMORE.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if failureDisconnectID == peripheral.identifier {
            failureDisconnectID = nil
            clearConnection()
            return
        }
        clearConnection()
        if let error {
            onError?("TIMEMORE disconnected: \(error.localizedDescription)")
        } else {
            onDisconnected?()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            failConnection("Could not read TIMEMORE services: \(error.localizedDescription)")
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            failConnection("This TIMEMORE model does not expose the supported smart-scale profile.")
            return
        }
        peripheral.discoverCharacteristics(
            [Self.notifyCharacteristicUUID, Self.writeCharacteristicUUID],
            for: service
        )
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            failConnection("Could not read TIMEMORE controls: \(error.localizedDescription)")
            return
        }
        let characteristics = service.characteristics ?? []
        guard
            let notify = characteristics.first(where: { $0.uuid == Self.notifyCharacteristicUUID }),
            let write = characteristics.first(where: { $0.uuid == Self.writeCharacteristicUUID })
        else {
            failConnection("This TIMEMORE model uses an unsupported Bluetooth profile.")
            return
        }

        notifyCharacteristic = notify
        writeCharacteristic = write
        peripheral.setNotifyValue(true, for: notify)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == Self.notifyCharacteristicUUID else { return }
        if let error {
            failConnection("Could not start TIMEMORE live measurements: \(error.localizedDescription)")
            return
        }
        guard characteristic.isNotifying else {
            failConnection("TIMEMORE live measurements are unavailable.")
            return
        }

        let id = peripheral.identifier.uuidString
        onConnected?(devicesByID[id]?.name ?? displayName(for: peripheral.name ?? ""))
        initializeProtocol()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, characteristic.uuid == Self.notifyCharacteristicUUID,
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

    private func initializeProtocol() {
        protocolTask?.cancel()
        protocolTask = Task { [weak self] in
            for _ in 0..<2 {
                for command in Self.initializationCommands {
                    guard !Task.isCancelled else { return }
                    self?.send(command)
                    try? await Task.sleep(for: .milliseconds(50))
                }
            }

            while !Task.isCancelled {
                self?.send(Self.pollCommand)
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                self?.send(Self.enableStreamingCommand)
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    private func parseWeight(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 10, bytes[0] == 0xA5, bytes[1] == 0x5A, bytes[2] == 0x01 else { return }
        let raw = Int16(bitPattern: (UInt16(bytes[8]) << 8) | UInt16(bytes[9]))
        onWeightChanged?(Double(raw) / 10)
    }

    private func send(_ data: Data) {
        guard let connectedPeripheral, let writeCharacteristic else { return }
        let writeType: CBCharacteristicWriteType = writeCharacteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        connectedPeripheral.writeValue(data, for: writeCharacteristic, type: writeType)
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
        protocolTask?.cancel()
        protocolTask = nil
        commandTask?.cancel()
        commandTask = nil
        connectedPeripheral = nil
        notifyCharacteristic = nil
        writeCharacteristic = nil
    }

    private func displayName(for rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "TIMEMORE Dot" : name
    }

    private func modelName(for rawName: String) -> String {
        let normalized = rawName.uppercased()
        if normalized.contains("DOT") { return "TIMEMORE Dot" }
        if normalized.contains("BLACK MIRROR") || normalized.contains("BLACKMIRROR") {
            return "TIMEMORE Black Mirror Smart"
        }
        return "TIMEMORE Smart Scale"
    }
}
