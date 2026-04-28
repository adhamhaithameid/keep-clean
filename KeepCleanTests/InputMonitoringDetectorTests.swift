import XCTest
@testable import KeepClean

/// Tests for InputMonitoringDetector.
///
/// NOTE: On a machine without Input Monitoring granted, all four methods return
/// false and `isGranted()` returns false. On a machine with it granted (e.g.,
/// during CI with a signed test runner), it should return true.
/// These tests verify the API contracts, not the actual permission state.
final class InputMonitoringDetectorTests: XCTestCase {

    func testIsGrantedReturnsBoolWithoutCrashing() {
        // Simply calling the detector must not crash or throw.
        let result = InputMonitoringDetector.isGranted()
        XCTAssertTrue(result == true || result == false) // tautology — verifies no crash
    }

    func testIsGrantedIsDeterministicWithinSameProcess() {
        // Multiple consecutive calls should return the same result
        // (permissions don't change spontaneously during a test run).
        let first = InputMonitoringDetector.isGranted()
        let second = InputMonitoringDetector.isGranted()
        XCTAssertEqual(first, second)
    }

    func testIsGrantedPerformance() {
        // The detector should be fast enough not to block the main thread.
        // Measure that 10 consecutive calls complete in a reasonable time.
        measure {
            for _ in 0..<10 {
                _ = InputMonitoringDetector.isGranted()
            }
        }
    }
}
