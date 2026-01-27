import Foundation

/// Service for calculating micronutrient targets based on Dietary Reference Intakes (DRI)
/// Uses NIH and FDA guidelines adjusted for age, sex, activity level, and diet style
final class MicronutrientCalculatorService {

    // MARK: - Singleton

    static let shared = MicronutrientCalculatorService()
    private init() {}

    // MARK: - Public Methods

    /// Calculate micronutrient targets from user profile
    func calculateTargets(from profile: UserProfile) -> MicronutrientTargets {
        let age = profile.age ?? 30
        let sex = profile.sex ?? .other
        let activityLevel = profile.activityLevel ?? .moderate
        let dietStyle = profile.dietStyle ?? .omnivore

        // Get base DRI values for age and sex
        var targets = baseDRI(age: age, sex: sex)

        // Apply activity level adjustments
        targets = applyActivityAdjustments(targets, level: activityLevel)

        // Apply diet style adjustments
        let (adjusted, adjustments) = applyDietAdjustments(targets, style: dietStyle)

        return MicronutrientTargets(
            vitaminA: adjusted.vitaminA,
            vitaminC: adjusted.vitaminC,
            vitaminD: adjusted.vitaminD,
            vitaminE: adjusted.vitaminE,
            vitaminK: adjusted.vitaminK,
            thiamin: adjusted.thiamin,
            riboflavin: adjusted.riboflavin,
            niacin: adjusted.niacin,
            vitaminB6: adjusted.vitaminB6,
            folate: adjusted.folate,
            vitaminB12: adjusted.vitaminB12,
            calcium: adjusted.calcium,
            iron: adjusted.iron,
            magnesium: adjusted.magnesium,
            phosphorus: adjusted.phosphorus,
            potassium: adjusted.potassium,
            zinc: adjusted.zinc,
            selenium: adjusted.selenium,
            copper: adjusted.copper,
            manganese: adjusted.manganese,
            iodine: adjusted.iodine,
            chromium: adjusted.chromium,
            omega3: adjusted.omega3,
            choline: adjusted.choline,
            source: "NIH Dietary Reference Intakes",
            adjustments: adjustments
        )
    }

    // MARK: - Base DRI Values

    /// Base DRI values by age group and sex (based on NIH RDA/AI values)
    private func baseDRI(age: Int, sex: Sex) -> DRIValues {
        // Age groups: 14-18, 19-30, 31-50, 51-70, 70+
        // Using RDA (Recommended Dietary Allowance) where available, AI (Adequate Intake) otherwise

        let isMale = sex == .male

        // Determine age group
        let ageGroup: AgeGroup
        switch age {
        case 0..<14:
            ageGroup = .child
        case 14..<19:
            ageGroup = .teen
        case 19..<31:
            ageGroup = .youngAdult
        case 31..<51:
            ageGroup = .adult
        case 51..<71:
            ageGroup = .middleAge
        default:
            ageGroup = .senior
        }

        return getDRIValues(ageGroup: ageGroup, isMale: isMale)
    }

