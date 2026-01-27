import Foundation

/// Protocol for workout repository
protocol WorkoutRepository {
    func fetchWorkouts(days: Int) async throws -> [Workout]
    func createWorkout(_ workout: WorkoutLogCreate) async throws -> Workout
    func getWeekSummary() async throws -> WorkoutSummary
}

/// Implementation of WorkoutRepository
final class WorkoutRepositoryImpl: WorkoutRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchWorkouts(days: Int) async throws -> [Workout] {
        try await apiClient.fetchWorkouts(days: days)
    }

    func createWorkout(_ workout: WorkoutLogCreate) async throws -> Workout {
        try await apiClient.createWorkout(workout)
    }

    func getWeekSummary() async throws -> WorkoutSummary {
        try await apiClient.getWeekWorkoutSummary()
    }
}
