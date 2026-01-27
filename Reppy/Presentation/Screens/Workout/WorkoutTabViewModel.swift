import SwiftUI

// MARK: - Exercise Progression Models

enum ProgressionTrend: String, Codable {
    case up
    case down
    case steady
}

struct ExerciseProgression: Identifiable {
    let id = UUID()
    let exerciseName: String
    let lastWeight: String
    let change: String
    let trend: ProgressionTrend
}

// MARK: - ViewModel

@MainActor
final class WorkoutTabViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var isLoadingPRs = false
    @Published var errorMessage: String?

    // Today's Workout
    @Published var todaysWorkoutDay: WorkoutPlanDay?
    @Published var activeWorkoutPlanId: String?

    // Week View
    @Published var weekWorkouts: [WorkoutPlanDay] = []
    @Published var completedDaysThisWeek: Int = 0

    // Progression
    @Published var progressionData: [ExerciseProgression] = []

    // Personal Records
    @Published var recentPRs: [PersonalRecord] = []

    // Recent Workouts
    @Published var recentWorkouts: [Workout] = []

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Computed Properties

    var hasTodaysWorkout: Bool {
        todaysWorkoutDay != nil && !(todaysWorkoutDay?.isRestDay ?? true)
    }

    var weekWorkoutCount: Int {
        recentWorkouts.count
    }

    var weekTotalMinutes: Int {
        recentWorkouts.reduce(0) { $0 + ($1.durationMin ?? 0) }
    }

    var weekTotalCalories: Int {
        recentWorkouts.reduce(0) { $0 + ($1.caloriesBurnedEst ?? 0) }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        async let todayTask: () = loadTodaysWorkout()
        async let weekTask: () = loadWeekWorkouts()
        async let prsTask: () = loadRecentPRs()
        async let workoutsTask: () = loadRecentWorkouts()
        async let progressionTask: () = loadProgressionData()

        _ = await (todayTask, weekTask, prsTask, workoutsTask, progressionTask)

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    private func loadTodaysWorkout() async {
        do {
            // First get the active workout plan to get its ID
            if let plan = try await container.apiClient.fetchActiveWorkoutPlan() {
                activeWorkoutPlanId = plan.id
            }
            // Then get today's workout
            todaysWorkoutDay = try await container.apiClient.fetchTodaysWorkout()
        } catch {
            // No workout plan active
            todaysWorkoutDay = nil
            activeWorkoutPlanId = nil
        }
    }

    private func loadRecentPRs() async {
        isLoadingPRs = true
        do {
            recentPRs = try await container.apiClient.getRecentPRs(days: 7)
        } catch {
            // Ignore PR loading errors for now
            recentPRs = []
        }
        isLoadingPRs = false
    }

    private func loadRecentWorkouts() async {
        do {
            recentWorkouts = try await container.workoutRepository.fetchWorkouts(days: 7)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadWeekWorkouts() async {
        do {
            // Fetch active workout plan and get all days
            if let plan = try await container.apiClient.fetchActiveWorkoutPlan() {
                weekWorkouts = plan.days

                // Count completed days this week
                completedDaysThisWeek = plan.days.filter { $0.isCompleted }.count
            } else {
                weekWorkouts = []
                completedDaysThisWeek = 0
            }
        } catch {
            weekWorkouts = []
            completedDaysThisWeek = 0
        }
    }

    private func loadProgressionData() async {
        // Build progression data from recent workouts
        // Group exercises and find weight changes

        var progressions: [ExerciseProgression] = []

        // Group workouts by exercise name and find weight progression
        var exerciseWeights: [String: [(date: Date, weight: Double)]] = [:]

        for workout in recentWorkouts {
            for exercise in workout.exercises {
                let name = exercise.name.lowercased()
                if let weight = exercise.weightKg {
                    if exerciseWeights[name] == nil {
                        exerciseWeights[name] = []
                    }
                    exerciseWeights[name]?.append((workout.loggedAt, weight))
                }
            }
        }

        // Calculate progressions
        for (name, weights) in exerciseWeights where weights.count >= 2 {
            let sorted = weights.sorted { $0.date > $1.date }
            let latest = sorted[0].weight
            let previous = sorted[1].weight
            let change = latest - previous

            let trend: ProgressionTrend
            let changeText: String

            if abs(change) < 0.1 {
                trend = .steady
                changeText = "No change"
            } else if change > 0 {
                trend = .up
                changeText = "+\(String(format: "%.1f", change)) kg"
            } else {
                trend = .down
                changeText = "\(String(format: "%.1f", change)) kg"
            }

            progressions.append(ExerciseProgression(
                exerciseName: name.capitalized,
                lastWeight: "\(String(format: "%.1f", latest)) kg",
                change: changeText,
                trend: trend
            ))
        }

        // Sort by most recent improvement first
        progressionData = progressions.sorted { $0.trend == .up && $1.trend != .up }
    }

    // MARK: - Actions

    func completeTodaysWorkout() async {
        guard let planId = activeWorkoutPlanId,
              let dayId = todaysWorkoutDay?.id else { return }

        do {
            try await container.apiClient.completeWorkoutDay(planId: planId, dayId: dayId)
            // Reload today's workout to get updated completion status
            await loadTodaysWorkout()
            await loadRecentWorkouts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
