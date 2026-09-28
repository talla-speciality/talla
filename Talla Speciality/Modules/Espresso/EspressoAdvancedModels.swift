import Foundation
import SwiftUI
import PhotosUI

enum EspressoTelemetryKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case pressure
    case flow
    case temperature

    var id: String { rawValue }
    var unit: String {
        switch self {
        case .pressure: return "bar"
        case .flow: return "g/s"
        case .temperature: return "°C"
        }
    }
}

struct EspressoTelemetrySample: Codable, Equatable, Identifiable {
    var id = UUID()
    var elapsedSeconds: Double
    var kind: EspressoTelemetryKind
    var value: Double

    init(elapsedSeconds: Double, kind: EspressoTelemetryKind, value: Double) {
        self.elapsedSeconds = elapsedSeconds
        self.kind = kind
        self.value = value
    }
}

struct RefractometerReading: Codable, Equatable {
    var tdsPercent: Double
    var measuredYieldGrams: Double
    var measuredAt = Date()
}

enum EspressoExtractionMath {
    /// EY = beverage mass × TDS ÷ dry coffee mass. Values are returned as a percent.
    static func extractionYieldPercent(doseGrams: Double, beverageYieldGrams: Double, tdsPercent: Double) -> Double? {
        guard doseGrams > 0, beverageYieldGrams >= 0, tdsPercent >= 0 else { return nil }
        return (beverageYieldGrams * tdsPercent) / doseGrams
    }
}

struct EspressoReferenceOverlay: Equatable {
    var pressure: [EspressoTelemetrySample]
    var flow: [EspressoTelemetrySample]
    var temperature: [EspressoTelemetrySample]

    init(samples: [EspressoTelemetrySample]) {
        pressure = samples.filter { $0.kind == .pressure }.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
        flow = samples.filter { $0.kind == .flow }.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
        temperature = samples.filter { $0.kind == .temperature }.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }

    var isEmpty: Bool { pressure.isEmpty && flow.isEmpty && temperature.isEmpty }
}

struct EspressoMachineIntegration: Codable, Equatable, Identifiable, Hashable {
    enum AccessMode: String, Codable, Hashable { case readOnly; case officialControl }
    enum SupportLevel: String, Codable, Hashable { case officialSDK; case officialCloudAPI; case officialCompanionApp; case manualOnly }

    var id: String
    var name: String
    var manufacturer: String
    var accessMode: AccessMode
    var supportLevel: SupportLevel
    var supportedStreams: Set<EspressoTelemetryKind>
    var officialURL: URL?
    var notes: String

