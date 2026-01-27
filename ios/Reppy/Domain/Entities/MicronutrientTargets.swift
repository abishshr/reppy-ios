import Foundation

/// Micronutrient daily targets based on Dietary Reference Intakes (DRI)
/// Calculated from age, sex, activity level, and diet style
struct MicronutrientTargets: Codable, Equatable {
    // MARK: - Vitamins

    /// Vitamin A (mcg RAE - Retinol Activity Equivalents)
    let vitaminA: Double
    /// Vitamin C (mg)
    let vitaminC: Double
    /// Vitamin D (mcg)
    let vitaminD: Double
    /// Vitamin E (mg alpha-tocopherol)
    let vitaminE: Double
    /// Vitamin K (mcg)
    let vitaminK: Double
    /// Thiamin B1 (mg)
    let thiamin: Double
    /// Riboflavin B2 (mg)
    let riboflavin: Double
    /// Niacin B3 (mg NE)
    let niacin: Double
    /// Vitamin B6 (mg)
    let vitaminB6: Double
    /// Folate B9 (mcg DFE)
    let folate: Double
    /// Vitamin B12 (mcg)
    let vitaminB12: Double

    // MARK: - Minerals

    /// Calcium (mg)
    let calcium: Double
    /// Iron (mg)
    let iron: Double
    /// Magnesium (mg)
    let magnesium: Double
    /// Phosphorus (mg)
    let phosphorus: Double
    /// Potassium (mg)
    let potassium: Double
    /// Zinc (mg)
    let zinc: Double
    /// Selenium (mcg)
    let selenium: Double
    /// Copper (mcg)
    let copper: Double
    /// Manganese (mg)
    let manganese: Double
    /// Iodine (mcg)
    let iodine: Double
    /// Chromium (mcg)
    let chromium: Double

    // MARK: - Additional Nutrients

    /// Omega-3 (g) - ALA
    let omega3: Double
    /// Choline (mg)
    let choline: Double

    // MARK: - Metadata

    /// The source of these recommendations
    let source: String
    /// Any diet-specific adjustments applied
    let adjustments: [String]
}

// MARK: - Micronutrient Info

struct MicronutrientInfo: Identifiable {
    let id = UUID()
    let name: String
    let target: Double
    let unit: String
    let category: MicronutrientCategory
    let description: String
    let foodSources: [String]

    var formattedTarget: String {
        if target >= 1000 {
            return String(format: "%.0f", target)
        } else if target >= 100 {
            return String(format: "%.0f", target)
        } else if target >= 10 {
            return String(format: "%.1f", target)
        } else {
            return String(format: "%.1f", target)
        }
    }
}

enum MicronutrientCategory: String, CaseIterable {
    case vitamin = "Vitamins"
    case mineral = "Minerals"
    case other = "Other Nutrients"
}

// MARK: - MicronutrientTargets Extension

