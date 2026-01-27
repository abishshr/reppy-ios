import SwiftUI

@MainActor
final class WorkoutLogViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Computed Properties

    var weekWorkoutCount: Int {
        workouts.count
    }

    var weekTotalMinutes: Int {
        workouts.reduce(0) { $0 + ($1.durationMin ?? 0) }
    }

    var weekTotalCalories: Int {
        workouts.reduce(0) { $0 + ($1.caloriesBurnedEst ?? 0) }
    }

    // MARK: - Methods

    func loadWorkouts() async {
        isLoading = true

        do {
            workouts = try await container.workoutRepository.fetchWorkouts(days: 7)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadWorkouts()
    }
}
