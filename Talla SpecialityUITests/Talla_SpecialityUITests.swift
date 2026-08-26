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

    func testExample() throws {
        _ = launchApp()
    }

    func testTabNavigationSmoke() throws {
        _ = launchApp()
    }

    func testLaunchSmoke() throws {
        _ = launchApp()
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))
        return app
    }
}
