import SwiftUI

/// Card displaying daily macro progress
struct MacrosCard: View {
    let calories: Int
    let calorieTarget: Int
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbsTarget: Double
    let fat: Double
    let fatTarget: Double

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Today's Nutrition")
                    .font(.headline)
                Spacer()
                Text("\(calories) / \(calorieTarget) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Calorie progress bar
            ProgressView(value: min(Double(calories) / Double(calorieTarget), 1.0))
                .tint(calories > calorieTarget ? .red : .green)

            // Macros
            HStack(spacing: 16) {
                MacroColumn(
                    name: "Protein",
                    current: protein,
                    target: proteinTarget,
                    color: .blue
                )

                MacroColumn(
                    name: "Carbs",
                    current: carbs,
                    target: carbsTarget,
                    color: .orange
                )

                MacroColumn(
                    name: "Fat",
                    current: fat,
                    target: fatTarget,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MacroColumn: View {
    let name: String
    let current: Double
    let target: Double
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(current))")
                        .font(.system(size: 14, weight: .semibold))
                    Text("/ \(Int(target))g")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60, height: 60)

            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MacrosCard(
        calories: 1500,
        calorieTarget: 2000,
        protein: 120,
        proteinTarget: 150,
        carbs: 180,
        carbsTarget: 250,
        fat: 50,
        fatTarget: 65
    )
    .padding()
}
