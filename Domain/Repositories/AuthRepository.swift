import Foundation

/// Protocol for authentication repository
protocol AuthRepository {
    func signInWithApple() async throws -> AuthResponse
    func signOut()
    var isAuthenticated: Bool { get }
}

/// Implementation of AuthRepository
final class AuthRepositoryImpl: AuthRepository {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func signInWithApple() async throws -> AuthResponse {
        try await authService.signInWithApple()
    }

    func signOut() {
        authService.signOut()
    }

    var isAuthenticated: Bool {
        // Check if we have a valid token
        false // Will be implemented with proper token validation
    }
}
