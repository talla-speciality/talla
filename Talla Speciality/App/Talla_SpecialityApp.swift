//
//  Talla_SpecialityApp.swift
//  Talla Speciality
//
//  Created by Ahmad AlBuainain on 15/3/26.
//

import SwiftUI
import SwiftData
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(AppIntents)
import AppIntents
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

#if canImport(UIKit) && canImport(UserNotifications)
private final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let pushDeviceTokenKey = "local.pushDeviceToken"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: pushDeviceTokenKey)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        #if DEBUG
        print("Remote notification registration failed: \(error.localizedDescription)")
        #endif
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge, .list]
    }
}
#endif

#if canImport(WatchConnectivity) && os(iOS)
final class TallaWatchPhoneBridge: NSObject, WCSessionDelegate {
    static let shared = TallaWatchPhoneBridge()

#if canImport(ActivityKit)
    private var watchBrewLiveActivity: Activity<TallaBrewActivityAttributes>?
#endif

    private enum Key {
        static let appGroupID = "group.Talla-Speciality.Talla-Speciality"
        static let loyaltyEmail = "loyalty.email"
        static let favoriteCount = "widget.favoriteCount"
        static let recentCount = "widget.recentCount"
        static let savedCartCount = "widget.savedCartCount"
        static let language = "app.language"
        static let loyaltyPoints = "watch.loyalty.points"
        static let loyaltyTier = "watch.loyalty.tier"
        static let loyaltyNextReward = "watch.loyalty.nextReward"
        static let loyaltyMemberID = "watch.loyalty.memberID"
        static let lastUpdated = "widget.lastUpdated"
        static let shortcutDestination = "shortcut.destination"
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: Key.appGroupID) ?? .standard
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let espressoAction = message["espressoAction"] as? String {
            UserDefaults.standard.set(espressoAction, forKey: "talla.espresso.watch.lastAction")
            NotificationCenter.default.post(name: .tallaEspressoWatchAction, object: nil, userInfo: [
                "action": espressoAction,
                "targetYield": message["targetYield"] as? Double ?? 36.0
            ])
            replyHandler(["espressoStatus": espressoAction, "espressoTarget": message["targetYield"] as? Double ?? 36.0])
            return
        }
        if let brewActivityAction = message["brewActivity"] as? String {
            var response = snapshot()
            response["brewActivityStatus"] = handleBrewActivity(action: brewActivityAction, message: message)
            replyHandler(response)
            return
        }

        if let destination = message["open"] as? String, !destination.isEmpty {
            UserDefaults.standard.set(destination, forKey: Key.shortcutDestination)
            replyHandler(snapshot())
            return
        }

