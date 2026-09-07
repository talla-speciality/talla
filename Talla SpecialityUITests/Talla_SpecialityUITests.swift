//
//  Talla_SpecialityUITests.swift
//  Talla SpecialityUITests
//
//  Created by Ahmad AlBuainain on 15/3/26.
//

import Network
import XCTest

final class Talla_SpecialityUITests: XCTestCase {
    private let launchTimeout: TimeInterval = 20

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCheckoutReachesAuthenticatedOrderAndPaymentServices() throws {
        let server = try TallaUITestServer()
        defer { server.stop() }
        let app = launchApp(scenario: "checkout", backendURL: server.baseURL)
        XCTAssertTrue(element("checkout.screen", in: app).waitForExistence(timeout: 8))
        XCTAssertTrue(element("checkout.summary", in: app).waitForExistence(timeout: 5))

        let submit = element("checkout.submit", in: app)
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertTrue(submit.isEnabled)
        tapWhenHittable(submit, in: app)

        let orderRequest = try XCTUnwrap(server.waitForRequest(path: "/orders/checkout-started", timeout: 15))
        XCTAssertEqual(orderRequest.method, "POST")
        XCTAssertEqual(orderRequest.authorization, "Bearer ui-test-access-token")
        let paymentRequest = try XCTUnwrap(server.waitForRequest(path: "/api/payments/benefit/create", timeout: 15))
        XCTAssertEqual(paymentRequest.method, "POST")
        XCTAssertEqual(paymentRequest.authorization, "Bearer ui-test-access-token")
        XCTAssertNotNil(server.waitForRequest(path: "/hosted-payment", timeout: 15))
        dismissHostedCheckout(in: app)
    }

