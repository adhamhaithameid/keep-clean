import SwiftUI

struct SettingsTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerPanel
                durationPanel
                autoStartPanel
                safetyPanel
            }
        }
    }

    private var headerPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Settings")
            Text("Preferences")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(KeepCleanPalette.ink)
            Text("These settings stay on this Mac and only affect the built-in cleaning flows.")
                .font(.body)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
    }

    private var durationPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Timed clean")

            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard + Trackpad Duration")
                        .font(.headline)
                        .foregroundStyle(KeepCleanPalette.ink)
                    Text("Choose how long the full clean mode should stay active.")
                        .font(.subheadline)
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                }

                Spacer()

                Text("\(settings.fullCleanDurationSeconds)s")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(KeepCleanPalette.orange)
            }

            Stepper("Allowed range: \(AppSettings.minimumDurationSeconds)-\(AppSettings.maximumDurationSeconds) seconds.", value: $settings.fullCleanDurationSeconds, in: AppSettings.minimumDurationSeconds...AppSettings.maximumDurationSeconds)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
    }

    private var autoStartPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Launch")

            Toggle(isOn: $settings.autoStartKeyboardDisableOnLaunch) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start keyboard disable after opening the app")
                        .font(.headline)
                        .foregroundStyle(KeepCleanPalette.ink)
                    Text("KeepClean shows a 3-second countdown first so you can cancel it with the trackpad.")
                        .font(.subheadline)
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                }
            }

            Text("Auto-start applies only to keyboard-only mode. Full clean always stays manual.")
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
    }

    private var safetyPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Notes")

            VStack(alignment: .leading, spacing: 8) {
                settingsRow("Keyboard-only mode never disables the built-in trackpad.")
                settingsRow("Full clean mode always auto-recovers after the selected duration.")
                settingsRow("KeepClean stays offline. The About tab links open in your default browser.")
            }
        }
    }

    private func settingsRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundStyle(KeepCleanPalette.blue)
                .padding(.top, 6)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
    }
}
