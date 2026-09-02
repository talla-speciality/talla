import SwiftUI
import Combine
import UserNotifications
import UIKit

@MainActor
final class AdminSession: ObservableObject {
    @Published private(set) var isRestoring = true
    @Published private(set) var isAuthenticated = false
    @Published private(set) var username = ""
    @Published private(set) var orders: [AdminOrder] = []
    @Published private(set) var isLoadingOrders = false
    @Published var message: String?
    @Published var errorMessage: String?
    @Published private(set) var notificationsEnabled = false

    let api = AdminAPI.configured

    func bootstrap() async {
        defer { isRestoring = false }
        do {
            let session = try await api.restoreSession()
            isAuthenticated = session.authenticated
            username = session.username ?? ""
            if session.authenticated {
                await api.synchronizeWebCookies()
                await refreshOrders()
            }
        } catch {
            isAuthenticated = false
        }
        await refreshNotificationState()
        if isAuthenticated, notificationsEnabled {
            UIApplication.shared.registerForRemoteNotifications()
            await registerStoredPushToken()
        }
    }

    func login(username: String, password: String) async -> Bool {
        errorMessage = nil
        do {
            let response = try await api.login(username: username, password: password)
            guard response.authenticated else { throw AdminAPIError.server("Admin sign-in failed.") }
            self.username = response.username ?? username
            isAuthenticated = true
            await refreshOrders()
            await refreshNotificationState()
            if notificationsEnabled {
                UIApplication.shared.registerForRemoteNotifications()
                await registerStoredPushToken()
            } else {
                await enableNotifications()
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() async {
        if let token = UserDefaults.standard.string(forKey: AdminPush.deviceTokenKey) {
            try? await api.unregisterPushToken(token)
        }
        try? await api.logout()
        isAuthenticated = false
        username = ""
        orders = []
        message = nil
    }

    func refreshOrders() async {
        guard isAuthenticated, !isLoadingOrders else { return }
        isLoadingOrders = true
        defer { isLoadingOrders = false }
        do {
            orders = try await api.orders()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateOrder(_ order: AdminOrder, status: String) async {
        do {
            orders = try await api.updateOrder(id: order.id, status: status)
            message = "\(order.title) updated to \(status)."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func notifyReady(_ order: AdminOrder) async {
        do {
            try await api.notifyReady(orderID: order.id)
            message = "Pickup-ready notification sent for \(order.title)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func enableNotifications() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else {
                errorMessage = "Notification permission was not granted."
                await refreshNotificationState()
                return
            }
            UIApplication.shared.registerForRemoteNotifications()
            notificationsEnabled = true
            message = "Order notifications are enabled."
            await registerStoredPushToken()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func registerPushToken(_ token: String) async {
        guard isAuthenticated else { return }
        do {
            let configured = try await api.registerPushToken(token)
            message = configured
                ? "This iPhone will receive new-order alerts."
                : "Device registered. APNs still needs to be configured on the backend."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func registerStoredPushToken() async {
        guard let token = UserDefaults.standard.string(forKey: AdminPush.deviceTokenKey) else { return }
        await registerPushToken(token)
    }

    private func refreshNotificationState() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
}