    static let catalog = [
        EspressoMachineIntegration(id: "decent-de1", name: "Decent DE1 / DE1XL", manufacturer: "Decent Espresso", accessMode: .readOnly, supportLevel: .officialCompanionApp, supportedStreams: [.pressure, .flow, .temperature], officialURL: URL(string: "https://decentespresso.com/docs"), notes: "Read-only monitoring is available through a local Decaid gateway. Direct Talla control remains disabled until hardware validation."),
        EspressoMachineIntegration(id: "linea-mini", name: "La Marzocco Linea Mini / Mini R", manufacturer: "La Marzocco", accessMode: .officialControl, supportLevel: .officialCompanionApp, supportedStreams: [.temperature], officialURL: URL(string: "https://www.lamarzocco.com/ca/en/home-products/espresso-machines/linea-mini-r/"), notes: "The official La Marzocco Home app supports machine settings and shot tracking; Talla control stays disabled without an approved partner integration."),
        EspressoMachineIntegration(id: "home-connect-coffee", name: "Home Connect coffee machines", manufacturer: "BSH Home Connect", accessMode: .officialControl, supportLevel: .officialCloudAPI, supportedStreams: [.temperature], officialURL: URL(string: "https://api-docs.home-connect.com/"), notes: "The official Home Connect API supports monitoring and control, subject to appliance capabilities and OAuth authorization."),
        EspressoMachineIntegration(id: "jura-smart-connect", name: "JURA Smart Connect / Wi-Fi Connect", manufacturer: "JURA", accessMode: .officialControl, supportLevel: .officialCompanionApp, supportedStreams: [.temperature], officialURL: URL(string: "https://www.jura.com/en/professional/accessories/joe"), notes: "JURA’s J.O.E. app can operate compatible machines; Talla requires a separate approved integration contract."),
        EspressoMachineIntegration(id: "victoria-arduino-e1-prima", name: "Victoria Arduino E1 Prima", manufacturer: "Victoria Arduino", accessMode: .officialControl, supportLevel: .officialCompanionApp, supportedStreams: [.temperature], officialURL: URL(string: "https://victoriaarduino.com/products-machines/e1-prima/"), notes: "The E1 Prima has an official companion app; direct Talla control is not enabled without an approved adapter."),
        EspressoMachineIntegration(id: "acaia-lunar-pearl", name: "Acaia Lunar / Pearl", manufacturer: "Acaia", accessMode: .readOnly, supportLevel: .officialSDK, supportedStreams: [.flow], officialURL: URL(string: "https://acaia.co/blogs/news/new-ios-sdk-api-release"), notes: "Official iOS SDK path for Bluetooth connection, tare, weight, and timer; flow is derived from weight samples."),
        EspressoMachineIntegration(id: "bookoo-mini", name: "BOOKOO Mini Scale", manufacturer: "BOOKOO", accessMode: .readOnly, supportLevel: .officialSDK, supportedStreams: [.flow], officialURL: nil, notes: "Talla already supports read-only Bluetooth weight and flow telemetry."),
        EspressoMachineIntegration(id: "goat-story-gina", name: "GOAT STORY GINA", manufacturer: "GOAT STORY", accessMode: .readOnly, supportLevel: .officialSDK, supportedStreams: [.flow], officialURL: nil, notes: "Talla already supports read-only Bluetooth weight and flow telemetry."),
        EspressoMachineIntegration(id: "hiroia-jimmy", name: "HIROIA JIMMY", manufacturer: "HIROIA", accessMode: .readOnly, supportLevel: .officialSDK, supportedStreams: [.flow], officialURL: nil, notes: "Talla already supports read-only Bluetooth weight and flow telemetry."),
        EspressoMachineIntegration(id: "mantabrew-scale", name: "MANTABREW Scale", manufacturer: "MANTABREW", accessMode: .readOnly, supportLevel: .officialSDK, supportedStreams: [.flow], officialURL: nil, notes: "Talla already supports read-only Bluetooth weight and flow telemetry."),
        EspressoMachineIntegration(id: "timemore-dot", name: "TIMEMORE Black Mirror / Dot", manufacturer: "TIMEMORE", accessMode: .readOnly, supportLevel: .officialSDK, supportedStreams: [.flow], officialURL: nil, notes: "Talla’s existing Bluetooth scale driver supports compatible TIMEMORE smart-scale profiles."),
        EspressoMachineIntegration(id: "rocket-profitec-ecm", name: "Rocket / Profitec / ECM", manufacturer: "Multiple manufacturers", accessMode: .readOnly, supportLevel: .manualOnly, supportedStreams: [], officialURL: nil, notes: "Excellent manual profiling candidates; use scale, pressure gauge, thermometer, and refractometer capture."),
        EspressoMachineIntegration(id: "rancilio-nuova-simonelli", name: "Rancilio / Nuova Simonelli", manufacturer: "Multiple manufacturers", accessMode: .readOnly, supportLevel: .manualOnly, supportedStreams: [], officialURL: nil, notes: "Manual shot logging until an official consumer API is available."),
        EspressoMachineIntegration(id: "manual-espresso", name: "Other espresso machine", manufacturer: "Any manufacturer", accessMode: .readOnly, supportLevel: .manualOnly, supportedStreams: [], officialURL: nil, notes: "Record dose, yield, pressure, temperature, and refractometer readings manually.")
    ]

