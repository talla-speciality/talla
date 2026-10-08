import SwiftUI
import Combine
import UserNotifications
import UIKit
import LocalAuthentication
import Security

private struct AdminBiometricCredential: Codable {
    let username: String
    let password: String
}

private enum AdminBiometricStore {
    private static let service = "com.talla.admin.biometric-login"
    private static let account = "admin-credential"

    static var available: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static var hasCredential: Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    static func save(username: String, password: String) throws {
        let data = try JSONEncoder().encode(AdminBiometricCredential(username: username, password: password))
        var accessError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &accessError
        ) else { throw AdminAPIError.server("Could not enable biometric sign-in.") }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl
        ]
        SecItemDelete(query as CFDictionary)
        guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { throw AdminAPIError.server("Could not enable biometric sign-in.") }
    }

    static func read() throws -> AdminBiometricCredential? {
        let context = LAContext()
        context.localizedReason = "Sign in to Talla Admin"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw AdminAPIError.server("Biometric sign-in was not completed.") }
        return try JSONDecoder().decode(AdminBiometricCredential.self, from: data)
    }

    static func remove() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }
}

@MainActor
final class AdminSession: ObservableObject {
    @Published private(set) var isRestoring = true
    @Published private(set) var isAuthenticated = false
    @Published private(set) var username = ""
    @Published private(set) var role = "viewer"
    @Published private(set) var permissions: Set<String> = []
    @Published private(set) var biometricAvailable = false
    @Published private(set) var biometricEnabled = false
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
        biometricAvailable = AdminBiometricStore.available
        biometricEnabled = AdminBiometricStore.hasCredential
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
            role = session.role ?? "viewer"
            permissions = Set(session.permissions ?? [])
            if session.authenticated {
                await api.synchronizeWebCookies()
                await refreshOrders()
            } else if biometricEnabled {
                await loginWithBiometrics()
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

    func login(username: String, password: String, saveBiometrics: Bool = false) async -> Bool {
        errorMessage = nil
        message = nil
        do {
            let response = try await api.login(username: username, password: password)
            guard response.authenticated else { throw AdminAPIError.server("Admin sign-in failed.") }
            self.username = response.username ?? username
            role = response.role ?? "viewer"
            permissions = Set(response.permissions ?? [])
            if saveBiometrics {
                do {
                    try AdminBiometricStore.save(username: username, password: password)
                    biometricEnabled = true
                } catch { errorMessage = error.localizedDescription }
            }
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

    func loginWithBiometrics() async {
        guard biometricAvailable, !isAuthenticated else { return }
        do {
            guard let credential = try AdminBiometricStore.read() else { biometricEnabled = false; return }
            _ = await login(username: credential.username, password: credential.password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disableBiometricLogin() {
        AdminBiometricStore.remove()
        biometricEnabled = false
    }

    func logout() async {
        if let token = UserDefaults.standard.string(forKey: AdminPush.deviceTokenKey) {
            try? await api.unregisterPushToken(token)
        }
        try? await api.logout()
        isAuthenticated = false
        username = ""
        role = "viewer"
        permissions = []
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

    func updateCoffeeClubShipment(
        _ order: AdminOrder,
        action: String,
        reason: String? = nil,
        note: String? = nil,
        amount: Double? = nil,
        coffeeItems: [[String: Any]]? = nil,
        fulfillment: [String: Any]? = nil
    ) async {
        message = nil
        errorMessage = nil
        do {
            orders = try await api.updateCoffeeClubShipment(
                id: order.id,
                action: action,
                reason: reason,
                note: note,
                amount: amount,
                coffeeItems: coffeeItems,
                fulfillment: fulfillment
            ).sorted {
                ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast)
            }
            let detailedOrder = try await api.orderDetail(id: order.id)
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders[index] = detailedOrder
            }
            lastRefreshAt = .now
            if action == "deliver", let club = detailedOrder.coffeeClub {
                message = "Shipment \(club.deliveredShipments) of \(club.shipmentCount) marked delivered."
            } else if action == "prepare", let club = detailedOrder.coffeeClub {
                message = "Shipment \(club.nextShipmentNumber ?? club.deliveredShipments + 1) marked as preparing."
            } else {
                message = "Coffee Club updated."
            }
        } catch {
            handle(error)
        }
    }

    func redeemCafePass(_ order: AdminOrder) async {
        message = nil
        errorMessage = nil
        do {
            orders = try await api.redeemCafePass(orderID: order.id).sorted {
                ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast)
            }
            let detailedOrder = try await api.orderDetail(id: order.id)
            if let index = orders.firstIndex(where: { $0.id == order.id }) { orders[index] = detailedOrder }
            lastRefreshAt = .now
            if let pass = detailedOrder.cafePass { message = "Café pass: \(pass.remainingCredits) drinks remaining." }
        } catch { handle(error) }
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

    func updateSupportCase(_ order: AdminOrder, status: String, note: String, assignedTo: String) async {
        message = nil
        errorMessage = nil
        do {
            let detailedOrder = try await api.updateSupportCase(orderID: order.id, status: status, note: note, assignedTo: assignedTo)
            if let index = orders.firstIndex(where: { $0.id == order.id }) { orders[index] = detailedOrder }
            message = "Customer case updated."
        } catch { handle(error) }
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

    func refund(_ order: AdminOrder, amount: Double, note: String) async {
        message = nil
        errorMessage = nil
        do {
            let result = try await api.refundOrder(orderID: order.id, email: order.email, amount: amount, note: note)
            if let updated = result.order, let index = orders.firstIndex(where: { $0.id == updated.id }) {
                orders[index] = updated
            }
            message = "Refund executed for \(order.title)."
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

    func hasPermission(_ permission: String) -> Bool {
        permissions.contains("*") || permissions.contains(permission)
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

    func handle(_ error: Error) {
        errorMessage = error.localizedDescription
        if let apiError = error as? AdminAPIError, case .unauthorized = apiError {
            isAuthenticated = false
            username = ""
            role = "viewer"
            permissions = []
            orders = []
            lastRefreshAt = nil
        }
    }

    #if DEBUG
    private static let previewOrders: [AdminOrder] = [
        AdminOrder(
            id: "TALLA-1048", email: "customer@example.com", title: "Talla Coffee Club #1048",
            total: "BHD 16.800", status: "Confirmed",
            items: [AdminOrderItem(name: "Colombia", quantity: 3, unitPrice: "BHD 4.000")],
            createdAt: "2026-09-02T14:20:00Z", beansAwarded: false, pointsAwarded: 12,
            customer: AdminOrderCustomer(fullName: "Sara Ahmed", email: "customer@example.com", phone: "+973 3900 0000"),
            fulfillment: AdminOrderFulfillment(method: "delivery", fullName: "Sara Ahmed", phone: "+973 3900 0000", line1: "Road 1307", city: "Riffa", countryCode: "BH", notes: "Call on arrival"),
            payment: AdminOrderPayment(method: "BenefitPay", provider: "BENEFIT", status: "Captured", amount: "16.800", currency: "BHD", reference: "BP-1048", paidAt: "2026-09-02T14:21:00Z"),
            coffeeClub: AdminCoffeeClub(
                shipmentCount: 3,
                intervalWeeks: 4,
                discountPercent: 10,
                deliveredShipments: 1,
                remainingShipments: 2,
                shipments: [AdminCoffeeClubShipment(
                    number: 1,
                    deliveredAt: "2026-09-15T10:00:00Z",
                    deliveredBy: "manager"
                )]
            ),
            source: "Talla iOS app", updatedAt: "2026-09-02T14:21:00Z"
        ),
        AdminOrder(
            id: "TALLA-1047", email: "long.customer.name@example.com", title: "Delivery order #1047",
            total: "BHD 7.250", status: "Ready",
            items: [AdminOrderItem(name: "Colombia Huila", quantity: 1)],
            createdAt: "2026-09-02T13:05:00Z", beansAwarded: true, pointsAwarded: 7,
            customer: nil, fulfillment: nil, payment: nil, coffeeClub: nil, source: "Talla app", updatedAt: nil
        ),
        AdminOrder(
            id: "TALLA-1046", email: "completed@example.com", title: "Pickup order #1046",
            total: "BHD 4.800", status: "Completed",
            items: [AdminOrderItem(name: "House Espresso", quantity: 1)],
            createdAt: "2026-09-01T11:30:00Z", beansAwarded: true, pointsAwarded: 4,
            customer: nil, fulfillment: nil, payment: nil, coffeeClub: nil, source: "Talla app", updatedAt: nil
        ),
        AdminOrder(
            id: "TALLA-1045", email: "cancelled@example.com", title: "Delivery order #1045",
            total: "BHD 9.600", status: "Cancelled",
            items: [AdminOrderItem(name: "Brazil Fazenda", quantity: 2)],
            createdAt: "2026-08-31T09:00:00Z", beansAwarded: false, pointsAwarded: 0,
            customer: nil, fulfillment: nil, payment: nil, coffeeClub: nil, source: "Talla app", updatedAt: nil
        )
    ]
    #endif
}
