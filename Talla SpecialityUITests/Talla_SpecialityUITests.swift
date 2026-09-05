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

    func testCheckoutRequiresExplicitConfirmation() throws {
        let app = launchApp(scenario: "checkout")
        let status = element("checkout.status", in: app)
        let continueButton = element("checkout.continue", in: app)
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "Order total BHD 8.500")
        continueButton.tap()
        XCTAssertEqual(status.label, "Apple Pay selected")
        element("checkout.confirm", in: app).tap()
        XCTAssertEqual(status.label, "Order confirmed")
    }

    func testArabicCheckoutUsesRightToLeftLocalizedContent() throws {
        let app = launchApp(scenario: "arabic")
        XCTAssertTrue(app.staticTexts["arabic.checkout-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["arabic.checkout-title"].label, "الدفع")
        XCTAssertTrue(app.staticTexts["المجموع"].exists)
        XCTAssertTrue(app.staticTexts["٨٫٥٠٠ د.ب"].exists)
    }

    func testAccountDeletionRequiresConfirmationAndClearsIdentity() throws {
        let app = launchApp(scenario: "account-deletion")
        app.buttons["account.delete"].tap()
        XCTAssertTrue(app.alerts["Delete Account Permanently?"].waitForExistence(timeout: 5))
        app.buttons["account.delete.confirm"].firstMatch.tap()
        XCTAssertEqual(app.staticTexts["account.status"].label, "Your account has been deleted")
    }

    func testOfflineCacheRemainsVisibleAndRetryRecovers() throws {
        let app = launchApp(scenario: "offline-recovery")
        XCTAssertTrue(app.staticTexts["offline.cached-brew"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["offline.status"].label, "Offline. Showing saved coffee data.")
        app.buttons["offline.retry"].tap()
        XCTAssertEqual(app.staticTexts["offline.status"].label, "Back online. Your saved coffee data is synced.")
    }

    func testBluetoothInterruptionOffersRecovery() throws {
        let app = launchApp(scenario: "bluetooth-interruption")
        app.buttons["bluetooth.interrupt"].tap()
        XCTAssertEqual(app.staticTexts["bluetooth.status"].label, "Scale connection interrupted")
        app.buttons["bluetooth.reconnect"].tap()
        XCTAssertEqual(app.staticTexts["bluetooth.status"].label, "Acaia scale connected")
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
}
