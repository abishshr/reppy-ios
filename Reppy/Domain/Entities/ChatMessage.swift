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

    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        toolCalls: [ToolCallResult]? = nil,
        pendingConfirmation: PendingConfirmation? = nil,
        attachedImage: UIImage? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolCalls = toolCalls
        self.pendingConfirmation = pendingConfirmation
        self.attachedImage = attachedImage
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content &&
        lhs.timestamp == rhs.timestamp &&
        lhs.toolCalls == rhs.toolCalls &&
        lhs.pendingConfirmation == rhs.pendingConfirmation
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
