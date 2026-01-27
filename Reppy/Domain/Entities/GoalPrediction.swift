import Foundation

// MARK: - Goal Settings

struct GoalSettings: Codable, Equatable {
    var weightGoalKg: Double?
    var targetRateKgPerWeek: Double?
    var goalTargetDate: Date?

    enum CodingKeys: String, CodingKey {
        case weightGoalKg = "weight_goal_kg"
        case targetRateKgPerWeek = "target_rate_kg_per_week"
        case goalTargetDate = "goal_target_date"
    }
}

struct UpdateGoalSettingsRequest: Codable {
    var weightGoalKg: Double?
    var targetRateKgPerWeek: Double?
    var goalTargetDate: Date?

    enum CodingKeys: String, CodingKey {
        case weightGoalKg = "weight_goal_kg"
        case targetRateKgPerWeek = "target_rate_kg_per_week"
        case goalTargetDate = "goal_target_date"
    }
}

// MARK: - Weight Data Point

struct WeightDataPoint: Codable, Identifiable {
    let date: Date
    let weightKg: Double

    var id: Date { date }

    enum CodingKeys: String, CodingKey {
        case date
        case weightKg = "weight_kg"
    }
}

// MARK: - Goal Prediction

enum GoalStatus: String, Codable {
    case ahead
    case onTrack = "on_track"
    case behind
    case noGoal = "no_goal"
    case noData = "no_data"

    var displayName: String {
        switch self {
        case .ahead: return "Ahead of Schedule"
        case .onTrack: return "On Track"
        case .behind: return "Behind Schedule"
        case .noGoal: return "No Goal Set"
        case .noData: return "No Data"
        }
    }

    var icon: String {
        switch self {
        case .ahead: return "hare.fill"
        case .onTrack: return "checkmark.circle.fill"
        case .behind: return "tortoise.fill"
        case .noGoal: return "target"
        case .noData: return "chart.line.downtrend.xyaxis"
        }
    }

    var color: String {
        switch self {
        case .ahead: return "green"
        case .onTrack: return "blue"
        case .behind: return "orange"
        case .noGoal, .noData: return "gray"
        }
    }
}

struct GoalPrediction: Codable {
    // Current state
    let currentWeight: Double?
    let goalWeight: Double?
    let weightToLose: Double?

    // Target rate
    let targetRateKgPerWeek: Double?
    let actualRateKgPerWeek: Double?

    // Predictions
    let predictedGoalDate: Date?
    let targetGoalDate: Date?
    let weeksToGoal: Int?
    let daysToGoal: Int?

    // Status
    let isOnTrack: Bool
    let onTrackPercentage: Double?
    let status: GoalStatus
    let statusMessage: String

    // Historical data
    let weightHistory: [WeightDataPoint]
    let trendLine: [WeightDataPoint]

    // Progress
    let totalLost: Double?
    let progressPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case currentWeight = "current_weight"
        case goalWeight = "goal_weight"
        case weightToLose = "weight_to_lose"
        case targetRateKgPerWeek = "target_rate_kg_per_week"
        case actualRateKgPerWeek = "actual_rate_kg_per_week"
        case predictedGoalDate = "predicted_goal_date"
        case targetGoalDate = "target_goal_date"
        case weeksToGoal = "weeks_to_goal"
        case daysToGoal = "days_to_goal"
        case isOnTrack = "is_on_track"
        case onTrackPercentage = "on_track_percentage"
        case status
        case statusMessage = "status_message"
        case weightHistory = "weight_history"
        case trendLine = "trend_line"
        case totalLost = "total_lost"
        case progressPercentage = "progress_percentage"
    }

    // MARK: - Computed Properties

    var formattedPredictedDate: String? {
        guard let date = predictedGoalDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var formattedTimeToGoal: String? {
        guard let weeks = weeksToGoal else { return nil }
        if weeks == 0 {
            if let days = daysToGoal, days > 0 {
                return "\(days) day\(days == 1 ? "" : "s")"
            }
            return "Less than a week"
        } else if weeks < 4 {
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = weeks / 4
            let remainingWeeks = weeks % 4
            if remainingWeeks == 0 {
                return "\(months) month\(months == 1 ? "" : "s")"
            }
            return "\(months) month\(months == 1 ? "" : "s"), \(remainingWeeks) week\(remainingWeeks == 1 ? "" : "s")"
        }
    }
}

// MARK: - Placeholder

extension GoalPrediction {
    static let placeholder = GoalPrediction(
        currentWeight: 80.0,
        goalWeight: 75.0,
        weightToLose: 5.0,
        targetRateKgPerWeek: 0.5,
        actualRateKgPerWeek: 0.4,
        predictedGoalDate: Calendar.current.date(byAdding: .day, value: 90, to: Date()),
        targetGoalDate: Calendar.current.date(byAdding: .day, value: 70, to: Date()),
        weeksToGoal: 13,
        daysToGoal: 90,
        isOnTrack: true,
        onTrackPercentage: 80.0,
        status: .onTrack,
        statusMessage: "You're on track to reach your goal!",
        weightHistory: [],
        trendLine: [],
        totalLost: 2.5,
        progressPercentage: 33.3
    )
}
