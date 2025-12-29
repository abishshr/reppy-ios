import SwiftUI

struct PersonalRecordCardView: View {
    let exercise: String
    let weight: Double
    let previousWeight: Double?
    let unit: String

    private var improvement: Double? {
        guard let previous = previousWeight else { return nil }
        return weight - previous
    }

    var body: some View {
        ZStack {
            // Background gradient
            CardGradientBackground(colors: [
                Color(red: 0.9, green: 0.7, blue: 0.1),
                Color(red: 1.0, green: 0.5, blue: 0.0),
                Color(red: 0.9, green: 0.3, blue: 0.1)
            ])

            // Trophy decorations
            GeometryReader { geometry in
                Image(systemName: "trophy.fill")
                    .font(.system(size: 200))
                    .foregroundStyle(.white.opacity(0.1))
                    .rotationEffect(.degrees(-15))
                    .offset(x: -80, y: 100)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 150))
                    .foregroundStyle(.white.opacity(0.1))
                    .rotationEffect(.degrees(15))
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 300)
            }

            VStack(spacing: 40) {
                Spacer()

                // PR Badge
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 160, height: 160)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)

                    VStack(spacing: 4) {
                        Text("PR")
                            .font(.system(size: 48, weight: .black))
                        Text("NEW")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(4)
                    }
                    .foregroundStyle(.white)
                }

                // Exercise name
                Text(exercise.uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .tracking(4)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Weight
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%.1f", weight))
                        .font(.system(size: 100, weight: .black, design: .rounded))
                    Text(unit)
                        .font(.system(size: 36, weight: .bold))
                }
                .foregroundStyle(.white)

                // Improvement (if previous exists)
                if let imp = improvement {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                        Text("+\(String(format: "%.1f", imp)) \(unit)")
                            .font(.title2.bold())
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
                }

                Spacer()

                ReppyBranding()
                    .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    PersonalRecordCardView(exercise: "Bench Press", weight: 100.0, previousWeight: 95.0, unit: "kg")
        .frame(width: 390, height: 844)
}
