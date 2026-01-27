import Foundation

// MARK: - Enums

/// Flow intensity levels
enum FlowIntensity: String, Codable, CaseIterable {
    case spotting
    case light
    case medium
    case heavy

    var displayName: String {
        switch self {
        case .spotting: return "Spotting"
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }

    var icon: String {
        switch self {
        case .spotting: return "drop"
        case .light: return "drop.fill"
        case .medium: return "drop.fill"
        case .heavy: return "drop.fill"
        }
    }

    var color: String {
        switch self {
        case .spotting: return "pink"
        case .light: return "red"
        case .medium: return "red"
        case .heavy: return "darkRed"
        }
    }
}

/// Menstrual cycle phases
enum CyclePhase: String, Codable, CaseIterable {
    case menstruation
    case follicular
    case ovulation
    case luteal
    case unknown

    var displayName: String {
        switch self {
        case .menstruation: return "Menstruation"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        case .unknown: return "Unknown"
        }
    }

    var description: String {
        switch self {
        case .menstruation: return "Period days"
        case .follicular: return "Energy rising"
        case .ovulation: return "Peak energy"
        case .luteal: return "Wind down"
        case .unknown: return "Log your period to track"
        }
    }

    var icon: String {
        switch self {
        case .menstruation: return "drop.fill"
        case .follicular: return "sunrise.fill"
        case .ovulation: return "sun.max.fill"
        case .luteal: return "moon.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .menstruation: return "red"
        case .follicular: return "orange"
        case .ovulation: return "green"
        case .luteal: return "purple"
        case .unknown: return "gray"
        }
    }
}

/// Common menstrual symptoms
enum CycleSymptom: String, Codable, CaseIterable, Identifiable {
    case cramps
    case bloating
    case headache
    case fatigue
    case breastTenderness = "breast_tenderness"
    case moodSwings = "mood_swings"
    case backPain = "back_pain"
    case nausea
    case acne
    case insomnia
    case cravings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cramps: return "Cramps"
        case .bloating: return "Bloating"
        case .headache: return "Headache"
        case .fatigue: return "Fatigue"
        case .breastTenderness: return "Breast Tenderness"
        case .moodSwings: return "Mood Swings"
        case .backPain: return "Back Pain"
        case .nausea: return "Nausea"
        case .acne: return "Acne"
        case .insomnia: return "Insomnia"
        case .cravings: return "Cravings"
        }
    }

    var icon: String {
        switch self {
        case .cramps: return "bolt.fill"
        case .bloating: return "circle.fill"
        case .headache: return "brain.head.profile"
        case .fatigue: return "battery.25"
        case .breastTenderness: return "heart.fill"
        case .moodSwings: return "theatermasks.fill"
        case .backPain: return "figure.stand"
        case .nausea: return "stomach"
        case .acne: return "face.dashed"
        case .insomnia: return "moon.zzz.fill"
        case .cravings: return "fork.knife"
        }
    }
}

// MARK: - Data Models

/// Menstrual cycle log entry
struct MenstrualCycleLog: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let isPeriodDay: Bool
    let flowIntensity: String?
    let symptoms: [String]?
    let mood: Int?
    let energyLevel: Int?
    let notes: String?
    let createdAt: Date

    var flowIntensityEnum: FlowIntensity? {
        guard let intensity = flowIntensity else { return nil }
        return FlowIntensity(rawValue: intensity)
    }

    var symptomEnums: [CycleSymptom] {
        symptoms?.compactMap { CycleSymptom(rawValue: $0) } ?? []
    }
}

/// Cycle settings for predictions
struct CycleSettings: Codable, Equatable {
    let id: String
    let averageCycleLength: Int
    let averagePeriodLength: Int
    let lastPeriodStart: Date?
    let notifyPeriodReminder: Bool
    let reminderDaysBefore: Int
}

/// Current cycle status
struct CycleStatus: Codable, Equatable {
    let currentPhase: String
    let cycleDay: Int
    let daysUntilPeriod: Int?
    let nextPeriodDate: Date?
    let isFertileWindow: Bool
    let phaseDay: Int
    let phaseDaysRemaining: Int

    var phaseEnum: CyclePhase {
        CyclePhase(rawValue: currentPhase) ?? .unknown
    }
}

/// Phase-based recommendations
struct CycleRecommendations: Codable, Equatable {
    let phase: String
    let phaseDescription: String
    let nutritionTips: [String]
    let recommendedFoods: [String]
    let foodsToLimit: [String]
    let workoutTips: [String]
    let workoutIntensity: String
    let selfCareTips: [String]

    var phaseEnum: CyclePhase {
        CyclePhase(rawValue: phase) ?? .unknown
    }
}

/// Calendar day data
struct CycleCalendarDay: Codable, Identifiable, Equatable {
    var id: Date { date }

    let date: Date
    let isPeriodDay: Bool
    let isPredictedPeriod: Bool
    let isFertileWindow: Bool
    let isOvulationDay: Bool
    let phase: String?
    let hasLog: Bool
    let flowIntensity: String?
    let symptoms: [String]?
    let mood: Int?
    let energyLevel: Int?

    var phaseEnum: CyclePhase? {
        guard let phase = phase else { return nil }
        return CyclePhase(rawValue: phase)
    }
}

/// History response
struct CycleHistory: Codable, Equatable {
    let logs: [MenstrualCycleLog]
    let averageCycleLength: Int
    let averagePeriodLength: Int
    let lastPeriodStart: Date?
    let totalPeriodsLogged: Int
}

// MARK: - Request Models

/// Request to create/update a cycle log
struct MenstrualLogCreate: Codable {
    let date: Date
    let isPeriodDay: Bool
    let flowIntensity: String?
    let symptoms: [String]?
    let mood: Int?
    let energyLevel: Int?
    let notes: String?

    init(
        date: Date,
        isPeriodDay: Bool = false,
        flowIntensity: FlowIntensity? = nil,
        symptoms: [CycleSymptom]? = nil,
        mood: Int? = nil,
        energyLevel: Int? = nil,
        notes: String? = nil
    ) {
        self.date = date
        self.isPeriodDay = isPeriodDay
        self.flowIntensity = flowIntensity?.rawValue
        self.symptoms = symptoms?.map { $0.rawValue }
        self.mood = mood
        self.energyLevel = energyLevel
        self.notes = notes
    }
}

/// Request to update cycle settings
struct CycleSettingsUpdate: Codable {
    let averageCycleLength: Int?
    let averagePeriodLength: Int?
    let lastPeriodStart: Date?
    let notifyPeriodReminder: Bool?
    let reminderDaysBefore: Int?

    init(
        averageCycleLength: Int? = nil,
        averagePeriodLength: Int? = nil,
        lastPeriodStart: Date? = nil,
        notifyPeriodReminder: Bool? = nil,
        reminderDaysBefore: Int? = nil
    ) {
        self.averageCycleLength = averageCycleLength
        self.averagePeriodLength = averagePeriodLength
        self.lastPeriodStart = lastPeriodStart
        self.notifyPeriodReminder = notifyPeriodReminder
        self.reminderDaysBefore = reminderDaysBefore
    }
}
