import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case clean
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean:
            "Clean"
        case .settings:
            "Settings"
        case .about:
            "About"
        }
    }

    var icon: String {
        switch self {
        case .clean:
            "sparkles"
        case .settings:
            "gearshape"
        case .about:
            "info.circle"
        }
    }
}
