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
    @Published var loadingMessage: String?

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
            content: "Hey! I'm Reppy 👋 Tell me what you ate or what workout you did, and I'll help log it for you!"
        ))
    }

    // MARK: - Actions

    func sendMessage(_ text: String, displayText: String? = nil, withImage: Bool = false) async {
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

        // Add user message - use displayText if provided (for simplified display), otherwise use actual text
        let messageToShow = displayText ?? trimmedText
        let displayContent = attachedImage != nil ? "[Photo attached] \(messageToShow)" : messageToShow
        let userMessage = ChatMessage(role: .user, content: displayContent, attachedImage: attachedImage)
        messages.append(userMessage)
        print("[ChatViewModel] Added user message, total messages: \(messages.count)")

        isLoading = true

        // Set loading message based on message content
        let lowerText = trimmedText.lowercased()
        if lowerText.contains("meal plan") || lowerText.contains("create a") && lowerText.contains("plan") {
            loadingMessage = "Creating your personalized plan..."
        } else if lowerText.contains("workout") && (lowerText.contains("create") || lowerText.contains("plan")) {
            loadingMessage = "Designing your workout program..."
        } else if attachedImage != nil {
            loadingMessage = "Analyzing your photo..."
        } else {
            loadingMessage = nil
        }

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

            // Parse plan preview from tool calls
            let planPreview = parsePlanPreview(from: response.toolCalls)

            // Add assistant response
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: response.message,
                toolCalls: response.toolCalls,
                pendingConfirmation: pendingConfirmation,
                planPreview: planPreview
            )
            messages.append(assistantMessage)

        } catch {
            print("[ChatViewModel] Error: \(error)")
            print("[ChatViewModel] Error localizedDescription: \(error.localizedDescription)")
            errorMessage = error.localizedDescription

            messages.append(ChatMessage(
                role: .assistant,
                content: "Sorry, I had trouble processing that. Please try again. (\(error.localizedDescription))"
            ))
        }

        isLoading = false
        loadingMessage = nil
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

    // MARK: - Plan Approval

    func approvePlan(_ plan: PlanPreview) async {
        print("[ChatViewModel] approvePlan called for: \(plan.name)")
        isLoading = true

        // Check if plan is already saved (no confirmation needed)
        if let savedPlanId = plan.savedPlanId {
            print("[ChatViewModel] Plan already saved with ID: \(savedPlanId)")

            // Remove the plan preview from the message
            if let index = messages.firstIndex(where: { $0.planPreview?.id == plan.id }) {
                messages[index].planPreview = nil
            }

            let planType = plan.type == .meal ? "meal" : "workout"
            messages.append(ChatMessage(
                role: .assistant,
                content: "Your \(planType) plan has been saved! You can view it in the \(plan.type == .meal ? "Meal Plan" : "Workout") tab."
            ))

            // Notify other views to refresh
            if plan.type == .meal {
                NotificationCenter.default.post(name: .mealLogged, object: nil)
            } else {
                NotificationCenter.default.post(name: .workoutLogged, object: nil)
            }

            isLoading = false
            return
        }

        // Fallback: try to confirm via API if we have a suggestionId
        do {
            let type = plan.type == .meal ? "meal_plan" : "workout_plan"
            guard let suggestionId = plan.suggestionId else {
                print("[ChatViewModel] No suggestionId or savedPlanId found for plan")
                isLoading = false
                return
            }

            let response = try await container.chatRepository.confirmSuggestion(
                type: type,
                suggestionId: suggestionId,
                sessionId: sessionId
            )

            print("[ChatViewModel] Plan approval successful: \(response.message)")

            // Remove the plan preview from the message
            if let index = messages.firstIndex(where: { $0.planPreview?.id == plan.id }) {
                messages[index].planPreview = nil
            }

            messages.append(ChatMessage(
                role: .assistant,
                content: response.message
            ))

            // Notify other views
            if plan.type == .meal {
                NotificationCenter.default.post(name: .mealLogged, object: nil)
            } else {
                NotificationCenter.default.post(name: .workoutLogged, object: nil)
            }

        } catch {
            print("[ChatViewModel] Plan approval error: \(error)")
            errorMessage = error.localizedDescription

            messages.append(ChatMessage(
                role: .assistant,
                content: "Sorry, I couldn't save the plan. Please try again."
            ))
        }

        isLoading = false
    }

    // MARK: - Plan Parsing

    private func parsePlanPreview(from toolCalls: [ToolCallResult]?) -> PlanPreview? {
        guard let toolCalls = toolCalls else {
            print("[ChatViewModel] No tool calls to parse")
            return nil
        }

        print("[ChatViewModel] Parsing \(toolCalls.count) tool calls for plan preview")

        for call in toolCalls {
            print("[ChatViewModel] Tool call: \(call.toolName), status: \(call.status), hasResult: \(call.result != nil)")

            if call.toolName == "generate_meal_plan" || call.toolName == "generate_workout_plan" {
                print("[ChatViewModel] Found plan tool: \(call.toolName)")
                guard call.status == "success", let result = call.result else {
                    print("[ChatViewModel] Skipping - status not success or no result")
                    continue
                }

                print("[ChatViewModel] Result keys: \(result.keys.joined(separator: ", "))")

                let isMealPlan = call.toolName == "generate_meal_plan"
                let planType: PlanType = isMealPlan ? .meal : .workout

                // Extract plan name
                let planName = (result["name"]?.value as? String) ??
                               (isMealPlan ? "Meal Plan" : "Workout Plan")

                // Extract plan data - could be in "plan" or "days" key
                var days: [PlanDayPreview] = []

                // Debug: Check what type the plan value is
                if let planValue = result["plan"]?.value {
                    print("[ChatViewModel] Plan value type: \(type(of: planValue))")

                    if let planData = planValue as? [[String: Any]] {
                        print("[ChatViewModel] Found plan as [[String: Any]] with \(planData.count) days")
                        days = parseDays(from: planData, isMealPlan: isMealPlan)
                    } else if let planArray = planValue as? [Any] {
                        print("[ChatViewModel] Found plan as [Any] with \(planArray.count) elements")
                        // Try to convert [Any] to [[String: Any]]
                        let converted = planArray.compactMap { $0 as? [String: Any] }
                        print("[ChatViewModel] Converted to \(converted.count) dictionaries")
                        days = parseDays(from: converted, isMealPlan: isMealPlan)
                    } else {
                        print("[ChatViewModel] Plan value is neither [[String: Any]] nor [Any]")
                    }
                } else if let daysValue = result["days"]?.value {
                    print("[ChatViewModel] Days value type: \(type(of: daysValue))")
                    if let daysData = daysValue as? [[String: Any]] {
                        days = parseDays(from: daysData, isMealPlan: isMealPlan)
                    } else if let daysArray = daysValue as? [Any] {
                        let converted = daysArray.compactMap { $0 as? [String: Any] }
                        days = parseDays(from: converted, isMealPlan: isMealPlan)
                    }
                } else {
                    print("[ChatViewModel] No 'plan' or 'days' key found in result")
                }

                // If no days found, skip
                if days.isEmpty {
                    print("[ChatViewModel] No days parsed, skipping plan preview")
                    continue
                }

                print("[ChatViewModel] Successfully parsed \(days.count) days")

                // Calculate totals
                let totalCalories = days.reduce(0) { $0 + ($1.totalCalories ?? 0) }
                let totalProtein = days.reduce(0.0) { $0 + ($1.totalProtein ?? 0) }

                // Extract saved plan ID (plan is already saved when tool succeeds)
                let savedPlanId = (result["meal_plan_id"]?.value as? String) ??
                                  (result["workout_plan_id"]?.value as? String)

                return PlanPreview(
                    id: UUID().uuidString,
                    type: planType,
                    name: planName,
                    days: days,
                    totalCalories: totalCalories > 0 ? totalCalories : nil,
                    totalProtein: totalProtein > 0 ? totalProtein : nil,
                    durationDays: days.count,
                    suggestionId: call.suggestionId,
                    savedPlanId: savedPlanId
                )
            }
        }

        return nil
    }

    private func parseDays(from daysData: [[String: Any]], isMealPlan: Bool) -> [PlanDayPreview] {
        var days: [PlanDayPreview] = []
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        for (index, dayData) in daysData.enumerated() {
            let dayNumber = (dayData["day_number"] as? Int) ?? (index + 1)
            let dayName = (dayData["day_name"] as? String) ??
                          (dayData["date"] as? String) ??
                          weekdays[(dayNumber - 1) % 7]

            var items: [PlanItemPreview] = []

            if isMealPlan {
                // Parse meals - handle both [Any] and [[String: Any]] due to AnyCodable unwrapping
                let mealsArray: [[String: Any]]
                if let meals = dayData["meals"] as? [[String: Any]] {
                    mealsArray = meals
                } else if let mealsAny = dayData["meals"] as? [Any] {
                    mealsArray = mealsAny.compactMap { $0 as? [String: Any] }
                } else {
                    mealsArray = []
                }

                for meal in mealsArray {
                    let mealType = (meal["type"] as? String) ?? "meal"
                    let mealName = (meal["name"] as? String) ?? "Meal"
                    // Handle both Int and Double for calories
                    let calories: Int?
                    if let cal = meal["calories"] as? Int {
                        calories = cal
                    } else if let cal = meal["calories"] as? Double {
                        calories = Int(cal)
                    } else {
                        calories = nil
                    }
                    // Handle both Double and Int for protein
                    let protein: Double?
                    if let prot = meal["protein_g"] as? Double {
                        protein = prot
                    } else if let prot = meal["protein_g"] as? Int {
                        protein = Double(prot)
                    } else {
                        protein = nil
                    }

                    items.append(PlanItemPreview(
                        itemType: mealType,
                        name: mealName,
                        calories: calories,
                        protein: protein
                    ))
                }
            } else {
                // Parse exercises - handle both [Any] and [[String: Any]] due to AnyCodable unwrapping
                let exercisesArray: [[String: Any]]
                if let exercises = dayData["exercises"] as? [[String: Any]] {
                    exercisesArray = exercises
                } else if let exercisesAny = dayData["exercises"] as? [Any] {
                    exercisesArray = exercisesAny.compactMap { $0 as? [String: Any] }
                } else {
                    exercisesArray = []
                }

                for exercise in exercisesArray {
                    let name = (exercise["name"] as? String) ?? "Exercise"
                    let sets = exercise["sets"] as? Int
                    let reps = exercise["reps"] as? String ?? "\(exercise["reps"] as? Int ?? 0)"

                    items.append(PlanItemPreview(
                        itemType: "exercise",
                        name: name,
                        sets: sets,
                        reps: reps
                    ))
                }
            }

            // Handle both Int and Double for totals
            let totalCal: Int
            if let cal = dayData["total_calories"] as? Int {
                totalCal = cal
            } else if let cal = dayData["total_calories"] as? Double {
                totalCal = Int(cal)
            } else {
                totalCal = items.reduce(0) { $0 + ($1.calories ?? 0) }
            }

            let totalProt: Double
            if let prot = dayData["total_protein"] as? Double {
                totalProt = prot
            } else if let prot = dayData["total_protein"] as? Int {
                totalProt = Double(prot)
            } else {
                totalProt = items.reduce(0.0) { $0 + ($1.protein ?? 0) }
            }

            days.append(PlanDayPreview(
                dayNumber: dayNumber,
                dayName: dayName,
                items: items,
                totalCalories: totalCal > 0 ? totalCal : nil,
                totalProtein: totalProt > 0 ? totalProt : nil
            ))
        }

        return days
    }
}
