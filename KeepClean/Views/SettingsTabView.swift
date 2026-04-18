import SwiftUI

struct SettingsTabView: View {
    @Bindable var settings: AppSettings
    let openPrivacyAndSecurity: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                KeepCleanPanel {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Keyboard + Trackpad Duration")
                            .font(.headline)
                            .foregroundStyle(KeepCleanPalette.ink)

                        Spacer()

                        Text("\(settings.fullCleanDurationSeconds) seconds")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(KeepCleanPalette.ink)
                            .accessibilityIdentifier("settings.durationValue")
                    }

                    Stepper(
                        "Choose how long full clean stays active.",
                        value: $settings.fullCleanDurationSeconds,
                        in: AppSettings.minimumDurationSeconds...AppSettings.maximumDurationSeconds
                    )
                    .accessibilityIdentifier("settings.durationStepper")
                }

                KeepCleanPanel {
                    Toggle("Start keyboard disable after opening the app", isOn: $settings.autoStartKeyboardDisableOnLaunch)
                        .font(.headline)
                        .foregroundStyle(KeepCleanPalette.ink)
                        .accessibilityIdentifier("settings.autoStartToggle")

                    Text("KeepClean shows a 3-second countdown first, so you can cancel with the trackpad before the keyboard turns off.")
                        .font(.subheadline)
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                KeepCleanPanel {
                    Button("Open Privacy & Security") {
                        openPrivacyAndSecurity()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("settings.openPrivacyAndSecurity")

                    Text("Use this if macOS asks you to approve KeepClean before cleaning can start.")
                        .font(.subheadline)
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
