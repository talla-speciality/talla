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
        XCTAssertTrue(app.buttons["Shop"].exists)
        XCTAssertTrue(app.buttons["Brewing"].exists)
        XCTAssertTrue(app.buttons["Account"].exists)
        XCTAssertTrue(app.buttons["Open cart"].exists)
    }

    func testTabNavigationSmoke() throws {
        let app = XCUIApplication()
        app.launch()

        let homeButton = app.buttons["Home"]
        let shopButton = app.buttons["Shop"]
        let brewingButton = app.buttons["Brewing"]
        let accountButton = app.buttons["Account"]

        XCTAssertTrue(homeButton.waitForExistence(timeout: 5))
        shopButton.tap()
        XCTAssertTrue(app.buttons["Shop"].exists)
        brewingButton.tap()
        XCTAssertTrue(app.buttons["Brewing"].exists)
        accountButton.tap()
        XCTAssertTrue(app.buttons["Account"].exists)
        homeButton.tap()
        XCTAssertTrue(app.buttons["Home"].exists)
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
