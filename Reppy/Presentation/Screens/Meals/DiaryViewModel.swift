import SwiftUI

@MainActor
final class DiaryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Water tracking
    @Published var todayWaterMl = 0
    @Published var waterGoalMl = 2500
    @Published var isAddingWater = false

    // Meals
    @Published var meals: [Meal] = []
    @Published var todayCalories = 0
    @Published var todayProtein = 0.0
    @Published var todayCarbs = 0.0
    @Published var todayFat = 0.0

    // Workouts
    @Published var workouts: [Workout] = []

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Workout Computed Properties

    var weekWorkoutCount: Int {
        workouts.count
    }

    var weekTotalMinutes: Int {
        workouts.reduce(0) { $0 + ($1.durationMin ?? 0) }
    }

    var weekTotalCalories: Int {
        workouts.reduce(0) { $0 + ($1.caloriesBurnedEst ?? 0) }
    }

    // MARK: - Computed Properties

    var untypedMeals: [Meal] {
        meals.filter { $0.mealType == nil }
    }

    func meals(for type: MealType) -> [Meal] {
        meals.filter { $0.mealType == type }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        async let waterTask: () = loadWater()
        async let mealsTask: () = loadMeals()
        async let profileTask: () = loadProfile()
        async let workoutsTask: () = loadWorkouts()

        _ = await (waterTask, mealsTask, profileTask, workoutsTask)

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    private func loadWater() async {
        do {
            let summary = try await container.apiClient.getTodayWater()
            todayWaterMl = summary.totalMl
            waterGoalMl = summary.goalMl
        } catch {
            // Water tracking might not be set up yet
        }
    }

    private func loadMeals() async {
        do {
            meals = try await container.mealRepository.fetchMeals(days: 1)

            // Calculate today's totals
            let today = meals.filter { $0.loggedAt.isToday }
            todayCalories = today.reduce(0) { $0 + ($1.calories ?? 0) }
            todayProtein = today.reduce(0) { $0 + ($1.proteinG ?? 0) }
            todayCarbs = today.reduce(0) { $0 + ($1.carbsG ?? 0) }
            todayFat = today.reduce(0) { $0 + ($1.fatG ?? 0) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProfile() async {
        do {
            let profile = try await container.profileRepository.fetchProfile()
            if let goal = profile.dailyWaterGoalMl {
                waterGoalMl = goal
            }
        } catch {
            // Use defaults
        }
    }

    private func loadWorkouts() async {
        do {
            workouts = try await container.workoutRepository.fetchWorkouts(days: 7)
        } catch {
            // Ignore workout loading errors
        }
    }

    // MARK: - Actions

    func addWater(amountMl: Int) async {
        isAddingWater = true
        do {
            _ = try await container.apiClient.logWater(amountMl: amountMl)
            todayWaterMl += amountMl
        } catch {
            errorMessage = error.localizedDescription
        }
        isAddingWater = false
    }

    func quickAddCalories(
        calories: Int,
        description: String,
        mealType: String,
        proteinG: Double?,
        carbsG: Double?,
        fatG: Double?,
        loggedAt: Date
    ) async throws {
        _ = try await container.apiClient.quickAddCalories(
            calories: calories,
            description: description,
            mealType: mealType,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            loggedAt: loggedAt
        )

        // Update local state
        todayCalories += calories
        if let protein = proteinG { todayProtein += protein }
        if let carbs = carbsG { todayCarbs += carbs }
        if let fat = fatG { todayFat += fat }

        // Notify other views
        NotificationCenter.default.post(name: .mealLogged, object: nil)
    }
}
