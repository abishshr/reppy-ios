import SwiftUI

/// Compact calorie display with big remaining number and progress bar
struct CompactCalorieHeader: View {
    let consumed: Int
    let burned: Int
    let target: Int

    private var remaining: Int {
        max(0, target - consumed + burned)
    }

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(consumed) / Double(target), 1.0)
    }

    private var progressColor: Color {
        if consumed > target {
            return .red
        } else if progress > 0.9 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Big remaining number
            VStack(spacing: 2) {
                Text("\(remaining)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("calories remaining")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * progress)
                            .animation(.spring(response: 0.4), value: progress)
                    }
                }
                .frame(height: 12)

                // Eaten / Target
                Text("\(consumed) / \(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Burned and Net row
            HStack(spacing: 24) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Burned: \(burned)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("Net: \(consumed - burned)")
                    .font(.subheadline.bold())
                    .foregroundColor(progressColor)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CompactCalorieHeader(consumed: 753, burned: 312, target: 2000)
        CompactCalorieHeader(consumed: 1850, burned: 200, target: 2000)
        CompactCalorieHeader(consumed: 2200, burned: 100, target: 2000)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
