import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentStep = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Step 1: Basic Info
    @Published var name = ""
    @Published var age: Int?
    @Published var sex: Sex?

    // Step 2: Physical Stats
    @Published var heightCm: Double?
    @Published var weightKg: Double?
    @Published var activityLevel: ActivityLevel?

    // Step 3: Goals
    @Published var goals: [FitnessGoal] = []
    @Published var dietStyle: DietStyle?

    // Step 4: Health
    @Published var healthKitEnabled = false

    // MARK: - Constants

    private let totalSteps = 5
    private let container = DependencyContainer.shared

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
                allergies: [],
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
