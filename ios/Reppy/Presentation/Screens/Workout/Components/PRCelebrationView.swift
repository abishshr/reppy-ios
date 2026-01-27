import SwiftUI

/// Full-screen celebration overlay when a new PR is achieved
struct PRCelebrationView: View {
    let prInfo: PRInfo
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var scale = 0.5
    @State private var opacity = 0.0
    @State private var trophyRotation = 0.0

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            // Content
            VStack(spacing: 24) {
                Spacer()

                // Trophy with animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)

                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .rotation3DEffect(
                            .degrees(trophyRotation),
                            axis: (x: 0, y: 1, z: 0)
                        )
                }
                .scaleEffect(scale)

                // Title
                Text("NEW PERSONAL RECORD!")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .opacity(opacity)

                // Exercise Name
                Text(prInfo.exerciseName.capitalized)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .opacity(opacity)

                // PR Details
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text(prTypeLabel)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    HStack(spacing: 8) {
                        // Previous value (if any)
                        if let previous = prInfo.previousValue {
                            Text(formatValue(previous))
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.5))
                                .strikethrough()
                        }

                        Image(systemName: "arrow.right")
                            .foregroundColor(.green)

                        // New value
                        Text(formatValue(prInfo.newValue))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .opacity(opacity)
                }

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(Color.yellow)
                        .cornerRadius(25)
                }
                .opacity(opacity)
                .padding(.bottom, 50)
            }

            // Confetti
            if showConfetti {
                PRConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Trophy rotation animation
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                trophyRotation = 360
            }

            // Show confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }

            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
            }
        }
    }

    private var prTypeLabel: String {
        switch prInfo.prType {
        case "weight": return "Weight PR"
        case "volume": return "Volume PR"
        case "reps": return "Reps PR"
        default: return "Personal Record"
        }
    }

    private func formatValue(_ value: Double) -> String {
        switch prInfo.prType {
        case "weight":
            return "\(String(format: "%.1f", value)) kg"
        case "volume":
            return "\(String(format: "%.0f", value)) kg"
        case "reps":
            return "\(Int(value)) reps"
        default:
            return "\(String(format: "%.1f", value)) \(prInfo.unit)"
        }
    }
}

// MARK: - Confetti View

struct PRConfettiView: View {
    @State private var particles: [PRConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let position = particle.position(at: timeline.date)
                    if position.y < size.height + 50 {
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: position.x - particle.size / 2,
                                y: position.y - particle.size / 2,
                                width: particle.size,
                                height: particle.size
                            )),
                            with: .color(particle.color)
                        )
                    }
                }
            }
        }
        .onAppear {
            particles = (0..<100).map { _ in PRConfettiParticle() }
        }
    }
}

struct PRConfettiParticle {
    let startX: CGFloat
    let velocity: CGFloat
    let size: CGFloat
    let color: Color
    let startTime: Date
    let horizontalVelocity: CGFloat

    init() {
        startX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
        velocity = CGFloat.random(in: 200...400)
        size = CGFloat.random(in: 6...12)
        color = [Color.yellow, Color.orange, Color.green, Color.blue, Color.purple, Color.red].randomElement()!
        startTime = Date()
        horizontalVelocity = CGFloat.random(in: -50...50)
    }

    func position(at time: Date) -> CGPoint {
        let elapsed = time.timeIntervalSince(startTime)
        let y = -50 + velocity * elapsed + 100 * elapsed * elapsed // Gravity effect
        let x = startX + horizontalVelocity * elapsed + sin(elapsed * 5) * 10 // Wave effect
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preview

#Preview {
    PRCelebrationView(
        prInfo: PRInfo(
            exerciseName: "barbell bench press",
            prType: "weight",
            newValue: 100,
            previousValue: 95,
            unit: "kg"
        ),
        onDismiss: {}
    )
}
