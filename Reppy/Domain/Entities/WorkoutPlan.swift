import Foundation

/// Workout plan entity
struct WorkoutPlan: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let durationWeeks: Int
    let daysPerWeek: Int
    let goal: String?
    let difficulty: String?
    let equipment: [String]?
    let splitType: String?
    let isActive: Bool
    let currentWeek: Int
    let currentDay: Int
    let startedAt: Date?
    let createdAt: Date
    var days: [WorkoutPlanDay]

    var totalWorkouts: Int {
        days.filter { !$0.isRestDay }.count
    }

    var completedWorkouts: Int {
        days.filter { $0.isCompleted && !$0.isRestDay }.count
    }

    var progressPercent: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(completedWorkouts) / Double(totalWorkouts) * 100
    }
}

/// A single day in a workout plan
struct WorkoutPlanDay: Identifiable, Codable, Equatable {
    let id: String
    let weekNumber: Int
    let dayNumber: Int
    let dayName: String?
    let workoutType: String?
    let exercises: [PlannedExercise]
    let targetMuscles: [String]?
    let estimatedDurationMin: Int?
    let estimatedCalories: Int?
    let notes: String?
    let isRestDay: Bool
    let isCompleted: Bool
    let completedAt: Date?

    var displayName: String {
        dayName ?? "Day \(dayNumber)"
    }

    var muscleGroupsDisplay: String {
        targetMuscles?.joined(separator: ", ").capitalized ?? ""
    }
}

/// An exercise in a workout plan
struct PlannedExercise: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let sets: Int?
    let reps: StringOrInt?
    let weightKg: Double?
    let weightSuggestion: String?
    let restSec: Int?
    let tempo: String?
    let notes: String?
    let isSuperset: Bool?
    let supersetWith: String?

    // ExerciseDB enrichment
    let gifUrl: String?
    let targetMuscle: String?
    let instructions: [String]?
    let secondaryMuscles: [String]?

    // MuscleWiki video (higher quality than GIF)
    let videoUrl: String?

    var repsDisplay: String {
        guard let reps = reps else { return "-" }
        switch reps {
        case .string(let s): return s
        case .int(let i): return "\(i)"
        }
    }

    var setsRepsDisplay: String {
        let setsStr = sets.map { "\($0)" } ?? "-"
        return "\(setsStr) x \(repsDisplay)"
    }

    var restDisplay: String? {
        guard let rest = restSec else { return nil }
        if rest >= 60 {
            let mins = rest / 60
            let secs = rest % 60
            return secs > 0 ? "\(mins)m \(secs)s" : "\(mins)m"
        }
        return "\(rest)s"
    }

    /// Prefer video over GIF
    var hasMedia: Bool {
        videoUrl != nil || gifUrl != nil
    }

    /// Best available media URL (video preferred)
    var mediaUrl: String? {
        videoUrl ?? gifUrl
    }

    /// Whether we have a video (not just GIF)
    var hasVideo: Bool {
        videoUrl != nil
    }
}

/// Helper for handling reps that can be string or int
enum StringOrInt: Codable, Equatable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                StringOrInt.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        }
    }

    /// Returns an integer value, parsing from string if needed
    var intValue: Int? {
        switch self {
        case .int(let i): return i
        case .string(let s):
            // Try to parse "8-10" as just 8, or "10" as 10
            if let firstNum = s.split(separator: "-").first,
               let num = Int(firstNum) {
                return num
            }
            return Int(s)
        }
    }

    /// Returns a display string (e.g., "10" or "8-12")
    var displayValue: String {
        switch self {
        case .int(let i): return "\(i)"
        case .string(let s): return s
        }
    }
}

/// Summary of a workout plan (for list view)
struct WorkoutPlanSummary: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let durationWeeks: Int
    let daysPerWeek: Int
    let goal: String?
    let difficulty: String?
    let splitType: String?
    let isActive: Bool
    let currentWeek: Int
    let currentDay: Int
    let totalWorkouts: Int
    let completedWorkouts: Int
    let progressPercent: Double
}

/// Workout goal types
enum WorkoutGoal: String, CaseIterable {
    case strength
    case hypertrophy
    case endurance
    case fatLoss = "fat_loss"
    case generalFitness = "general_fitness"

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Muscle Growth"
        case .endurance: return "Endurance"
        case .fatLoss: return "Fat Loss"
        case .generalFitness: return "General Fitness"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .endurance: return "figure.run"
        case .fatLoss: return "flame.fill"
        case .generalFitness: return "heart.fill"
        }
    }

    var color: String {
        switch self {
        case .strength: return "red"
        case .hypertrophy: return "purple"
        case .endurance: return "blue"
        case .fatLoss: return "orange"
        case .generalFitness: return "green"
        }
    }
}

/// Workout split types
enum WorkoutSplit: String, CaseIterable {
    case fullBody = "full_body"
    case upperLower = "upper_lower"
    case pushPullLegs = "push_pull_legs"
    case broSplit = "bro_split"

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        case .upperLower: return "Upper/Lower"
        case .pushPullLegs: return "Push/Pull/Legs"
        case .broSplit: return "Bro Split"
        }
    }
}

/// Difficulty levels
enum WorkoutDifficulty: String, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "red"
        }
    }
}
