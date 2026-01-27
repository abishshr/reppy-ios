import SwiftUI

struct HealthScoreBadge: View {
    let score: Int
    var size: Size = .medium

    enum Size {
        case small, medium, large

        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .title2
            }
        }

        var circleSize: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 64
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .small: return 3
            case .medium: return 4
            case .large: return 6
            }
        }
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: size.lineWidth)
                .frame(width: size.circleSize, height: size.circleSize)

            // Progress circle
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                )
                .frame(width: size.circleSize, height: size.circleSize)
                .rotationEffect(.degrees(-90))

            // Score text
            Text("\(score)")
                .font(size.fontSize.bold())
                .foregroundStyle(scoreColor)
        }
    }
}

struct HealthScoreDetailSheet: View {
    let analysis: MealHealthAnalysis
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Main Score
                    VStack(spacing: 8) {
                        HealthScoreBadge(score: analysis.overallScore, size: .large)

                        Text(analysis.scoreRating)
                            .font(.title2.bold())
                            .foregroundStyle(scoreColor)

                        Text("Health Impact Score")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical)

                    // Score Breakdown
                    BreakdownSection(breakdown: analysis.breakdown)

                    // Positive Aspects
                    if !analysis.positiveAspects.isEmpty {
                        InsightsSection(
                            title: "Positives",
                            items: analysis.positiveAspects,
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }

                    // Concerns
                    if !analysis.concerns.isEmpty {
                        InsightsSection(
                            title: "Concerns",
                            items: analysis.concerns,
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                    }

                    // Insights
                    if !analysis.insights.isEmpty {
                        InsightsSection(
                            title: "Insights",
                            items: analysis.insights,
                            icon: "lightbulb.fill",
                            color: .blue
                        )
                    }

                    // Suggestions
                    if !analysis.suggestions.isEmpty {
                        InsightsSection(
                            title: "Suggestions",
                            items: analysis.suggestions,
                            icon: "arrow.up.right.circle.fill",
                            color: .purple
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Health Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var scoreColor: Color {
        switch analysis.overallScore {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Breakdown Section

private struct BreakdownSection: View {
    let breakdown: HealthScoreBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.headline)

            VStack(spacing: 12) {
                BreakdownRow(label: "Nutritional Balance", score: breakdown.nutritionalBalance)
                BreakdownRow(label: "Processing Level", score: breakdown.processingLevel)
                BreakdownRow(label: "Ingredient Quality", score: breakdown.ingredientQuality)
                BreakdownRow(label: "Macro Balance", score: breakdown.macroBalance)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct BreakdownRow: View {
    let label: String
    let score: Int

    private var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(score)")
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * Double(score) / 100)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Insights Section

private struct InsightsSection: View {
    let title: String
    let items: [String]
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color.opacity(0.5))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HealthScoreDetailSheet(
        analysis: MealHealthAnalysis(
            overallScore: 75,
            breakdown: HealthScoreBreakdown(
                nutritionalBalance: 80,
                processingLevel: 70,
                ingredientQuality: 75,
                macroBalance: 72
            ),
            insights: ["Good protein content", "Moderate fiber"],
            suggestions: ["Add more vegetables", "Consider whole grain alternatives"],
            positiveAspects: ["High in protein", "Low in sugar"],
            concerns: ["Could use more fiber", "Slightly high in sodium"]
        )
    )
}
