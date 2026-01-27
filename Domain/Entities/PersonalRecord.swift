import Foundation

/// Personal record for a specific exercise
struct PersonalRecord: Codable, Identifiable {
    let id: String
    let exerciseName: String

    // Weight PR (heaviest weight lifted)
    let maxWeightKg: Double?
    let maxWeightReps: Int?
    let maxWeightDate: Date?

    // Volume PR (weight × reps × sets)
    let maxVolumeKg: Double?
    let maxVolumeDate: Date?

    // Reps PR (most reps)
    let maxReps: Int?
    let maxRepsWeightKg: Double?
    let maxRepsDate: Date?

    // Tracking
    let timesPerformed: Int
    let lastPerformed: Date?
    let lastWeightKg: Double?
    let lastReps: Int?
    let lastSets: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseName = "exercise_name"
        case maxWeightKg = "max_weight_kg"
        case maxWeightReps = "max_weight_reps"
        case maxWeightDate = "max_weight_date"
        case maxVolumeKg = "max_volume_kg"
        case maxVolumeDate = "max_volume_date"
        case maxReps = "max_reps"
        case maxRepsWeightKg = "max_reps_weight_kg"
        case maxRepsDate = "max_reps_date"
        case timesPerformed = "times_performed"
        case lastPerformed = "last_performed"
        case lastWeightKg = "last_weight_kg"
        case lastReps = "last_reps"
        case lastSets = "last_sets"
    }
}

/// Information about a new PR that was set during a workout
struct PRInfo: Codable {
    let exerciseName: String
    let prType: String  // "weight", "volume", "reps"
    let newValue: Double
    let previousValue: Double?
    let unit: String  // "kg", "reps", or "kg (volume)"

    enum CodingKeys: String, CodingKey {
        case exerciseName = "exercise_name"
        case prType = "pr_type"
        case newValue = "new_value"
        case previousValue = "previous_value"
        case unit
    }
}

/// Exercise attempt history entry
struct ExerciseAttempt: Codable, Identifiable {
    var id: String { workoutId }

    let workoutId: String
    let loggedAt: String
    let weightKg: Double?
    let reps: Int?
    let sets: Int?
    let durationMin: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case workoutId = "workout_id"
        case loggedAt = "logged_at"
        case weightKg = "weight_kg"
        case reps
        case sets
        case durationMin = "duration_min"
        case notes
    }
}