        replyHandler(snapshot())
    }

    /// Sends the espresso state to the Watch while a shot is running.  The Watch
    /// can therefore be used as the glanceable display even when the phone is
    /// handling the scale connection.
    static func sendEspressoState(elapsed: Int, weight: Double, ratio: Double, flow: Double, targetYield: Double, isRunning: Bool) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        let payload: [String: Any] = [
            "espressoState": "updated",
            "espressoElapsed": elapsed,
            "espressoWeight": weight,
            "espressoRatio": ratio,
            "espressoFlow": flow,
            "espressoTargetYield": targetYield,
            "espressoIsRunning": isRunning
        ]
        if session.isReachable { session.sendMessage(payload, replyHandler: nil) }
        else { session.transferUserInfo(payload) }
    }

    static func syncRecipeSelection(methodName: String, coffeeGrams: Double, ratio: Double, totalWater: Double, totalSeconds: Int, grind: String, temperature: String, stepTimes: [Int], stepTitles: [String], stepWaterTargets: [Double]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        let defaults = UserDefaults(suiteName: Key.appGroupID) ?? .standard
        defaults.set(methodName, forKey: "watch.recipe.methodName")
        defaults.set(coffeeGrams, forKey: "watch.recipe.coffeeGrams")
        defaults.set(ratio, forKey: "watch.recipe.ratio")
        defaults.set(totalWater, forKey: "watch.recipe.totalWater")
        defaults.set(totalSeconds, forKey: "watch.recipe.totalSeconds")
        defaults.set(grind, forKey: "watch.recipe.grind")
        defaults.set(temperature, forKey: "watch.recipe.temperature")
        defaults.set(stepTimes, forKey: "watch.recipe.stepTimes")
        defaults.set(stepTitles, forKey: "watch.recipe.stepTitles")
        defaults.set(stepWaterTargets, forKey: "watch.recipe.stepWaterTargets")
        let payload: [String: Any] = [
            "recipeSelection": "updated",
            "methodName": methodName,
            "coffeeGrams": coffeeGrams,
            "ratio": ratio,
            "totalWaterGrams": totalWater,
            "totalSeconds": totalSeconds,
            "grind": grind,
            "temperature": temperature,
            "stepTimes": stepTimes,
            "stepTitles": stepTitles,
            "stepWaterTargets": stepWaterTargets
        ]
        if session.isReachable { session.sendMessage(payload, replyHandler: nil) }
        else { session.transferUserInfo(payload) }
    }

    private func snapshot() -> [String: Any] {
        var response: [String: Any] = [
            "email": defaults.string(forKey: Key.loyaltyEmail) ?? "",
            "favoriteCount": defaults.integer(forKey: Key.favoriteCount),
            "recentCount": defaults.integer(forKey: Key.recentCount),
            "savedCartCount": defaults.integer(forKey: Key.savedCartCount),
            "language": defaults.string(forKey: Key.language) ?? "en",
            "points": defaults.integer(forKey: Key.loyaltyPoints),
            "tier": defaults.string(forKey: Key.loyaltyTier) ?? "Bronze",
            "nextReward": defaults.string(forKey: Key.loyaltyNextReward) ?? "Check rewards in app",
            "memberID": defaults.string(forKey: Key.loyaltyMemberID) ?? "",
            "lastUpdated": defaults.double(forKey: Key.lastUpdated)
        ]
        if let methodName = defaults.string(forKey: "watch.recipe.methodName") {
            response["methodName"] = methodName
            response["coffeeGrams"] = defaults.double(forKey: "watch.recipe.coffeeGrams")
            response["ratio"] = defaults.double(forKey: "watch.recipe.ratio")
            response["totalWaterGrams"] = defaults.double(forKey: "watch.recipe.totalWater")
            response["totalSeconds"] = defaults.integer(forKey: "watch.recipe.totalSeconds")
            response["grind"] = defaults.string(forKey: "watch.recipe.grind") ?? ""
            response["temperature"] = defaults.string(forKey: "watch.recipe.temperature") ?? ""
            response["stepTimes"] = defaults.array(forKey: "watch.recipe.stepTimes") as? [Int] ?? []
            response["stepTitles"] = defaults.array(forKey: "watch.recipe.stepTitles") as? [String] ?? []
            response["stepWaterTargets"] = defaults.array(forKey: "watch.recipe.stepWaterTargets") as? [Double] ?? []
        }
        return response
    }

    private func handleBrewActivity(action: String, message: [String: Any]) -> String {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return "unavailable" }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return "disabled" }

        switch action {
        case "start":
            return startWatchBrewLiveActivity(message: message)
        case "update":
            return updateWatchBrewLiveActivity(message: message, isPaused: message["isPaused"] as? Bool ?? false)
        case "end":
            return endWatchBrewLiveActivity(message: message)
        default:
            return "unknown"
        }
#else
        return "unavailable"
#endif
    }

