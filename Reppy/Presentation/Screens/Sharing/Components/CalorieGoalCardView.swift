import SwiftUI

struct CalorieGoalCardView: View {
    let targetCalories: Int
    let streak: Int

    var body: some View {
        ZStack {
            // Background gradient
            CardGradientBackground(colors: [
                Color(red: 0.1, green: 0.7, blue: 0.4),
                Color(red: 0.2, green: 0.5, blue: 0.3),
                Color(red: 0.1, green: 0.4, blue: 0.3)
            ])

            // Decorative elements
            GeometryReader { geometry in
                Group {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 300, height: 300)
                        .offset(x: -100, y: -50)

                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 400, height: 400)
                        .offset(x: geometry.size.width - 200, y: geometry.size.height - 300)

                    Image(systemName: "target")
                        .font(.system(size: 100))
                        .foregroundStyle(.white.opacity(0.1))
                        .offset(x: geometry.size.width - 120, y: 150)
                }
            }

            VStack(spacing: 40) {
                Spacer()

                // Target hit animation
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.white.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                            .frame(width: CGFloat(140 + i * 40), height: CGFloat(140 + i * 40))
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                }

                // Title
                VStack(spacing: 12) {
                    Text("CALORIE GOAL")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("ACHIEVED!")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.white)
                }

                // Calorie target
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(targetCalories)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                    Text("cal")
                        .font(.system(size: 32, weight: .bold))
                }
                .foregroundStyle(.white)

                // Streak
                if streak > 1 {
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundStyle(.orange)

                        Text("\(streak) Day Streak")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
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
    CalorieGoalCardView(targetCalories: 2000, streak: 7)
        .frame(width: 390, height: 844)
}
