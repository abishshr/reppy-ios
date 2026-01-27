import SwiftUI

struct FastingTimerView: View {
    let progress: Double // 0.0 to 1.0
    let elapsedTime: String
    let remainingTime: String

    private let lineWidth: CGFloat = 16
    private let gradient = LinearGradient(
        colors: [.orange, .red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

                // Progress arc
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        gradient,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                // Glow effect
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        gradient.opacity(0.3),
                        style: StrokeStyle(
                            lineWidth: lineWidth + 8,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 4)

                // Center content
                VStack(spacing: 8) {
                    // Elapsed time (large)
                    Text(elapsedTime)
                        .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("elapsed")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()
                        .frame(width: size * 0.3)
                        .padding(.vertical, 4)

                    // Remaining time
                    Text(remainingTime)
                        .font(.system(size: size * 0.08, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

// MARK: - Compact Timer (for Dashboard)

struct CompactFastingTimer: View {
    let progress: Double
    let remainingTime: String
    let protocolName: String

    var body: some View {
        HStack(spacing: 16) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Fasting: \(protocolName)")
                    .font(.subheadline.weight(.medium))

                Text("\(remainingTime) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%.0f%%", progress * 100))
                .font(.headline)
                .foregroundStyle(.orange)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Full Timer") {
    FastingTimerView(
        progress: 0.65,
        elapsedTime: "10:24:35",
        remainingTime: "5:35:25"
    )
    .frame(height: 300)
    .padding()
}

#Preview("Compact Timer") {
    CompactFastingTimer(
        progress: 0.65,
        remainingTime: "5:35:25",
        protocolName: "16:8"
    )
    .padding()
}