extension MicronutrientTargets {
    /// Get all micronutrients as displayable info
    var allNutrients: [MicronutrientInfo] {
        [
            // Vitamins
            MicronutrientInfo(
                name: "Vitamin A",
                target: vitaminA,
                unit: "mcg",
                category: .vitamin,
                description: "Essential for vision, immune function, and skin health",
                foodSources: ["Sweet potatoes", "Carrots", "Spinach", "Eggs"]
            ),
            MicronutrientInfo(
                name: "Vitamin C",
                target: vitaminC,
                unit: "mg",
                category: .vitamin,
                description: "Antioxidant, supports immune system and collagen synthesis",
                foodSources: ["Oranges", "Bell peppers", "Strawberries", "Broccoli"]
            ),
            MicronutrientInfo(
                name: "Vitamin D",
                target: vitaminD,
                unit: "mcg",
                category: .vitamin,
                description: "Supports bone health, immune function, and muscle strength",
                foodSources: ["Fatty fish", "Fortified milk", "Eggs", "Sunlight exposure"]
            ),
            MicronutrientInfo(
                name: "Vitamin E",
                target: vitaminE,
                unit: "mg",
                category: .vitamin,
                description: "Antioxidant, protects cells from damage",
                foodSources: ["Almonds", "Sunflower seeds", "Spinach", "Avocado"]
            ),
            MicronutrientInfo(
                name: "Vitamin K",
                target: vitaminK,
                unit: "mcg",
                category: .vitamin,
                description: "Essential for blood clotting and bone health",
                foodSources: ["Kale", "Spinach", "Broccoli", "Brussels sprouts"]
            ),
            MicronutrientInfo(
                name: "Thiamin (B1)",
                target: thiamin,
                unit: "mg",
                category: .vitamin,
                description: "Helps convert food into energy",
                foodSources: ["Whole grains", "Pork", "Legumes", "Nuts"]
            ),
            MicronutrientInfo(
                name: "Riboflavin (B2)",
                target: riboflavin,
                unit: "mg",
                category: .vitamin,
                description: "Energy production and cell function",
                foodSources: ["Dairy", "Eggs", "Lean meats", "Green vegetables"]
            ),
            MicronutrientInfo(
                name: "Niacin (B3)",
                target: niacin,
                unit: "mg",
                category: .vitamin,
                description: "Energy metabolism and DNA repair",
                foodSources: ["Chicken", "Tuna", "Turkey", "Peanuts"]
            ),
            MicronutrientInfo(
                name: "Vitamin B6",
                target: vitaminB6,
                unit: "mg",
                category: .vitamin,
                description: "Protein metabolism and brain development",
                foodSources: ["Chicken", "Fish", "Potatoes", "Bananas"]
            ),
            MicronutrientInfo(
                name: "Folate (B9)",
                target: folate,
                unit: "mcg",
                category: .vitamin,
                description: "Cell division and DNA synthesis",
                foodSources: ["Leafy greens", "Legumes", "Fortified cereals", "Asparagus"]
            ),
            MicronutrientInfo(
                name: "Vitamin B12",
                target: vitaminB12,
                unit: "mcg",
                category: .vitamin,
                description: "Nerve function and red blood cell formation",
                foodSources: ["Meat", "Fish", "Dairy", "Fortified foods"]
            ),

            // Minerals
            MicronutrientInfo(
                name: "Calcium",
                target: calcium,
                unit: "mg",
                category: .mineral,
                description: "Strong bones and teeth, muscle function",
                foodSources: ["Dairy", "Fortified plant milk", "Leafy greens", "Tofu"]
            ),
            MicronutrientInfo(
                name: "Iron",
                target: iron,
                unit: "mg",
                category: .mineral,
                description: "Oxygen transport in blood, energy production",
                foodSources: ["Red meat", "Spinach", "Lentils", "Fortified cereals"]
            ),
            MicronutrientInfo(
                name: "Magnesium",
                target: magnesium,
                unit: "mg",
                category: .mineral,
                description: "Muscle and nerve function, energy production",
                foodSources: ["Nuts", "Seeds", "Whole grains", "Dark chocolate"]
            ),
            MicronutrientInfo(
                name: "Phosphorus",
                target: phosphorus,
                unit: "mg",
                category: .mineral,
                description: "Bone health and energy storage",
                foodSources: ["Dairy", "Meat", "Fish", "Nuts"]
            ),
            MicronutrientInfo(
                name: "Potassium",
                target: potassium,
                unit: "mg",
                category: .mineral,
                description: "Blood pressure regulation, muscle contractions",
                foodSources: ["Bananas", "Potatoes", "Beans", "Yogurt"]
            ),
            MicronutrientInfo(
                name: "Zinc",
                target: zinc,
                unit: "mg",
                category: .mineral,
                description: "Immune function and wound healing",
                foodSources: ["Oysters", "Beef", "Pumpkin seeds", "Chickpeas"]
            ),
            MicronutrientInfo(
                name: "Selenium",
                target: selenium,
                unit: "mcg",
                category: .mineral,
                description: "Antioxidant, thyroid function",
                foodSources: ["Brazil nuts", "Fish", "Eggs", "Sunflower seeds"]
            ),
            MicronutrientInfo(
                name: "Copper",
                target: copper,
                unit: "mcg",
                category: .mineral,
                description: "Iron metabolism and connective tissue",
                foodSources: ["Shellfish", "Nuts", "Seeds", "Dark chocolate"]
            ),
            MicronutrientInfo(
                name: "Manganese",
                target: manganese,
                unit: "mg",
                category: .mineral,
                description: "Bone health and metabolism",
                foodSources: ["Whole grains", "Nuts", "Legumes", "Tea"]
            ),
            MicronutrientInfo(
                name: "Iodine",
                target: iodine,
                unit: "mcg",
                category: .mineral,
                description: "Thyroid hormone production",
                foodSources: ["Seaweed", "Fish", "Dairy", "Iodized salt"]
            ),
            MicronutrientInfo(
                name: "Chromium",
                target: chromium,
                unit: "mcg",
                category: .mineral,
                description: "Blood sugar regulation",
                foodSources: ["Broccoli", "Grapes", "Whole grains", "Meat"]
            ),

            // Other
            MicronutrientInfo(
                name: "Omega-3 (ALA)",
                target: omega3,
                unit: "g",
                category: .other,
                description: "Heart and brain health, reduces inflammation",
                foodSources: ["Fatty fish", "Flaxseeds", "Walnuts", "Chia seeds"]
            ),
            MicronutrientInfo(
                name: "Choline",
                target: choline,
                unit: "mg",
                category: .other,
                description: "Brain function and liver health",
                foodSources: ["Eggs", "Liver", "Fish", "Peanuts"]
            )
        ]
    }

    /// Get nutrients by category
    func nutrients(for category: MicronutrientCategory) -> [MicronutrientInfo] {
        allNutrients.filter { $0.category == category }
    }
}
