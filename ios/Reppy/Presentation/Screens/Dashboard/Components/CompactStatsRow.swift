import SwiftUI

/// Compact row showing steps, calories burned, and streak
struct CompactStatsRow: View {
    let steps: Int
    let stepsGoal: Int
    let caloriesBurned: Int
    let streakDays: Int

    private var stepsProgress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(Double(steps) / Double(stepsGoal), 1.0)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Steps
            StatItem(
                icon: "figure.walk",
                value: formatSteps(steps),
                subtitle: "/ \(formatSteps(stepsGoal))",
                color: .green,
                progress: stepsProgress
            )

            Divider()
                .frame(height: 30)
                .padding(.horizontal, 8)

            // Calories burned
            StatItem(
                icon: "flame.fill",
                value: "\(caloriesBurned)",
                subtitle: "burned",
                color: .orange
            )

            Divider()
                .frame(height: 30)
                .padding(.horizontal, 8)

            // Streak
            StatItem(
                icon: "flame.fill",
                value: "\(streakDays)",
                subtitle: "day streak",
                color: streakDays > 0 ? .red : .gray
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }

    private func formatSteps(_ value: Int) -> String {
        if value >= 1000 {
            let formatted = Double(value) / 1000.0
            return String(format: "%.1fk", formatted)
        }
        return "\(value)"
    }
}

/// Individual stat item
struct StatItem: View {
    let icon: String
    let value: String
    let subtitle: String
    let color: Color
    var progress: Double? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Icon with optional progress ring
            ZStack {
                if let progress = progress {
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: icon)
                    .font(.system(size: progress != nil ? 12 : 14))
                    .foregroundColor(color)
            }
            .frame(width: 32, height: 32)

            // Value and subtitle
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 2) {
                    Text(value)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    if !subtitle.starts(with: "/") {
                        // Don't show subtitle inline if it's a goal
                    } else {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !subtitle.starts(with: "/") {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 20) {
        CompactStatsRow(
            steps: 6234,
            stepsGoal: 10000,
            caloriesBurned: 312,
            streakDays: 3
        )

        CompactStatsRow(
            steps: 10500,
            stepsGoal: 10000,
            caloriesBurned: 450,
            streakDays: 7
        )

        CompactStatsRow(
            steps: 0,
            stepsGoal: 10000,
            caloriesBurned: 0,
            streakDays: 0
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
