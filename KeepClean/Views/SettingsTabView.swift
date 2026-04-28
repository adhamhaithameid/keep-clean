import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var model: AppViewModel
    let openPrivacyAndSecurity: () -> Void
    let hasAccessibility: Bool
    let hasInputMonitoring: Bool

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {

                // MARK: App identity header
                HStack(spacing: 10) {
                    KeepCleanBrandMark(size: 36, hoverRotate: false)
                        .shadow(color: KeepCleanPalette.teal.opacity(0.20), radius: 6, y: 2)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("KeepClean")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(KeepCleanPalette.ink)
                        Text(
                            "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
                        )
                        .font(KeepCleanType.caption)
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                    }
                }
                .padding(.bottom, 4)

                // MARK: Duration (#10 / #6 animated number)
                KeepCleanPanel {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Full Clean Duration")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(KeepCleanPalette.ink)
                            Text(
                                "\(AppSettings.minimumDurationSeconds)s – \(AppSettings.maximumDurationSeconds)s"
                            )
                            .font(KeepCleanType.caption)
                            .foregroundStyle(KeepCleanPalette.mutedInk)
                        }
                        Spacer()
                        // #6 animated number flip
                        Text("\(settings.fullCleanDurationSeconds)s")
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundStyle(KeepCleanPalette.teal)
                            .contentTransition(.numericText())
                            .animation(
                                .spring(response: 0.35), value: settings.fullCleanDurationSeconds
                            )
                            .accessibilityIdentifier("settings.durationValue")
                    }

                    Divider().opacity(0.5)

                    Stepper(
                        "Adjust duration", value: $settings.fullCleanDurationSeconds,
                        in: AppSettings.minimumDurationSeconds...AppSettings.maximumDurationSeconds
                    )
                    .labelsHidden()
                    .tint(KeepCleanPalette.teal)
                    .accessibilityIdentifier("settings.durationStepper")
                }

                // MARK: Auto-start
                KeepCleanPanel {
                    Toggle(isOn: $settings.autoStartKeyboardDisableOnLaunch) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-start on launch")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(KeepCleanPalette.ink)
                            Text("Disables keyboard 3 seconds after opening")
                                .font(KeepCleanType.caption)
                                .foregroundStyle(KeepCleanPalette.mutedInk)
                        }
                    }
                    .tint(KeepCleanPalette.teal)
                    .accessibilityIdentifier("settings.autoStartToggle")
                }

                // MARK: Behavior (#12 notifications, #24 sounds)
                KeepCleanPanel {
                    Text("Behavior")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(KeepCleanPalette.ink)

                    Divider().opacity(0.5)

                    // #12 notifications
                    HStack {
                        Toggle(isOn: $settings.notificationsEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notify when session ends")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(KeepCleanPalette.ink)
                                Text("System notification when cleaning completes")
                                    .font(KeepCleanType.caption)
                                    .foregroundStyle(KeepCleanPalette.mutedInk)
                            }
                        }
                        .tint(KeepCleanPalette.teal)
                        .onChange(of: settings.notificationsEnabled) { enabled in
                            if enabled { model.requestNotificationPermission() }
                        }
                    }

                    Divider().opacity(0.3)

                    // #24 sounds
                    Toggle(isOn: $settings.soundsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sound effects")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(KeepCleanPalette.ink)
                            Text("Subtle audio cue when sessions start and end")
                                .font(KeepCleanType.caption)
                                .foregroundStyle(KeepCleanPalette.mutedInk)
                        }
                    }
                    .tint(KeepCleanPalette.teal)

                    Divider().opacity(0.3)

                    // Emergency stop shortcut toggle
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(isOn: $settings.emergencyStopEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Emergency Stop")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(KeepCleanPalette.ink)
                                Text("Re-enables input instantly during any active session")
                                    .font(KeepCleanType.caption)
                                    .foregroundStyle(KeepCleanPalette.mutedInk)
                            }
                        }
                        .tint(KeepCleanPalette.teal)
                        .accessibilityIdentifier("settings.emergencyStopToggle")

                        if settings.emergencyStopEnabled {
                            HStack(spacing: 4) {
                                ShortcutChip(label: "⌘L")
                                Text("+")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(KeepCleanPalette.mutedInk)
                                ShortcutChip(label: "⌘R")
                                Text("+")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(KeepCleanPalette.mutedInk)
                                ShortcutChip(label: "1")
                                Text("+")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(KeepCleanPalette.mutedInk)
                                ShortcutChip(label: "0")
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: settings.emergencyStopEnabled)
                }

                // MARK: Permissions
                KeepCleanPanel {
                    HStack {
                        Text("Permissions")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(KeepCleanPalette.ink)
                        Spacer()
                        Button {
                            openPrivacyAndSecurity()
                        } label: {
                            Label("Open Settings", systemImage: "arrow.up.forward.square")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(KeepCleanPalette.teal)
                        .accessibilityIdentifier("settings.openPrivacyAndSecurity")
                    }

                    Divider().opacity(0.5)

                    VStack(spacing: 6) {
                        permissionRow(
                            "Accessibility", granted: hasAccessibility,
                            id: "settings.accessibility.status")
                        Divider().opacity(0.3)
                        permissionRow(
                            "Input Monitoring", granted: hasInputMonitoring,
                            id: "settings.inputMonitoring.status")
                    }
                }

                // MARK: Stats + History (#21 / #10)
                KeepCleanPanel {
                    HStack {
                        Text("Usage")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(KeepCleanPalette.ink)
                        Spacer()
                        if !settings.sessionHistory.isEmpty {
                            Button("Clear") {
                                settings.sessionHistory = []
                                settings.totalCompletedSessions = 0
                                settings.totalLockedSeconds = 0
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(KeepCleanPalette.danger)
                            .buttonStyle(.plain)
                        }
                    }

                    Divider().opacity(0.5)

                    UsageStatsCard(
                        totalSessions: settings.totalCompletedSessions,
                        totalLockSeconds: settings.totalLockedSeconds
                    )

                    if !settings.sessionHistory.isEmpty {
                        Divider().opacity(0.3)
                        SessionHistoryView(
                            sessions: settings.sessionHistory,
                            totalSessions: settings.totalCompletedSessions,
                            totalLockSeconds: settings.totalLockedSeconds
                        )
                    }
                }

                Spacer(minLength: 8)
            }  // end inner VStack
        }  // end ScrollView
    }

    // MARK: - Permission Row

    private func permissionRow(_ name: String, granted: Bool, id: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(granted ? KeepCleanPalette.success : KeepCleanPalette.danger)
                .frame(width: 8, height: 8)
                .shadow(
                    color: (granted ? KeepCleanPalette.success : KeepCleanPalette.danger).opacity(
                        0.5), radius: 3)
            Text(name)
                .font(.system(size: 13))
                .foregroundStyle(KeepCleanPalette.ink)
            Spacer()
            Text(granted ? "Granted" : "Not Granted")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(granted ? KeepCleanPalette.success : KeepCleanPalette.danger)
        }
        .accessibilityIdentifier(id)
        .accessibilityLabel("\(name): \(granted ? "Granted" : "Not Granted")")
        .animation(.easeInOut(duration: 0.3), value: granted)
    }
}

// MARK: - Preview (#30)

#Preview {
    SettingsTabView(
        settings: AppSettings(userDefaults: .standard),
        model: .preview(),
        openPrivacyAndSecurity: {},
        hasAccessibility: true,
        hasInputMonitoring: false
    )
    .padding()
    .frame(width: 520)
}
