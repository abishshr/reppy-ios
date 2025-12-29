import Foundation

/// Plan type for creation
enum PlanType: String, CaseIterable {
    case workout
    case meal

    var title: String {
        switch self {
        case .workout: return "Workout Plan"
        case .meal: return "Meal Plan"
        }
    }

    var icon: String {
        switch self {
        case .workout: return "dumbbell.fill"
        case .meal: return "fork.knife"
        }
    }
}

/// Creation mode for plan
enum CreationMode: String, CaseIterable {
    case quick
    case customize
    case manual

    var title: String {
        switch self {
        case .quick: return "Quick"
        case .customize: return "Customize"
        case .manual: return "Manual"
        }
    }

    var description: String {
        switch self {
        case .quick: return "AI creates plan from your profile"
        case .customize: return "Guide AI with your preferences"
        case .manual: return "Build your own plan"
        }
    }
}
