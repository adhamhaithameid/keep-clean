import SwiftUI

struct RootTabsView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ZStack {
            KeepCleanAmbientBackground()

            VStack(spacing: 20) {
                header

                HStack(spacing: 10) {
                    ForEach(AppTab.allCases) { tab in
                        Button(tab.title) {
                            model.selectedTab = tab
                        }
                        .buttonStyle(KeepCleanTabChipStyle(isSelected: model.selectedTab == tab))
                        .accessibilityIdentifier("tab.\(tab.rawValue)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.46))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.82), lineWidth: 1)
                        }
                )

                Group {
                    switch model.selectedTab {
                    case .clean:
                        CleanTabView(model: model)
                    case .settings:
                        SettingsTabView(settings: model.settings)
                    case .about:
                        AboutTabView(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(24)
        }
        .frame(minWidth: 840, minHeight: 640)
        .task {
            model.handleInitialAppearance()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            KeepCleanBrandMark(size: 62)

            VStack(alignment: .leading, spacing: 6) {
                KeepCleanSectionEyebrow(text: "Offline Mac utility")
                Text("KeepClean")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(KeepCleanPalette.ink)
                Text(currentSubtitle)
                    .font(.headline)
                    .foregroundStyle(KeepCleanPalette.ink.opacity(0.72))
            }

            Spacer()

            KeepCleanStatusPill(text: currentPillText, tint: currentPillTint)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.52))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.82), lineWidth: 1)
                }
        )
        .shadow(color: KeepCleanPalette.ink.opacity(0.08), radius: 20, x: 0, y: 10)
    }

    private var currentSubtitle: String {
        switch model.selectedTab {
        case .clean:
            "Safer cleaning controls for your built-in keyboard and trackpad."
        case .settings:
            "Dial in timing and launch behavior before you start cleaning."
        case .about:
            "A tiny practice project with a little more shine."
        }
    }

    private var currentPillText: String {
        switch model.selectedTab {
        case .clean:
            model.activeSession == nil ? "Ready to clean" : "Cleaning active"
        case .settings:
            "Safety defaults"
        case .about:
            "Made locally"
        }
    }

    private var currentPillTint: Color {
        switch model.selectedTab {
        case .clean:
            model.activeSession == nil ? KeepCleanPalette.success : KeepCleanPalette.warning
        case .settings:
            KeepCleanPalette.sky
        case .about:
            KeepCleanPalette.amber
        }
    }
}
