import Foundation
import Combine

@MainActor
final class MealPlanViewModel: ObservableObject {
    @Published var activePlan: MealPlan?
    @Published var allPlans: [MealPlanSummary] = []
    @Published var groceryLists: [GroceryList] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedDay: MealPlanDay?

    private let repository: MealPlanRepository

    init(repository: MealPlanRepository? = nil) {
        self.repository = repository ?? MealPlanRepositoryImpl(
            apiClient: DependencyContainer.shared.apiClient
        )
    }

    func loadActivePlan() async {
        isLoading = true
        error = nil

        do {
            activePlan = try await repository.fetchActiveMealPlan()
            if let plan = activePlan, let firstDay = plan.days.first {
                selectedDay = firstDay
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadAllPlans() async {
        do {
            allPlans = try await repository.fetchMealPlans(activeOnly: false)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadPlan(id: String) async -> MealPlan? {
        isLoading = true
        defer { isLoading = false }
        do {
            let plan = try await repository.fetchMealPlan(id: id)
            return plan
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func loadGroceryLists() async {
        do {
            groceryLists = try await repository.fetchGroceryLists()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deletePlan(id: String) async {
        do {
            try await repository.deleteMealPlan(id: id)
            allPlans.removeAll { $0.id == id }
            if activePlan?.id == id {
                activePlan = nil
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deactivatePlan(id: String) async {
        do {
            try await repository.deactivateMealPlan(id: id)
            if activePlan?.id == id {
                activePlan = nil
            }
            await loadAllPlans()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleGroceryItem(listId: String, itemIndex: Int, checked: Bool) async {
        do {
            try await repository.toggleGroceryItem(listId: listId, itemIndex: itemIndex, checked: checked)
            // Update local state
            if let listIndex = groceryLists.firstIndex(where: { $0.id == listId }) {
                groceryLists[listIndex].items[itemIndex].checked = checked
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteGroceryList(id: String) async {
        do {
            try await repository.deleteGroceryList(id: id)
            groceryLists.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectDay(_ day: MealPlanDay) {
        selectedDay = day
    }

    var todaysMeals: [PlannedMeal] {
        selectedDay?.meals ?? []
    }

    var todaysCalories: Int {
        selectedDay?.totalCalories ?? 0
    }

    var todaysProtein: Double {
        selectedDay?.totalProtein ?? 0
    }

    var todaysCarbs: Double {
        selectedDay?.totalCarbs ?? 0
    }

    var todaysFat: Double {
        selectedDay?.totalFat ?? 0
    }
}
