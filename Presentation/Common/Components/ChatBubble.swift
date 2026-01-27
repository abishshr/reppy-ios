import SwiftUI

/// Modern game-like chat message bubble
struct ChatBubble: View {
    let message: ChatMessage
    let onConfirm: ((String, String) -> Void)?

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.role == .assistant {
                assistantMessage
            } else {
                userMessage
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    // MARK: - User Message (Right-aligned, game-like bubble)

    private var userMessage: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer(minLength: 50)

            VStack(alignment: .trailing, spacing: 6) {
                // Attached image with glow
                if let image = message.attachedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                }

                // Message bubble with gradient
                HStack(spacing: 0) {
                    Text(cleanedContent)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(BubbleShape(isUser: true))
                .shadow(color: .purple.opacity(0.25), radius: 6, y: 3)

                // Timestamp
                Text(message.timestamp.timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // User avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Assistant Message (Game-like coach style)

    private var assistantMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            // Coach avatar with animated ring
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 38, height: 38)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "figure.run")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 10) {
                // Coach name tag
                HStack(spacing: 6) {
                    Text("Coach")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                }

                // Message content with better styling
                Text(message.content)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)

                // Pending confirmation card
                if let pending = message.pendingConfirmation {
                    GameConfirmationCard(
                        type: pending.type,
                        suggestionId: pending.suggestionId,
                        data: pending.data as? [String: AnyCodable],
                        onConfirm: onConfirm
                    )
                }

                // Timestamp
                Text(message.timestamp.timeString)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
    }

    private var cleanedContent: String {
        message.content.replacingOccurrences(of: "[Photo attached] ", with: "")
    }
}

// MARK: - Bubble Shape with Tail

struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        var path = Path()

        if isUser {
            // User bubble (right side tail)
            path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width - 6, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
        } else {
            // Assistant bubble (left side tail)
            path.addRoundedRect(in: CGRect(x: 6, y: 0, width: rect.width - 6, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
        }

        return path
    }
}

// MARK: - Game-Style Confirmation Card

struct GameConfirmationCard: View {
    let type: ConfirmationType
    let suggestionId: String
    let data: [String: AnyCodable]?
    let onConfirm: ((String, String) -> Void)?

    @State private var isConfirming = false
    @State private var showSuccess = false

    private var accentColor: Color {
        type == .meal ? .orange : .blue
    }

    private var gradientColors: [Color] {
        type == .meal ? [.orange, .red] : [.blue, .purple]
    }

    var body: some View {
        VStack(spacing: 14) {
            // XP-style header
            HStack(spacing: 12) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: type == .meal ? "fork.knife" : "dumbbell.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: accentColor.opacity(0.4), radius: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type == .meal ? "MEAL READY" : "WORKOUT READY")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(accentColor)
                        .tracking(1)

                    Text("Confirm to earn XP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // XP badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("+\(xpValue)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.15))
                .clipShape(Capsule())
            }

            // Details
            if let data = data {
                if type == .workout {
                    WorkoutConfirmationDetails(data: data)
                } else {
                    MealConfirmationDetails(data: data)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                // Confirm button with gradient
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isConfirming = true
                    }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onConfirm?(type.rawValue, suggestionId)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        isConfirming = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isConfirming {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(isConfirming ? "Logging..." : "Log It!")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: isConfirming ? [.gray] : gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: accentColor.opacity(isConfirming ? 0 : 0.4), radius: 8, y: 4)
                }
                .disabled(isConfirming)
                .scaleEffect(isConfirming ? 0.98 : 1)

                // Edit button
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 48, height: 48)
                        .background(Color(.tertiarySystemFill))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var xpValue: Int {
        if type == .meal {
            let calories = data?["calories"]?.value as? Int ?? 0
            return max(10, calories / 20)
        } else {
            let exercises = data?["exercises"]?.value as? [[String: Any]] ?? []
            return max(15, exercises.count * 10)
        }
    }
}

// Wrapper for backward compatibility
struct ConfirmationCard: View {
    let type: ConfirmationType
    let suggestionId: String
    let data: [String: AnyCodable]?
    let onConfirm: ((String, String) -> Void)?

    var body: some View {
        GameConfirmationCard(
            type: type,
            suggestionId: suggestionId,
            data: data,
            onConfirm: onConfirm
        )
    }
}

// MARK: - Workout Confirmation Details

struct WorkoutConfirmationDetails: View {
    let data: [String: AnyCodable]

    private var exercises: [[String: Any]] {
        data["exercises"]?.value as? [[String: Any]] ?? []
    }

    private var duration: Int {
        data["duration_min"]?.value as? Int ??
        data["estimated_duration_min"]?.value as? Int ?? 0
    }

    private var calories: Int {
        data["calories_burned_est"]?.value as? Int ??
        data["estimated_calories_burned"]?.value as? Int ?? 0
    }

