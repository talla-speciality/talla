import Foundation
import SwiftUI
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

enum BackendConfiguration {
    private static let infoPlistKey = "BackendBaseURL"
    private static let simulatorDefaultURL = URL(string: "http://127.0.0.1:8787")

    static var serviceBaseURL: URL? {
        if let configuredURL {
            return configuredURL
        }

        #if targetEnvironment(simulator)
        return simulatorDefaultURL
        #else
        return nil
        #endif
    }

    static func unavailableMessage(for serviceName: String) -> String {
        "\(serviceName) is unavailable. Set `BackendBaseURL` in Info.plist to your Mac's local network address, for example `http://192.168.1.23:8787`, or use a real HTTPS backend."
    }

    static func connectionMessage(for serviceName: String) -> String {
        "Could not reach the \(serviceName.lowercased()). On iPhone, `127.0.0.1` and `localhost` point to the phone itself. Set `BackendBaseURL` in Info.plist to your Mac's local network address, then make sure the backend server is running and reachable on the same Wi-Fi network."
    }

    private static var configuredURL: URL? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, let url = URL(string: trimmedValue) else {
            return nil
        }

        #if targetEnvironment(simulator)
        return url
        #else
        guard let host = url.host?.lowercased(), host != "127.0.0.1", host != "localhost" else {
            return nil
        }
        return url
        #endif
    }
}

#if canImport(UserNotifications)
private enum ProductAlertNotificationService {
    private static let center = UNUserNotificationCenter.current()

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

    static func scheduleReminder(for productID: String, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: reminderIdentifier(for: productID),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 86_400, repeats: false)
        )

        do {
            try await center.add(request)
        } catch {
            return
        }
    }

    static func removeReminder(for productID: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(for: productID)])
    }

    private static func reminderIdentifier(for productID: String) -> String {
        "product-alert-\(productID)"
    }
}
#endif

private enum AccountService {
    private static let baseURL = BackendConfiguration.serviceBaseURL

    static func register(firstName: String, lastName: String, email: String, password: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Account service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "password": password
        ])

        return try await performProfileRequest(request)
    }

    static func signIn(email: String, password: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        return try await performProfileRequest(request)
    }

    static func fetchProfile(email: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/accounts/profile"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performProfileRequest(request)
    }

    static func updateProfile(email: String, firstName: String, lastName: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/profile/update"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "firstName": firstName,
            "lastName": lastName
        ])

        return try await performProfileRequest(request)
    }

    static func resetPassword(email: String, currentPassword: String, newPassword: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/password/reset"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ])

        _ = try await performEmptyRequest(request)
    }

    static func fetchOrders(email: String) async throws -> [ContentView.AccountOrder] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/orders"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performOrdersRequest(request)
    }

    static func createSampleOrder(email: String) async throws -> [ContentView.AccountOrder] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/orders/sample"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email
        ])

        return try await performOrdersRequest(request)
    }

    static func fetchStockAlerts(email: String) async throws -> [ContentView.StockAlertRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/alerts"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performStockAlertsRequest(request)
    }

    static func fetchAlertInbox(email: String) async throws -> [ContentView.AlertInboxRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/alerts/inbox"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performAlertInboxRequest(request)
    }

    static func watchStockAlert(email: String, alert: ContentView.StockAlertRecord) async throws -> ContentView.StockAlertRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var payload = [
            "email": email,
            "productID": alert.productID,
            "productName": alert.productName,
            "isAvailableForSale": alert.isAvailableForSale
        ] as [String: Any]
        if let tag = alert.tag {
            payload["tag"] = tag
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/watch"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performStockAlertRequest(request)
    }

    static func removeStockAlert(email: String, productID: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/unwatch"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "productID": productID
        ])

        _ = try await performEmptyRequest(request)
    }

    static func syncStockAlerts(email: String, alerts: [ContentView.StockAlertRecord]) async throws -> [ContentView.StockAlertRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        let payloadAlerts = alerts.map { alert -> [String: Any] in
            var payload: [String: Any] = [
                "productID": alert.productID,
                "productName": alert.productName,
                "isAvailableForSale": alert.isAvailableForSale
            ]
            if let tag = alert.tag {
                payload["tag"] = tag
            }
            return payload
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/sync"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "alerts": payloadAlerts
        ])

        return try await performStockAlertsRequest(request)
    }

    static func fetchAddresses(email: String) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/addresses"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performAddressesRequest(request)
    }

    static func saveAddress(email: String, label: String, fullName: String, phone: String, line1: String, city: String, notes: String?) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var payload: [String: Any] = [
            "email": email,
            "label": label,
            "fullName": fullName,
            "phone": phone,
            "line1": line1,
            "city": city
        ]
        if let notes {
            payload["notes"] = notes
        }

        var request = URLRequest(url: baseURL.appending(path: "/addresses/save"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performAddressesRequest(request)
    }

    static func deleteAddress(email: String, addressID: String) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/addresses/delete"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "addressID": addressID
        ])

        return try await performAddressesRequest(request)
    }

    static func fetchVouchers(email: String) async throws -> [ContentView.VoucherRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/vouchers"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performVouchersRequest(request)
    }

    static func previewVoucher(code: String, email: String) async throws -> ContentView.VoucherRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/vouchers/preview"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code,
            "email": email
        ])

        return try await performVoucherRequest(request)
    }

    static func consumeVoucher(code: String, email: String) async throws -> ContentView.VoucherRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/vouchers/consume"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code,
            "email": email
        ])

        return try await performVoucherRequest(request)
    }

