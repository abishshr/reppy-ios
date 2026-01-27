import SwiftUI

struct TrainerControlBar: View {
    let state: TrainerState
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void
    let onCompleteSet: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            switch state {
            case .active:
                // Pause button
                ControlButton(
                    icon: "pause.fill",
                    label: "Pause",
                    style: .secondary,
                    action: onPause
                )

                // Complete set button
                ControlButton(
                    icon: "checkmark",
                    label: "Complete Set",
                    style: .primary,
                    action: onCompleteSet
                )

                // End button
                ControlButton(
                    icon: "xmark",
                    label: "End",
                    style: .destructive,
                    action: onEnd
                )

            case .paused:
                // Resume button
                ControlButton(
                    icon: "play.fill",
                    label: "Resume",
                    style: .primary,
                    action: onResume
                )

                // End button
                ControlButton(
                    icon: "xmark",
                    label: "End",
                    style: .destructive,
                    action: onEnd
                )

            case .resting:
                // End button only during rest
                ControlButton(
                    icon: "xmark",
                    label: "End Workout",
                    style: .destructive,
                    action: onEnd
                )

            case .preparing, .idle:
                // No controls during countdown
                EmptyView()

            case .setComplete, .exerciseComplete, .error:
                // No controls
                EmptyView()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let icon: String
    let label: String
    let style: ControlButtonStyle
    let action: () -> Void

    enum ControlButtonStyle {
        case primary
        case secondary
        case destructive
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)

                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(foregroundColor)
            .frame(minWidth: 60)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .green
        case .secondary:
            return .white
        case .destructive:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black

        VStack(spacing: 30) {
            TrainerControlBar(
                state: .active,
                onPause: {},
                onResume: {},
                onEnd: {},
                onCompleteSet: {}
            )

            TrainerControlBar(
                state: .paused,
                onPause: {},
                onResume: {},
                onEnd: {},
                onCompleteSet: {}
            )

            TrainerControlBar(
                state: .resting(timeRemaining: 30),
                onPause: {},
                onResume: {},
                onEnd: {},
                onCompleteSet: {}
            )
        }
    }
}
