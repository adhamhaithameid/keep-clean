import AppKit
import XCTest
@testable import KeepClean

@MainActor
final class AppDelegateTests: XCTestCase {
    func testTerminationCallbackRunsWhenAppWillTerminate() {
        let delegate = AppDelegate()
        var didCall = false
        delegate.onWillTerminate = {
            didCall = true
        }

        delegate.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification))

        XCTAssertTrue(didCall)
    }

    func testClosingLastWindowTerminatesApp() {
        let delegate = AppDelegate()

        XCTAssertTrue(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
    }
}
