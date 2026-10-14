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

enum BirthdayNotificationService {
    static let center = UNUserNotificationCenter.current()
    private static let identifier = "talla-birthday"

    static func schedule(month: Int, day: Int) async -> Bool {
        let settings = await ProductAlertNotificationService.authorizationStatus()
        let authorized: Bool
        switch settings {
        case .authorized, .provisional, .ephemeral:
            authorized = true
        case .notDetermined:
            authorized = await ProductAlertNotificationService.requestAuthorization()
        default:
            authorized = false
        }
        guard authorized else { return false }

        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "Happy birthday from Talla"
        content.body = "Your birthday reward is ready. Open Talla to see it."
        content.sound = .default
        content.userInfo = ["type": "birthday_reward", "url": "talla://account/loyalty"]

        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day], from: .now)
        let trigger: UNNotificationTrigger
        if today.month == month && today.day == day {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        } else {
            var components = DateComponents()
            components.month = month
            components.day = day
            components.hour = 9
            components.minute = 0
            trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )
        }
        do {
            try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            return true
        } catch {
            return false
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

enum CoffeeReorderNotificationService {
    static let center = UNUserNotificationCenter.current()

    static func scheduleIfLow(coffee: CoffeeInventoryRecord, doseGrams: Double) async {
        guard coffee.remainingQuantityGrams > 0, coffee.estimatedBrews(doseGrams: doseGrams) <= 3 else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier(coffee.id)])
            return
        }
        let settings = await BrewTimerNotificationService.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.text("coffee_running_low", fallback: "Your coffee is running low")
        content.body = String(format: AppLocalization.text("coffee_reorder_reminder_body", fallback: "%@ has about %d brews left. Reorder before your next cup."), coffee.productName, coffee.estimatedBrews(doseGrams: doseGrams))
        content.sound = .default
        try? await center.add(UNNotificationRequest(identifier: identifier(coffee.id), content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)))
    }

    private static func identifier(_ coffeeID: UUID) -> String { "coffee-reorder-\(coffeeID.uuidString)" }
}

enum TallaRetentionNotificationService {
    static let center = UNUserNotificationCenter.current()

    static func scheduleBrewDay(date: Date, title: String, body: String) async {
        guard date > .now else { return }
        let settings = await BrewTimerNotificationService.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        try? await center.add(UNNotificationRequest(
            identifier: "talla-brew-day",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        ))
    }

    static func cancelBrewDay() {
        center.removePendingNotificationRequests(withIdentifiers: ["talla-brew-day"])
    }

    static func scheduleMaintenance(date: Date, equipmentName: String, task: String, id: UUID) async {
        guard date > .now else { return }
        let settings = await BrewTimerNotificationService.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.text("maintenance_due_title", fallback: "Equipment care is due")
        content.body = String(format: AppLocalization.text("maintenance_due_body", fallback: "%@ · %@"), equipmentName, task)
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        try? await center.add(UNNotificationRequest(
            identifier: "talla-maintenance-\(id.uuidString)",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        ))
    }

    static func cancelMaintenance(id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["talla-maintenance-\(id.uuidString)"])
    }
}
#endif
