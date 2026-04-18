import Foundation
import XCTest
@testable import KeepClean

final class HelperProcessLauncherTests: XCTestCase {
    func testLaunchThrowsWhenHelperIsMissing() {
        let launcher = HelperProcessLauncher(helperURLProvider: { nil })
        let request = HelperLaunchRequest(
            target: .keyboardAndTrackpad,
            durationSeconds: 60,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertThrowsError(try launcher.launch(request: request)) { error in
            guard case KeepCleanError.helperMissing = error else {
                return XCTFail("Expected helperMissing, got \(error)")
            }
        }
    }

    func testLaunchPassesBase64PayloadToHelper() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let outputURL = directory.appendingPathComponent("args.txt")
        let scriptURL = directory.appendingPathComponent("helper.sh")
        try """
        #!/bin/sh
        printf '%s\\n' "$@" > "\(outputURL.path)"
        exit 0
        """.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let request = HelperLaunchRequest(
            target: .keyboardAndTrackpad,
            durationSeconds: 45,
            startedAt: Date(timeIntervalSince1970: 1_700_000_123)
        )
        let launcher = HelperProcessLauncher(helperURLProvider: { scriptURL })

        let process = try launcher.launch(request: request)
        process.waitUntilExit()

        let arguments = try String(contentsOf: outputURL, encoding: .utf8)
            .split(separator: "\n")
            .map(String.init)
        XCTAssertEqual(arguments.first, "--payload-base64")

        let payloadData = try XCTUnwrap(Data(base64Encoded: try XCTUnwrap(arguments.last)))
        let decoded = try JSONDecoder().decode(HelperLaunchRequest.self, from: payloadData)
        XCTAssertEqual(decoded, request)
    }
}
