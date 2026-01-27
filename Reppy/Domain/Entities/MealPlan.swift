import Foundation

/// Meal plan entity
struct MealPlan: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let startDate: Date
    let endDate: Date
    let goal: String?
    let dailyCalorieTarget: Int?
    let dailyProteinTarget: Double?
    let dailyCarbsTarget: Double?
    let dailyFatTarget: Double?
    let preferences: [String: AnyCodable]?
    let isActive: Bool
    let createdAt: Date
    var days: [MealPlanDay]

    var dayCount: Int {
        days.count
    }
}

/// A single day in a meal plan
struct MealPlanDay: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let dayNumber: Int
    let meals: [PlannedMeal]
    let totalCalories: Int?
    let totalProtein: Double?
    let totalCarbs: Double?
    let totalFat: Double?
    let notes: String?
}

/// A planned meal within a day
struct PlannedMeal: Codable, Equatable, Identifiable {
    var id: String { "\(type)-\(name)" }
    let type: String  // breakfast, lunch, dinner, snack
    let name: String
    let description: String?
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double

    // Micronutrients
    let sugarG: Double?
    let fiberG: Double?
    let sodiumMg: Double?
    let saturatedFatG: Double?
    let cholesterolMg: Double?

    // Recipe data (pre-fetched during plan creation)
    let ingredients: [RecipeIngredient]?
    let instructions: [String]?
    let prepTimeMin: Int?
    let cookTimeMin: Int?
    let difficulty: String?
    let tips: [String]?
    let nutritionNotes: String?

    // Image enrichment (Spoonacular or Unsplash)
    let imageUrl: String?
    let imageSource: String?  // "unsplash" or "spoonacular"
    let imagePhotographer: String?  // Unsplash photographer attribution
    let readyInMinutes: Int?
    let servings: Int?

    /// Whether this meal has a pre-fetched recipe
    var hasRecipe: Bool {
        ingredients != nil && !ingredients!.isEmpty && instructions != nil && !instructions!.isEmpty
    }

    /// Total cooking time (prep + cook)
    var totalTimeMin: Int? {
        if let prep = prepTimeMin, let cook = cookTimeMin {
            return prep + cook
        }
        return prepTimeMin ?? cookTimeMin ?? readyInMinutes
    }

    var mealType: MealType? {
        MealType(rawValue: type)
    }

    var hasImage: Bool {
        imageUrl != nil
    }

    /// Whether the image is from Unsplash (high quality restaurant-style)
    var isUnsplashImage: Bool {
        imageSource == "unsplash"
    }

    var typeIcon: String {
        switch type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "carrot.fill"
        default: return "fork.knife"
        }
    }

    var typeColor: String {
        switch type.lowercased() {
        case "breakfast": return "orange"
        case "lunch": return "yellow"
        case "dinner": return "purple"
        case "snack": return "green"
        default: return "blue"
        }
    }
}

/// Recipe response from AI generation
struct MealRecipe: Codable, Equatable {
    let name: String
    let description: String
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let servings: Int
    let difficulty: String
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let tips: [String]
    let nutritionNotes: String
    let imageUrl: String?
}

struct RecipeIngredient: Codable, Equatable, Identifiable {
    var id: String { item }
    let item: String
    let amount: String
    let notes: String?
}


/// Summary of a meal plan (for list view)
struct MealPlanSummary: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let startDate: Date
    let endDate: Date
    let goal: String?
    let isActive: Bool
    let dayCount: Int
}

/// Grocery list entity
struct GroceryList: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let mealPlanId: String?
    var items: [GroceryItem]
    let createdAt: Date

    var checkedCount: Int {
        items.filter { $0.checked }.count
    }

    var totalCount: Int {
        items.count
    }
}

/// Individual grocery item
struct GroceryItem: Codable, Equatable, Identifiable {
    var id: String { "\(name)-\(category)" }
    let name: String
    let quantity: Double
    let unit: String
    let category: GroceryCategory
    var checked: Bool
}

enum GroceryCategory: String, Codable, CaseIterable {
    case produce
    case protein
    case dairy
    case grains
    case pantry
    case frozen
    case other

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .protein: return "fish.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .grains: return "takeoutbag.and.cup.and.straw.fill"
        case .pantry: return "cabinet.fill"
        case .frozen: return "snowflake"
        case .other: return "cart.fill"
        }
    }
}
