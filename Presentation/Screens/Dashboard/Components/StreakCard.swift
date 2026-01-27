import SwiftUI

/// Streak tracking card for the dashboard
struct StreakCard: View {
    let streakInfo: StreakInfo?
    let isLoading: Bool
    let onTap: () -> Void

    private var currentStreak: Int {
        streakInfo?.currentStreak ?? 0
    }

    private var longestStreak: Int {
        streakInfo?.longestStreak ?? 0
    }

    private var isActiveToday: Bool {
        streakInfo?.isActiveToday ?? false
    }

    private var streakAtRisk: Bool {
        streakInfo?.streakAtRisk ?? false
    }

    private var statusColor: Color {
        guard let info = streakInfo else { return .gray }
        switch info.statusColor {
        case .success: return .green
        case .warning: return .orange
        case .info: return .blue
        case .neutral: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Streak")
                        .font(.headline)
                }

                Spacer()

                Button(action: onTap) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if isLoading && streakInfo == nil {
                // Loading state
                HStack {
                    ProgressView()
                    Text("Loading streak...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Main content
                HStack(spacing: 20) {
                    // Streak flame with number
                    ZStack {
                        Circle()
                            .fill(
                                isActiveToday
                                    ? Color.orange.opacity(0.15)
                                    : streakAtRisk
                                        ? Color.orange.opacity(0.1)
                                        : Color.gray.opacity(0.1)
                            )
                            .frame(width: 70, height: 70)

                        VStack(spacing: 0) {
                            if currentStreak > 0 {
                                Image(systemName: "flame.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        isActiveToday ? .orange : streakAtRisk ? .orange.opacity(0.7) : .gray
                                    )
                                    .symbolEffect(.pulse, options: .repeating, value: streakAtRisk)

                                Text("\(currentStreak)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(isActiveToday ? .orange : .primary)
                            } else {
                                Image(systemName: "flame")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                                Text("0")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Stats
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(currentStreak == 1 ? "1 day" : "\(currentStreak) days")
                                .font(.title2.bold())

                            if currentStreak > 0 && currentStreak == longestStreak {
                                Text("(Best!)")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .fontWeight(.semibold)
                            }
                        }

                        // Status text
                        Text(streakInfo?.statusText ?? "Start your streak today!")
                            .font(.caption)
                            .foregroundStyle(statusColor)

                        // Next milestone
                        if let nextMilestone = streakInfo?.nextMilestone,
                           let daysRemaining = streakInfo?.daysToNextMilestone {
                            HStack(spacing: 4) {
                                Text(nextMilestone.emoji)
                                    .font(.caption)
                                Text("\(nextMilestone.displayName) in \(daysRemaining) days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()
                }

                // Milestone badges row (if any achieved)
                if let achieved = streakInfo?.achievedMilestones, !achieved.isEmpty {
                    Divider()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(achieved, id: \.self) { milestone in
                                MilestoneBadge(milestone: milestone)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

/// Small badge for achieved milestones
struct MilestoneBadge: View {
    let milestone: StreakMilestone

    var body: some View {
        HStack(spacing: 4) {
            Text(milestone.emoji)
                .font(.caption)
            Text(milestone.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .foregroundStyle(.orange)
        .clipShape(Capsule())
    }
}

/// Full-screen celebration overlay for new milestones
struct MilestoneCelebrationView: View {
    let milestone: StreakMilestone
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        onDismiss()
                    }
                }

            // Content
            VStack(spacing: 24) {
                // Emoji with animation
                Text(milestone.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)

                VStack(spacing: 8) {
                    Text("Milestone Achieved!")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(milestone.displayName)
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)

                Text(milestone.celebrationMessage)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 20)

                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 48)
                .padding(.top, 8)
                .opacity(showContent ? 1.0 : 0.0)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

#Preview("Active Streak") {
    let info = StreakInfo(
        currentStreak: 7,
        longestStreak: 7,
        lastActivityDate: Date(),
        isActiveToday: true,
        streakAtRisk: false,
        hoursUntilBreak: 35,
        nextMilestone: .twoWeeks,
        daysToNextMilestone: 7,
        achievedMilestones: [.firstDay, .week]
    )

    StreakCard(streakInfo: info, isLoading: false, onTap: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("At Risk") {
    let info = StreakInfo(
        currentStreak: 5,
        longestStreak: 10,
        lastActivityDate: Date().addingTimeInterval(-36 * 3600),
        isActiveToday: false,
        streakAtRisk: true,
        hoursUntilBreak: 8,
        nextMilestone: .week,
        daysToNextMilestone: 2,
        achievedMilestones: [.firstDay]
    )

    StreakCard(streakInfo: info, isLoading: false, onTap: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("New User") {
    let info = StreakInfo(
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: nil,
        isActiveToday: false,
        streakAtRisk: false,
        hoursUntilBreak: nil,
        nextMilestone: .firstDay,
        daysToNextMilestone: 1,
        achievedMilestones: []
    )

    StreakCard(streakInfo: info, isLoading: false, onTap: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Celebration") {
    MilestoneCelebrationView(milestone: .week, onDismiss: {})
}
