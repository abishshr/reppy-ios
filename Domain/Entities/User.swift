import Foundation

/// User entity
struct User: Identifiable, Codable, Equatable {
    let id: String
    var email: String?
    var createdAt: Date?

    init(id: String, email: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}
