import SwiftUI

/// Multi-layer glass card with noise texture, inner glow, light sweep, and double border.
struct GlassCard<Content: View>: View {
    let theme: AppTheme
    @State private var isHovering = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(glassLayers)
            .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
            .shadow(
                color: theme.shadowColor,
                radius: theme.shadowRadius,
                x: 0,
                y: isHovering ? 20 : 16
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: AppAnimation.hoverGlowResponse)) {
                    isHovering = hovering
                }
            }
    }

    // MARK: - Glass Layers

    @ViewBuilder
    private var glassLayers: some View {
        ZStack {
            // Layer 1: Material background
            materialBackground

            // Layer 2: Gradient fill
            gradientFill

            // Layer 3: Noise texture
            noiseTexture

            // Layer 4: Inner glow
            innerGlow

            // Layer 5: Light sweep
            lightSweep

            // Layer 6: Double border
            doubleBorder
        }
    }

    // MARK: - Layer 1: Material

    @ViewBuilder
    private var materialBackground: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
            .fill(materialFor(theme.glass.baseMaterial))
    }

    private func materialFor(_ style: GlassConfig.MaterialStyle) -> Material {
        switch style {
        case .ultraThin: return .ultraThinMaterial
        case .regular:   return .regularMaterial
        case .thick:     return .thickMaterial
        }
    }

    // MARK: - Layer 2: Gradient

    private var gradientFill: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: theme.glass.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(theme.glass.gradientOpacity)
    }

    // MARK: - Layer 3: Noise Texture

    private var noiseTexture: some View {
        NoiseOverlay(opacity: theme.glass.noiseOpacity)
            .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
            .allowsHitTesting(false)
    }

    // MARK: - Layer 4: Inner Glow

    private var innerGlow: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
            .stroke(
                theme.glass.innerGlowColor.opacity(0.10),
                lineWidth: theme.glass.innerGlowRadius
            )
            .blur(radius: theme.glass.innerGlowRadius * 0.7)
            .padding(-theme.glass.innerGlowRadius * 0.5)
            .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
            .allowsHitTesting(false)
    }

    // MARK: - Layer 5: Light Sweep

    private var lightSweep: some View {
        LightSweepView(
            period: isHovering ? AppAnimation.sweepHoverPeriod : AppAnimation.sweepPeriod,
            color: theme.glass.sweepColor,
            opacity: theme.glass.sweepOpacity,
            cornerRadius: theme.cardCornerRadius
        )
        .allowsHitTesting(false)
    }

    // MARK: - Layer 6: Double Border

    private var doubleBorder: some View {
        ZStack {
            // Outer: theme accent
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .stroke(
                    theme.glass.borderLightColor.opacity(
                        isHovering
                            ? theme.glass.borderLightOpacity + AppAnimation.hoverBorderBoost
                            : theme.glass.borderLightOpacity
                    ),
                    lineWidth: 1.2
                )

            // Inner: subtle white highlight
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
                .padding(1)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Noise Overlay

private struct NoiseOverlay: View {
    let opacity: Double

    var body: some View {
        Canvas { context, size in
            guard opacity > 0 else { return }
            let scale: CGFloat = 4
            let cols = Int(size.width / scale)
            let rows = Int(size.height / scale)

            var rng = SeededRandom(seed: 42)
            for row in 0..<rows {
                for col in 0..<cols {
                    let brightness = Double(rng.next()) / Double(UInt32.max)
                    let rect = CGRect(
                        x: CGFloat(col) * scale,
                        y: CGFloat(row) * scale,
                        width: scale,
                        height: scale
                    )
                    context.fill(
                        Path(rect),
                        with: .color(Color(white: brightness, opacity: opacity))
                    )
                }
            }
        }
    }
}

// MARK: - Light Sweep

private struct LightSweepView: View {
    let period: Double
    let color: Color
    let opacity: Double
    let cornerRadius: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince1970
            let phase = elapsed.truncatingRemainder(dividingBy: period) / period

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .clear, location: max(0, phase - 0.25)),
                            .init(color: color.opacity(opacity), location: phase),
                            .init(color: .clear, location: min(1, phase + 0.25)),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(x: 1, y: 1)
                    )
                )
        }
    }
}

// MARK: - Seeded Random Generator

private struct SeededRandom {
    private var state: UInt32

    init(seed: UInt32) {
        self.state = seed
    }

    mutating func next() -> UInt32 {
        state = state &* 1_103_515_245 &+ 12_345
        state = (state ^ (state >> 13)) &* 2_654_435_769
        state = state ^ (state >> 16)
        return state
    }
}
