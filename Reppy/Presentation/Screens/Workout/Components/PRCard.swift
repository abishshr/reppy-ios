import SwiftUI

/// Card displaying a personal record
struct PRCard: View {
    let pr: PersonalRecord
    let isNew: Bool

    init(pr: PersonalRecord, isNew: Bool = false) {
        self.pr = pr
        self.isNew = isNew
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(pr.exerciseName.capitalized)
                        .font(.headline)
                        .fontWeight(.bold)

                    if let date = pr.maxWeightDate {
                        Text(date.shortDateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isNew {
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .cornerRadius(4)
                }
            }

            // Stats Grid
            HStack(spacing: 16) {
                // Weight PR
                if let weight = pr.maxWeightKg {
                    PRStatColumn(
                        icon: "scalemass.fill",
                        value: String(format: "%.1f", weight),
                        unit: "kg",
                        label: "Max Weight",
                        color: .blue
                    )
                }

                // Reps at max weight
                if let reps = pr.maxWeightReps {
                    PRStatColumn(
                        icon: "repeat",
                        value: "\(reps)",
                        unit: "reps",
                        label: "at Max",
                        color: .green
                    )
                }

                // Volume PR
                if let volume = pr.maxVolumeKg {
                    PRStatColumn(
                        icon: "chart.bar.fill",
                        value: String(format: "%.0f", volume),
                        unit: "kg",
                        label: "Volume",
                        color: .orange
                    )
                }

                // Max Reps
                if let maxReps = pr.maxReps {
                    PRStatColumn(
                        icon: "arrow.up.circle.fill",
                        value: "\(maxReps)",
                        unit: "reps",
                        label: "Max Reps",
                        color: .purple
                    )
                }
            }

            // Last Performed
            if let lastPerformed = pr.lastPerformed {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Last: \(lastPerformed.shortDateString)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let lastWeight = pr.lastWeightKg, let lastReps = pr.lastReps {
                        Text(" - \(String(format: "%.1f", lastWeight))kg x \(lastReps)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(pr.timesPerformed)x performed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isNew ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}

struct PRStatColumn: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            HStack(spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Compact PR Card (for lists)

struct CompactPRCard: View {
    let pr: PersonalRecord

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.yellow.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exerciseName.capitalized)
                    .fontWeight(.medium)

                if let weight = pr.maxWeightKg {
                    Text("\(String(format: "%.1f", weight)) kg")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            if let date = pr.maxWeightDate {
                Text(date.shortDateString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PRCard(
            pr: PersonalRecord(
                id: "1",
                exerciseName: "barbell bench press",
                maxWeightKg: 100,
                maxWeightReps: 5,
                maxWeightDate: Date(),
                maxVolumeKg: 1500,
                maxVolumeDate: Date(),
                maxReps: 12,
                maxRepsWeightKg: 60,
                maxRepsDate: Date().addingTimeInterval(-86400 * 7),
                timesPerformed: 42,
                lastPerformed: Date().addingTimeInterval(-86400 * 2),
                lastWeightKg: 95,
                lastReps: 6,
                lastSets: 3
            ),
            isNew: true
        )
        .padding()

        CompactPRCard(
            pr: PersonalRecord(
                id: "2",
                exerciseName: "barbell squat",
                maxWeightKg: 120,
                maxWeightReps: 5,
                maxWeightDate: Date(),
                maxVolumeKg: nil,
                maxVolumeDate: nil,
                maxReps: nil,
                maxRepsWeightKg: nil,
                maxRepsDate: nil,
                timesPerformed: 30,
                lastPerformed: Date(),
                lastWeightKg: 115,
                lastReps: 5,
                lastSets: 5
            )
        )
        .padding(.horizontal)
    }
    .background(Color(.systemGroupedBackground))
}
