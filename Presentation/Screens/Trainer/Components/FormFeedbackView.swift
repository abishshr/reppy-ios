import SwiftUI

struct FormFeedbackView: View {
    let status: FormStatus
    let correction: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.displayText.isEmpty ? " " : status.displayText)
                    .font(.headline)
                    .foregroundStyle(.white)

                if let correction = correction, status == .needsCorrection {
                    Text(correction)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: status)
    }

    private var iconName: String {
        switch status {
        case .good:
            return "checkmark.circle.fill"
        case .needsCorrection:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "figure.stand"
        }
    }

    private var iconColor: Color {
        switch status {
        case .good:
            return .green
        case .needsCorrection:
            return .orange
        case .unknown:
            return .white.opacity(0.5)
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .good:
            return .green.opacity(0.2)
        case .needsCorrection:
            return .orange.opacity(0.2)
        case .unknown:
            return .white.opacity(0.1)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black

        VStack(spacing: 20) {
            FormFeedbackView(status: .good, correction: nil)
            FormFeedbackView(status: .needsCorrection, correction: "Keep your knees behind your toes")
            FormFeedbackView(status: .unknown, correction: nil)
        }
        .padding()
    }
}
