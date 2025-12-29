import SwiftUI

struct StreakView: View {
    @State private var data: WidgetData = WidgetDataManager.shared.load() ?? .placeholder

    private var streakMessage: String {
        switch data.currentStreak {
        case 0:
            return "Start your streak today!"
        case 1:
            return "Great start! Keep going!"
        case 2...6:
            return "Building momentum!"
        case 7...13:
            return "One week strong!"
        case 14...29:
            return "Two weeks! Amazing!"
        case 30...59:
            return "A whole month!"
        case 60...89:
            return "Two months! Incredible!"
        case 90...179:
            return "Three months! You're unstoppable!"
        case 180...364:
            return "Half a year! Legend!"
        default:
            return "Over a year! You're a master!"
        }
    }

    private var streakIcon: String {
        switch data.currentStreak {
        case 0:
            return "flame"
        case 1...6:
            return "flame.fill"
        case 7...29:
            return "flame.fill"
        case 30...89:
            return "flame.fill"
        default:
            return "flame.fill"
        }
    }

    private var flameColor: Color {
        switch data.currentStreak {
        case 0:
            return .gray
        case 1...6:
            return .orange
        case 7...29:
            return .orange
        case 30...89:
            return .red
        default:
            return .purple
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Streak Icon
                ZStack {
                    Circle()
                        .fill(flameColor.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: streakIcon)
                        .font(.system(size: 36))
                        .foregroundStyle(flameColor)
                        .symbolEffect(.pulse, options: .repeating, value: data.currentStreak > 0)
                }

                // Streak Count
                VStack(spacing: 4) {
                    Text("\(data.currentStreak)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(flameColor)

                    Text(data.currentStreak == 1 ? "Day" : "Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Streak Message
                Text(streakMessage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                // Milestone Progress (next milestone)
                if data.currentStreak > 0 {
                    let nextMilestone = getNextMilestone(data.currentStreak)
                    let progress = Double(data.currentStreak) / Double(nextMilestone)

                    VStack(spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(flameColor)
                                    .frame(width: geometry.size.width * progress)
                            }
                        }
                        .frame(height: 6)

                        Text("\(nextMilestone - data.currentStreak) days to \(nextMilestone)-day milestone")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Streak")
        .onAppear {
            data = WidgetDataManager.shared.load() ?? .placeholder
        }
    }

    private func getNextMilestone(_ current: Int) -> Int {
        let milestones = [7, 14, 30, 60, 90, 180, 365, 500, 1000]
        return milestones.first { $0 > current } ?? (current + 100)
    }
}

#Preview {
    StreakView()
}
