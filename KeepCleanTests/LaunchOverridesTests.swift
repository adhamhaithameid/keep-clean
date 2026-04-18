import XCTest
@testable import KeepClean

final class LaunchOverridesTests: XCTestCase {
    func testArgumentsEnableMockModeAndAutoStart() {
        let overrides = LaunchOverrides(arguments: ["KeepClean", "UITEST_MOCK_INPUT", "UITEST_AUTOSTART_ON", "UITEST_FULL_CLEAN_ON"])

        XCTAssertTrue(overrides.useMockInputController)
        XCTAssertTrue(overrides.forceAutoStartOn)
        XCTAssertTrue(overrides.forceTimedFullCleanOn)
    }

    func testArgumentsDefaultToDisabledOverrides() {
        let overrides = LaunchOverrides(arguments: ["KeepClean"])

        XCTAssertFalse(overrides.useMockInputController)
        XCTAssertFalse(overrides.forceAutoStartOn)
        XCTAssertFalse(overrides.forceTimedFullCleanOn)
    }
}
