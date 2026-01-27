import SwiftUI

@MainActor
final class StatsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Micronutrients
    @Published var todaySugar = 0.0
    @Published var sugarTarget = 50.0
    @Published var todayFiber = 0.0
    @Published var fiberTarget = 28.0
    @Published var todaySodium = 0.0
    @Published var sodiumTarget = 2300.0
    @Published var todaySaturatedFat = 0.0
    @Published var saturatedFatTarget = 20.0
    @Published var todayCholesterol = 0.0
    @Published var cholesterolTarget = 300.0

    // Weekly stats
    @Published var weeklyAvgCalories = 0
    @Published var weeklyAvgProtein = 0.0
    @Published var weeklyWorkouts = 0
    @Published var currentStreak = 0

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        async let mealsTask: () = loadMeals()
        async let workoutsTask: () = loadWorkouts()
        async let streakTask: () = loadStreak()

        _ = await (mealsTask, workoutsTask, streakTask)

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    private func loadMeals() async {
        do {
            let meals = try await container.mealRepository.fetchMeals(days: 7)

            // Today's micronutrients
            let today = meals.filter { $0.loggedAt.isToday }
            todaySugar = today.reduce(0.0) { $0 + ($1.sugarGEst ?? 0) }
            todayFiber = today.reduce(0.0) { $0 + ($1.fiberGEst ?? 0) }
            todaySodium = today.reduce(0.0) { $0 + ($1.sodiumMgEst ?? 0) }
            todaySaturatedFat = today.reduce(0.0) { $0 + ($1.saturatedFatGEst ?? 0) }
            todayCholesterol = today.reduce(0.0) { $0 + ($1.cholesterolMgEst ?? 0) }

            // Weekly averages
            let totalCalories = meals.reduce(0) { $0 + ($1.calories ?? 0) }
            let totalProtein = meals.reduce(0.0) { $0 + ($1.proteinG ?? 0) }

            // Group by day to get accurate averages
            let dayCount = Set(meals.map { Calendar.current.startOfDay(for: $0.loggedAt) }).count
            if dayCount > 0 {
                weeklyAvgCalories = totalCalories / dayCount
                weeklyAvgProtein = totalProtein / Double(dayCount)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadWorkouts() async {
        do {
            let workouts = try await container.workoutRepository.fetchWorkouts(days: 7)
            weeklyWorkouts = workouts.count
        } catch {
            // Ignore workout loading errors
        }
    }

    private func loadStreak() async {
        do {
            let streakInfo = try await container.apiClient.getStreak()
            currentStreak = streakInfo.currentStreak
        } catch {
            // Ignore streak loading errors
        }
    }
}
