import XCTest
@testable import KeepClean

final class ExternalLinkTests: XCTestCase {
    func testAllLinksUseHTTPS() {
        for link in ExternalLink.allCases {
            XCTAssertEqual(link.url.scheme, "https")
        }
    }

    func testLinksPointToExpectedDestinations() {
        XCTAssertEqual(ExternalLink.donation.url.absoluteString, "https://buymeacoffee.com/adhamhaithameid")
        XCTAssertEqual(ExternalLink.repository.url.absoluteString, "https://github.com/adhamhaithameid/keep-clean")
        XCTAssertEqual(ExternalLink.profile.url.absoluteString, "https://github.com/adhamhaithameid")
    }
}
