import SwiftUI

enum AppAnimation {
    // Glass light sweep
    static let sweepPeriod: Double = 10.0
    static let sweepHoverPeriod: Double = 4.0

    // Number value change
    static let numberSpring = Animation.spring(response: 0.35, dampingFraction: 0.65)

    // Theme transition
    static let themeTransition = Animation.spring(response: 0.45, dampingFraction: 0.78)

    // Card press
    static let pressScale = Animation.spring(response: 0.18, dampingFraction: 0.82)
    static let pressScaleAmount: CGFloat = 0.985

    // Orb drift
    static let orbDriftRange: ClosedRange<Double> = 6...10

    // Particle
    static let particleCount = 16
    static let particleLifespanRange: ClosedRange<Double> = 8...15
    static let particleSizeRange: ClosedRange<CGFloat> = 1.5...3.5
    static let particleOpacityRange: ClosedRange<Double> = 0.25...0.55

    // Click ripple
    static let rippleDuration: Double = 0.45
    static let rippleMaxRadius: CGFloat = 80
    static let rippleStartOpacity: Double = 0.35

    // Hover glow
    static let hoverBorderBoost: Double = 0.30
    static let hoverGlowResponse: Double = 0.22
}

// MARK: - View Extensions

extension View {
    func numberChangeAnimation(trigger: AnyHashable) -> some View {
        self
            .modifier(NumberPulseModifier(trigger: trigger))
    }
}

private struct NumberPulseModifier: ViewModifier {
    let trigger: AnyHashable
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pulsing ? 1.06 : 1.0)
            .overlay(
                content
                    .scaleEffect(pulsing ? 1.12 : 1.0)
                    .blur(radius: pulsing ? 8 : 0)
                    .opacity(pulsing ? 0.18 : 0)
                    .allowsHitTesting(false)
            )
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.60)) {
                    pulsing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
                        pulsing = false
                    }
                }
            }
    }
}
