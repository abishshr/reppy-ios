import SwiftUI
import Charts

struct GoalTimelineView: View {
    @StateObject private var viewModel = GoalTimelineViewModel()
    @State private var showingGoalSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let prediction = viewModel.prediction {
                    // Status Card
                    StatusCard(prediction: prediction)

                    // Progress Card (if goal exists)
                    if prediction.goalWeight != nil {
                        GoalProgressCard(prediction: prediction)
                    }

                    // Weight Chart
                    if !prediction.weightHistory.isEmpty {
                        WeightChartCard(prediction: prediction)
                    }

                    // Rate Comparison
                    if prediction.actualRateKgPerWeek != nil {
                        RateComparisonCard(prediction: prediction)
                    }

                    // Prediction Details
                    if prediction.predictedGoalDate != nil {
                        PredictionDetailsCard(prediction: prediction)
                    }
                } else {
                    NoDataView()
                }
            }
            .padding()
        }
        .navigationTitle("Goal Timeline")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingGoalSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingGoalSettings) {
            GoalSettingsSheet(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - View Model

@MainActor
class GoalTimelineViewModel: ObservableObject {
    @Published var prediction: GoalPrediction?
    @Published var settings: GoalSettings?
    @Published var isLoading = false
    @Published var error: String?

    private let apiClient = DependencyContainer.shared.apiClient

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let predictionTask = apiClient.getWeightPrediction(days: 90)
            async let settingsTask = apiClient.getGoalSettings()

            let (pred, set) = try await (predictionTask, settingsTask)
            prediction = pred
            settings = set
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func updateGoal(weightKg: Double?, rateKgPerWeek: Double?, targetDate: Date?) async {
        do {
            let request = UpdateGoalSettingsRequest(
                weightGoalKg: weightKg,
                targetRateKgPerWeek: rateKgPerWeek,
                goalTargetDate: targetDate
            )
            settings = try await apiClient.updateGoalSettings(request)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearGoal() async {
        do {
            try await apiClient.clearGoalSettings()
            settings = GoalSettings(weightGoalKg: nil, targetRateKgPerWeek: nil, goalTargetDate: nil)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let prediction: GoalPrediction

    private var statusColor: Color {
        switch prediction.status {
        case .ahead: return .green
        case .onTrack: return .blue
        case .behind: return .orange
        case .noGoal, .noData: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: prediction.status.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(statusColor)
            }

            // Status Title
            Text(prediction.status.displayName)
                .font(.title2.bold())
                .foregroundStyle(statusColor)

            // Status Message
            Text(prediction.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Goal Progress Card

struct GoalProgressCard: View {
    let prediction: GoalPrediction

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                if let percent = prediction.progressPercentage {
                    Text("\(Int(percent))%")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (prediction.progressPercentage ?? 0) / 100)
                }
            }
            .frame(height: 12)

            // Weight details
            HStack {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let current = prediction.currentWeight {
                        Text(String(format: "%.1f kg", current))
                            .font(.title3.bold())
                    }
                }

                Spacer()

                if let lost = prediction.totalLost {
                    VStack {
                        Text("Lost")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f kg", lost))
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let goal = prediction.goalWeight {
                        Text(String(format: "%.1f kg", goal))
                            .font(.title3.bold())
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Weight Chart Card

struct WeightChartCard: View {
    let prediction: GoalPrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Trend")
                .font(.headline)

            Chart {
                // Weight history
                ForEach(prediction.weightHistory) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weightKg)
                    )
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weightKg)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }

                // Trend line
                ForEach(prediction.trendLine) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weightKg)
                    )
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(dash: [5, 5]))
                }

                // Goal line
                if let goal = prediction.goalWeight {
                    RuleMark(y: .value("Goal", goal))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(dash: [3, 3]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal: \(String(format: "%.1f", goal)) kg")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Rate Comparison Card

struct RateComparisonCard: View {
    let prediction: GoalPrediction

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Rate")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                // Target rate
                VStack {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let rate = prediction.targetRateKgPerWeek {
                        Text(String(format: "%.2f kg", rate))
                            .font(.title3.bold())
                    } else {
                        Text("-")
                            .font(.title3.bold())
                    }
                    Text("per week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                // Actual rate
                VStack {
                    Text("Actual")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let rate = prediction.actualRateKgPerWeek {
                        Text(String(format: "%.2f kg", abs(rate)))
                            .font(.title3.bold())
                            .foregroundStyle(rate >= 0 ? .green : .red)
                    } else {
                        Text("-")
                            .font(.title3.bold())
                    }
                    Text("per week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // On track percentage
                if let percent = prediction.onTrackPercentage {
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                                .frame(width: 60, height: 60)

                            Circle()
                                .trim(from: 0, to: min(percent / 100, 1.0))
                                .stroke(
                                    percent >= 80 ? Color.green : (percent >= 50 ? Color.orange : Color.red),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(percent))%")
                                .font(.caption.bold())
                        }
                        Text("On Track")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Prediction Details Card

struct PredictionDetailsCard: View {
    let prediction: GoalPrediction

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Prediction")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                // Predicted date
                HStack {
                    Label("Predicted Goal Date", systemImage: "calendar")
                        .font(.subheadline)
                    Spacer()
                    if let date = prediction.formattedPredictedDate {
                        Text(date)
                            .font(.subheadline.bold())
                    }
                }

                Divider()

                // Time to goal
                HStack {
                    Label("Time to Goal", systemImage: "clock")
                        .font(.subheadline)
                    Spacer()
                    if let time = prediction.formattedTimeToGoal {
                        Text(time)
                            .font(.subheadline.bold())
                    }
                }

                // Target date comparison
                if let targetDate = prediction.targetGoalDate {
                    Divider()

                    HStack {
                        Label("Your Target Date", systemImage: "flag")
                            .font(.subheadline)
                        Spacer()
                        Text(targetDate, style: .date)
                            .font(.subheadline.bold())
                    }
                }

                // Weight remaining
                if let remaining = prediction.weightToLose {
                    Divider()

                    HStack {
                        Label("Weight Remaining", systemImage: "scalemass")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f kg", remaining))
                            .font(.subheadline.bold())
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - No Data View

struct NoDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Weight Data")
                .font(.title3.bold())

            Text("Log your weight regularly to see predictions and track your progress toward your goal.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Goal Settings Sheet

struct GoalSettingsSheet: View {
    @ObservedObject var viewModel: GoalTimelineViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var goalWeight: Double = 70
    @State private var targetRate: Double = 0.5
    @State private var useTargetDate = false
    @State private var targetDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Weight") {
                    HStack {
                        Text("Goal")
                        Spacer()
                        TextField("kg", value: $goalWeight, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Weight Loss Rate") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target Rate")
                            Spacer()
                            Text(String(format: "%.2f kg/week", targetRate))
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $targetRate, in: 0.25...1.5, step: 0.05)

                        HStack {
                            Text("Slow & Steady")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Aggressive")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Toggle("Set Target Date", isOn: $useTargetDate)

                    if useTargetDate {
                        DatePicker("Target Date", selection: $targetDate, in: Date()..., displayedComponents: .date)
                    }
                }

                Section {
                    Button("Clear Goal", role: .destructive) {
                        Task {
                            await viewModel.clearGoal()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Goal Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updateGoal(
                                weightKg: goalWeight,
                                rateKgPerWeek: targetRate,
                                targetDate: useTargetDate ? targetDate : nil
                            )
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if let settings = viewModel.settings {
                    goalWeight = settings.weightGoalKg ?? 70
                    targetRate = settings.targetRateKgPerWeek ?? 0.5
                    if let date = settings.goalTargetDate {
                        useTargetDate = true
                        targetDate = date
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GoalTimelineView()
    }
}
