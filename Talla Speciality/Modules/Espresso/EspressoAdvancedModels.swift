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

    var title: String {
        switch self {
        case .pressure: return "Pressure"
        case .flow: return "Flow"
        case .temperature: return "Temperature"
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

    var supportTitle: String {
        switch supportLevel {
        case .officialSDK: return "Official SDK"
        case .officialCloudAPI: return "Official cloud API"
        case .officialCompanionApp: return "Companion app"
        case .manualOnly: return "Manual capture"
        }
    }

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

    @State private var tdsPercent = 9.0
    @State private var measuredYield = 36.0
    @State private var selectedKind: EspressoTelemetryKind = .pressure
    @State private var sampleValue = 9.0
    @State private var sampleSeconds = 0.0
    @State private var videoURL = ""
    @State private var videoSelection: PhotosPickerItem?
    @State private var selectedVideoData: Data?
    @State private var diagnostics: Set<BottomlessDiagnostic> = []
    @State private var isShowingProfile = false
    @State private var shareStatus = ""
    @AppStorage("talla.espresso.advanced.snapshot.v1") private var snapshotPayload = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ADVANCED ESPRESSO", systemImage: "waveform.path.ecg.rectangle")
                .font(.caption.weight(.bold)).tracking(1.1).foregroundStyle(advancedAccent)
            Text("Measure first. Change one variable at a time.")
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            advancedCard(telemetryEditor)
            advancedCard(overlaySummary)
            advancedCard(refractometerCard)
            advancedCard(profileAndVideoCard)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            loadSnapshot()
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

    private let advancedAccent = Color(red: 0.72, green: 0.48, blue: 0.20)

    private func advancedCard<Content: View>(_ content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground).opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.black.opacity(0.06), lineWidth: 1))
    }

    private var telemetryEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Sensor streams", detail: telemetry.isEmpty ? "No samples yet" : "\(telemetry.count) captured")
            Picker("Stream", selection: $selectedKind) {
                ForEach(EspressoTelemetryKind.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            HStack(spacing: 8) {
                labeledNumberField("Value", value: $sampleValue)
                Text(selectedKind.unit).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                labeledNumberField("Seconds", value: $sampleSeconds)
                Button {
                    telemetry.append(.init(elapsedSeconds: sampleSeconds, kind: selectedKind, value: sampleValue))
                    persistSnapshot()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.borderedProminent).tint(advancedAccent)
                .accessibilityLabel("Add sensor sample")
            }
        }
    }

    private var overlaySummary: some View {
        let overlay = EspressoReferenceOverlay(samples: telemetry)
        return VStack(alignment: .leading, spacing: 5) {
            sectionHeading("Pressure / flow / temperature", detail: "Reference overlay")
            Text("Pressure \(overlay.pressure.count) · Flow \(overlay.flow.count) · Temperature \(overlay.temperature.count)")
                .font(.caption).foregroundStyle(.secondary)
            if let maxPressure = overlay.pressure.map(\.value).max() { Text("Peak pressure \(String(format: "%.1f bar", maxPressure))").font(.caption) }
            if overlay.isEmpty { Text("Add readings above to build the shot overlay.").font(.caption).foregroundStyle(.secondary) }
        }
    }

    private var refractometerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Refractometer", detail: "Optional")
            HStack(spacing: 10) {
                labeledNumberField("TDS %", value: $tdsPercent)
                labeledNumberField("Yield (g)", value: $measuredYield)
            }
            Button("Save reading") { persistSnapshot() }
                .font(.subheadline.weight(.semibold)).foregroundStyle(advancedAccent)
            if let ey = EspressoExtractionMath.extractionYieldPercent(doseGrams: draft.dose, beverageYieldGrams: measuredYield, tdsPercent: tdsPercent) {
                Text(String(format: "Extraction yield %.2f%%", ey)).font(.subheadline.weight(.semibold))
            }
        }
    }

    private var profileAndVideoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Community starting points", detail: "Share when ready")
            Button { Task { await shareProfile() } } label: {
                Label("Share espresso profile", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }.buttonStyle(.bordered)
            TextField("Video URL (optional)", text: $videoURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            PhotosPicker(selection: $videoSelection, matching: .videos) {
                Label(selectedVideoData == nil ? "Choose bottomless video" : "Video selected", systemImage: "video.badge.plus")
                    .frame(maxWidth: .infinity)
            }.onChange(of: videoSelection) { _, item in
                Task { selectedVideoData = try? await item?.loadTransferable(type: Data.self) }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(BottomlessDiagnostic.allCases) { diagnostic in
                    let selected = diagnostics.contains(diagnostic)
                    Button {
                        if selected { diagnostics.remove(diagnostic) } else { diagnostics.insert(diagnostic) }
                    } label: {
                        Text(diagnostic.title).font(.caption.weight(.semibold)).lineLimit(1).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(selected ? advancedAccent : .secondary)
                }
            }
            Button("Submit video assessment") { Task { await submitVideoAssessment() } }.buttonStyle(.bordered)
            if selectedVideoData != nil {
                Button("Upload selected video") { Task { await uploadVideoAssessment() } }.buttonStyle(.borderedProminent).tint(advancedAccent)
            }
            if !shareStatus.isEmpty { Text(shareStatus).font(.caption).foregroundStyle(.secondary) }
            Text("Video notes stay attached to the shot; publishing requires an explicit share action and moderation.").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func sectionHeading(_ title: String, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
        }
    }

    private func labeledNumberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            TextField(title, value: value, format: .number)
                .keyboardType(.decimalPad)
                .font(.body.monospacedDigit())
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
