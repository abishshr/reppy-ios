import SwiftUI

struct FastingStatusView: View {
    @State private var data: WidgetData = WidgetDataManager.shared.load() ?? .placeholder
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var fastingProgress: Double {
        guard data.isFasting,
              let startedAt = data.fastingStartedAt,
              let targetEnd = data.fastingTargetEndAt else {
            return 0
        }

        let totalDuration = targetEnd.timeIntervalSince(startedAt)
        let elapsed = currentTime.timeIntervalSince(startedAt)

        guard totalDuration > 0 else { return 0 }
        return min(1.0, max(0, elapsed / totalDuration))
    }

    private var timeRemaining: TimeInterval {
        guard data.isFasting,
              let targetEnd = data.fastingTargetEndAt else {
            return 0
        }
        return max(0, targetEnd.timeIntervalSince(currentTime))
    }

    private var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var formattedElapsed: String {
        guard let startedAt = data.fastingStartedAt else { return "00:00" }
        let elapsed = currentTime.timeIntervalSince(startedAt)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if data.isFasting {
                    // Active Fast View
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 10)

                        Circle()
                            .trim(from: 0, to: fastingProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(formattedTimeRemaining)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                            Text("remaining")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 100, height: 100)

                    // Protocol & Elapsed
                    VStack(spacing: 4) {
                        if let protocol_ = data.fastingProtocol {
                            Text(protocol_)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }

                        Text("Elapsed: \(formattedElapsed)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Progress Percentage
                    Text("\(Int(fastingProgress * 100))% Complete")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())

                } else {
                    // No Active Fast
                    VStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)

                        Text("No Active Fast")
                            .font(.headline)

                        Text("Start a fast from the iPhone app")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Fasting")
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            data = WidgetDataManager.shared.load() ?? .placeholder
            currentTime = Date()
        }
    }
}

#Preview {
    FastingStatusView()
}
