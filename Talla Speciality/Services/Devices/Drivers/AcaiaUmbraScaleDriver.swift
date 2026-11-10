import Foundation
@preconcurrency import CoreBluetooth

@MainActor
final class AcaiaUmbraScaleDriver: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
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

    private static let serviceUUID = CBUUID(string: "0000FE40-CC7A-482A-984A-7F2ED5B3E58F")
    private static let writeCharacteristicUUID = CBUUID(string: "0000FE41-8E22-4541-9D4C-21EDAE82ED19")
    private static let notifyCharacteristicUUID = CBUUID(string: "0000FE42-8E22-4541-9D4C-21EDAE82ED19")

    private var centralManager: CBCentralManager?
    private var peripheralsByID: [String: CBPeripheral] = [:]
    private var devicesByID: [String: Device] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var scanTask: Task<Void, Never>?
    private var handshakeTask: Task<Void, Never>?
    private var shouldStartScanning = false
    private var failureDisconnectID: UUID?
    private var notificationBuffer = Data()

    deinit {
        scanTask?.cancel()
        handshakeTask?.cancel()
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
            onError?("The Acaia Umbra scale is no longer available. Scan again.")
            return
        }
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        notificationBuffer.removeAll(keepingCapacity: true)
        onConnecting?(devicesByID[id]?.name ?? "Acaia Umbra")
        centralManager.connect(peripheral)
    }

    func disconnect() {
        guard let connectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(connectedPeripheral)
    }

    func tare() {
        sendMessage(type: 0x04, payload: [0x00])
        onWeightChanged?(0)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            beginScanningIfReady()
        case .poweredOff:
            reportBluetoothUnavailable("Bluetooth is off. Turn it on to connect Acaia Umbra.")
        case .unauthorized:
            reportBluetoothUnavailable("Bluetooth access is required to connect Acaia Umbra.")
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
        guard name.uppercased().hasPrefix("UMBRA") else { return }

        let id = peripheral.identifier.uuidString
        peripheralsByID[id] = peripheral
        devicesByID[id] = Device(id: id, name: displayName(for: name), modelName: modelName(for: name))
        onDevicesChanged?(sortedDevices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        notificationBuffer.removeAll(keepingCapacity: true)
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        clearConnection()
        onError?(error?.localizedDescription ?? "Could not connect to Acaia Umbra.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if failureDisconnectID == peripheral.identifier {
            failureDisconnectID = nil
            clearConnection()
            return
        }
        clearConnection()
        if let error {
            onError?("Acaia Umbra disconnected: \(error.localizedDescription)")
        } else {
            onDisconnected?()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            failConnection("Could not read Acaia Umbra services: \(error.localizedDescription)")
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            failConnection("This device does not expose the supported Acaia Umbra service.")
            return
        }
        peripheral.discoverCharacteristics(
            [Self.writeCharacteristicUUID, Self.notifyCharacteristicUUID],
            for: service
        )
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            failConnection("Could not read Acaia Umbra controls: \(error.localizedDescription)")
            return
        }
        let characteristics = service.characteristics ?? []
        guard
            let write = characteristics.first(where: { $0.uuid == Self.writeCharacteristicUUID }),
            let notify = characteristics.first(where: { $0.uuid == Self.notifyCharacteristicUUID })
        else {
            failConnection("This Acaia Umbra uses an unsupported Bluetooth profile.")
            return
        }

        writeCharacteristic = write
        peripheral.setNotifyValue(true, for: notify)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == Self.notifyCharacteristicUUID else { return }
        if let error {
            failConnection("Could not start Acaia Umbra live readings: \(error.localizedDescription)")
            return
        }
        guard characteristic.isNotifying else {
            failConnection("Acaia Umbra did not enable live readings.")
            return
        }

        beginHandshake()
        let id = peripheral.identifier.uuidString
        let name = devicesByID[id]?.name ?? displayName(for: peripheral.name ?? "UMBRA")
        onConnected?(name)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, characteristic.uuid == Self.notifyCharacteristicUUID,
              let data = characteristic.value, !data.isEmpty else { return }
        notificationBuffer.append(data)
        parseAvailableFrames()
    }

    private var sortedDevices: [Device] {
        devicesByID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func beginScanningIfReady() {
        guard shouldStartScanning, let centralManager, centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    private func beginHandshake() {
        handshakeTask?.cancel()
        sendIdentify()
        requestStreamingWeight()

        handshakeTask = Task { [weak self] in
            for delay in [300, 900] {
                try? await Task.sleep(for: .milliseconds(delay))
                guard !Task.isCancelled else { return }
                self?.sendIdentify()
                self?.requestStreamingWeight()
            }
        }
    }

    private func sendIdentify() {
        sendMessage(type: 0x0B, payload: Array(repeating: 0x2D, count: 15))
    }

    private func requestStreamingWeight() {
        sendMessage(type: 0x0C, payload: [0x03, 0x00, 0x01])
    }

    private func sendMessage(type: UInt8, payload: [UInt8]) {
        guard let connectedPeripheral, let writeCharacteristic else { return }
        let checksums = Self.checksums(for: payload)
        let message = Data([0xEF, 0xDD, type] + payload + checksums)
        let writeType: CBCharacteristicWriteType = writeCharacteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        connectedPeripheral.writeValue(message, for: writeCharacteristic, type: writeType)
    }

    private func parseAvailableFrames() {
        while notificationBuffer.count >= 4 {
            let bytes = [UInt8](notificationBuffer)
            guard let headerIndex = bytes.indices.dropLast().first(where: {
                bytes[$0] == 0xEF && bytes[$0 + 1] == 0xDD
            }) else {
                notificationBuffer.removeAll(keepingCapacity: true)
                return
            }

            if headerIndex > 0 {
                notificationBuffer.removeFirst(headerIndex)
                continue
            }

            let framedBytes = [UInt8](notificationBuffer)
            guard framedBytes.count >= 4 else { return }
            let payloadLength = Int(framedBytes[3])
            guard payloadLength > 0 else {
                notificationBuffer.removeFirst(2)
                continue
            }

            let totalLength = payloadLength + 5
            guard framedBytes.count >= totalLength else { return }

            let command = framedBytes[2]
            let payload = Array(framedBytes[3..<(3 + payloadLength)])
            let expectedChecksums = Self.checksums(for: payload)
            let receivedChecksums = Array(framedBytes[(3 + payloadLength)..<(5 + payloadLength)])

            if expectedChecksums == receivedChecksums, command == 0x0C {
                parseEventPayload(payload)
            }
            notificationBuffer.removeFirst(totalLength)
        }
    }

    private func parseEventPayload(_ payload: [UInt8]) {
        guard payload.count >= 8, payload[1] == 0x05 else { return }
        let weightBytes = Array(payload[2...7])
        let rawValue = UInt32(weightBytes[0])
            | (UInt32(weightBytes[1]) << 8)
            | (UInt32(weightBytes[2]) << 16)
            | (UInt32(weightBytes[3]) << 24)

        var weight = Double(rawValue)
        switch weightBytes[4] {
        case 1: weight /= 10
        case 2: weight /= 100
        case 3: weight /= 1_000
        case 4: weight /= 10_000
        default: break
        }
        if (weightBytes[5] & 0x02) != 0 {
            weight *= -1
        }
        onWeightChanged?(weight)
    }

    private static func checksums(for payload: [UInt8]) -> [UInt8] {
        var even: UInt8 = 0
        var odd: UInt8 = 0
        for (index, byte) in payload.enumerated() {
            if index.isMultiple(of: 2) {
                even &+= byte
            } else {
                odd &+= byte
            }
        }
        return [even, odd]
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
        handshakeTask?.cancel()
        handshakeTask = nil
        connectedPeripheral = nil
        writeCharacteristic = nil
        notificationBuffer.removeAll(keepingCapacity: true)
    }

    private func displayName(for rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.uppercased().contains("DUO") { return "Acaia Umbra Duo" }
        return name.isEmpty ? "Acaia Umbra" : name
    }

    private func modelName(for name: String) -> String {
        name.uppercased().contains("DUO") ? "Acaia Umbra Duo" : "Acaia Umbra Lunar"
    }
}
