import Foundation

/// Current streak information
struct StreakInfo: Codable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: Date?
    let isActiveToday: Bool
    let streakAtRisk: Bool
    let hoursUntilBreak: Int?
    let nextMilestone: StreakMilestone?
    let daysToNextMilestone: Int?
    let achievedMilestones: [StreakMilestone]

    /// Whether this is a new user with no streak yet
    var isNewUser: Bool {
        currentStreak == 0 && lastActivityDate == nil
    }

    /// Progress towards next milestone (0.0 to 1.0)
    var milestoneProgress: Double {
        guard let next = nextMilestone, let daysRemaining = daysToNextMilestone else {
            return 1.0 // All milestones achieved
        }
        let milestoneTotal = next.days
        let daysCompleted = milestoneTotal - daysRemaining
        return Double(daysCompleted) / Double(milestoneTotal)
    }

    /// Human-readable streak status
    var statusText: String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if isActiveToday {
            return "Keep it going!"
        } else if streakAtRisk {
            return "Log activity to keep your streak!"
        } else if let hours = hoursUntilBreak {
            return "\(hours)h left to log activity"
        }
        return "Great job!"
    }

    /// Color hint for streak status
    var statusColor: StreakStatusColor {
        if currentStreak == 0 {
            return .neutral
        } else if streakAtRisk {
            return .warning
        } else if isActiveToday {
            return .success
        } else {
            return .info
        }
    }
}

/// Response from recording activity
struct StreakUpdateResponse: Codable, Equatable {
    let streak: StreakInfo
    let newMilestone: StreakMilestone?
    let milestoneMessage: String?
}

/// Streak milestone achievements
enum StreakMilestone: String, Codable, CaseIterable {
    case firstDay = "first_day"
    case week = "week"
    case twoWeeks = "two_weeks"
    case month = "month"
    case twoMonths = "two_months"
    case quarter = "quarter"
    case halfYear = "half_year"
    case year = "year"

    /// Number of days required for this milestone
    var days: Int {
        switch self {
        case .firstDay: return 1
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        case .twoMonths: return 60
        case .quarter: return 90
        case .halfYear: return 180
        case .year: return 365
        }
    }

    /// Display name for the milestone
    var displayName: String {
        switch self {
        case .firstDay: return "First Day"
        case .week: return "1 Week"
        case .twoWeeks: return "2 Weeks"
        case .month: return "1 Month"
        case .twoMonths: return "2 Months"
        case .quarter: return "3 Months"
        case .halfYear: return "6 Months"
        case .year: return "1 Year"
        }
    }

    /// Emoji for the milestone
    var emoji: String {
        switch self {
        case .firstDay: return "🎯"
        case .week: return "🔥"
        case .twoWeeks: return "💪"
        case .month: return "⭐️"
        case .twoMonths: return "🏆"
        case .quarter: return "🥇"
        case .halfYear: return "👑"
        case .year: return "🎖️"
        }
    }

    /// Congratulations message
    var celebrationMessage: String {
        switch self {
        case .firstDay: return "You've started your journey! Keep it going!"
        case .week: return "One week strong! You're building a great habit!"
        case .twoWeeks: return "Two weeks of consistency! You're on fire!"
        case .month: return "A full month! You're unstoppable!"
        case .twoMonths: return "60 days of dedication! Incredible!"
        case .quarter: return "90 days! You've made fitness a lifestyle!"
        case .halfYear: return "Half a year! You're a true champion!"
        case .year: return "365 days! Legendary achievement!"
        }
    }
}

/// Color hints for streak status
enum StreakStatusColor {
    case success  // Green - streak active today
    case warning  // Orange - streak at risk
    case info     // Blue - normal status
    case neutral  // Gray - no streak yet
}
