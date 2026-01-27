import Foundation
import Combine

@MainActor
final class FastingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Active fast state
    @Published var activeFast: FastingSession?
    @Published var isFasting = false
    @Published var eatingWindowActive = false

    // Stats
    @Published var stats: FastingStats?

    // History
    @Published var history: [FastingSession] = []
    @Published var hasMoreHistory = false
    private var currentPage = 1

    // Settings
    @Published var settings: FastingSettings?

    // Timer
    @Published var elapsedSeconds: Int = 0
    @Published var remainingSeconds: Int = 0
    @Published var progressPercentage: Double = 0

    // UI State
    @Published var showProtocolPicker = false
    @Published var showSettings = false
    @Published var selectedProtocol: FastingProtocol = .if16_8
    @Published var customDuration: Double = 16

    // MARK: - Private Properties

    private let container = DependencyContainer.shared
    private var timerCancellable: AnyCancellable?

    // MARK: - Initialization

    init() {
        startTimer()
    }

    deinit {
        timerCancellable?.cancel()
    }

    // MARK: - Timer

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimerValues()
            }
    }

    private func updateTimerValues() {
        guard let fast = activeFast, fast.isActive else { return }

        let now = Date()
        let started = fast.startedAt
        let targetEnd = fast.targetEndAt

        let totalSeconds = targetEnd.timeIntervalSince(started)
        let elapsed = now.timeIntervalSince(started)
        let remaining = max(0, targetEnd.timeIntervalSince(now))

        elapsedSeconds = Int(elapsed)
        remainingSeconds = Int(remaining)
        progressPercentage = min(100, (elapsed / totalSeconds) * 100)

        // Check if fast completed
        if remaining <= 0 && isFasting {
            // Auto-complete the fast
            Task {
                await stopFast(completed: true)
            }
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        errorMessage = nil

        async let activeTask: () = loadActiveFast()
        async let statsTask: () = loadStats()
        async let historyTask: () = loadHistory(reset: true)

        _ = await (activeTask, statsTask, historyTask)

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    private func loadActiveFast() async {
        do {
            let response = try await container.apiClient.getActiveFast()
            isFasting = response.isFasting
            activeFast = response.session
            eatingWindowActive = response.eatingWindowActive

            if let fast = response.session {
                elapsedSeconds = fast.elapsedSeconds
                remainingSeconds = fast.remainingSeconds
                progressPercentage = fast.progressPercentage
            }
        } catch {
            print("Error loading active fast: \(error)")
        }
    }

    private func loadStats() async {
        do {
            stats = try await container.apiClient.getFastingStats()
        } catch {
            print("Error loading fasting stats: \(error)")
        }
    }

    func loadHistory(reset: Bool = false) async {
        if reset {
            currentPage = 1
            history = []
        }

        do {
            let response = try await container.apiClient.getFastingHistory(page: currentPage, pageSize: 20)
            if reset {
                history = response.items
            } else {
                history.append(contentsOf: response.items)
            }
            hasMoreHistory = response.hasMore
        } catch {
            print("Error loading fasting history: \(error)")
        }
    }

    func loadMoreHistory() async {
        guard hasMoreHistory else { return }
        currentPage += 1
        await loadHistory(reset: false)
    }

    func loadSettings() async {
        do {
            settings = try await container.apiClient.getFastingSettings()
            if let preferred = settings?.preferredProtocol,
               let fastingProtocol = FastingProtocol(rawValue: preferred) {
                selectedProtocol = fastingProtocol
            }
        } catch {
            print("Error loading fasting settings: \(error)")
        }
    }

    // MARK: - Actions

    func startFast() async {
        isLoading = true
        errorMessage = nil

        do {
            let duration: Double? = selectedProtocol == .custom ? customDuration : nil
            let session = try await container.apiClient.startFast(
                protocol: selectedProtocol,
                durationHours: duration
            )

            activeFast = session
            isFasting = true
            elapsedSeconds = session.elapsedSeconds
            remainingSeconds = session.remainingSeconds
            progressPercentage = session.progressPercentage

            showProtocolPicker = false

            // Reload stats
            await loadStats()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func stopFast(completed: Bool) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await container.apiClient.stopFast(completed: completed)

            activeFast = nil
            isFasting = false
            elapsedSeconds = 0
            remainingSeconds = 0
            progressPercentage = 0

            // Reload data
            await loadStats()
            await loadHistory(reset: true)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteFast(_ session: FastingSession) async {
        do {
            try await container.apiClient.deleteFastingSession(id: session.id)
            history.removeAll { $0.id == session.id }
            await loadStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSettings(_ update: UpdateFastingSettingsRequest) async {
        do {
            settings = try await container.apiClient.updateFastingSettings(update)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    var formattedElapsed: String {
        formatDuration(seconds: elapsedSeconds)
    }

    var formattedRemaining: String {
        formatDuration(seconds: remainingSeconds)
    }

    var formattedProgress: String {
        String(format: "%.1f%%", progressPercentage)
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

    var currentStreakText: String {
        guard let streak = stats?.currentFastingStreak else { return "0" }
        return "\(streak)"
    }

    var totalFastsText: String {
        guard let total = stats?.totalFastsCompleted else { return "0" }
        return "\(total)"
    }

    var totalHoursText: String {
        guard let hours = stats?.totalHoursFasted else { return "0" }
        return String(format: "%.0f", hours)
    }
}