#if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func startWatchBrewLiveActivity(message: [String: Any]) -> String {
        if let watchBrewLiveActivity {
            Task {
                await watchBrewLiveActivity.end(nil, dismissalPolicy: .immediate)
            }
            self.watchBrewLiveActivity = nil
        }

        let attributes = TallaBrewActivityAttributes(
            methodName: message["methodName"] as? String ?? "Solo Dripper",
            coffeeGrams: message["coffeeGrams"] as? Double ?? 20,
            ratio: message["ratio"] as? Double ?? 16,
            totalWaterGrams: message["totalWaterGrams"] as? Double ?? 320,
            totalSeconds: message["totalSeconds"] as? Int ?? 210,
            languageCode: AppLocalization.currentLanguage.effectiveLanguageCode
        )
        let state = brewActivityState(from: message)
        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(TimeInterval(max(attributes.totalSeconds - state.elapsedSeconds, 1))),
            relevanceScore: 100
        )

        do {
            watchBrewLiveActivity = try Activity<TallaBrewActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            return "started"
        } catch {
            watchBrewLiveActivity = nil
            return "failed"
        }
    }

    @available(iOS 16.1, *)
    private func updateWatchBrewLiveActivity(message: [String: Any], isPaused: Bool) -> String {
        guard let watchBrewLiveActivity else {
            return startWatchBrewLiveActivity(message: message)
        }

        let state = brewActivityState(from: message, isPaused: isPaused)
        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(TimeInterval(max(watchBrewLiveActivity.attributes.totalSeconds - state.elapsedSeconds, 1))),
            relevanceScore: 100
        )

        Task {
            await watchBrewLiveActivity.update(content)
        }
        return "updated"
    }

    @available(iOS 16.1, *)
    private func endWatchBrewLiveActivity(message: [String: Any]) -> String {
        guard let watchBrewLiveActivity else { return "inactive" }

        let content = ActivityContent(
            state: brewActivityState(from: message),
            staleDate: nil,
            relevanceScore: 100
        )
        self.watchBrewLiveActivity = nil

        Task {
            await watchBrewLiveActivity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(8)))
        }
        return "ended"
    }

    @available(iOS 16.1, *)
    private func brewActivityState(from message: [String: Any], isPaused: Bool? = nil) -> TallaBrewActivityAttributes.ContentState {
        let elapsedSeconds = message["elapsedSeconds"] as? Int ?? 0
        return TallaBrewActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            timerStartDate: Date().addingTimeInterval(-Double(elapsedSeconds)),
            currentStep: message["currentStep"] as? String ?? "Start brewing",
            nextStep: message["nextStep"] as? String ?? "Your brew is ready. Enjoy it slowly.",
            currentWaterGrams: message["currentWaterGrams"] as? Double ?? 0,
            isPaused: isPaused ?? (message["isPaused"] as? Bool ?? false),
            stepTimes: message["stepTimes"] as? [Int] ?? [],
            stepTitles: message["stepTitles"] as? [String] ?? [],
            stepWaterTargets: message["stepWaterTargets"] as? [Double] ?? []
        )
    }
#endif
}
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, *)
nonisolated struct TallaCommerceActivityAttributes: ActivityAttributes, Sendable {
    enum Kind: String, Codable, Hashable, Sendable {
        case order
        case groupOrder
        case gift
    }

    nonisolated struct ContentState: Codable, Hashable, Sendable {
        let status: String
        let statusKey: String
        let progress: Double
        let deadline: Date?
        let detail: String?
    }

    let kind: Kind
    let referenceID: String
    let title: String
    let isPickup: Bool
    let languageCode: String
}

@available(iOS 16.1, *)
final class TallaCommerceLiveActivityCoordinator {
    static let shared = TallaCommerceLiveActivityCoordinator()
    private var activity: Activity<TallaCommerceActivityAttributes>?

    private init() {
        activity = Activity<TallaCommerceActivityAttributes>.activities.first
    }

    func syncOrder(id: String, title: String, status: String, isPickup: Bool, languageCode: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = orderState(status: status, isPickup: isPickup)
        let attributes = TallaCommerceActivityAttributes(
            kind: .order,
            referenceID: id,
            title: title,
            isPickup: isPickup,
            languageCode: languageCode
        )
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(60 * 60), relevanceScore: 100)

        if let activity, activity.attributes.referenceID == id {
            Task { await activity.update(content) }
            return
        }

