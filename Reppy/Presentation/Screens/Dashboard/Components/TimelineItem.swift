import SwiftUI

/// Represents an item in the today timeline (meal or workout)
enum TimelineItemType {
    case plannedMeal(PlannedMeal)
    case loggedMeal(Meal)
    case plannedWorkout(WorkoutPlanDay)
    case loggedWorkout(Workout)

    var time: Date {
        switch self {
        case .plannedMeal(let meal):
            // Use meal type to estimate time
            return Calendar.current.date(bySettingHour: meal.mealType?.estimatedHour ?? 12, minute: 0, second: 0, of: Date()) ?? Date()
        case .loggedMeal(let meal):
            return meal.loggedAt
        case .plannedWorkout:
            return Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        case .loggedWorkout(let workout):
            return workout.loggedAt
        }
    }

    var isLogged: Bool {
        switch self {
        case .loggedMeal, .loggedWorkout:
            return true
        case .plannedMeal, .plannedWorkout:
            return false
        }
    }

    var sortOrder: Int {
        switch self {
        case .plannedMeal(let meal):
            return meal.mealType?.sortOrder ?? 99
        case .loggedMeal(let meal):
            return meal.mealType?.sortOrder ?? 99
        case .plannedWorkout, .loggedWorkout:
            return 50 // Middle of the day
        }
    }
}

// MARK: - MealType Extensions for Timeline

extension MealType {
    var sortOrder: Int {
        switch self {
        case .breakfast: return 10
        case .lunch: return 30
        case .snack: return 40
        case .dinner: return 60
        }
    }

    var estimatedHour: Int {
        switch self {
        case .breakfast: return 8
        case .lunch: return 12
        case .snack: return 15
        case .dinner: return 19
        }
    }
}

/// Single item row in the timeline
struct TimelineItemRow: View {
    let item: TimelineItemType
    var onLog: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var offset: CGFloat = 0
    private let deleteThreshold: CGFloat = -70

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            if offset < 0, onDelete != nil {
                HStack {
                    Spacer()
                    Button(action: { onDelete?() }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .frame(width: 50, height: 40)
                    }
                    .background(Color.red)
                    .cornerRadius(8)
                }
            }

            // Main content
            HStack(spacing: 12) {
                // Timeline connector
                VStack(spacing: 0) {
                    Circle()
                        .fill(isLogged ? Color.green : Color(.systemGray4))
                        .frame(width: 10, height: 10)
                        .overlay(
                            isLogged ? Image(systemName: "checkmark")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.white) : nil
                        )

                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: 10)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Time
                    Text(timeText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Title and info
                    HStack {
                        if isLogged {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }

                        Text(title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Log button for unlogged items
                        if !isLogged, onLog != nil {
                            Button(action: { onLog?() }) {
                                Text("Log")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(.systemBackground))
            .offset(x: offset)
            .gesture(
                onDelete != nil && !isLogged ?
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, deleteThreshold)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3)) {
                            if value.translation.width < deleteThreshold / 2 {
                                offset = deleteThreshold
                            } else {
                                offset = 0
                            }
                        }
                    }
                : nil
            )
        }
    }

    private var isLogged: Bool {
        item.isLogged
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: item.time)
    }

    private var title: String {
        switch item {
        case .plannedMeal(let meal):
            let typeName = meal.mealType?.displayName ?? meal.type.capitalized
            return "\(typeName) - \(meal.name)"
        case .loggedMeal(let meal):
            let mealName = meal.items.first?.name ?? meal.notes ?? "Meal"
            let typeName = meal.mealType?.displayName ?? ""
            return typeName.isEmpty ? mealName : "\(typeName) - \(mealName)"
        case .plannedWorkout(let workout):
            return "Workout - \(workout.displayName)"
        case .loggedWorkout(let workout):
            return "Workout - \(workout.workoutType?.displayName ?? "General")"
        }
    }

    private var subtitle: String {
        switch item {
        case .plannedMeal(let meal):
            return "\(meal.calories) cal"
        case .loggedMeal(let meal):
            return "\(meal.calories ?? 0) cal"
        case .plannedWorkout(let workout):
            let duration = workout.estimatedDurationMin ?? (workout.exercises.count * 3)
            return "\(duration) min"
        case .loggedWorkout(let workout):
            return "\(workout.durationMin ?? 0) min"
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        TimelineItemRow(
            item: .loggedMeal(Meal(
                id: "1",
                userId: "user1",
                loggedAt: Date(),
                mealType: .breakfast,
                items: [MealItem(name: "Oatmeal")],
                calories: 450,
                proteinG: 12,
                carbsG: 65,
                fatG: 14
            ))
        )

        TimelineItemRow(
            item: .plannedMeal(PlannedMeal(
                type: "lunch",
                name: "Grilled Chicken Salad",
                description: nil,
                calories: 520,
                proteinG: 45,
                carbsG: 20,
                fatG: 25,
                sugarG: nil,
                fiberG: nil,
                sodiumMg: nil,
                saturatedFatG: nil,
                cholesterolMg: nil,
                ingredients: nil,
                instructions: nil,
                prepTimeMin: nil,
                cookTimeMin: nil,
                difficulty: nil,
                tips: nil,
                nutritionNotes: nil,
                imageUrl: nil,
                imageSource: nil,
                imagePhotographer: nil,
                readyInMinutes: nil,
                servings: nil
            )),
            onLog: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
