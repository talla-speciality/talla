import SwiftUI
import Observation
#if canImport(WatchKit)
import WatchKit
#endif
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

struct WatchBrewStep: Identifiable, Equatable {
    let id: Int
    let time: Int
    let title: String
    let detail: String
    let waterTarget: Int?
}

struct WatchBrewRecipe {
    let methodName = "Solo Dripper"
    let coffeeAmount = 20
    let ratio = 16
    let totalWater = 320
    let totalSeconds = 210

    var steps: [WatchBrewStep] {
        [
            WatchBrewStep(
                id: 0,
                time: 0,
                title: "Prepare your bed",
                detail: "Level the coffee, start the timer, and get ready to bloom.",
                waterTarget: nil
            ),
            WatchBrewStep(
                id: 1,
                time: 10,
                title: "Pour to 60 g",
                detail: "Bloom evenly and let the coffee open.",
                waterTarget: 60
            ),
            WatchBrewStep(
                id: 2,
                time: 45,
                title: "Continue to 180 g",
                detail: "Pour slowly from the centre outward.",
                waterTarget: 180
            ),
            WatchBrewStep(
                id: 3,
                time: 90,
                title: "Finish at 320 g",
                detail: "Keep the stream steady and avoid the paper edge.",
                waterTarget: 320
            ),
            WatchBrewStep(
                id: 4,
                time: 150,
                title: "Drawdown",
                detail: "Let the bed drain flat and clean.",
                waterTarget: 320
            ),
            WatchBrewStep(
                id: 5,
                time: 210,
                title: "Brew ready",
                detail: "Your brew is ready. Enjoy it slowly.",
                waterTarget: 320
            )
        ]
    }
}

struct TallaWatchSnapshot {
    var email: String = ""
    var points: Int = 0
    var tier: String = "Bronze"
    var nextReward: String = "Open Talla on iPhone to check rewards"
    var memberID: String = ""
    var favoriteCount: Int = 0
    var recentCount: Int = 0
    var savedCartCount: Int = 0
    var lastUpdated: Date?

    var isSignedIn: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayEmail: String {
        guard isSignedIn else { return "Connect Talla" }
        return email
    }

    var progressTarget: Int {
        max(((points / 50) + 1) * 50, 50)
    }

    var progressValue: Double {
        min(Double(points % 50) / 50, 1)
    }

    var beansToNextReward: Int {
        let remainder = points % 50
        return remainder == 0 && points > 0 ? 0 : 50 - remainder
    }
}

@Observable
@MainActor
final class TallaWatchStore: NSObject {
    var snapshot = TallaWatchSnapshot()
    var statusText = "Open Talla on your iPhone and sign in to sync."
    var isSyncing = false
    var lastActionText = "Ready"

#if canImport(WatchConnectivity)
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }
#endif

    override init() {
        super.init()
        activate()
    }

    var canReachPhone: Bool {
#if canImport(WatchConnectivity)
        session?.isReachable == true
#else
        false
#endif
    }

    func activate() {
#if canImport(WatchConnectivity)
        guard let session else { return }
        session.delegate = self
        session.activate()
#endif
    }

    func refresh() {
#if canImport(WatchConnectivity)
        guard let session else {
            statusText = "Watch sync is unavailable."
            return
        }

        isSyncing = true
        lastActionText = "Syncing"

        guard session.isReachable else {
            isSyncing = false
            statusText = "Open Talla on your iPhone and sign in to sync."
            lastActionText = "Connect Talla"
            return
        }

        session.sendMessage(["request": "snapshot"], replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.apply(reply)
                self?.isSyncing = false
                self?.statusText = "Synced from iPhone."
                self?.lastActionText = "Synced"
            }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in
                self?.isSyncing = false
                self?.statusText = "Could not reach iPhone."
                self?.lastActionText = "Sync failed"
            }
        })
#else
        statusText = "Watch sync is unavailable."
#endif
    }

    func openOnPhone(_ destination: String) {
#if canImport(WatchConnectivity)
        guard let session, session.isReachable else {
            statusText = "Open Talla on your iPhone and sign in to sync."
            lastActionText = "Connect Talla"
            return
        }

        lastActionText = "Opening"
        session.sendMessage(["open": destination], replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.apply(reply)
                self?.statusText = "Sent to iPhone."
                self?.lastActionText = "Sent"
            }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in
                self?.statusText = "Could not open iPhone app."
                self?.lastActionText = "Failed"
            }
        })
#else
        statusText = "Watch sync is unavailable."
