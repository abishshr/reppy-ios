import SwiftUI

struct WaterLogView: View {
    @State private var data: WidgetData = WidgetDataManager.shared.load() ?? .placeholder
    @State private var showingConfirmation = false
    @State private var lastAddedAmount = 0

    private let quickAmounts = [250, 500, 750]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: data.waterProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Image(systemName: "drop.fill")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                        Text("\(data.waterConsumedMl)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("/ \(data.waterTargetMl)ml")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Quick Add Buttons
                VStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { amount in
                        Button {
                            addWater(amount)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("\(amount)ml")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Water")
        .overlay {
            if showingConfirmation {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("+\(lastAddedAmount)ml")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
            }
        }
        .onAppear {
            data = WidgetDataManager.shared.load() ?? .placeholder
        }
    }

    private func addWater(_ amount: Int) {
        lastAddedAmount = amount
        let newTotal = data.waterConsumedMl + amount
        WidgetDataManager.shared.updateWater(consumed: newTotal)
        data = WidgetDataManager.shared.load() ?? .placeholder

        // Show confirmation
        withAnimation {
            showingConfirmation = true
        }

        // Send to phone via WatchConnectivity
        WatchSessionManager.shared.sendWaterLog(amount: amount)

        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingConfirmation = false
            }
        }
    }
}

#Preview {
    WaterLogView()
}
