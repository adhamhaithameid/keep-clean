import XCTest

final class KeepCleanUITests: XCTestCase {
    func testCleanTabShowsOnlyTheTwoPrimaryActions() {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_MOCK_INPUT")
        app.launch()
        app.activate()

        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertTrue(window.buttons["tab.clean"].waitForExistence(timeout: 5))
        XCTAssertTrue(window.buttons["tab.settings"].exists)
        XCTAssertTrue(window.buttons["tab.about"].exists)
        XCTAssertTrue(window.buttons["Disable Keyboard"].exists)
        XCTAssertTrue(window.buttons["Disable Keyboard + Trackpad for 60 Seconds"].exists)
        XCTAssertTrue(window.staticTexts["Keeps the built-in trackpad active so you can turn the keyboard back on."].exists)
        XCTAssertTrue(window.staticTexts["Turns off the built-in keyboard and trackpad for the selected timer, then restores them automatically."].exists)
    }

    func testSettingsTabShowsDurationAndAutoStartControls() {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_MOCK_INPUT")
        app.launch()
        app.activate()

        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.waitForExistence(timeout: 5))
        window.buttons["tab.settings"].click()

        XCTAssertTrue(window.staticTexts["60 seconds"].waitForExistence(timeout: 5))
        XCTAssertTrue(window.steppers["Choose how long full clean stays active."].exists)
        XCTAssertTrue(window.checkBoxes["Start keyboard disable after opening the app"].exists)
    }

    func testAutoStartCountdownCanBeCanceled() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_MOCK_INPUT", "UITEST_AUTOSTART_ON"]
        app.launch()
        app.activate()

        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertTrue(window.staticTexts["Keyboard disable starts in 3 seconds."].waitForExistence(timeout: 5))
        window.buttons["Cancel Auto-Start"].click()
        XCTAssertFalse(window.staticTexts["Keyboard disable starts in 3 seconds."].exists)
    }

    func testAboutTabShowsLinks() {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_MOCK_INPUT")
        app.launch()
        app.activate()

        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.waitForExistence(timeout: 5))
        window.buttons["tab.about"].click()

        XCTAssertTrue(window.buttons["GitHub Profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(window.buttons["GitHub"].exists)
        XCTAssertTrue(window.buttons["Buy Me a Coffee"].exists)
        XCTAssertTrue(window.staticTexts["Made with love, coffee, VS Code, and Figma."].exists)
    }
}
