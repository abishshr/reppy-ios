import SwiftUI

struct TodaySummaryView: View {
    @State private var data: WidgetData = WidgetDataManager.shared.load() ?? .placeholder

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Calories Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: min(data.caloriesProgress, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(data.caloriesRemaining)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("cal left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Macros Grid
                HStack(spacing: 16) {
                    MacroRing(
                        label: "P",
                        value: Int(data.proteinConsumed),
                        target: Int(data.proteinTarget),
                        color: .red
                    )
                    MacroRing(
                        label: "C",
                        value: Int(data.carbsConsumed),
                        target: Int(data.carbsTarget),
                        color: .blue
                    )
                    MacroRing(
                        label: "F",
                        value: Int(data.fatConsumed),
                        target: Int(data.fatTarget),
                        color: .yellow
                    )
                }

                // Water & Steps
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.cyan)
                        Text("\(data.waterConsumedMl)ml")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }

                    VStack(spacing: 2) {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(.green)
                        Text("\(data.stepsToday)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Today")
        .onAppear {
            data = WidgetDataManager.shared.load() ?? .placeholder
        }
    }
}

// MARK: - Macro Ring

struct MacroRing: View {
    let label: String
    let value: Int
    let target: Int
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(value) / Double(target))
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(label)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            .frame(width: 36, height: 36)

            Text("\(value)g")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    TodaySummaryView()
}
