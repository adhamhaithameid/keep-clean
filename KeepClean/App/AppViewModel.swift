@preconcurrency import ApplicationServices
import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: "com.adhamhaithameid.keepclean", category: "AppViewModel")

@MainActor
final class AppViewModel: ObservableObject {
    let settings: AppSettings

    @Published var selectedTab: AppTab = .clean
    @Published var activeSession: LockSession?
    @Published var statusMessage = "Ready"
    @Published var remainingTimedLockSeconds: Int?
    @Published var autoStartCountdownSecondsRemaining: Int?

    // Permission tracking
    @Published var hasAccessibility = false
    @Published var hasInputMonitoring = false

    // Toast notification system
    @Published var toastMessage: String?
    @Published var toastIsError: Bool = false
    private var toastDismissTask: Task<Void, Never>?
    private var permissionPollTask: Task<Void, Never>?

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
    func refreshPermissions() {
        hasAccessibility = AXIsProcessTrusted()
        // Input Monitoring: try multiple detection methods.
        // 1. Test event tap creation (most reliable runtime check)
        // 2. CGPreflightListenEventAccess() as fallback
        hasInputMonitoring = checkInputMonitoringAvailable()
        logger.debug("Permissions refreshed: accessibility=\(self.hasAccessibility), inputMonitoring=\(self.hasInputMonitoring)")
    }

    /// Check if Input Monitoring is available using multiple methods.
    private func checkInputMonitoringAvailable() -> Bool {
        // Method 1: Try creating a test listenOnly event tap.
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback = inputMonitoringTestCallback as CGEventTapCallBack
        if let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: nil
        ) {
            CFMachPortInvalidate(tap)
            return true
        }

        // Method 2: Official API (may not update in real-time).
        return CGPreflightListenEventAccess()
    }

    /// Prompt for Accessibility and open the settings pane.
    func promptAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
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

        Task {
            await manualKeyboardLease?.release()
            await timedLease?.release()
        }

        lockCoordinator.clear()
        helperProcess = nil
        manualKeyboardLease = nil
        timedLease = nil
        activeSession = nil
        remainingTimedLockSeconds = nil
        autoStartCountdownSecondsRemaining = nil
        toastMessage = nil
        statusMessage = "KeepClean closed."
    }

    // MARK: - Keyboard Toggle

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
            let lease = try await inputController.lock(target: .keyboard)
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
            let lease = try await inputController.lock(target: .keyboardAndTrackpad)
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
        remainingTimedLockSeconds = nil
        helperProcess = nil
        lockCoordinator.clear()
        activeSession = nil
        statusMessage = "Done! Input re-enabled."
        showToast("Cleaning session completed.", isError: false)
    }

    private func secondsUntil(_ endDate: Date) -> Int {
        max(Int(ceil(endDate.timeIntervalSinceNow)), 0)
    }
}

// MARK: - Input Monitoring Test Callback

/// Free function usable as a C function pointer for test event tap creation.
/// Simply passes events through — we only need the tap creation to succeed
/// to prove Input Monitoring is granted.
private func inputMonitoringTestCallback(
    _ proxy: CGEventTapProxy,
    _ type: CGEventType,
    _ event: CGEvent,
    _ userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    Unmanaged.passUnretained(event)
}
