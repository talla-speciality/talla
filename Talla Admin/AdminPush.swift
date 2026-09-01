import UIKit
import UserNotifications

enum AdminPush {
    static let deviceTokenKey = "talla.admin.pushDeviceToken"
    static let tokenDidChange = Notification.Name("TallaAdminPushTokenDidChange")
    static let orderDidArrive = Notification.Name("TallaAdminOrderDidArrive")
    static let openOrders = Notification.Name("TallaAdminOpenOrders")
}

final class TallaAdminAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: AdminPush.deviceTokenKey)
        NotificationCenter.default.post(name: AdminPush.tokenDidChange, object: token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("Talla Admin push registration failed: \(error.localizedDescription)")
        #endif
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationCenter.default.post(name: AdminPush.orderDidArrive, object: userInfo["orderID"] as? String)
        completionHandler(.newData)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        NotificationCenter.default.post(name: AdminPush.orderDidArrive, object: notification.request.content.userInfo["orderID"] as? String)
        return [.banner, .sound, .badge, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        NotificationCenter.default.post(name: AdminPush.openOrders, object: response.notification.request.content.userInfo["orderID"] as? String)
    }
}
