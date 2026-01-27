import Foundation

/// Protocol for workout plan repository
protocol WorkoutPlanRepository {
    func fetchWorkoutPlans(activeOnly: Bool) async throws -> [WorkoutPlanSummary]
    func fetchActiveWorkoutPlan() async throws -> WorkoutPlan?
    func fetchWorkoutPlan(id: String) async throws -> WorkoutPlan
    func fetchTodaysWorkout() async throws -> WorkoutPlanDay?
    func fetchWeekWorkouts(planId: String, weekNumber: Int) async throws -> [WorkoutPlanDay]
    func completeWorkoutDay(planId: String, dayId: String) async throws
    func deleteWorkoutPlan(id: String) async throws
    func deactivateWorkoutPlan(id: String) async throws
}

/// Implementation of WorkoutPlanRepository
final class WorkoutPlanRepositoryImpl: WorkoutPlanRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchWorkoutPlans(activeOnly: Bool) async throws -> [WorkoutPlanSummary] {
        try await apiClient.fetchWorkoutPlans(activeOnly: activeOnly)
    }

    func fetchActiveWorkoutPlan() async throws -> WorkoutPlan? {
        try await apiClient.fetchActiveWorkoutPlan()
    }

    func fetchWorkoutPlan(id: String) async throws -> WorkoutPlan {
        try await apiClient.fetchWorkoutPlan(id: id)
    }

    func fetchTodaysWorkout() async throws -> WorkoutPlanDay? {
        try await apiClient.fetchTodaysWorkout()
    }

    func fetchWeekWorkouts(planId: String, weekNumber: Int) async throws -> [WorkoutPlanDay] {
        try await apiClient.fetchWeekWorkouts(planId: planId, weekNumber: weekNumber)
    }

    func completeWorkoutDay(planId: String, dayId: String) async throws {
        try await apiClient.completeWorkoutDay(planId: planId, dayId: dayId)
    }

    func deleteWorkoutPlan(id: String) async throws {
        try await apiClient.deleteWorkoutPlan(id: id)
    }

    func deactivateWorkoutPlan(id: String) async throws {
        try await apiClient.deactivateWorkoutPlan(id: id)
    }
}
