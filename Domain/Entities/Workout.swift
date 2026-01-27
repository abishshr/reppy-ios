import Foundation

/// Workout log entity
struct Workout: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    var loggedAt: Date
    var workoutType: WorkoutType?
    var exercises: [Exercise]
    var durationMin: Int?
    var caloriesBurnedEst: Int?
    var confidence: Double?
    var notes: String?

    init(
        id: String = UUID().uuidString,
        userId: String,
        loggedAt: Date = Date(),
        workoutType: WorkoutType? = nil,
        exercises: [Exercise] = [],
        durationMin: Int? = nil,
        caloriesBurnedEst: Int? = nil,
        confidence: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.loggedAt = loggedAt
        self.workoutType = workoutType
        self.exercises = exercises
        self.durationMin = durationMin
        self.caloriesBurnedEst = caloriesBurnedEst
        self.confidence = confidence
        self.notes = notes
    }
}

/// Individual exercise in a workout
struct Exercise: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    var sets: Int?
    var reps: Int?
    var weightKg: Double?
    var durationMin: Double?
    var restSec: Int?
    var notes: String?

    var summary: String {
        var parts: [String] = []

        if let sets = sets, let reps = reps {
            parts.append("\(sets)x\(reps)")
        }

        if let weight = weightKg {
            parts.append("\(Int(weight))kg")
        }

        if let duration = durationMin {
            parts.append("\(Int(duration)) min")
        }

        return parts.isEmpty ? name : "\(name) - \(parts.joined(separator: " "))"
    }
}

enum WorkoutType: String, Codable, CaseIterable {
    case strength
    case cardio
    case flexibility
    case mixed
    case crossfit
    case hyrox
    case hiit
    case functional
    case endurance
    case olympic = "olympic_lifting"
    case powerlifting
    case bodyweight
    case circuit
    // Combat sports
    case boxing
    case muayThai = "muay_thai"
    case mma
    case kickboxing
    case wrestling
    case bjj
    // Mind-body
    case pilates
    case yoga
    case barre
    // Other
    case swimming
    case cycling
    case running
    case rowing
    case sports

    var displayName: String {
        switch self {
        case .crossfit: return "CrossFit"
        case .hyrox: return "Hyrox"
        case .hiit: return "HIIT"
        case .olympic: return "Olympic Lifting"
        case .muayThai: return "Muay Thai"
        case .mma: return "MMA"
        case .bjj: return "Brazilian Jiu-Jitsu"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.yoga"
        case .mixed: return "figure.mixed.cardio"
        case .crossfit: return "figure.cross.training"
        case .hyrox: return "figure.run.circle.fill"
        case .hiit: return "bolt.heart.fill"
        case .functional: return "figure.strengthtraining.functional"
        case .endurance: return "figure.run"
        case .olympic: return "figure.weightlifting"
        case .powerlifting: return "scalemass.fill"
        case .bodyweight: return "figure.stand"
        case .circuit: return "arrow.triangle.2.circlepath"
        // Combat sports
        case .boxing: return "figure.boxing"
        case .muayThai: return "figure.kickboxing"
        case .mma: return "figure.mma"
        case .kickboxing: return "figure.kickboxing"
        case .wrestling: return "figure.wrestling"
        case .bjj: return "figure.wrestling"
        // Mind-body
        case .pilates: return "figure.pilates"
        case .yoga: return "figure.yoga"
        case .barre: return "figure.barre"
        // Other
        case .swimming: return "figure.pool.swim"
        case .cycling: return "figure.outdoor.cycle"
        case .running: return "figure.run"
        case .rowing: return "figure.rower"
        case .sports: return "sportscourt.fill"
        }
    }

    var description: String {
        switch self {
        case .strength: return "Build muscle and strength"
        case .cardio: return "Improve cardiovascular fitness"
        case .flexibility: return "Increase mobility and flexibility"
        case .mixed: return "Combination of different training styles"
        case .crossfit: return "High-intensity functional movements"
        case .hyrox: return "Fitness racing - run + functional stations"
        case .hiit: return "High-intensity interval training"
        case .functional: return "Real-world movement patterns"
        case .endurance: return "Long-duration stamina training"
        case .olympic: return "Snatch, clean & jerk training"
        case .powerlifting: return "Squat, bench, deadlift focus"
        case .bodyweight: return "No equipment required"
        case .circuit: return "Station-based workout rotation"
        // Combat sports
        case .boxing: return "Punching techniques and footwork"
        case .muayThai: return "Art of eight limbs"
        case .mma: return "Mixed martial arts training"
        case .kickboxing: return "Punches and kicks combination"
        case .wrestling: return "Grappling and takedowns"
        case .bjj: return "Ground fighting and submissions"
        // Mind-body
        case .pilates: return "Core strength and flexibility"
        case .yoga: return "Mind-body connection and flexibility"
        case .barre: return "Ballet-inspired toning"
        // Other
        case .swimming: return "Full-body aquatic workout"
        case .cycling: return "Leg strength and cardio"
        case .running: return "Cardiovascular endurance"
        case .rowing: return "Full-body cardio and strength"
        case .sports: return "Sport-specific training"
        }
    }
}

/// AI-suggested workout before confirmation
struct WorkoutSuggestion: Codable {
    let suggestionId: String
    let exercises: [Exercise]
    let workoutType: WorkoutType?
    let estimatedDurationMin: Int?
    let estimatedCaloriesBurned: Int?
    let confidence: Double
    let notes: String?
    let clarifyingQuestions: [String]
}