    func testArabicCheckoutUsesRightToLeftLocalizedContent() throws {
        let server = try TallaUITestServer()
        defer { server.stop() }
        let app = launchApp(scenario: "arabic", backendURL: server.baseURL)
        XCTAssertTrue(element("checkout.screen", in: app).waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["ملخص الطلب"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["الإجمالي"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("checkout.summary", in: app).exists)

        let submit = element("checkout.submit", in: app)
        tapWhenHittable(submit, in: app)
        XCTAssertNotNil(server.waitForRequest(path: "/orders/checkout-started", timeout: 15))
        XCTAssertNotNil(server.waitForRequest(path: "/api/payments/benefit/create", timeout: 15))
        XCTAssertNotNil(server.waitForRequest(path: "/hosted-payment", timeout: 15))
        dismissHostedCheckout(in: app)
    }

    func testAccountDeletionRequiresConfirmationAndClearsIdentity() throws {
        let server = try TallaUITestServer()
        defer { server.stop() }
        let app = launchApp(scenario: "account-deletion", backendURL: server.baseURL)
        let openDelete = app.buttons["account.navigation.deleteAccount"]
        XCTAssertTrue(openDelete.waitForExistence(timeout: 8))
        openDelete.tap()
        let delete = app.buttons["account.delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        XCTAssertTrue(app.alerts["Delete Account Permanently?"].waitForExistence(timeout: 5))
        app.buttons["account.delete.confirm"].firstMatch.tap()
        let request = try XCTUnwrap(server.waitForRequest(path: "/accounts/delete", timeout: 15))
        XCTAssertEqual(request.authorization, "Bearer ui-test-access-token")
        let toast = element("toast.banner", in: app)
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        XCTAssertTrue(toast.label.contains("Your account has been deleted"))
    }

    func testOfflineCacheRemainsVisibleAndRetryRecovers() throws {
        let server = try TallaUITestServer()
        defer { server.stop() }
        let app = launchApp(scenario: "offline-recovery", backendURL: server.baseURL)
        XCTAssertTrue(app.staticTexts["offline.cached-brew"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["offline.status"].label, "Offline. Showing saved coffee data.")
        app.buttons["offline.retry"].tap()
        let request = try XCTUnwrap(server.waitForRequest(path: "/coffee-data/sync", timeout: 15))
        XCTAssertEqual(request.authorization, "Bearer ui-test-access-token")
        XCTAssertTrue(waitForLabel(app.staticTexts["offline.status"], containing: "Back online"))
    }

    func testBluetoothInterruptionOffersRecovery() throws {
        let app = launchApp(scenario: "bluetooth-interruption")
        XCTAssertTrue(app.buttons["bluetooth.interrupt"].waitForExistence(timeout: 8))
        app.buttons["bluetooth.interrupt"].tap()
        XCTAssertTrue(waitForLabel(element("bluetooth.status", in: app), containing: "Scale connection interrupted"))
        XCTAssertTrue(app.buttons["bluetooth.reconnect"].waitForExistence(timeout: 5))
        app.buttons["bluetooth.reconnect"].tap()
        XCTAssertTrue(waitForLabel(element("bluetooth.status", in: app), containing: "Connected and ready for your next brew"))
    }

    private func launchApp(scenario: String, backendURL: URL? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["TALLA_UI_TEST_SCENARIO"] = scenario
        app.launchEnvironment["TALLA_UI_TEST_ACCESS_TOKEN"] = "ui-test-access-token"
        app.launchEnvironment["TALLA_UI_TEST_REFRESH_TOKEN"] = "ui-test-refresh-token"
        if let backendURL {
            app.launchEnvironment["TALLA_BACKEND_BASE_URL"] = backendURL.absoluteString
        }
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))
        return app
    }

    private func dismissHostedCheckout(in app: XCUIApplication) {
        for title in ["Done", "تم"] {
            let button = app.buttons[title].firstMatch
            if button.waitForExistence(timeout: 2) {
                button.tap()
                return
            }
        }
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func tapWhenHittable(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<3 where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Expected \(element.identifier) to be hittable")
        element.tap()
    }

    private func waitForLabel(_ element: XCUIElement, containing expected: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}

private final class TallaUITestServer: @unchecked Sendable {
    struct Request {
        let method: String
        let path: String
        let authorization: String?
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "TallaUITestServer")
    private let lock = NSLock()
    private var capturedRequests: [Request] = []
    private var startupError: Error?
    private let ready = DispatchSemaphore(value: 0)
    private(set) var baseURL: URL!

    init() throws {
        listener = try NWListener(using: .tcp, on: .any)
        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                ready.signal()
            case .failed(let error):
                startupError = error
                ready.signal()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)

        guard ready.wait(timeout: .now() + 5) == .success else {
            throw NSError(domain: "TallaUITestServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock service did not start."])
        }
        if let startupError { throw startupError }
        guard let port = listener.port,
              let url = URL(string: "http://127.0.0.1:\(port.rawValue)") else {
            throw NSError(domain: "TallaUITestServer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock service has no port."])
        }
        baseURL = url
    }

    func stop() {
        listener.cancel()
    }

    func waitForRequest(path: String, timeout: TimeInterval) -> Request? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            lock.lock()
            let request = capturedRequests.last { $0.path == path }
            lock.unlock()
            if let request { return request }
            Thread.sleep(forTimeInterval: 0.02)
        } while Date() < deadline
        return nil
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, accumulated: Data())
    }

    private func receive(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, complete, error in
            guard let self else { return }
            var requestData = accumulated
            if let data { requestData.append(data) }
            if requestIsComplete(requestData) || complete {
                respond(to: requestData, on: connection)
            } else if error == nil {
                receive(on: connection, accumulated: requestData)
            } else {
                connection.cancel()
            }
        }
    }

    private func requestIsComplete(_ data: Data) -> Bool {
        let marker = Data("\r\n\r\n".utf8)
        guard let headerEnd = data.range(of: marker),
              let headers = String(data: data[..<headerEnd.lowerBound], encoding: .utf8) else { return false }
        let contentLength = headers.components(separatedBy: "\r\n")
            .first { $0.lowercased().hasPrefix("content-length:") }
            .flatMap { Int($0.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces) ?? "") } ?? 0
        return data.count >= headerEnd.upperBound + contentLength
    }

    private func respond(to data: Data, on connection: NWConnection) {
        guard let raw = String(data: data, encoding: .utf8),
              let firstLine = raw.components(separatedBy: "\r\n").first else {
            connection.cancel()
            return
        }
        let parts = firstLine.split(separator: " ")
        let method = parts.first.map(String.init) ?? ""
        let target = parts.count > 1 ? String(parts[1]) : "/"
        let path = target.split(separator: "?", maxSplits: 1).first.map(String.init) ?? target
        let authorization = raw.components(separatedBy: "\r\n")
            .first { $0.lowercased().hasPrefix("authorization:") }
            .map { String($0.dropFirst("authorization:".count)).trimmingCharacters(in: .whitespaces) }

        lock.lock()
        capturedRequests.append(Request(method: method, path: path, authorization: authorization))
        lock.unlock()

        let contentType: String
        let body: String
        switch path {
        case "/orders/checkout-started":
            contentType = "application/json"
            body = #"{"orderID":"ui-order-1","orders":[{"id":"ui-order-1","title":"Pickup order","total":"8.500","status":"pending","items":[{"name":"Release Test Coffee","quantity":1}],"createdAt":"2026-09-07T00:00:00Z","beansAwarded":false,"pointsAwarded":0}],"pricingVersion":2}"#
        case "/api/payments/benefit/create":
            contentType = "application/json"
            body = #"{"paymentUrl":"\#(baseURL.absoluteString)/hosted-payment","trackId":"ui-track-1"}"#
        case "/coffee-data/sync":
            contentType = "application/json"
            body = #"{"records":[],"conflicts":[],"cursor":"0","hasMore":false}"#
        case "/hosted-payment":
            contentType = "text/html; charset=utf-8"
            body = "<html><body><h1>Secure payment handoff</h1></body></html>"
        default:
            contentType = "application/json"
            body = "{}"
        }
        let bodyData = Data(body.utf8)
        let headers = "HTTP/1.1 200 OK\r\nContent-Type: \(contentType)\r\nContent-Length: \(bodyData.count)\r\nConnection: close\r\n\r\n"
        var response = Data(headers.utf8)
        response.append(bodyData)
        connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
    }
}
