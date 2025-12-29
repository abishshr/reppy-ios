import SwiftUI

/// Compact fasting card for dashboard display
struct FastingCard: View {
    @StateObject private var viewModel = FastingCardViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text("Fasting")
                    .font(.headline)
                Spacer()

                if viewModel.isFasting {
                    StatusPill(text: "Active", color: .green)
                }
            }

            if viewModel.isFasting, let session = viewModel.activeSession {
                // Active fast display
                ActiveFastContent(
                    session: session,
                    elapsedTime: viewModel.formattedElapsed,
                    remainingTime: viewModel.formattedRemaining,
                    progress: viewModel.progress
                )
            } else {
                // Not fasting display
                NotFastingContent(
                    streak: viewModel.streak,
                    eatingWindowActive: viewModel.eatingWindowActive,
                    onStartTap: { viewModel.showFastingView = true }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            await viewModel.loadData()
        }
        .fullScreenCover(isPresented: $viewModel.showFastingView) {
            FastingView()
        }
    }
}

// MARK: - Active Fast Content

private struct ActiveFastContent: View {
    let session: FastingSession
    let elapsedTime: String
    let remainingTime: String
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Mini progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.fastingProtocol.shortName)
                        .font(.subheadline.weight(.medium))

                    Text(elapsedTime)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("\(remainingTime) remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(String(format: "%.0f%%", progress * 100))
                    .font(.title.bold())
                    .foregroundStyle(.orange)
            }

            // Progress bar
            ProgressView(value: progress)
                .tint(.orange)
        }
    }
}

// MARK: - Not Fasting Content

private struct NotFastingContent: View {
    let streak: Int
    let eatingWindowActive: Bool
    let onStartTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if eatingWindowActive {
                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.green)
                        Text("Eating Window Open")
                            .font(.subheadline)
                    }
                } else {
                    Text("Not fasting")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(streak) day streak")
                            .font(.caption)
                    }
                }
            }

            Spacer()

            Button(action: onStartTap) {
                Text("Start Fast")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Status Pill

private struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - ViewModel

@MainActor
final class FastingCardViewModel: ObservableObject {
    @Published var isFasting = false
    @Published var activeSession: FastingSession?
    @Published var eatingWindowActive = false
    @Published var streak = 0
    @Published var showFastingView = false

    @Published var elapsedSeconds = 0
    @Published var remainingSeconds = 0

    private let container = DependencyContainer.shared
    private var timer: Timer?

    var progress: Double {
        guard let session = activeSession else { return 0 }
        let total = session.targetEndAt.timeIntervalSince(session.startedAt)
        let elapsed = Date().timeIntervalSince(session.startedAt)
        return min(elapsed / total, 1.0)
    }

    var formattedElapsed: String {
        formatDuration(seconds: elapsedSeconds)
    }

    var formattedRemaining: String {
        formatDuration(seconds: remainingSeconds)
    }

    func loadData() async {
        do {
            let response = try await container.apiClient.getActiveFast()
            isFasting = response.isFasting
            activeSession = response.session
            eatingWindowActive = response.eatingWindowActive

            if let session = response.session {
                elapsedSeconds = session.elapsedSeconds
                remainingSeconds = session.remainingSeconds
                startTimer()
            }

            // Get streak
            let stats = try await container.apiClient.getFastingStats()
            streak = stats.currentFastingStreak
        } catch {
            print("Error loading fasting data: \(error)")
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }

    private func updateTimer() {
        guard let session = activeSession else { return }
        let now = Date()
        elapsedSeconds = Int(now.timeIntervalSince(session.startedAt))
        remainingSeconds = max(0, Int(session.targetEndAt.timeIntervalSince(now)))
    }

    private func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    deinit {
        timer?.invalidate()
    }
}

#Preview {
    VStack {
        FastingCard()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
