import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let container = DependencyContainer.shared

    func handleSignInResult(
        _ result: Result<ASAuthorization, Error>,
        appState: AppState
    ) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                errorMessage = "Failed to get credentials"
                return
            }

            isLoading = true
            errorMessage = nil

            Task {
                do {
                    // Get user name if available (first sign-in only)
                    var userName: String?
                    if let fullName = credential.fullName {
                        userName = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                    }

                    let response = try await container.apiClient.signInWithApple(
                        identityToken: tokenString,
                        userName: userName?.isEmpty == false ? userName : nil,
                        email: credential.email
                    )

                    appState.signIn(with: response)
                } catch {
                    errorMessage = error.localizedDescription
                }

                isLoading = false
            }

        case .failure(let error):
            // User cancelled is not an error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }
}
