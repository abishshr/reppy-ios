import SwiftUI

struct WorkoutCompleteCardView: View {
    let workoutName: String
    let exerciseCount: Int
    let duration: Int // in minutes

    private var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        ZStack {
            // Background gradient
            CardGradientBackground(colors: [
                Color(red: 0.4, green: 0.2, blue: 0.8),
                Color(red: 0.6, green: 0.1, blue: 0.7),
                Color(red: 0.8, green: 0.1, blue: 0.5)
            ])

            // Dumbbell decorations
            GeometryReader { geometry in
                Group {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 100))
                        .rotationEffect(.degrees(-30))
                        .offset(x: -30, y: 120)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .offset(x: geometry.size.width - 100, y: 180)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 60))
                        .offset(x: geometry.size.width - 80, y: geometry.size.height - 280)

                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .offset(x: 40, y: geometry.size.height - 320)
                }
                .foregroundStyle(.white.opacity(0.1))
            }

            VStack(spacing: 40) {
                Spacer()

                // Completed badge
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)
                }

                // Title
                VStack(spacing: 12) {
                    Text("WORKOUT")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("CRUSHED IT!")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(.white)
                }

                // Workout name
                Text(workoutName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Stats
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("\(exerciseCount)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("EXERCISES")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 60)

                    VStack(spacing: 8) {
                        Text(formattedDuration)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("DURATION")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                )

                Spacer()

                ReppyBranding()
                    .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    WorkoutCompleteCardView(workoutName: "Push Day", exerciseCount: 8, duration: 65)
        .frame(width: 390, height: 844)
}
