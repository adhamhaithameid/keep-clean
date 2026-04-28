import Combine
import Foundation

// MARK: - Session History Model

struct StoredSession: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let mode: AppSettings.CleanMode
    let startedAt: Date
    let durationSeconds: Int

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    var formattedDate: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: startedAt, relativeTo: Date())
    }
}

// MARK: - App Settings

@MainActor
final class AppSettings: ObservableObject {
    static let defaultDurationSeconds = 60
    static let minimumDurationSeconds = 15
    static let maximumDurationSeconds = 300

    private enum Keys {
        static let duration = "fullCleanDurationSeconds"
        static let autoStart = "autoStartKeyboardDisableOnLaunch"
        static let setupCompleted = "permissionSetupCompleted"
        static let lastUsedMode = "lastUsedCleanMode"
        static let soundsEnabled = "soundEffectsEnabled"
        static let notificationsOn = "sessionNotificationsEnabled"
        static let sessionHistory = "sessionHistoryJSON"
        static let totalSessions = "totalCompletedSessions"
        static let totalLockSeconds = "totalLockedSeconds"
        static let emergencyStopEnabled = "emergencyStopEnabled"
    }

    private let userDefaults: UserDefaults

    // MARK: - Settings

    @Published var fullCleanDurationSeconds: Int {
        didSet {
            let clamped = Self.clamp(fullCleanDurationSeconds)
            if fullCleanDurationSeconds != clamped {
                fullCleanDurationSeconds = clamped
                return
            }
            userDefaults.set(clamped, forKey: Keys.duration)
        }
    }

    @Published var autoStartKeyboardDisableOnLaunch: Bool {
        didSet { userDefaults.set(autoStartKeyboardDisableOnLaunch, forKey: Keys.autoStart) }
    }

    @Published var setupCompleted: Bool {
        didSet { userDefaults.set(setupCompleted, forKey: Keys.setupCompleted) }
    }

    enum CleanMode: String, Codable {
        case keyboard = "keyboard"
        case timed = "timed"
    }

    @Published var lastUsedCleanMode: CleanMode {
        didSet { userDefaults.set(lastUsedCleanMode.rawValue, forKey: Keys.lastUsedMode) }
    }

    @Published var soundsEnabled: Bool {
        didSet { userDefaults.set(soundsEnabled, forKey: Keys.soundsEnabled) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { userDefaults.set(notificationsEnabled, forKey: Keys.notificationsOn) }
    }

    @Published var emergencyStopEnabled: Bool {
        didSet { userDefaults.set(emergencyStopEnabled, forKey: Keys.emergencyStopEnabled) }
    }

    // MARK: - Session History

    @Published var sessionHistory: [StoredSession] {
        didSet { saveSessionHistory() }
    }

    @Published var totalCompletedSessions: Int {
        didSet { userDefaults.set(totalCompletedSessions, forKey: Keys.totalSessions) }
    }

    @Published var totalLockedSeconds: Int {
        didSet { userDefaults.set(totalLockedSeconds, forKey: Keys.totalLockSeconds) }
    }

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let duration =
            userDefaults.object(forKey: Keys.duration) as? Int ?? Self.defaultDurationSeconds
        self.fullCleanDurationSeconds = Self.clamp(duration)

        self.autoStartKeyboardDisableOnLaunch =
            userDefaults.object(forKey: Keys.autoStart) as? Bool ?? false

        self.setupCompleted =
            userDefaults.object(forKey: Keys.setupCompleted) as? Bool ?? false

        let modeRaw = userDefaults.string(forKey: Keys.lastUsedMode) ?? CleanMode.keyboard.rawValue
        self.lastUsedCleanMode = CleanMode(rawValue: modeRaw) ?? .keyboard

        self.soundsEnabled =
            userDefaults.object(forKey: Keys.soundsEnabled) as? Bool ?? true
        self.notificationsEnabled = userDefaults.bool(forKey: Keys.notificationsOn)
        self.emergencyStopEnabled =
            userDefaults.object(forKey: Keys.emergencyStopEnabled) as? Bool ?? true

        self.totalCompletedSessions = userDefaults.integer(forKey: Keys.totalSessions)
        self.totalLockedSeconds = userDefaults.integer(forKey: Keys.totalLockSeconds)

        if let data = userDefaults.data(forKey: Keys.sessionHistory),
            let decoded = try? JSONDecoder().decode([StoredSession].self, from: data)
        {
            self.sessionHistory = decoded
        } else {
            self.sessionHistory = []
        }

        userDefaults.set(self.fullCleanDurationSeconds, forKey: Keys.duration)
        userDefaults.set(self.autoStartKeyboardDisableOnLaunch, forKey: Keys.autoStart)
    }

    // MARK: - Session Tracking

    func recordCompletedSession(mode: CleanMode, durationSeconds: Int) {
        let session = StoredSession(
            id: UUID(), mode: mode,
            startedAt: Date(), durationSeconds: durationSeconds
        )
        sessionHistory.insert(session, at: 0)
        if sessionHistory.count > 20 { sessionHistory = Array(sessionHistory.prefix(20)) }
        totalCompletedSessions += 1
        totalLockedSeconds += durationSeconds
    }

    // MARK: - Helpers

    private func saveSessionHistory() {
        if let data = try? JSONEncoder().encode(sessionHistory) {
            userDefaults.set(data, forKey: Keys.sessionHistory)
        }
    }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, minimumDurationSeconds), maximumDurationSeconds)
    }
}
