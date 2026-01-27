import SwiftUI

/// Compact card showing blood work status on the dashboard
struct BloodWorkCard: View {
    let summary: BloodWorkSummary?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "drop.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    )

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text("Blood Work")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let summary = summary, summary.hasData {
                        if let days = summary.daysSinceTest {
                            if days == 0 {
                                Text("Updated today")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if days < 30 {
                                Text("\(days) days ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Due for update")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    } else {
                        Text("Tap to add results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Health score or status
                if let summary = summary, summary.hasData {
                    if let score = summary.healthScore {
                        HealthScoreMini(score: score)
                    } else {
                        // Show marker counts
                        HStack(spacing: 4) {
                            if summary.outOfRangeCount > 0 {
                                MiniCountBadge(count: summary.outOfRangeCount, color: .red)
                            }
                            if summary.suboptimalCount > 0 {
                                MiniCountBadge(count: summary.suboptimalCount, color: .orange)
                            }
                            if summary.optimalCount > 0 {
                                MiniCountBadge(count: summary.optimalCount, color: .green)
                            }
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Health Score Mini

struct HealthScoreMini: View {
    let score: Int

    var color: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        if score >= 40 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
                .frame(width: 32, height: 32)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Mini Count Badge

struct MiniCountBadge: View {
    let count: Int
    let color: Color

    var body: some View {
        Text("\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(color)
            .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 16) {
        BloodWorkCard(
            summary: BloodWorkSummary(
                hasData: true,
                latestPanelId: "1",
                latestTestDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                daysSinceTest: 7,
                healthScore: 75,
                totalMarkersTested: 20,
                optimalCount: 15,
                suboptimalCount: 3,
                outOfRangeCount: 2,
                criticalMarkers: ["Vitamin D"],
                topConcerns: ["Low Vitamin D"]
            ),
            onTap: {}
        )

        BloodWorkCard(summary: nil, onTap: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