        if let activity {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        do {
            activity = try Activity<TallaCommerceActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func endOrder() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .after(Date().addingTimeInterval(8))) }
    }

    func startGroupOrder(id: String, title: String, deadline: Date?, participantCount: Int, languageCode: String) {
        sync(
            kind: .groupOrder,
            id: id,
            title: title,
            isPickup: false,
            status: "Group order closing soon",
            statusKey: "group_order_closing_soon",
            progress: 0.8,
            deadline: deadline,
            detail: "\(participantCount) people joined",
            languageCode: languageCode
        )
    }

    func startGift(id: String, title: String, expiry: Date?, languageCode: String) {
        sync(
            kind: .gift,
            id: id,
            title: title,
            isPickup: true,
            status: "Gift ready to redeem",
            statusKey: "gift_ready_to_redeem",
            progress: 1,
            deadline: expiry,
            detail: "Show this gift at the counter",
            languageCode: languageCode
        )
    }

    private func sync(kind: TallaCommerceActivityAttributes.Kind, id: String, title: String, isPickup: Bool, status: String, statusKey: String, progress: Double, deadline: Date?, detail: String, languageCode: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = TallaCommerceActivityAttributes(kind: kind, referenceID: id, title: title, isPickup: isPickup, languageCode: languageCode)
        let content = ActivityContent(
            state: TallaCommerceActivityAttributes.ContentState(status: status, statusKey: statusKey, progress: progress, deadline: deadline, detail: detail),
            staleDate: deadline ?? Date().addingTimeInterval(60 * 60),
            relevanceScore: 80
        )
        if let activity,
           activity.attributes.referenceID == id,
           activity.attributes.kind == kind {
            Task { await activity.update(content) }
            return
        }
        if let activity { Task { await activity.end(nil, dismissalPolicy: .immediate) } }
        do { activity = try Activity.request(attributes: attributes, content: content, pushType: nil) }
        catch { activity = nil }
    }

    private func orderState(status: String, isPickup: Bool) -> TallaCommerceActivityAttributes.ContentState {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "pending", "placed", "received":
            return .init(status: "Order confirmed", statusKey: "order_confirmed", progress: 0.2, deadline: nil, detail: "We received your order")
        case "confirmed":
            return .init(status: "Order confirmed", statusKey: "order_confirmed", progress: 0.3, deadline: nil, detail: "We received your order")
        case "preparing", "roasting", "resting", "packed":
            return .init(status: "Preparing", statusKey: "preparing", progress: 0.6, deadline: nil, detail: "Your coffee is being prepared")
        case "ready":
            return .init(status: isPickup ? "Ready for pickup" : "Ready", statusKey: "ready_for_pickup", progress: 1, deadline: nil, detail: isPickup ? "Your order is waiting at Talla" : "Your order is ready")
        default:
            return .init(status: status.capitalized, statusKey: status.lowercased(), progress: 0.45, deadline: nil, detail: "Your order is in progress")
        }
    }
}
#endif

extension Notification.Name {
    static let tallaEspressoWatchAction = Notification.Name("talla.espresso.watch.action")
}

@main
struct Talla_SpecialityApp: App {
    @AppStorage("app.language") private var savedAppLanguage = AppLanguage.arabic.rawValue
    @StateObject private var coffeeData = CoffeeDataStore.shared
    @Environment(\.scenePhase) private var scenePhase
    #if canImport(UIKit) && canImport(UserNotifications)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: savedAppLanguage) ?? .system
    }

    init() {
#if canImport(WatchConnectivity) && os(iOS)
        TallaWatchPhoneBridge.shared.activate()
#endif
        TallaTelemetry.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(TallaTheme.Colors.ink)
                .fontDesign(.rounded)
                .environment(\.layoutDirection, appLanguage.layoutDirection)
                .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
                .environmentObject(coffeeData)
                .task {
                    guard ProcessInfo.processInfo.environment["TALLA_UI_TEST_SCENARIO"] == nil else { return }
#if canImport(AppIntents)
                    TallaAppShortcuts.updateAppShortcutParameters()
#endif
                    TallaTelemetry.shared.appReady()
                    // Give the first local frame a chance to render before
                    // legacy migration and account synchronization do work.
                    await Task.yield()
                    try? coffeeData.migrateLegacyJSON()
                    await coffeeData.retryCurrentAccountSynchronization()
                }
        }
        .modelContainer(coffeeData.container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                TallaTelemetry.shared.enteredBackground()
            } else if phase == .active,
                      ProcessInfo.processInfo.environment["TALLA_UI_TEST_SCENARIO"] == nil {
                Task { await coffeeData.retryCurrentAccountSynchronization() }
            }
        }
    }
}
