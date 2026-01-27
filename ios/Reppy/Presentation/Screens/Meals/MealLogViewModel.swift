import SwiftUI

@MainActor
final class MealLogViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var allMeals: [Meal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Computed Properties

    var todayMeals: [Meal] {
        allMeals.filter { $0.loggedAt.isToday }
    }

    var todayCalories: Int {
        todayMeals.reduce(0) { $0 + ($1.calories ?? 0) }
    }

    var todayProtein: Double {
        todayMeals.reduce(0) { $0 + ($1.proteinG ?? 0) }
    }

    var todayCarbs: Double {
        todayMeals.reduce(0) { $0 + ($1.carbsG ?? 0) }
    }

    var todayFat: Double {
        todayMeals.reduce(0) { $0 + ($1.fatG ?? 0) }
    }

    var untypedMeals: [Meal] {
        todayMeals.filter { $0.mealType == nil }
    }

    // MARK: - Methods

    func meals(for type: MealType) -> [Meal] {
        todayMeals.filter { $0.mealType == type }
    }

    func loadMeals() async {
        print("[MealLogViewModel] loadMeals() called")
        isLoading = true

        do {
            let meals = try await container.mealRepository.fetchMeals(days: 7)
            print("[MealLogViewModel] Fetched \(meals.count) meals")
            for meal in meals {
                print("[MealLogViewModel] Meal: \(meal.items.map { $0.name }.joined(separator: ", ")) - \(meal.calories ?? 0) cal - logged at: \(meal.loggedAt)")
            }
            allMeals = meals
        } catch {
            print("[MealLogViewModel] Error fetching meals: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadMeals()
    }
}
