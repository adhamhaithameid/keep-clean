import SwiftUI

struct SettingsTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerPanel
                durationPanel
                autoStartPanel
                safetyPanel
            }
        }
    }

    private var headerPanel: some View {
        KeepCleanPanel(accent: KeepCleanPalette.sky) {
            KeepCleanSectionEyebrow(text: "Preferences")
            Text("Tune the cleaning experience before you need it.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(KeepCleanPalette.ink)

            Text("These settings stay local to your Mac and keep the recovery rules easy to understand.")
                .font(.headline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.70))
        }
    }

    private var durationPanel: some View {
        KeepCleanPanel(accent: KeepCleanPalette.amber) {
            KeepCleanSectionEyebrow(text: "Timed full clean")
            Text("Keyboard + Trackpad Duration")
                .font(.title3.weight(.bold))
                .foregroundStyle(KeepCleanPalette.ink)

            HStack(alignment: .center, spacing: 16) {
                Text("\(settings.fullCleanDurationSeconds)s")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(KeepCleanPalette.warning)
                    .frame(minWidth: 104, alignment: .leading)

                Stepper(value: $settings.fullCleanDurationSeconds, in: AppSettings.minimumDurationSeconds...AppSettings.maximumDurationSeconds) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Adjust the strict auto-release timer.")
                            .font(.headline)
                            .foregroundStyle(KeepCleanPalette.ink)
                        Text("Allowed range: \(AppSettings.minimumDurationSeconds)-\(AppSettings.maximumDurationSeconds) seconds.")
                            .font(.subheadline)
                            .foregroundStyle(KeepCleanPalette.ink.opacity(0.65))
                    }
                }
            }
        }
    }

    private var autoStartPanel: some View {
        KeepCleanPanel(accent: KeepCleanPalette.sky) {
            KeepCleanSectionEyebrow(text: "Launch behavior")
            Toggle(isOn: $settings.autoStartKeyboardDisableOnLaunch) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start keyboard disable after opening the app")
                        .font(.headline)
                        .foregroundStyle(KeepCleanPalette.ink)
                    Text("KeepClean shows a 3-second countdown first so you can cancel it with the trackpad.")
                        .font(.subheadline)
                        .foregroundStyle(KeepCleanPalette.ink.opacity(0.68))
                }
            }
            .toggleStyle(.switch)

            Text("Auto-start applies only to the keyboard-only mode. The timed full-clean mode is always manual on purpose.")
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.68))
        }
    }

    private var safetyPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Safety defaults")

            VStack(alignment: .leading, spacing: 10) {
                settingsRow(symbol: "keyboard.fill", text: "Keyboard-only mode never disables the built-in trackpad.")
                settingsRow(symbol: "clock.badge.checkmark", text: "Full clean mode always auto-recovers after the selected duration.")
                settingsRow(symbol: "lock.shield.fill", text: "KeepClean stays offline. The only links it opens are the About tab buttons in your default browser.")
            }
        }
    }

    private func settingsRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(KeepCleanPalette.sky)
                .frame(width: 18)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.72))
        }
    }
}
