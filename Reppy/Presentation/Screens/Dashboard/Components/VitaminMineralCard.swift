import SwiftUI

/// Card showing daily vitamin & mineral progress on the dashboard
struct VitaminMineralCard: View {
    let totals: VitaminMineralTotals
    let targets: MicronutrientTargets?
    let onTap: () -> Void

    private var keyNutrients: [KeyNutrientProgress] {
        totals.keyNutrients(targets: targets)
    }

    private var hasData: Bool {
        totals.hasData
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "pill.fill")
                            .foregroundStyle(.purple)
                        Text("Vitamins & Minerals")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        if hasData {
                            Text(overallStatusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Always show compact view with key nutrients
                if hasData {
                    HStack(spacing: 8) {
                        ForEach(keyNutrients.prefix(4)) { nutrient in
                            CompactNutrientBadge(nutrient: nutrient)
                        }
                        Spacer()
                    }

                    // Progress summary
                    let wellTrackedCount = keyNutrients.filter { $0.percentComplete >= 80 }.count
                    HStack {
                        Text("\(wellTrackedCount)/\(keyNutrients.count) nutrients on track")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Tap for details")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Log a meal to track vitamins & minerals")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var overallStatusText: String {
        let wellTrackedCount = keyNutrients.filter { $0.percentComplete >= 80 }.count
        if wellTrackedCount >= 5 {
            return "Great!"
        } else if wellTrackedCount >= 3 {
            return "Good"
        } else {
            return ""
        }
    }
}

// MARK: - Vitamin Nutrient Row

struct VitaminNutrientRow: View {
    let nutrient: KeyNutrientProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: nutrient.icon)
                        .font(.caption)
                        .foregroundStyle(nutrient.color)
                        .frame(width: 16)

                    Text(nutrient.name)
                        .font(.subheadline)
                }

                Spacer()

                Text("\(nutrient.formattedActual) / \(nutrient.formattedTarget) \(nutrient.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(nutrient.color.opacity(0.2))
                        .frame(height: 6)

                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * nutrient.progress, height: 6)
                        .animation(.spring(response: 0.4), value: nutrient.progress)
                }
            }
            .frame(height: 6)
        }
    }

    private var progressColor: Color {
        if nutrient.percentComplete >= 80 {
            return .green
        } else if nutrient.percentComplete >= 50 {
            return nutrient.color
        } else {
            return nutrient.color.opacity(0.7)
        }
    }
}

// MARK: - Compact Nutrient Badge

struct CompactNutrientBadge: View {
    let nutrient: KeyNutrientProgress

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: nutrient.icon)
                .font(.caption2)
                .foregroundStyle(statusColor)

            Text("\(nutrient.percentComplete)%")
                .font(.caption2.bold())
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        if nutrient.percentComplete >= 80 {
            return .green
        } else if nutrient.percentComplete >= 50 {
            return nutrient.color
        } else {
            return .gray
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // With data
        VitaminMineralCard(
            totals: VitaminMineralTotals(
                vitaminA: 450,
                vitaminC: 65,
                vitaminD: 10,
                vitaminE: 8,
                vitaminK: 80,
                calcium: 600,
                iron: 12,
                magnesium: 280,
                potassium: 2000
            ),
            targets: MicronutrientTargets(
                vitaminA: 900, vitaminC: 90, vitaminD: 15, vitaminE: 15, vitaminK: 120,
                thiamin: 1.2, riboflavin: 1.3, niacin: 16, vitaminB6: 1.3, folate: 400, vitaminB12: 2.4,
                calcium: 1000, iron: 8, magnesium: 420, phosphorus: 700, potassium: 3400,
                zinc: 11, selenium: 55, copper: 900, manganese: 2.3, iodine: 150, chromium: 35,
                omega3: 1.6, choline: 550,
                source: "NIH DRI", adjustments: []
            ),
            onTap: {}
        )

        // Without data
        VitaminMineralCard(
            totals: VitaminMineralTotals(),
            targets: nil,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
