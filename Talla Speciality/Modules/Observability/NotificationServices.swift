import Foundation
import SwiftUI
import StoreKit
#if canImport(Security)
import Security
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

#if canImport(UserNotifications)
enum ProductAlertNotificationService {
    static let center = UNUserNotificationCenter.current()

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

}

enum BrewTimerNotificationService {
    static let center = UNUserNotificationCenter.current()

    static func scheduleCompletion(runID: UUID, after seconds: Int, title: String, body: String) async {
        let settings = await notificationSettings()
        let canNotify: Bool

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            canNotify = true
        case .notDetermined:
            canNotify = await requestAuthorization()
        default:
            canNotify = false
        }

        guard canNotify else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: completionIdentifier(for: runID),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(max(seconds, 1)),
                repeats: false
            )
        )

        try? await center.add(request)
    }

    static func cancelCompletion(runID: UUID) {
        let identifier = completionIdentifier(for: runID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    static func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func completionIdentifier(for runID: UUID) -> String {
        "brew-timer-complete-\(runID.uuidString)"
    }
}
#endif
