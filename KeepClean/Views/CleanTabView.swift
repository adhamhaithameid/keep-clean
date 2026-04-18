import SwiftUI

struct CleanTabView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let autoStartCountdown = model.autoStartCountdownSecondsRemaining {
                    infoPanel(
                        title: "Keyboard disable starts in \(autoStartCountdown) seconds.",
                        message: "Cancel now if you opened the app by mistake."
                    ) {
                        Button("Cancel Auto-Start") {
                            model.cancelAutoStart()
                        }
                        .accessibilityIdentifier("clean.cancelAutoStart")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("clean.autoStartPanel")
                }

                if let remainingTimedLockSeconds = model.remainingTimedLockSeconds {
                    infoPanel(
                        title: "Keyboard and trackpad are disabled.",
                        message: "They will turn back on automatically in \(remainingTimedLockSeconds) seconds."
                    )
                    .accessibilityIdentifier("clean.timedCountdown")
                }

                if let errorMessage = model.errorMessage {
                    infoPanel(
                        title: "Couldn’t start cleaning.",
                        message: errorMessage,
                        tint: .red
                    ) {
                        if model.shouldOfferPrivacyAndSecurityHelp {
                            Button("Open Privacy & Security") {
                                model.openPrivacyAndSecurity()
                            }
                            .accessibilityIdentifier("clean.openPrivacyAndSecurity")
                        }
                    }
                    .accessibilityIdentifier("clean.error")
                }

                actionPanel(
                    buttonTitle: model.keyboardButtonTitle,
                    buttonIdentifier: "clean.disableKeyboard",
                    tint: KeepCleanPalette.blue,
                    description: "Keeps the built-in trackpad active so you can turn the keyboard back on.",
                    descriptionIdentifier: "clean.keyboardDescription",
                    action: {
                        Task {
                            await model.toggleKeyboardLock()
                        }
                    }
                )
                .accessibilityIdentifier("clean.keyboardAction")

                actionPanel(
                    buttonTitle: model.fullCleanButtonTitle,
                    buttonIdentifier: "clean.disableKeyboardAndTrackpad",
                    tint: KeepCleanPalette.orange,
                    description: "Turns off the built-in keyboard and trackpad for the selected timer, then restores them automatically.",
                    descriptionIdentifier: "clean.fullCleanDescription",
                    action: {
                        Task {
                            await model.startTimedFullClean()
                        }
                    }
                )
                .accessibilityIdentifier("clean.fullCleanAction")
            }
            .padding(.vertical, 4)
        }
    }

    private func actionPanel(
        buttonTitle: String,
        buttonIdentifier: String,
        tint: Color,
        description: String,
        descriptionIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        KeepCleanPanel {
            Button(buttonTitle, action: action)
                .buttonStyle(KeepCleanActionButtonStyle(tint: tint))
                .accessibilityIdentifier(buttonIdentifier)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(descriptionIdentifier)
        }
    }

    private func infoPanel<Actions: View>(
        title: String,
        message: String,
        tint: Color = KeepCleanPalette.blue,
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) -> some View {
        KeepCleanPanel {
            Text(title)
                .font(.headline)
                .foregroundStyle(KeepCleanPalette.ink)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            actions()
                .tint(tint)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.55), lineWidth: 1)
        }
    }
}
