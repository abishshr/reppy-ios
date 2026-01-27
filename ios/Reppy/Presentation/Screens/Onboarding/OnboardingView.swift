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
                    ForEach(0..<7, id: \.self) { index in
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

                    HealthRestrictionsStep(viewModel: viewModel)
                        .tag(4)

                    BodyMeasurementsStep(viewModel: viewModel)
                        .tag(5)

                    FinalStep(viewModel: viewModel, appState: appState)
                        .tag(6)
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
    @State private var selectedAge: Int = 25

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Title
            Text("About you")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Age picker - wheel style for precise selection
            VStack(spacing: 8) {
                Text("Age")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                // Display selected age prominently
                Text("\(selectedAge)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                // Wheel picker
                Picker("Age", selection: $selectedAge) {
                    ForEach(13...100, id: \.self) { age in
                        Text("\(age)")
                            .tag(age)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .clipped()
                .onChange(of: selectedAge) { _, newValue in
                    viewModel.age = newValue
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
        .onAppear {
            // Initialize with existing value or default
            selectedAge = viewModel.age ?? 25
            viewModel.age = selectedAge
        }
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
    @State private var useMetric = true

    // Metric values (stored internally)
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70

    // Imperial values (for display)
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 7
    @State private var weightLbs: Double = 154

    // Conversion helpers
    private func cmToFeetInches(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches) % 12
        return (feet, inches)
    }

    private func feetInchesToCm(feet: Int, inches: Int) -> Double {
        Double(feet * 12 + inches) * 2.54
    }

    private func kgToLbs(_ kg: Double) -> Double {
        kg * 2.20462
    }

    private func lbsToKg(_ lbs: Double) -> Double {
        lbs / 2.20462
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Your measurements")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Unit toggle
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        useMetric = true
                    }
                } label: {
                    Text("Metric")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(useMetric ? .black : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(useMetric ? Color.white : Color.clear)
                }

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        useMetric = false
                        // Convert current values to imperial for display
                        let (ft, inches) = cmToFeetInches(heightCm)
                        heightFeet = ft
                        heightInches = inches
                        weightLbs = kgToLbs(weightKg)
                    }
                } label: {
                    Text("Imperial")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(!useMetric ? .black : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!useMetric ? Color.white : Color.clear)
                }
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 40)

            // Height
            VStack(spacing: 12) {
                HStack {
                    Text("Height")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if useMetric {
                        Text("\(Int(heightCm)) cm")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(heightFeet)' \(heightInches)\"")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                if useMetric {
                    Slider(value: $heightCm, in: 120...220, step: 1)
                        .tint(.blue)
                        .onChange(of: heightCm) { _, newValue in
                            viewModel.heightCm = newValue
                        }
                } else {
                    // Feet and inches pickers
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("ft")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(4...7, id: \.self) { ft in
                                    Text("\(ft)").tag(ft)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 100)
                            .clipped()
                        }

                        VStack(spacing: 4) {
                            Text("in")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inches in
                                    Text("\(inches)").tag(inches)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 100)
                            .clipped()
                        }
                    }
                    .onChange(of: heightFeet) { _, _ in
                        heightCm = feetInchesToCm(feet: heightFeet, inches: heightInches)
                        viewModel.heightCm = heightCm
                    }
                    .onChange(of: heightInches) { _, _ in
                        heightCm = feetInchesToCm(feet: heightFeet, inches: heightInches)
                        viewModel.heightCm = heightCm
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)

            // Weight
            VStack(spacing: 12) {
                HStack {
                    Text("Weight")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if useMetric {
                        Text("\(Int(weightKg)) kg")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(Int(weightLbs)) lbs")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                if useMetric {
                    Slider(value: $weightKg, in: 30...200, step: 1)
                        .tint(.green)
                        .onChange(of: weightKg) { _, newValue in
                            viewModel.weightKg = newValue
                        }
                } else {
                    Slider(value: $weightLbs, in: 66...440, step: 1)
                        .tint(.green)
                        .onChange(of: weightLbs) { _, newValue in
                            weightKg = lbsToKg(newValue)
                            viewModel.weightKg = weightKg
                        }
                }
            }
            .padding(16)
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
            viewModel.heightCm = heightCm
            viewModel.weightKg = weightKg
            // Initialize imperial values
            let (ft, inches) = cmToFeetInches(heightCm)
            heightFeet = ft
            heightInches = inches
            weightLbs = kgToLbs(weightKg)
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

// MARK: - Step 5: Health & Restrictions (Engaging Tap Experience)

struct HealthRestrictionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var currentSection = 0  // 0: allergies, 1: injuries, 2: conditions
    @State private var showCustomInput = false
    @State private var customText = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Dynamic Icon based on section
            ZStack {
                Circle()
                    .fill(sectionColor.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: sectionIcon)
                    .font(.system(size: 44))
                    .foregroundColor(sectionColor)
            }

            // Section indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == currentSection ? sectionColor : Color.white.opacity(0.3))
                        .frame(width: index == currentSection ? 24 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.3), value: currentSection)

            // Title
            VStack(spacing: 8) {
                Text(sectionTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(sectionSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // Tap-to-select grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(sectionItems, id: \.self) { item in
                    HealthChip(
                        text: item,
                        isSelected: isItemSelected(item),
                        color: sectionColor
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            toggleItem(item)
                        }
                    }
                }

                // Add custom button
                Button {
                    showCustomInput = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Other")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 8)

            // Selected items display
            if !currentSelectedItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(currentSelectedItems, id: \.self) { item in
                            HStack(spacing: 4) {
                                Text(item)
                                    .font(.caption.weight(.medium))
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        removeItem(item)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(sectionColor)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 36)
            }

            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                if currentSection > 0 {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            currentSection -= 1
                        }
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                }

                Button {
                    if currentSection < 2 {
                        withAnimation(.spring(response: 0.4)) {
                            currentSection += 1
                        }
                    } else {
                        withAnimation {
                            viewModel.nextStep()
                        }
                    }
                } label: {
                    HStack {
                        Text(currentSection < 2 ? "Next" : "Continue")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(16)
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $showCustomInput) {
            CustomInputSheet(
                title: "Add \(sectionSingular)",
                placeholder: "Enter \(sectionSingular.lowercased())...",
                onSave: { text in
                    withAnimation(.spring(response: 0.3)) {
                        addItem(text)
                    }
                }
            )
            .presentationDetents([.height(200)])
        }
    }

    // MARK: - Computed Properties

    private var sectionColor: Color {
        switch currentSection {
        case 0: return .orange
        case 1: return .red
        case 2: return .purple
        default: return .blue
        }
    }

    private var sectionIcon: String {
        switch currentSection {
        case 0: return "leaf.fill"
        case 1: return "bandage.fill"
        case 2: return "heart.text.square.fill"
        default: return "heart.fill"
        }
    }

    private var sectionTitle: String {
        switch currentSection {
        case 0: return "Any Food Allergies?"
        case 1: return "Current Injuries?"
        case 2: return "Medical Conditions?"
        default: return ""
        }
    }

    private var sectionSubtitle: String {
        switch currentSection {
        case 0: return "Tap any that apply to you"
        case 1: return "We'll adjust workouts to avoid these areas"
        case 2: return "This helps us personalize your nutrition"
        default: return ""
        }
    }

    private var sectionSingular: String {
        switch currentSection {
        case 0: return "Allergy"
        case 1: return "Injury"
        case 2: return "Condition"
        default: return "Item"
        }
    }

    private var sectionItems: [String] {
        switch currentSection {
        case 0: return ["Dairy", "Gluten", "Nuts", "Shellfish", "Eggs", "Soy", "Fish", "Wheat"]
        case 1: return ["Lower Back", "Shoulder", "Knee", "Ankle", "Wrist", "Neck", "Hip", "Elbow"]
        case 2: return ["Diabetes", "High Blood Pressure", "Heart Disease", "Thyroid", "PCOS", "Arthritis"]
        default: return []
        }
    }

    private var currentSelectedItems: [String] {
        switch currentSection {
        case 0: return viewModel.allergies
        case 1: return viewModel.injuries
        case 2: return viewModel.medicalConditions
        default: return []
        }
    }

    // MARK: - Actions

    private func isItemSelected(_ item: String) -> Bool {
        switch currentSection {
        case 0: return viewModel.allergies.contains(item)
        case 1: return viewModel.injuries.contains(item)
        case 2: return viewModel.medicalConditions.contains(item)
        default: return false
        }
    }

    private func toggleItem(_ item: String) {
        switch currentSection {
        case 0:
            if viewModel.allergies.contains(item) {
                viewModel.allergies.removeAll { $0 == item }
            } else {
                viewModel.allergies.append(item)
            }
        case 1:
            if viewModel.injuries.contains(item) {
                viewModel.injuries.removeAll { $0 == item }
            } else {
                viewModel.injuries.append(item)
            }
        case 2:
            if viewModel.medicalConditions.contains(item) {
                viewModel.medicalConditions.removeAll { $0 == item }
            } else {
                viewModel.medicalConditions.append(item)
            }
        default: break
        }
    }

    private func addItem(_ item: String) {
        guard !item.isEmpty else { return }
        switch currentSection {
        case 0:
            if !viewModel.allergies.contains(item) {
                viewModel.allergies.append(item)
            }
        case 1:
            if !viewModel.injuries.contains(item) {
                viewModel.injuries.append(item)
            }
        case 2:
            if !viewModel.medicalConditions.contains(item) {
                viewModel.medicalConditions.append(item)
            }
        default: break
        }
    }

    private func removeItem(_ item: String) {
        switch currentSection {
        case 0: viewModel.allergies.removeAll { $0 == item }
        case 1: viewModel.injuries.removeAll { $0 == item }
        case 2: viewModel.medicalConditions.removeAll { $0 == item }
        default: break
        }
    }
}

// MARK: - Health Chip

struct HealthChip: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
                Text(text)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? color : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Custom Input Sheet

struct CustomInputSheet: View {
    let title: String
    let placeholder: String
    let onSave: (String) -> Void

    @State private var text = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .padding(.top)

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)

                Button("Add") {
                    onSave(text)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.bottom)
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Step 6: Body Measurements (Optional)

struct BodyMeasurementsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState

    // Input mode
    @State private var useARScan = false
    @State private var showARScan = false
    @State private var arScanCompleted = false

    // Manual entry values
    @State private var waistValue: Double = 80
    @State private var neckValue: Double = 38
    @State private var hipsValue: Double = 95
    @State private var isCalculating = false
    @State private var showResult = false

    private var isFemale: Bool {
        viewModel.sex == .female
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: useARScan ? "camera.viewfinder" : "ruler")
                    .font(.system(size: 44))
                    .foregroundColor(.purple)
            }

            // Title
            VStack(spacing: 8) {
                Text("Body Measurements")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Optional - Calculate your body fat %")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.subheadline)
            }

            // Method toggle
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        useARScan = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "ruler")
                            .font(.caption)
                        Text("Manual")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(!useARScan ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(!useARScan ? Color.white : Color.clear)
                }

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        useARScan = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.viewfinder")
                            .font(.caption)
                        Text("AR Scan")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(useARScan ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(useARScan ? Color.white : Color.clear)
                }
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 40)

            if useARScan {
                // AR Scan content
                arScanContent
            } else {
                // Manual entry content
                manualEntryContent
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                if useARScan {
                    // AR Scan buttons
                    Button {
                        showARScan = true
                    } label: {
                        HStack {
                            Image(systemName: arScanCompleted ? "arrow.counterclockwise" : "camera.fill")
                            Text(arScanCompleted ? "Retake Scan" : "Start Body Scan")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                } else {
                    // Manual calculate button
                    Button {
                        calculateBodyFat()
                    } label: {
                        HStack {
                            if isCalculating {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "function")
                                Text("Calculate Body Fat")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .disabled(isCalculating)
                }

                // Skip / Continue
                Button {
                    if showResult || arScanCompleted {
                        saveAndContinue()
                    } else {
                        skipStep()
                    }
                } label: {
                    HStack {
                        Text((showResult || arScanCompleted) ? "Save & Continue" : "Skip for now")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor((showResult || arScanCompleted) ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background((showResult || arScanCompleted) ? Color.white : Color.white.opacity(0.2))
                    .cornerRadius(16)
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .fullScreenCover(isPresented: $showARScan) {
            OnboardingARScanView(viewModel: viewModel) { measurements in
                handleARScanResult(measurements)
            }
        }
        .onAppear {
            if !arScanCompleted {
                viewModel.waistCm = waistValue
                viewModel.neckCm = neckValue
                if isFemale {
                    viewModel.hipsCm = hipsValue
                }
            }
        }
    }

    // MARK: - AR Scan Content

    private var arScanContent: some View {
        VStack(spacing: 16) {
            if arScanCompleted, let bodyFat = viewModel.calculatedBodyFat {
                // Show AR scan results
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Scan Complete")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Text("\(String(format: "%.1f", bodyFat))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    if let category = viewModel.bodyFatCategory {
                        Text(category)
                            .font(.subheadline)
                            .foregroundColor(categoryColor(category))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(categoryColor(category).opacity(0.2))
                            .cornerRadius(8)
                    }

                    // Show measurements
                    HStack(spacing: 24) {
                        if let waist = viewModel.waistCm {
                            VStack {
                                Text("\(Int(waist))")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                                Text("Waist cm")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        if let neck = viewModel.neckCm {
                            VStack {
                                Text("\(Int(neck))")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                                Text("Neck cm")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        if isFemale, let hips = viewModel.hipsCm {
                            VStack {
                                Text("\(Int(hips))")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                                Text("Hips cm")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
            } else {
                // Instructions for AR scan
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.purple)
                            Text("Prop your phone at waist height")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.purple)
                            Text("Stand 6-8 feet away")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.purple)
                            Text("Follow on-screen instructions")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    // Device compatibility note
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Works best on iPhone 12 or newer")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    // MARK: - Manual Entry Content

    private var manualEntryContent: some View {
        VStack(spacing: 16) {
            // Instructions
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Use a tape measure for accuracy")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)

            // Measurements
            VStack(spacing: 12) {
                // Waist
                MeasurementSlider(
                    title: "Waist",
                    subtitle: "At belly button level",
                    value: $waistValue,
                    range: 50...150,
                    color: .orange,
                    icon: "circle.dashed"
                )
                .onChange(of: waistValue) { _, newValue in
                    viewModel.waistCm = newValue
                    clearResult()
                }

                // Neck
                MeasurementSlider(
                    title: "Neck",
                    subtitle: "Below Adam's apple",
                    value: $neckValue,
                    range: 25...60,
                    color: .cyan,
                    icon: "circle"
                )
                .onChange(of: neckValue) { _, newValue in
                    viewModel.neckCm = newValue
                    clearResult()
                }

                // Hips (female only)
                if isFemale {
                    MeasurementSlider(
                        title: "Hips",
                        subtitle: "Widest point",
                        value: $hipsValue,
                        range: 60...160,
                        color: .pink,
                        icon: "circle.bottomhalf.filled"
                    )
                    .onChange(of: hipsValue) { _, newValue in
                        viewModel.hipsCm = newValue
                        clearResult()
                    }
                }
            }

            // Result
            if showResult, let bodyFat = viewModel.calculatedBodyFat {
                VStack(spacing: 8) {
                    Text("Estimated Body Fat")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)

                    Text("\(String(format: "%.1f", bodyFat))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    if let category = viewModel.bodyFatCategory {
                        Text(category)
                            .font(.subheadline)
                            .foregroundColor(categoryColor(category))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(categoryColor(category).opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Handle AR Scan Result

    private func handleARScanResult(_ measurements: ScanMeasurements) {
        // Apply measurements from AR scan
        viewModel.waistCm = measurements.waistCm
        viewModel.neckCm = measurements.neckCm
        viewModel.hipsCm = measurements.hipsCm

        // Calculate body fat from these measurements
        if let heightCm = viewModel.heightCm {
            var bodyFat: Double

            if viewModel.sex == .male {
                if measurements.waistCm > measurements.neckCm {
                    bodyFat = 495 / (1.0324 - 0.19077 * log10(measurements.waistCm - measurements.neckCm) + 0.15456 * log10(heightCm)) - 450
                } else {
                    bodyFat = 15.0 // Default fallback
                }
            } else {
                if (measurements.waistCm + measurements.hipsCm) > measurements.neckCm {
                    bodyFat = 495 / (1.29579 - 0.35004 * log10(measurements.waistCm + measurements.hipsCm - measurements.neckCm) + 0.22100 * log10(heightCm)) - 450
                } else {
                    bodyFat = 22.0 // Default fallback
                }
            }

            bodyFat = max(2.0, min(60.0, bodyFat))
            viewModel.calculatedBodyFat = bodyFat
            viewModel.bodyFatCategory = getCategory(bodyFat: bodyFat, isMale: viewModel.sex == .male)
        }

        withAnimation(.spring(response: 0.4)) {
            arScanCompleted = true
        }
    }

    private func clearResult() {
        showResult = false
        viewModel.calculatedBodyFat = nil
        viewModel.bodyFatCategory = nil
    }

    private func calculateBodyFat() {
        isCalculating = true

        // Calculate locally using US Navy method
        guard let heightCm = viewModel.heightCm else {
            isCalculating = false
            return
        }

        let waist = waistValue
        let neck = neckValue
        let hips = isFemale ? hipsValue : nil

        // US Navy formula
        var bodyFat: Double

        if viewModel.sex == .male {
            guard waist > neck else {
                isCalculating = false
                return
            }
            bodyFat = 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(heightCm)) - 450
        } else {
            guard let hipsCm = hips, (waist + hipsCm) > neck else {
                isCalculating = false
                return
            }
            bodyFat = 495 / (1.29579 - 0.35004 * log10(waist + hipsCm - neck) + 0.22100 * log10(heightCm)) - 450
        }

        // Clamp to reasonable range
        bodyFat = max(2.0, min(60.0, bodyFat))

        withAnimation(.spring(response: 0.4)) {
            viewModel.calculatedBodyFat = bodyFat
            viewModel.bodyFatCategory = getCategory(bodyFat: bodyFat, isMale: viewModel.sex == .male)
            showResult = true
            isCalculating = false
        }
    }

    private func getCategory(bodyFat: Double, isMale: Bool) -> String {
        if isMale {
            if bodyFat < 6 { return "Essential Fat" }
            else if bodyFat < 14 { return "Athletic" }
            else if bodyFat < 18 { return "Fitness" }
            else if bodyFat < 25 { return "Average" }
            else { return "Above Average" }
        } else {
            if bodyFat < 14 { return "Essential Fat" }
            else if bodyFat < 21 { return "Athletic" }
            else if bodyFat < 25 { return "Fitness" }
            else if bodyFat < 32 { return "Average" }
            else { return "Above Average" }
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Essential Fat": return .yellow
        case "Athletic": return .green
        case "Fitness": return .blue
        case "Average": return .gray
        case "Above Average": return .orange
        default: return .white
        }
    }

    private func skipStep() {
        viewModel.skipMeasurements = true
        viewModel.waistCm = nil
        viewModel.neckCm = nil
        viewModel.hipsCm = nil
        viewModel.calculatedBodyFat = nil
        withAnimation {
            viewModel.nextStep()
        }
    }

    private func saveAndContinue() {
        withAnimation {
            viewModel.nextStep()
        }
    }
}

// MARK: - Onboarding AR Scan View (wrapper for onboarding flow)

struct OnboardingARScanView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    let onComplete: (ScanMeasurements) -> Void

    var body: some View {
        OnboardingARScanContainer(
            userHeightCm: viewModel.heightCm ?? 170,
            userSex: viewModel.sex ?? .male,
            onComplete: { measurements in
                onComplete(measurements)
                dismiss()
            },
            onDismiss: {
                dismiss()
            }
        )
    }
}

// MARK: - AR Scan Container (using existing ARBodyScanViewModel)

struct OnboardingARScanContainer: View {
    @StateObject private var scanViewModel = ARBodyScanViewModel()
    let userHeightCm: Double
    let userSex: Sex
    let onComplete: (ScanMeasurements) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Camera background
            Color.black.ignoresSafeArea()

            // Camera/AR feed
            if scanViewModel.isCameraReady {
                if scanViewModel.deviceCapability == .bodyTrackingSupported,
                   let arSession = scanViewModel.arSession {
                    ARBodyScanPreview(session: arSession)
                        .ignoresSafeArea()
                } else {
                    CameraScanPreview(session: scanViewModel.captureSession)
                        .ignoresSafeArea()
                }
            }

            // Skeleton overlay
            if let pose = scanViewModel.detectedPose, scanViewModel.showSkeleton {
                SkeletonOverlayView(pose: pose)
            }

            // Main content based on mode
            Group {
                switch scanViewModel.currentMode {
                case .tutorial:
                    TutorialOverlay(onStart: scanViewModel.startScanning)

                case .detecting:
                    DetectingOverlay()

                case .tooClose:
                    DistanceWarningOverlay(message: "Step back a bit", icon: "arrow.backward")

                case .tooFar:
                    DistanceWarningOverlay(message: "Step closer", icon: "arrow.forward")

                case .positioningFront:
                    PositioningOverlay(
                        title: "Face the camera",
                        subtitle: "Stand with arms slightly away from body",
                        silhouetteRotation: 0,
                        isReady: scanViewModel.isBodyAligned
                    )

                case .countdown(let count):
                    ScanCountdownOverlay(count: count)

                case .capturingFront, .capturingSide:
                    CapturingOverlay()

                case .turningSide:
                    TurnInstructionOverlay()

                case .positioningSide:
                    PositioningOverlay(
                        title: "Show your side",
                        subtitle: "Turn 90° to face left or right",
                        silhouetteRotation: 90,
                        isReady: scanViewModel.isBodyAligned
                    )

                case .processing:
                    ProcessingOverlay()

                case .complete:
                    if let measurements = scanViewModel.finalMeasurements {
                        OnboardingScanCompleteOverlay(
                            measurements: measurements,
                            onSave: { onComplete(measurements) },
                            onRetake: scanViewModel.reset
                        )
                    }

                case .error(let message):
                    ScanErrorOverlay(message: message, onRetry: scanViewModel.reset)
                }
            }

            // Top bar
            if scanViewModel.currentMode != .tutorial {
                VStack {
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        Spacer()

                        // Step indicator
                        HStack(spacing: 8) {
                            ForEach(1...2, id: \.self) { s in
                                Circle()
                                    .fill(s <= scanViewModel.currentStep ? Color.green : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)

                        Spacer()

                        Text(scanViewModel.deviceCapability.shortName)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(scanViewModel.deviceCapability.color.opacity(0.8))
                            .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                }
            }

            // Capture button
            if scanViewModel.showCaptureButton {
                VStack {
                    Spacer()
                    CaptureButton(
                        isReady: scanViewModel.isBodyAligned,
                        onTap: scanViewModel.capture
                    )
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            scanViewModel.userHeightCm = userHeightCm
            scanViewModel.userSex = userSex
        }
        .onDisappear {
            scanViewModel.stopSession()
        }
    }
}

// MARK: - Onboarding Scan Complete Overlay

struct OnboardingScanCompleteOverlay: View {
    let measurements: ScanMeasurements
    let onSave: () -> Void
    let onRetake: () -> Void
    @State private var showCheckmark = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 24) {
                // Success animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(showCheckmark ? 1 : 0)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .scaleEffect(showCheckmark ? 1 : 0)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)

                Text("Scan Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Measurements card
                VStack(spacing: 16) {
                    MeasurementResultItem(label: "Neck", value: measurements.neckCm)
                    MeasurementResultItem(label: "Shoulders", value: measurements.shouldersCm)
                    MeasurementResultItem(label: "Chest", value: measurements.chestCm)
                    MeasurementResultItem(label: "Waist", value: measurements.waistCm)
                    MeasurementResultItem(label: "Hips", value: measurements.hipsCm)
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)

                // Confidence badge
                HStack {
                    Circle()
                        .fill(measurements.confidence > 0.8 ? .green : (measurements.confidence > 0.6 ? .yellow : .orange))
                        .frame(width: 8, height: 8)
                    Text("\(Int(measurements.confidence * 100))% confidence")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Actions
                HStack(spacing: 16) {
                    Button(action: onRetake) {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }

                    Button(action: onSave) {
                        Label("Use These", systemImage: "checkmark")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCheckmark = true
            }
        }
    }
}

struct MeasurementSlider: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .foregroundColor(.white.opacity(0.5))
                        .font(.caption2)
                }
                Spacer()
                Text("\(Int(value)) cm")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Slider(value: $value, in: range, step: 0.5)
                .tint(color)
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Step 6: Final

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
                if let bodyFat = viewModel.calculatedBodyFat {
                    SummaryRow(icon: "percent", title: "Body Fat", value: "\(String(format: "%.1f", bodyFat))%")
                }
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
