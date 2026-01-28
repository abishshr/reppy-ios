import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section("Profile") {
                    if let profile = appState.userProfile {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(profile.name ?? "Not set")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Goals")
                            Spacer()
                            Text(profile.goals.map { $0.displayName }.joined(separator: ", "))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        NavigationLink("Edit Profile") {
                            ProfileEditView(profile: profile)
                        }
                    }
                }

                // Progress Section
                Section("Analytics") {
                    NavigationLink {
                        StatsView()
                    } label: {
                        Label("Progress & Stats", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                // Targets Section
                Section {
                    if let profile = appState.userProfile {
                        TargetRow(name: "Calories", value: profile.dailyCalorieTarget, unit: "cal")
                        TargetRow(name: "Protein", value: Int(profile.dailyProteinTarget ?? 0), unit: "g")
                        TargetRow(name: "Carbs", value: Int(profile.dailyCarbsTarget ?? 0), unit: "g")
                        TargetRow(name: "Fat", value: Int(profile.dailyFatTarget ?? 0), unit: "g")
                        TargetRow(name: "Steps", value: profile.dailyStepsGoal, unit: "")

                        NavigationLink("Edit Targets") {
                            DailyTargetsEditView(profile: profile)
                                .environmentObject(appState)
                        }
                    }
                } header: {
                    Text("Daily Targets")
                }

                // Micronutrient Limits Section
                Section {
                    if let profile = appState.userProfile {
                        TargetRow(name: "Fiber", value: Int(profile.dailyFiberTargetG ?? 28), unit: "g")
                        TargetRow(name: "Sugar", value: Int(profile.dailySugarTargetG ?? 50), unit: "g")
                        TargetRow(name: "Sodium", value: Int(profile.dailySodiumTargetMg ?? 2300), unit: "mg")
                        TargetRow(name: "Saturated Fat", value: Int(profile.dailySaturatedFatTargetG ?? 20), unit: "g")

                        NavigationLink("Edit Limits") {
                            MicronutrientTargetsEditView(profile: profile)
                                .environmentObject(appState)
                        }
                    }
                } header: {
                    Text("Micronutrient Limits")
                } footer: {
                    Text("Based on FDA daily value recommendations for a 2,000 calorie diet.")
                }

                // Vitamin & Mineral Targets Section
                Section {
                    if let profile = appState.userProfile {
                        let targets = MicronutrientCalculatorService.shared.calculateTargets(from: profile)

                        // Quick summary of key vitamins
                        HStack {
                            Image(systemName: "pill.fill")
                                .foregroundColor(.orange)
                            Text("Vitamin D")
                            Spacer()
                            Text("\(Int(targets.vitaminD)) mcg")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.red)
                            Text("Iron")
                            Spacer()
                            Text("\(Int(targets.iron)) mg")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                            Text("Calcium")
                            Spacer()
                            Text("\(Int(targets.calcium)) mg")
                                .foregroundColor(.secondary)
                        }

                        NavigationLink {
                            MicronutrientTargetsView(profile: profile)
                        } label: {
                            HStack {
                                Text("View All Vitamins & Minerals")
                                Spacer()
                                Text("\(targets.allNutrients.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Vitamin & Mineral Targets")
                } footer: {
                    Text("Personalized DRI targets based on your age, sex, activity level, and diet style.")
                }

                // Health Section
                Section("Health Integration") {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Apple Health")
                        Spacer()
                        Text(viewModel.healthKitStatus)
                            .foregroundColor(.secondary)
                    }

                    Button("Sync Steps Now") {
                        Task { await viewModel.syncSteps() }
                    }
                }

                // Body Measurements Section
                Section {
                    NavigationLink {
                        BodyMeasurementsView()
                    } label: {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.purple)
                            Text("Body Measurements")
                        }
                    }

                    if let latestBodyFat = viewModel.latestBodyFat {
                        HStack {
                            Text("Latest Body Fat")
                            Spacer()
                            Text("\(String(format: "%.1f", latestBodyFat))%")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Body Composition")
                } footer: {
                    Text("Track waist, neck, and hip measurements to estimate body fat %.")
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link("Privacy Policy", destination: URL(string: "https://reppy.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://reppy.app/terms")!)
                }

                // Danger Zone
                Section {
                    Button("Sign Out", role: .destructive) {
                        viewModel.showSignOutConfirmation = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $viewModel.showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Target Row

struct TargetRow: View {
    let name: String
    let value: Int?
    let unit: String

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            if let value = value {
                Text("\(value)\(unit)")
                    .foregroundColor(.secondary)
            } else {
                Text("Not set")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    let profile: UserProfile

    var body: some View {
        Text("Profile editing coming soon")
            .navigationTitle("Edit Profile")
    }
}

// MARK: - Daily Targets Edit View

struct DailyTargetsEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile

    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var steps: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let container = DependencyContainer.shared

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("2000", text: $calories)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("cal")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Protein")
                    Spacer()
                    TextField("150", text: $protein)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("g")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Carbs")
                    Spacer()
                    TextField("250", text: $carbs)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("g")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Fat")
                    Spacer()
                    TextField("65", text: $fat)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("g")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Steps")
                    Spacer()
                    TextField("10000", text: $steps)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            } footer: {
                Text("These targets help track your daily nutrition and activity goals.")
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Edit Targets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await saveTargets() }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            calories = profile.dailyCalorieTarget.map { String($0) } ?? ""
            protein = profile.dailyProteinTarget.map { String(Int($0)) } ?? ""
            carbs = profile.dailyCarbsTarget.map { String(Int($0)) } ?? ""
            fat = profile.dailyFatTarget.map { String(Int($0)) } ?? ""
            steps = profile.dailyStepsGoal.map { String($0) } ?? ""
        }
    }

    private func saveTargets() async {
        isSaving = true
        errorMessage = nil

        var update = ProfileUpdate()
        update.dailyCalorieTarget = Int(calories)
        update.dailyProteinTarget = Double(protein)
        update.dailyCarbsTarget = Double(carbs)
        update.dailyFatTarget = Double(fat)
        update.dailyStepsGoal = Int(steps)

        do {
            let updated = try await container.profileRepository.updateProfile(update)
            appState.userProfile = updated
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - Micronutrient Targets Edit View

struct MicronutrientTargetsEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile

    @State private var fiber: String = ""
    @State private var sugar: String = ""
    @State private var sodium: String = ""
    @State private var saturatedFat: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let container = DependencyContainer.shared

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fiber")
                        Text("Goal to reach")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    TextField("28", text: $fiber)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("g")
                        .foregroundColor(.secondary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sugar")
                        Text("Limit to stay under")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    TextField("50", text: $sugar)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("g")
                        .foregroundColor(.secondary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sodium")
                        Text("Limit to stay under")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    TextField("2300", text: $sodium)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("mg")
                        .foregroundColor(.secondary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saturated Fat")
                        Text("Limit to stay under")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    TextField("20", text: $saturatedFat)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("g")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Daily Limits")
            } footer: {
                Text("Fiber is a goal to reach. Sugar, sodium, and saturated fat are limits to stay under. Based on FDA recommendations for a 2,000 calorie diet.")
            }

            Section {
                Button("Reset to FDA Defaults") {
                    fiber = "28"
                    sugar = "50"
                    sodium = "2300"
                    saturatedFat = "20"
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Micronutrient Limits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await saveTargets() }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            fiber = String(Int(profile.dailyFiberTargetG ?? 28))
            sugar = String(Int(profile.dailySugarTargetG ?? 50))
            sodium = String(Int(profile.dailySodiumTargetMg ?? 2300))
            saturatedFat = String(Int(profile.dailySaturatedFatTargetG ?? 20))
        }
    }

    private func saveTargets() async {
        isSaving = true
        errorMessage = nil

        var update = ProfileUpdate()
        update.dailyFiberTargetG = Double(fiber)
        update.dailySugarTargetG = Double(sugar)
        update.dailySodiumTargetMg = Double(sodium)
        update.dailySaturatedFatTargetG = Double(saturatedFat)

        do {
            let updated = try await container.profileRepository.updateProfile(update)
            appState.userProfile = updated
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - Micronutrient Targets View

struct MicronutrientTargetsView: View {
    let profile: UserProfile
    @State private var selectedCategory: MicronutrientCategory = .vitamin
    @State private var targets: MicronutrientTargets?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let targets = targets {
                MicronutrientContentView(
                    profile: profile,
                    targets: targets,
                    selectedCategory: $selectedCategory
                )
            }
        }
        .navigationTitle("Micronutrients")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Calculate targets off main thread perception
            await MainActor.run {
                targets = MicronutrientCalculatorService.shared.calculateTargets(from: profile)
                withAnimation(.easeOut(duration: 0.2)) {
                    isLoading = false
                }
            }
        }
    }
}

// Separate content view for better performance
private struct MicronutrientContentView: View {
    let profile: UserProfile
    let targets: MicronutrientTargets
    @Binding var selectedCategory: MicronutrientCategory

    var body: some View {
        List {
            // Profile Summary
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calculated for")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(profileSummary)
                            .font(.subheadline)
                    }
                    Spacer()
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }

            // Diet Adjustments
            if !targets.adjustments.isEmpty {
                Section {
                    ForEach(targets.adjustments, id: \.self) { adjustment in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(adjustment)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Diet-Specific Notes")
                }
            }

            // Category Picker
            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(MicronutrientCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            // Nutrients for selected category
            Section {
                ForEach(targets.nutrients(for: selectedCategory)) { nutrient in
                    NutrientRowOptimized(nutrient: nutrient)
                }
            } header: {
                Text(selectedCategory.rawValue)
            }
        }
    }

    private var profileSummary: String {
        var parts: [String] = []
        if let age = profile.age {
            parts.append("\(age) years old")
        }
        if let sex = profile.sex {
            parts.append(sex.displayName)
        }
        if let activity = profile.activityLevel {
            parts.append(activity.displayName)
        }
        if let diet = profile.dietStyle {
            parts.append(diet.displayName)
        }
        return parts.joined(separator: " • ")
    }
}

// Optimized nutrient row without FlowLayout
private struct NutrientRowOptimized: View {
    let nutrient: MicronutrientInfo
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(nutrient.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(nutrient.formattedTarget) \(nutrient.unit)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text(nutrient.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Food Sources")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    // Simple horizontal scroll instead of FlowLayout
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(nutrient.foodSources, id: \.self) { source in
                                Text(source)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(categoryColor.opacity(0.1))
                                    .foregroundColor(categoryColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch nutrient.category {
        case .vitamin: return .orange
        case .mineral: return .blue
        case .other: return .green
        }
    }
}

// MARK: - Nutrient Row

struct NutrientRow: View {
    let nutrient: MicronutrientInfo
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nutrient.name)
                            .font(.body)
                            .foregroundColor(.primary)
                        if isExpanded {
                            Text(nutrient.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text("\(nutrient.formattedTarget) \(nutrient.unit)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Food Sources")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(nutrient.foodSources, id: \.self) { source in
                            Text(source)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(categoryColor.opacity(0.1))
                                .foregroundColor(categoryColor)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch nutrient.category {
        case .vitamin: return .orange
        case .mineral: return .blue
        case .other: return .green
        }
    }
}

// MARK: - Micronutrient Progress View (Consumed vs Target)

struct MicronutrientProgressView: View {
    let profile: UserProfile
    let consumed: VitaminMineralTotals
    let targets: MicronutrientTargets?

    @State private var expandedVitamins = true
    @State private var expandedMinerals = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Card
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        OverallProgressRing(
                            consumed: consumed,
                            targets: targets
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Progress")
                                .font(.headline)

                            let stats = progressStats
                            Text("\(stats.onTrack) nutrients on track")
                                .font(.subheadline)
                                .foregroundColor(.green)

                            if stats.low > 0 {
                                Text("\(stats.low) below target")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        Spacer()
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // Vitamins Section (Dropdown)
                NutrientDropdownSection(
                    title: "Vitamins",
                    icon: "pill.fill",
                    color: .orange,
                    isExpanded: $expandedVitamins,
                    items: nutrientItems(for: .vitamin)
                )

                // Minerals Section (Dropdown)
                NutrientDropdownSection(
                    title: "Minerals",
                    icon: "atom",
                    color: .blue,
                    isExpanded: $expandedMinerals,
                    items: nutrientItems(for: .mineral)
                )
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Vitamins & Minerals")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressStats: (onTrack: Int, low: Int) {
        var onTrack = 0
        var low = 0

        for item in allNutrientItems {
            if item.percentComplete >= 80 {
                onTrack += 1
            } else if item.consumed > 0 && item.percentComplete < 50 {
                low += 1
            }
        }

        return (onTrack, low)
    }

    private var allNutrientItems: [NutrientProgressItem] {
        nutrientItems(for: .vitamin) + nutrientItems(for: .mineral)
    }

    private func nutrientItems(for category: MicronutrientCategory) -> [NutrientProgressItem] {
        switch category {
        case .vitamin:
            return [
                NutrientProgressItem(name: "Vitamin A", consumed: consumed.vitaminA, target: targets?.vitaminA ?? 900, unit: "mcg", icon: "a.circle.fill", color: .orange),
                NutrientProgressItem(name: "Vitamin C", consumed: consumed.vitaminC, target: targets?.vitaminC ?? 90, unit: "mg", icon: "c.circle.fill", color: .orange),
                NutrientProgressItem(name: "Vitamin D", consumed: consumed.vitaminD, target: targets?.vitaminD ?? 15, unit: "mcg", icon: "d.circle.fill", color: .orange),
                NutrientProgressItem(name: "Vitamin E", consumed: consumed.vitaminE, target: targets?.vitaminE ?? 15, unit: "mg", icon: "e.circle.fill", color: .orange),
                NutrientProgressItem(name: "Vitamin K", consumed: consumed.vitaminK, target: targets?.vitaminK ?? 120, unit: "mcg", icon: "k.circle.fill", color: .orange),
                NutrientProgressItem(name: "Thiamin (B1)", consumed: consumed.thiamin, target: targets?.thiamin ?? 1.2, unit: "mg", icon: "1.circle.fill", color: .orange),
                NutrientProgressItem(name: "Riboflavin (B2)", consumed: consumed.riboflavin, target: targets?.riboflavin ?? 1.3, unit: "mg", icon: "2.circle.fill", color: .orange),
                NutrientProgressItem(name: "Niacin (B3)", consumed: consumed.niacin, target: targets?.niacin ?? 16, unit: "mg", icon: "3.circle.fill", color: .orange),
                NutrientProgressItem(name: "Vitamin B6", consumed: consumed.vitaminB6, target: targets?.vitaminB6 ?? 1.3, unit: "mg", icon: "6.circle.fill", color: .orange),
                NutrientProgressItem(name: "Folate (B9)", consumed: consumed.folate, target: targets?.folate ?? 400, unit: "mcg", icon: "9.circle.fill", color: .orange),
                NutrientProgressItem(name: "Vitamin B12", consumed: consumed.vitaminB12, target: targets?.vitaminB12 ?? 2.4, unit: "mcg", icon: "12.circle", color: .orange),
            ]
        case .mineral:
            return [
                NutrientProgressItem(name: "Calcium", consumed: consumed.calcium, target: targets?.calcium ?? 1000, unit: "mg", icon: "circle.fill", color: .blue),
                NutrientProgressItem(name: "Iron", consumed: consumed.iron, target: targets?.iron ?? 8, unit: "mg", icon: "circle.fill", color: .blue),
                NutrientProgressItem(name: "Magnesium", consumed: consumed.magnesium, target: targets?.magnesium ?? 420, unit: "mg", icon: "circle.fill", color: .blue),
                NutrientProgressItem(name: "Phosphorus", consumed: consumed.phosphorus, target: targets?.phosphorus ?? 700, unit: "mg", icon: "circle.fill", color: .blue),
                NutrientProgressItem(name: "Potassium", consumed: consumed.potassium, target: targets?.potassium ?? 3400, unit: "mg", icon: "circle.fill", color: .blue),
                NutrientProgressItem(name: "Zinc", consumed: consumed.zinc, target: targets?.zinc ?? 11, unit: "mg", icon: "circle.fill", color: .blue),
                NutrientProgressItem(name: "Selenium", consumed: consumed.selenium, target: targets?.selenium ?? 55, unit: "mcg", icon: "circle.fill", color: .blue),
                NutrientProgressItem(name: "Copper", consumed: consumed.copper, target: targets?.copper ?? 900, unit: "mcg", icon: "circle.fill", color: .blue),
                NutrientProgressItem(name: "Manganese", consumed: consumed.manganese, target: targets?.manganese ?? 2.3, unit: "mg", icon: "circle.fill", color: .blue),
            ]
        case .other:
            // Omega-3 and Choline are not currently tracked in meal data
            return []
        }
    }
}

// MARK: - Nutrient Dropdown Section

private struct NutrientDropdownSection: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var isExpanded: Bool
    let items: [NutrientProgressItem]

    private var completedCount: Int {
        items.filter { $0.percentComplete >= 80 }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                            .frame(width: 28)

                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // Progress indicator
                    Text("\(completedCount)/\(items.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(completedCount == items.count ? .green : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(completedCount == items.count ? Color.green.opacity(0.15) : Color(.tertiarySystemFill))
                        .cornerRadius(8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        VStack(spacing: 0) {
                            Divider()
                                .padding(.leading, 48)

                            MicroProgressRow(item: item)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Overall Progress Ring

private struct OverallProgressRing: View {
    let consumed: VitaminMineralTotals
    let targets: MicronutrientTargets?

    private var averageProgress: Double {
        guard let targets = targets else { return 0 }

        let items: [(Double, Double)] = [
            (consumed.vitaminA, targets.vitaminA),
            (consumed.vitaminC, targets.vitaminC),
            (consumed.vitaminD, targets.vitaminD),
            (consumed.calcium, targets.calcium),
            (consumed.iron, targets.iron),
            (consumed.magnesium, targets.magnesium),
        ]

        let progresses = items.map { min(1.0, $0.0 / max(1, $0.1)) }
        return progresses.reduce(0, +) / Double(progresses.count)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                .frame(width: 70, height: 70)

            Circle()
                .trim(from: 0, to: averageProgress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))

            Text("\(Int(averageProgress * 100))%")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(progressColor)
        }
    }

    private var progressColor: Color {
        if averageProgress >= 0.8 { return .green }
        if averageProgress >= 0.5 { return .orange }
        return .red
    }
}

// MARK: - Nutrient Progress Item

struct NutrientProgressItem: Identifiable {
    let id = UUID()
    let name: String
    let consumed: Double
    let target: Double
    let unit: String
    let icon: String
    let color: Color

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, consumed / target)
    }

    var percentComplete: Int {
        Int(progress * 100)
    }

    var formattedConsumed: String {
        if consumed >= 100 {
            return String(format: "%.0f", consumed)
        } else if consumed >= 10 {
            return String(format: "%.1f", consumed)
        } else {
            return String(format: "%.2f", consumed)
        }
    }

    var formattedTarget: String {
        if target >= 100 {
            return String(format: "%.0f", target)
        } else if target >= 10 {
            return String(format: "%.1f", target)
        } else {
            return String(format: "%.2f", target)
        }
    }
}

// MARK: - Micro Progress Row

private struct MicroProgressRow: View {
    let item: NutrientProgressItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                // Consumed vs Target
                HStack(spacing: 4) {
                    Text(item.formattedConsumed)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColor)

                    Text("/")
                        .foregroundColor(.secondary)

                    Text("\(item.formattedTarget) \(item.unit)")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.color.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * item.progress, height: 8)
                }
            }
            .frame(height: 8)

            // Percentage label
            HStack {
                Text("\(item.percentComplete)% of daily target")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if item.percentComplete >= 100 {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else if item.percentComplete < 25 && item.consumed > 0 {
                    Text("Low")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var progressColor: Color {
        if item.percentComplete >= 80 { return .green }
        if item.percentComplete >= 50 { return item.color }
        if item.percentComplete >= 25 { return .orange }
        return .red
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
