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

actor AccountSessionRefreshCoordinator {
    private var refreshTask: Task<AccountTokenRefreshResponse, Error>?

    func refresh() async throws -> AccountTokenRefreshResponse {
        if let refreshTask { return try await refreshTask.value }
        let task = Task { try await AccountService.performRefreshSession() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}

enum AccountService {
    static let baseURL = BackendConfiguration.serviceBaseURL
    static let refreshCoordinator = AccountSessionRefreshCoordinator()

    enum SessionError: LocalizedError {
        case invalid
        case invalidCredentials
        case deactivated

        var errorDescription: String? {
            switch self {
            case .invalid:
                return "Your account session expired. Sign in again to continue."
            case .invalidCredentials:
                return "The email or password is incorrect."
            case .deactivated:
                return "This account is deactivated. Contact Talla support for help."
            }
        }
    }

    struct CustomerSession {
        let profile: ContentView.ShopifyCustomerProfile
        let accessToken: String
        let expiresAt: String
        let refreshToken: String
        let refreshExpiresAt: String
    }

    struct CheckoutStartResult {
        let orderID: String
        let orders: [ContentView.AccountOrder]
    }

    struct CustomerLibraryMutation: Encodable {
        let action: String
        var favorites: [String]? = nil
        var recentlyViewed: [String]? = nil
        var brewJournal: [ContentView.BrewJournalEntry]? = nil
        var productID: String? = nil
        var favorite: Bool? = nil
        var journal: ContentView.BrewJournalEntry? = nil
        var journalID: String? = nil
    }

    static var accessToken: String {
        TallaAccountCredentialStore.accessToken
    }

    static func authorize(_ request: inout URLRequest, accessTokenOverride: String? = nil) throws {
        let token = (accessTokenOverride ?? accessToken).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            throw ContentView.LoyaltyServiceError.operationFailed("Sign in again to continue.")
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    static func data(for request: URLRequest, allowRefresh: Bool = true) async throws -> (Data, URLResponse) {
        let result = try await TallaSecureSession.data(for: request)
        guard allowRefresh,
              (result.1 as? HTTPURLResponse)?.statusCode == 401,
              request.value(forHTTPHeaderField: "Authorization") != nil,
              !TallaAccountCredentialStore.refreshToken.isEmpty else {
            return result
        }

        let tokens = try await refreshCoordinator.refresh()
        var retry = request
        retry.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        return try await TallaSecureSession.data(for: retry)
    }

    static func refreshSession() async throws -> AccountTokenRefreshResponse {
        try await refreshCoordinator.refresh()
    }

    static func performRefreshSession() async throws -> AccountTokenRefreshResponse {
        guard let baseURL else { throw SessionError.invalid }
        let refreshToken = TallaAccountCredentialStore.refreshToken
        guard !refreshToken.isEmpty else { throw SessionError.invalid }
        var request = URLRequest(url: baseURL.appending(path: "/accounts/session/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refreshToken": refreshToken])
        let (data, response) = try await TallaSecureSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200 ..< 300 ~= httpResponse.statusCode,
              let tokens = try? JSONDecoder().decode(AccountTokenRefreshResponse.self, from: data) else {
            TallaAccountCredentialStore.clear()
            throw SessionError.invalid
        }
        TallaAccountCredentialStore.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        return tokens
    }

    static func register(firstName: String, lastName: String, email: String, password: String) async throws -> CustomerSession {
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

        return try await performCustomerSessionRequest(request)
    }

    static func signIn(email: String, password: String) async throws -> CustomerSession {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/login"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        return try await performCustomerSessionRequest(request)
    }

    static func signInWithApple(
        identityToken: String,
        userIdentifier: String,
        email: String?,
        firstName: String?,
        lastName: String?,
        nonce: String
    ) async throws -> CustomerSession {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var payload: [String: Any] = [
            "identityToken": identityToken,
            "userIdentifier": userIdentifier,
            "nonce": nonce
        ]

        if let email, !email.isEmpty {
            payload["email"] = email
        }

        if let firstName, !firstName.isEmpty {
            payload["firstName"] = firstName
        }

        if let lastName, !lastName.isEmpty {
            payload["lastName"] = lastName
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/apple"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performCustomerSessionRequest(request)
    }

    static func fetchProfile() async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/session"))
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performProfileRequest(request)
    }

    static func fetchCustomerLibrary() async throws -> ContentView.CustomerLibraryPayload {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The customer library service is unavailable.")
        }
        var request = URLRequest(url: baseURL.appending(path: "/customer-library"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)
        return try await performCustomerLibraryRequest(request)
    }

    static func mergeCustomerLibrary(
        favorites: [String],
        recentlyViewed: [String],
        brewJournal: [ContentView.BrewJournalEntry]
    ) async throws -> ContentView.CustomerLibraryPayload {
        try await mutateCustomerLibrary(CustomerLibraryMutation(
            action: "merge",
            favorites: favorites,
            recentlyViewed: recentlyViewed,
            brewJournal: brewJournal
        ))
    }

    static func setFavorite(productID: String, favorite: Bool) async throws -> ContentView.CustomerLibraryPayload {
        try await mutateCustomerLibrary(CustomerLibraryMutation(action: "setFavorite", productID: productID, favorite: favorite))
    }

    static func recordRecentlyViewed(productID: String) async throws -> ContentView.CustomerLibraryPayload {
        try await mutateCustomerLibrary(CustomerLibraryMutation(action: "recordRecent", productID: productID))
    }

    static func clearRecentlyViewed() async throws -> ContentView.CustomerLibraryPayload {
        try await mutateCustomerLibrary(CustomerLibraryMutation(action: "clearRecent"))
    }

    static func saveBrewJournal(_ entry: ContentView.BrewJournalEntry) async throws -> ContentView.CustomerLibraryPayload {
        try await mutateCustomerLibrary(CustomerLibraryMutation(action: "saveJournal", journal: entry))
    }

    static func deleteBrewJournal(id: UUID) async throws -> ContentView.CustomerLibraryPayload {
        try await mutateCustomerLibrary(CustomerLibraryMutation(action: "deleteJournal", journalID: id.uuidString))
    }

    static func mutateCustomerLibrary(_ mutation: CustomerLibraryMutation) async throws -> ContentView.CustomerLibraryPayload {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The customer library service is unavailable.")
        }
        var request = URLRequest(url: baseURL.appending(path: "/customer-library"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONEncoder().encode(mutation)
        return try await performCustomerLibraryRequest(request)
    }

    static func updateProfile(email: String, firstName: String, lastName: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/profile/update"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
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
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ])

        _ = try await performEmptyRequest(request)
    }

    static func deleteAccount() async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/delete"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        _ = try await performEmptyRequest(request)
    }

    static func changePasswordWithoutSignIn(email: String, currentPassword: String, newPassword: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/password/change"))
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

    static func requestPasswordResetLink(email: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/password/request-reset"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email
        ])

        _ = try await performEmptyRequest(request)
    }

    static func fetchOrders(email: String) async throws -> [ContentView.AccountOrder] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/orders"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performOrdersRequest(request)
    }

    static func fetchTasteMemory(email: String) async throws -> [ContentView.TasteMemoryRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/taste-memory"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performTasteMemoryRequest(request)
    }

    static func saveTasteMemory(email: String, orderID: String, productName: String, reaction: String, tags: [String]) async throws -> [ContentView.TasteMemoryRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/taste-memory/save"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "orderID": orderID,
            "productName": productName,
            "reaction": reaction,
            "tags": tags
        ])

        return try await performTasteMemoryEnvelopeRequest(request)
    }

    static func recordCheckoutStarted(
        email: String,
        items: [(name: String, quantity: Int, variantID: String)],
        total: Double,
        fulfillmentMethod: TallaFulfillmentMethod,
        address: ContentView.DeliveryAddress?,
        paymentMethod: TallaPaymentMethod
    ) async throws -> CheckoutStartResult {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service is unavailable.")
        }

        let orderItems = items.map { item in
            [
                "name": item.name,
                "quantity": item.quantity,
                "variantId": item.variantID
            ] as [String: Any]
        }

        var request = URLRequest(url: baseURL.appending(path: "/orders/checkout-started"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        var payload: [String: Any] = [
            "email": email,
            "title": fulfillmentMethod == .pickup ? "Pickup order" : "Delivery order",
            "total": total,
            "fulfillmentMethod": fulfillmentMethod.rawValue,
            "paymentMethod": paymentMethod.rawValue,
            "source": "Talla iOS app",
            "items": orderItems
        ]
        if let address {
            payload["customer"] = ["fullName": address.fullName, "phone": address.phone]
            payload["fulfillment"] = [
                "method": fulfillmentMethod.rawValue,
                "fullName": address.fullName,
                "phone": address.phone,
                "line1": address.line1,
                "city": address.city,
                "countryCode": address.country.rawValue,
                "notes": address.notes ?? ""
            ]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performCheckoutStartRequest(request)
    }

    static func createBenefitPayment(orderID: String) async throws -> URL {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/api/payments/benefit/create"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "orderID": orderID
        ])

        return try await performBenefitPaymentRequest(request)
    }

    static func fetchBenefitPaymentStatus(orderID: String) async throws -> BenefitHostedPaymentStatus {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/api/payments/benefit/status"))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["orderID": orderID])

        let (data, response) = try await data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service returned an invalid response.")
        }
        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(BenefitHostedPaymentStatus.self, from: data)
        }
        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }
        throw ContentView.LoyaltyServiceError.operationFailed("The payment service could not confirm the payment.")
    }

    static func createEazyShopifyPaymentSession(tallaPaymentID: String) async throws -> EazyShopifyPaymentResponse {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service is unavailable.")
        }
        var request = URLRequest(url: baseURL.appending(path: "/api/payments/eazy/shopify/session"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["tallaPaymentId": tallaPaymentID])
        return try await performEazyShopifyPaymentRequest(request)
    }

    static func fetchEazyShopifyPaymentStatus(tallaPaymentID: String) async throws -> EazyShopifyPaymentResponse {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service is unavailable.")
        }
        var components = URLComponents(url: baseURL.appending(path: "/api/payments/eazy/shopify/status"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "tallaPaymentId", value: tallaPaymentID)]
        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment status URL is invalid.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)
        return try await performEazyShopifyPaymentRequest(request)
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
        try authorize(&request)

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
        try authorize(&request)

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
        ] as [String : Any]
        if let tag = alert.tag {
            payload["tag"] = tag
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/watch"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
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
        try authorize(&request)
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
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "alerts": payloadAlerts
        ])

        return try await performStockAlertsRequest(request)
    }

    static func registerPushDeviceToken(email: String, deviceToken: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The notifications service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/notifications/push/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "deviceToken": deviceToken,
            "platform": "ios"
        ])

        _ = try await performEmptyRequest(request)
    }

    static func unregisterPushDeviceToken(
        email: String,
        deviceToken: String,
        accessTokenOverride: String? = nil
    ) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The notifications service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/notifications/push/unregister"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request, accessTokenOverride: accessTokenOverride)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "deviceToken": deviceToken
        ])

        _ = try await performEmptyRequest(request)
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
        try authorize(&request)

        return try await performAddressesRequest(request)
    }

    static func saveAddress(email: String, label: String, fullName: String, phone: String, line1: String, city: String, countryCode: String, notes: String?) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var payload: [String: Any] = [
            "email": email,
            "label": label,
            "fullName": fullName,
            "phone": phone,
            "line1": line1,
            "city": city,
            "countryCode": countryCode,
            "isPreferred": true
        ]
        if let notes {
            payload["notes"] = notes
        }

        var request = URLRequest(url: baseURL.appending(path: "/addresses/save"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
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
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "addressID": addressID
        ])

        return try await performAddressesRequest(request)
    }

    static func setPreferredAddress(email: String, addressID: String) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/addresses/preferred"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
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
        try authorize(&request)

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
        try authorize(&request)
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
        try authorize(&request)
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
        try authorize(&request)

        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try await Task.detached(priority: .userInitiated) {
                guard let pass = try? PKPass(data: data) else {
                    throw ContentView.LoyaltyServiceError.operationFailed("The Wallet pass could not be loaded.")
                }
                return pass
            }.value
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The wallet service could not complete your request.")
    }
