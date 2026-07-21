//
//  Talla_SpecialityApp.swift
//  Talla Speciality
//
//  Created by Ahmad AlBuainain on 15/3/26.
//

import SwiftUI
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
            "tier": defaults.string(forKey: Key.loyaltyTier) ?? "Reserve",
            "nextReward": defaults.string(forKey: Key.loyaltyNextReward) ?? "Check rewards in app",
            "memberID": defaults.string(forKey: Key.loyaltyMemberID) ?? "",
            "lastUpdated": defaults.double(forKey: Key.lastUpdated)
        ]
    }
}
#endif

@main
struct Talla_SpecialityApp: App {
    @AppStorage("app.language") private var savedAppLanguage = AppLanguage.system.rawValue
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, appLanguage.layoutDirection)
                .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
        }
    }
}
