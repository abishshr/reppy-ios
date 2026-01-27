import Foundation

/// Daily activity tracking (steps, etc.)
struct DailyActivity: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let date: Date
    var steps: Int
    var source: String?
    var syncedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        date: Date,
        steps: Int = 0,
        source: String? = "apple_health",
        syncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.steps = steps
        self.source = source
        self.syncedAt = syncedAt
    }
}

/// Activity summary
struct ActivitySummary: Codable {
    let todaySteps: Int
    let todayGoal: Int
    let todayProgressPercent: Double
    let sevenDayAverage: Double
    let sevenDayTotal: Int
    let streakDays: Int
    let dailyData: [DailyActivity]

    var remainingSteps: Int {
        max(0, todayGoal - todaySteps)
    }

    var isGoalMet: Bool {
        todaySteps >= todayGoal
    }
}
