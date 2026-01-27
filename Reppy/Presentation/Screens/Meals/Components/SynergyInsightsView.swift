import SwiftUI

struct SynergyInsightsView: View {
    let synergy: MealSynergyAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with counts
            HStack {
                Text("Nutrient Interactions")
                    .font(.headline)

                Spacer()

                if synergy.beneficialCount > 0 {
                    Label("\(synergy.beneficialCount)", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if synergy.inhibitingCount > 0 {
                    Label("\(synergy.inhibitingCount)", systemImage: "minus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            if synergy.insights.isEmpty {
                NoSynergiesView()
            } else {
                // Synergy cards
                VStack(spacing: 12) {
                    ForEach(synergy.insights) { insight in
                        SynergyCard(insight: insight)
                    }
                }
            }
        }
    }
}

// MARK: - Synergy Card

struct SynergyCard: View {
    let insight: SynergyInsight

    private var backgroundColor: Color {
        insight.isBeneficial ? .green.opacity(0.1) : .orange.opacity(0.1)
    }

    private var accentColor: Color {
        insight.isBeneficial ? .green : .orange
    }

    private var icon: String {
        insight.isBeneficial ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)

                Text(insight.title)
                    .font(.subheadline.bold())

                Spacer()

                ImpactBadge(impact: insight.impact)
            }

            Text(insight.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !insight.foodsInvolved.isEmpty {
                HStack {
                    ForEach(insight.foodsInvolved, id: \.self) { food in
                        Text(food.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Impact Badge

struct ImpactBadge: View {
    let impact: String

    private var color: Color {
        switch impact {
        case "high": return .red
        case "medium": return .orange
        case "low": return .gray
        default: return .gray
        }
    }

    var body: some View {
        Text(impact.capitalized)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - No Synergies View

private struct NoSynergiesView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No notable nutrient interactions")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Add more variety to your meal to see beneficial combinations")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Synergy Sheet

struct SynergyDetailSheet: View {
    let synergy: MealSynergyAnalysis
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary
                    SynergySummaryCard(synergy: synergy)

                    // Beneficial Synergies
                    let beneficial = synergy.insights.filter { $0.isBeneficial }
                    if !beneficial.isEmpty {
                        SynergySection(
                            title: "Beneficial Combinations",
                            icon: "plus.circle.fill",
                            color: .green,
                            insights: beneficial
                        )
                    }

                    // Inhibiting Interactions
                    let inhibiting = synergy.insights.filter { !$0.isBeneficial }
                    if !inhibiting.isEmpty {
                        SynergySection(
                            title: "Watch Out For",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange,
                            insights: inhibiting
                        )
                    }

                    // Tips
                    TipsSection()
                }
                .padding()
            }
            .navigationTitle("Nutrient Synergies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Synergy Summary Card

private struct SynergySummaryCard: View {
    let synergy: MealSynergyAnalysis

    var body: some View {
        HStack(spacing: 24) {
            VStack {
                Text("\(synergy.beneficialCount)")
                    .font(.title.bold())
                    .foregroundStyle(.green)
                Text("Beneficial")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 40)

            VStack {
                Text("\(synergy.inhibitingCount)")
                    .font(.title.bold())
                    .foregroundStyle(.orange)
                Text("To Watch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Synergy Section

private struct SynergySection: View {
    let title: String
    let icon: String
    let color: Color
    let insights: [SynergyInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }

            ForEach(insights) { insight in
                SynergyCard(insight: insight)
            }
        }
    }
}

// MARK: - Tips Section

private struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Quick Tips")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                TipRow(text: "Pair iron-rich foods with vitamin C for better absorption")
                TipRow(text: "Separate calcium and iron sources when possible")
                TipRow(text: "Add healthy fats to vegetables for vitamin absorption")
                TipRow(text: "Wait 1-2 hours after meals before coffee/tea")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SynergyDetailSheet(
        synergy: MealSynergyAnalysis(
            insights: [
                SynergyInsight(
                    type: "beneficial",
                    title: "Iron + Vitamin C",
                    description: "Vitamin C significantly enhances iron absorption.",
                    foodsInvolved: ["spinach", "orange"],
                    impact: "high"
                ),
                SynergyInsight(
                    type: "inhibiting",
                    title: "Calcium blocks Iron",
                    description: "Calcium can reduce iron absorption.",
                    foodsInvolved: ["spinach", "milk"],
                    impact: "medium"
                )
            ],
            beneficialCount: 1,
            inhibitingCount: 1
        )
    )
}
