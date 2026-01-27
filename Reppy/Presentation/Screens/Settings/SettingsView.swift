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

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
