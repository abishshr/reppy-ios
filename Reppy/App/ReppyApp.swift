import SwiftUI

@main
struct ReppyApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Pre-warm the keyboard on app launch
        KeyboardPrewarmer.shared.prewarm()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Keyboard Prewarmer

final class KeyboardPrewarmer {
    static let shared = KeyboardPrewarmer()

    private init() {}

    func prewarm() {
        // Delay to ensure window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let textField = UITextField()
            textField.alpha = 0

            // Add to window briefly
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addSubview(textField)
                textField.becomeFirstResponder()

                // Dismiss after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    textField.resignFirstResponder()
                    textField.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else if appState.isAuthenticated {
                if appState.needsOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: appState.isAuthenticated)
    }
}

// MARK: - Splash View

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)

                Text("Reppy")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                ProgressView()
                    .padding(.top)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var chatViewModel = ChatViewModel()
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView(onSuggestMeal: requestMealSuggestion)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ChatViewWrapper(viewModel: chatViewModel)
                .tabItem {
                    Label("Coach", systemImage: "message.fill")
                }
                .tag(1)

            FoodTabView()
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }
                .tag(2)

            WorkoutTabView()
                .tabItem {
                    Label("Workout", systemImage: "dumbbell.fill")
                }
                .tag(3)

            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            // Handle pending chat message when switching to chat tab
            if newValue == 1, let message = appState.pendingChatMessage {
                let displayMessage = appState.pendingChatDisplayMessage
                appState.pendingChatMessage = nil
                appState.pendingChatDisplayMessage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Task {
                        await chatViewModel.sendMessage(message, displayText: displayMessage)
                    }
                }
            }
        }
    }

    private func requestMealSuggestion() {
        impactMedium.impactOccurred()
        appState.navigateToChatWith(message: "Suggest a healthy meal based on my remaining macros and goals")
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environmentObject(AppState())
}
