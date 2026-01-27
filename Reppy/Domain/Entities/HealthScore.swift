import Foundation

// MARK: - Health Score Models

struct HealthScoreBreakdown: Codable, Equatable {
    let nutritionalBalance: Int
    let processingLevel: Int
    let ingredientQuality: Int
    let macroBalance: Int

    enum CodingKeys: String, CodingKey {
        case nutritionalBalance = "nutritional_balance"
        case processingLevel = "processing_level"
        case ingredientQuality = "ingredient_quality"
        case macroBalance = "macro_balance"
    }
}

struct MealHealthAnalysis: Codable, Equatable {
    let overallScore: Int
    let breakdown: HealthScoreBreakdown
    let insights: [String]
    let suggestions: [String]
    let positiveAspects: [String]
    let concerns: [String]

    enum CodingKeys: String, CodingKey {
        case overallScore = "overall_score"
        case breakdown
        case insights
        case suggestions
        case positiveAspects = "positive_aspects"
        case concerns
    }

    var scoreColor: String {
        switch overallScore {
        case 80...100: return "green"
        case 60..<80: return "yellow"
        case 40..<60: return "orange"
        default: return "red"
        }
    }

    var scoreRating: String {
        switch overallScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Improvement"
        }
    }
}

struct DailyHealthSummary: Codable, Equatable {
    let averageScore: Double
    let mealCount: Int
    let overallRating: String
    let analyzedAt: Date

    enum CodingKeys: String, CodingKey {
        case averageScore = "average_score"
        case mealCount = "meal_count"
        case overallRating = "overall_rating"
        case analyzedAt = "analyzed_at"
    }
}

// MARK: - Nutrient Synergy Models

struct SynergyInsight: Codable, Identifiable, Equatable {
    var id: String { "\(type)-\(title)" }
    let type: String // "beneficial" or "inhibiting"
    let title: String
    let description: String
    let foodsInvolved: [String]
    let impact: String // "high", "medium", "low"

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case description
        case foodsInvolved = "foods_involved"
        case impact
    }

    var isBeneficial: Bool {
        type == "beneficial"
    }

    var impactLevel: Int {
        switch impact {
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 0
        }
    }
}

struct MealSynergyAnalysis: Codable, Equatable {
    let insights: [SynergyInsight]
    let beneficialCount: Int
    let inhibitingCount: Int

    enum CodingKeys: String, CodingKey {
        case insights
        case beneficialCount = "beneficial_count"
        case inhibitingCount = "inhibiting_count"
    }
}

// MARK: - Circadian Models

struct MealTimingAnalysis: Codable, Equatable {
    let averageFirstMeal: String?
    let averageLastMeal: String?
    let eatingWindowHours: Double?
    let lateNightEatingFrequency: Double
    let consistencyScore: Int
    let mealTimeVarianceMinutes: Double

    enum CodingKeys: String, CodingKey {
        case averageFirstMeal = "average_first_meal"
        case averageLastMeal = "average_last_meal"
        case eatingWindowHours = "eating_window_hours"
        case lateNightEatingFrequency = "late_night_eating_frequency"
        case consistencyScore = "consistency_score"
        case mealTimeVarianceMinutes = "meal_time_variance_minutes"
    }

    var consistencyRating: String {
        switch consistencyScore {
        case 80...100: return "Very Consistent"
        case 60..<80: return "Fairly Consistent"
        case 40..<60: return "Somewhat Inconsistent"
        default: return "Needs Improvement"
        }
    }
}

struct CircadianRecommendation: Codable, Identifiable, Equatable {
    var id: String { title }
    let priority: String // "high", "medium", "low"
    let title: String
    let description: String
    let action: String
    let benefit: String

    var priorityLevel: Int {
        switch priority {
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 0
        }
    }
}

struct CircadianAnalysis: Codable, Equatable {
    let analysis: MealTimingAnalysis
    let recommendations: [CircadianRecommendation]
    let hasData: Bool

    enum CodingKeys: String, CodingKey {
        case analysis
        case recommendations
        case hasData = "has_data"
    }
}

struct OptimalMealTimesRequest: Codable {
    let wakeTime: String
    let sleepTime: String

    enum CodingKeys: String, CodingKey {
        case wakeTime = "wake_time"
        case sleepTime = "sleep_time"
    }
}

struct OptimalMealTimes: Codable, Equatable {
    let breakfast: String
    let lunch: String
    let dinner: String
    let eatingCutoff: String
    let eatingWindowHours: Int

    enum CodingKeys: String, CodingKey {
        case breakfast
        case lunch
        case dinner
        case eatingCutoff = "eating_cutoff"
        case eatingWindowHours = "eating_window_hours"
    }
}

struct DailyEatingWindow: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let firstMeal: String
    let lastMeal: String
    let eatingWindowHours: Double
    let mealCount: Int

    enum CodingKeys: String, CodingKey {
        case date
        case firstMeal = "first_meal"
        case lastMeal = "last_meal"
        case eatingWindowHours = "eating_window_hours"
        case mealCount = "meal_count"
    }
}

struct EatingWindowStats: Codable, Equatable {
    let dailyWindows: [DailyEatingWindow]
    let averageEatingWindowHours: Double
    let daysAnalyzed: Int

    enum CodingKeys: String, CodingKey {
        case dailyWindows = "daily_windows"
        case averageEatingWindowHours = "average_eating_window_hours"
        case daysAnalyzed = "days_analyzed"
    }
}
