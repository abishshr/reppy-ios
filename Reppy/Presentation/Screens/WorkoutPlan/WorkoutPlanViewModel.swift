import Foundation
import Combine

@MainActor
final class WorkoutPlanViewModel: ObservableObject {
    @Published var activePlan: WorkoutPlan?
    @Published var allPlans: [WorkoutPlanSummary] = []
    @Published var todaysWorkout: WorkoutPlanDay?
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedWeek: Int = 1
    @Published var completingWorkout = false
    @Published var showCompletionSuccess = false

    private let repository: WorkoutPlanRepository

    init(repository: WorkoutPlanRepository? = nil) {
        self.repository = repository ?? WorkoutPlanRepositoryImpl(
            apiClient: DependencyContainer.shared.apiClient
        )
    }

    // MARK: - Loading Methods

    func loadActivePlan() async {
        isLoading = true
        error = nil

        do {
            activePlan = try await repository.fetchActiveWorkoutPlan()
            if let plan = activePlan {
                selectedWeek = plan.currentWeek
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadTodaysWorkout() async {
        do {
            todaysWorkout = try await repository.fetchTodaysWorkout()
        } catch {
            // Not an error if no workout today
            todaysWorkout = nil
        }
    }

    func loadAllPlans() async {
        do {
            allPlans = try await repository.fetchWorkoutPlans(activeOnly: false)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadAll() async {
        isLoading = true
        await loadActivePlan()
        await loadTodaysWorkout()
        isLoading = false
    }

    // MARK: - Actions

    func completeWorkout(planId: String, dayId: String) async {
        completingWorkout = true

        do {
            try await repository.completeWorkoutDay(planId: planId, dayId: dayId)
            showCompletionSuccess = true

            // Refresh data
            await loadActivePlan()
            await loadTodaysWorkout()
        } catch {
            self.error = error.localizedDescription
        }

        completingWorkout = false
    }

    func deletePlan(id: String) async {
        do {
            try await repository.deleteWorkoutPlan(id: id)
            allPlans.removeAll { $0.id == id }
            if activePlan?.id == id {
                activePlan = nil
                todaysWorkout = nil
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deactivatePlan(id: String) async {
        do {
            try await repository.deactivateWorkoutPlan(id: id)
            if activePlan?.id == id {
                activePlan = nil
                todaysWorkout = nil
            }
            await loadAllPlans()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectWeek(_ week: Int) {
        selectedWeek = week
    }

    // MARK: - Computed Properties

    var currentWeekDays: [WorkoutPlanDay] {
        activePlan?.days.filter { $0.weekNumber == selectedWeek }
            .sorted { $0.dayNumber < $1.dayNumber } ?? []
    }

    var weeksArray: [Int] {
        guard let plan = activePlan else { return [] }
        return Array(1...plan.durationWeeks)
    }

    var progressText: String {
        guard let plan = activePlan else { return "" }
        return "\(plan.completedWorkouts)/\(plan.totalWorkouts) workouts"
    }

    var progressPercent: Double {
        activePlan?.progressPercent ?? 0
    }

    var hasActivePlan: Bool {
        activePlan != nil
    }
}
