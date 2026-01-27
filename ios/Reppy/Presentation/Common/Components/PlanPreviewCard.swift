import SwiftUI

/// Modern card for displaying meal/workout plan previews in chat
struct PlanPreviewCard: View {
    let plan: PlanPreview
    let onApprove: () -> Void
    let onEdit: (() -> Void)?

    @State private var expandedDays: Set<Int> = [1]  // Day 1 expanded by default
    @State private var isApproving = false

    private var accentColor: Color {
        plan.type == .meal ? .green : .blue
    }

    private var gradientColors: [Color] {
        plan.type == .meal ? [.green, .mint] : [.blue, .purple]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()
                .padding(.horizontal, 16)

            // Stats row
            statsSection

            Divider()
                .padding(.horizontal, 16)

            // Days list
            daysSection

            Divider()
                .padding(.horizontal, 16)

            // Action buttons
            actionButtons
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.4), accentColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: plan.type == .meal ? "fork.knife" : "dumbbell.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: accentColor.opacity(0.4), radius: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.type == .meal ? "MEAL PLAN" : "WORKOUT PLAN")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(accentColor)
                    .tracking(1)

                Text(plan.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            Spacer()

            // XP Badge
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                Text("+50")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(.yellow)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(16)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 8) {
            if let calories = plan.totalCalories {
                PlanStatChip(
                    icon: "flame.fill",
                    value: formatNumber(calories),
                    label: "cal",
                    color: .orange
                )
            }

            if let protein = plan.totalProtein {
                PlanStatChip(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(Int(protein))",
                    label: "g protein",
                    color: .blue
                )
            }

            PlanStatChip(
                icon: "calendar",
                value: "\(plan.durationDays)",
                label: plan.durationDays == 1 ? "day" : "days",
                color: .purple
            )

            if plan.type == .meal {
                PlanStatChip(
                    icon: "fork.knife",
                    value: "\(plan.totalMeals)",
                    label: "meals",
                    color: .green
                )
            } else {
                PlanStatChip(
                    icon: "figure.run",
                    value: "\(plan.totalExercises)",
                    label: "exercises",
                    color: .cyan
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Days Section

    private var daysSection: some View {
        VStack(spacing: 0) {
            ForEach(plan.days) { day in
                PlanDayRow(
                    day: day,
                    planType: plan.type,
                    isExpanded: expandedDays.contains(day.dayNumber),
                    accentColor: accentColor
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if expandedDays.contains(day.dayNumber) {
                            expandedDays.remove(day.dayNumber)
                        } else {
                            expandedDays.insert(day.dayNumber)
                        }
                    }
                }

                if day.dayNumber < plan.days.count {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Approve button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isApproving = true
                }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onApprove()
            } label: {
                HStack(spacing: 8) {
                    if isApproving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(isApproving ? "Saving..." : "Approve & Save")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: isApproving ? [.gray] : gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: accentColor.opacity(isApproving ? 0 : 0.4), radius: 8, y: 4)
            }
            .disabled(isApproving)
            .scaleEffect(isApproving ? 0.98 : 1)

            // Edit button
            if let onEdit = onEdit {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 50, height: 50)
                        .background(Color(.tertiarySystemFill))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fk", Double(num) / 1000)
        }
        return "\(num)"
    }
}

// MARK: - Plan Stat Chip

struct PlanStatChip: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.caption)
                .fontWeight(.bold)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Plan Day Row

struct PlanDayRow: View {
    let day: PlanDayPreview
    let planType: PlanType
    let isExpanded: Bool
    let accentColor: Color
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Day number circle
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Text("\(day.dayNumber)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.dayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if let cal = day.totalCalories {
                            Text("\(cal) cal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(day.items.count) \(planType == .meal ? "meals" : "exercises")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(day.items) { item in
                        if planType == .meal {
                            MealItemRow(item: item)
                        } else {
                            ExerciseItemRow(item: item)
                        }
                    }
                }
                .padding(.leading, 52)
                .padding(.trailing, 16)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Meal Item Row

struct MealItemRow: View {
    let item: PlanItemPreview

    private var iconColor: Color {
        switch item.itemType.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.mealIcon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemType.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()

            if let cal = item.calories {
                Text("\(cal) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Exercise Item Row

struct ExerciseItemRow: View {
    let item: PlanItemPreview

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(item.name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 6) {
                if let sets = item.sets, let reps = item.reps {
                    Text("\(sets)x\(reps)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Meal Plan Preview
            PlanPreviewCard(
                plan: PlanPreview(
                    id: "1",
                    type: .meal,
                    name: "7-Day High Protein Plan",
                    days: [
                        PlanDayPreview(
                            dayNumber: 1,
                            dayName: "Monday",
                            items: [
                                PlanItemPreview(itemType: "breakfast", name: "Oatmeal with Berries", calories: 350, protein: 12),
                                PlanItemPreview(itemType: "lunch", name: "Grilled Chicken Salad", calories: 520, protein: 45),
                                PlanItemPreview(itemType: "dinner", name: "Salmon with Rice", calories: 680, protein: 42),
                                PlanItemPreview(itemType: "snack", name: "Greek Yogurt", calories: 150, protein: 15)
                            ],
                            totalCalories: 1700,
                            totalProtein: 114
                        ),
                        PlanDayPreview(
                            dayNumber: 2,
                            dayName: "Tuesday",
                            items: [
                                PlanItemPreview(itemType: "breakfast", name: "Egg White Omelette", calories: 280, protein: 24),
                                PlanItemPreview(itemType: "lunch", name: "Turkey Wrap", calories: 450, protein: 35),
                                PlanItemPreview(itemType: "dinner", name: "Lean Beef Stir Fry", calories: 600, protein: 48)
                            ],
                            totalCalories: 1330,
                            totalProtein: 107
                        )
                    ],
                    totalCalories: 11900,
                    totalProtein: 840,
                    durationDays: 7,
                    suggestionId: "abc123",
                    savedPlanId: nil
                ),
                onApprove: { print("Approved!") },
                onEdit: { print("Edit!") }
            )
            .padding(.horizontal, 16)

            // Workout Plan Preview
            PlanPreviewCard(
                plan: PlanPreview(
                    id: "2",
                    type: .workout,
                    name: "4-Week Strength Program",
                    days: [
                        PlanDayPreview(
                            dayNumber: 1,
                            dayName: "Push Day",
                            items: [
                                PlanItemPreview(itemType: "exercise", name: "Bench Press", sets: 4, reps: "8-10"),
                                PlanItemPreview(itemType: "exercise", name: "Overhead Press", sets: 3, reps: "10-12"),
                                PlanItemPreview(itemType: "exercise", name: "Tricep Dips", sets: 3, reps: "12-15")
                            ]
                        ),
                        PlanDayPreview(
                            dayNumber: 2,
                            dayName: "Pull Day",
                            items: [
                                PlanItemPreview(itemType: "exercise", name: "Pull-ups", sets: 4, reps: "8-10"),
                                PlanItemPreview(itemType: "exercise", name: "Barbell Rows", sets: 4, reps: "8-10")
                            ]
                        )
                    ],
                    totalCalories: nil,
                    totalProtein: nil,
                    durationDays: 28,
                    suggestionId: "def456",
                    savedPlanId: nil
                ),
                onApprove: { print("Approved!") },
                onEdit: nil
            )
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }
    .background(Color(.systemGroupedBackground))
}
