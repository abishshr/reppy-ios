import Foundation

/// Meal log entity
struct Meal: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    var loggedAt: Date
    var mealType: MealType?
    var items: [MealItem]
    var calories: Int?
    var proteinG: Double?
    var carbsG: Double?
    var fatG: Double?
    var sugarGEst: Double?
    var fiberGEst: Double?
    var sodiumMgEst: Double?
    var saturatedFatGEst: Double?
    var cholesterolMgEst: Double?
    var confidence: Double?
    var notes: String?
    var imageUrl: String?

    // Testosterone impact for male users (nil for female/other users)
    var testosteroneImpact: String?  // "boosting", "reducing", "mixed", "neutral"

    init(
        id: String = UUID().uuidString,
        userId: String,
        loggedAt: Date = Date(),
        mealType: MealType? = nil,
        items: [MealItem] = [],
        calories: Int? = nil,
        proteinG: Double? = nil,
        carbsG: Double? = nil,
        fatG: Double? = nil,
        sugarGEst: Double? = nil,
        fiberGEst: Double? = nil,
        sodiumMgEst: Double? = nil,
        saturatedFatGEst: Double? = nil,
        cholesterolMgEst: Double? = nil,
        confidence: Double? = nil,
        notes: String? = nil,
        imageUrl: String? = nil,
        testosteroneImpact: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.loggedAt = loggedAt
        self.mealType = mealType
        self.items = items
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.sugarGEst = sugarGEst
        self.fiberGEst = fiberGEst
        self.sodiumMgEst = sodiumMgEst
        self.saturatedFatGEst = saturatedFatGEst
        self.cholesterolMgEst = cholesterolMgEst
        self.confidence = confidence
        self.notes = notes
        self.imageUrl = imageUrl
        self.testosteroneImpact = testosteroneImpact
    }
}

/// Individual food item
struct MealItem: Codable, Equatable, Identifiable {
    var id: String { "\(name)-\(quantity ?? 0)-\(unit ?? "")" }
    let name: String
    let quantity: Double?
    let unit: String?
    let testosteroneImpact: String?  // "boosts", "reduces", "neutral"

    init(name: String, quantity: Double? = nil, unit: String? = nil, testosteroneImpact: String? = nil) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.testosteroneImpact = testosteroneImpact
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "carrot.fill"
        }
    }
}

/// AI-suggested meal before confirmation
struct MealSuggestion: Codable {
    let suggestionId: String
    let items: [MealItem]
    let estimatedCalories: Int
    let estimatedProteinG: Double
    let estimatedCarbsG: Double
    let estimatedFatG: Double
    let estimatedSugarG: Double?
    let estimatedFiberG: Double?
    let estimatedSodiumMg: Double?
    let estimatedSaturatedFatG: Double?
    let estimatedCholesterolMg: Double?
    let confidence: Double
    let notes: String?
    let clarifyingQuestions: [String]
}
