import Foundation

/// App-wide constants
enum Constants {
    /// API configuration
    enum API {
        #if DEBUG
        // Use localhost for simulator, ngrok for physical device
        #if targetEnvironment(simulator)
        static let baseURL = "http://localhost:8000/api/v1"
        #else
        // ngrok tunnel for device testing - update this URL when ngrok restarts
        static let baseURL = "https://uncontagiously-unplastic-sabrina.ngrok-free.dev/api/v1"
        #endif
        #else
        static let baseURL = "https://reppy-api.onrender.com/api/v1"
        #endif

        static let timeout: TimeInterval = 30
    }

    /// Keychain keys
    enum Keychain {
        static let accessToken = "com.reppy.accessToken"
        static let userId = "com.reppy.userId"
    }

    /// UserDefaults keys
    enum UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastStepsSync = "lastStepsSync"
    }

    /// Default values
    enum Defaults {
        static let dailyStepsGoal = 10000
        static let dailyCalorieTarget = 2000
    }

    /// Supabase configuration
    enum Supabase {
        static let url = "https://kenkdboykpzblypatjro.supabase.co"
        static let anonKey = "sb_publishable_U6MS9inLoJIpzv5YAOS8xg_GggmQ1Na"
        static let bucket = "meal-images"
    }

    /// Pipecat AI Coach configuration
    enum Pipecat {
        #if DEBUG
        // Use Mac's IP for physical device testing, localhost for simulator
        // Change this IP to your Mac's local IP when testing on physical device
        static let baseURL = "http://192.168.110.47:7860"
        #else
        static let baseURL = "https://api.reppy.app/pipecat"
        #endif
    }
}
