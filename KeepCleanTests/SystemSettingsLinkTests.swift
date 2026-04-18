import XCTest
@testable import KeepClean

final class SystemSettingsLinkTests: XCTestCase {
    func testPrivacyAndSecurityUsesSystemPreferencesScheme() {
        XCTAssertEqual(SystemSettingsLink.privacyAndSecurity.url.scheme, "x-apple.systempreferences")
    }

    func testPrivacyAndSecurityPointsToExpectedPane() {
        XCTAssertEqual(
            SystemSettingsLink.privacyAndSecurity.url.absoluteString,
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
        )
    }
}
