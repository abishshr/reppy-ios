import SwiftUI

@MainActor
final class ProfileTabViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSignOutConfirmation = false

    // Micronutrients
    @Published var todaySugar = 0.0
    @Published var sugarTarget = 25.0
    @Published var todayFiber = 0.0
    @Published var fiberTarget = 25.0
    @Published var todaySodium = 0.0
    @Published var sodiumTarget = 2300.0
    @Published var todaySaturatedFat = 0.0
    @Published var saturatedFatTarget = 20.0
    @Published var todayCholesterol = 0.0
    @Published var cholesterolTarget = 300.0

    // Weekly Stats
    @Published var weeklyAvgCalories = 0
    @Published var weeklyAvgProtein = 0.0
    @Published var weeklyWorkouts = 0
    @Published var currentStreak = 0

    // Health
    @Published var healthKitStatus = "Connected"

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        async let microTask: () = loadMicronutrients()
        async let weeklyTask: () = loadWeeklyStats()
        async let streakTask: () = loadStreak()

        _ = await (microTask, weeklyTask, streakTask)

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    private func loadMicronutrients() async {
        do {
            let meals = try await container.mealRepository.fetchMeals(days: 1)
            let today = meals.filter { $0.loggedAt.isToday }

            // Sum up micronutrients from all meals
            for meal in today {
                todaySugar += meal.sugarGEst ?? 0
                todayFiber += meal.fiberGEst ?? 0
                todaySodium += meal.sodiumMgEst ?? 0
                todaySaturatedFat += meal.saturatedFatGEst ?? 0
                todayCholesterol += meal.cholesterolMgEst ?? 0
            }
        } catch {
            // Use defaults
        }
    }

    private func loadWeeklyStats() async {
        do {
            let meals = try await container.mealRepository.fetchMeals(days: 7)
            let workouts = try await container.workoutRepository.fetchWorkouts(days: 7)

            // Calculate daily averages
            let totalCalories = meals.reduce(0) { $0 + ($1.calories ?? 0) }
            let totalProtein = meals.reduce(0.0) { $0 + ($1.proteinG ?? 0) }

            weeklyAvgCalories = totalCalories / 7
            weeklyAvgProtein = totalProtein / 7
            weeklyWorkouts = workouts.count
        } catch {
            // Use defaults
        }
    }

    private func loadStreak() async {
        do {
            let streak = try await container.apiClient.getStreak()
            currentStreak = streak.currentStreak
        } catch {
            currentStreak = 0
        }
    }

    // MARK: - Actions

    func syncSteps() async {
        // Sync steps from HealthKit
        // This would trigger the health kit sync
    }
}