    private func getDRIValues(ageGroup: AgeGroup, isMale: Bool) -> DRIValues {
        // NIH DRI Tables (RDA/AI values)
        // https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx

        switch (ageGroup, isMale) {
        // Males
        case (.child, true):
            return DRIValues(
                vitaminA: 600, vitaminC: 45, vitaminD: 15, vitaminE: 11, vitaminK: 60,
                thiamin: 0.9, riboflavin: 0.9, niacin: 12, vitaminB6: 1.0, folate: 300, vitaminB12: 1.8,
                calcium: 1300, iron: 8, magnesium: 240, phosphorus: 1250, potassium: 2500,
                zinc: 8, selenium: 40, copper: 700, manganese: 1.9, iodine: 120, chromium: 25,
                omega3: 1.2, choline: 375
            )
        case (.teen, true):
            return DRIValues(
                vitaminA: 900, vitaminC: 75, vitaminD: 15, vitaminE: 15, vitaminK: 75,
                thiamin: 1.2, riboflavin: 1.3, niacin: 16, vitaminB6: 1.3, folate: 400, vitaminB12: 2.4,
                calcium: 1300, iron: 11, magnesium: 410, phosphorus: 1250, potassium: 3000,
                zinc: 11, selenium: 55, copper: 890, manganese: 2.2, iodine: 150, chromium: 35,
                omega3: 1.6, choline: 550
            )
        case (.youngAdult, true), (.adult, true):
            return DRIValues(
                vitaminA: 900, vitaminC: 90, vitaminD: 15, vitaminE: 15, vitaminK: 120,
                thiamin: 1.2, riboflavin: 1.3, niacin: 16, vitaminB6: 1.3, folate: 400, vitaminB12: 2.4,
                calcium: 1000, iron: 8, magnesium: 420, phosphorus: 700, potassium: 3400,
                zinc: 11, selenium: 55, copper: 900, manganese: 2.3, iodine: 150, chromium: 35,
                omega3: 1.6, choline: 550
            )
        case (.middleAge, true):
            return DRIValues(
                vitaminA: 900, vitaminC: 90, vitaminD: 15, vitaminE: 15, vitaminK: 120,
                thiamin: 1.2, riboflavin: 1.3, niacin: 16, vitaminB6: 1.7, folate: 400, vitaminB12: 2.4,
                calcium: 1000, iron: 8, magnesium: 420, phosphorus: 700, potassium: 3400,
                zinc: 11, selenium: 55, copper: 900, manganese: 2.3, iodine: 150, chromium: 30,
                omega3: 1.6, choline: 550
            )
        case (.senior, true):
            return DRIValues(
                vitaminA: 900, vitaminC: 90, vitaminD: 20, vitaminE: 15, vitaminK: 120,
                thiamin: 1.2, riboflavin: 1.3, niacin: 16, vitaminB6: 1.7, folate: 400, vitaminB12: 2.4,
                calcium: 1200, iron: 8, magnesium: 420, phosphorus: 700, potassium: 3400,
                zinc: 11, selenium: 55, copper: 900, manganese: 2.3, iodine: 150, chromium: 30,
                omega3: 1.6, choline: 550
            )

        // Females
        case (.child, false):
            return DRIValues(
                vitaminA: 600, vitaminC: 45, vitaminD: 15, vitaminE: 11, vitaminK: 60,
                thiamin: 0.9, riboflavin: 0.9, niacin: 12, vitaminB6: 1.0, folate: 300, vitaminB12: 1.8,
                calcium: 1300, iron: 8, magnesium: 240, phosphorus: 1250, potassium: 2300,
                zinc: 8, selenium: 40, copper: 700, manganese: 1.6, iodine: 120, chromium: 21,
                omega3: 1.0, choline: 375
            )
        case (.teen, false):
            return DRIValues(
                vitaminA: 700, vitaminC: 65, vitaminD: 15, vitaminE: 15, vitaminK: 75,
                thiamin: 1.0, riboflavin: 1.0, niacin: 14, vitaminB6: 1.2, folate: 400, vitaminB12: 2.4,
                calcium: 1300, iron: 15, magnesium: 360, phosphorus: 1250, potassium: 2300,
                zinc: 9, selenium: 55, copper: 890, manganese: 1.6, iodine: 150, chromium: 24,
                omega3: 1.1, choline: 400
            )
        case (.youngAdult, false), (.adult, false):
            return DRIValues(
                vitaminA: 700, vitaminC: 75, vitaminD: 15, vitaminE: 15, vitaminK: 90,
                thiamin: 1.1, riboflavin: 1.1, niacin: 14, vitaminB6: 1.3, folate: 400, vitaminB12: 2.4,
                calcium: 1000, iron: 18, magnesium: 320, phosphorus: 700, potassium: 2600,
                zinc: 8, selenium: 55, copper: 900, manganese: 1.8, iodine: 150, chromium: 25,
                omega3: 1.1, choline: 425
            )
        case (.middleAge, false):
            return DRIValues(
                vitaminA: 700, vitaminC: 75, vitaminD: 15, vitaminE: 15, vitaminK: 90,
                thiamin: 1.1, riboflavin: 1.1, niacin: 14, vitaminB6: 1.5, folate: 400, vitaminB12: 2.4,
                calcium: 1000, iron: 18, magnesium: 320, phosphorus: 700, potassium: 2600,
                zinc: 8, selenium: 55, copper: 900, manganese: 1.8, iodine: 150, chromium: 20,
                omega3: 1.1, choline: 425
            )
        case (.senior, false):
            return DRIValues(
                vitaminA: 700, vitaminC: 75, vitaminD: 20, vitaminE: 15, vitaminK: 90,
                thiamin: 1.1, riboflavin: 1.1, niacin: 14, vitaminB6: 1.5, folate: 400, vitaminB12: 2.4,
                calcium: 1200, iron: 8, magnesium: 320, phosphorus: 700, potassium: 2600,
                zinc: 8, selenium: 55, copper: 900, manganese: 1.8, iodine: 150, chromium: 20,
                omega3: 1.1, choline: 425
            )
        }
    }

    // MARK: - Activity Adjustments

