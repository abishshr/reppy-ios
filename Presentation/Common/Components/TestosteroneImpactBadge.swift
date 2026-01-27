import SwiftUI

/// Badge showing testosterone impact for a food or meal
/// Only displayed for male users
struct TestosteroneImpactBadge: View {
    let impact: String  // "boosts", "reduces", "neutral", "boosting", "reducing", "mixed"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .semibold))
            Text(displayText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }

    private var iconName: String {
        switch impact.lowercased() {
        case "boosts", "boosting":
            return "arrow.up.circle.fill"
        case "reduces", "reducing":
            return "arrow.down.circle.fill"
        case "mixed":
            return "arrow.up.arrow.down.circle.fill"
        default:
            return "minus.circle.fill"
        }
    }

    private var color: Color {
        switch impact.lowercased() {
        case "boosts", "boosting":
            return .green
        case "reduces", "reducing":
            return .red
        case "mixed":
            return .orange
        default:
            return .gray
        }
    }

    private var displayText: String {
        switch impact.lowercased() {
        case "boosts":
            return "T+"
        case "reduces":
            return "T-"
        case "boosting":
            return "T+ Meal"
        case "reducing":
            return "T- Meal"
        case "mixed":
            return "T Mixed"
        default:
            return "T Neutral"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        TestosteroneImpactBadge(impact: "boosts")
        TestosteroneImpactBadge(impact: "reduces")
        TestosteroneImpactBadge(impact: "neutral")
        TestosteroneImpactBadge(impact: "boosting")
        TestosteroneImpactBadge(impact: "reducing")
        TestosteroneImpactBadge(impact: "mixed")
    }
    .padding()
}
