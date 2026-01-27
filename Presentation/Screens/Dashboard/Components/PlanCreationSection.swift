import SwiftUI

/// Section for creating workout and meal plans
/// Shows compact buttons when plans exist, hero buttons when no plans
struct PlanCreationSection: View {
    var hasWorkoutPlan: Bool = false
    var hasMealPlan: Bool = false
    let onCreateWorkoutPlan: () -> Void
    let onCreateMealPlan: () -> Void

    private var showHeroStyle: Bool {
        !hasWorkoutPlan && !hasMealPlan
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showHeroStyle {
                // No plans - show hero buttons
                Text("Create a Plan")
                    .font(.headline)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    PlanCreationHeroButton(
                        icon: "dumbbell.fill",
                        title: "Workout Plan",
                        subtitle: "Build strength & muscle",
                        gradient: [.blue, .cyan],
                        action: onCreateWorkoutPlan
                    )

                    PlanCreationHeroButton(
                        icon: "fork.knife",
                        title: "Meal Plan",
                        subtitle: "Fuel your goals",
                        gradient: [.green, .mint],
                        action: onCreateMealPlan
                    )
                }
            } else {
                // Has at least one plan - show compact "New Plan" buttons
                Text("Plans")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 12) {
                    CompactPlanButton(
                        icon: "dumbbell.fill",
                        title: hasWorkoutPlan ? "New Workout" : "Create Workout",
                        color: .blue,
                        action: onCreateWorkoutPlan
                    )

                    CompactPlanButton(
                        icon: "fork.knife",
                        title: hasMealPlan ? "New Meal Plan" : "Create Meal Plan",
                        color: .green,
                        action: onCreateMealPlan
                    )
                }
            }
        }
    }
}

// MARK: - Compact Plan Button (when plans exist)

struct CompactPlanButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(color)
                    )

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.body)
                    .foregroundColor(color)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Hero Button (when no plans)

struct PlanCreationHeroButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 12) {
                // Icon with gradient background (no glow)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Create badge
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption2)
                    Text("Create")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(gradient[0])
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(gradient[0].opacity(0.1))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    VStack(spacing: 30) {
        // No plans
        PlanCreationSection(
            hasWorkoutPlan: false,
            hasMealPlan: false,
            onCreateWorkoutPlan: {},
            onCreateMealPlan: {}
        )

        // Has plans
        PlanCreationSection(
            hasWorkoutPlan: true,
            hasMealPlan: true,
            onCreateWorkoutPlan: {},
            onCreateMealPlan: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
