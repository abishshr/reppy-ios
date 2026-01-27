import SwiftUI

/// Visual overlay showing positioning guidance
struct InFrameGuidanceView: View {
    let guidance: PositioningGuidance

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Guidance card
            VStack(spacing: 16) {
                Image(systemName: guidance.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)

                Text(guidance.message)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Silhouette hint
                if !guidance.isFullBody {
                    HStack(spacing: 30) {
                        // Left arrow
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))

                        // Body silhouette
                        Image(systemName: "figure.stand")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.3))

                        // Right arrow
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )

            Spacer()
            Spacer()
        }
        .padding()
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.easeInOut(duration: 0.3), value: guidance.message)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black

        InFrameGuidanceView(
            guidance: PositioningGuidance(
                message: "Step back so your whole body is visible",
                icon: "arrow.backward.circle.fill",
                isFullBody: false
            )
        )
    }
}
