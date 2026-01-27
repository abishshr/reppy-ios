import SwiftUI

/// Card displaying daily steps progress
struct StepsCard: View {
    let steps: Int
    let goal: Int
    let onSync: () -> Void

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }

    private var remaining: Int {
        max(0, goal - steps)
    }

    private var isGoalMet: Bool {
        steps >= goal
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("Steps")
                    .font(.headline)

                Spacer()

                Button(action: onSync) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(steps.formatted())")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text("/ \(goal.formatted())")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            ProgressView(value: progress)
                .tint(isGoalMet ? .green : .blue)

            HStack {
                if isGoalMet {
                    Label("Goal reached!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                } else {
                    Text("\(remaining.formatted()) steps to go")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isGoalMet ? .green : .blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        StepsCard(steps: 7500, goal: 10000, onSync: {})
        StepsCard(steps: 12000, goal: 10000, onSync: {})
    }
    .padding()
    .background(Color(.systemGray6))
}
