import SwiftUI

/// Animated counting label that makes numbers feel alive
struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color
    let suffix: String

    @State private var displayValue: Int = 0
    @State private var previousValue: Int = 0

    init(
        value: Int,
        font: Font = .title,
        color: Color = .primary,
        suffix: String = ""
    ) {
        self.value = value
        self.font = font
        self.color = color
        self.suffix = suffix
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(displayValue)")
                .font(font)
                .fontWeight(.bold)
                .foregroundColor(color)
                .contentTransition(.numericText(value: Double(displayValue)))

            if !suffix.isEmpty {
                Text(suffix)
                    .font(font)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
        }
        .onAppear {
            displayValue = value
        }
        .onChange(of: value) { _, newValue in
            previousValue = displayValue
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                displayValue = newValue
            }
        }
    }
}

/// Animated counter with scale pulse effect
struct PulsingCounter: View {
    let value: Int
    let font: Font
    let color: Color
    let suffix: String

    @State private var scale: CGFloat = 1.0
    @State private var previousValue: Int = 0

    init(
        value: Int,
        font: Font = .title,
        color: Color = .primary,
        suffix: String = ""
    ) {
        self.value = value
        self.font = font
        self.color = color
        self.suffix = suffix
    }

    var body: some View {
        AnimatedCounter(value: value, font: font, color: color, suffix: suffix)
            .scaleEffect(scale)
            .onChange(of: value) { oldValue, newValue in
                if newValue > oldValue {
                    // Pulse up when value increases
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        scale = 1.15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            scale = 1.0
                        }
                    }
                }
            }
    }
}

/// Big animated calorie meter with ring
struct CalorieMeter: View {
    let consumed: Int
    let burned: Int
    let target: Int

    @State private var animatedProgress: Double = 0
    @State private var showGlow = false

    private var netCalories: Int {
        consumed - burned
    }

    private var remaining: Int {
        max(0, target - netCalories)
    }

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(netCalories) / Double(target), 1.5)
    }

    private var ringColor: Color {
        if netCalories > target {
            return .red
        } else if progress > 0.8 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(ringColor.opacity(showGlow ? 0.3 : 0))
                .frame(width: 180, height: 180)
                .blur(radius: 20)

            // Background ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 20)
                .frame(width: 160, height: 160)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [ringColor.opacity(0.5), ringColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * min(animatedProgress, 1.0))
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.4), radius: 8, y: 4)

            // Overflow indicator (if over target)
            if animatedProgress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(animatedProgress - 1.0, 0.5))
                    .stroke(
                        Color.red.opacity(0.8),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round, dash: [8, 4])
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
            }

            // Center content
            VStack(spacing: 4) {
                PulsingCounter(
                    value: remaining,
                    font: .system(size: 42, weight: .bold, design: .rounded),
                    color: ringColor
                )

                Text("remaining")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = progress
            }
            withAnimation(.easeInOut(duration: 0.5).delay(0.8)) {
                showGlow = true
            }
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedProgress = newProgress
            }
            // Pulse glow on change
            withAnimation(.easeOut(duration: 0.2)) {
                showGlow = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showGlow = false
                }
            }
        }
    }
}

/// Confetti explosion for celebrations
struct ConfettiView: View {
    let isActive: Bool

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                explode()
            }
        }
    }

    private func explode() {
        particles = (0..<30).map { _ in
            ConfettiParticle(
                x: 0,
                y: 0,
                color: [.green, .orange, .purple, .blue, .pink].randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: 0,
                opacity: 1
            )
        }

        for i in particles.indices {
            let angle = Double.random(in: 0...360)
            let distance = CGFloat.random(in: 100...200)
            let duration = Double.random(in: 0.5...1.0)

            withAnimation(.easeOut(duration: duration)) {
                particles[i].x = cos(angle * .pi / 180) * distance
                particles[i].y = sin(angle * .pi / 180) * distance - 50
                particles[i].rotation = Double.random(in: 180...720)
                particles[i].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            particles = []
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    var rotation: Double
    var opacity: Double
}

/// Progress bar with animated fill
struct AnimatedProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.opacity(0.15))

                // Fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(animatedProgress, 1.0))
                    .shadow(color: color.opacity(0.3), radius: 4, y: 2)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedProgress = newProgress
            }
        }
    }
}

/// XP-style level bar
struct LevelProgressBar: View {
    let current: Double
    let target: Double
    let label: String
    let color: Color
    let icon: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return current / target
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 2) {
                    PulsingCounter(
                        value: Int(current),
                        font: .caption.bold(),
                        color: color
                    )
                    Text("/\(Int(target))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            AnimatedProgressBar(progress: progress, color: color, height: 8)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CalorieMeter(consumed: 1200, burned: 300, target: 2000)

        LevelProgressBar(
            current: 85,
            target: 150,
            label: "Protein",
            color: .blue,
            icon: "p.circle.fill"
        )
        .padding(.horizontal)
    }
}