    /// Adjust targets based on activity level
    private func applyActivityAdjustments(_ base: DRIValues, level: ActivityLevel) -> DRIValues {
        let multiplier: Double
        switch level {
        case .sedentary:
            multiplier = 1.0
        case .light:
            multiplier = 1.05
        case .moderate:
            multiplier = 1.1
        case .active:
            multiplier = 1.15
        case .veryActive:
            multiplier = 1.2
        }

        // Higher activity = higher needs for B vitamins, magnesium, iron, potassium
        return DRIValues(
            vitaminA: base.vitaminA,
            vitaminC: base.vitaminC * multiplier,  // Antioxidant for exercise recovery
            vitaminD: base.vitaminD,
            vitaminE: base.vitaminE * multiplier,  // Antioxidant
            vitaminK: base.vitaminK,
            thiamin: base.thiamin * multiplier,    // Energy metabolism
            riboflavin: base.riboflavin * multiplier,
            niacin: base.niacin * multiplier,
            vitaminB6: base.vitaminB6 * multiplier,
            folate: base.folate,
            vitaminB12: base.vitaminB12,
            calcium: base.calcium,
            iron: base.iron * (multiplier > 1.1 ? 1.1 : multiplier),  // Cap iron increase
            magnesium: base.magnesium * multiplier,  // Muscle function
            phosphorus: base.phosphorus,
            potassium: base.potassium * multiplier,  // Electrolyte
            zinc: base.zinc * multiplier,
            selenium: base.selenium,
            copper: base.copper,
            manganese: base.manganese,
            iodine: base.iodine,
            chromium: base.chromium,
            omega3: base.omega3,
            choline: base.choline
        )
    }

    // MARK: - Diet Style Adjustments

    /// Adjust targets based on diet style and return adjustment notes
    private func applyDietAdjustments(_ base: DRIValues, style: DietStyle) -> (DRIValues, [String]) {
        var adjusted = base
        var adjustments: [String] = []

        switch style {
        case .vegan:
            // Vegans need more attention to B12, Iron, Zinc, Calcium, Omega-3
            adjusted.vitaminB12 *= 1.5  // B12 is only in animal products
            adjusted.iron *= 1.8        // Plant iron less bioavailable
            adjusted.zinc *= 1.5        // Phytates reduce absorption
            adjusted.calcium *= 1.1
            adjusted.omega3 *= 1.3      // ALA conversion is inefficient
            adjustments = [
                "B12 increased (plant foods lack B12)",
                "Iron increased (plant iron less bioavailable)",
                "Zinc increased (phytates reduce absorption)",
                "Consider B12, D3, and Omega-3 supplements"
            ]

        case .vegetarian:
            adjusted.vitaminB12 *= 1.2
            adjusted.iron *= 1.5
            adjusted.zinc *= 1.2
            adjusted.omega3 *= 1.2
            adjustments = [
                "Iron increased (plant sources less bioavailable)",
                "Consider B12 supplementation if not eating eggs/dairy"
            ]

        case .pescatarian:
            // Generally good for most nutrients, slightly higher omega-3
            adjusted.omega3 *= 1.1
            adjustments = [
                "Omega-3 well covered by fish intake"
            ]

        case .keto:
            // Low carb may affect fiber intake, electrolytes important
            adjusted.magnesium *= 1.3
            adjusted.potassium *= 1.2
            adjusted.thiamin *= 1.2
            adjustments = [
                "Magnesium increased (common deficiency on keto)",
                "Potassium increased (electrolyte balance)",
                "Ensure adequate fiber from low-carb vegetables"
            ]

        case .paleo:
            // Generally nutrient-dense, may need calcium without dairy
            adjusted.calcium *= 1.2
            adjustments = [
                "Calcium increased (no dairy)",
                "Focus on leafy greens and bone-in fish for calcium"
            ]

        case .mediterranean:
            // Well-balanced, high in omega-3 and antioxidants
            adjustments = [
                "Mediterranean diet naturally high in most micronutrients",
                "Continue emphasis on olive oil, fish, and vegetables"
            ]

        case .omnivore:
            adjustments = [
                "Standard DRI recommendations",
                "Balanced diet from all food groups"
            ]
        }

        return (adjusted, adjustments)
    }
}

// MARK: - Supporting Types

private enum AgeGroup {
    case child      // <14
    case teen       // 14-18
    case youngAdult // 19-30
    case adult      // 31-50
    case middleAge  // 51-70
    case senior     // 70+
}

private struct DRIValues {
    var vitaminA: Double
    var vitaminC: Double
    var vitaminD: Double
    var vitaminE: Double
    var vitaminK: Double
    var thiamin: Double
    var riboflavin: Double
    var niacin: Double
    var vitaminB6: Double
    var folate: Double
    var vitaminB12: Double
    var calcium: Double
    var iron: Double
    var magnesium: Double
    var phosphorus: Double
    var potassium: Double
    var zinc: Double
    var selenium: Double
    var copper: Double
    var manganese: Double
    var iodine: Double
    var chromium: Double
    var omega3: Double
    var choline: Double
}
