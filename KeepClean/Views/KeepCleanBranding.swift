import AppKit
import SwiftUI

enum KeepCleanPalette {
    static let ink = Color.primary
    static let mutedInk = Color.secondary
    static let blue = Color.accentColor
    static let blueSoft = Color.accentColor.opacity(0.12)
    static let orange = Color(red: 0.92, green: 0.47, blue: 0.16)
    static let success = Color(red: 0.17, green: 0.60, blue: 0.38)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let surfaceWarm = Color(nsColor: .controlBackgroundColor)
    static let border = Color(nsColor: .separatorColor).opacity(0.65)
    static let windowBackground = Color(nsColor: .windowBackgroundColor)
    static let subtleFill = Color(nsColor: .textBackgroundColor)
}

struct KeepCleanBrandMark: View {
    var size: CGFloat = 64

    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "brand-mark", withExtension: "png"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(KeepCleanPalette.surfaceWarm)
                    .overlay {
                        Text("K")
                            .font(.system(size: size * 0.42, weight: .semibold))
                            .foregroundStyle(KeepCleanPalette.ink)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                    }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
