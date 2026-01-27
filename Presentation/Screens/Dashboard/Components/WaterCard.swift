import SwiftUI

/// Water tracking card for the dashboard
struct WaterCard: View {
    let todayMl: Int
    let goalMl: Int
    let onQuickAdd: (Int) -> Void
    let onTap: () -> Void

    private var percentage: Double {
        guard goalMl > 0 else { return 0 }
        return min(Double(todayMl) / Double(goalMl), 1.0)
    }

    private var remainingMl: Int {
        max(0, goalMl - todayMl)
    }

    private var isGoalMet: Bool {
        todayMl >= goalMl
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.cyan)
                    Text("Water")
                        .font(.headline)
                }

                Spacer()

                Button(action: onTap) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress ring and stats
            HStack(spacing: 20) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: percentage)
                        .stroke(
                            isGoalMet ? Color.green : Color.cyan,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: percentage)

                    VStack(spacing: 2) {
                        if isGoalMet {
                            Image(systemName: "checkmark")
                                .font(.title2.bold())
                                .foregroundStyle(.green)
                        } else {
                            Text("\(Int(percentage * 100))%")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .frame(width: 70, height: 70)

                // Stats
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formatAmount(todayMl))
                            .font(.title2.bold())
                        Text("/ \(formatAmount(goalMl))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if isGoalMet {
                        Text("Goal reached!")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("\(formatAmount(remainingMl)) remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Quick add buttons
            HStack(spacing: 8) {
                ForEach(QuickWaterAmount.allCases, id: \.rawValue) { amount in
                    QuickAddWaterButton(amount: amount) {
                        onQuickAdd(amount.rawValue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func formatAmount(_ ml: Int) -> String {
        if ml >= 1000 {
            return String(format: "%.1fL", Double(ml) / 1000.0)
        }
        return "\(ml)ml"
    }
}

struct QuickAddWaterButton: View {
    let amount: QuickWaterAmount
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: amount.icon)
                    .font(.caption)
                Text(amount.displayName)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.cyan.opacity(0.1))
            .foregroundStyle(.cyan)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2)) { isPressed = false }
                }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        WaterCard(
            todayMl: 1500,
            goalMl: 2500,
            onQuickAdd: { _ in },
            onTap: {}
        )

        WaterCard(
            todayMl: 2600,
            goalMl: 2500,
            onQuickAdd: { _ in },
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
