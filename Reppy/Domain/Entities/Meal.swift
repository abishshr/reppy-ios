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

    // Vitamin estimates
    var vitaminAMcgEst: Double?
    var vitaminCMgEst: Double?
    var vitaminDMcgEst: Double?
    var vitaminEMgEst: Double?
    var vitaminKMcgEst: Double?
    var vitaminB1MgEst: Double?  // Thiamin
    var vitaminB2MgEst: Double?  // Riboflavin
    var vitaminB3MgEst: Double?  // Niacin
    var vitaminB6MgEst: Double?
    var vitaminB9McgEst: Double?  // Folate
    var vitaminB12McgEst: Double?

    // Mineral estimates
    var calciumMgEst: Double?
    var ironMgEst: Double?
    var magnesiumMgEst: Double?
    var phosphorusMgEst: Double?
    var potassiumMgEst: Double?
    var zincMgEst: Double?
    var seleniumMcgEst: Double?
    var copperMcgEst: Double?
    var manganeseMgEst: Double?

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
        vitaminAMcgEst: Double? = nil,
        vitaminCMgEst: Double? = nil,
        vitaminDMcgEst: Double? = nil,
        vitaminEMgEst: Double? = nil,
        vitaminKMcgEst: Double? = nil,
        vitaminB1MgEst: Double? = nil,
        vitaminB2MgEst: Double? = nil,
        vitaminB3MgEst: Double? = nil,
        vitaminB6MgEst: Double? = nil,
        vitaminB9McgEst: Double? = nil,
        vitaminB12McgEst: Double? = nil,
        calciumMgEst: Double? = nil,
        ironMgEst: Double? = nil,
        magnesiumMgEst: Double? = nil,
        phosphorusMgEst: Double? = nil,
        potassiumMgEst: Double? = nil,
        zincMgEst: Double? = nil,
        seleniumMcgEst: Double? = nil,
        copperMcgEst: Double? = nil,
        manganeseMgEst: Double? = nil,
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
        self.vitaminAMcgEst = vitaminAMcgEst
        self.vitaminCMgEst = vitaminCMgEst
        self.vitaminDMcgEst = vitaminDMcgEst
        self.vitaminEMgEst = vitaminEMgEst
        self.vitaminKMcgEst = vitaminKMcgEst
        self.vitaminB1MgEst = vitaminB1MgEst
        self.vitaminB2MgEst = vitaminB2MgEst
        self.vitaminB3MgEst = vitaminB3MgEst
        self.vitaminB6MgEst = vitaminB6MgEst
        self.vitaminB9McgEst = vitaminB9McgEst
        self.vitaminB12McgEst = vitaminB12McgEst
        self.calciumMgEst = calciumMgEst
        self.ironMgEst = ironMgEst
        self.magnesiumMgEst = magnesiumMgEst
        self.phosphorusMgEst = phosphorusMgEst
        self.potassiumMgEst = potassiumMgEst
        self.zincMgEst = zincMgEst
        self.seleniumMcgEst = seleniumMcgEst
        self.copperMcgEst = copperMcgEst
        self.manganeseMgEst = manganeseMgEst
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

    // Vitamin estimates
    let estimatedVitaminAMcg: Double?
    let estimatedVitaminCMg: Double?
    let estimatedVitaminDMcg: Double?
    let estimatedVitaminEMg: Double?
    let estimatedVitaminKMcg: Double?
    let estimatedVitaminB1Mg: Double?
    let estimatedVitaminB2Mg: Double?
    let estimatedVitaminB3Mg: Double?
    let estimatedVitaminB6Mg: Double?
    let estimatedVitaminB9Mcg: Double?
    let estimatedVitaminB12Mcg: Double?

    // Mineral estimates
    let estimatedCalciumMg: Double?
    let estimatedIronMg: Double?
    let estimatedMagnesiumMg: Double?
    let estimatedPhosphorusMg: Double?
    let estimatedPotassiumMg: Double?
    let estimatedZincMg: Double?
    let estimatedSeleniumMcg: Double?
    let estimatedCopperMcg: Double?
    let estimatedManganeseMg: Double?

    let confidence: Double
    let notes: String?
    let clarifyingQuestions: [String]
}
