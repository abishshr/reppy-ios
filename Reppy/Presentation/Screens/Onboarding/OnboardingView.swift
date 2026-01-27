import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(hex: "1a1a2e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .onTapGesture {
                hideKeyboard()
            }

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index <= viewModel.currentStep ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == viewModel.currentStep ? 10 : 8,
                                   height: index == viewModel.currentStep ? 10 : 8)
                            .animation(.spring(response: 0.3), value: viewModel.currentStep)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)

                // Content
                TabView(selection: $viewModel.currentStep) {
                    NameStep(viewModel: viewModel)
                        .tag(0)

                    AgeGenderStep(viewModel: viewModel)
                        .tag(1)

                    BodyStatsStep(viewModel: viewModel)
                        .tag(2)

                    GoalsStep(viewModel: viewModel)
                        .tag(3)

                    FinalStep(viewModel: viewModel, appState: appState)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.currentStep) { _, _ in
            hideKeyboard()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Step 1: Name

struct NameStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)
            }

            // Title
            Text("What should we call you?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Input
            TextField("", text: $viewModel.name, prompt: Text("Your name").foregroundColor(.white.opacity(0.5)))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .textContentType(.name)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 40)

            Spacer()

            // Continue button
            ContinueButton(isEnabled: !viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty) {
                isFocused = false
                withAnimation {
                    viewModel.nextStep()
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Step 2: Age & Gender

struct AgeGenderStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let ages = Array(stride(from: 16, through: 80, by: 1))

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Title
            Text("About you")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Age picker
            VStack(spacing: 12) {
                Text("Age")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 0) {
                    ForEach([18, 25, 35, 45, 55], id: \.self) { age in
                        AgeButton(age: age, isSelected: viewModel.age == age) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.age = age
                            }
                        }
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                // Custom age input
                if viewModel.age == nil || ![18, 25, 35, 45, 55].contains(viewModel.age!) {
                    HStack {
                        Text("Or enter age:")
                            .foregroundColor(.white.opacity(0.5))
                        TextField("", value: $viewModel.age, format: .number)
                            .keyboardType(.numberPad)
                            .foregroundColor(.white)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }

            // Gender selection
            VStack(spacing: 12) {
                Text("Sex")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 16) {
                    GenderButton(title: "Male", icon: "figure.stand", isSelected: viewModel.sex == .male) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.sex = .male
                        }
                    }

                    GenderButton(title: "Female", icon: "figure.stand.dress", isSelected: viewModel.sex == .female) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.sex = .female
                        }
                    }
                }
            }

            Spacer()

            ContinueButton(isEnabled: viewModel.age != nil && viewModel.sex != nil) {
                withAnimation {
                    viewModel.nextStep()
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}

struct AgeButton: View {
    let age: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(age)")
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(8)
        }
    }
}

struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isSelected ? Color.white : Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

// MARK: - Step 3: Body Stats

struct BodyStatsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var heightValue: Double = 170
    @State private var weightValue: Double = 70

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Your measurements")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Height
            VStack(spacing: 16) {
                HStack {
                    Text("Height")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(heightValue)) cm")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                Slider(value: $heightValue, in: 120...220, step: 1)
                    .tint(.blue)
                    .onChange(of: heightValue) { _, newValue in
                        viewModel.heightCm = newValue
                    }
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)

            // Weight
            VStack(spacing: 16) {
                HStack {
                    Text("Weight")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(weightValue)) kg")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                Slider(value: $weightValue, in: 30...200, step: 1)
                    .tint(.green)
                    .onChange(of: weightValue) { _, newValue in
                        viewModel.weightKg = newValue
                    }
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)

            // Activity Level
            VStack(spacing: 12) {
                Text("Activity Level")
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 8) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        ActivityButton(
                            level: level,
                            isSelected: viewModel.activityLevel == level
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.activityLevel = level
                            }
                        }
                    }
                }
            }

            Spacer()

            ContinueButton(isEnabled: viewModel.heightCm != nil && viewModel.weightKg != nil && viewModel.activityLevel != nil) {
                withAnimation {
                    viewModel.nextStep()
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            viewModel.heightCm = heightValue
            viewModel.weightKg = weightValue
        }
    }
}

struct ActivityButton: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        switch level {
        case .sedentary: return "figure.seated.side"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "figure.highintensity.intervaltraining"
        case .veryActive: return "flame.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(level.shortName)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.white : Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Step 4: Goals

struct GoalsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("What's your goal?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Select all that apply")
                .foregroundColor(.white.opacity(0.6))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: viewModel.goals.contains(goal)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.toggleGoal(goal)
                        }
                    }
                }
            }

            Spacer()

            ContinueButton(isEnabled: !viewModel.goals.isEmpty) {
                withAnimation {
                    viewModel.nextStep()
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        switch goal {
        case .fatLoss: return "arrow.down.circle.fill"
        case .muscleGain: return "dumbbell.fill"
        case .maintenance: return "equal.circle.fill"
        case .health: return "heart.circle.fill"
        case .endurance: return "figure.run"
        case .strength: return "bolt.circle.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                Text(goal.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.white : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Step 5: Final

struct FinalStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let appState: AppState
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.green)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(showConfetti ? 1 : 0.5)
            .opacity(showConfetti ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)

            Text("You're all set, \(viewModel.name)!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .opacity(showConfetti ? 1 : 0)
                .animation(.easeIn.delay(0.2), value: showConfetti)

            Text("Let's start your fitness journey")
                .foregroundColor(.white.opacity(0.7))
                .opacity(showConfetti ? 1 : 0)
                .animation(.easeIn.delay(0.3), value: showConfetti)

            // Summary card
            VStack(spacing: 16) {
                SummaryRow(icon: "person.fill", title: "Age", value: "\(viewModel.age ?? 0) years")
                SummaryRow(icon: "ruler", title: "Height", value: "\(Int(viewModel.heightCm ?? 0)) cm")
                SummaryRow(icon: "scalemass", title: "Weight", value: "\(Int(viewModel.weightKg ?? 0)) kg")
                SummaryRow(icon: "target", title: "Goals", value: "\(viewModel.goals.count) selected")
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .opacity(showConfetti ? 1 : 0)
            .animation(.easeIn.delay(0.4), value: showConfetti)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }

            // Start button
            Button {
                Task {
                    await viewModel.completeOnboarding(appState: appState)
                }
            } label: {
                HStack {
                    Text("Let's Go!")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(viewModel.isLoading)
            .opacity(showConfetti ? 1 : 0)
            .animation(.easeIn.delay(0.5), value: showConfetti)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            showConfetti = true
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Continue Button

struct ContinueButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(isEnabled ? .black : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isEnabled ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(16)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ActivityLevel Extension

extension ActivityLevel {
    var shortName: String {
        switch self {
        case .sedentary: return "Low"
        case .light: return "Light"
        case .moderate: return "Med"
        case .active: return "High"
        case .veryActive: return "Max"
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