#endif
    }

    func sendBrewActivity(
        action: String,
        recipe: WatchBrewRecipe,
        elapsedSeconds: Int,
        currentStep: WatchBrewStep,
        nextStep: WatchBrewStep?,
        currentWaterGrams: Int,
        isPaused: Bool
    ) {
#if canImport(WatchConnectivity)
        guard let session, session.isReachable else {
            statusText = "Open Talla on iPhone to show this brew as a Live Activity."
            lastActionText = "Live Activity waiting"
            return
        }

        let payload: [String: Any] = [
            "brewActivity": action,
            "methodName": recipe.methodName,
            "coffeeGrams": Double(recipe.coffeeAmount),
            "ratio": Double(recipe.ratio),
            "totalWaterGrams": Double(recipe.totalWater),
            "totalSeconds": recipe.totalSeconds,
            "elapsedSeconds": elapsedSeconds,
            "currentStep": currentStep.title,
            "nextStep": nextStep?.title ?? "Your brew is ready. Enjoy it slowly.",
            "currentWaterGrams": Double(currentWaterGrams),
            "isPaused": isPaused,
            "stepTimes": recipe.steps.map(\.time),
            "stepTitles": recipe.steps.map(\.title),
            "stepWaterTargets": recipe.steps.map { Double($0.waterTarget ?? -1) }
        ]

        session.sendMessage(payload, replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.apply(reply)
                if let status = reply["brewActivityStatus"] as? String {
                    self?.statusText = status == "started" || status == "updated"
                        ? "Brew Live Activity is running on iPhone."
                        : "Brew Live Activity status: \(status)."
                    self?.lastActionText = "Live Activity"
                }
            }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in
                self?.statusText = "Open Talla on iPhone to show this brew as a Live Activity."
                self?.lastActionText = "Live Activity waiting"
            }
        })
#else
        statusText = "Watch sync is unavailable."
#endif
    }

    private func apply(_ payload: [String: Any]) {
        snapshot = TallaWatchSnapshot(
            email: payload["email"] as? String ?? "",
            points: payload["points"] as? Int ?? 0,
            tier: payload["tier"] as? String ?? "Bronze",
            nextReward: payload["nextReward"] as? String ?? "Open Talla on iPhone to check rewards",
            memberID: payload["memberID"] as? String ?? "",
            favoriteCount: payload["favoriteCount"] as? Int ?? 0,
            recentCount: payload["recentCount"] as? Int ?? 0,
            savedCartCount: payload["savedCartCount"] as? Int ?? 0,
            lastUpdated: (payload["lastUpdated"] as? Double).flatMap { $0 > 0 ? Date(timeIntervalSince1970: $0) : nil }
        )
    }
}

#if canImport(WatchConnectivity)
extension TallaWatchStore: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        Task { @MainActor in
            if error != nil {
                statusText = "Open Talla on your iPhone and sign in to sync."
                lastActionText = "Connect Talla"
            } else {
                refresh()
            }
        }
    }
}
#endif

struct ContentView: View {
    @State private var store = TallaWatchStore()
    @State private var isBrewPresented = false

    private let accent = Color(red: 0.79, green: 0.59, blue: 0.35)
    private let watchBrewRecipe = WatchBrewRecipe()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    if store.snapshot.isSignedIn {
                        rewardHero
                        continueBrewCard
                        watchPrimaryActions
                        secondaryRowAction("Open Talla on iPhone", icon: "iphone", destination: "home")
                        syncFooter
                    } else {
                        continueBrewCard
                        connectTallaCard
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Talla")
            .fullScreenCover(isPresented: $isBrewPresented) {
                WatchBrewSessionView(recipe: watchBrewRecipe) { action, elapsedSeconds, currentStep, nextStep, currentWaterGrams, isPaused in
                    store.sendBrewActivity(
                        action: action,
                        recipe: watchBrewRecipe,
                        elapsedSeconds: elapsedSeconds,
                        currentStep: currentStep,
                        nextStep: nextStep,
                        currentWaterGrams: currentWaterGrams,
                        isPaused: isPaused
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.refresh()
                    } label: {
                        if store.isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(store.isSyncing)
                }
            }
        }
    }

    private var continueBrewCard: some View {
        Button {
            isBrewPresented = true
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue Last Brew")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.primary)
                    Text("\(watchBrewRecipe.methodName) · \(watchBrewRecipe.coffeeAmount) g · 1:\(watchBrewRecipe.ratio)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(accent, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("TALLA")
                    .font(.system(size: 18, weight: .black, design: .serif))
                Text(store.snapshot.isSignedIn ? store.snapshot.tier : "Connect Talla")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(store.canReachPhone ? .green : .orange)
                .frame(width: 6, height: 6)
            Text(store.snapshot.isSignedIn ? (store.canReachPhone ? "Live" : "Phone") : "Connect")
                .font(.system(size: 9, weight: .bold))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.09), in: Capsule())
    }

