import SwiftUI

/// Slow-drifting blurred orb lights behind the glass card.
struct AnimatedGradientBackground: View {
    let theme: AppTheme

    @State private var orbs: [OrbState] = []
    private let orbCount = 3

    var body: some View {
        ZStack {
            ForEach(Array(orbs.enumerated()), id: \.offset) { index, orb in
                Circle()
                    .fill(
                        index % 2 == 0
                            ? theme.accent.opacity(orb.opacity)
                            : theme.accentSecondary.opacity(orb.opacity)
                    )
                    .frame(width: orb.radius * 2, height: orb.radius * 2)
                    .blur(radius: orb.radius * 0.7)
                    .position(x: orb.x, y: orb.y)
                    .animation(
                        .easeInOut(duration: orb.duration),
                        value: orb.x
                    )
            }
        }
        .onAppear {
            generateOrbs(in: CGSize(width: 360, height: 170))
            startOrbTimer()
        }
    }

    private func generateOrbs(in size: CGSize) {
        orbs = (0..<orbCount).map { i in
            OrbState(
                x: CGFloat.random(in: size.width * 0.1 ... size.width * 0.9),
                y: CGFloat.random(in: size.height * 0.1 ... size.height * 0.9),
                radius: CGFloat.random(in: 50...110),
                opacity: Double.random(in: 0.08...0.16),
                duration: Double.random(in: AppAnimation.orbDriftRange)
            )
        }
    }

    private func startOrbTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard orbs.count == orbCount else { return }

            for i in 0..<orbCount {
                let newDuration = Double.random(in: AppAnimation.orbDriftRange)
                let size = CGSize(width: 360, height: 170)

                withAnimation(.easeInOut(duration: newDuration)) {
                    orbs[i].x = CGFloat.random(in: size.width * 0.1 ... size.width * 0.9)
                    orbs[i].y = CGFloat.random(in: size.height * 0.1 ... size.height * 0.9)
                    orbs[i].opacity = Double.random(in: 0.08...0.16)
                    orbs[i].duration = newDuration
                }
            }
        }
    }
}

private struct OrbState {
    var x: CGFloat
    var y: CGFloat
    var radius: CGFloat
    var opacity: Double
    var duration: Double
}
