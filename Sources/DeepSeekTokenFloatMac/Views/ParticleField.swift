import SwiftUI

/// Lightweight particle field rendered on Canvas for minimal overhead.
struct ParticleField: View {
    let theme: AppTheme

    @State private var particles: [ParticleState] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince1970

                for particle in particles {
                    let progress = elapsed
                        .truncatingRemainder(dividingBy: particle.lifespan)
                        / particle.lifespan

                    let posX = particle.baseX + sin(progress * .pi * 2 + particle.phase) * 18
                    let posY = size.height - (progress * size.height * 0.95)
                        + cos(progress * .pi * 2 + particle.phase * 1.3) * 12

                    let fadeOpacity = progress < 0.15
                        ? particle.opacity * (progress / 0.15)
                        : progress > 0.85
                            ? particle.opacity * ((1.0 - progress) / 0.15)
                            : particle.opacity

                    let rect = CGRect(
                        x: posX,
                        y: posY,
                        width: particle.size,
                        height: particle.size
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(theme.accent.opacity(fadeOpacity))
                    )

                    // Subtle glow
                    let glowRect = rect.insetBy(dx: -particle.size, dy: -particle.size)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(theme.accent.opacity(fadeOpacity * 0.25))
                    )
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        let count = AppAnimation.particleCount
        particles = (0..<count).map { _ in
            ParticleState(
                baseX: CGFloat.random(in: 20...340),
                size: CGFloat.random(in: AppAnimation.particleSizeRange),
                opacity: Double.random(in: AppAnimation.particleOpacityRange),
                lifespan: Double.random(in: AppAnimation.particleLifespanRange),
                phase: Double.random(in: 0...(2 * .pi)),
                delay: Double.random(in: 0...5)
            )
        }
    }
}

private struct ParticleState {
    let baseX: CGFloat
    let size: CGFloat
    let opacity: Double
    let lifespan: Double
    let phase: Double
    let delay: Double
}
