import SwiftUI
import Combine
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

struct EspressoShot: Identifiable, Codable, Equatable {
    var id = UUID()
    var date = Date()
    var dose = 18.0
    var yield = 36.0
    var totalSeconds = 30
    var firstDripSeconds = 8
    var preinfusionSeconds = 3
    var temperature = 93.0
    var pressure: Double?
    var grinder = ""
    var burr = ""
    var basket = "18 g precision"
    var portafilter = "Bottomless"
    var machine = ""
    var grind = ""
    var taste = ""
    var rating = 0
    var notes = ""
    var advancedSnapshot: EspressoAdvancedSnapshot?

    var ratio: Double { dose > 0 ? yield / dose : 0 }
    var isPositive: Bool { rating >= 4 }
}

struct EspressoDiagnosticTag: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let systemImage: String
}

struct EspressoPuckChecklistItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    var isComplete: Bool
}

struct EspressoWorkspaceView: View {
    let accent: Color
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    @Environment(\.dismiss) private var dismiss
    @State private var mode = "Quick"
    @State private var shots: [EspressoShot] = []
    @State private var draft = EspressoShot()
    @State private var referenceID: UUID?
    @State private var isRunning = false
    @State private var elapsed = 0
    @State private var firstDrop: Int?
    @State private var liveWeight = 0.0
    @State private var weightSamples: [EspressoSample] = []
    @State private var advancedTelemetry: [EspressoTelemetrySample] = []
    @StateObject private var scaleManager = CoffeeScaleManager()
    @State private var showScalePicker = false
    @State private var didAlertTarget = false
    @State private var feedbackTrigger = 0
    @State private var showNewShot = false
    @State private var puckChecklist = [
        EspressoPuckChecklistItem(id: "dose", title: "Dose and distribute evenly", isComplete: false),
        EspressoPuckChecklistItem(id: "tamp", title: "Tamp level", isComplete: false),
        EspressoPuckChecklistItem(id: "flush", title: "Flush and lock in", isComplete: false)
    ]
    @State private var diagnosticTags: [EspressoDiagnosticTag] = []
    @State private var milkElapsed = 0
    @State private var milkRunning = false
    @State private var milkTargetTemperature = 60.0
    @State private var milkScale = 1.0
    @AppStorage("talla.espresso.waterHardnessPPM") private var waterHardnessPPM = 90.0
    @AppStorage("talla.espresso.burrRevision") private var burrRevision = 1
    private let storageKey = "talla.espresso.shots.v1"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                scoreCard
                modePicker
                if mode == "Quick" { quickMode } else { labMode }
                weightGraph
                puckPreparation
                milkSteamingCard
                maintenanceCard
                referenceComparison
                EspressoAdvancedPanel(draft: $draft, shots: $shots, telemetry: $advancedTelemetry)
                history
            }
            .padding(20)
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("Espresso Workspace")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
        .sensoryFeedback(.success, trigger: feedbackTrigger)
        .onReceive(NotificationCenter.default.publisher(for: .tallaEspressoWatchAction)) { notification in
            guard let action = notification.userInfo?["action"] as? String else { return }
            if let target = notification.userInfo?["targetYield"] as? Double { draft.yield = target }
            if action == "start" && !isRunning { startShot() }
            if action == "stop" && isRunning { finishShot() }
        }
        .onChange(of: scaleManager.weightGrams) { _, weight in
            liveWeight = max(0, weight)
            TallaWatchPhoneBridge.sendEspressoState(elapsed: elapsed, weight: liveWeight, ratio: draft.ratio, flow: scaleManager.flowRateGramsPerSecond, targetYield: draft.yield, isRunning: isRunning)
            if isRunning {
                weightSamples.append(EspressoSample(seconds: elapsed, weight: liveWeight, flow: scaleManager.flowRateGramsPerSecond))
                advancedTelemetry.append(EspressoTelemetrySample(elapsedSeconds: Double(elapsed), kind: .flow, value: scaleManager.flowRateGramsPerSecond))
            }
            if isRunning && !didAlertTarget && liveWeight >= draft.yield { didAlertTarget = true; targetReachedFeedback(); finishShot() }
        }
        .sheet(isPresented: $showNewShot) { shotEditor }
        .sheet(isPresented: $showScalePicker) {
            NavigationStack {
                List {
                    Button("Scan for Bluetooth scales") { scaleManager.scan() }
                    ForEach(scaleManager.discoveredScales) { scale in
                        Button { scaleManager.connect(to: scale.id); showScalePicker = false } label: {
                            VStack(alignment: .leading) { Text(scale.name); Text(scale.modelName).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }.navigationTitle("Connect Scale").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showScalePicker = false } } }
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if milkRunning { milkElapsed += 1 }
                guard !Task.isCancelled, isRunning else { continue }
                elapsed += 1
                if firstDrop == nil && liveWeight > 0.5 { firstDrop = elapsed }
                if liveWeight >= draft.yield { finishShot() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("DEDICATED DIAL-IN", systemImage: "dial.medium")
                .font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundStyle(accent)
            Text("Find the shot you want to drink.").font(.system(size: 25, weight: .semibold, design: .serif)).foregroundStyle(primary)
            Text("Change one variable at a time and keep the whole iteration visible.")
                .font(.system(size: 13)).foregroundStyle(secondary)
        }
    }

    private var scoreCard: some View {
        let positive = shots.filter(\.isPositive).count
        return HStack(spacing: 16) {
            Image(systemName: "target").font(.title2).foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Shots to a positive espresso").font(.subheadline.weight(.semibold)).foregroundStyle(primary)
                Text(positive > 0 ? "\((shots.firstIndex(where: { $0.isPositive }) ?? 0) + 1) shots · \(positive) positive" : "No positive shot recorded yet")
                    .font(.caption).foregroundStyle(secondary)
            }
            Spacer()
            Button { draft = EspressoShot(); showNewShot = true } label: { Image(systemName: "plus") }
                .buttonStyle(.tallaPrimary).tint(accent)
        }.padding(16).background(surface).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(accent.opacity(0.12), lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var modePicker: some View { Picker("Mode", selection: $mode) { Text("Quick").tag("Quick"); Text("Lab").tag("Lab") }.pickerStyle(.segmented).tint(accent) }

    private var quickMode: some View {
        VStack(alignment: .leading, spacing: 14) {
            metricGrid
            Button { isRunning ? finishShot() : startShot() } label: {
                Label(isRunning ? "Finish Shot" : "Start Shot", systemImage: isRunning ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity).padding(13)
            }.buttonStyle(.tallaPrimary).tint(accent)
            HStack {
                Label(scaleManager.isConnected ? (scaleManager.connectedScaleName ?? "Scale connected") : "Connect scale", systemImage: scaleManager.isConnected ? "checkmark.circle.fill" : "scalemass")
                    .font(.caption).foregroundStyle(secondary)
                Spacer()
                Button("Manage") { showScalePicker = true }.font(.caption.weight(.semibold))
            }
            if let suggestion { suggestionCard(suggestion) }
        }.padding(16).background(surface).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(accent.opacity(0.12), lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var puckPreparation: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("Puck preparation").font(.headline).foregroundStyle(primary); Spacer(); Text("\(puckChecklist.filter(\.isComplete).count)/\(puckChecklist.count)").font(.caption).foregroundStyle(secondary) }
            ForEach(puckChecklist.indices, id: \.self) { index in
                Button { puckChecklist[index].isComplete.toggle() } label: {
                    Label(puckChecklist[index].title, systemImage: puckChecklist[index].isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline).foregroundStyle(puckChecklist[index].isComplete ? accent : primary)
                }.buttonStyle(.plain)
            }
            HStack(spacing: 6) {
                ForEach([("sour", "Sour", "drop.triangle"), ("bitter", "Bitter", "flame"), ("channeling", "Channeling", "waveform.path.ecg")], id: \.0) { tag in
                    let active = diagnosticTags.contains { $0.id == tag.0 }
                    Button { toggleDiagnostic(tag.0, title: tag.1, icon: tag.2) } label: {
                        Text(tag.1).font(.caption.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 6).background(active ? accent.opacity(0.2) : background.opacity(0.5)).clipShape(Capsule())
                    }.buttonStyle(.plain)
                }
            }
        }.padding(16).background(surface).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var maintenanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Maintenance").font(.headline).foregroundStyle(primary); Spacer(); Text(maintenanceMessage).font(.caption.weight(.semibold)).foregroundStyle(accent) }
            HStack { Text("Water hardness").font(.caption).foregroundStyle(secondary); Spacer(); Stepper("\(Int(waterHardnessPPM)) ppm", value: $waterHardnessPPM, in: 0...500, step: 10).font(.caption) }
            Text("Shot count drives group-head cleaning; hardness drives descaling. Grinder burr changes remain attached to each shot's setting history.").font(.caption).foregroundStyle(secondary)
        }.padding(16).background(surface).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var maintenanceMessage: String {
        if shots.count >= 200 { return "Clean group head now" }
        if waterHardnessPPM >= 120 && shots.count >= 100 { return "Descale soon" }
        return "On track"
    }

    private var milkSteamingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("Milk steaming").font(.headline).foregroundStyle(primary); Spacer(); Text(String(format: "%02d:%02d", milkElapsed / 60, milkElapsed % 60)).font(.caption.monospacedDigit()).foregroundStyle(accent) }
            HStack { Text("Target temperature").font(.caption).foregroundStyle(secondary); Spacer(); Stepper("\(Int(milkTargetTemperature)) °C", value: $milkTargetTemperature, in: 50...75, step: 1).font(.caption) }
            HStack { Text("Drink scale").font(.caption).foregroundStyle(secondary); Spacer(); Stepper(String(format: "%.1fx", milkScale), value: $milkScale, in: 0.5...2.0, step: 0.1).font(.caption) }
            Button { milkRunning.toggle() } label: { Label(milkRunning ? "Pause steam timer" : "Start steam timer", systemImage: milkRunning ? "pause.fill" : "play.fill").font(.caption.weight(.semibold)) }.buttonStyle(.tallaPrimary).tint(accent)
            Text(String(format: "For this shot: %.1f g espresso · %.0f °C milk target", draft.yield * milkScale, milkTargetTemperature)).font(.caption).foregroundStyle(secondary)
        }.padding(16).background(surface).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func toggleDiagnostic(_ id: String, title: String, icon: String) {
        if diagnosticTags.contains(where: { $0.id == id }) { diagnosticTags.removeAll { $0.id == id } }
        else { diagnosticTags.append(EspressoDiagnosticTag(id: id, title: title, systemImage: icon)) }
    }

    private var labMode: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment & variables").font(.headline).foregroundStyle(primary)
            editorField("Machine", text: $draft.machine); editorField("Grinder", text: $draft.grinder)
            editorField("Burr", text: $draft.burr); editorField("Basket", text: $draft.basket)
            editorField("Portafilter", text: $draft.portafilter); editorField("Grind setting", text: $draft.grind)
            HStack {
                Text("Burr revision \(burrRevision)").font(.caption).foregroundStyle(secondary)
                Spacer()
                Button("Record burr change") { burrRevision += 1; draft.burr = "Revision \(burrRevision)" }.font(.caption.weight(.semibold))
            }
            metricGrid
            if let suggestion { suggestionCard(suggestion) }
            Button("Save iteration") { finishShot() }.buttonStyle(.tallaPrimary).tint(accent)
        }.padding(16).background(surface).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(accent.opacity(0.12), lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metric("Dose", String(format: "%.1f g", draft.dose)); metric("Yield", String(format: "%.1f g", liveWeight > 0 ? liveWeight : draft.yield))
            metric("Ratio", String(format: "1:%.2f", draft.ratio)); metric("Time", "\(isRunning ? elapsed : draft.totalSeconds)s")
            metric("First drip", "\(firstDrop ?? draft.firstDripSeconds)s"); metric("Pre-infusion", "\(draft.preinfusionSeconds)s")
            metric("Temperature", String(format: "%.0f °C", draft.temperature)); metric("Pressure", draft.pressure.map { String(format: "%.1f bar", $0) } ?? "—")
        }
    }

    private func metric(_ title: String, _ value: String) -> some View { VStack(alignment: .leading, spacing: 3) { Text(title).font(.caption).foregroundStyle(secondary); Text(value).font(.headline.monospacedDigit()).foregroundStyle(primary) }.frame(maxWidth: .infinity, alignment: .leading).padding(10).background(background.opacity(0.55)).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) }

    private var suggestion: String? {
        guard let last = shots.last else { return "Record a shot to get a one-variable recommendation." }
        if last.rating >= 4 { return "Keep this recipe. Select it as your reference shot and repeat once to confirm." }
        if last.taste.localizedCaseInsensitiveContains("sour") { return "Next: grind one small step finer. Keep dose, yield and temperature unchanged." }
        if last.taste.localizedCaseInsensitiveContains("bitter") || last.taste.localizedCaseInsensitiveContains("dry") { return "Next: grind one small step coarser. Keep every other variable unchanged." }
        return "Next: adjust yield by 2 g only, then taste again."
    }

    private func suggestionCard(_ text: String) -> some View { Label(text, systemImage: "wand.and.stars").font(.subheadline).foregroundStyle(primary).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(accent.opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)) }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("Dial-in history").font(.headline).foregroundStyle(primary); Spacer(); Text("\(shots.count) shots").font(.caption).foregroundStyle(secondary) }
            ForEach(shots) { shot in
                let shotNumber = (shots.firstIndex(of: shot) ?? 0) + 1
                let ratio = String(format: "%.2f", shot.ratio)
                let grind = shot.grind.isEmpty ? "grind unchanged" : shot.grind
                HStack(spacing: 10) { Text("#\(shotNumber)").font(.caption.weight(.bold)).foregroundStyle(accent); VStack(alignment: .leading) { Text("1:\(ratio) · \(shot.totalSeconds)s · \(grind)").font(.subheadline).foregroundStyle(primary); Text(shot.taste.isEmpty ? "No taste note" : shot.taste).font(.caption).foregroundStyle(secondary) }; Spacer(); Text(String(repeating: "★", count: shot.rating)).foregroundStyle(accent) }
                .padding(11).background(surface).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(referenceID == shot.id ? RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(accent, lineWidth: 1.5) : nil)
                .onTapGesture { referenceID = shot.id }
            }
        }
    }

    private var shotEditor: some View {
        NavigationStack { Form {
            Section("Recipe") { DoubleField("Dose (g)", value: $draft.dose); DoubleField("Yield (g)", value: $draft.yield); Stepper("Total time: \(draft.totalSeconds)s", value: $draft.totalSeconds, in: 1...120); Stepper("First drip: \(draft.firstDripSeconds)s", value: $draft.firstDripSeconds, in: 0...60); Stepper("Pre-infusion: \(draft.preinfusionSeconds)s", value: $draft.preinfusionSeconds, in: 0...30); DoubleField("Temperature (°C)", value: $draft.temperature) }
            Section("Taste") { TextField("What did it taste like? (sour, bitter, sweet…)", text: $draft.taste); Stepper("Rating: \(draft.rating)/5", value: $draft.rating, in: 0...5); TextField("Notes", text: $draft.notes) }
        }.navigationTitle("New shot").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { showNewShot = false; finishShot() } } } }
    }

    private func editorField(_ title: String, text: Binding<String>) -> some View { TextField(title, text: text).textFieldStyle(.talla) }
    private func startShot() { elapsed = 0; firstDrop = nil; liveWeight = 0; weightSamples = []; advancedTelemetry = []; didAlertTarget = false; isRunning = true; advancedTelemetry.append(EspressoTelemetrySample(elapsedSeconds: 0, kind: .temperature, value: draft.temperature)); if let pressure = draft.pressure { advancedTelemetry.append(EspressoTelemetrySample(elapsedSeconds: 0, kind: .pressure, value: pressure)) }; TallaWatchPhoneBridge.sendEspressoState(elapsed: 0, weight: 0, ratio: draft.ratio, flow: 0, targetYield: draft.yield, isRunning: true); if scaleManager.isConnected { scaleManager.tare(); scaleManager.startTimer() } }
    private func finishShot() {
        guard !isRunning || elapsed > 0 else { return }
        isRunning = false
        if scaleManager.isConnected { scaleManager.stopTimer() }
        draft.totalSeconds = elapsed > 0 ? elapsed : draft.totalSeconds
        draft.firstDripSeconds = firstDrop ?? draft.firstDripSeconds
        draft.yield = liveWeight > 0 ? liveWeight : draft.yield
        if draft.burr.isEmpty { draft.burr = "Revision \(burrRevision)" }
        var snapshot = draft.advancedSnapshot ?? EspressoAdvancedSnapshot()
        snapshot.telemetry = advancedTelemetry
        draft.advancedSnapshot = snapshot
        let completedShot = draft
        shots.append(completedShot)
        TallaWatchPhoneBridge.sendEspressoState(elapsed: elapsed, weight: completedShot.yield, ratio: completedShot.ratio, flow: 0, targetYield: completedShot.yield, isRunning: false)
        save()
        syncCompletedShot(completedShot)
        scheduleMaintenanceReminderIfNeeded()
        draft = EspressoShot()
        liveWeight = 0
        weightSamples = []
        advancedTelemetry = []
    }

    private func syncCompletedShot(_ shot: EspressoShot) {
        guard !AccountService.accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let formatter = ISO8601DateFormatter()
        let entry = ContentView.BrewJournalEntry(
            id: shot.id,
            title: shot.machine.isEmpty ? "Espresso shot" : "\(shot.machine) espresso",
            method: "Espresso",
            coffeeGrams: shot.dose,
            ratio: shot.ratio,
            waterGrams: shot.yield,
            brewTimeSeconds: shot.totalSeconds,
            rating: shot.rating,
            notes: [shot.taste, shot.notes].filter { !$0.isEmpty }.joined(separator: " · "),
            createdAt: formatter.string(from: shot.date)
        )
        Task { _ = try? await AccountService.saveBrewJournal(entry) }
    }
    private func scheduleMaintenanceReminderIfNeeded() {
#if canImport(UserNotifications)
        let count = shots.count
        guard count == 100 || count == 200 || (waterHardnessPPM >= 120 && count % 50 == 0) else { return }
        let content = UNMutableNotificationContent()
        content.title = count >= 200 ? "Clean your espresso machine" : "Espresso maintenance reminder"
        content.body = waterHardnessPPM >= 120 && count >= 100 ? "Check the group head and plan a descale for your water profile." : "Your shot count suggests it is time to clean the group head."
        content.sound = .default
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let request = UNNotificationRequest(identifier: "espresso-maintenance-\(count)", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
            UNUserNotificationCenter.current().add(request)
        }
#endif
    }
    private func targetReachedFeedback() {
        feedbackTrigger += 1
#if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(1057)
#endif
#if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "Espresso target reached"
        content.body = String(format: "%.1f g yield reached.", liveWeight)
        content.sound = .default
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "espresso-target-\(UUID().uuidString)", content: content, trigger: nil))
        }
