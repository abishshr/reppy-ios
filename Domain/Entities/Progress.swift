import Foundation

// MARK: - Weight Log

struct WeightLog: Identifiable, Codable, Equatable {
    let id: String
    let weightKg: Double
    let loggedAt: Date
    let notes: String?
    let source: String?

    init(
        id: String = UUID().uuidString,
        weightKg: Double,
        loggedAt: Date = Date(),
        notes: String? = nil,
        source: String = "manual"
    ) {
        self.id = id
        self.weightKg = weightKg
        self.loggedAt = loggedAt
        self.notes = notes
        self.source = source
    }
}

// MARK: - Weight Progress

struct WeightProgress: Codable, Equatable {
    let currentWeight: Double?
    let startingWeight: Double?
    let lowestWeight: Double?
    let highestWeight: Double?
    let totalChange: Double?
    let avgWeeklyChange: Double?
    let trend: String?
    let logs: [WeightTrend]
    let daysTracked: Int

    var trendDescription: String {
        switch trend {
        case "losing": return "Losing weight"
        case "gaining": return "Gaining weight"
        case "maintaining": return "Maintaining"
        default: return "Not enough data"
        }
    }

    var trendIcon: String {
        switch trend {
        case "losing": return "arrow.down.right"
        case "gaining": return "arrow.up.right"
        case "maintaining": return "arrow.right"
        default: return "minus"
        }
    }

    var trendColor: String {
        switch trend {
        case "losing": return "green"
        case "gaining": return "orange"
        case "maintaining": return "blue"
        default: return "gray"
        }
    }
}

struct WeightTrend: Codable, Equatable, Identifiable {
    var id: Date { date }
    let date: Date
    let weightKg: Double
}

// MARK: - Workout Progress

struct WorkoutProgress: Codable, Equatable {
    let totalWorkouts: Int
    let workoutsThisWeek: Int
    let workoutsThisMonth: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalDurationMin: Int
    let avgWorkoutDurationMin: Double
    let favoriteWorkoutType: String?
}

// MARK: - Nutrition Progress

struct NutritionProgress: Codable, Equatable {
    let avgDailyCalories: Double
    let avgDailyProtein: Double
    let avgDailyCarbs: Double
    let avgDailyFat: Double
    let daysOnTarget: Int
    let daysOverTarget: Int
    let daysUnderTarget: Int
    let totalMealsLogged: Int

    var adherencePercent: Double {
        let total = daysOnTarget + daysOverTarget + daysUnderTarget
        guard total > 0 else { return 0 }
        return Double(daysOnTarget) / Double(total) * 100
    }
}

// MARK: - Steps Progress

struct StepsProgress: Codable, Equatable {
    let avgDailySteps: Int
    let totalSteps: Int
    let daysGoalMet: Int
    let currentStreak: Int
    let bestDaySteps: Int
}

// MARK: - Progress Summary

struct ProgressSummary: Codable, Equatable {
    let weight: WeightProgress?
    let workouts: WorkoutProgress
    let nutrition: NutritionProgress
    let steps: StepsProgress
    let periodDays: Int
}
