import SwiftUI

struct StreakMilestoneCardView: View {
    let days: Int
    let milestone: StreakMilestone

    var body: some View {
        ZStack {
            // Background gradient
            CardGradientBackground(colors: [
                Color(red: 1.0, green: 0.4, blue: 0.2),
                Color(red: 1.0, green: 0.2, blue: 0.3),
                Color(red: 0.8, green: 0.1, blue: 0.4)
            ])

            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -50)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 400, height: 400)
                    .offset(x: geometry.size.width - 200, y: -200)
            }

            VStack(spacing: 40) {
                Spacer()

                // Emoji
                Text(milestone.emoji)
                    .font(.system(size: 120))

                // Fire icon with glow
                ZStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 150))
                        .foregroundStyle(.white.opacity(0.3))
                        .blur(radius: 20)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }

                // Day count
                VStack(spacing: 8) {
                    Text("\(days)")
                        .font(.system(size: 140, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("DAY STREAK")
                        .font(.system(size: 32, weight: .bold))
                        .tracking(8)
                        .foregroundStyle(.white.opacity(0.9))
                }

                // Milestone badge
                Text(milestone.displayName.uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .tracking(4)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )

                Spacer()

                ReppyBranding()
                    .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    StreakMilestoneCardView(days: 30, milestone: .month)
        .frame(width: 390, height: 844)
}
