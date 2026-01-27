import Foundation
import AuthenticationServices

/// Service for Apple Sign-In authentication
final class AuthService: NSObject {
    private let apiClient: APIClient
    private let keychainService: KeychainService

    private var authContinuation: CheckedContinuation<AuthResponse, Error>?

    init(apiClient: APIClient, keychainService: KeychainService) {
        self.apiClient = apiClient
        self.keychainService = keychainService
    }

    /// Sign in with Apple
    @MainActor
    func signInWithApple() async throws -> AuthResponse {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            controller.performRequests()
        }
    }

    /// Sign out
    func signOut() {
        keychainService.clearAll()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            authContinuation?.resume(throwing: AuthError.invalidCredentials)
            return
        }

        // Build user name if available
        var userName: String?
        if let fullName = credential.fullName {
            userName = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
        }

        // Call backend to verify token and get JWT
        Task {
            do {
                let response = try await apiClient.signInWithApple(
                    identityToken: tokenString,
                    userName: userName,
                    email: credential.email
                )
                authContinuation?.resume(returning: response)
            } catch {
                authContinuation?.resume(throwing: error)
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        authContinuation?.resume(throwing: error)
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case tokenExpired
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials"
        case .tokenExpired:
            return "Session expired. Please sign in again."
        case .networkError:
            return "Network error. Please try again."
        }
    }
}

// MARK: - Auth Response

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let userId: String
    let isNewUser: Bool
}
