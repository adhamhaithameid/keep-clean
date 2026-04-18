import SwiftUI

struct RootTabsView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ZStack(alignment: .top) {
            KeepCleanAmbientBackground()

            VStack(spacing: 18) {
                tabBar

                Group {
                    switch model.selectedTab {
                    case .clean:
                        CleanTabView(model: model)
                    case .settings:
                        SettingsTabView(
                            settings: model.settings,
                            openPrivacyAndSecurity: model.openPrivacyAndSecurity
                        )
                    case .about:
                        AboutTabView(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(24)
        }
        .frame(minWidth: 540, minHeight: 440)
        .task {
            model.handleInitialAppearance()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 10) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        if model.selectedTab == tab {
            Button(tab.title) {
                model.selectedTab = tab
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("tab.\(tab.rawValue)")
        } else {
            Button(tab.title) {
                model.selectedTab = tab
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("tab.\(tab.rawValue)")
        }
    }
}
