import Foundation

/// Issues detected during workout setup that AI coach should address
struct SetupIssue: Equatable {
    let type: String
    let message: String

    // MARK: - Predefined Issues

    static let notInFrame = SetupIssue(
        type: "not_in_frame",
        message: "User is not visible in the camera frame"
    )

    static let legsNotVisible = SetupIssue(
        type: "legs_not_visible",
        message: "User's legs are not visible - they need to step back"
    )

    static let upperBodyNotVisible = SetupIssue(
        type: "upper_body_not_visible",
        message: "User's head and shoulders are not visible - they need to step forward or adjust phone"
    )

    static let tooClose = SetupIssue(
        type: "too_close",
        message: "User is too close to the camera for full body tracking"
    )

    static let lowLighting = SetupIssue(
        type: "low_lighting",
        message: "Lighting appears too dim for accurate pose detection"
    )

    static let phoneUnstable = SetupIssue(
        type: "phone_unstable",
        message: "Camera appears to be moving - phone should be propped up stable"
    )

    static func custom(type: String, message: String) -> SetupIssue {
        SetupIssue(type: type, message: message)
    }
}
