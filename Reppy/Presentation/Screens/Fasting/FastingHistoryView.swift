import SwiftUI

struct FastingHistoryView: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.history.isEmpty {
                    EmptyHistoryView()
                } else {
                    HistoryList(viewModel: viewModel)
                }
            }
            .navigationTitle("Fasting History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if viewModel.history.isEmpty {
                    await viewModel.loadHistory(reset: true)
                }
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Fasting History")
                .font(.headline)

            Text("Complete your first fast to see it here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History List

private struct HistoryList: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        List {
            // Stats summary at top
            Section {
                StatsSummary(viewModel: viewModel)
            }

            // Grouped by date
            ForEach(groupedHistory.keys.sorted().reversed(), id: \.self) { date in
                Section(header: Text(formatSectionDate(date))) {
                    ForEach(groupedHistory[date] ?? []) { session in
                        HistoryDetailRow(session: session)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteFast(session)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            // Load more
            if viewModel.hasMoreHistory {
                Section {
                    Button {
                        Task { await viewModel.loadMoreHistory() }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Load More")
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedHistory: [Date: [FastingSession]] {
        Dictionary(grouping: viewModel.history) { session in
            Calendar.current.startOfDay(for: session.startedAt)
        }
    }

    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Stats Summary

private struct StatsSummary: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                SummaryStat(
                    value: "\(viewModel.stats?.totalFastsCompleted ?? 0)",
                    label: "Total Fasts",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                SummaryStat(
                    value: String(format: "%.0f", viewModel.stats?.totalHoursFasted ?? 0),
                    label: "Total Hours",
                    icon: "clock.fill",
                    color: .blue
                )

                SummaryStat(
                    value: String(format: "%.1f", viewModel.stats?.averageFastDurationHours ?? 0),
                    label: "Avg Duration",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }

            if let mostUsed = viewModel.stats?.mostUsedProtocol,
               let fastingProtocol = FastingProtocol(rawValue: mostUsed) {
                HStack {
                    Text("Most Used:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(fastingProtocol.displayName)
                        .font(.caption.weight(.medium))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct SummaryStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - History Detail Row

private struct HistoryDetailRow: View {
    let session: FastingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: session.fastingProtocol.icon)
                        .foregroundStyle(.orange)
                    Text(session.fastingProtocol.displayName)
                        .font(.headline)
                }

                Spacer()

                StatusBadge(isCompleted: session.isCompleted)
            }

            // Details
            HStack(spacing: 16) {
                DetailItem(
                    icon: "clock",
                    label: "Duration",
                    value: session.formattedElapsed
                )

                DetailItem(
                    icon: "calendar",
                    label: "Date",
                    value: formatDate(session.startedAt)
                )

                DetailItem(
                    icon: "sunrise",
                    label: "Started",
                    value: formatTime(session.startedAt)
                )
            }

            // Progress bar
            if session.isCompleted {
                ProgressView(value: 1.0)
                    .tint(.green)
            } else {
                ProgressView(value: session.progressPercentage / 100)
                    .tint(.orange)
            }

            // Notes if any
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct DetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.medium))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatusBadge: View {
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(isCompleted ? "Completed" : "Cancelled")
        }
        .font(.caption)
        .foregroundStyle(isCompleted ? .green : .red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isCompleted ? Color.green : Color.red).opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    FastingHistoryView(viewModel: FastingViewModel())
}
