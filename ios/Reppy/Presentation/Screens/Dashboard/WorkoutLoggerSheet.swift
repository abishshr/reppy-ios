import SwiftUI

// MARK: - Game-like Workout Logger

struct WorkoutLoggerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var selectedType: WorkoutType = .strength
    @State private var animateIn = false
    @State private var showStreak = false
    @State private var pulseXP = false

    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // Mock data - would come from ViewModel
    private let currentStreak = 5
    private let todayXP = 150
    private let level = 7
    private let xpToNextLevel = 350
    private let currentLevelXP = 200

    enum WorkoutType: String, CaseIterable {
        case strength = "Strength"
        case cardio = "Cardio"
        case hiit = "HIIT"
        case yoga = "Yoga"
        case sports = "Sports"
        case custom = "Custom"

        var icon: String {
            switch self {
            case .strength: return "dumbbell.fill"
            case .cardio: return "figure.run"
            case .hiit: return "bolt.fill"
            case .yoga: return "figure.mind.and.body"
            case .sports: return "sportscourt.fill"
            case .custom: return "ellipsis.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .strength: return .blue
            case .cardio: return .red
            case .hiit: return .orange
            case .yoga: return .purple
            case .sports: return .green
            case .custom: return .gray
            }
        }

        var gradient: [Color] {
            switch self {
            case .strength: return [.blue, .cyan]
            case .cardio: return [.red, .orange]
            case .hiit: return [.orange, .yellow]
            case .yoga: return [.purple, .pink]
            case .sports: return [.green, .mint]
            case .custom: return [.gray, .secondary]
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        selectedType.color.opacity(0.1),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: selectedType)

                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Header
                        statsHeader
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        // Workout Type Selection
                        workoutTypeGrid
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)

                        // Quick Start Section
                        quickStartSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 30)

                        // Log with AI Button
                        logWithAIButton
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 40)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        impactMedium.impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Log Workout")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                impactMedium.prepare()
                impactHeavy.prepare()
                notificationFeedback.prepare()

                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    animateIn = true
                }

                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                    showStreak = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 16) {
            // Streak Card
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .scaleEffect(showStreak ? 1.2 : 1.0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.5)
                            .repeatCount(3, autoreverses: true),
                            value: showStreak
                        )

                    Text("\(currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Text("Day Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )

            // XP Card
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .scaleEffect(pulseXP ? 1.1 : 1.0)

                    Text("\(todayXP)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Text("XP Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )

            // Level Card
            VStack(spacing: 4) {
                Text("Lv.\(level)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.purple.opacity(0.2))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (Double(currentLevelXP) / Double(xpToNextLevel)))
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Workout Type Grid

    private var workoutTypeGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What type of workout?")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    WorkoutTypeButton(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        impactMedium.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Start Section

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                QuickWorkoutRow(
                    title: "Continue Today's Plan",
                    subtitle: "Upper Body - Week 2, Day 3",
                    icon: "play.fill",
                    color: .green,
                    xp: 100
                ) {
                    startWorkout()
                }

                QuickWorkoutRow(
                    title: "Quick \(selectedType.rawValue)",
                    subtitle: "15-30 min session",
                    icon: "bolt.fill",
                    color: selectedType.color,
                    xp: 50
                ) {
                    startQuickWorkout()
                }
            }
        }
    }

    // MARK: - Log with AI Button

    private var logWithAIButton: some View {
        Button {
            impactHeavy.impactOccurred()
            dismiss()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.navigateToChatWith(
                    message: "I want to log a \(selectedType.rawValue.lowercased()) workout"
                )
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "message.fill")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Describe Your Workout")
                        .font(.headline)

                    Text("Tell the AI what you did")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("+XP")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: selectedType.gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: selectedType.color.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Actions

    private func startWorkout() {
        notificationFeedback.notificationOccurred(.success)
        impactHeavy.impactOccurred()
        dismiss()

        // Navigate to active workout view (future feature)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigateToChatWith(
                message: "Start my scheduled workout for today"
            )
        }
    }

    private func startQuickWorkout() {
        impactMedium.impactOccurred()
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigateToChatWith(
                message: "I want to do a quick \(selectedType.rawValue.lowercased()) workout, around 20 minutes"
            )
        }
    }
}

// MARK: - Workout Type Button

struct WorkoutTypeButton: View {
    let type: WorkoutLoggerSheet.WorkoutType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(colors: type.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [type.color.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : type.color)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? type.color : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? type.color.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Quick Workout Row

struct QuickWorkoutRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let xp: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // XP Badge
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("+\(xp)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(12)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Bounce Button Style

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    WorkoutLoggerSheet()
        .environmentObject(AppState())
}