#endif
    }
    private func load() { if let data = UserDefaults.standard.data(forKey: storageKey), let saved = try? JSONDecoder().decode([EspressoShot].self, from: data) { shots = saved; if let last = saved.last { draft.machine = last.machine; draft.grinder = last.grinder; draft.burr = last.burr; draft.basket = last.basket; draft.portafilter = last.portafilter } } }
    private func save() { if let data = try? JSONEncoder().encode(shots) { UserDefaults.standard.set(data, forKey: storageKey) }; UserDefaults.standard.set(draft.machine, forKey: "talla.espresso.machine"); UserDefaults.standard.set(draft.grinder, forKey: "talla.espresso.grinder"); UserDefaults.standard.set(draft.burr, forKey: "talla.espresso.burr"); UserDefaults.standard.set(draft.basket, forKey: "talla.espresso.basket"); UserDefaults.standard.set(draft.portafilter, forKey: "talla.espresso.portafilter") }
    private var referenceComparison: some View {
        Group {
            if let referenceID, let reference = shots.first(where: { $0.id == referenceID }), let current = shots.last {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reference overlay").font(.headline).foregroundStyle(primary)
                    HStack { comparison("Yield", current.yield, reference.yield, "%.1f g"); comparison("Ratio", current.ratio, reference.ratio, "1:%.2f"); comparison("Time", Double(current.totalSeconds), Double(reference.totalSeconds), "%.0f s") }
                }.padding(16).background(surface).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    private func comparison(_ title: String, _ current: Double, _ reference: Double, _ format: String) -> some View { VStack(alignment: .leading) { Text(title).font(.caption).foregroundStyle(secondary); Text(String(format: format, current)).font(.subheadline.weight(.semibold)).foregroundStyle(primary); Text("ref " + String(format: format, reference)).font(.caption).foregroundStyle(secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
    private var weightGraph: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Weight & flow").font(.headline).foregroundStyle(primary); Spacer(); Text(scaleManager.isConnected ? "LIVE" : "SHOT CURVE").font(.caption.weight(.bold)).foregroundStyle(accent) }
            HStack(spacing: 14) {
                Label("Weight", systemImage: "circle.fill").font(.caption).foregroundStyle(accent)
                Label("Flow", systemImage: "circle.fill").font(.caption).foregroundStyle(.blue)
                Spacer()
            }
            GeometryReader { proxy in
                ZStack {
                    espressoCurve(samples: weightSamples.map { ($0.weight, $0.seconds) }, maxValue: max(max(draft.yield, weightSamples.map(\.weight).max() ?? draft.yield), 1), size: proxy.size, color: accent)
                    espressoCurve(samples: weightSamples.map { ($0.flow, $0.seconds) }, maxValue: max(weightSamples.map(\.flow).max() ?? 1, 1), size: proxy.size, color: .blue)
                }
            }.frame(height: 90).background(background.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(scaleManager.isConnected ? String(format: "%.1f g · %.1f g/s", liveWeight, scaleManager.flowRateGramsPerSecond) : "Connect a scale to capture a live weight curve.").font(.caption).foregroundStyle(secondary)
        }.padding(16).background(surface).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private func espressoCurve(samples: [(Double, Int)], maxValue: Double, size: CGSize, color: Color) -> some View {
        Path { path in
            guard samples.count > 1 else { return }
            for (index, sample) in samples.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(max(samples.count - 1, 1))
                let y = size.height * (1 - CGFloat(sample.0 / maxValue))
                index == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
            }
        }.stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
    }
    private struct EspressoSample { let seconds: Int; let weight: Double; let flow: Double }
    private struct DoubleField: View { let title: String; @Binding var value: Double; init(_ title: String, value: Binding<Double>) { self.title = title; self._value = value }; var body: some View { HStack { Text(title); Spacer(); TextField("0", value: $value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90) } } }
}