#if canImport(PassKit)
    static func fetchWalletPass(email: String) async throws -> PKPass {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/wallet/pass"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            guard let pass = try? PKPass(data: data) else {
                throw ContentView.LoyaltyServiceError.operationFailed("The Wallet pass could not be loaded.")
            }
            return pass
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The wallet service could not complete your request.")
    }
#endif

    private static func performProfileRequest(_ request: URLRequest) async throws -> ContentView.ShopifyCustomerProfile {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(AccountProfileResponse.self, from: data)
            return ContentView.ShopifyCustomerProfile(
                id: decoded.id,
                firstName: decoded.firstName,
                lastName: decoded.lastName,
                email: decoded.email
            )
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The account service could not complete your request.")
    }

    private static func performOrdersRequest(_ request: URLRequest) async throws -> [ContentView.AccountOrder] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.AccountOrder].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The orders service could not complete your request.")
    }

    private static func performVouchersRequest(_ request: URLRequest) async throws -> [ContentView.VoucherRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.VoucherRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The voucher service could not complete your request.")
    }

    private static func performStockAlertsRequest(_ request: URLRequest) async throws -> [ContentView.StockAlertRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.StockAlertRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts service could not complete your request.")
    }

    private static func performStockAlertRequest(_ request: URLRequest) async throws -> ContentView.StockAlertRecord {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.StockAlertRecord.self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts service could not complete your request.")
    }

    private static func performAlertInboxRequest(_ request: URLRequest) async throws -> [ContentView.AlertInboxRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.AlertInboxRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox could not complete your request.")
    }

    private static func performAddressesRequest(_ request: URLRequest) async throws -> [ContentView.DeliveryAddress] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.DeliveryAddress].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The address service could not complete your request.")
    }

    private static func performVoucherRequest(_ request: URLRequest) async throws -> ContentView.VoucherRecord {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.VoucherRecord.self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The voucher service could not complete your request.")
    }

    private static func performEmptyRequest(_ request: URLRequest) async throws -> Bool {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return true
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The service could not complete your request.")
    }
}

private enum LoyaltyService {
    private static let baseURL = BackendConfiguration.serviceBaseURL

    static func fetchAccount(email: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Loyalty service"))
        }

        var components = URLComponents(url: baseURL.appending(path: "/loyalty/account"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performLoyaltyRequest(request)
    }

    static func redeemReward(email: String, points: Int, reward: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/loyalty/redeem"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "reward": reward
        ])

        return try await performLoyaltyRequest(request)
    }

    static func earnPoints(email: String, points: Int, note: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/loyalty/earn"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "note": note
        ])

        return try await performLoyaltyRequest(request)
    }

    private static func performLoyaltyRequest(_ request: URLRequest) async throws -> ContentView.LoyaltyAccount {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.LoyaltyAccount.self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service could not complete your request.")
    }
}

#if canImport(PassKit) && canImport(UIKit)
private struct WalletPassView: UIViewControllerRepresentable {
    let pass: PKPass

