import SwiftUI

struct RepCounterView: View {
    let count: Int
    let targetReps: Int

    @State private var animationScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Progress ring
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.3), value: progress)

                // Count display
                Text("\(count)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(animationScale)
            }

            Text("\(targetReps - count) to go")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .onChange(of: count) { oldValue, newValue in
            if newValue > oldValue {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    animationScale = 1.2
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5).delay(0.1)) {
                    animationScale = 1.0
                }
            }
        }
    }

    private var progress: CGFloat {
        guard targetReps > 0 else { return 0 }
        return CGFloat(count) / CGFloat(targetReps)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.75 {
            return .yellow
        } else {
            return .white
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
        RepCounterView(count: 7, targetReps: 10)
    }
}