    static let examples = catalog
}

enum EspressoMachineConnectionState: String, Codable { case disconnected, pairing, connected, unavailable }

enum EspressoMachineControlCommand: Codable, Equatable {
    case startShot
    case stopShot
    case setTemperature(Double)
    case setPressure(Double)
}

struct EspressoMachineAdapterDescriptor: Codable, Equatable, Identifiable {
    var id: String
    var integrationID: String
    var officialApprovalReference: String
    var allowsControl: Bool
}

enum EspressoMachineControlPolicy {
    static func allows(_ command: EspressoMachineControlCommand, integration: EspressoMachineIntegration, adapter: EspressoMachineAdapterDescriptor?) -> Bool {
        guard integration.accessMode == .officialControl,
              let adapter,
              adapter.integrationID == integration.id,
              adapter.allowsControl,
              !adapter.officialApprovalReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return true
    }
}

struct SharedEspressoProfile: Codable, Equatable, Identifiable {
    var id = UUID()
    var title: String
    var machine: String
    var doseGrams: Double
    var yieldGrams: Double
    var temperatureC: Double
    var pressureBar: Double?
    var grindSetting: String
    var notes: String
    var author: String
    var equipmentTags: [String]
}

struct RoasterEspressoRecipe: Codable, Equatable, Identifiable {
    var id = UUID()
    var title: String
    var roaster: String
    var coffeeName: String
    var doseGrams: Double
    var yieldGrams: Double
    var temperatureC: Double
    var grindSetting: String
    var publishedAt = Date()
    var sourceURL: URL?
}

enum BottomlessDiagnostic: String, Codable, CaseIterable, Identifiable, Hashable {
    case channeling
    case blonding
    case spurting
    case unevenFlow
    case slowStart

    var id: String { rawValue }
    var title: String {
        switch self {
        case .channeling: return "Channeling"
        case .blonding: return "Early blonding"
        case .spurting: return "Spurting"
        case .unevenFlow: return "Uneven flow"
        case .slowStart: return "Slow start"
        }
    }
}

struct BottomlessVideoAssessment: Codable, Equatable, Identifiable {
    var id = UUID()
    var videoURL: URL
    var diagnostics: Set<BottomlessDiagnostic>
    var note: String
    var createdAt = Date()
}

struct EspressoCommunityStartingPoint: Codable, Equatable, Identifiable {
    var id = UUID()
    var equipment: String
    var title: String
    var profile: SharedEspressoProfile
    var source: String
}

struct EspressoAdvancedSnapshot: Codable, Equatable {
    var telemetry: [EspressoTelemetrySample] = []
    var refractometer: RefractometerReading?
    var sharedProfiles: [SharedEspressoProfile] = []
    var roasterRecipes: [RoasterEspressoRecipe] = []
    var videoAssessments: [BottomlessVideoAssessment] = []
}

struct EspressoAdvancedPanel: View {
    @Binding var draft: EspressoShot
    @Binding var shots: [EspressoShot]
    @Binding var telemetry: [EspressoTelemetrySample]
    @Environment(\.openURL) private var openURL

