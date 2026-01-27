import SwiftUI

/// Modern game-like chat message bubble
struct ChatBubble: View {
    let message: ChatMessage
    let onConfirm: ((String, String) -> Void)?
    let onApprovePlan: ((PlanPreview) -> Void)?

    @State private var appeared = false

    init(
        message: ChatMessage,
        onConfirm: ((String, String) -> Void)? = nil,
        onApprovePlan: ((PlanPreview) -> Void)? = nil
    ) {
        self.message = message
        self.onConfirm = onConfirm
        self.onApprovePlan = onApprovePlan
    }

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
                // Reppy name tag
                HStack(spacing: 6) {
                    Text("Reppy")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                }

                // Plan preview card (if present)
                if let plan = message.planPreview {
                    PlanPreviewCard(
                        plan: plan,
                        onApprove: {
                            onApprovePlan?(plan)
                        },
                        onEdit: nil
                    )
                } else {
                    // Message content with better styling
                    Text(message.content)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }

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
    @State private var showAllNutrients = false

    // Helper to get numeric value
    private func getDouble(_ key: String) -> Double {
        if let d = data[key]?.value as? Double { return d }
        if let i = data[key]?.value as? Int { return Double(i) }
        return 0
    }

    private var items: [[String: Any]] { data["items"]?.value as? [[String: Any]] ?? [] }
    private var calories: Int { Int(getDouble("calories")) }
    private var protein: Double { getDouble("protein_g") }
    private var carbs: Double { getDouble("carbs_g") }
    private var fat: Double { getDouble("fat_g") }
    private var sugar: Double { getDouble("sugar_g") }
    private var fiber: Double { getDouble("fiber_g") }
    private var sodium: Double { getDouble("sodium_mg") }
    private var saturatedFat: Double { getDouble("saturated_fat_g") }
    private var cholesterol: Double { getDouble("cholesterol_mg") }
    private var vitaminA: Double { getDouble("vitamin_a_mcg") }
    private var vitaminC: Double { getDouble("vitamin_c_mg") }
    private var vitaminD: Double { getDouble("vitamin_d_mcg") }
    private var vitaminB12: Double { getDouble("vitamin_b12_mcg") }
    private var calcium: Double { getDouble("calcium_mg") }
    private var iron: Double { getDouble("iron_mg") }
    private var potassium: Double { getDouble("potassium_mg") }

    // Health score calculation (0-100)
    private var healthScore: Int {
        var score = 50 // Start neutral

        // Protein is good (+)
        if protein > 20 { score += 15 }
        else if protein > 10 { score += 8 }

        // Fiber is good (+)
        if fiber > 5 { score += 12 }
        else if fiber > 2 { score += 6 }

        // Vitamins are good (+)
        if vitaminC > 10 { score += 5 }
        if vitaminA > 100 { score += 5 }
        if vitaminD > 1 { score += 5 }
        if iron > 1 { score += 5 }
        if calcium > 50 { score += 5 }
        if potassium > 200 { score += 5 }

        // Sugar is bad (-)
        if sugar > 25 { score -= 20 }
        else if sugar > 15 { score -= 10 }
        else if sugar > 8 { score -= 5 }

        // Saturated fat is bad (-)
        if saturatedFat > 10 { score -= 15 }
        else if saturatedFat > 5 { score -= 8 }

        // Sodium is bad if high (-)
        if sodium > 800 { score -= 12 }
        else if sodium > 500 { score -= 6 }

        // Cholesterol (moderate concern)
        if cholesterol > 200 { score -= 8 }
        else if cholesterol > 100 { score -= 4 }

        return min(100, max(0, score))
    }

    private var scoreColor: Color {
        if healthScore >= 70 { return .green }
        if healthScore >= 50 { return .yellow }
        if healthScore >= 30 { return .orange }
        return .red
    }

    private var scoreLabel: String {
        if healthScore >= 70 { return "Great" }
        if healthScore >= 50 { return "Good" }
        if healthScore >= 30 { return "OK" }
        return "Poor"
    }

    private var hasExtendedNutrients: Bool {
        sugar > 0 || fiber > 0 || sodium > 0 || saturatedFat > 0 ||
        vitaminA > 0 || vitaminC > 0 || vitaminD > 0 || vitaminB12 > 0 ||
        calcium > 0 || iron > 0 || potassium > 0
    }

