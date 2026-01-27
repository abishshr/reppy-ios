import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentStep = 0 {
        didSet { saveProgress() }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Step 1: Basic Info
    @Published var name = "" {
        didSet { saveProgress() }
    }
    @Published var age: Int? {
        didSet { saveProgress() }
    }
    @Published var sex: Sex? {
        didSet { saveProgress() }
    }

    // Step 2: Physical Stats
    @Published var heightCm: Double? {
        didSet { saveProgress() }
    }
    @Published var weightKg: Double? {
        didSet { saveProgress() }
    }
    @Published var activityLevel: ActivityLevel? {
        didSet { saveProgress() }
    }

    // Step 3: Goals
    @Published var goals: [FitnessGoal] = [] {
        didSet { saveProgress() }
    }
    @Published var dietStyle: DietStyle? {
        didSet { saveProgress() }
    }

    // Step 4: Health & Restrictions
    @Published var allergies: [String] = [] {
        didSet { saveProgress() }
    }
    @Published var injuries: [String] = [] {
        didSet { saveProgress() }
    }
    @Published var medicalConditions: [String] = [] {
        didSet { saveProgress() }
    }
    @Published var preferredIngredients: [String] = [] {
        didSet { saveProgress() }
    }

    // Step 5: Body Measurements (Optional)
    @Published var waistCm: Double? {
        didSet { saveProgress() }
    }
    @Published var neckCm: Double? {
        didSet { saveProgress() }
    }
    @Published var hipsCm: Double? {
        didSet { saveProgress() }
    }
    @Published var calculatedBodyFat: Double?
    @Published var bodyFatCategory: String?
    @Published var skipMeasurements = false {
        didSet { saveProgress() }
    }

    // Step 5: Health
    @Published var healthKitEnabled = false

    // MARK: - Constants

    private let totalSteps = 7
    private let container = DependencyContainer.shared
    private var isLoadingProgress = false  // Prevents saving while loading

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let currentStep = "onboarding_currentStep"
        static let name = "onboarding_name"
        static let age = "onboarding_age"
        static let sex = "onboarding_sex"
        static let heightCm = "onboarding_heightCm"
        static let weightKg = "onboarding_weightKg"
        static let activityLevel = "onboarding_activityLevel"
        static let goals = "onboarding_goals"
        static let dietStyle = "onboarding_dietStyle"
        static let allergies = "onboarding_allergies"
        static let injuries = "onboarding_injuries"
        static let medicalConditions = "onboarding_medicalConditions"
        static let preferredIngredients = "onboarding_preferredIngredients"
        static let waistCm = "onboarding_waistCm"
        static let neckCm = "onboarding_neckCm"
        static let hipsCm = "onboarding_hipsCm"
        static let skipMeasurements = "onboarding_skipMeasurements"
        static let hasProgress = "onboarding_hasProgress"
    }

    // MARK: - Init

    init() {
        loadProgress()
    }

    // MARK: - Computed Properties

    var progress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }

    var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    var canProceed: Bool {
        switch currentStep {
        case 0:
            return !name.isEmpty
        case 1:
            return heightCm != nil && weightKg != nil && activityLevel != nil
        case 2:
            return !goals.isEmpty
        case 3:
            return true // Health permissions are optional
        default:
            return true
        }
    }

    // MARK: - Progress Persistence

    private func saveProgress() {
        guard !isLoadingProgress else { return }  // Don't save while loading

        let defaults = UserDefaults.standard

        defaults.set(true, forKey: Keys.hasProgress)
        defaults.set(currentStep, forKey: Keys.currentStep)
        defaults.set(name, forKey: Keys.name)

        if let age = age {
            defaults.set(age, forKey: Keys.age)
        }
        if let sex = sex {
            defaults.set(sex.rawValue, forKey: Keys.sex)
        }
        if let heightCm = heightCm {
            defaults.set(heightCm, forKey: Keys.heightCm)
        }
        if let weightKg = weightKg {
            defaults.set(weightKg, forKey: Keys.weightKg)
        }
        if let activityLevel = activityLevel {
            defaults.set(activityLevel.rawValue, forKey: Keys.activityLevel)
        }

        let goalStrings = goals.map { $0.rawValue }
        defaults.set(goalStrings, forKey: Keys.goals)

        if let dietStyle = dietStyle {
            defaults.set(dietStyle.rawValue, forKey: Keys.dietStyle)
        }

        defaults.set(allergies, forKey: Keys.allergies)
        defaults.set(injuries, forKey: Keys.injuries)
        defaults.set(medicalConditions, forKey: Keys.medicalConditions)
        defaults.set(preferredIngredients, forKey: Keys.preferredIngredients)

        if let waistCm = waistCm {
            defaults.set(waistCm, forKey: Keys.waistCm)
        }
        if let neckCm = neckCm {
            defaults.set(neckCm, forKey: Keys.neckCm)
        }
        if let hipsCm = hipsCm {
            defaults.set(hipsCm, forKey: Keys.hipsCm)
        }

        defaults.set(skipMeasurements, forKey: Keys.skipMeasurements)
    }

    private func loadProgress() {
        let defaults = UserDefaults.standard

        guard defaults.bool(forKey: Keys.hasProgress) else { return }

        isLoadingProgress = true  // Prevent saving while loading

        currentStep = defaults.integer(forKey: Keys.currentStep)
        name = defaults.string(forKey: Keys.name) ?? ""

        let savedAge = defaults.integer(forKey: Keys.age)
        if savedAge > 0 {
            age = savedAge
        }

        if let sexString = defaults.string(forKey: Keys.sex) {
            sex = Sex(rawValue: sexString)
        }

        let savedHeight = defaults.double(forKey: Keys.heightCm)
        if savedHeight > 0 {
            heightCm = savedHeight
        }

        let savedWeight = defaults.double(forKey: Keys.weightKg)
        if savedWeight > 0 {
            weightKg = savedWeight
        }

        if let activityString = defaults.string(forKey: Keys.activityLevel) {
            activityLevel = ActivityLevel(rawValue: activityString)
        }

        if let goalStrings = defaults.stringArray(forKey: Keys.goals) {
            goals = goalStrings.compactMap { FitnessGoal(rawValue: $0) }
        }

        if let dietString = defaults.string(forKey: Keys.dietStyle) {
            dietStyle = DietStyle(rawValue: dietString)
        }

        if let savedAllergies = defaults.stringArray(forKey: Keys.allergies) {
            allergies = savedAllergies
        }
        if let savedInjuries = defaults.stringArray(forKey: Keys.injuries) {
            injuries = savedInjuries
        }
        if let savedConditions = defaults.stringArray(forKey: Keys.medicalConditions) {
            medicalConditions = savedConditions
        }
        if let savedIngredients = defaults.stringArray(forKey: Keys.preferredIngredients) {
            preferredIngredients = savedIngredients
        }

        let savedWaist = defaults.double(forKey: Keys.waistCm)
        if savedWaist > 0 {
            waistCm = savedWaist
        }

        let savedNeck = defaults.double(forKey: Keys.neckCm)
        if savedNeck > 0 {
            neckCm = savedNeck
        }

        let savedHips = defaults.double(forKey: Keys.hipsCm)
        if savedHips > 0 {
            hipsCm = savedHips
        }

        skipMeasurements = defaults.bool(forKey: Keys.skipMeasurements)

        isLoadingProgress = false  // Re-enable saving

        print("📂 Loaded onboarding progress - Step \(currentStep + 1)/\(totalSteps)")
    }

    func clearProgress() {
        let defaults = UserDefaults.standard
        let keys = [
            Keys.hasProgress, Keys.currentStep, Keys.name, Keys.age, Keys.sex,
            Keys.heightCm, Keys.weightKg, Keys.activityLevel, Keys.goals,
            Keys.dietStyle, Keys.allergies, Keys.injuries, Keys.medicalConditions,
            Keys.preferredIngredients, Keys.waistCm, Keys.neckCm, Keys.hipsCm, Keys.skipMeasurements
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
        print("🗑️ Cleared onboarding progress")
    }

    // MARK: - Navigation

    func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    // MARK: - Goals

    func toggleGoal(_ goal: FitnessGoal) {
        if goals.contains(goal) {
            goals.removeAll { $0 == goal }
        } else {
            goals.append(goal)
        }
    }

    // MARK: - HealthKit

    func requestHealthKitAccess() async {
        do {
            try await container.healthKitService.requestAuthorization()
            healthKitEnabled = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func skipHealthKit() {
        healthKitEnabled = false
    }

    // MARK: - Complete Onboarding

    func completeOnboarding(appState: AppState) async {
        isLoading = true
        errorMessage = nil

        print("🚀 Starting onboarding completion...")

        do {
            let profileCreate = ProfileCreate(
                name: name,
                age: age,
                sex: sex?.rawValue,
                heightCm: heightCm,
                weightKg: weightKg,
                activityLevel: activityLevel?.rawValue,
                goals: goals.map { $0.rawValue },
                dietStyle: dietStyle?.rawValue,
                allergies: allergies,
                injuries: injuries,
                medicalConditions: medicalConditions,
                preferredIngredients: preferredIngredients,
                equipment: [],
                dailyStepsGoal: 10000
            )

            print("📝 Creating profile...")
            var profile = try await container.profileRepository.createProfile(profileCreate)
            print("✅ Profile created: \(profile.id)")

            // Mark onboarding as complete
            let update = ProfileUpdate(
                name: nil,
                age: nil,
                sex: nil,
                heightCm: nil,
                weightKg: nil,
                activityLevel: nil,
                goals: nil,
                dietStyle: nil,
                allergies: nil,
                onboardingCompleted: true
            )
            print("📝 Updating profile with onboardingCompleted...")
            profile = try await container.profileRepository.updateProfile(update)
            print("✅ Profile updated")

            // Sync initial steps if health is enabled
            if healthKitEnabled {
                print("📝 Syncing HealthKit steps...")
                _ = try? await container.activityRepository.syncTodaySteps()
            }

            // Save body measurements if entered
            if !skipMeasurements, let waist = waistCm, let neck = neckCm {
                print("📝 Saving body measurements...")
                let measurementCreate = BodyMeasurementCreate(
                    neckCm: neck,
                    waistCm: waist,
                    hipsCm: hipsCm,
                    bodyFatPercentage: calculatedBodyFat
                )
                _ = try? await container.apiClient.createMeasurement(measurementCreate)
                print("✅ Body measurements saved")
            }

            // Clear saved progress since onboarding is complete
            clearProgress()

            print("🎉 Completing onboarding in AppState...")
            appState.completeOnboarding(profile: profile)
            print("✅ Onboarding complete!")
        } catch {
            print("❌ Onboarding error: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
