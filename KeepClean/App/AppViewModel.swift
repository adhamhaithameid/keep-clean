import AppKit
@preconcurrency import ApplicationServices
import Combine
import Foundation
import UserNotifications
import os.log
import os.signpost

// MARK: - Structured Loggers (#28)
private let logger = Logger(subsystem: "com.adhamhaithameid.keepclean", category: "AppViewModel")
private let sessionLog = Logger(subsystem: "com.adhamhaithameid.keepclean", category: "sessions")
private let perfLog = OSLog(subsystem: "com.adhamhaithameid.keepclean", category: .pointsOfInterest)

@MainActor
final class AppViewModel: ObservableObject {
    let settings: AppSettings

    @Published var selectedTab: AppTab = .clean
    @Published var activeSession: LockSession?
    @Published var statusMessage = "Ready"
    @Published var remainingTimedLockSeconds: Int?
    @Published var autoStartCountdownSecondsRemaining: Int?

    // Permission tracking
    @Published private(set) var hasAccessibility = false
    @Published private(set) var hasInputMonitoring = false

    // Toast notification system
    @Published var toastMessage: String?
    @Published var toastIsError: Bool = false

    // #13 undo window
    @Published var undoPendingMode: AppSettings.CleanMode?

    // #7 confetti trigger
    @Published var showConfetti: Bool = false

    private var toastDismissTask: Task<Void, Never>?
    private var permissionPollTask: Task<Void, Never>?
    private var undoTask: Task<Void, Never>?

    private let inputController: any BuiltInInputControlling
    private let helperLauncher: HelperProcessLauncher
    private let linkOpener: any LinkOpening
    private let launchOverrides: LaunchOverrides

    private var lockCoordinator = LockStateCoordinator()
    private var manualKeyboardLease: InputLockLease?
    private var timedLease: InputLockLease?
    private var helperProcess: Process?
    private var timedCountdownTask: Task<Void, Never>?
    private var autoStartTask: Task<Void, Never>?
    private var didHandleInitialLaunch = false

    init(
        settings: AppSettings,
        inputController: any BuiltInInputControlling,
        helperLauncher: HelperProcessLauncher,
        linkOpener: any LinkOpening,
        launchOverrides: LaunchOverrides
    ) {
        self.settings = settings
        self.inputController = inputController
        self.helperLauncher = helperLauncher
        self.linkOpener = linkOpener
        self.launchOverrides = launchOverrides

        // Initial permission check
        refreshPermissions()
    }

    // MARK: - Permission State

    /// True when both permissions are granted.
    var allPermissionsGranted: Bool {
        hasAccessibility && hasInputMonitoring
    }

    /// Refresh permission state (called by polling and manually).
    /// In mock/UI test mode this is a no-op — permissions are set once by AppEnvironment
    /// via setPermissionsForTesting() and must not be overwritten by live TCC checks.
    func refreshPermissions() {
        guard !launchOverrides.useMockInputController else { return }
        hasAccessibility = AXIsProcessTrusted()
        // Delegate to the shared 4-method detector — single source of truth.
        hasInputMonitoring = InputMonitoringDetector.isGranted()
        logger.debug(
            "Permissions refreshed: accessibility=\(self.hasAccessibility), inputMonitoring=\(self.hasInputMonitoring)"
        )
    }

    /// Internal helper for tests — bypasses system TCC checks so permission
    /// logic can be exercised without needing a real macOS permission grant.
    func setPermissionsForTesting(accessibility: Bool, inputMonitoring: Bool) {
        hasAccessibility = accessibility
        hasInputMonitoring = inputMonitoring
    }

    /// Prompt for Accessibility and open the settings pane.
    func promptAccessibility() {
        let options =
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        SystemSettingsLink.accessibility.open()
        startPermissionPolling()
    }

    /// Open Input Monitoring settings pane and request permission.
    func promptInputMonitoring() {
        // Trigger the system consent dialog for Input Monitoring.
        CGRequestListenEventAccess()
        SystemSettingsLink.inputMonitoring.open()
        startPermissionPolling()
    }

