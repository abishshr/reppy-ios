import SwiftUI

/// Timeline view showing today's meals and workouts
struct TodayTimeline: View {
    let plannedMeals: [PlannedMeal]
    let loggedMeals: [Meal]
    let plannedWorkout: WorkoutPlanDay?
    let loggedWorkouts: [Workout]
    var onLogMeal: ((PlannedMeal) -> Void)?
    var onDeleteMeal: ((PlannedMeal) -> Void)?
    var onCompleteWorkout: (() -> Void)?

    private var timelineItems: [TimelineItemType] {
        var items: [TimelineItemType] = []

        // Add logged meals (today only)
        for meal in loggedMeals.filter({ $0.loggedAt.isToday }) {
            items.append(.loggedMeal(meal))
        }

        // Add planned meals (only those not yet logged for today)
        let loggedMealTypes = Set(loggedMeals.filter { $0.loggedAt.isToday }.compactMap { $0.mealType })
        for meal in plannedMeals {
            if let mealType = meal.mealType, !loggedMealTypes.contains(mealType) {
                items.append(.plannedMeal(meal))
            } else if meal.mealType == nil {
                // If no meal type, still show it
                items.append(.plannedMeal(meal))
            }
        }

        // Add logged workouts (today only)
        for workout in loggedWorkouts.filter({ $0.loggedAt.isToday }) {
            items.append(.loggedWorkout(workout))
        }

        // Add planned workout if not completed today
        if let workout = plannedWorkout {
            let hasLoggedWorkoutToday = !loggedWorkouts.filter({ $0.loggedAt.isToday }).isEmpty
            if !hasLoggedWorkoutToday && !workout.isCompleted {
                items.append(.plannedWorkout(workout))
            }
        }

        // Sort by meal order
        return items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("TODAY")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .tracking(1)
                .padding(.bottom, 12)

            if timelineItems.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No meals or workouts scheduled")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Timeline items
                VStack(spacing: 0) {
                    ForEach(Array(timelineItems.enumerated()), id: \.offset) { index, item in
                        TimelineItemRow(
                            item: item,
                            onLog: {
                                if case .plannedMeal(let meal) = item {
                                    onLogMeal?(meal)
                                } else if case .plannedWorkout = item {
                                    onCompleteWorkout?()
                                }
                            },
                            onDelete: {
                                if case .plannedMeal(let meal) = item {
                                    onDeleteMeal?(meal)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

#Preview {
    ScrollView {
        TodayTimeline(
            plannedMeals: [
                PlannedMeal(
                    type: "breakfast",
                    name: "Oatmeal with berries",
                    description: nil,
                    calories: 450,
                    proteinG: 12,
                    carbsG: 65,
                    fatG: 14,
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
                ),
                PlannedMeal(
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
                )
            ],
            loggedMeals: [
                Meal(
                    userId: "user1",
                    loggedAt: Date(),
                    mealType: .breakfast,
                    items: [MealItem(name: "Oatmeal")],
                    calories: 450,
                    proteinG: 12,
                    carbsG: 65,
                    fatG: 14
                )
            ],
            plannedWorkout: nil,
            loggedWorkouts: [],
            onLogMeal: { _ in },
            onDeleteMeal: { _ in },
            onCompleteWorkout: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
