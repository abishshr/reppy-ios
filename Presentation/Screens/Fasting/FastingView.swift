import SwiftUI

struct FastingView: View {
    @StateObject private var viewModel = FastingViewModel()
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Active Fast or Start Button
                    if viewModel.isFasting {
                        ActiveFastCard(viewModel: viewModel)
                    } else {
                        StartFastCard(viewModel: viewModel)
                    }

                    // Stats Section
                    StatsSection(viewModel: viewModel)

                    // Quick Actions
                    QuickActionsSection(viewModel: viewModel, showHistory: $showHistory)

                    // Recent History Preview
                    if !viewModel.history.isEmpty {
                        RecentHistorySection(viewModel: viewModel, showHistory: $showHistory)
                    }
                }
                .padding()
            }
            .navigationTitle("Fasting")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showProtocolPicker) {
                ProtocolPickerSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showHistory) {
                FastingHistoryView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Active Fast Card

private struct ActiveFastCard: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Protocol badge
            if let fast = viewModel.activeFast {
                Text(fast.fastingProtocol.displayName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // Timer Circle
            FastingTimerView(
                progress: viewModel.progressPercentage / 100,
                elapsedTime: viewModel.formattedElapsed,
                remainingTime: viewModel.formattedRemaining
            )
            .frame(height: 250)

            // Progress percentage
            Text(viewModel.formattedProgress)
                .font(.title2.bold())
                .foregroundStyle(.green)

            // Stop buttons
            HStack(spacing: 16) {
                Button {
                    Task { await viewModel.stopFast(completed: false) }
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    Task { await viewModel.stopFast(completed: true) }
                } label: {
                    Label("Complete", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// MARK: - Start Fast Card

private struct StartFastCard: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)

            Text("Ready to Fast?")
                .font(.title2.bold())

            if viewModel.eatingWindowActive {
                Label("Eating window is open", systemImage: "fork.knife")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            Button {
                viewModel.showProtocolPicker = true
            } label: {
                Label("Start Fasting", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// MARK: - Stats Section

private struct StatsSection: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.headline)

            HStack(spacing: 16) {
                StatCard(
                    title: "Streak",
                    value: viewModel.currentStreakText,
                    unit: "days",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Completed",
                    value: viewModel.totalFastsText,
                    unit: "fasts",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatCard(
                    title: "Total",
                    value: viewModel.totalHoursText,
                    unit: "hours",
                    icon: "clock.fill",
                    color: .blue
                )
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title.bold())

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Actions

private struct QuickActionsSection: View {
    @ObservedObject var viewModel: FastingViewModel
    @Binding var showHistory: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                ActionButton(
                    title: "History",
                    icon: "clock.arrow.circlepath",
                    color: .blue
                ) {
                    showHistory = true
                }

                ActionButton(
                    title: "Settings",
                    icon: "gearshape",
                    color: .gray
                ) {
                    viewModel.showSettings = true
                }
            }
        }
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Recent History

private struct RecentHistorySection: View {
    @ObservedObject var viewModel: FastingViewModel
    @Binding var showHistory: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Fasts")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    showHistory = true
                }
                .font(.subheadline)
            }

            ForEach(viewModel.history.prefix(3)) { session in
                HistoryRow(session: session)
            }
        }
    }
}

private struct HistoryRow: View {
    let session: FastingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.fastingProtocol.displayName)
                    .font(.subheadline.weight(.medium))
                Text(session.startedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.formattedElapsed)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 4) {
                    Circle()
                        .fill(session.isCompleted ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(session.isCompleted ? "Completed" : "Cancelled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Protocol Picker Sheet

private struct ProtocolPickerSheet: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(FastingProtocol.allCases) { fastingProtocol in
                    Button {
                        viewModel.selectedProtocol = fastingProtocol
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: fastingProtocol.icon)
                                        .foregroundStyle(.orange)
                                    Text(fastingProtocol.displayName)
                                        .font(.headline)
                                }

                                Text(fastingProtocol.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Text("\(fastingProtocol.fastingHours)h fasting")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .clipShape(Capsule())

                                    Text(fastingProtocol.difficulty)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }

                            Spacer()

                            if viewModel.selectedProtocol == fastingProtocol {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }

                if viewModel.selectedProtocol == .custom {
                    Section("Custom Duration") {
                        Stepper(
                            "\(Int(viewModel.customDuration)) hours",
                            value: $viewModel.customDuration,
                            in: 1...168,
                            step: 1
                        )
                    }
                }
            }
            .navigationTitle("Choose Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        Task {
                            await viewModel.startFast()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    FastingView()
}