    /// Start polling permissions after the user is sent to System Settings.
    func startPermissionPolling() {
        permissionPollTask?.cancel()
        permissionPollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(800))
                self?.refreshPermissions()
            }
        }
    }

    func stopPermissionPolling() {
        permissionPollTask?.cancel()
        permissionPollTask = nil
    }

    // MARK: - Computed State

    /// Whether the keyboard-only lock is currently active.
    var isKeyboardLocked: Bool {
        manualKeyboardLease != nil
    }

    /// Whether the timed full clean (keyboard + trackpad) is active.
    var isTimedSessionActive: Bool {
        activeSession?.target == .keyboardAndTrackpad
    }

    /// Whether the keyboard-only button can be used.
    var canToggleKeyboard: Bool {
        !isTimedSessionActive
    }

    /// Whether the timed full clean button can be used.
    var canStartTimedClean: Bool {
        activeSession == nil
    }

    // MARK: - Lifecycle

    func handleInitialAppearance() {
        guard !didHandleInitialLaunch else {
            return
        }

        didHandleInitialLaunch = true

        Task {
            await inputController.prepareMonitoring()
            statusMessage = await inputController.availabilitySummary()
        }

        if launchOverrides.forceTimedFullCleanOn {
            Task {
                await startTimedFullClean()
            }
        } else if launchOverrides.forceAutoStartOn || settings.autoStartKeyboardDisableOnLaunch {
            beginAutoStartCountdown()
        }
    }

    func handleAppTermination() {
        timedCountdownTask?.cancel()
        autoStartTask?.cancel()
        permissionPollTask?.cancel()

        // Release device locks synchronously so the hardware is never left blocked
        // if the process exits before an async Task gets scheduled.
        let keyboard = manualKeyboardLease
        let timed = timedLease
        manualKeyboardLease = nil
        timedLease = nil

        if keyboard != nil || timed != nil {
            let sem = DispatchSemaphore(value: 0)
            Task.detached {
                await keyboard?.release()
                await timed?.release()
                sem.signal()
            }
            // Wait up to 2 s — plenty for a HID/tap teardown.
            _ = sem.wait(timeout: .now() + 2)
        }

        lockCoordinator.clear()
        helperProcess = nil
        activeSession = nil
        remainingTimedLockSeconds = nil
        autoStartCountdownSecondsRemaining = nil
        toastMessage = nil
        statusMessage = "KeepClean closed."
    }

    // MARK: - Keyboard Toggle

    // MARK: - Emergency Stop

    /// Called when the user presses Left ⌘ + Right ⌘ + 1 + 0 while a session is active.
    /// Cancels whichever session is currently running and re-enables input.
    func handleEmergencyStop() async {
        logger.info("Emergency stop shortcut triggered.")
        if isTimedSessionActive {
            await cancelTimedSession()
        } else if isKeyboardLocked {
            await toggleKeyboardLock()
        }
    }

    /// Returns a `@Sendable` emergency-stop closure if the feature is enabled,
    /// or a no-op closure when it's disabled. Using a function avoids Swift's
    /// type-inference limitation with `@Sendable` in ternary expressions.
    private func makeEmergencyStopHandler() -> @Sendable () -> Void {
        guard settings.emergencyStopEnabled else { return {} }
        return { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handleEmergencyStop()
            }
        }
    }

    func toggleKeyboardLock() async {
        toastMessage = nil
        autoStartTask?.cancel()
        autoStartCountdownSecondsRemaining = nil

        // Check current permission state
        guard hasAccessibility else {
            showToast("Accessibility permission required. Click \"Grant\" above.", isError: true)
            return
        }
        guard hasInputMonitoring else {
            showToast("Input Monitoring permission required. Click \"Grant\" above.", isError: true)
            return
        }

        if let manualKeyboardLease {
            await manualKeyboardLease.release()
            self.manualKeyboardLease = nil
            lockCoordinator.clear()
            activeSession = nil
            statusMessage = await inputController.availabilitySummary()
            showToast("Keyboard re-enabled.", isError: false)
            return
        }

        do {
            let lease = try await inputController.lock(
                target: .keyboard,
                onEmergencyStop: makeEmergencyStopHandler()
            )
            manualKeyboardLease = lease
            activeSession = lockCoordinator.beginManual(target: .keyboard, owner: .app)
            statusMessage = "Keyboard disabled."
        } catch {
            showErrorToast(error)
        }
    }

    // MARK: - Timed Full Clean

    func startTimedFullClean() async {
        guard activeSession == nil else {
            return
        }

        toastMessage = nil
        autoStartTask?.cancel()
        autoStartCountdownSecondsRemaining = nil

        // Check current permission state
        guard hasAccessibility else {
            showToast("Accessibility permission required. Click \"Grant\" above.", isError: true)
            return
        }
        guard hasInputMonitoring else {
            showToast("Input Monitoring permission required. Click \"Grant\" above.", isError: true)
            return
        }

        do {
            let lease = try await inputController.lock(
                target: .keyboardAndTrackpad,
                onEmergencyStop: makeEmergencyStopHandler()
            )
            timedLease = lease
            let session = lockCoordinator.beginTimed(
                target: .keyboardAndTrackpad,
                durationSeconds: settings.fullCleanDurationSeconds,
                owner: .app
            )
            activeSession = session
            startTimedCountdown(until: session.endsAt)
            statusMessage = "Keyboard and trackpad disabled."
        } catch {
            showErrorToast(error)
        }
    }

    /// Cancel a running timed session early.
    func cancelTimedSession() async {
        timedCountdownTask?.cancel()
        if let timedLease {
            await timedLease.release()
            self.timedLease = nil
        }
        helperProcess?.terminate()
        helperProcess = nil
        lockCoordinator.clear()
        activeSession = nil
        remainingTimedLockSeconds = nil
        statusMessage = await inputController.availabilitySummary()
        showToast("Input re-enabled.", isError: false)
    }

    // MARK: - Auto-Start

    func cancelAutoStart() {
        autoStartTask?.cancel()
        autoStartCountdownSecondsRemaining = nil
        statusMessage = "Auto-start canceled."
    }

    // MARK: - Links & Settings

    func open(_ link: ExternalLink) {
        linkOpener.open(link.url)
    }

    func openPrivacyAndSecurity() {
        SystemSettingsLink.privacyAndSecurity.open()
    }

    // MARK: - Toast Notifications

    func showToast(_ message: String, isError: Bool) {
        toastDismissTask?.cancel()
        toastMessage = message
        toastIsError = isError
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(isError ? 8 : 3))
            guard !Task.isCancelled else { return }
            self.toastMessage = nil
        }
    }

    func dismissToast() {
        toastDismissTask?.cancel()
        toastMessage = nil
    }

    // MARK: - Private

    private func showErrorToast(_ error: Error) {
        let message: String
        if let keepCleanError = error as? KeepCleanError {
            switch keepCleanError {
            case .permissionDenied(let details):
                message = details
            case .keyboardUnavailable:
                message = "Built-in keyboard not found."
            case .trackpadUnavailable:
                message = "Built-in trackpad not found. The keyboard was still disabled."
            case .seizeFailed(let details):
                message = details
            case .devicesUnavailable:
                message = "No built-in input devices found."
            case .helperMissing:
                message = "Helper tool is missing from the app bundle."
            case .invalidHelperArguments:
                message = "Internal error in helper communication."
            }
        } else {
            message = error.localizedDescription
        }
        showToast(message, isError: true)
    }

    private func beginAutoStartCountdown() {
        autoStartTask?.cancel()
        autoStartCountdownSecondsRemaining = 3
        statusMessage = "Auto-start in 3s..."

        autoStartTask = Task { [weak self] in
            guard let self else { return }

            for remaining in stride(from: 3, through: 1, by: -1) {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.autoStartCountdownSecondsRemaining = remaining
                }
                try? await Task.sleep(for: .seconds(1))
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.autoStartCountdownSecondsRemaining = nil
            }
            await self.toggleKeyboardLock()
        }
    }

    private func startTimedCountdown(until endDate: Date?) {
        timedCountdownTask?.cancel()

        guard let endDate else {
            return
        }

        remainingTimedLockSeconds = secondsUntil(endDate)

        timedCountdownTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                let remaining = self.secondsUntil(endDate)
                await MainActor.run {
                    self.remainingTimedLockSeconds = remaining
                }

                if remaining <= 0 {
                    await self.timedLease?.release()
                    await MainActor.run {
                        self.timedLease = nil
                        self.finishTimedSession()
                    }
                    return
                }

                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func finishTimedSession() {
        timedCountdownTask?.cancel()
        let duration = settings.fullCleanDurationSeconds
        remainingTimedLockSeconds = nil
        helperProcess = nil
        lockCoordinator.clear()
        activeSession = nil
        statusMessage = "Done! Input re-enabled."
        showToast("Cleaning session completed.", isError: false)

        // #10 record history
        settings.recordCompletedSession(mode: .timed, durationSeconds: duration)
        // #7 confetti — ConfettiBurst observes this via onChange and animates itself
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { self.showConfetti = false }
        // #8 clear dock badge
        updateDockBadge(active: false)
        // #12 post notification
        postCompletionNotification()
        // #24 sound
        playSound("Glass")

        sessionLog.info("Timed session finished, duration=\(duration)s")
    }

    // MARK: - #8 Dock Badge

    func updateDockBadge(active: Bool) {
        NSApp.dockTile.badgeLabel = active ? "●" : nil
    }

    // MARK: - #11 Sleep Auto-End

    func handleMacSleep() {
        guard activeSession != nil || isKeyboardLocked else { return }
        Task {
            if isKeyboardLocked { await toggleKeyboardLock() } else { await cancelTimedSession() }
        }
        logger.info("Session auto-ended due to Mac sleep")
    }

    // MARK: - #12 System Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
            granted, _ in
            DispatchQueue.main.async { self.settings.notificationsEnabled = granted }
        }
    }

    private func postCompletionNotification() {
        guard settings.notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "KeepClean ✓"
        content.body = "Your cleaning session is done. Input has been re-enabled."
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    // MARK: - #13 3-Second Undo Window

    private func armUndoWindow(mode: AppSettings.CleanMode) {
        undoTask?.cancel()
        undoPendingMode = mode
        undoTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.undoPendingMode = nil }
        }
    }

    func undoLastAction() {
        undoTask?.cancel()
        undoPendingMode = nil
        Task {
            if isKeyboardLocked {
                await toggleKeyboardLock()
            } else if isTimedSessionActive {
                await cancelTimedSession()
            }
        }
        showToast("Action undone.", isError: false)
    }

    // MARK: - #14 Repeat Last Session (⌘R)

    func repeatLastSession() {
        guard !isKeyboardLocked && !isTimedSessionActive else { return }
        Task {
            switch settings.lastUsedCleanMode {
            case .keyboard: await toggleKeyboardLock()
            case .timed: await startTimedFullClean()
            }
        }
        sessionLog.info("Repeating last session: \(self.settings.lastUsedCleanMode.rawValue)")
    }

    // MARK: - #24 Sound Effects

    func playSound(_ name: String) {
        guard settings.soundsEnabled else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    private func secondsUntil(_ endDate: Date) -> Int {
        max(Int(ceil(endDate.timeIntervalSinceNow)), 0)
    }
}

// MARK: - Xcode Preview Factory (#30)

extension AppViewModel {
    static func preview() -> AppViewModel {
        let settings = AppSettings(userDefaults: .standard)
        settings.setupCompleted = true
        let model = AppViewModel(
            settings: settings,
            inputController: MockBuiltInInputController(),
            helperLauncher: HelperProcessLauncher(),
            linkOpener: WorkspaceLinkOpener(),
            launchOverrides: LaunchOverrides(arguments: ["UITEST_MOCK_INPUT"])
        )
        model.setPermissionsForTesting(accessibility: true, inputMonitoring: true)
        return model
    }
}
