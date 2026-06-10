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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, appLanguage.layoutDirection)
                .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
        }
    }
}
