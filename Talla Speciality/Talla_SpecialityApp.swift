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
private final class TallaWatchPhoneBridge: NSObject, WCSessionDelegate {
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

    private func snapshot() -> [String: Any] {
        [
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

@main
struct Talla_SpecialityApp: App {
    @AppStorage("app.language") private var savedAppLanguage = AppLanguage.system.rawValue
    @StateObject private var coffeeData = CoffeeDataStore.shared
    @Environment(\.scenePhase) private var scenePhase
    #if canImport(UIKit) && canImport(UserNotifications)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: savedAppLanguage) ?? .system
    }

    init() {
#if canImport(AppIntents)
        TallaAppShortcuts.updateAppShortcutParameters()
#endif
#if canImport(WatchConnectivity) && os(iOS)
        TallaWatchPhoneBridge.shared.activate()
#endif
        TallaTelemetry.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, appLanguage.layoutDirection)
                .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
                .environmentObject(coffeeData)
                .task {
                    TallaTelemetry.shared.appReady()
                    try? coffeeData.migrateLegacyJSON()
                    let defaults = UserDefaults.standard
                    let token = defaults.string(forKey: "local.customerAccessToken")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let owner = defaults.string(forKey: "local.customerEmail")?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
                    let baseURL = (Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String).flatMap(URL.init(string:))
                    if !token.isEmpty, !owner.isEmpty, let baseURL {
                        try? await coffeeData.synchronize(ownerID: owner, bearerToken: token, baseURL: baseURL)
                    }
                }
        }
        .modelContainer(coffeeData.container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { TallaTelemetry.shared.enteredBackground() }
        }
    }
}
