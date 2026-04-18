import SwiftUI

struct KeepCleanAmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [KeepCleanPalette.cream, Color.white, KeepCleanPalette.mist],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(KeepCleanPalette.sky.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 32)
                .offset(x: -220, y: -180)

            Circle()
                .fill(KeepCleanPalette.amber.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 30)
                .offset(x: 260, y: -120)

            Circle()
                .fill(KeepCleanPalette.sky.opacity(0.10))
                .frame(width: 360, height: 360)
                .blur(radius: 40)
                .offset(x: 180, y: 220)
        }
        .ignoresSafeArea()
    }
}

struct KeepCleanPanel<Content: View>: View {
    var accent: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.70), lineWidth: 1)
                }
                .overlay(alignment: .topLeading) {
                    if let accent {
                        Capsule(style: .continuous)
                            .fill(accent.opacity(0.24))
                            .frame(width: 92, height: 8)
                            .padding(.top, 16)
                            .padding(.leading, 18)
                    }
                }
        }
        .shadow(color: KeepCleanPalette.ink.opacity(0.08), radius: 20, x: 0, y: 10)
    }
}

struct KeepCleanSectionEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(KeepCleanPalette.ink.opacity(0.55))
    }
}

struct KeepCleanStatusPill: View {
    let text: String
    var tint: Color = KeepCleanPalette.sky

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 9, height: 9)

            Text(text)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(KeepCleanPalette.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }
}

struct KeepCleanActionButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 94)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.86)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    }
            }
            .shadow(color: tint.opacity(configuration.isPressed ? 0.18 : 0.28), radius: configuration.isPressed ? 10 : 22, x: 0, y: configuration.isPressed ? 6 : 14)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct KeepCleanTabChipStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(isSelected ? Color.white : KeepCleanPalette.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [KeepCleanPalette.ink, KeepCleanPalette.sky],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color.white.opacity(configuration.isPressed ? 0.85 : 0.64))
                    )
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(isSelected ? 0.18 : 0.82), lineWidth: 1)
            }
    }
}
