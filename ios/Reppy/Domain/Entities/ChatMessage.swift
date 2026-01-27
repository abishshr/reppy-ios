import Foundation
import UIKit

/// Chat message entity
struct ChatMessage: Identifiable, Equatable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var toolCalls: [ToolCallResult]?
    var pendingConfirmation: PendingConfirmation?
    var attachedImage: UIImage?
    var planPreview: PlanPreview?

    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        toolCalls: [ToolCallResult]? = nil,
        pendingConfirmation: PendingConfirmation? = nil,
        attachedImage: UIImage? = nil,
        planPreview: PlanPreview? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolCalls = toolCalls
        self.pendingConfirmation = pendingConfirmation
        self.attachedImage = attachedImage
        self.planPreview = planPreview
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content &&
        lhs.timestamp == rhs.timestamp &&
        lhs.toolCalls == rhs.toolCalls &&
        lhs.pendingConfirmation == rhs.pendingConfirmation &&
        lhs.planPreview == rhs.planPreview
    }
}

// MARK: - Plan Preview Models

/// Preview data for a meal or workout plan displayed in chat
struct PlanPreview: Equatable, Identifiable {
    let id: String
    let type: PlanType
    let name: String
    let days: [PlanDayPreview]
    let totalCalories: Int?
    let totalProtein: Double?
    let durationDays: Int
    let suggestionId: String?
    let savedPlanId: String?  // The plan is already saved if this is set

    var totalMeals: Int {
        days.reduce(0) { $0 + $1.items.count }
    }

    var totalExercises: Int {
        days.reduce(0) { $0 + $1.items.count }
    }

    static func == (lhs: PlanPreview, rhs: PlanPreview) -> Bool {
        lhs.id == rhs.id
    }
}

/// A single day in the plan preview
struct PlanDayPreview: Identifiable, Equatable {
    let id: String
    let dayNumber: Int
    let dayName: String
    let items: [PlanItemPreview]
    let totalCalories: Int?
    let totalProtein: Double?

    init(
        id: String = UUID().uuidString,
        dayNumber: Int,
        dayName: String,
        items: [PlanItemPreview],
        totalCalories: Int? = nil,
        totalProtein: Double? = nil
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.dayName = dayName
        self.items = items
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
    }
}

/// A single item (meal or exercise) in a day
struct PlanItemPreview: Identifiable, Equatable {
    let id: String
    let itemType: String  // breakfast, lunch, dinner, snack OR exercise name
    let name: String
    let calories: Int?
    let protein: Double?
    let sets: Int?
    let reps: String?
    let duration: Int?  // minutes for exercises

    init(
        id: String = UUID().uuidString,
        itemType: String,
        name: String,
        calories: Int? = nil,
        protein: Double? = nil,
        sets: Int? = nil,
        reps: String? = nil,
        duration: Int? = nil
    ) {
        self.id = id
        self.itemType = itemType
        self.name = name
        self.calories = calories
        self.protein = protein
        self.sets = sets
        self.reps = reps
        self.duration = duration
    }

    /// Icon for meal type
    var mealIcon: String {
        switch itemType.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }

    /// Color for meal type
    var mealColor: String {
        switch itemType.lowercased() {
        case "breakfast": return "orange"
        case "lunch": return "yellow"
        case "dinner": return "purple"
        case "snack": return "green"
        default: return "gray"
        }
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

/// Result of an AI tool call
struct ToolCallResult: Codable, Equatable {
    let toolName: String
    let status: String
    let result: [String: AnyCodable]?
    let error: String?
    let requiresConfirmation: Bool
    let suggestionId: String?
}

/// Pending confirmation for meal or workout
struct PendingConfirmation: Equatable {
    let type: ConfirmationType
    let suggestionId: String
    let data: Any

    static func == (lhs: PendingConfirmation, rhs: PendingConfirmation) -> Bool {
        lhs.type == rhs.type && lhs.suggestionId == rhs.suggestionId
    }
}

enum ConfirmationType: String {
    case meal
    case workout
}

/// Type-erased Codable wrapper
struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }
}
