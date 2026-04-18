import AppKit
import SwiftUI

struct AboutTabView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Button {
                    model.open(.profile)
                } label: {
                    ProfileAvatarView()
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("about.profile")
                .accessibilityLabel("GitHub Profile")

                VStack(spacing: 4) {
                    Text("Made with love, coffee, VS Code, and Figma.")
                        .font(.headline)
                        .foregroundStyle(KeepCleanPalette.ink)
                        .multilineTextAlignment(.center)

                    Text("Built for practicing Swift as a junior software engineer.")
                        .font(.subheadline)
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 14) {
                    iconButton(
                        systemName: "chevron.left.forwardslash.chevron.right",
                        label: "GitHub",
                        identifier: "about.repo"
                    ) {
                        model.open(.repository)
                    }

                    iconButton(
                        systemName: "cup.and.saucer.fill",
                        label: "Buy Me a Coffee",
                        identifier: "about.donate"
                    ) {
                        model.open(.donation)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    private func iconButton(
        systemName: String,
        label: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 42, height: 42)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(label)
    }
}

private struct ProfileAvatarView: View {
    var body: some View {
        Group {
            if let image = NSImage(named: "Profile") {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let url = Bundle.main.url(forResource: "profile", withExtension: "png"),
                      let data = try? Data(contentsOf: url),
                      let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(KeepCleanPalette.blueSoft)
                    .overlay {
                        Text("AE")
                            .font(.title.bold())
                            .foregroundStyle(KeepCleanPalette.ink)
                    }
            }
        }
        .frame(width: 112, height: 112)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(KeepCleanPalette.border, lineWidth: 1))
    }
}
