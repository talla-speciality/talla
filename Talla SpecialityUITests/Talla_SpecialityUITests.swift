//
//  Talla_SpecialityUITests.swift
//  Talla SpecialityUITests
//
//  Created by Ahmad AlBuainain on 15/3/26.
//

import XCTest

final class Talla_SpecialityUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Shop"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Brewing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Account"].waitForExistence(timeout: 5))
    }

    func testTabNavigationSmoke() throws {
        let app = XCUIApplication()
        app.launch()

        let homeExists = app.buttons["Home"].waitForExistence(timeout: 5)
        XCTAssertTrue(homeExists)

        app.buttons["Shop"].tap()
        let shopExists = app.buttons["Shop"].exists
        XCTAssertTrue(shopExists)

        app.buttons["Brewing"].tap()
        let brewingExists = app.buttons["Brewing"].exists
        XCTAssertTrue(brewingExists)

        app.buttons["Account"].tap()
        let accountExists = app.buttons["Account"].exists
        XCTAssertTrue(accountExists)

        app.buttons["Home"].tap()
        let finalHomeExists = app.buttons["Home"].exists
        XCTAssertTrue(finalHomeExists)
    }

    func testLaunchSmoke() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
    }
}
