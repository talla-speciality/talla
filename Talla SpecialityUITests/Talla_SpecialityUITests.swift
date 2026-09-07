//
//  Talla_SpecialityUITests.swift
//  Talla SpecialityUITests
//
//  Created by Ahmad AlBuainain on 15/3/26.
//

import XCTest

final class Talla_SpecialityUITests: XCTestCase {
    private let launchTimeout: TimeInterval = 20

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCheckoutCompletesThroughProductionCheckout() throws {
        let app = launchApp(scenario: "checkout")
        XCTAssertTrue(element("checkout.screen", in: app).waitForExistence(timeout: 8))
        XCTAssertTrue(element("checkout.summary", in: app).waitForExistence(timeout: 5))

        let submit = element("checkout.submit", in: app)
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertTrue(submit.isEnabled)
        submit.tap()

        let status = element("checkout.payment-status", in: app)
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(status, containing: "Payment complete"))
    }

    func testArabicCheckoutUsesRightToLeftLocalizedContent() throws {
        let app = launchApp(scenario: "arabic")
        XCTAssertTrue(element("checkout.screen", in: app).waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["ملخص الطلب"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["الإجمالي"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("checkout.summary", in: app).exists)
    }

    func testAccountDeletionRequiresConfirmationAndClearsIdentity() throws {
        let app = launchApp(scenario: "account-deletion")
        let openDelete = app.buttons["account.navigation.deleteAccount"]
        XCTAssertTrue(openDelete.waitForExistence(timeout: 8))
        openDelete.tap()
        let delete = app.buttons["account.delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        XCTAssertTrue(app.alerts["Delete Account Permanently?"].waitForExistence(timeout: 5))
        app.buttons["account.delete.confirm"].firstMatch.tap()
        let toast = element("toast.banner", in: app)
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        XCTAssertTrue(toast.label.contains("Your account has been deleted"))
    }

    func testOfflineCacheRemainsVisibleAndRetryRecovers() throws {
        let app = launchApp(scenario: "offline-recovery")
        XCTAssertTrue(app.staticTexts["offline.cached-brew"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["offline.status"].label, "Offline. Showing saved coffee data.")
        app.buttons["offline.retry"].tap()
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

    private func launchApp(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["TALLA_UI_TEST_SCENARIO"] = scenario
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))
        return app
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func waitForLabel(_ element: XCUIElement, containing expected: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
