import SwiftUI

/// Compact horizontal row showing protein, carbs, and fat progress
struct MacroPillsRow: View {
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbsTarget: Double
    let fat: Double
    let fatTarget: Double

    var body: some View {
        HStack(spacing: 8) {
            MacroProgressPill(
                label: "P",
                current: protein,
                target: proteinTarget,
                color: .blue
            )

            MacroProgressPill(
                label: "C",
                current: carbs,
                target: carbsTarget,
                color: .orange
            )

            MacroProgressPill(
                label: "F",
                current: fat,
                target: fatTarget,
                color: .purple
            )
        }
    }
}

/// Individual macro pill with mini progress bar
struct MacroProgressPill: View {
    let label: String
    let current: Double
    let target: Double
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Label and values
            HStack(spacing: 2) {
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(color)

                Text("\(Int(current))/\(Int(target))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }
}

#Preview {
    MacroPillsRow(
        protein: 45,
        proteinTarget: 120,
        carbs: 80,
        carbsTarget: 200,
        fat: 25,
        fatTarget: 65
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
