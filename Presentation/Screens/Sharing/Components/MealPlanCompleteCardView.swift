import SwiftUI

struct MealPlanCompleteCardView: View {
    let planName: String
    let daysCompleted: Int

    var body: some View {
        ZStack {
            // Background gradient
            CardGradientBackground(colors: [
                Color(red: 0.2, green: 0.8, blue: 0.5),
                Color(red: 0.1, green: 0.6, blue: 0.6),
                Color(red: 0.1, green: 0.4, blue: 0.7)
            ])

            // Food decorations
            GeometryReader { geometry in
                Group {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .rotationEffect(.degrees(-20))
                        .offset(x: 20, y: 150)

                    Image(systemName: "carrot.fill")
                        .font(.system(size: 60))
                        .rotationEffect(.degrees(15))
                        .offset(x: geometry.size.width - 100, y: 200)

                    Image(systemName: "fork.knife")
                        .font(.system(size: 100))
                        .rotationEffect(.degrees(-10))
                        .offset(x: geometry.size.width - 150, y: geometry.size.height - 250)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .offset(x: 50, y: geometry.size.height - 300)
                }
                .foregroundStyle(.white.opacity(0.1))
            }

            VStack(spacing: 40) {
                Spacer()

                // Checkmark badge
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 160, height: 160)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 140, height: 140)

                    Image(systemName: "checkmark")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(.green)
                }

                // Title
                VStack(spacing: 12) {
                    Text("MEAL PLAN")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("COMPLETED")
                        .font(.system(size: 40, weight: .black))
                        .tracking(4)
                        .foregroundStyle(.white)
                }

                // Plan name
                Text(planName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.2))
                    )

                // Days completed
                VStack(spacing: 8) {
                    Text("\(daysCompleted)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("DAYS COMPLETED")
                        .font(.system(size: 20, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                ReppyBranding()
                    .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    MealPlanCompleteCardView(planName: "High Protein Plan", daysCompleted: 14)
        .frame(width: 390, height: 844)
}