#endif

    static func performCustomerSessionRequest(_ request: URLRequest) async throws -> CustomerSession {
        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(AccountSessionResponse.self, from: data)
            return CustomerSession(
                profile: ContentView.ShopifyCustomerProfile(
                    id: decoded.profile.id,
                    firstName: decoded.profile.firstName,
                    lastName: decoded.profile.lastName,
                    email: decoded.profile.email
                ),
                accessToken: decoded.accessToken,
                expiresAt: decoded.expiresAt,
                refreshToken: decoded.refreshToken,
                refreshExpiresAt: decoded.refreshExpiresAt
            )
        }

        if httpResponse.statusCode == 401 {
            throw SessionError.invalidCredentials
        }

        if httpResponse.statusCode == 403 {
            throw SessionError.deactivated
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The account service could not complete your request.")
    }

    static func performProfileRequest(_ request: URLRequest) async throws -> ContentView.ShopifyCustomerProfile {
        let (data, response) = try await data(for: request)

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

        if [401, 403].contains(httpResponse.statusCode) {
            throw SessionError.invalid
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The account service could not complete your request.")
    }

    static func performCustomerLibraryRequest(_ request: URLRequest) async throws -> ContentView.CustomerLibraryPayload {
        let (data, response) = try await data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The customer library returned an invalid response.")
        }
        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.CustomerLibraryPayload.self, from: data)
        }
        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }
        throw ContentView.LoyaltyServiceError.operationFailed("The customer library could not complete your request.")
    }

    static func performOrdersRequest(_ request: URLRequest) async throws -> [ContentView.AccountOrder] {
        let (data, response) = try await data(for: request)

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

    static func performCheckoutStartRequest(_ request: URLRequest) async throws -> CheckoutStartResult {
        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(CheckoutStartResponse.self, from: data)
            return CheckoutStartResult(orderID: decoded.orderID, orders: decoded.orders)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The orders service could not complete your request.")
    }

    static func performBenefitPaymentRequest(_ request: URLRequest) async throws -> URL {
        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(BenefitPaymentResponse.self, from: data)
            return decoded.paymentUrl
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The payment service could not complete your request.")
    }

    static func performEazyShopifyPaymentRequest(_ request: URLRequest) async throws -> EazyShopifyPaymentResponse {
        let (data, response) = try await data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service returned an invalid response.")
        }
        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(EazyShopifyPaymentResponse.self, from: data)
        }
        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }
        throw ContentView.LoyaltyServiceError.operationFailed("The payment service could not complete your request.")
    }

    static func performTasteMemoryRequest(_ request: URLRequest) async throws -> [ContentView.TasteMemoryRecord] {
        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.TasteMemoryRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service could not complete your request.")
    }

    static func performTasteMemoryEnvelopeRequest(_ request: URLRequest) async throws -> [ContentView.TasteMemoryRecord] {
        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(TasteMemoryResponse.self, from: data).tasteMemory
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service could not complete your request.")
    }

    static func performVouchersRequest(_ request: URLRequest) async throws -> [ContentView.VoucherRecord] {
        let (data, response) = try await data(for: request)

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

    static func performStockAlertsRequest(_ request: URLRequest) async throws -> [ContentView.StockAlertRecord] {
        let (data, response) = try await data(for: request)

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

    static func performStockAlertRequest(_ request: URLRequest) async throws -> ContentView.StockAlertRecord {
        let (data, response) = try await data(for: request)

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

    static func performAlertInboxRequest(_ request: URLRequest) async throws -> [ContentView.AlertInboxRecord] {
        let (data, response) = try await data(for: request)

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

    static func performAddressesRequest(_ request: URLRequest) async throws -> [ContentView.DeliveryAddress] {
        let (data, response) = try await data(for: request)

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

    static func performVoucherRequest(_ request: URLRequest) async throws -> ContentView.VoucherRecord {
        let (data, response) = try await data(for: request)

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

    static func performEmptyRequest(_ request: URLRequest) async throws -> Bool {
        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return true
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The account service could not complete your request.")
    }
}
