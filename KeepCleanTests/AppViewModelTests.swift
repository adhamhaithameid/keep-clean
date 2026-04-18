import Foundation
import XCTest
@testable import KeepClean

@MainActor
final class AppViewModelTests: XCTestCase {
    func testHandleInitialAppearanceStartsMonitoringOnlyOnce() async throws {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let model = makeModel(inputController: controller)

        model.handleInitialAppearance()
        model.handleInitialAppearance()

        try await waitFor {
            await controller.prepareCallCount() == 1
        }
        XCTAssertEqual(model.statusMessage, "Built-in input ready.")
    }

    func testToggleKeyboardLockStartsAndStopsManualSession() async throws {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let model = makeModel(inputController: controller)

        await model.toggleKeyboardLock()

        XCTAssertEqual(model.activeSession?.target, .keyboard)
        XCTAssertEqual(model.keyboardButtonTitle, "Re-enable Keyboard")
        XCTAssertFalse(model.canTriggerTimedAction)
        let lockedTargetsAfterStart = await controller.recordedTargets()
        XCTAssertEqual(lockedTargetsAfterStart, [.keyboard])

        await model.toggleKeyboardLock()

        XCTAssertNil(model.activeSession)
        XCTAssertEqual(model.keyboardButtonTitle, "Disable Keyboard")
        XCTAssertEqual(model.statusMessage, "Built-in input ready.")
    }

    func testToggleKeyboardLockSurfacesPermissionErrors() async {
        let controller = TestBuiltInInputController(
            availability: "Built-in input ready.",
            nextLockError: KeepCleanError.permissionDenied("Allow access.")
        )
        let model = makeModel(inputController: controller)

        await model.toggleKeyboardLock()

        XCTAssertNil(model.activeSession)
        XCTAssertEqual(
            model.errorMessage,
            "macOS denied input access. Allow access."
        )
        XCTAssertTrue(model.shouldOfferPrivacyAndSecurityHelp)
        XCTAssertEqual(model.statusMessage, "Built-in input ready.")
        XCTAssertTrue(model.canTriggerKeyboardAction)
    }

    func testToggleKeyboardLockCancelsAutoStartCountdown() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.autoStartKeyboardDisableOnLaunch = true
        let model = makeModel(settings: settings, inputController: controller)

        model.handleInitialAppearance()
        XCTAssertEqual(model.autoStartCountdownSecondsRemaining, 3)

        await model.toggleKeyboardLock()

