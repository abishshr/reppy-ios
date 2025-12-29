import Foundation

/// Protocol for meal repository
protocol MealRepository {
    func fetchMeals(days: Int) async throws -> [Meal]
    func createMeal(_ meal: MealLogCreate) async throws -> Meal
    func getTodaySummary() async throws -> MealSummary
}

/// Implementation of MealRepository
final class MealRepositoryImpl: MealRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchMeals(days: Int) async throws -> [Meal] {
        try await apiClient.fetchMeals(days: days)
    }

    func createMeal(_ meal: MealLogCreate) async throws -> Meal {
        try await apiClient.createMeal(meal)
    }

    func getTodaySummary() async throws -> MealSummary {
        try await apiClient.getTodayMealSummary()
    }
}
