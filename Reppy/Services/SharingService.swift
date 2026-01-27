import SwiftUI
import UIKit

// Uses StreakMilestone from Streak.swift

enum SharingCardType {
    case streakMilestone(days: Int, milestone: StreakMilestone)
    case weightProgress(startWeight: Double, currentWeight: Double, goalWeight: Double?, unit: String)
    case personalRecord(exercise: String, weight: Double, previousWeight: Double?, unit: String)
    case mealPlanComplete(planName: String, daysCompleted: Int)
    case workoutComplete(workoutName: String, exerciseCount: Int, duration: Int)
    case calorieGoal(targetCalories: Int, streak: Int)
}

@MainActor
class SharingService {
    static let shared = SharingService()

    private init() {}

    // MARK: - Card Generation

    func generateCard(type: SharingCardType, size: CGSize = CGSize(width: 1080, height: 1920)) -> UIImage? {
        let cardView: some View = {
            switch type {
            case .streakMilestone(let days, let milestone):
                return AnyView(StreakMilestoneCardView(days: days, milestone: milestone))
            case .weightProgress(let start, let current, let goal, let unit):
                return AnyView(WeightProgressCardView(startWeight: start, currentWeight: current, goalWeight: goal, unit: unit))
            case .personalRecord(let exercise, let weight, let previous, let unit):
                return AnyView(PersonalRecordCardView(exercise: exercise, weight: weight, previousWeight: previous, unit: unit))
            case .mealPlanComplete(let name, let days):
                return AnyView(MealPlanCompleteCardView(planName: name, daysCompleted: days))
            case .workoutComplete(let name, let exerciseCount, let duration):
                return AnyView(WorkoutCompleteCardView(workoutName: name, exerciseCount: exerciseCount, duration: duration))
            case .calorieGoal(let calories, let streak):
                return AnyView(CalorieGoalCardView(targetCalories: calories, streak: streak))
            }
        }()

        return renderToImage(cardView, size: size)
    }

    // MARK: - Share

    func share(image: UIImage, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }

    // MARK: - Private

    private func renderToImage<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view.frame(width: size.width, height: size.height))
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Card Background Gradient

struct CardGradientBackground: View {
    let colors: [Color]

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Reppy Branding Footer

struct ReppyBranding: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.title2)
            Text("Reppy")
                .font(.title2)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white.opacity(0.8))
    }
}