        XCTAssertNil(model.autoStartCountdownSecondsRemaining)
        XCTAssertEqual(model.activeSession?.target, .keyboard)
    }

    func testTimedFullCleanWithMockControllerStartsSessionUsingConfiguredDuration() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.fullCleanDurationSeconds = 15
        let model = makeModel(
            settings: settings,
            inputController: controller,
            launchOverrides: LaunchOverrides(useMockInputController: true, forceAutoStartOn: false, forceTimedFullCleanOn: false)
        )

        await model.startTimedFullClean()

        XCTAssertEqual(model.activeSession?.target, .keyboardAndTrackpad)
        XCTAssertEqual(model.activeSession?.owner, .helper)
        XCTAssertNotNil(model.remainingTimedLockSeconds)
        XCTAssertLessThanOrEqual(model.remainingTimedLockSeconds ?? 0, 15)
        XCTAssertGreaterThan(model.remainingTimedLockSeconds ?? 0, 0)
        let lockedTargets = await controller.recordedTargets()
        XCTAssertEqual(lockedTargets, [.keyboardAndTrackpad])

        model.handleAppTermination()
    }

    func testTimedFullCleanMockFailureRestoresAvailabilityStatus() async {
        let controller = TestBuiltInInputController(
            availability: "Built-in input ready.",
            nextLockError: KeepCleanError.devicesUnavailable
        )
        let model = makeModel(
            inputController: controller,
            launchOverrides: LaunchOverrides(useMockInputController: true, forceAutoStartOn: false, forceTimedFullCleanOn: false)
        )

        await model.startTimedFullClean()

        XCTAssertNil(model.activeSession)
        XCTAssertEqual(
            model.errorMessage,
            "KeepClean couldn't find the built-in keyboard and trackpad yet. If macOS asks for approval, please allow access and try again."
        )
        XCTAssertEqual(model.statusMessage, "Built-in input ready.")
    }

    func testTimedFullCleanIgnoredWhileAnotherSessionIsActive() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let model = makeModel(
            inputController: controller,
            launchOverrides: LaunchOverrides(useMockInputController: true, forceAutoStartOn: false, forceTimedFullCleanOn: false)
        )

        await model.toggleKeyboardLock()
        let lockedTargetsBeforeSecondAction = await controller.recordedTargets()

        await model.startTimedFullClean()

        XCTAssertEqual(model.activeSession?.target, .keyboard)
        let lockedTargetsAfterSecondAction = await controller.recordedTargets()
        XCTAssertEqual(lockedTargetsBeforeSecondAction, lockedTargetsAfterSecondAction)
    }

    func testTimedFullCleanHelperMissingRestoresAvailabilityStatus() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let model = makeModel(
            inputController: controller,
            helperLauncher: HelperProcessLauncher(helperURLProvider: { nil }),
            launchOverrides: LaunchOverrides(useMockInputController: false, forceAutoStartOn: false, forceTimedFullCleanOn: false)
        )

        await model.startTimedFullClean()

        XCTAssertNil(model.activeSession)
        XCTAssertEqual(model.errorMessage, "The timed cleaning helper is missing from the app bundle.")
        XCTAssertFalse(model.shouldOfferPrivacyAndSecurityHelp)
        XCTAssertEqual(model.statusMessage, "Built-in input ready.")
    }

    func testFullCleanButtonTitleTracksSettingsDuration() {
        let settings = makeSettings(testName: #function)
        settings.fullCleanDurationSeconds = 90
        let model = makeModel(settings: settings)

        XCTAssertEqual(model.fullCleanButtonTitle, "Disable Keyboard + Trackpad for 90 Seconds")
    }

    func testCancelAutoStartClearsCountdown() {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.autoStartKeyboardDisableOnLaunch = true
        let model = makeModel(settings: settings, inputController: controller)

        model.handleInitialAppearance()
        XCTAssertEqual(model.autoStartCountdownSecondsRemaining, 3)

        model.cancelAutoStart()

        XCTAssertNil(model.autoStartCountdownSecondsRemaining)
        XCTAssertNil(model.activeSession)
        XCTAssertEqual(model.statusMessage, "Auto-start canceled. You can trigger keyboard cleaning manually.")
    }

    func testAutoStartEventuallyLocksKeyboardWithMockController() async throws {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.autoStartKeyboardDisableOnLaunch = true
        let model = makeModel(
            settings: settings,
            inputController: controller,
            launchOverrides: LaunchOverrides(useMockInputController: true, forceAutoStartOn: false, forceTimedFullCleanOn: false)
        )

        model.handleInitialAppearance()

        try await waitFor(timeoutNanoseconds: 5_000_000_000) {
            model.activeSession?.target == .keyboard
        }
        let lockedTargets = await controller.recordedTargets()
        XCTAssertEqual(lockedTargets, [.keyboard])

        model.handleAppTermination()
    }

    func testHandleAppTerminationClearsVisibleState() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.autoStartKeyboardDisableOnLaunch = true
        let model = makeModel(
            settings: settings,
            inputController: controller,
            launchOverrides: LaunchOverrides(useMockInputController: true, forceAutoStartOn: false, forceTimedFullCleanOn: false)
        )

        await model.startTimedFullClean()
        model.handleInitialAppearance()

        model.handleAppTermination()

        XCTAssertNil(model.activeSession)
        XCTAssertNil(model.remainingTimedLockSeconds)
        XCTAssertNil(model.autoStartCountdownSecondsRemaining)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.statusMessage, "KeepClean closed. Built-in input remains available.")
    }

    func testOpenDelegatesToLinkOpener() {
        let opener = TestLinkOpener()
        let model = makeModel(linkOpener: opener)

        model.open(.repository)

        XCTAssertEqual(opener.openedURLs, [ExternalLink.repository.url])
    }

    func testOpenPrivacyAndSecurityDelegatesToLinkOpener() {
        let opener = TestLinkOpener()
        let model = makeModel(linkOpener: opener)

        model.openPrivacyAndSecurity()

        XCTAssertEqual(opener.openedURLs, [SystemSettingsLink.privacyAndSecurity.url])
    }

    func testTimedFullCleanReportsEarlyHelperExit() async throws {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let helperURL = try makeExecutableScript(contents: """
        #!/bin/sh
        sleep 0.2
        exit 1
        """)
        let launcher = HelperProcessLauncher(helperURLProvider: { helperURL })
        let model = makeModel(
            inputController: controller,
            helperLauncher: launcher,
            launchOverrides: LaunchOverrides(useMockInputController: false, forceAutoStartOn: false, forceTimedFullCleanOn: false)
        )

        await model.startTimedFullClean()
        XCTAssertEqual(model.activeSession?.target, .keyboardAndTrackpad)

        try await waitFor(timeoutNanoseconds: 3_000_000_000) {
            model.activeSession == nil
        }
        XCTAssertEqual(model.errorMessage, "The cleaning helper exited early.")
    }

    private func makeModel(
        settings: AppSettings? = nil,
        inputController: TestBuiltInInputController = TestBuiltInInputController(),
        helperLauncher: HelperProcessLauncher = HelperProcessLauncher(helperURLProvider: { nil }),
        linkOpener: TestLinkOpener = TestLinkOpener(),
        launchOverrides: LaunchOverrides = LaunchOverrides(useMockInputController: false, forceAutoStartOn: false, forceTimedFullCleanOn: false)
    ) -> AppViewModel {
        AppViewModel(
            settings: settings ?? makeSettings(testName: #function),
            inputController: inputController,
            helperLauncher: helperLauncher,
            linkOpener: linkOpener,
            launchOverrides: launchOverrides
        )
    }

    private func makeSettings(testName: String) -> AppSettings {
        let defaults = UserDefaults(suiteName: testName)!
        defaults.removePersistentDomain(forName: testName)
        return AppSettings(userDefaults: defaults)
    }

    private func makeExecutableScript(contents: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let scriptURL = directory.appendingPathComponent("helper.sh")
        try contents.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        return scriptURL
    }

    private func waitFor(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @MainActor () async -> Bool
    ) async throws {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for condition.")
    }
}

private actor TestBuiltInInputController: BuiltInInputControlling {
    private var prepareCalls = 0
    private var lockedTargets: [BuiltInInputTarget] = []
    private let availability: String
    private let nextLockError: Error?

    init(
        availability: String = "Built-in input ready.",
        nextLockError: Error? = nil
    ) {
        self.availability = availability
        self.nextLockError = nextLockError
    }

    func prepareMonitoring() async {
        prepareCalls += 1
    }

    func availabilitySummary() async -> String {
        availability
    }

    func lock(target: BuiltInInputTarget) async throws -> InputLockLease {
        if let nextLockError {
            throw nextLockError
        }

        lockedTargets.append(target)
        return InputLockLease(target: target, retainedObjects: [NSObject()])
    }

    func prepareCallCount() -> Int {
        prepareCalls
    }

    func recordedTargets() -> [BuiltInInputTarget] {
        lockedTargets
    }
}

private final class TestLinkOpener: LinkOpening {
    private(set) var openedURLs: [URL] = []

    func open(_ url: URL) {
        openedURLs.append(url)
    }
}
