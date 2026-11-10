import Foundation
import Combine
import AcaiaSDK

struct DiscoveredCoffeeScale: Identifiable, Equatable {
    let id: String
    let name: String
    let modelName: String
}

@MainActor
final class CoffeeScaleManager: NSObject, ObservableObject {
    enum ConnectionState: Equatable {
        case disconnected
        case scanning
        case connecting(String)
        case connected(String)
        case failed(String)
    }

    private enum Backend {
        case acaia
        case acaiaUmbra
        case bookoo
        case gina
        case hiroia
        case mantabrew
        case timemore
    }

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var discoveredScales: [DiscoveredCoffeeScale] = []
    @Published private(set) var weightGrams = 0.0
    @Published private(set) var flowRateGramsPerSecond = 0.0
    @Published private(set) var scaleTimerSeconds = 0

    private var acaiaScalesByID: [String: AcaiaScale] = [:]
    private var acaiaUmbraDevicesByID: [String: AcaiaUmbraScaleDriver.Device] = [:]
    private var bookooDevicesByID: [String: BookooScaleDriver.Device] = [:]
    private var ginaDevicesByID: [String: GinaScaleDriver.Device] = [:]
    private var hiroiaDevicesByID: [String: HiroiaScaleDriver.Device] = [:]
    private var mantabrewDevicesByID: [String: MantabrewScaleDriver.Device] = [:]
    private var timemoreDevicesByID: [String: TimemoreScaleDriver.Device] = [:]
    private var activeBackend: Backend?
    private var lastWeightSample: (weight: Double, uptime: TimeInterval)?
#if DEBUG
    private var isBluetoothInterruptionUITest = false
#endif

    private lazy var acaiaUmbraDriver: AcaiaUmbraScaleDriver = {
        let driver = AcaiaUmbraScaleDriver()
        driver.onDevicesChanged = { [weak self] devices in
            self?.acaiaUmbraDevicesByID = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
            self?.refreshDiscoveredScales()
        }
        driver.onConnecting = { [weak self] name in
            self?.handleConnecting(name, backend: .acaiaUmbra)
        }
        driver.onConnected = { [weak self] name in
            self?.handleConnected(name, backend: .acaiaUmbra)
        }
        driver.onDisconnected = { [weak self] in
            self?.handleDisconnected(backend: .acaiaUmbra)
        }
        driver.onError = { [weak self] message in
            self?.handleError(message, backend: .acaiaUmbra)
        }
        driver.onWeightChanged = { [weak self] weight in
            self?.handleWeight(weight, backend: .acaiaUmbra)
        }
        return driver
    }()

    private lazy var bookooDriver: BookooScaleDriver = {
        let driver = BookooScaleDriver()
        driver.onDevicesChanged = { [weak self] devices in
            self?.bookooDevicesByID = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
            self?.refreshDiscoveredScales()
        }
        driver.onScanFinished = { [weak self] in
            self?.finishCombinedScan()
        }
        driver.onConnecting = { [weak self] name in
            self?.handleConnecting(name, backend: .bookoo)
        }
        driver.onConnected = { [weak self] name in
            self?.handleConnected(name, backend: .bookoo)
        }
        driver.onDisconnected = { [weak self] in
            self?.handleDisconnected(backend: .bookoo)
        }
        driver.onError = { [weak self] message in
            self?.handleError(message, backend: .bookoo)
        }
        driver.onTelemetry = { [weak self] weight, flow, timer in
            self?.handleTelemetry(weight: weight, flow: flow, timer: timer, backend: .bookoo)
        }
        return driver
    }()

    private lazy var ginaDriver: GinaScaleDriver = {
        let driver = GinaScaleDriver()
        driver.onDevicesChanged = { [weak self] devices in
            self?.ginaDevicesByID = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
            self?.refreshDiscoveredScales()
        }
        driver.onConnecting = { [weak self] name in
            self?.handleConnecting(name, backend: .gina)
        }
        driver.onConnected = { [weak self] name in
            self?.handleConnected(name, backend: .gina)
        }
        driver.onDisconnected = { [weak self] in
            self?.handleDisconnected(backend: .gina)
        }
        driver.onError = { [weak self] message in
            self?.handleError(message, backend: .gina)
        }
        driver.onWeightChanged = { [weak self] weight in
            self?.handleWeight(weight, backend: .gina)
        }
        return driver
    }()

