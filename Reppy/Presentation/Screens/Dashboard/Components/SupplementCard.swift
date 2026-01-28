import SwiftUI

/// Compact card showing today's supplement status on the dashboard
struct SupplementCard: View {
    let summary: TodaySupplementSummary?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "pills.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                    )

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text("Supplements")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let summary = summary, summary.hasData {
                        Text("\(summary.totalLogs) taken today")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Tap to log vitamins")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Quick nutrients preview
                if let summary = summary, summary.hasData {
                    HStack(spacing: 6) {
                        if summary.totalVitaminDMcg > 0 {
                            SmallNutrientBadge(label: "D", color: .orange)
                        }
                        if summary.totalVitaminCMg > 0 {
                            SmallNutrientBadge(label: "C", color: .yellow)
                        }
                        if summary.totalVitaminB12Mcg > 0 {
                            SmallNutrientBadge(label: "B12", color: .red)
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

// MARK: - Small Nutrient Badge

struct SmallNutrientBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}

#Preview {
    VStack(spacing: 16) {
        SupplementCard(
            summary: TodaySupplementSummary(
                totalLogs: 2,
                supplementsTaken: ["Vitamin D", "Fish Oil"],
                totalVitaminAMcg: 0,
                totalVitaminCMg: 0,
                totalVitaminDMcg: 125,
                totalVitaminEMg: 0,
                totalVitaminKMcg: 0,
                totalVitaminB1Mg: 0,
                totalVitaminB2Mg: 0,
                totalVitaminB3Mg: 0,
                totalVitaminB6Mg: 0,
                totalVitaminB9Mcg: 0,
                totalVitaminB12Mcg: 2.4,
                totalCalciumMg: 0,
                totalIronMg: 0,
                totalMagnesiumMg: 0,
                totalPhosphorusMg: 0,
                totalPotassiumMg: 0,
                totalZincMg: 0,
                totalSeleniumMcg: 0,
                totalCopperMcg: 0,
                totalManganeseMg: 0
            ),
            onTap: {}
        )

        SupplementCard(summary: nil, onTap: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
