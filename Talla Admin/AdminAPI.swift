import Foundation
import WebKit

struct AdminAPI {
    let baseURL: URL

    static var configured: AdminAPI {
        let configuredValue = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String
        let fallback = "https://talla-backend.onrender.com"
        return AdminAPI(baseURL: URL(string: configuredValue ?? fallback)!)
    }

    private func url(_ path: String) -> URL {
        URL(string: path, relativeTo: baseURL)!.absoluteURL
    }

    private func request(
        _ path: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url(path))
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AdminAPIError.invalidResponse }
        if http.statusCode == 401 { throw AdminAPIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = payload?["error"] as? String ?? "Admin request failed (\(http.statusCode))."
            throw AdminAPIError.server(message)
        }
        return data
    }

    func restoreSession() async throws -> AdminLoginResponse {
        let data = try await request("/admin/api/session")
        return try JSONDecoder().decode(AdminLoginResponse.self, from: data)
    }

    func login(username: String, password: String) async throws -> AdminLoginResponse {
        let data: Data
        do {
            data = try await request("/admin/api/login", method: "POST", body: [
                "username": username,
                "password": password
            ])
        } catch AdminAPIError.unauthorized {
            throw AdminAPIError.server("Incorrect admin username or password.")
        }
        let response = try JSONDecoder().decode(AdminLoginResponse.self, from: data)
        await synchronizeWebCookies()
        return response
    }

    func logout() async throws {
        _ = try await request("/admin/api/logout", method: "POST")
        await clearWebCookies()
    }

    func orders() async throws -> [AdminOrder] {
        let data = try await request("/admin/api/orders")
        return try JSONDecoder().decode(AdminOrdersResponse.self, from: data).orders
    }

    func updateOrder(id: String, status: String) async throws -> [AdminOrder] {
        let data = try await request("/admin/api/orders/status", method: "POST", body: [
            "orderID": id,
            "status": status
        ])
        let response = try JSONDecoder().decode(AdminStatusUpdateResponse.self, from: data)
        if let updatedOrders = response.orders { return updatedOrders }
        return try await orders()
    }

    func notifyReady(orderID: String) async throws -> AdminPushDeliveryResult {
        let data = try await request("/admin/api/orders/notify-ready", method: "POST", body: ["orderID": orderID])
        return try JSONDecoder().decode(AdminNotifyReadyResponse.self, from: data).push
    }

    func registerPushToken(_ token: String) async throws -> Bool {
        #if DEBUG
        let environment = "sandbox"
        #else
        let environment = "production"
        #endif
        let data = try await request("/admin/api/notifications/native/register", method: "POST", body: [
            "deviceToken": token,
            "platform": "ios",
            "environment": environment
        ])
        return try JSONDecoder().decode(AdminPushRegistrationResponse.self, from: data).configured ?? false
    }

    func unregisterPushToken(_ token: String) async throws {
        _ = try await request("/admin/api/notifications/native/unregister", method: "POST", body: ["deviceToken": token])
    }

    @MainActor
    func synchronizeWebCookies() async {
        let cookies = HTTPCookieStorage.shared.cookies(for: baseURL.appending(path: "admin/")) ?? []
        for cookie in cookies where cookie.name == "talla_admin_session" {
            await WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie)
        }
    }

    @MainActor
    private func clearWebCookies() async {
        let store = WKWebsiteDataStore.default().httpCookieStore
        let cookies = await store.allCookies()
        for cookie in cookies where cookie.name == "talla_admin_session" {
            await store.deleteCookie(cookie)
        }
    }
}

private extension WKHTTPCookieStore {
    func setCookie(_ cookie: HTTPCookie) async {
        await withCheckedContinuation { continuation in
            setCookie(cookie) { continuation.resume() }
        }
    }

    func allCookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            getAllCookies { continuation.resume(returning: $0) }
        }
    }

    func deleteCookie(_ cookie: HTTPCookie) async {
        await withCheckedContinuation { continuation in
            delete(cookie) { continuation.resume() }
        }
    }
}