    func makeUIViewController(context: Context) -> UIViewController {
        guard let controller = PKAddPassesViewController(pass: pass) else {
            return UIViewController()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
#endif

#if canImport(SafariServices) && canImport(UIKit)
private struct CheckoutWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}
#else
private struct CheckoutWebView: View {
    let url: URL

    var body: some View {
        VStack(spacing: 16) {
            Text("Checkout is only available on iPhone.")
                .font(.headline)
            Text(url.absoluteString)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
}
#endif

private enum ShopifyStorefrontClient {
    private static let endpoint = URL(string: "https://\(ShopifyConfiguration.shopDomain)/api/2025-10/graphql.json")!

    static func fetchAllProducts() async throws -> [ContentView.Product] {
        var products: [ContentView.Product] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            let response = try await fetchPage(after: cursor)

            products.append(contentsOf: response.products.edges.compactMap { edge in
                guard ContentView.Product.shouldInclude(shopifyNode: edge.node) else {
                    return nil
                }
                return ContentView.Product(shopifyNode: edge.node)
            })

            hasNextPage = response.products.pageInfo.hasNextPage
            cursor = response.products.pageInfo.endCursor
        }

        return products
    }

    static func fetchBrewingMethods() async throws -> [ContentView.BrewingMethod] {
        let body = ShopifyGraphQLRequest(
            query: """
            query BrewingArticles($handle: String!, $query: String!) {
              blog(handle: $handle) {
                articles(first: 12) {
                  edges {
                    node {
                      id
                      handle
                      title
                      excerpt
                      content(truncateAt: 180)
                      tags
                      onlineStoreUrl
                      blog {
                        handle
                        title
                      }
                    }
                  }
                }
              }
              articles(first: 12, sortKey: PUBLISHED_AT, reverse: true, query: $query) {
                edges {
                  node {
                    id
                    handle
                    title
                    excerpt
                    content(truncateAt: 180)
                    tags
                    onlineStoreUrl
                    blog {
                      handle
                      title
                    }
                  }
                }
              }
            }
            """,
            variables: [
                "handle": ShopifyConfiguration.brewingBlogHandle,
                "query": ShopifyConfiguration.brewingArticlesQuery
            ]
        )

        let decoded: ShopifyBrewingArticlesResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        let nodesFromBlog = decoded.data?.blog?.articles.edges.map(\.node) ?? []
        let fallbackNodes = decoded.data?.articles.edges.map(\.node) ?? []
        let selectedNodes = nodesFromBlog.isEmpty ? fallbackNodes : nodesFromBlog

        guard !selectedNodes.isEmpty else {
            throw ShopifyError.api("No brewing articles are available in Shopify yet.")
        }

        return selectedNodes.map(ContentView.BrewingMethod.init(article:))
    }

    static func createCustomerAccessToken(email: String, password: String) async throws -> ShopifyCustomerSession {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CustomerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
              customerAccessTokenCreate(input: $input) {
                customerAccessToken {
                  accessToken
                  expiresAt
                }
                customerUserErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": [
                    "email": email,
                    "password": password
                ]
            ]
        )

        let decoded: ShopifyCustomerAccessTokenCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.customerAccessTokenCreate.customerUserErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let session = decoded.data?.customerAccessTokenCreate.customerAccessToken else {
            throw ShopifyError.invalidResponse
        }

        return session
    }

    static func createCustomer(firstName: String, lastName: String, email: String, password: String) async throws -> ShopifyCustomerCreateResponse.CreatedCustomer {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CustomerCreate($input: CustomerCreateInput!) {
              customerCreate(input: $input) {
                customer {
                  id
                }
                customerUserErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": [
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    "password": password
                ]
            ]
        )

        let decoded: ShopifyCustomerCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.customerCreate.customerUserErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let customer = decoded.data?.customerCreate.customer else {
            throw ShopifyError.invalidResponse
        }

        return customer
    }

    static func fetchCustomer(accessToken: String) async throws -> ContentView.ShopifyCustomerProfile {
        let body = ShopifyGraphQLRequest(
            query: """
            query Customer($customerAccessToken: String!) {
              customer(customerAccessToken: $customerAccessToken) {
                id
                firstName
                lastName
                email
              }
            }
            """,
            variables: [
                "customerAccessToken": accessToken
            ]
        )

        let decoded: ShopifyCustomerQueryResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let customer = decoded.data?.customer else {
            throw ShopifyError.api("Your account session has expired. Please sign in again.")
        }

        return ContentView.ShopifyCustomerProfile(
            id: customer.id,
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email
        )
    }

