import SwiftUI

/// Card showing phase-based nutrition and workout recommendations
struct CycleRecommendationsCard: View {
    let recommendations: CycleRecommendations
    @State private var selectedTab: RecommendationTab = .nutrition

    enum RecommendationTab: String, CaseIterable {
        case nutrition = "Nutrition"
        case workout = "Workout"
        case selfCare = "Self-Care"

        var icon: String {
            switch self {
            case .nutrition: return "leaf.fill"
            case .workout: return "figure.run"
            case .selfCare: return "heart.fill"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with phase
            HStack {
                Image(systemName: recommendations.phaseEnum.icon)
                    .font(.title2)
                    .foregroundColor(phaseColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(recommendations.phaseEnum.displayName) Phase")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Workout intensity badge
                Text(workoutIntensityText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(workoutIntensityColor)
                    .cornerRadius(12)
            }

            // Phase description
            Text(recommendations.phaseDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Tab selector
            HStack(spacing: 0) {
                ForEach(RecommendationTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.subheadline)

                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab
                                ? phaseColor.opacity(0.2)
                                : Color.clear
                        )
                        .foregroundColor(
                            selectedTab == tab ? phaseColor : .secondary
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(10)

            // Content based on selected tab
            Group {
                switch selectedTab {
                case .nutrition:
                    nutritionContent
                case .workout:
                    workoutContent
                case .selfCare:
                    selfCareContent
                }
            }
            .transition(.opacity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Tab Content

    private var nutritionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recommendations.nutritionTips.prefix(3), id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text(tip)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }

            Divider()

            // Recommended foods
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommended Foods")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recommendations.recommendedFoods, id: \.self) { food in
                            Text(food)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // Foods to limit
            if !recommendations.foodsToLimit.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Limit")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recommendations.foodsToLimit, id: \.self) { food in
                                Text(food)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }

    private var workoutContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Intensity indicator
            HStack {
                Text("Recommended Intensity:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < intensityLevel ? workoutIntensityColor : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }

                Text(recommendations.workoutIntensity.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(workoutIntensityColor)
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(10)

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recommendations.workoutTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "figure.run")
                            .foregroundColor(phaseColor)
                            .font(.caption)

                        Text(tip)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private var selfCareContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(recommendations.selfCareTips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.caption)

                    Text(tip)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: - Helpers

    private var phaseColor: Color {
        switch recommendations.phaseEnum {
        case .menstruation: return .red
        case .follicular: return .orange
        case .ovulation: return .green
        case .luteal: return .purple
        case .unknown: return .gray
        }
    }

    private var workoutIntensityText: String {
        switch recommendations.workoutIntensity {
        case "light": return "Light"
        case "moderate": return "Moderate"
        case "high": return "High"
        default: return "Moderate"
        }
    }

    private var workoutIntensityColor: Color {
        switch recommendations.workoutIntensity {
        case "light": return .blue
        case "moderate": return .orange
        case "high": return .red
        default: return .orange
        }
    }

    private var intensityLevel: Int {
        switch recommendations.workoutIntensity {
        case "light": return 1
        case "moderate": return 2
        case "high": return 3
        default: return 2
        }
    }
}

/// Compact version for dashboard
struct CycleRecommendationsCardCompact: View {
    let recommendations: CycleRecommendations
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(phaseColor)

                    Text("Phase Tips")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(recommendations.phaseEnum.displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(phaseColor)
                        .cornerRadius(8)
                }

                // Quick tips preview
                HStack(spacing: 16) {
                    // Nutrition tip
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Eat", systemImage: "leaf.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(recommendations.recommendedFoods.first ?? "")
                            .font(.caption)
                            .lineLimit(1)
                    }

                    Divider()
                        .frame(height: 30)

                    // Workout tip
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Workout", systemImage: "figure.run")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("\(recommendations.workoutIntensity.capitalized) intensity")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var phaseColor: Color {
        switch recommendations.phaseEnum {
        case .menstruation: return .red
        case .follicular: return .orange
        case .ovulation: return .green
        case .luteal: return .purple
        case .unknown: return .gray
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CycleRecommendationsCard(
                recommendations: CycleRecommendations(
                    phase: "follicular",
                    phaseDescription: "Estrogen is rising, boosting your mood and energy. This is a great time for new challenges and high-energy activities.",
                    nutritionTips: [
                        "Focus on lean proteins to support muscle building",
                        "Include fermented foods for gut health",
                        "Eat fresh, vibrant vegetables"
                    ],
                    recommendedFoods: ["Eggs", "Chicken", "Yogurt", "Broccoli", "Quinoa"],
                    foodsToLimit: ["Heavy, greasy foods", "Excessive caffeine"],
                    workoutTips: [
                        "Great time for high-intensity workouts",
                        "Try new exercises or classes",
                        "Strength training is highly effective now"
                    ],
                    workoutIntensity: "high",
                    selfCareTips: [
                        "Channel your energy into creative projects",
                        "Social activities can be fulfilling"
                    ]
                )
            )

            CycleRecommendationsCardCompact(
                recommendations: CycleRecommendations(
                    phase: "luteal",
                    phaseDescription: "Progesterone rises, which may cause PMS symptoms.",
                    nutritionTips: ["Include complex carbs"],
                    recommendedFoods: ["Dark chocolate", "Bananas"],
                    foodsToLimit: ["Caffeine"],
                    workoutTips: ["Moderate intensity"],
                    workoutIntensity: "moderate",
                    selfCareTips: ["Rest"]
                ),
                onTap: {}
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
