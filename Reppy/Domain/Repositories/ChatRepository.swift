import Foundation

/// Protocol for chat repository
protocol ChatRepository {
    func sendMessage(_ message: String, sessionId: String?, imageBase64: String?) async throws -> ChatAPIResponse
    func confirmSuggestion(type: String, suggestionId: String, sessionId: String?) async throws -> ConfirmationResponse
}

/// Implementation of ChatRepository
final class ChatRepositoryImpl: ChatRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func sendMessage(_ message: String, sessionId: String?, imageBase64: String? = nil) async throws -> ChatAPIResponse {
        try await apiClient.sendMessage(message, sessionId: sessionId, imageBase64: imageBase64)
    }

    func confirmSuggestion(type: String, suggestionId: String, sessionId: String?) async throws -> ConfirmationResponse {
        try await apiClient.confirmSuggestion(type: type, suggestionId: suggestionId, sessionId: sessionId)
    }
}
