import Foundation

/// Protocol for meal plan repository
protocol MealPlanRepository {
    func fetchMealPlans(activeOnly: Bool) async throws -> [MealPlanSummary]
    func fetchActiveMealPlan() async throws -> MealPlan?
    func fetchTodaysMeals() async throws -> MealPlanDay?
    func fetchMealPlan(id: String) async throws -> MealPlan
    func deleteMealPlan(id: String) async throws
    func deactivateMealPlan(id: String) async throws

    // Recipe
    func getRecipe(mealName: String, mealType: String) async throws -> MealRecipe

    // Grocery lists
    func fetchGroceryLists() async throws -> [GroceryList]
    func fetchGroceryList(id: String) async throws -> GroceryList
    func toggleGroceryItem(listId: String, itemIndex: Int, checked: Bool) async throws
    func deleteGroceryList(id: String) async throws
}

/// Implementation of MealPlanRepository
final class MealPlanRepositoryImpl: MealPlanRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchMealPlans(activeOnly: Bool) async throws -> [MealPlanSummary] {
        try await apiClient.fetchMealPlans(activeOnly: activeOnly)
    }

    func fetchActiveMealPlan() async throws -> MealPlan? {
        try await apiClient.fetchActiveMealPlan()
    }

    func fetchTodaysMeals() async throws -> MealPlanDay? {
        try await apiClient.fetchTodaysMeals()
    }

    func fetchMealPlan(id: String) async throws -> MealPlan {
        try await apiClient.fetchMealPlan(id: id)
    }

    func deleteMealPlan(id: String) async throws {
        try await apiClient.deleteMealPlan(id: id)
    }

    func deactivateMealPlan(id: String) async throws {
        try await apiClient.deactivateMealPlan(id: id)
    }

    func getRecipe(mealName: String, mealType: String) async throws -> MealRecipe {
        try await apiClient.getRecipe(mealName: mealName, mealType: mealType)
    }

    func fetchGroceryLists() async throws -> [GroceryList] {
        try await apiClient.fetchGroceryLists()
    }

    func fetchGroceryList(id: String) async throws -> GroceryList {
        try await apiClient.fetchGroceryList(id: id)
    }

    func toggleGroceryItem(listId: String, itemIndex: Int, checked: Bool) async throws {
        try await apiClient.toggleGroceryItem(listId: listId, itemIndex: itemIndex, checked: checked)
    }

    func deleteGroceryList(id: String) async throws {
        try await apiClient.deleteGroceryList(id: id)
    }
}
