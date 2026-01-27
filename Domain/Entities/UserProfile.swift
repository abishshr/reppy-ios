import Foundation

/// User profile with fitness preferences and goals
struct UserProfile: Codable, Equatable {
    let id: String
    let userId: String
    var name: String?
    var age: Int?
    var sex: Sex?
    var heightCm: Double?
    var weightKg: Double?
    var activityLevel: ActivityLevel?
    var goals: [FitnessGoal]
    var dietStyle: DietStyle?
    var allergies: [String]
    var equipment: [String]
    var timezone: String?
    var dailyCalorieTarget: Int?
    var dailyProteinTarget: Double?
    var dailyCarbsTarget: Double?
    var dailyFatTarget: Double?
    // Micronutrient targets
    var dailySugarTargetG: Double?
    var dailyFiberTargetG: Double?
    var dailySodiumTargetMg: Double?
    var dailySaturatedFatTargetG: Double?
    var dailyStepsGoal: Int?
    var dailyWaterGoalMl: Int?
    var onboardingCompleted: Bool

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String? = nil,
        age: Int? = nil,
        sex: Sex? = nil,
        heightCm: Double? = nil,
        weightKg: Double? = nil,
        activityLevel: ActivityLevel? = nil,
        goals: [FitnessGoal] = [],
        dietStyle: DietStyle? = nil,
        allergies: [String] = [],
        equipment: [String] = [],
        timezone: String? = nil,
        dailyCalorieTarget: Int? = nil,
        dailyProteinTarget: Double? = nil,
        dailyCarbsTarget: Double? = nil,
        dailyFatTarget: Double? = nil,
        dailySugarTargetG: Double? = 50,      // FDA recommendation: <50g
        dailyFiberTargetG: Double? = 28,       // FDA recommendation: 28g
        dailySodiumTargetMg: Double? = 2300,   // FDA recommendation: <2300mg
        dailySaturatedFatTargetG: Double? = 20, // FDA recommendation: <20g (based on 2000 cal diet)
        dailyStepsGoal: Int? = 10000,
        dailyWaterGoalMl: Int? = 2500,
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.age = age
        self.sex = sex
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevel = activityLevel
        self.goals = goals
        self.dietStyle = dietStyle
        self.allergies = allergies
        self.equipment = equipment
        self.timezone = timezone
        self.dailyCalorieTarget = dailyCalorieTarget
        self.dailyProteinTarget = dailyProteinTarget
        self.dailyCarbsTarget = dailyCarbsTarget
        self.dailyFatTarget = dailyFatTarget
        self.dailySugarTargetG = dailySugarTargetG
        self.dailyFiberTargetG = dailyFiberTargetG
        self.dailySodiumTargetMg = dailySodiumTargetMg
        self.dailySaturatedFatTargetG = dailySaturatedFatTargetG
        self.dailyStepsGoal = dailyStepsGoal
        self.dailyWaterGoalMl = dailyWaterGoalMl
        self.onboardingCompleted = onboardingCompleted
    }
}

// MARK: - Enums

enum Sex: String, Codable, CaseIterable {
    case male
    case female
    case other

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive = "very_active"

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly Active"
        case .moderate: return "Moderately Active"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .active: return "Hard exercise 6-7 days/week"
        case .veryActive: return "Very hard exercise, physical job"
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable {
    case fatLoss = "fat_loss"
    case muscleGain = "muscle_gain"
    case maintenance
    case health
    case endurance
    case strength

    var displayName: String {
        switch self {
        case .fatLoss: return "Fat Loss"
        case .muscleGain: return "Muscle Gain"
        case .maintenance: return "Maintenance"
        case .health: return "General Health"
        case .endurance: return "Endurance"
        case .strength: return "Strength"
        }
    }
}

enum DietStyle: String, Codable, CaseIterable {
    case omnivore
    case vegetarian
    case vegan
    case pescatarian
    case keto
    case paleo
    case mediterranean

    var displayName: String {
        rawValue.capitalized
    }
}
