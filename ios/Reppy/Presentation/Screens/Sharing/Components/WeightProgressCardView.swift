import SwiftUI

struct WeightProgressCardView: View {
    let startWeight: Double
    let currentWeight: Double
    let goalWeight: Double?
    let unit: String

    private var weightLost: Double {
        startWeight - currentWeight
    }

    private var progressPercent: Double {
        guard let goal = goalWeight else { return 0 }
        let totalToLose = startWeight - goal
        guard totalToLose > 0 else { return 0 }
        return min(1.0, weightLost / totalToLose)
    }

    private var formattedLost: String {
        String(format: "%.1f", abs(weightLost))
    }

    var body: some View {
        ZStack {
            // Background gradient
            CardGradientBackground(colors: [
                Color(red: 0.1, green: 0.6, blue: 0.8),
                Color(red: 0.2, green: 0.4, blue: 0.9),
                Color(red: 0.3, green: 0.2, blue: 0.8)
            ])

            // Decorative elements
            GeometryReader { geometry in
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: CGFloat(100 + i * 50), height: CGFloat(100 + i * 50))
                        .offset(
                            x: CGFloat.random(in: -50...geometry.size.width),
                            y: CGFloat.random(in: -50...geometry.size.height)
                        )
                }
            }

            VStack(spacing: 40) {
                Spacer()

                // Title
                Text("WEIGHT PROGRESS")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(6)
                    .foregroundStyle(.white.opacity(0.8))

                // Main stat
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(weightLost >= 0 ? "-" : "+")
                            .font(.system(size: 60, weight: .bold))
                        Text(formattedLost)
                            .font(.system(size: 120, weight: .black, design: .rounded))
                        Text(unit)
                            .font(.system(size: 40, weight: .bold))
                    }
                    .foregroundStyle(.white)

                    Text(weightLost >= 0 ? "LOST" : "GAINED")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(8)
                        .foregroundStyle(.white.opacity(0.9))
                }

                // Progress visualization
                VStack(spacing: 20) {
                    // Start -> Current -> Goal
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("START")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Text(String(format: "%.1f", startWeight))
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)

                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))

                        VStack(spacing: 4) {
                            Text("NOW")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Text(String(format: "%.1f", currentWeight))
                                .font(.title.bold())
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity)

                        if let goal = goalWeight {
                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.5))

                            VStack(spacing: 4) {
                                Text("GOAL")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(String(format: "%.1f", goal))
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 40)

                    // Progress bar (if goal exists)
                    if goalWeight != nil {
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.2))

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [.green, .mint],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progressPercent)
                                }
                            }
                            .frame(height: 16)
                            .padding(.horizontal, 40)

                            Text("\(Int(progressPercent * 100))% to goal")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }

                Spacer()

                ReppyBranding()
                    .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    WeightProgressCardView(startWeight: 85.0, currentWeight: 78.5, goalWeight: 75.0, unit: "kg")
        .frame(width: 390, height: 844)
}