    private var rewardHero: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.20), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: store.snapshot.progressValue)
                        .stroke(accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(store.snapshot.points)")
                        .font(.system(size: 20, weight: .black, design: .serif))
                        .minimumScaleFactor(0.6)
                }
                .frame(width: 66, height: 66)

                VStack(alignment: .leading, spacing: 3) {
                    Text("The Talla Club")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                    Text("\(store.snapshot.points) Beans")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                    Text(store.snapshot.beansToNextReward == 0 ? "Reward ready" : "\(store.snapshot.beansToNextReward) Beans to your next reward")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.22), Color.white.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var connectTallaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "iphone")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 32, height: 32)
                    .background(accent, in: Circle())

                Text("Connect Talla")
                    .font(.system(size: 15, weight: .black, design: .serif))
                    .lineLimit(1)
            }

            Text("Open Talla on your iPhone and sign in to sync rewards, saved items, and orders.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                store.openOnPhone("account")
            } label: {
                HStack(spacing: 6) {
                    Text("Open on iPhone")
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.forward")
                }
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.20), Color.white.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var watchPrimaryActions: some View {
        HStack(spacing: 7) {
            localCompactAction("Brew", icon: "drop.fill") {
                isBrewPresented = true
            }
            compactAction("Shelf", icon: "books.vertical.fill", destination: "shelf")
        }
    }

    private func localCompactAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.borderedProminent)
        .tint(accent)
    }

    private func compactAction(_ title: String, icon: String, destination: String) -> some View {
        Button {
            store.openOnPhone(destination)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.borderedProminent)
        .tint(accent)
    }

    private func secondaryRowAction(_ title: String, icon: String, destination: String) -> some View {
        Button {
            store.openOnPhone(destination)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accent)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var syncFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: store.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.seal.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent)
                Text(store.lastActionText)
                    .font(.system(size: 10, weight: .bold))
            }

            Text(store.statusText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let lastUpdated = store.snapshot.lastUpdated {
                Text(lastUpdated, style: .relative)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 2)
    }
}