    var body: some View {
        VStack(spacing: 14) {
            // Health Score Badge
            HStack {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.3), lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: Double(healthScore) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(healthScore)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(scoreLabel)
                        .font(.subheadline.bold())
                        .foregroundColor(scoreColor)
                    Text("Health Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Quick macro summary
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(calories) cal")
                        .font(.title3.bold())
                    Text("\(Int(protein))P • \(Int(carbs))C • \(Int(fat))F")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Main Macros - compact grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                MacroCell(label: "Protein", value: "\(Int(protein))g", color: .blue, icon: "p.circle.fill")
                MacroCell(label: "Carbs", value: "\(Int(carbs))g", color: .green, icon: "c.circle.fill")
                MacroCell(label: "Fat", value: "\(Int(fat))g", color: .purple, icon: "f.circle.fill")
                MacroCell(label: "Fiber", value: "\(Int(fiber))g", color: .mint, icon: "leaf.fill")
            }

            // Expandable nutrients section
            if hasExtendedNutrients {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showAllNutrients.toggle()
                    }
                } label: {
                    HStack {
                        Text(showAllNutrients ? "Hide Details" : "Show All Nutrients")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Image(systemName: showAllNutrients ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                }

                if showAllNutrients {
                    VStack(spacing: 10) {
                        // Micronutrients to watch
                        if sugar > 0 || sodium > 0 || saturatedFat > 0 || cholesterol > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Watch")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)

                                HStack(spacing: 6) {
                                    if sugar > 0 {
                                        NutrientBadge(name: "Sugar", value: "\(Int(sugar))g", isGood: sugar < 10)
                                    }
                                    if sodium > 0 {
                                        NutrientBadge(name: "Sodium", value: "\(Int(sodium))mg", isGood: sodium < 400)
                                    }
                                    if saturatedFat > 0 {
                                        NutrientBadge(name: "Sat Fat", value: "\(Int(saturatedFat))g", isGood: saturatedFat < 5)
                                    }
                                    if cholesterol > 0 {
                                        NutrientBadge(name: "Chol", value: "\(Int(cholesterol))mg", isGood: cholesterol < 100)
                                    }
                                }
                            }
                        }

                        // Vitamins
                        if vitaminA > 0 || vitaminC > 0 || vitaminD > 0 || vitaminB12 > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Vitamins")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)

                                HStack(spacing: 6) {
                                    if vitaminA > 0 {
                                        NutrientBadge(name: "A", value: "\(Int(vitaminA))mcg", isGood: true)
                                    }
                                    if vitaminC > 0 {
                                        NutrientBadge(name: "C", value: "\(Int(vitaminC))mg", isGood: true)
                                    }
                                    if vitaminD > 0 {
                                        NutrientBadge(name: "D", value: String(format: "%.1f", vitaminD), isGood: true)
                                    }
                                    if vitaminB12 > 0 {
                                        NutrientBadge(name: "B12", value: String(format: "%.1f", vitaminB12), isGood: true)
                                    }
                                }
                            }
                        }

                        // Minerals
                        if calcium > 0 || iron > 0 || potassium > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Minerals")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)

                                HStack(spacing: 6) {
                                    if calcium > 0 {
                                        NutrientBadge(name: "Calcium", value: "\(Int(calcium))mg", isGood: true)
                                    }
                                    if iron > 0 {
                                        NutrientBadge(name: "Iron", value: String(format: "%.1f", iron), isGood: true)
                                    }
                                    if potassium > 0 {
                                        NutrientBadge(name: "K", value: "\(Int(potassium))mg", isGood: true)
                                    }
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Food items (compact)
            if !items.isEmpty {
                VStack(spacing: 4) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, item in
                        if let name = item["name"] as? String {
                            HStack {
                                Text("• \(name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    if items.count > 3 {
                        Text("+\(items.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Macro Cell Component

private struct MacroCell: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.caption.bold())

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Nutrient Badge Component (for meal confirmation)

private struct NutrientBadge: View {
    let name: String
    let value: String
    let isGood: Bool

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(isGood ? Color.green : Color.orange)
                .frame(width: 5, height: 5)

            Text("\(name): \(value)")
                .font(.system(size: 10))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(6)
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
