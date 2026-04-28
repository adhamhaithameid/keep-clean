import AppKit
import SwiftUI

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Glass Card Modifier
//
// Uses .regularMaterial so each card is a true translucent glass panel
// floating inside the window's liquid-glass background.

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var borderColor: Color = KeepCleanPalette.border
    var borderWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    }
            }
    }
}

extension View {
    func glassCard(
        cornerRadius: CGFloat = 14,
        border: Color = KeepCleanPalette.border,
        borderWidth: CGFloat = 1
    ) -> some View {
        modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius, borderColor: border, borderWidth: borderWidth))
    }
}

// MARK: - Sweep Shimmer

struct ShimmerModifier: ViewModifier {
    var active: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                .white.opacity(0),
                                .white.opacity(0.28),
                                .white.opacity(0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: geo.size.width * phase)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.65)) {
                                phase = 2.2
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .onChange(of: active) { nowActive in
                if nowActive {
                    phase = -1
                    withAnimation(.easeInOut(duration: 0.65)) { phase = 2.2 }
                } else {
                    phase = -1
                }
            }
    }
}

extension View {
    func shimmer(when active: Bool) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}

// MARK: - Confetti Burst

struct ConfettiBurst: View {
    var active: Bool
    @State private var particles: [ConfettiParticle] = []

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var color: Color
        var offset: CGSize
        var opacity: Double
        var scale: CGFloat
    }

    private let colors: [Color] = [
        KeepCleanPalette.teal, KeepCleanPalette.success,
        Color.yellow, Color.mint, Color.cyan, Color.orange,
    ]

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: 7, height: 7)
                    .offset(p.offset)
                    .opacity(p.opacity)
                    .scaleEffect(p.scale)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: active) { nowActive in
            guard nowActive else {
                particles = []
                return
            }
            fire()
        }
    }

    private func fire() {
        particles = (0..<18).map { i in
            let angle = Double(i) / 18.0 * 2 * .pi
            let dist = Double.random(in: 60...130)
            return ConfettiParticle(
                color: colors.randomElement()!,
                offset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                opacity: 1,
                scale: 1
            )
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            for i in particles.indices {
                particles[i].scale = CGFloat.random(in: 0.6...1.2)
            }
        }
        withAnimation(.easeOut(duration: 0.9).delay(0.3)) {
            for i in particles.indices {
                particles[i].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            particles = []
        }
    }
}

// MARK: - Panel

struct KeepCleanPanel<Content: View>: View {
    var padding: EdgeInsets = .init(top: 16, leading: 18, bottom: 16, trailing: 18)
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Spring Press Button Style

struct KeepCleanPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .animation(
                .spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Primary Action Button Style

struct KeepCleanActionButtonStyle: ButtonStyle {
    let tint: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.82 : 1))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(
                .spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Shortcut Chip

struct ShortcutChip: View {
    let label: String
    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(KeepCleanPalette.mutedInk)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                    }
            }
    }
}

// MARK: - Permission Revoked Interstitial

struct PermissionRevokedInterstitialView: View {
    let onReconnect: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KeepCleanPalette.danger.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(KeepCleanPalette.danger)
            }

            VStack(spacing: 8) {
                Text("Permissions Removed")
                    .font(KeepCleanType.display)
                    .foregroundStyle(KeepCleanPalette.ink)

                Text(
                    "KeepClean needs Accessibility and Input Monitoring to work. One or both were removed in System Settings."
                )
                .font(KeepCleanType.body)
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            }

            Button {
                onReconnect()
            } label: {
                Text("Reconnect Permissions")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(KeepCleanPalette.teal)
                    }
            }
            .buttonStyle(KeepCleanPressButtonStyle())
            .frame(maxWidth: 280)

            Spacer()
        }
        .padding(32)
        .frame(width: 520, height: 520)
    }
}
