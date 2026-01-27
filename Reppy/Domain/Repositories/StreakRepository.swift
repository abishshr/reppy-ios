import Foundation
import Combine

/// Repository for streak operations
final class StreakRepository: ObservableObject {
    private let apiClient: APIClient

    @Published private(set) var streakInfo: StreakInfo?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var newMilestone: StreakMilestone?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    /// Fetch current streak information
    @MainActor
    func fetchStreak() async {
        isLoading = true
        error = nil

        do {
            streakInfo = try await apiClient.getStreak()
        } catch {
            self.error = error
            print("[StreakRepository] Error fetching streak: \(error)")
        }

        isLoading = false
    }

    /// Manually record activity and check for new milestones
    @MainActor
    func recordActivity() async -> StreakMilestone? {
        isLoading = true
        error = nil
        newMilestone = nil

        do {
            let response = try await apiClient.recordActivity()
            streakInfo = response.streak
            if let milestone = response.newMilestone {
                newMilestone = milestone
                return milestone
            }
        } catch {
            self.error = error
            print("[StreakRepository] Error recording activity: \(error)")
        }

        isLoading = false
        return nil
    }

    /// Clear the new milestone after showing celebration
    @MainActor
    func clearNewMilestone() {
        newMilestone = nil
    }
}
