import SwiftUI

/// Celebration overlay for when user logs meals/workouts
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    let type: CelebrationType
    let value: Int
    let label: String

    @State private var showContent = false
    @State private var particles: [CelebrationParticle] = []
    @State private var valueScale: CGFloat = 0.5
    @State private var valueOpacity: Double = 0

    var body: some View {
        ZStack {
            // Particles
            ForEach(particles) { particle in
                particle.content
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
            }

            // Main content
            VStack(spacing: 16) {
                // Icon burst
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)

                    Image(systemName: type.icon)
                        .font(.system(size: 44))
                        .foregroundColor(type.color)
                        .scaleEffect(showContent ? 1 : 0)
                }

                // Value counter
                HStack(spacing: 4) {
                    Text("+\(value)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(type.color)

                    Text(type.unit)
                        .font(.title2.bold())
                        .foregroundColor(type.color.opacity(0.8))
                }
                .scaleEffect(valueScale)
                .opacity(valueOpacity)

                // Label
                Text(label)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .opacity(showContent ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(showContent ? 0.4 : 0)
                .ignoresSafeArea()
        )
        .onAppear {
            if isShowing {
                runAnimation()
            }
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                runAnimation()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }

    private func runAnimation() {
        // Generate particles
        generateParticles()

        // Show main content
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showContent = true
        }

        // Animate value with bounce
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
            valueScale = 1.2
            valueOpacity = 1
        }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.35)) {
            valueScale = 1.0
        }

        // Trigger haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }

    private func generateParticles() {
        particles = (0..<25).map { _ in
            CelebrationParticle(
                x: 0, y: 0,
                content: AnyView(
                    type.particleContent
                        .frame(width: CGFloat.random(in: 8...16))
                ),
                scale: 1,
                rotation: 0,
                opacity: 1
            )
        }

        // Animate particles outward
        for i in particles.indices {
            let angle = Double.random(in: 0...360)
            let distance = CGFloat.random(in: 80...180)
            let duration = Double.random(in: 0.6...1.0)

            withAnimation(.easeOut(duration: duration).delay(Double(i) * 0.02)) {
                particles[i].x = cos(angle * .pi / 180) * distance
                particles[i].y = sin(angle * .pi / 180) * distance - 30
                particles[i].rotation = Double.random(in: 180...540)
                particles[i].scale = CGFloat.random(in: 0.3...0.8)
                particles[i].opacity = 0
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            showContent = false
            valueOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
            particles = []
        }
    }
}

enum CelebrationType {
    case meal
    case workout
    case steps
    case water
    case achievement

    var icon: String {
        switch self {
        case .meal: return "fork.knife.circle.fill"
        case .workout: return "flame.circle.fill"
        case .steps: return "figure.walk.circle.fill"
        case .water: return "drop.circle.fill"
        case .achievement: return "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .meal: return .orange
        case .workout: return .green
        case .steps: return .blue
        case .water: return .cyan
        case .achievement: return .yellow
        }
    }

    var unit: String {
        switch self {
        case .meal: return "cal"
        case .workout: return "cal burned"
        case .steps: return "steps"
        case .water: return "ml"
        case .achievement: return "XP"
        }
    }

    @ViewBuilder
    var particleContent: some View {
        switch self {
        case .meal:
            Image(systemName: ["carrot.fill", "leaf.fill", "star.fill"].randomElement()!)
                .foregroundColor([.orange, .green, .yellow].randomElement()!)
        case .workout:
            Image(systemName: ["flame.fill", "bolt.fill", "star.fill"].randomElement()!)
                .foregroundColor([.orange, .red, .yellow].randomElement()!)
        case .steps:
            Circle()
                .fill([Color.blue, .cyan, .green].randomElement()!)
        case .water:
            Image(systemName: ["drop.fill", "drop.fill", "sparkle"].randomElement()!)
                .foregroundColor([.cyan, .blue, .teal].randomElement()!)
        case .achievement:
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let content: AnyView
    var scale: CGFloat
    var rotation: Double
    var opacity: Double
}

/// Quick celebration toast for smaller wins
struct QuickCelebration: View {
    let message: String
    let icon: String
    let color: Color
    @Binding var isShowing: Bool

    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(color.gradient)
                .shadow(color: color.opacity(0.4), radius: 12, y: 4)
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            if isShowing {
                show()
            }
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                show()
            }
        }
    }

    private func show() {
        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Slide in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            offset = 0
            opacity = 1
        }

        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 0.25)) {
                offset = -100
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShowing = false
            }
        }
    }
}

/// Floating +XP indicator
struct FloatingGain: View {
    let value: String
    let color: Color
    @Binding var isShowing: Bool

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text(value)
            .font(.headline.bold())
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .scaleEffect(scale)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                if isShowing {
                    animate()
                }
            }
            .onChange(of: isShowing) { _, showing in
                if showing {
                    animate()
                }
            }
    }

    private func animate() {
        scale = 0.5
        offset = 0
        opacity = 1

        // Pop in
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            scale = 1.1
        }

        withAnimation(.spring(response: 0.15, dampingFraction: 0.6).delay(0.2)) {
            scale = 1.0
        }

        // Float up and fade
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            offset = -60
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isShowing = false
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()

        CelebrationOverlay(
            isShowing: .constant(true),
            type: .meal,
            value: 450,
            label: "Logged Breakfast"
        )
    }
}
