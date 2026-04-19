import AppKit
import Foundation

enum SystemSettingsLink {
    case privacyAndSecurity
    case accessibility
    case inputMonitoring

    /// Opens the corresponding System Settings pane.
    /// Uses the modern `x-apple.systempreferences:` deep-link on Ventura+,
    /// and falls back to the legacy `com.apple.preference.security` URL scheme
    /// on older macOS versions. If both fail, opens System Settings at the top level.
    func open() {
        for candidate in urls {
            if NSWorkspace.shared.open(candidate) {
                return
            }
        }
        // Absolute fallback: just open System Settings / System Preferences
        if let fallback = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(fallback)
        }
    }

    // MARK: - Private

    /// Ordered list of candidate URLs, most specific first.
    private var urls: [URL] {
        switch self {
        case .privacyAndSecurity:
            return [
                // macOS 13+ (Ventura) System Settings deep link
                URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")!,
                // macOS 12 and earlier (System Preferences)
                URL(string: "x-apple.systempreferences:com.apple.preference.security")!,
            ]
        case .accessibility:
            return [
                // macOS 13+ (Ventura)
                URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")!,
                // macOS 12 and earlier
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!,
            ]
        case .inputMonitoring:
            return [
                // macOS 13+ (Ventura)
                URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent")!,
                // macOS 12 and earlier
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!,
            ]
        }
    }

    /// Legacy `.url` accessor retained for compatibility — returns the first candidate.
    var url: URL {
        urls[0]
    }
}
