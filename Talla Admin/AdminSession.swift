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
    @Published private(set) var lastRefreshAt: Date?
    @Published var message: String?
    @Published var errorMessage: String?
    @Published private(set) var notificationsEnabled = false
    @Published private(set) var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    let api = AdminAPI.configured

    func bootstrap() async {
        defer { isRestoring = false }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-admin-preview") {
            isAuthenticated = true
            username = "Preview Admin"
            orders = Self.previewOrders
            lastRefreshAt = .now
            notificationsEnabled = true
            return
        }
        #endif
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
        message = nil
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
        errorMessage = nil
        lastRefreshAt = nil
    }

    func refreshOrders() async {
        guard isAuthenticated, !isLoadingOrders else { return }
        isLoadingOrders = true
        defer { isLoadingOrders = false }
        do {
            orders = try await api.orders().sorted {
                ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast)
            }
            lastRefreshAt = .now
            errorMessage = nil
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        } catch {
            handle(error)
        }
    }

    func updateOrder(_ order: AdminOrder, status: String) async {
        message = nil
        errorMessage = nil
        do {
            orders = try await api.updateOrder(id: order.id, status: status).sorted {
                ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast)
            }
            let detailedOrder = try await api.orderDetail(id: order.id)
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders[index] = detailedOrder
            }
            lastRefreshAt = .now
            message = "\(order.title) updated to \(status)."
        } catch {
            handle(error)
        }
    }

    func refreshOrderDetail(id: String) async {
        guard isAuthenticated else { return }
        do {
            let detailedOrder = try await api.orderDetail(id: id)
            if let index = orders.firstIndex(where: { $0.id == id }) {
                orders[index] = detailedOrder
            } else {
                orders.insert(detailedOrder, at: 0)
            }
            errorMessage = nil
        } catch {
            handle(error)
        }
    }

    func notifyReady(_ order: AdminOrder) async {
        message = nil
        errorMessage = nil
        do {
            let result = try await api.notifyReady(orderID: order.id)
            if !result.configured {
                errorMessage = "Customer push notifications are not configured on the backend."
            } else if result.targetCount == 0 {
                errorMessage = "This customer has no notification-enabled device."
            } else if result.sentCount == 0 {
                errorMessage = "Apple did not accept the notification. Please try again."
            } else {
                message = "Pickup-ready alert sent to \(result.sentCount) device\(result.sentCount == 1 ? "" : "s") for \(order.title)."
            }
        } catch {
            handle(error)
        }
    }

    func enableNotifications() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else {
                errorMessage = "Notifications are off. Open iOS Settings to enable new-order alerts."
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

    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func clearFeedback() {
        message = nil
        errorMessage = nil
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
        notificationAuthorizationStatus = settings.authorizationStatus
        notificationsEnabled = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
    }

    private func handle(_ error: Error) {
        errorMessage = error.localizedDescription
        if let apiError = error as? AdminAPIError, case .unauthorized = apiError {
            isAuthenticated = false
            username = ""
            orders = []
            lastRefreshAt = nil
        }
    }

    #if DEBUG
    private static let previewOrders: [AdminOrder] = [
        AdminOrder(
            id: "TALLA-1048", email: "customer@example.com", title: "Pickup order #1048",
            total: "BHD 12.400", status: "Pending",
            items: [AdminOrderItem(name: "Ethiopia Guji — Filter Roast", quantity: 2), AdminOrderItem(name: "Glass Cup", quantity: 1)],
            createdAt: "2026-09-02T14:20:00Z", beansAwarded: false, pointsAwarded: 12,
            customer: AdminOrderCustomer(fullName: "Sara Ahmed", email: "customer@example.com", phone: "+973 3900 0000"),
            fulfillment: AdminOrderFulfillment(method: "pickup", fullName: "Sara Ahmed", phone: "+973 3900 0000", line1: "Talla, Riffa", city: "Riffa", countryCode: "BH", notes: "Call on arrival"),
            payment: AdminOrderPayment(method: "BenefitPay", provider: "BENEFIT", status: "Captured", amount: "12.400", currency: "BHD", reference: "BP-1048", paidAt: "2026-09-02T14:21:00Z"),
            source: "Talla iOS app", updatedAt: "2026-09-02T14:21:00Z"
        ),
        AdminOrder(
            id: "TALLA-1047", email: "long.customer.name@example.com", title: "Delivery order #1047",
            total: "BHD 7.250", status: "Ready",
            items: [AdminOrderItem(name: "Colombia Huila", quantity: 1)],
            createdAt: "2026-09-02T13:05:00Z", beansAwarded: true, pointsAwarded: 7,
            customer: nil, fulfillment: nil, payment: nil, source: "Talla app", updatedAt: nil
        ),
        AdminOrder(
            id: "TALLA-1046", email: "completed@example.com", title: "Pickup order #1046",
            total: "BHD 4.800", status: "Completed",
            items: [AdminOrderItem(name: "House Espresso", quantity: 1)],
            createdAt: "2026-09-01T11:30:00Z", beansAwarded: true, pointsAwarded: 4,
            customer: nil, fulfillment: nil, payment: nil, source: "Talla app", updatedAt: nil
        ),
        AdminOrder(
            id: "TALLA-1045", email: "cancelled@example.com", title: "Delivery order #1045",
            total: "BHD 9.600", status: "Cancelled",
            items: [AdminOrderItem(name: "Brazil Fazenda", quantity: 2)],
            createdAt: "2026-08-31T09:00:00Z", beansAwarded: false, pointsAwarded: 0,
            customer: nil, fulfillment: nil, payment: nil, source: "Talla app", updatedAt: nil
        )
    ]
    #endif
}
