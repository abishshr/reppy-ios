import Foundation

/// Protocol for food database repository
protocol FoodRepository {
    func searchFoods(query: String, limit: Int) async throws -> [CustomFood]
    func lookupBarcode(_ barcode: String) async throws -> BarcodeLookupResponse
    func getRecentFoods(limit: Int) async throws -> [CustomFood]
    func getFrequentFoods(limit: Int) async throws -> [CustomFood]
    func getMyFoods() async throws -> [CustomFood]
    func createFood(_ food: CustomFoodCreate) async throws -> CustomFood
    func deleteFood(id: String) async throws
    func recordFoodUsage(foodId: String) async throws
}

/// Implementation of FoodRepository
final class FoodRepositoryImpl: FoodRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func searchFoods(query: String, limit: Int = 20) async throws -> [CustomFood] {
        let response = try await apiClient.searchFoodsDatabase(query: query, limit: limit)
        return response.foods
    }

    func lookupBarcode(_ barcode: String) async throws -> BarcodeLookupResponse {
        try await apiClient.lookupBarcode(barcode)
    }

    func getRecentFoods(limit: Int = 20) async throws -> [CustomFood] {
        let response = try await apiClient.getRecentFoods(limit: limit)
        return response.foods
    }

    func getFrequentFoods(limit: Int = 20) async throws -> [CustomFood] {
        let response = try await apiClient.getFrequentFoods(limit: limit)
        return response.foods
    }

    func getMyFoods() async throws -> [CustomFood] {
        try await apiClient.getMyCustomFoods()
    }

    func createFood(_ food: CustomFoodCreate) async throws -> CustomFood {
        try await apiClient.createCustomFood(food)
    }

    func deleteFood(id: String) async throws {
        try await apiClient.deleteCustomFood(id: id)
    }

    func recordFoodUsage(foodId: String) async throws {
        try await apiClient.recordFoodUsage(foodId: foodId)
    }
}
