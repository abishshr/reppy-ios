import Foundation

/// Dependency injection container
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()

    // MARK: - Services

    lazy var keychainService: KeychainService = {
        KeychainService()
    }()

    lazy var apiClient: APIClient = {
        APIClient(keychainService: keychainService)
    }()

    lazy var authService: AuthService = {
        AuthService(apiClient: apiClient, keychainService: keychainService)
    }()

    lazy var healthKitService: HealthKitService = {
        HealthKitService()
    }()

    lazy var speechService: SpeechService = {
        SpeechService()
    }()

    // MARK: - Repositories

    lazy var authRepository: AuthRepository = {
        AuthRepositoryImpl(authService: authService)
    }()

    lazy var profileRepository: ProfileRepository = {
        ProfileRepositoryImpl(apiClient: apiClient)
    }()

    lazy var mealRepository: MealRepository = {
        MealRepositoryImpl(apiClient: apiClient)
    }()

    lazy var workoutRepository: WorkoutRepository = {
        WorkoutRepositoryImpl(apiClient: apiClient)
    }()

    lazy var activityRepository: ActivityRepository = {
        ActivityRepositoryImpl(apiClient: apiClient, healthKitService: healthKitService)
    }()

    lazy var chatRepository: ChatRepository = {
        ChatRepositoryImpl(apiClient: apiClient)
    }()

    lazy var mealPlanRepository: MealPlanRepository = {
        MealPlanRepositoryImpl(apiClient: apiClient)
    }()

    lazy var workoutPlanRepository: WorkoutPlanRepository = {
        WorkoutPlanRepositoryImpl(apiClient: apiClient)
    }()

    lazy var foodRepository: FoodRepository = {
        FoodRepositoryImpl(apiClient: apiClient)
    }()

    lazy var streakRepository: StreakRepository = {
        StreakRepository(apiClient: apiClient)
    }()

    private init() {}
}
