import Foundation

/// A single water intake log entry
struct WaterLog: Codable, Identifiable, Equatable {
    let id: String
    let amountMl: Int
    let loggedAt: Date
    let source: String

    var amountL: Double {
        Double(amountMl) / 1000.0
    }

    var displayAmount: String {
        if amountMl >= 1000 {
            return String(format: "%.1fL", amountL)
        }
        return "\(amountMl)ml"
    }
}

/// Daily water summary
struct WaterSummary: Codable, Equatable {
    let date: String
    let totalMl: Int
    let goalMl: Int
    let percentage: Double
    let logsCount: Int
    let logs: [WaterLog]

    var totalL: Double {
        Double(totalMl) / 1000.0
    }

    var goalL: Double {
        Double(goalMl) / 1000.0
    }

    var remainingMl: Int {
        max(0, goalMl - totalMl)
    }

    var isGoalMet: Bool {
        totalMl >= goalMl
    }
}

/// Water intake statistics
struct WaterStats: Codable, Equatable {
    let todayMl: Int
    let todayGoalMl: Int
    let todayPercentage: Double
    let weekAvgMl: Double
    let weekGoalMetDays: Int
    let streakDays: Int

    var todayL: Double {
        Double(todayMl) / 1000.0
    }

    var goalL: Double {
        Double(todayGoalMl) / 1000.0
    }
}

/// Common water amounts for quick add
enum QuickWaterAmount: Int, CaseIterable {
    case small = 250
    case medium = 500
    case large = 750
    case bottle = 1000

    var displayName: String {
        switch self {
        case .small: return "250ml"
        case .medium: return "500ml"
        case .large: return "750ml"
        case .bottle: return "1L"
        }
    }

    var icon: String {
        switch self {
        case .small: return "drop"
        case .medium: return "drop.fill"
        case .large: return "waterbottle"
        case .bottle: return "waterbottle.fill"
        }
    }
}
