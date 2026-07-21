import SwiftUI
import Observation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

struct TallaWatchSnapshot {
    var email: String = ""
    var points: Int = 0
    var tier: String = "Reserve"
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
        guard isSignedIn else { return "Not signed in" }
        return email
    }

    var progressTarget: Int {
        max(((points / 100) + 1) * 100, 100)
    }

    var progressValue: Double {
        min(Double(points % 100) / 100, 1)
    }

    var beansToNextReward: Int {
        let remainder = points % 100
        return remainder == 0 && points > 0 ? 0 : 100 - remainder
    }
}

@Observable
@MainActor
final class TallaWatchStore: NSObject {
    var snapshot = TallaWatchSnapshot()
    var statusText = "Open Talla on iPhone once to sync."
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
            statusText = "Open Talla on iPhone, then tap Sync."
            lastActionText = "iPhone needed"
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
            statusText = "Open Talla on iPhone first."
            lastActionText = "iPhone needed"
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

    private func apply(_ payload: [String: Any]) {
        snapshot = TallaWatchSnapshot(
            email: payload["email"] as? String ?? "",
            points: payload["points"] as? Int ?? 0,
            tier: payload["tier"] as? String ?? "Reserve",
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
                statusText = "Pair with iPhone to sync."
                lastActionText = "Pair iPhone"
            } else {
                refresh()
            }
        }
    }
}
#endif

struct ContentView: View {
    @State private var store = TallaWatchStore()

    private let accent = Color(red: 0.79, green: 0.59, blue: 0.35)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    rewardHero
                    if !store.snapshot.isSignedIn {
                        signInPrompt
                    }
                    statsGrid
                    memberCard
                    quickActions
                    syncFooter
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Talla")
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
                Text(store.snapshot.tier)
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
            Text(store.canReachPhone ? "Live" : "Phone")
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
                    Text(store.snapshot.isSignedIn ? "Beans" : "Rewards")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                    Text(store.snapshot.isSignedIn ? store.snapshot.nextReward : "Sync your iPhone to see Beans.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                    Text(store.snapshot.beansToNextReward == 0 ? "Reward ready" : "\(store.snapshot.beansToNextReward) Beans to next 100")
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

    private var signInPrompt: some View {
        Button {
            store.openOnPhone("rewards")
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundStyle(accent)
                Text("Sign in on iPhone for live rewards")
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(2)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var statsGrid: some View {
        HStack(spacing: 6) {
            statTile(title: "Shelf", value: store.snapshot.favoriteCount, icon: "books.vertical.fill")
            statTile(title: "Recent", value: store.snapshot.recentCount, icon: "clock.fill")
            statTile(title: "Carts", value: store.snapshot.savedCartCount, icon: "cart.fill")
        }
    }

    private func statTile(title: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(accent)
            Text("\(value)")
                .font(.system(size: 17, weight: .black))
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var memberCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Member")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(accent)
            Text(store.snapshot.displayEmail)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.middle)
            if !store.snapshot.memberID.isEmpty {
                Text(store.snapshot.memberID)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var quickActions: some View {
        VStack(spacing: 7) {
            HStack(spacing: 7) {
                compactAction("Rewards", icon: "star.circle.fill", destination: "rewards")
                compactAction("Shelf", icon: "books.vertical.fill", destination: "shelf")
            }
            actionButton("Shop Coffee on iPhone", icon: "bag.fill", destination: "shop")
        }
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

    private func actionButton(_ title: String, icon: String, destination: String) -> some View {
        Button {
            store.openOnPhone(destination)
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .tint(accent)
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

#Preview {
    ContentView()
}
