import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)

                    Text("Reppy")
                        .font(.system(size: 48, weight: .bold))

                    Text("Your AI Fitness Coach")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "mic.fill", text: "Log meals with voice")
                    FeatureRow(icon: "camera.fill", text: "Snap photos for nutrition")
                    FeatureRow(icon: "dumbbell.fill", text: "Track workouts easily")
                    FeatureRow(icon: "heart.fill", text: "Sync with Apple Health")
                }
                .padding(.horizontal, 40)

                Spacer()

                // Sign in with Apple button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.email, .fullName]
                    },
                    onCompletion: { result in
                        viewModel.handleSignInResult(result, appState: appState)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, 40)

                // Loading indicator
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }

                // Terms
                Text("By signing in, you agree to our Terms & Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environmentObject(AppState())
}