    private lazy var hiroiaDriver: HiroiaScaleDriver = {
        let driver = HiroiaScaleDriver()
        driver.onDevicesChanged = { [weak self] devices in
            self?.hiroiaDevicesByID = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
            self?.refreshDiscoveredScales()
        }
        driver.onConnecting = { [weak self] name in
            self?.handleConnecting(name, backend: .hiroia)
        }
        driver.onConnected = { [weak self] name in
            self?.handleConnected(name, backend: .hiroia)
        }
        driver.onDisconnected = { [weak self] in
            self?.handleDisconnected(backend: .hiroia)
        }
        driver.onError = { [weak self] message in
            self?.handleError(message, backend: .hiroia)
        }
        driver.onWeightChanged = { [weak self] weight in
            self?.handleWeight(weight, backend: .hiroia)
        }
        return driver
    }()

    private lazy var mantabrewDriver: MantabrewScaleDriver = {
        let driver = MantabrewScaleDriver()
        driver.onDevicesChanged = { [weak self] devices in
            self?.mantabrewDevicesByID = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
            self?.refreshDiscoveredScales()
        }
        driver.onConnecting = { [weak self] name in
            self?.handleConnecting(name, backend: .mantabrew)
        }
        driver.onConnected = { [weak self] name in
            self?.handleConnected(name, backend: .mantabrew)
        }
        driver.onDisconnected = { [weak self] in
            self?.handleDisconnected(backend: .mantabrew)
        }
        driver.onError = { [weak self] message in
            self?.handleError(message, backend: .mantabrew)
        }
        driver.onWeightChanged = { [weak self] weight in
            self?.handleWeight(weight, backend: .mantabrew)
        }
        return driver
    }()

    private lazy var timemoreDriver: TimemoreScaleDriver = {
        let driver = TimemoreScaleDriver()
        driver.onDevicesChanged = { [weak self] devices in
            self?.timemoreDevicesByID = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
            self?.refreshDiscoveredScales()
        }
        driver.onConnecting = { [weak self] name in
            self?.handleConnecting(name, backend: .timemore)
        }
        driver.onConnected = { [weak self] name in
            self?.handleConnected(name, backend: .timemore)
        }
        driver.onDisconnected = { [weak self] in
            self?.handleDisconnected(backend: .timemore)
        }
        driver.onError = { [weak self] message in
            self?.handleError(message, backend: .timemore)
        }
        driver.onWeightChanged = { [weak self] weight in
            self?.handleWeight(weight, backend: .timemore)
        }
        return driver
    }()

    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    var connectedScaleName: String? {
        if case let .connected(name) = connectionState { return name }
        return nil
    }