struct WatchBrewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let recipe: WatchBrewRecipe
    let liveActivityHandler: (String, Int, WatchBrewStep, WatchBrewStep?, Int, Bool) -> Void

    @State private var isRunning = true
    @State private var startDate = Date()
    @State private var elapsedWhenPaused = 0
    @State private var lastHapticStepID: Int?

    private let accent = Color(red: 0.79, green: 0.59, blue: 0.35)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = elapsedSeconds(at: context.date)
            let currentStep = currentStep(for: elapsed)
            let nextStep = nextStep(after: elapsed)
            let progress = Double(elapsed) / Double(recipe.totalSeconds)
            let waterTarget = currentWaterTarget(for: elapsed)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sessionHeader(elapsed: elapsed)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentStep.title)
                            .font(.system(size: 22, weight: .black, design: .serif))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        Text(currentStep.detail)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    progressTimer(elapsed: elapsed, progress: progress)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Water target")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(accent)
                        Text("\(waterTarget) / \(recipe.totalWater) g")
                            .font(.system(size: 18, weight: .black))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if let nextStep {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Next")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(accent)
                            Text("\(nextStep.title) at \(formattedTime(nextStep.time))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    controls(elapsed: elapsed)
                }
                .padding(.vertical, 10)
            }
            .onChange(of: currentStep.id) { _, newStepID in
                guard lastHapticStepID != newStepID else { return }
                lastHapticStepID = newStepID
                playStepHaptic()
                sendLiveActivityUpdate(
                    action: elapsed >= recipe.totalSeconds ? "end" : "update",
                    elapsedSeconds: elapsed,
                    currentStep: currentStep,
                    nextStep: nextStep,
                    currentWaterGrams: waterTarget,
                    isPaused: !isRunning || elapsed >= recipe.totalSeconds
                )
            }
        }
        .onAppear {
            startDate = .now
            elapsedWhenPaused = 0
            isRunning = true
            lastHapticStepID = currentStep(for: 0).id
            sendLiveActivityUpdate(
                action: "start",
                elapsedSeconds: 0,
                currentStep: currentStep(for: 0),
                nextStep: nextStep(after: 0),
                currentWaterGrams: 0,
                isPaused: false
            )
        }
    }

    private func sessionHeader(elapsed: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Guided Brew")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(accent)
                Text(recipe.methodName)
                    .font(.system(size: 16, weight: .black))
                    .lineLimit(1)
                Text("\(recipe.coffeeAmount) g · 1:\(recipe.ratio)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .black))
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .disabled(isRunning && elapsed < recipe.totalSeconds)
        }
    }

    private func progressTimer(elapsed: Int, progress: Double) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(accent.opacity(0.20), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(formattedTime(elapsed))
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 4) {
                Text(elapsed >= recipe.totalSeconds ? "Done" : (isRunning ? "Brewing" : "Paused"))
                    .font(.system(size: 12, weight: .black))
                Text("\(formattedTime(recipe.totalSeconds - min(elapsed, recipe.totalSeconds))) remaining")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func controls(elapsed: Int) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                Button {
                    togglePause(elapsed: elapsed)
                } label: {
                    Label(isRunning ? "Pause" : "Resume", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .disabled(elapsed >= recipe.totalSeconds)

                Button {
                    skip(elapsed: elapsed)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(accent)
                .disabled(elapsed >= recipe.totalSeconds)
            }

            HStack(spacing: 7) {
                Button {
                    restart()
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(accent)

                Button(role: .destructive) {
                    let elapsed = elapsedSeconds(at: .now)
                    sendLiveActivityUpdate(
                        action: "end",
                        elapsedSeconds: elapsed,
                        currentStep: currentStep(for: elapsed),
                        nextStep: nextStep(after: elapsed),
                        currentWaterGrams: currentWaterTarget(for: elapsed),
                        isPaused: true
                    )
                    dismiss()
                } label: {
                    Text("End")
                        .font(.system(size: 10, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func elapsedSeconds(at date: Date) -> Int {
        guard isRunning else {
            return min(elapsedWhenPaused, recipe.totalSeconds)
        }
        return min(elapsedWhenPaused + Int(date.timeIntervalSince(startDate)), recipe.totalSeconds)
    }

    private func currentStep(for elapsed: Int) -> WatchBrewStep {
        recipe.steps.last(where: { $0.time <= elapsed }) ?? recipe.steps[0]
    }

    private func nextStep(after elapsed: Int) -> WatchBrewStep? {
        recipe.steps.first(where: { $0.time > elapsed })
    }

    private func currentWaterTarget(for elapsed: Int) -> Int {
        recipe.steps
            .filter { $0.time <= elapsed }
            .compactMap(\.waterTarget)
            .last ?? 0
    }

    private func togglePause(elapsed: Int) {
        if isRunning {
            elapsedWhenPaused = elapsed
            isRunning = false
        } else {
            startDate = .now
            isRunning = true
        }
        sendLiveActivityUpdate(
            action: "update",
            elapsedSeconds: elapsed,
            currentStep: currentStep(for: elapsed),
            nextStep: nextStep(after: elapsed),
            currentWaterGrams: currentWaterTarget(for: elapsed),
            isPaused: !isRunning
        )
    }

    private func skip(elapsed: Int) {
        elapsedWhenPaused = nextStep(after: elapsed)?.time ?? recipe.totalSeconds
        startDate = .now
        if elapsedWhenPaused >= recipe.totalSeconds {
            isRunning = false
        }
        playStepHaptic()
        sendLiveActivityUpdate(
            action: elapsedWhenPaused >= recipe.totalSeconds ? "end" : "update",
            elapsedSeconds: elapsedWhenPaused,
            currentStep: currentStep(for: elapsedWhenPaused),
            nextStep: nextStep(after: elapsedWhenPaused),
            currentWaterGrams: currentWaterTarget(for: elapsedWhenPaused),
            isPaused: !isRunning
        )
    }

    private func restart() {
        elapsedWhenPaused = 0
        startDate = .now
        isRunning = true
        lastHapticStepID = currentStep(for: 0).id
        playStepHaptic()
        sendLiveActivityUpdate(
            action: "start",
            elapsedSeconds: 0,
            currentStep: currentStep(for: 0),
            nextStep: nextStep(after: 0),
            currentWaterGrams: 0,
            isPaused: false
        )
    }

    private func formattedTime(_ seconds: Int) -> String {
        let clampedSeconds = max(seconds, 0)
        return "\(clampedSeconds / 60):\(String(format: "%02d", clampedSeconds % 60))"
    }

    private func playStepHaptic() {
#if canImport(WatchKit)
        WKInterfaceDevice.current().play(.notification)
#endif
    }

    private func sendLiveActivityUpdate(
        action: String,
        elapsedSeconds: Int,
        currentStep: WatchBrewStep,
        nextStep: WatchBrewStep?,
        currentWaterGrams: Int,
        isPaused: Bool
    ) {
        liveActivityHandler(action, elapsedSeconds, currentStep, nextStep, currentWaterGrams, isPaused)
    }
}

#Preview {
    ContentView()
}
