import SwiftUI

/// Card showing current cycle phase, day, and next period prediction
struct CycleStatusCard: View {
    let status: CycleStatus
    let onLogTap: () -> Void
    let onDetailsTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundColor(phaseColor)

                Text("Cycle Tracker")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: onDetailsTap) {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Phase indicator
            HStack(spacing: 16) {
                // Phase circle
                ZStack {
                    Circle()
                        .fill(phaseColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    VStack(spacing: 2) {
                        Text("Day")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(status.cycleDay)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(phaseColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: status.phaseEnum.icon)
                            .font(.subheadline)
                            .foregroundColor(phaseColor)

                        Text(status.phaseEnum.displayName)
                            .font(.headline)
                            .fontWeight(.medium)
                    }

                    Text(status.phaseEnum.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if status.phaseDaysRemaining > 0 {
                        Text("\(status.phaseDaysRemaining) days left in this phase")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Progress bar showing cycle progress
            CycleProgressBar(
                cycleDay: status.cycleDay,
                cycleLength: 28,  // Will be updated from settings
                currentPhase: status.phaseEnum
            )

            // Predictions row
            HStack(spacing: 16) {
                // Next period
                if status.nextPeriodDate != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Next Period", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let daysUntil = status.daysUntilPeriod, daysUntil > 0 {
                            Text("in \(daysUntil) days")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Text("Expected today")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                    }
                }

                Spacer()

                // Fertile window indicator
                if status.isFertileWindow {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Fertile Window")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                }
            }

            // Log button
            Button(action: onLogTap) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Today")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(phaseColor)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var phaseColor: Color {
        switch status.phaseEnum {
        case .menstruation: return .red
        case .follicular: return .orange
        case .ovulation: return .green
        case .luteal: return .purple
        case .unknown: return .gray
        }
    }
}

/// Progress bar showing cycle phases
struct CycleProgressBar: View {
    let cycleDay: Int
    let cycleLength: Int
    let currentPhase: CyclePhase

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Phase segments
                HStack(spacing: 2) {
                    // Menstruation (days 1-5)
                    phaseSegment(color: .red, width: segmentWidth(for: 5, in: geometry.size.width))

                    // Follicular (days 6-13)
                    phaseSegment(color: .orange, width: segmentWidth(for: 8, in: geometry.size.width))

                    // Ovulation (days 14-16)
                    phaseSegment(color: .green, width: segmentWidth(for: 3, in: geometry.size.width))

                    // Luteal (days 17-28)
                    phaseSegment(color: .purple, width: segmentWidth(for: 12, in: geometry.size.width))
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // Current day indicator
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: indicatorOffset(for: geometry.size.width))
            }
        }
        .frame(height: 12)
    }

    private func phaseSegment(color: Color, width: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width)
    }

    private func segmentWidth(for days: Int, in totalWidth: CGFloat) -> CGFloat {
        let adjustedWidth = totalWidth - 6 // Account for spacing
        return (CGFloat(days) / CGFloat(cycleLength)) * adjustedWidth
    }

    private func indicatorOffset(for totalWidth: CGFloat) -> CGFloat {
        let progress = CGFloat(cycleDay - 1) / CGFloat(cycleLength - 1)
        return progress * (totalWidth - 12)
    }
}

/// Compact version for dashboard
struct CycleStatusCardCompact: View {
    let status: CycleStatus
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Phase icon
                ZStack {
                    Circle()
                        .fill(phaseColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: status.phaseEnum.icon)
                        .font(.system(size: 18))
                        .foregroundColor(phaseColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.phaseEnum.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Day \(status.cycleDay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Next period
                if let daysUntil = status.daysUntilPeriod, daysUntil > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(daysUntil)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(phaseColor)

                        Text("days until period")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var phaseColor: Color {
        switch status.phaseEnum {
        case .menstruation: return .red
        case .follicular: return .orange
        case .ovulation: return .green
        case .luteal: return .purple
        case .unknown: return .gray
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CycleStatusCard(
            status: CycleStatus(
                currentPhase: "follicular",
                cycleDay: 8,
                daysUntilPeriod: 20,
                nextPeriodDate: Date().addingTimeInterval(86400 * 20),
                isFertileWindow: false,
                phaseDay: 3,
                phaseDaysRemaining: 5
            ),
            onLogTap: {},
            onDetailsTap: {}
        )

        CycleStatusCardCompact(
            status: CycleStatus(
                currentPhase: "ovulation",
                cycleDay: 14,
                daysUntilPeriod: 14,
                nextPeriodDate: Date().addingTimeInterval(86400 * 14),
                isFertileWindow: true,
                phaseDay: 1,
                phaseDaysRemaining: 3
            ),
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
