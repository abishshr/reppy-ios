import Foundation

/// Supplement entity representing a vitamin/mineral supplement
struct Supplement: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    var name: String
    var brand: String?
    var servingSize: String?  // e.g., "1 tablet"
    var notes: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    // Vitamins
    var vitaminAMcg: Double?
    var vitaminCMg: Double?
    var vitaminDMcg: Double?
    var vitaminEMg: Double?
    var vitaminKMcg: Double?
    var vitaminB1Mg: Double?  // Thiamin
    var vitaminB2Mg: Double?  // Riboflavin
    var vitaminB3Mg: Double?  // Niacin
    var vitaminB6Mg: Double?
    var vitaminB9Mcg: Double?  // Folate
    var vitaminB12Mcg: Double?

    // Minerals
    var calciumMg: Double?
    var ironMg: Double?
    var magnesiumMg: Double?
    var phosphorusMg: Double?
    var potassiumMg: Double?
    var zincMg: Double?
    var seleniumMcg: Double?
    var copperMcg: Double?
    var manganeseMg: Double?
    var iodineMcg: Double?

    // Other
    var omega3Mg: Double?
    var biotinMcg: Double?
    var cholineMg: Double?

    /// Display name with brand if available
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) - \(name)"
        }
        return name
    }

    /// Check if this supplement has any vitamin content
    var hasVitamins: Bool {
        vitaminAMcg != nil || vitaminCMg != nil || vitaminDMcg != nil ||
        vitaminEMg != nil || vitaminKMcg != nil || vitaminB1Mg != nil ||
        vitaminB2Mg != nil || vitaminB3Mg != nil || vitaminB6Mg != nil ||
        vitaminB9Mcg != nil || vitaminB12Mcg != nil
    }

    /// Check if this supplement has any mineral content
    var hasMinerals: Bool {
        calciumMg != nil || ironMg != nil || magnesiumMg != nil ||
        phosphorusMg != nil || potassiumMg != nil || zincMg != nil ||
        seleniumMcg != nil || copperMcg != nil || manganeseMg != nil || iodineMcg != nil
    }

    /// Summary of key nutrients in supplement
    var nutrientSummary: String {
        var parts: [String] = []

        if let d = vitaminDMcg, d > 0 { parts.append("Vit D") }
        if let c = vitaminCMg, c > 0 { parts.append("Vit C") }
        if let b12 = vitaminB12Mcg, b12 > 0 { parts.append("B12") }
        if let calcium = calciumMg, calcium > 0 { parts.append("Calcium") }
        if let iron = ironMg, iron > 0 { parts.append("Iron") }
        if let omega = omega3Mg, omega > 0 { parts.append("Omega-3") }

        if parts.isEmpty {
            return "No nutrients specified"
        } else if parts.count <= 3 {
            return parts.joined(separator: ", ")
        } else {
            return "\(parts.prefix(3).joined(separator: ", ")), +\(parts.count - 3) more"
        }
    }
}

/// Log entry for when a supplement is taken
struct SupplementLog: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let supplementId: String
    var supplementName: String
    var servings: Double
    var loggedAt: Date
    var notes: String?
    let createdAt: Date

    // Calculated totals (servings * supplement nutrients)
    var totalVitaminDMcg: Double?
    var totalVitaminCMg: Double?
    var totalCalciumMg: Double?
    var totalIronMg: Double?
}

/// Summary of supplements taken today
struct TodaySupplementSummary: Codable {
    let totalLogs: Int
    let supplementsTaken: [String]

    // Totals from all supplements today
    let totalVitaminAMcg: Double
    let totalVitaminCMg: Double
    let totalVitaminDMcg: Double
    let totalVitaminEMg: Double
    let totalVitaminKMcg: Double
    let totalVitaminB1Mg: Double
    let totalVitaminB2Mg: Double
    let totalVitaminB3Mg: Double
    let totalVitaminB6Mg: Double
    let totalVitaminB9Mcg: Double
    let totalVitaminB12Mcg: Double
    let totalCalciumMg: Double
    let totalIronMg: Double
    let totalMagnesiumMg: Double
    let totalPhosphorusMg: Double
    let totalPotassiumMg: Double
    let totalZincMg: Double
    let totalSeleniumMcg: Double
    let totalCopperMcg: Double
    let totalManganeseMg: Double

    /// Check if any supplements were taken today
    var hasData: Bool {
        totalLogs > 0
    }
}

/// Request to create a new supplement
struct SupplementCreateRequest: Codable {
    let name: String
    let brand: String?
    let servingSize: String?
    let notes: String?

    // Vitamins
    let vitaminAMcg: Double?
    let vitaminCMg: Double?
    let vitaminDMcg: Double?
    let vitaminEMg: Double?
    let vitaminKMcg: Double?
    let vitaminB1Mg: Double?
    let vitaminB2Mg: Double?
    let vitaminB3Mg: Double?
    let vitaminB6Mg: Double?
    let vitaminB9Mcg: Double?
    let vitaminB12Mcg: Double?

    // Minerals
    let calciumMg: Double?
    let ironMg: Double?
    let magnesiumMg: Double?
    let phosphorusMg: Double?
    let potassiumMg: Double?
    let zincMg: Double?
    let seleniumMcg: Double?
    let copperMcg: Double?
    let manganeseMg: Double?
    let iodineMcg: Double?

    // Other
    let omega3Mg: Double?
    let biotinMcg: Double?
    let cholineMg: Double?
}

/// Request to log supplement intake
struct SupplementLogRequest: Codable {
    let supplementId: String
    let servings: Double
    let loggedAt: Date?
    let notes: String?
}

/// Request to update a supplement
struct SupplementUpdateRequest: Codable {
    var name: String?
    var brand: String?
    var servingSize: String?
    var notes: String?
    var isActive: Bool?

    // Vitamins
    var vitaminAMcg: Double?
    var vitaminCMg: Double?
    var vitaminDMcg: Double?
    var vitaminEMg: Double?
    var vitaminKMcg: Double?
    var vitaminB1Mg: Double?
    var vitaminB2Mg: Double?
    var vitaminB3Mg: Double?
    var vitaminB6Mg: Double?
    var vitaminB9Mcg: Double?
    var vitaminB12Mcg: Double?

    // Minerals
    var calciumMg: Double?
    var ironMg: Double?
    var magnesiumMg: Double?
    var phosphorusMg: Double?
    var potassiumMg: Double?
    var zincMg: Double?
    var seleniumMcg: Double?
    var copperMcg: Double?
    var manganeseMg: Double?
    var iodineMcg: Double?

    // Other
    var omega3Mg: Double?
    var biotinMcg: Double?
    var cholineMg: Double?
}