    var body: some View {
        VStack(spacing: 12) {
            // Stats chips
            HStack(spacing: 8) {
                StatChip(icon: "dumbbell.fill", value: "\(exercises.count)", label: "exercises", color: .blue)
                StatChip(icon: "clock.fill", value: "\(duration)", label: "min", color: .purple)
                StatChip(icon: "flame.fill", value: "\(calories)", label: "cal", color: .orange)
            }

            // Exercise list
            if !exercises.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(exercises.prefix(4).enumerated()), id: \.offset) { _, exercise in
                        if let name = exercise["name"] as? String {
                            HStack {
                                Text(name)
                                    .font(.subheadline)

                                Spacer()

                                if let sets = exercise["sets"] as? Int, sets > 0,
                                   let reps = exercise["reps"] as? Int, reps > 0 {
                                    Text("\(sets) x \(reps)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.tertiarySystemFill))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    if exercises.count > 4 {
                        Text("+\(exercises.count - 4) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Meal Confirmation Details

struct MealConfirmationDetails: View {
    let data: [String: AnyCodable]

    private var items: [[String: Any]] {
        data["items"]?.value as? [[String: Any]] ?? []
    }

    private var calories: Int {
        data["calories"]?.value as? Int ?? Int(data["calories"]?.value as? Double ?? 0)
    }

    private var protein: Double {
        // Handle both Int and Double from backend
        if let doubleValue = data["protein_g"]?.value as? Double {
            return doubleValue
        } else if let intValue = data["protein_g"]?.value as? Int {
            return Double(intValue)
        }
        return 0
    }

    private var carbs: Double {
        // Handle both Int and Double from backend
        if let doubleValue = data["carbs_g"]?.value as? Double {
            return doubleValue
        } else if let intValue = data["carbs_g"]?.value as? Int {
            return Double(intValue)
        }
        return 0
    }

    private var fat: Double {
        // Handle both Int and Double from backend
        if let doubleValue = data["fat_g"]?.value as? Double {
            return doubleValue
        } else if let intValue = data["fat_g"]?.value as? Int {
            return Double(intValue)
        }
        return 0
    }

    // Micronutrients
    private var sugar: Double {
        if let doubleValue = data["sugar_g"]?.value as? Double { return doubleValue }
        if let intValue = data["sugar_g"]?.value as? Int { return Double(intValue) }
        return 0
    }

    private var fiber: Double {
        if let doubleValue = data["fiber_g"]?.value as? Double { return doubleValue }
        if let intValue = data["fiber_g"]?.value as? Int { return Double(intValue) }
        return 0
    }

    private var sodium: Double {
        if let doubleValue = data["sodium_mg"]?.value as? Double { return doubleValue }
        if let intValue = data["sodium_mg"]?.value as? Int { return Double(intValue) }
        return 0
    }

    private var saturatedFat: Double {
        if let doubleValue = data["saturated_fat_g"]?.value as? Double { return doubleValue }
        if let intValue = data["saturated_fat_g"]?.value as? Int { return Double(intValue) }
        return 0
    }

    private var hasMicronutrients: Bool {
        sugar > 0 || fiber > 0 || sodium > 0 || saturatedFat > 0
    }

    var body: some View {
        VStack(spacing: 12) {
            // Macro chips
            HStack(spacing: 8) {
                StatChip(icon: "flame.fill", value: "\(calories)", label: "cal", color: .orange)
                StatChip(icon: "p.circle.fill", value: "\(Int(protein))", label: "g", color: .blue)
                StatChip(icon: "c.circle.fill", value: "\(Int(carbs))", label: "g", color: .green)
                StatChip(icon: "f.circle.fill", value: "\(Int(fat))", label: "g", color: .purple)
            }

            // Micronutrient chips (if available)
            if hasMicronutrients {
                HStack(spacing: 8) {
                    if sugar > 0 {
                        MicroChip(label: "Sugar", value: "\(Int(sugar))g", color: .pink)
                    }
                    if fiber > 0 {
                        MicroChip(label: "Fiber", value: "\(Int(fiber))g", color: .green)
                    }
                    if sodium > 0 {
                        MicroChip(label: "Sodium", value: "\(Int(sodium))mg", color: .gray)
                    }
                    if saturatedFat > 0 {
                        MicroChip(label: "Sat Fat", value: "\(Int(saturatedFat))g", color: .red)
                    }
                }
            }

            // Food items
            if !items.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(items.prefix(4).enumerated()), id: \.offset) { _, item in
                        if let name = item["name"] as? String {
                            HStack {
                                Text(name)
                                    .font(.subheadline)

                                Spacer()

                                if let itemCals = item["calories"] as? Int {
                                    Text("\(itemCals) cal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    if items.count > 4 {
                        Text("+\(items.count - 4) more items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Stat Chip Component

struct StatChip: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)

            Text(value)
                .font(.caption.weight(.semibold))

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Micro Chip Component (for micronutrients)

struct MicroChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            ChatBubble(
                message: ChatMessage(
                    role: .user,
                    content: "I just had 2 eggs and some toast for breakfast"
                ),
                onConfirm: nil
            )

            ChatBubble(
                message: ChatMessage(
                    role: .assistant,
                    content: "Got it! I've logged your breakfast. That's about 280 calories with 18g protein. Great start to the day!"
                ),
                onConfirm: nil
            )

            ChatBubble(
                message: ChatMessage(
                    role: .user,
                    content: "Just finished chest day at the gym"
                ),
                onConfirm: nil
            )
        }
    }
}
