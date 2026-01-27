import SwiftUI
import UIKit

extension Notification.Name {
    static let mealLogged = Notification.Name("mealLogged")
    static let workoutLogged = Notification.Name("workoutLogged")
    static let requestMealSuggestion = Notification.Name("requestMealSuggestion")
}

@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var selectedImage: UIImage?

    // MARK: - Private Properties

    private var sessionId: String?
    private let container = DependencyContainer.shared
    private lazy var speechService = SpeechService()
    private lazy var imageService = ImageService()

    // MARK: - Initialization

    init() {
        addWelcomeMessage()
    }

    private func addWelcomeMessage() {
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hi! I'm your Reppy coach. Tell me what you ate or what workout you did, and I'll help you log it. You can also ask for meal or workout suggestions!"
        ))
    }

    // MARK: - Actions

    func sendMessage(_ text: String, withImage: Bool = false) async {
        print("[ChatViewModel] sendMessage called with: '\(text)', withImage: \(withImage)")
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            print("[ChatViewModel] Empty text, returning")
            return
        }

        // Get image base64 if present
        var imageBase64: String?
        let attachedImage = selectedImage
        if withImage, let image = attachedImage {
            imageBase64 = imageService.imageToBase64(image)
            print("[ChatViewModel] Image attached, base64 length: \(imageBase64?.count ?? 0)")
        }

        // Clear selected image after capturing
        selectedImage = nil

        // Add user message (with image indicator if present)
        let displayText = attachedImage != nil ? "[Photo attached] \(trimmedText)" : trimmedText
        let userMessage = ChatMessage(role: .user, content: displayText, attachedImage: attachedImage)
        messages.append(userMessage)
        print("[ChatViewModel] Added user message, total messages: \(messages.count)")

        isLoading = true

        do {
            print("[ChatViewModel] Calling chatRepository.sendMessage...")
            let response = try await container.chatRepository.sendMessage(trimmedText, sessionId: sessionId, imageBase64: imageBase64)
            print("[ChatViewModel] Got response message: '\(response.message)'")
            print("[ChatViewModel] Response message length: \(response.message.count)")
            print("[ChatViewModel] Response sessionId: \(response.sessionId)")
            sessionId = response.sessionId

            // Parse pending confirmation
            var pendingConfirmation: PendingConfirmation?
            if let pending = response.pendingConfirmation,
               let suggestionId = pending["suggestion_id"]?.value as? String {
                // Determine type from backend response or message content
                let type: ConfirmationType
                if let typeString = pending["type"]?.value as? String {
                    type = typeString.lowercased() == "meal" ? .meal : .workout
                } else {
                    // Fallback: check for food-related keywords first
                    let message = response.message.lowercased()
                    let mealKeywords = ["meal", "food", "ate", "eat", "breakfast", "lunch", "dinner", "snack", "calories", "protein", "carbs", "eggs", "chicken", "rice"]
                    let isMeal = mealKeywords.contains { message.contains($0) }
                    type = isMeal ? .meal : .workout
                }
                pendingConfirmation = PendingConfirmation(
                    type: type,
                    suggestionId: suggestionId,
                    data: pending
                )
            }

            // Add assistant response
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: response.message,
                toolCalls: response.toolCalls,
                pendingConfirmation: pendingConfirmation
            )
            messages.append(assistantMessage)

        } catch {
            errorMessage = error.localizedDescription

            messages.append(ChatMessage(
                role: .assistant,
                content: "Sorry, I had trouble processing that. Please try again."
            ))
        }

        isLoading = false
    }

    func confirmSuggestion(type: String, suggestionId: String) async {
        print("[ChatViewModel] confirmSuggestion called - type: \(type), suggestionId: \(suggestionId)")
        isLoading = true

        do {
            print("[ChatViewModel] Calling chatRepository.confirmSuggestion...")
            let response = try await container.chatRepository.confirmSuggestion(
                type: type,
                suggestionId: suggestionId,
                sessionId: sessionId
            )

            print("[ChatViewModel] Confirmation successful: \(response.message)")

            // Remove pending confirmation from the message that has this suggestionId
            if let index = messages.firstIndex(where: { $0.pendingConfirmation?.suggestionId == suggestionId }) {
                messages[index].pendingConfirmation = nil
                print("[ChatViewModel] Removed pendingConfirmation from message at index \(index)")
            }

            messages.append(ChatMessage(
                role: .assistant,
                content: response.message
            ))

            // Notify other views to refresh
            if type == "meal" {
                print("[ChatViewModel] Posting .mealLogged notification")
                NotificationCenter.default.post(name: .mealLogged, object: nil)
            } else if type == "workout" {
                print("[ChatViewModel] Posting .workoutLogged notification")
                NotificationCenter.default.post(name: .workoutLogged, object: nil)
            }

        } catch {
            print("[ChatViewModel] Confirmation error: \(error)")
            errorMessage = error.localizedDescription

            messages.append(ChatMessage(
                role: .assistant,
                content: "Sorry, I couldn't confirm that. Please try again."
            ))
        }

        isLoading = false
    }

    func toggleRecording() async {
        if isRecording {
            speechService.stopRecording()
            isRecording = false

            let transcription = speechService.getTranscription()
            if !transcription.isEmpty {
                await sendMessage(transcription)
            }
        } else {
            do {
                let authorized = await speechService.requestAuthorization()
                guard authorized else {
                    errorMessage = "Speech recognition not authorized"
                    return
                }

                try await speechService.startRecording()
                isRecording = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func startNewSession() {
        sessionId = nil
        messages.removeAll()
        addWelcomeMessage()
    }
}
