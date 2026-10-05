import SwiftUI

/// Lightweight confetti burst drawn with Canvas. Respects Reduce Motion
/// and the "Celebration effects" setting.
struct ConfettiView: View {
    var count = 120
    var duration: Double = 3.2

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage(SettingsKey.celebrations) var celebrations = true
    @State var particles: [Particle] = []
    @State var start = Date()

    struct Particle {
        let x: Double
        let vx: Double
        let vy: Double
        let spin: Double
        let rotation: Double
        let size: CGSize
        let color: Color
        let isCircle: Bool
    }

    private static let palette: [Color] = [
        Color(hex: "#D9B779"), Color(hex: "#A87F40"), Color(hex: "#4A6C8C"),
        Color(hex: "#A8BDD1"), Color(hex: "#6FD39A"), Color(hex: "#D9643A"), Color(hex: "#B4A7CF"),
    ]

    var body: some View {
        if reduceMotion || !celebrations {
            Color.clear
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSince(start)
                    guard t < duration else { return }
                    let fade = t > duration - 0.8 ? max(0, (duration - t) / 0.8) : 1
                    for particle in particles {
                        let x = particle.x * size.width + particle.vx * t
                        let y = size.height * 0.35 + particle.vy * t + 0.5 * 900 * t * t
                        guard y < size.height + 40 else { continue }
                        var ctx = context
                        ctx.opacity = fade
                        ctx.translateBy(x: x, y: y)
                        ctx.rotate(by: .radians(particle.rotation + particle.spin * t))
                        let rect = CGRect(origin: CGPoint(x: -particle.size.width / 2, y: -particle.size.height / 2),
                                          size: particle.size)
                        let path = particle.isCircle ? Path(ellipseIn: rect) : Path(rect)
                        ctx.fill(path, with: .color(particle.color))
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                start = Date()
                particles = (0..<count).map { _ in
                    Particle(
                        x: Double.random(in: 0.3...0.7),
                        vx: Double.random(in: -320...320),
                        vy: Double.random(in: -820 ... -320),
                        spin: Double.random(in: -8...8),
                        rotation: Double.random(in: 0...(2 * .pi)),
                        size: CGSize(width: Double.random(in: 6...11), height: Double.random(in: 8...15)),
                        color: Self.palette.randomElement()!,
                        isCircle: Bool.random() && Bool.random()
                    )
                }
            }
        }
    }
}