    override init() {
        super.init()
        addObservers()
        refreshConnectionState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func scan() {
#if DEBUG
        if isBluetoothInterruptionUITest {
            connectionState = .connected("Acaia Pearl")
            weightGrams = 42
            flowRateGramsPerSecond = 2.4
            return
        }
#endif
        guard activeBackend == nil, !isConnected else { return }
        connectionState = .scanning
        acaiaScalesByID = [:]
        acaiaUmbraDevicesByID = [:]
        bookooDevicesByID = [:]
        ginaDevicesByID = [:]
        hiroiaDevicesByID = [:]
        mantabrewDevicesByID = [:]
        timemoreDevicesByID = [:]
        discoveredScales = []
        AcaiaManager.shared().startScan(0.5)
        acaiaUmbraDriver.scan()
        bookooDriver.scan()
        ginaDriver.scan()
        hiroiaDriver.scan()
        mantabrewDriver.scan()
        timemoreDriver.scan()
    }

    func stopScanning() {
        AcaiaManager.shared().stopScan()
        acaiaUmbraDriver.stopScanning()
        bookooDriver.stopScanning()
        ginaDriver.stopScanning()
        hiroiaDriver.stopScanning()
        mantabrewDriver.stopScanning()
        timemoreDriver.stopScanning()
        if !isConnected, case .scanning = connectionState {
            connectionState = .disconnected
        }
    }

    func connect(to id: String) {
        guard activeBackend == nil else { return }
        if id.hasPrefix("acaia:"), let scale = acaiaScalesByID[id] {
            activeBackend = .acaia
            connectionState = .connecting(scale.name)
            acaiaUmbraDriver.stopScanning()
            bookooDriver.stopScanning()
            ginaDriver.stopScanning()
            hiroiaDriver.stopScanning()
            mantabrewDriver.stopScanning()
            timemoreDriver.stopScanning()
            scale.connect()
        } else if id.hasPrefix("acaia-umbra:") {
            activeBackend = .acaiaUmbra
            AcaiaManager.shared().stopScan()
            bookooDriver.stopScanning()
            ginaDriver.stopScanning()
            hiroiaDriver.stopScanning()
            mantabrewDriver.stopScanning()
            timemoreDriver.stopScanning()
            acaiaUmbraDriver.connect(to: String(id.dropFirst("acaia-umbra:".count)))
        } else if id.hasPrefix("bookoo:") {
            activeBackend = .bookoo
            AcaiaManager.shared().stopScan()
            acaiaUmbraDriver.stopScanning()
            ginaDriver.stopScanning()
            hiroiaDriver.stopScanning()
            mantabrewDriver.stopScanning()
            timemoreDriver.stopScanning()
            bookooDriver.connect(to: String(id.dropFirst("bookoo:".count)))
        } else if id.hasPrefix("gina:") {
            activeBackend = .gina
            AcaiaManager.shared().stopScan()
            acaiaUmbraDriver.stopScanning()
            bookooDriver.stopScanning()
            hiroiaDriver.stopScanning()
            mantabrewDriver.stopScanning()
            timemoreDriver.stopScanning()
            ginaDriver.connect(to: String(id.dropFirst("gina:".count)))
        } else if id.hasPrefix("hiroia:") {
            activeBackend = .hiroia
            AcaiaManager.shared().stopScan()
            acaiaUmbraDriver.stopScanning()
            bookooDriver.stopScanning()
            ginaDriver.stopScanning()
            mantabrewDriver.stopScanning()
            timemoreDriver.stopScanning()
            hiroiaDriver.connect(to: String(id.dropFirst("hiroia:".count)))
        } else if id.hasPrefix("mantabrew:") {
            activeBackend = .mantabrew
            AcaiaManager.shared().stopScan()
            acaiaUmbraDriver.stopScanning()
            bookooDriver.stopScanning()
            ginaDriver.stopScanning()
            hiroiaDriver.stopScanning()
            timemoreDriver.stopScanning()
            mantabrewDriver.connect(to: String(id.dropFirst("mantabrew:".count)))
        } else if id.hasPrefix("timemore:") {
            activeBackend = .timemore
            AcaiaManager.shared().stopScan()
            acaiaUmbraDriver.stopScanning()
            bookooDriver.stopScanning()
            ginaDriver.stopScanning()
            hiroiaDriver.stopScanning()
            mantabrewDriver.stopScanning()
            timemoreDriver.connect(to: String(id.dropFirst("timemore:".count)))
        }
    }

    func disconnect() {
#if DEBUG
        if isBluetoothInterruptionUITest {
            activeBackend = nil
            connectionState = .failed("Scale connection interrupted")
            return
        }
#endif
        switch activeBackend {
        case .acaia: AcaiaManager.shared().connectedScale?.disconnect()
        case .acaiaUmbra: acaiaUmbraDriver.disconnect()
        case .bookoo: bookooDriver.disconnect()
        case .gina: ginaDriver.disconnect()
        case .hiroia: hiroiaDriver.disconnect()
        case .mantabrew: mantabrewDriver.disconnect()
        case .timemore: timemoreDriver.disconnect()
        case nil: break
        }
        resetConnection()
    }

#if DEBUG
    func configureBluetoothInterruptionUITest() {
        isBluetoothInterruptionUITest = true
        connectionState = .connected("Acaia Pearl")
        weightGrams = 42
        flowRateGramsPerSecond = 2.4
    }
#endif

    func tare() {
        switch activeBackend {
        case .acaia: AcaiaManager.shared().connectedScale?.tare()
        case .acaiaUmbra: acaiaUmbraDriver.tare()
        case .bookoo: bookooDriver.tare()
        case .gina: ginaDriver.tare()
        case .hiroia: hiroiaDriver.tare()
        case .mantabrew: mantabrewDriver.tare()
        case .timemore: timemoreDriver.tare()
        case nil: break
        }
        weightGrams = 0
        flowRateGramsPerSecond = 0
        lastWeightSample = nil
    }

    func startTimer() {
        switch activeBackend {
        case .acaia: AcaiaManager.shared().connectedScale?.startTimer()
        case .acaiaUmbra: break
        case .bookoo: bookooDriver.startTimer()
        case .gina: break
        case .hiroia: break
        case .mantabrew: mantabrewDriver.startTimer()
        case .timemore: timemoreDriver.startTimer()
        case nil: break
        }
    }

    func pauseTimer() {
        switch activeBackend {
        case .acaia: AcaiaManager.shared().connectedScale?.pauseTimer()
        case .acaiaUmbra: break
        case .bookoo: bookooDriver.pauseTimer()
        case .gina: break
        case .hiroia: break
        case .mantabrew: mantabrewDriver.pauseTimer()
        case .timemore: timemoreDriver.pauseTimer()
        case nil: break
        }
    }

    func stopTimer() {
        switch activeBackend {
        case .acaia: AcaiaManager.shared().connectedScale?.stopTimer()
        case .acaiaUmbra: break
        case .bookoo: bookooDriver.stopTimer()
        case .gina: break
        case .hiroia: break
        case .mantabrew: mantabrewDriver.stopTimer()
        case .timemore: timemoreDriver.stopTimer()
        case nil: break
        }
        scaleTimerSeconds = 0
    }

    private func addObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(scaleDidConnect), name: .init(rawValue: AcaiaScaleDidConnected), object: nil)
        center.addObserver(self, selector: #selector(scaleDidDisconnect), name: .init(rawValue: AcaiaScaleDidDisconnected), object: nil)
        center.addObserver(self, selector: #selector(scaleConnectionFailed), name: .init(rawValue: AcaiaScaleConnectFailed), object: nil)
        center.addObserver(self, selector: #selector(scaleListChanged), name: .init(rawValue: AcaiaScaleDeviceListChanged), object: nil)
        center.addObserver(self, selector: #selector(scaleScanFinished), name: .init(rawValue: AcaiaScaleDidFinishScan), object: nil)
        center.addObserver(self, selector: #selector(scaleWeightChanged), name: .init(rawValue: AcaiaScaleWeight), object: nil)
        center.addObserver(self, selector: #selector(scaleTimerChanged), name: .init(rawValue: AcaiaScaleTimer), object: nil)
    }

    private func refreshAcaiaScales() {
        let scales = AcaiaManager.shared().scaleList.filter {
            !$0.name.localizedCaseInsensitiveContains("umbra")
                && !$0.modelName.localizedCaseInsensitiveContains("umbra")
        }
        acaiaScalesByID = Dictionary(uniqueKeysWithValues: scales.map { ("acaia:\($0.uuid)", $0) })
        refreshDiscoveredScales()
    }

    private func refreshDiscoveredScales() {
        let acaia = acaiaScalesByID.map { id, scale in
            DiscoveredCoffeeScale(id: id, name: scale.name, modelName: scale.modelName)
        }
        let acaiaUmbra = acaiaUmbraDevicesByID.values.map { device in
            DiscoveredCoffeeScale(id: "acaia-umbra:\(device.id)", name: device.name, modelName: device.modelName)
        }
        let bookoo = bookooDevicesByID.values.map { device in
            DiscoveredCoffeeScale(id: "bookoo:\(device.id)", name: device.name, modelName: device.modelName)
        }
        let gina = ginaDevicesByID.values.map { device in
            DiscoveredCoffeeScale(id: "gina:\(device.id)", name: device.name, modelName: device.modelName)
        }
        let hiroia = hiroiaDevicesByID.values.map { device in
            DiscoveredCoffeeScale(id: "hiroia:\(device.id)", name: device.name, modelName: device.modelName)
        }
        let mantabrew = mantabrewDevicesByID.values.map { device in
            DiscoveredCoffeeScale(id: "mantabrew:\(device.id)", name: device.name, modelName: device.modelName)
        }
        let timemore = timemoreDevicesByID.values.map { device in
            DiscoveredCoffeeScale(id: "timemore:\(device.id)", name: device.name, modelName: device.modelName)
        }
        discoveredScales = (acaia + acaiaUmbra + bookoo + gina + hiroia + mantabrew + timemore).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func refreshConnectionState() {
        guard let scale = AcaiaManager.shared().connectedScale else {
            connectionState = .disconnected
            return
        }
        activeBackend = .acaia
        connectionState = .connected(scale.name)
    }

    private func finishCombinedScan() {
        guard activeBackend == nil, !isConnected else { return }
        refreshAcaiaScales()
        connectionState = discoveredScales.isEmpty
            ? .failed("No supported scale found. Make sure your Acaia, BOOKOO, GINA, HIROIA, MANTABREW, or TIMEMORE scale is on and nearby.")
            : .disconnected
    }

    private func handleConnecting(_ name: String, backend: Backend) {
        guard activeBackend == backend else { return }
        connectionState = .connecting(name)
    }

    private func handleConnected(_ name: String, backend: Backend) {
        guard activeBackend == backend else { return }
        weightGrams = 0
        flowRateGramsPerSecond = 0
        scaleTimerSeconds = 0
        lastWeightSample = nil
        connectionState = .connected(name)
    }

    private func handleDisconnected(backend: Backend) {
        guard activeBackend == backend else { return }
        resetConnection()
    }

    private func handleError(_ message: String, backend: Backend) {
        guard activeBackend == backend else { return }
        resetConnection()
        connectionState = .failed(message)
    }

    private func handleWeight(_ weight: Double, backend: Backend) {
        guard activeBackend == backend, isConnected else { return }
        updateComputedWeight(weight)
    }

    private func handleTelemetry(weight: Double, flow: Double, timer: Int, backend: Backend) {
        guard activeBackend == backend, isConnected, weight.isFinite else { return }
        weightGrams = weight
        flowRateGramsPerSecond = flow.isFinite ? max(flow, 0) : 0
        scaleTimerSeconds = max(timer, 0)
    }

    private func resetConnection() {
        weightGrams = 0
        flowRateGramsPerSecond = 0
        scaleTimerSeconds = 0
        lastWeightSample = nil
        activeBackend = nil
        connectionState = .disconnected
    }

    private func updateComputedWeight(_ weight: Double) {
        guard weight.isFinite else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if let lastWeightSample {
            let elapsed = now - lastWeightSample.uptime
            if elapsed > 0.05 {
                let instantaneous = max((weight - lastWeightSample.weight) / elapsed, 0)
                flowRateGramsPerSecond = (flowRateGramsPerSecond * 0.65) + (instantaneous * 0.35)
                if instantaneous < 0.15 {
                    flowRateGramsPerSecond *= 0.6
                }
            }
        }
        weightGrams = weight
        lastWeightSample = (weight, now)
    }

    @objc private func scaleDidConnect() {
        guard activeBackend == .acaia else { return }
        refreshConnectionState()
    }

    @objc private func scaleDidDisconnect() {
        guard activeBackend == .acaia else { return }
        resetConnection()
    }

    @objc private func scaleConnectionFailed() {
        handleError("Could not connect to the Acaia scale.", backend: .acaia)
    }

    @objc private func scaleListChanged() {
        refreshAcaiaScales()
    }

    @objc private func scaleScanFinished() {
        refreshAcaiaScales()
    }

    @objc private func scaleWeightChanged(_ notification: Notification) {
        guard activeBackend == .acaia,
              let rawWeight = notification.userInfo?[AcaiaScaleUserInfoKeyWeight] as? NSNumber else { return }
        let unit = notification.userInfo?[AcaiaScaleUserInfoKeyUnit] as? NSNumber
        let weight = unit?.intValue == AcaiaScaleWeightUnit.ounce.rawValue
            ? rawWeight.doubleValue * 28.349_523_125
            : rawWeight.doubleValue

        updateComputedWeight(weight)
    }

    @objc private func scaleTimerChanged(_ notification: Notification) {
        guard activeBackend == .acaia,
              let seconds = notification.userInfo?[AcaiaScaleUserInfoKeyTimer] as? NSNumber else { return }
        scaleTimerSeconds = seconds.intValue
    }
}
