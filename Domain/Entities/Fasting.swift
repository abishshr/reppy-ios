import Foundation

// MARK: - Fasting Protocol

enum FastingProtocol: String, Codable, CaseIterable, Identifiable {
    case if16_8 = "16:8"
    case if18_6 = "18:6"
    case if20_4 = "20:4"
    case omad = "omad"
    case extended24h = "24h"
    case extended36h = "36h"
    case extended48h = "48h"
    case fiveTwo = "5:2"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .if16_8: return "16:8 Fasting"
        case .if18_6: return "18:6 Fasting"
        case .if20_4: return "20:4 Warrior Diet"
        case .omad: return "One Meal A Day"
        case .extended24h: return "24-Hour Fast"
        case .extended36h: return "36-Hour Fast"
        case .extended48h: return "48-Hour Fast"
        case .fiveTwo: return "5:2 Diet"
        case .custom: return "Custom Fast"
        }
    }

    var shortName: String {
        switch self {
        case .if16_8: return "16:8"
        case .if18_6: return "18:6"
        case .if20_4: return "20:4"
        case .omad: return "OMAD"
        case .extended24h: return "24h"
        case .extended36h: return "36h"
        case .extended48h: return "48h"
        case .fiveTwo: return "5:2"
        case .custom: return "Custom"
        }
    }

    var description: String {
        switch self {
        case .if16_8:
            return "Fast for 16 hours, eat within an 8-hour window. Most popular and sustainable."
        case .if18_6:
            return "Fast for 18 hours, eat within a 6-hour window. More intense than 16:8."
        case .if20_4:
            return "Fast for 20 hours, eat within a 4-hour window. Also known as Warrior Diet."
        case .omad:
            return "Eat one large meal per day within a 1-hour window."
        case .extended24h:
            return "Full day fast from dinner to dinner or lunch to lunch."
        case .extended36h:
            return "Extended fast lasting 36 hours. Significant autophagy benefits."
        case .extended48h:
            return "Two-day extended fast. Consult a doctor before attempting."
        case .fiveTwo:
            return "Eat normally 5 days, restrict calories on 2 non-consecutive days."
        case .custom:
            return "Set your own fasting duration."
        }
    }

    var fastingHours: Int {
        switch self {
        case .if16_8: return 16
        case .if18_6: return 18
        case .if20_4: return 20
        case .omad: return 23
        case .extended24h: return 24
        case .extended36h: return 36
        case .extended48h: return 48
        case .fiveTwo: return 16
        case .custom: return 0
        }
    }

    var eatingHours: Int {
        switch self {
        case .if16_8: return 8
        case .if18_6: return 6
        case .if20_4: return 4
        case .omad: return 1
        case .extended24h, .extended36h, .extended48h: return 0
        case .fiveTwo: return 8
        case .custom: return 0
        }
    }

    var difficulty: String {
        switch self {
        case .if16_8, .fiveTwo: return "Easy"
        case .if18_6: return "Moderate"
        case .if20_4, .omad, .extended24h: return "Advanced"
        case .extended36h, .extended48h: return "Expert"
        case .custom: return "Varies"
        }
    }

    var difficultyColor: String {
        switch self {
        case .if16_8, .fiveTwo: return "green"
        case .if18_6: return "yellow"
        case .if20_4, .omad, .extended24h: return "orange"
        case .extended36h, .extended48h: return "red"
        case .custom: return "blue"
        }
    }

    var icon: String {
        switch self {
        case .if16_8: return "clock"
        case .if18_6: return "clock.badge"
        case .if20_4: return "figure.strengthtraining.traditional"
        case .omad: return "fork.knife.circle"
        case .extended24h: return "24.circle"
        case .extended36h: return "36.circle"
        case .extended48h: return "48.circle"
        case .fiveTwo: return "calendar"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Fasting Status

enum FastingStatus: String, Codable {
    case active
    case completed
    case cancelled
}

// MARK: - Fasting Session

struct FastingSession: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let `protocol`: String
    let startedAt: Date
    let targetEndAt: Date
    var actualEndAt: Date?
    let status: String
    let durationHours: Double
    var notes: String?
    let createdAt: Date

    // Computed fields from API
    var elapsedSeconds: Int
    var remainingSeconds: Int
    var progressPercentage: Double

    var fastingProtocol: FastingProtocol {
        FastingProtocol(rawValue: `protocol`) ?? .custom
    }

    var fastingStatus: FastingStatus {
        FastingStatus(rawValue: status) ?? .active
    }

    var isActive: Bool {
        fastingStatus == .active
    }

    var isCompleted: Bool {
        fastingStatus == .completed
    }

    var formattedElapsed: String {
        formatDuration(seconds: elapsedSeconds)
    }

    var formattedRemaining: String {
        formatDuration(seconds: remainingSeconds)
    }

    private func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Fasting Stats

struct FastingStats: Codable {
    let currentFastingStreak: Int
    let longestFastingStreak: Int
    let totalFastsCompleted: Int
    let totalHoursFasted: Double
    let averageFastDurationHours: Double
    let mostUsedProtocol: String?
    let thisWeekFasts: Int
    let thisMonthFasts: Int
    let fastsByProtocol: [String: Int]?
}

// MARK: - Fasting Settings

struct FastingSettings: Codable {
    let id: String
    let userId: String
    var preferredProtocol: String?
    var eatingWindowStart: String?
    var eatingWindowEnd: String?
    var notifyFastComplete: Bool
    var notifyReminderBeforeMin: Int
    var fastingDaysOfWeek: [Int]?
    var fastingCalorieLimit: Int?
    var currentFastingStreak: Int
    var longestFastingStreak: Int
    var lastFastCompletedAt: Date?
}

// MARK: - Active Fast Response

struct ActiveFastResponse: Codable {
    let isFasting: Bool
    let session: FastingSession?
    let eatingWindowActive: Bool
    let nextEatingWindowStarts: Date?
    let nextEatingWindowEnds: Date?
}

// MARK: - Fasting History Response

struct FastingHistoryResponse: Codable {
    let items: [FastingSession]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

// MARK: - Protocol Info

struct FastingProtocolInfo: Codable, Identifiable {
    let `protocol`: String
    let name: String
    let description: String
    let fastingHours: Int
    let eatingHours: Int
    let difficulty: String
    let recommendedFor: [String]

    var id: String { `protocol` }
}

// MARK: - Request Models

struct StartFastRequest: Codable {
    let `protocol`: String
    let durationHours: Double?
    let notes: String?

    init(protocol: FastingProtocol, durationHours: Double? = nil, notes: String? = nil) {
        self.protocol = `protocol`.rawValue
        self.durationHours = durationHours
        self.notes = notes
    }
}

struct StopFastRequest: Codable {
    let completed: Bool
    let notes: String?
}

struct UpdateFastingSettingsRequest: Codable {
    var preferredProtocol: String?
    var eatingWindowStart: String?
    var eatingWindowEnd: String?
    var notifyFastComplete: Bool?
    var notifyReminderBeforeMin: Int?
    var fastingDaysOfWeek: [Int]?
    var fastingCalorieLimit: Int?
}