    private static func fetchPage(after cursor: String?) async throws -> ShopifyProductsResponse.DataPayload {
        let body = ShopifyGraphQLRequest(
            query: """
            query Products($cursor: String) {
              products(first: 50, after: $cursor, sortKey: TITLE) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
                edges {
                  node {
                    id
                    title
                    description
                    tags
                    productType
                    featuredImage {
                      url
                    }
                    variants(first: 1) {
                      edges {
                        node {
                          id
                          availableForSale
                        }
                      }
                    }
                    priceRange {
                      minVariantPrice {
                        amount
                        currencyCode
                      }
                    }
                  }
                }
              }
            }
            """,
            variables: ["cursor": cursor as Any]
        )

        let decoded: ShopifyProductsResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let payload = decoded.data else {
            throw ShopifyError.invalidResponse
        }

        return payload
    }

    static func createCheckoutURL(lines: [ShopifyCheckoutLine], checkoutAddress: ShopifyCheckoutAddress? = nil) async throws -> URL {
        let lineInputs = lines.map { line in
            [
                "merchandiseId": line.merchandiseId,
                "quantity": line.quantity
            ] as [String: Any]
        }

        let input: [String: Any]
        if let checkoutAddress {
            let nameParts = checkoutAddress.fullName
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            let firstName = nameParts.first ?? checkoutAddress.fullName
            let lastName = nameParts.dropFirst().joined(separator: " ")
            let deliveryAddress: [String: Any] = [
                "address1": checkoutAddress.address1,
                "city": checkoutAddress.city,
                "country": "Bahrain",
                "firstName": firstName,
                "lastName": lastName,
                "phone": checkoutAddress.phone
            ]
            let deliveryAddressPreference: [String: Any] = [
                "deliveryAddress": deliveryAddress
            ]
            let buyerIdentity: [String: Any] = [
                "email": checkoutAddress.email,
                "phone": checkoutAddress.phone,
                "deliveryAddressPreferences": [deliveryAddressPreference]
            ]

            input = [
                "lines": lineInputs,
                "buyerIdentity": buyerIdentity
            ]
        } else {
            input = [
                "lines": lineInputs
            ]
        }

        let body = ShopifyGraphQLRequest(
            query: """
            mutation CreateCart($input: CartInput) {
              cartCreate(input: $input) {
                cart {
                  checkoutUrl
                }
                userErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": input
            ]
        )

        let decoded: ShopifyCartCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.cartCreate.userErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let checkoutURL = decoded.data?.cartCreate.cart?.checkoutUrl else {
            throw ShopifyError.invalidResponse
        }

        return checkoutURL
    }

    private static func performRequest<Response: Decodable>(_ body: ShopifyGraphQLRequest) async throws -> Response {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ShopifyConfiguration.storefrontToken, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")
        request.httpBody = try JSONSerialization.data(withJSONObject: body.dictionary, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ShopifyError.invalidResponse
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct ShopifyConfiguration {
    static let shopDomain = "duneroastery.myshopify.com"
    static let storefrontToken = "0b8e38878678cd9b9db8325f88f95141"
    static let accountLoginURL = URL(string: "https://\(shopDomain)/account/login")!
    static let accountRegisterURL = URL(string: "https://\(shopDomain)/account/register")!
    static let brewingBlogHandle = "brewing-methods"
    static let brewingArticlesQuery = "blog_title:\"Brewing Methods\" OR tag:brewing OR tag:brew"
}

private struct ShopifyGraphQLRequest {
    let query: String
    let variables: [String: Any]

    var dictionary: [String: Any] {
        [
            "query": query,
            "variables": variables
        ]
    }
}

private struct ShopifyProductsResponse: Decodable {
    let data: DataPayload?
    let errors: [GraphQLError]?

    struct DataPayload: Decodable {
        let products: ProductConnection
    }

    struct ProductConnection: Decodable {
        let pageInfo: PageInfo
        let edges: [ProductEdge]
    }

    struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
    }

    struct ProductEdge: Decodable {
        let node: ShopifyProductNode
    }

    struct GraphQLError: Decodable {
        let message: String
    }
}

private struct ShopifyProductNode: Decodable {
    let id: String
    let title: String
    let description: String
    let tags: [String]
    let productType: String
    let featuredImage: FeaturedImage?
    let variants: VariantConnection
    let priceRange: PriceRange

    struct FeaturedImage: Decodable {
        let url: URL
    }

    struct PriceRange: Decodable {
        let minVariantPrice: Money
    }

    struct VariantConnection: Decodable {
        let edges: [VariantEdge]
    }

    struct VariantEdge: Decodable {
        let node: ProductVariant
    }

    struct ProductVariant: Decodable {
        let id: String
        let availableForSale: Bool
    }

    struct Money: Decodable {
        let amount: String
        let currencyCode: String
    }
}

private enum ShopifyError: LocalizedError {
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The Shopify response was invalid."
        case .api(let message):
            return message
        }
    }
}

private struct ShopifyCheckoutLine {
    let merchandiseId: String
    let quantity: Int
}

private struct ShopifyCheckoutAddress {
    let email: String
    let fullName: String
    let phone: String
    let address1: String
    let city: String
}

private struct ShopifyCartCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let cartCreate: CartCreatePayload
    }

    struct CartCreatePayload: Decodable {
        let cart: Cart?
        let userErrors: [UserError]
    }

    struct Cart: Decodable {
        let checkoutUrl: URL
    }

    struct UserError: Decodable {
        let message: String
    }
}

private struct ShopifyCustomerSession: Decodable {
    let accessToken: String
    let expiresAt: String
}

private struct ShopifyCustomerAccessTokenCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customerAccessTokenCreate: CustomerAccessTokenCreatePayload
    }

    struct CustomerAccessTokenCreatePayload: Decodable {
        let customerAccessToken: ShopifyCustomerSession?
        let customerUserErrors: [ShopifyCustomerUserError]
    }

    struct ShopifyCustomerUserError: Decodable {
        let message: String
    }
}

private struct ShopifyCustomerQueryResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customer: Customer?
    }

    struct Customer: Decodable {
        let id: String
        let firstName: String?
        let lastName: String?
        let email: String
    }
}

private struct ShopifyCustomerCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customerCreate: CustomerCreatePayload
    }

    struct CustomerCreatePayload: Decodable {
        let customer: CreatedCustomer?
        let customerUserErrors: [ShopifyCustomerAccessTokenCreateResponse.ShopifyCustomerUserError]
    }

    struct CreatedCustomer: Decodable {
        let id: String
    }
}

private struct ShopifyBrewingArticlesResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let blog: Blog?
        let articles: ArticleConnection
    }

    struct Blog: Decodable {
        let articles: ArticleConnection
    }

    struct ArticleConnection: Decodable {
        let edges: [ArticleEdge]
    }

    struct ArticleEdge: Decodable {
        let node: ArticleNode
    }

    struct ArticleNode: Decodable {
        let id: String
        let handle: String
        let title: String
        let excerpt: String?
        let content: String
        let tags: [String]
        let onlineStoreUrl: URL?
        let blog: BlogSummary
    }

    struct BlogSummary: Decodable {
        let handle: String
        let title: String
    }
}

private struct AccountProfileResponse: Decodable {
    let id: String
    let firstName: String?
    let lastName: String?
    let email: String
}

private struct ServiceErrorResponse: Decodable {
    let error: String
}

private extension ContentView.Product {
    static func shouldInclude(shopifyNode: ShopifyProductNode) -> Bool {
        let source = ([shopifyNode.title, shopifyNode.productType] + shopifyNode.tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("gift card") || source.contains("giftcard") {
            return false
        }

        return true
    }

    init(shopifyNode: ShopifyProductNode) {
        let categoryKey = Self.categoryKey(
            productType: shopifyNode.productType,
            tags: shopifyNode.tags,
            title: shopifyNode.title
        )
        let firstVariant = shopifyNode.variants.edges.first?.node

        self.init(
            id: shopifyNode.id,
            variantID: firstVariant?.id,
            name: shopifyNode.title,
            price: Self.formattedPrice(from: shopifyNode.priceRange.minVariantPrice),
            categoryKey: categoryKey,
            categoryLabel: Self.categoryLabel(productType: shopifyNode.productType, fallbackKey: categoryKey),
            imageURL: shopifyNode.featuredImage?.url,
            desc: shopifyNode.description.isEmpty ? "Freshly synced from Shopify." : shopifyNode.description,
            tag: Self.productTag(from: shopifyNode.tags),
            isAvailableForSale: firstVariant?.availableForSale ?? false
        )
    }

    private static func categoryKey(productType: String, tags: [String], title: String) -> String {
        let source = ([title, productType] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("talla box")
            || source.contains("mini talla box")
            || source.contains("mini coffee box")
            || source.contains("mini arabic coffee box") {
            return "gifts"
        }

        if source.contains("shamali coffee") {
            return "arabic-coffee-beans"
        }

        let trimmedType = productType.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedType.isEmpty {
            let sluggedType = slug(from: trimmedType)
            if sluggedType == "northern-coffee" {
                return "arabic-coffee-beans"
            }
            if sluggedType == "tea" {
                return "ready-made-drinks"
            }
            if sluggedType == "desserts" || sluggedType == "spreads" || sluggedType == "bread" {
                return "crmb-tallas-speciality-bakery"
            }
            return sluggedType
        }

        if source.contains("tea") {
            return "ready-made-drinks"
        }

        if source.contains("dessert") || source.contains("bread") || source.contains("jam") || source.contains("spread") || source.contains("butter") || source.contains("cookie") || source.contains("cake") {
            return "crmb-tallas-speciality-bakery"
        }

        if source.contains("gift") || source.contains("bundle") {
            return "gifts"
        }

        if source.contains("turkish") {
            return "arabic-coffee-beans"
        }

        return "arabic-coffee-beans"
    }

    private static func categoryLabel(productType: String, fallbackKey: String) -> String {
        let trimmedType = productType.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedType.isEmpty, slug(from: trimmedType) != "tea", fallbackKey != "gifts" {
            return trimmedType
        }

        if fallbackKey == "ready-made-drinks" {
            return "Ready-Made Drinks"
        }

        if fallbackKey == "crmb-tallas-speciality-bakery" {
            return "CRMB Talla's Speciality Bakery"
        }

        if fallbackKey == "gifts" {
            return "Talla Boxes"
        }

        if fallbackKey == "other" || fallbackKey == "arabic-coffee-beans" || fallbackKey == "arabic-coffee" {
            return "Arabic & Shamali Coffee"
        }

        return fallbackKey
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private static func slug(from value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    private static func productTag(from tags: [String]) -> String? {
        let preferred = ["BESTSELLER", "NEW", "LOCAL", "PREMIUM", "GIFT"]
        let uppercased = tags.map { $0.uppercased() }
        return preferred.first(where: uppercased.contains)
    }

    private static func formattedPrice(from money: ShopifyProductNode.Money) -> String {
        guard let decimal = Decimal(string: money.amount) else {
            return "\(money.amount) \(money.currencyCode)"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = money.currencyCode == "BHD" ? 3 : 2

        return formatter.string(from: decimal as NSDecimalNumber) ?? "\(money.amount) \(money.currencyCode)"
    }
}

private extension ContentView.BrewingMethod {
    init(article: ShopifyBrewingArticlesResponse.ArticleNode) {
        let summarySource = [article.excerpt, article.content]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Brew guide from Shopify."

        self.init(
            id: article.id,
            name: article.title,
            summary: summarySource,
            detail: article.blog.title,
            symbol: Self.symbol(title: article.title, tags: article.tags),
            articleURL: article.onlineStoreUrl ?? Self.articleURL(blogHandle: article.blog.handle, articleHandle: article.handle),
            categories: Self.categories(title: article.title, tags: article.tags),
            difficulty: Self.difficulty(title: article.title, tags: article.tags),
            brewTime: Self.brewTime(title: article.title, tags: article.tags)
        )
    }

    private static func symbol(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("press") {
            return "cup.and.saucer.fill"
        }

        if source.contains("chemex") || source.contains("filter") {
            return "flask.fill"
        }

        if source.contains("espresso") {
            return "bolt.fill"
        }

        if source.contains("cold") {
            return "snowflake"
        }

        return "drop.fill"
    }

    private static func categories(title: String, tags: [String]) -> [String] {
        let cleanedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !cleanedTags.isEmpty {
            return Array(Set(cleanedTags)).sorted()
        }

        let source = title.lowercased()
        if source.contains("press") {
            return ["Immersion"]
        }

        if source.contains("chemex") || source.contains("pour") {
            return ["Pour Over"]
        }

        if source.contains("espresso") {
            return ["Espresso"]
        }

        if source.contains("cold") {
            return ["Cold Brew"]
        }

        return ["Guide"]
    }

    private static func difficulty(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("espresso") || source.contains("v60") {
            return "Advanced"
        }

        if source.contains("chemex") || source.contains("pour") || source.contains("aeropress") {
            return "Intermediate"
        }

        return "Easy"
    }

    private static func brewTime(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("cold") {
            return "8-12 hr"
        }

        if source.contains("espresso") {
            return "30 sec"
        }

        if source.contains("press") {
            return "4 min"
        }

        if source.contains("chemex") {
            return "4-5 min"
        }

        if source.contains("pour") || source.contains("v60") || source.contains("filter") {
            return "3-4 min"
        }

        return "3-5 min"
    }

    private static func articleURL(blogHandle: String, articleHandle: String) -> URL? {
        URL(string: "https://\(ShopifyConfiguration.shopDomain)/blogs/\(blogHandle)/\(articleHandle)")
    }
}
