import SwiftUI

/// Daily testosterone impact summary card for male users
struct DailyTestosteroneSummary: View {
    let boostingCount: Int
    let reducingCount: Int
    let neutralCount: Int

    private var overallRating: String {
        if boostingCount > reducingCount * 2 { return "Great" }
        if boostingCount > reducingCount { return "Good" }
        if reducingCount > boostingCount { return "Poor" }
        return "Neutral"
    }

    private var ratingColor: Color {
        switch overallRating {
        case "Great": return .green
        case "Good": return .blue
        case "Poor": return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                Text("Testosterone Today")
                    .font(.headline)
                Spacer()
                Text(overallRating)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(ratingColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ratingColor.opacity(0.15))
                    .cornerRadius(8)
            }

            // Score breakdown
            HStack(spacing: 16) {
                TScoreItem(count: boostingCount, label: "Boosting", color: .green, icon: "arrow.up")
                TScoreItem(count: reducingCount, label: "Reducing", color: .red, icon: "arrow.down")
                TScoreItem(count: neutralCount, label: "Neutral", color: .gray, icon: "minus")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct TScoreItem: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "\(icon).circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 20) {
        DailyTestosteroneSummary(boostingCount: 5, reducingCount: 1, neutralCount: 3)
        DailyTestosteroneSummary(boostingCount: 2, reducingCount: 4, neutralCount: 1)
        DailyTestosteroneSummary(boostingCount: 2, reducingCount: 2, neutralCount: 4)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
