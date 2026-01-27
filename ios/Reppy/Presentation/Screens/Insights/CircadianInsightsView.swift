import SwiftUI
import Charts

struct CircadianInsightsView: View {
    @StateObject private var viewModel = CircadianViewModel()
    @State private var showingOptimalTimes = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let analysis = viewModel.analysis, analysis.hasData {
                    // Consistency Score
                    ConsistencyScoreCard(score: analysis.analysis.consistencyScore)

                    // Eating Window
                    EatingWindowCard(analysis: analysis.analysis)

                    // Eating Window Chart
                    if let stats = viewModel.eatingWindowStats, !stats.dailyWindows.isEmpty {
                        EatingWindowChart(stats: stats)
                    }

                    // Recommendations
                    if !analysis.recommendations.isEmpty {
                        RecommendationsCard(recommendations: analysis.recommendations)
                    }
                } else {
                    NoDataCard()
                }
            }
            .padding()
        }
        .navigationTitle("Circadian Insights")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingOptimalTimes = true
                } label: {
                    Image(systemName: "clock.badge.checkmark")
                }
            }
        }
        .sheet(isPresented: $showingOptimalTimes) {
            OptimalTimesSheet()
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
class CircadianViewModel: ObservableObject {
    @Published var analysis: CircadianAnalysis?
    @Published var eatingWindowStats: EatingWindowStats?
    @Published var isLoading = false
    @Published var error: String?

    private let apiClient = DependencyContainer.shared.apiClient

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let analysisTask = apiClient.getCircadianAnalysis(days: 14)
            async let statsTask = apiClient.getEatingWindowStats(days: 7)

            let (analysisResult, statsResult) = try await (analysisTask, statsTask)
            analysis = analysisResult
            eatingWindowStats = statsResult
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Consistency Score Card

private struct ConsistencyScoreCard: View {
    let score: Int

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var rating: String {
        switch score {
        case 80...100: return "Very Consistent"
        case 60..<80: return "Fairly Consistent"
        case 40..<60: return "Somewhat Inconsistent"
        default: return "Needs Improvement"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.title.bold())
                        .foregroundStyle(scoreColor)
                    Text("%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(rating)
                .font(.headline)
                .foregroundStyle(scoreColor)

            Text("Meal Timing Consistency")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Eating Window Card

private struct EatingWindowCard: View {
    let analysis: MealTimingAnalysis

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Eating Pattern")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 32) {
                // First Meal
                VStack {
                    Image(systemName: "sunrise.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("First Meal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analysis.averageFirstMeal ?? "--:--")
                        .font(.title3.bold())
                }

                // Eating Window
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Window")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let hours = analysis.eatingWindowHours {
                        Text(String(format: "%.1fh", hours))
                            .font(.title3.bold())
                    } else {
                        Text("--")
                            .font(.title3.bold())
                    }
                }

                // Last Meal
                VStack {
                    Image(systemName: "moon.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("Last Meal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analysis.averageLastMeal ?? "--:--")
                        .font(.title3.bold())
                }
            }

            // Late Night Eating
            if analysis.lateNightEatingFrequency > 0 {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(.purple)
                    Text("Late eating (after 9 PM)")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.0f%% of days", analysis.lateNightEatingFrequency))
                        .font(.subheadline.bold())
                        .foregroundStyle(analysis.lateNightEatingFrequency > 30 ? .orange : .secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Eating Window Chart

private struct EatingWindowChart: View {
    let stats: EatingWindowStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Eating Windows")
                    .font(.headline)
                Spacer()
                Text(String(format: "Avg: %.1fh", stats.averageEatingWindowHours))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart {
                ForEach(stats.dailyWindows) { window in
                    BarMark(
                        x: .value("Date", formatDate(window.date)),
                        y: .value("Hours", window.eatingWindowHours)
                    )
                    .foregroundStyle(
                        window.eatingWindowHours <= 12 ? Color.green : Color.orange
                    )
                }

                // Target line at 12 hours
                RuleMark(y: .value("Target", 12))
                    .foregroundStyle(.blue.opacity(0.5))
                    .lineStyle(StrokeStyle(dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("12h target")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
            }
            .frame(height: 150)
            .chartYScale(domain: 0...18)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatDate(_ dateString: String) -> String {
        // Convert "2025-01-15" to "Mon"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        return dayFormatter.string(from: date)
    }
}

// MARK: - Recommendations Card

private struct RecommendationsCard: View {
    let recommendations: [CircadianRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Recommendations")
                    .font(.headline)
            }

            ForEach(recommendations) { rec in
                RecommendationRow(recommendation: rec)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct RecommendationRow: View {
    let recommendation: CircadianRecommendation

    private var priorityColor: Color {
        switch recommendation.priority {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
                Text(recommendation.title)
                    .font(.subheadline.bold())
            }

            Text(recommendation.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label(recommendation.action, systemImage: "arrow.right.circle")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text(recommendation.benefit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - No Data Card

private struct NoDataCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Not Enough Data")
                .font(.title3.bold())

            Text("Log meals for at least 7 days to see your circadian rhythm analysis and personalized recommendations.")
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

// MARK: - Optimal Times Sheet

private struct OptimalTimesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var wakeTime = Date()
    @State private var sleepTime = Date()
    @State private var optimalTimes: OptimalMealTimes?
    @State private var isLoading = false

    private let apiClient = DependencyContainer.shared.apiClient

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Schedule") {
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    DatePicker("Sleep Time", selection: $sleepTime, displayedComponents: .hourAndMinute)

                    Button("Calculate Optimal Times") {
                        calculateTimes()
                    }
                    .disabled(isLoading)
                }

                if let times = optimalTimes {
                    Section("Recommended Meal Times") {
                        MealTimeRow(icon: "sunrise.fill", color: .orange, label: "Breakfast", time: times.breakfast)
                        MealTimeRow(icon: "sun.max.fill", color: .yellow, label: "Lunch", time: times.lunch)
                        MealTimeRow(icon: "sunset.fill", color: .orange, label: "Dinner", time: times.dinner)
                        MealTimeRow(icon: "moon.fill", color: .purple, label: "Eating Cutoff", time: times.eatingCutoff)
                    }

                    Section {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.blue)
                            Text("Recommended eating window")
                            Spacer()
                            Text("\(times.eatingWindowHours) hours")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Optimal Meal Times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                // Set default times
                let calendar = Calendar.current
                wakeTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
                sleepTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
            }
        }
    }

    private func calculateTimes() {
        isLoading = true
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        Task {
            do {
                optimalTimes = try await apiClient.getOptimalMealTimes(
                    wakeTime: formatter.string(from: wakeTime),
                    sleepTime: formatter.string(from: sleepTime)
                )
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}

private struct MealTimeRow: View {
    let icon: String
    let color: Color
    let label: String
    let time: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
            Spacer()
            Text(time)
                .font(.headline)
        }
    }
}

#Preview {
    NavigationStack {
        CircadianInsightsView()
    }
}
