import SwiftUI
import Combine

/// Global application state
@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = true
    @Published var isAuthenticated = false
    @Published var needsOnboarding = true
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?

    // MARK: - Navigation

    @Published var selectedTab: Int = 0
    @Published var pendingChatMessage: String?
    @Published var pendingChatDisplayMessage: String?  // Simplified message shown to user

    // MARK: - Services

    let authService: AuthService
    let apiClient: APIClient
    let keychainService: KeychainService
    let healthKitService: HealthKitService

    // MARK: - Cancellables

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.keychainService = KeychainService()
        self.apiClient = APIClient(keychainService: keychainService)
        self.authService = AuthService(apiClient: apiClient, keychainService: keychainService)
        self.healthKitService = HealthKitService()

        checkAuthStatus()
    }

    // MARK: - Auth Methods

    func checkAuthStatus() {
        Task {
            isLoading = true

            if keychainService.getToken() != nil {
                do {
                    // Try to fetch profile to validate token
                    let profile = try await apiClient.fetchProfile()
                    self.userProfile = profile
                    self.isAuthenticated = true
                    self.needsOnboarding = !profile.onboardingCompleted
                } catch {
                    // Token invalid, clear it
                    keychainService.deleteToken()
                    self.isAuthenticated = false
                }
            }

            isLoading = false
        }
    }

    func signIn(with authResponse: AuthResponse) {
        keychainService.saveToken(authResponse.accessToken)
        currentUser = User(id: authResponse.userId)
        isAuthenticated = true
        needsOnboarding = authResponse.isNewUser
    }

    func signOut() {
        keychainService.deleteToken()
        currentUser = nil
        userProfile = nil
        isAuthenticated = false
        needsOnboarding = true
    }

    func completeOnboarding(profile: UserProfile) {
        userProfile = profile
        needsOnboarding = false
    }

    // MARK: - Navigation Helpers

    func navigateToChatWith(message: String, displayMessage: String? = nil) {
        pendingChatMessage = message
        pendingChatDisplayMessage = displayMessage
        selectedTab = 1  // Chat tab
    }
}
