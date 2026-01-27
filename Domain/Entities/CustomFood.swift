import Foundation

// MARK: - Health Rating

/// Overall health rating for a food product
enum FoodHealthRating: String, Codable {
    case excellent = "A"  // No harmful ingredients, whole food
    case good = "B"       // Minor concerns
    case okay = "C"       // Some processed ingredients
    case poor = "D"       // Contains harmful ingredients
    case bad = "F"        // Multiple harmful ingredients

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "lime"
        case .okay: return "yellow"
        case .poor: return "orange"
        case .bad: return "red"
        }
    }

    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .okay: return "Okay"
        case .poor: return "Poor"
        case .bad: return "Avoid"
        }
    }

    var emoji: String {
        switch self {
        case .excellent: return "✓"
        case .good: return "✓"
        case .okay: return "~"
        case .poor: return "✗"
        case .bad: return "✗✗"
        }
    }
}

/// Category of harmful ingredient
enum IngredientWarningCategory: String, Codable, CaseIterable {
    case seedOil = "seed_oil"
    case artificialSweetener = "artificial_sweetener"
    case preservative = "preservative"
    case additive = "additive"
    case highSugar = "high_sugar"
    case transFat = "trans_fat"
    case highSodium = "high_sodium"
    case artificial = "artificial"

    var displayName: String {
        switch self {
        case .seedOil: return "Seed Oil"
        case .artificialSweetener: return "Artificial Sweetener"
        case .preservative: return "Preservative"
        case .additive: return "Additive"
        case .highSugar: return "High Sugar"
        case .transFat: return "Trans Fat"
        case .highSodium: return "High Sodium"
        case .artificial: return "Artificial Ingredient"
        }
    }

    var icon: String {
        switch self {
        case .seedOil: return "drop.fill"
        case .artificialSweetener: return "cube.fill"
        case .preservative: return "clock.badge.exclamationmark"
        case .additive: return "plus.circle.fill"
        case .highSugar: return "cube.fill"
        case .transFat: return "exclamationmark.triangle.fill"
        case .highSodium: return "salt.fill"
        case .artificial: return "testtube.2"
        }
    }
}

/// A specific ingredient warning
struct IngredientWarning: Codable, Identifiable, Equatable {
    var id: String { ingredient }
    let ingredient: String
    let category: IngredientWarningCategory
    let severity: Int  // 1-3, 3 being worst
    let reason: String

    static func == (lhs: IngredientWarning, rhs: IngredientWarning) -> Bool {
        lhs.ingredient == rhs.ingredient
    }
}

/// Complete ingredient analysis for a food
struct IngredientAnalysis: Codable, Equatable {
    let rating: FoodHealthRating
    let score: Int  // 0-100
    let warnings: [IngredientWarning]
    let positives: [String]  // Good ingredients found
    let ingredientsList: [String]?  // Raw ingredients list

    var hasWarnings: Bool {
        !warnings.isEmpty
    }

    var topWarnings: [IngredientWarning] {
        Array(warnings.sorted { $0.severity > $1.severity }.prefix(3))
    }
}

// MARK: - Harmful Ingredients Database

/// Known harmful ingredients to flag
struct HarmfulIngredients {
    // Seed oils (inflammatory, high omega-6)
    static let seedOils = [
        "canola oil", "rapeseed oil", "soybean oil", "corn oil",
        "sunflower oil", "safflower oil", "cottonseed oil",
        "vegetable oil", "rice bran oil", "grapeseed oil"
    ]

    // Artificial sweeteners
    static let artificialSweeteners = [
        "aspartame", "sucralose", "saccharin", "acesulfame",
        "acesulfame potassium", "acesulfame k", "neotame",
        "advantame", "cyclamate"
    ]

    // MSG and related
    static let additives = [
        "monosodium glutamate", "msg", "glutamic acid",
        "hydrolyzed vegetable protein", "hydrolyzed protein",
        "autolyzed yeast", "yeast extract", "sodium caseinate",
        "calcium caseinate", "textured protein"
    ]

    // Preservatives
    static let preservatives = [
        "sodium nitrite", "sodium nitrate", "bha", "bht",
        "tbhq", "sodium benzoate", "potassium benzoate",
        "potassium sorbate", "sodium sulfite", "sulfur dioxide",
        "propyl gallate", "carrageenan"
    ]

    // Artificial colors
    static let artificialColors = [
        "red 40", "red 3", "yellow 5", "yellow 6",
        "blue 1", "blue 2", "green 3", "caramel color",
        "fd&c", "tartrazine", "sunset yellow", "allura red"
    ]

    // Trans fats
    static let transFats = [
        "partially hydrogenated", "hydrogenated oil",
        "shortening", "margarine"
    ]
}

// MARK: - Custom Food

/// User-created custom food item
struct CustomFood: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let brand: String?
    let servingSize: String?
    let servingSizeG: Double?
    let calories: Double?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let fiberG: Double?
    let sugarG: Double?
    let barcode: String?
    let source: String
    let isVerified: Bool
    let imageUrl: String?
    let createdAt: Date

    // Testosterone impact for male users (nil for female/other users)
    let testosteroneImpact: String?  // "boosts", "reduces", "neutral"

    // Ingredient analysis (from barcode lookup)
    let ingredients: String?  // Raw ingredients text
    let ingredientAnalysis: IngredientAnalysis?

    init(
        id: String,
        name: String,
        brand: String? = nil,
        servingSize: String? = nil,
        servingSizeG: Double? = nil,
        calories: Double? = nil,
        proteinG: Double? = nil,
        carbsG: Double? = nil,
        fatG: Double? = nil,
        fiberG: Double? = nil,
        sugarG: Double? = nil,
        barcode: String? = nil,
        source: String,
        isVerified: Bool,
        imageUrl: String? = nil,
        createdAt: Date,
        testosteroneImpact: String? = nil,
        ingredients: String? = nil,
        ingredientAnalysis: IngredientAnalysis? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.servingSizeG = servingSizeG
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.sugarG = sugarG
        self.barcode = barcode
        self.source = source
        self.isVerified = isVerified
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.testosteroneImpact = testosteroneImpact
        self.ingredients = ingredients
        self.ingredientAnalysis = ingredientAnalysis
    }

    var macroSummary: String {
        var parts: [String] = []
        if let protein = proteinG { parts.append("\(Int(protein))P") }
        if let carbs = carbsG { parts.append("\(Int(carbs))C") }
        if let fat = fatG { parts.append("\(Int(fat))F") }
        return parts.joined(separator: " / ")
    }

    var healthRating: FoodHealthRating? {
        ingredientAnalysis?.rating
    }

    var hasHealthConcerns: Bool {
        ingredientAnalysis?.hasWarnings ?? false
    }
}

/// Response wrapper for custom foods list
struct CustomFoodsResponse: Codable {
    let foods: [CustomFood]
}

/// Request to create a custom food
struct CustomFoodCreate: Codable {
    let name: String
    let brand: String?
    let servingSize: String
    let servingSizeG: Double?
    let calories: Double
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let fiberG: Double?
    let sugarG: Double?
    let barcode: String?

    init(
        name: String,
        brand: String? = nil,
        servingSize: String,
        servingSizeG: Double? = nil,
        calories: Double,
        proteinG: Double? = nil,
        carbsG: Double? = nil,
        fatG: Double? = nil,
        fiberG: Double? = nil,
        sugarG: Double? = nil,
        barcode: String? = nil
    ) {
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.servingSizeG = servingSizeG
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.sugarG = sugarG
        self.barcode = barcode
    }
}