    @State private var tdsPercent = 9.0
    @State private var measuredYield = 36.0
    @State private var selectedKind: EspressoTelemetryKind = .pressure
    @State private var sampleValue = 9.0
    @State private var sampleSeconds = 0.0
    @State private var videoURL = ""
    @State private var videoSelection: PhotosPickerItem?
    @State private var selectedVideoData: Data?
    @State private var diagnostics: Set<BottomlessDiagnostic> = []
    @State private var selectedIntegration = EspressoMachineIntegration.catalog[0]
    @State private var homeConnectAppliances: [[String: String]] = []
    @State private var isLoadingHomeConnect = false
    @StateObject private var decentClient = DecentDE1ReadOnlyClient()
    @State private var decentGatewayURL = "http://192.168.1.100:8080"
    @State private var isShowingProfile = false
    @State private var shareStatus = ""
    @AppStorage("talla.espresso.advanced.snapshot.v1") private var snapshotPayload = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ADVANCED ESPRESSO", systemImage: "waveform.path.ecg.rectangle")
                .font(.caption.weight(.bold)).tracking(1.1)
            Text("Measure the shot before changing the shot.")
                .font(.headline)
            telemetryEditor
            overlaySummary
            refractometerCard
            integrationCard
            profileAndVideoCard
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            loadSnapshot()
            if selectedIntegration.id == "home-connect-coffee" { Task { await refreshHomeConnectAppliances() } }
        }
        .onChange(of: selectedIntegration) { _, integration in
            if integration.id == "home-connect-coffee" { Task { await refreshHomeConnectAppliances() } }
            if integration.id != "decent-de1" { decentClient.stopMonitoring() }
        }
        .onChange(of: decentClient.snapshot) { _, snapshot in
            guard let snapshot else { return }
            if let pressure = snapshot.pressure { telemetry.append(.init(elapsedSeconds: sampleSeconds, kind: .pressure, value: pressure)) }
            if let flow = snapshot.flow { telemetry.append(.init(elapsedSeconds: sampleSeconds, kind: .flow, value: flow)) }
            if let temperature = snapshot.groupTemperature ?? snapshot.mixTemperature { telemetry.append(.init(elapsedSeconds: sampleSeconds, kind: .temperature, value: temperature)) }
            sampleSeconds += 1
            persistSnapshot()
        }
        .sheet(isPresented: $isShowingProfile) {
            NavigationStack {
                Form {
                    Section("Shared profile") {
                        Text("This profile is ready to publish or share after review.")
            Text("1:\(String(format: "%.2f", draft.ratio)) · \(String(format: "%.0f", draft.temperature)) °C")
                    }
                }.navigationTitle("Espresso profile")
            }
        }
    }

    private var telemetryEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sensor streams").font(.subheadline.weight(.semibold))
            HStack {
                Picker("Stream", selection: $selectedKind) { ForEach(EspressoTelemetryKind.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                TextField("Value", value: $sampleValue, format: .number).keyboardType(.decimalPad).frame(width: 70)
                Text(selectedKind.unit).font(.caption)
                TextField("s", value: $sampleSeconds, format: .number).keyboardType(.decimalPad).frame(width: 45)
                Button("Add") {
                    telemetry.append(.init(elapsedSeconds: sampleSeconds, kind: selectedKind, value: sampleValue))
                    persistSnapshot()
                }
            }
            Text(telemetry.isEmpty ? "No pressure, flow, or temperature samples yet." : "\(telemetry.count) samples captured")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var overlaySummary: some View {
        let overlay = EspressoReferenceOverlay(samples: telemetry)
        return VStack(alignment: .leading, spacing: 5) {
            Text("Pressure / flow / temperature overlay").font(.subheadline.weight(.semibold))
            Text("Pressure \(overlay.pressure.count) · Flow \(overlay.flow.count) · Temperature \(overlay.temperature.count)")
                .font(.caption).foregroundStyle(.secondary)
            if let maxPressure = overlay.pressure.map(\.value).max() { Text("Peak pressure \(String(format: "%.1f bar", maxPressure))").font(.caption) }
        }
    }

    private var refractometerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Refractometer").font(.subheadline.weight(.semibold))
            HStack { TextField("TDS %", value: $tdsPercent, format: .number).keyboardType(.decimalPad); TextField("Yield g", value: $measuredYield, format: .number).keyboardType(.decimalPad); Button("Save") { persistSnapshot() }.font(.caption) }
            if let ey = EspressoExtractionMath.extractionYieldPercent(doseGrams: draft.dose, beverageYieldGrams: measuredYield, tdsPercent: tdsPercent) {
                Text(String(format: "Extraction yield %.2f%%", ey)).font(.caption.weight(.semibold))
            }
        }
    }

    private var integrationCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Machine integrations").font(.subheadline.weight(.semibold))
            Picker("Integration", selection: $selectedIntegration) { ForEach(EspressoMachineIntegration.catalog) { Text($0.name).tag($0) } }
            Text(selectedIntegration.notes).font(.caption).foregroundStyle(.secondary)
            Text(selectedIntegration.supportLevel == .manualOnly ? "Manual capture" : selectedIntegration.supportLevel.rawValue)
                .font(.caption).foregroundStyle(.secondary)
            if selectedIntegration.id == "home-connect-coffee" {
                HStack {
                    Button("Connect Home Connect") {
                    Task {
                        do { openURL(try await AccountService.homeConnectAuthorizationURL()) }
                        catch { shareStatus = "Home Connect is not configured on the server." }
                    }
                    }.buttonStyle(.bordered)
                    Button(isLoadingHomeConnect ? "Loading…" : "Refresh appliances") {
                        Task { await refreshHomeConnectAppliances() }
                    }.buttonStyle(.bordered).disabled(isLoadingHomeConnect)
                }
                if homeConnectAppliances.isEmpty {
                    Text("No connected appliances returned yet.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(homeConnectAppliances.enumerated()), id: \.offset) { _, appliance in
                        let name = appliance["name"] ?? appliance["brand"] ?? appliance["haId"] ?? "Home Connect appliance"
                        HStack {
                            Text(name).font(.caption)
                            Spacer()
                            if let applianceID = appliance["haId"] {
                                Button("Brew espresso") {
                                    Task {
                                        do {
                                            try await AccountService.startHomeConnectEspresso(applianceID: applianceID, fillQuantity: draft.yield > 0 ? draft.yield : 35)
                                            shareStatus = "Espresso start sent to Home Connect."
                                        } catch {
                                            shareStatus = "The appliance is not ready for remote start."
                                        }
                                    }
                                }.font(.caption).buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            if selectedIntegration.id == "decent-de1" {
                TextField("Decaid gateway URL", text: $decentGatewayURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                Button(decentClient.isMonitoring ? "Stop Decent monitoring" : "Monitor Decent DE1") {
                    guard let url = URL(string: decentGatewayURL), url.scheme == "http" || url.scheme == "https" else { return }
                    if decentClient.isMonitoring { decentClient.stopMonitoring() } else { decentClient.startMonitoring(baseURL: url) }
                }.buttonStyle(.bordered)
                if let snapshot = decentClient.snapshot {
                    Text("DE1 (snapshot.state?.state ?? "unknown") · (String(format: "%.1f bar", snapshot.pressure ?? 0)) · (String(format: "%.1f g/s", snapshot.flow ?? 0)) · (String(format: "%.1f °C", snapshot.groupTemperature ?? snapshot.mixTemperature ?? 0))")
                        .font(.caption)
                }
                if let error = decentClient.errorMessage { Text(error).font(.caption).foregroundStyle(.secondary) }
            }
        }
    }

    private var profileAndVideoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Community starting points").font(.subheadline.weight(.semibold))
            HStack {
                Button("Share profile") { Task { await shareProfile() } }.buttonStyle(.bordered)
                Spacer()
                Text("Equipment-specific").font(.caption).foregroundStyle(.secondary)
            }
            TextField("Bottomless video URL (optional)", text: $videoURL)
            PhotosPicker(selection: $videoSelection, matching: .videos) {
                Label(selectedVideoData == nil ? "Choose bottomless video" : "Video selected", systemImage: "video.badge.plus")
            }.onChange(of: videoSelection) { _, item in
                Task { selectedVideoData = try? await item?.loadTransferable(type: Data.self) }
            }
            HStack { ForEach(BottomlessDiagnostic.allCases) { diagnostic in Button(diagnostic.title) { if diagnostics.contains(diagnostic) { diagnostics.remove(diagnostic) } else { diagnostics.insert(diagnostic) } }.font(.caption).buttonStyle(.bordered) } }
            Button("Submit video assessment") { Task { await submitVideoAssessment() } }.buttonStyle(.bordered)
            if selectedVideoData != nil {
                Button("Upload selected video") { Task { await uploadVideoAssessment() } }.buttonStyle(.borderedProminent)
            }
            if !shareStatus.isEmpty { Text(shareStatus).font(.caption).foregroundStyle(.secondary) }
            Text("Video notes stay attached to the shot; publishing requires an explicit share action and moderation.").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func shareProfile() async {
        let profile = SharedEspressoProfile(
            title: "\(draft.machine.isEmpty ? "My" : draft.machine) espresso",
            machine: draft.machine.isEmpty ? "Unspecified machine" : draft.machine,
            doseGrams: draft.dose,
            yieldGrams: draft.yield,
            temperatureC: draft.temperature,
            pressureBar: draft.pressure,
            grindSetting: draft.grind,
            notes: draft.notes,
            author: "",
            equipmentTags: [draft.machine, draft.grinder].filter { !$0.isEmpty }
        )
        do {
            _ = try await AccountService.submitSharedEspressoProfile(profile)
            shareStatus = "Profile submitted for community review."
        } catch {
            shareStatus = "Sign in to share this profile."
        }
    }

    private func submitVideoAssessment() async {
        guard let url = URL(string: videoURL), url.scheme == "https" else {
            shareStatus = "Enter an https video URL first."
            return
        }
        do {
            try await AccountService.submitBottomlessAssessment(videoURL: url, diagnostics: Array(diagnostics), note: "Shot \(draft.id.uuidString)")
            shareStatus = "Video assessment saved privately."
        } catch {
            shareStatus = "Sign in to save this assessment."
        }
    }

    private func uploadVideoAssessment() async {
        guard let selectedVideoData else { return }
        do {
            _ = try await AccountService.uploadBottomlessVideo(data: selectedVideoData, fileExtension: "mp4", mimeType: "video/mp4", diagnostics: Array(diagnostics), note: "Shot \(draft.id.uuidString)")
            shareStatus = "Video uploaded and saved for moderation."
        } catch {
            shareStatus = "Video upload failed. Check the file size and sign-in status."
        }
    }

    private func refreshHomeConnectAppliances() async {
        isLoadingHomeConnect = true
        defer { isLoadingHomeConnect = false }
        do {
            homeConnectAppliances = try await AccountService.fetchHomeConnectAppliances()
            shareStatus = homeConnectAppliances.isEmpty ? "Home Connect is connected, but no appliances were returned." : "Home Connect appliances refreshed."
        } catch {
            homeConnectAppliances = []
        }
    }

    private func persistSnapshot() {
        var snapshot = EspressoAdvancedSnapshot()
        snapshot.telemetry = telemetry
        snapshot.refractometer = RefractometerReading(tdsPercent: tdsPercent, measuredYieldGrams: measuredYield)
        draft.advancedSnapshot = snapshot
        if let data = try? JSONEncoder().encode(snapshot) { snapshotPayload = data.base64EncodedString() }
    }

    private func loadSnapshot() {
        guard let data = Data(base64Encoded: snapshotPayload), let snapshot = try? JSONDecoder().decode(EspressoAdvancedSnapshot.self, from: data) else { return }
        telemetry = snapshot.telemetry
        tdsPercent = snapshot.refractometer?.tdsPercent ?? tdsPercent
        measuredYield = snapshot.refractometer?.measuredYieldGrams ?? measuredYield
        draft.advancedSnapshot = snapshot
    }
}
