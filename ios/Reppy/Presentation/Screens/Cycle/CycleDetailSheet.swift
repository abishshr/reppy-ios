import SwiftUI

/// Sheet showing full cycle details and recommendations
struct CycleDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let apiClient: APIClient
    let status: CycleStatus?
    let recommendations: CycleRecommendations?
    let onLogTap: () -> Void

    @State private var selectedMonth = Date()
    @State private var calendarDays: [CycleCalendarDay] = []
    @State private var isLoadingCalendar = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status card
                    if let status = status {
                        CycleStatusCard(
                            status: status,
                            onLogTap: onLogTap,
                            onDetailsTap: {}
                        )
                    }

                    // Recommendations
                    if let recommendations = recommendations {
                        CycleRecommendationsCard(recommendations: recommendations)
                    }

                    // Calendar preview
                    calendarSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cycle Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadCalendar()
            }
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Month")
                    .font(.headline)

                Spacer()

                if isLoadingCalendar {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // Simple calendar grid
            if !calendarDays.isEmpty {
                CalendarGrid(days: calendarDays)
            } else {
                Text("Log your period to see predictions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .red, label: "Period")
                LegendItem(color: .pink, label: "Predicted")
                LegendItem(color: .green, label: "Fertile")
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func loadCalendar() async {
        isLoadingCalendar = true
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)

        do {
            calendarDays = try await apiClient.getCycleCalendar(month: month, year: year)
        } catch {
            print("Failed to load calendar: \(error)")
        }
        isLoadingCalendar = false
    }
}

/// Simple calendar grid
private struct CalendarGrid: View {
    let days: [CycleCalendarDay]

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: columns, spacing: 8) {
                // Add empty cells for days before the 1st
                ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                    Text("")
                        .frame(width: 32, height: 32)
                }

                ForEach(days) { day in
                    CalendarDayCell(day: day)
                }
            }
        }
    }

    private var leadingEmptyCells: Int {
        guard let firstDay = days.first else { return 0 }
        return Calendar.current.component(.weekday, from: firstDay.date) - 1
    }
}

private struct CalendarDayCell: View {
    let day: CycleCalendarDay

    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)

            // Day number
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(textColor)

            // Ovulation indicator
            if day.isOvulationDay {
                Circle()
                    .strokeBorder(Color.green, lineWidth: 2)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    private var backgroundColor: Color {
        if day.isPeriodDay {
            return .red.opacity(0.8)
        } else if day.isPredictedPeriod {
            return .pink.opacity(0.3)
        } else if day.isFertileWindow {
            return .green.opacity(0.2)
        } else if isToday {
            return .accentColor.opacity(0.2)
        }
        return .clear
    }

    private var textColor: Color {
        if day.isPeriodDay {
            return .white
        }
        return .primary
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CycleDetailSheet(
        apiClient: DependencyContainer.shared.apiClient,
        status: CycleStatus(
            currentPhase: "follicular",
            cycleDay: 8,
            daysUntilPeriod: 20,
            nextPeriodDate: Date().addingTimeInterval(86400 * 20),
            isFertileWindow: false,
            phaseDay: 3,
            phaseDaysRemaining: 5
        ),
        recommendations: CycleRecommendations(
            phase: "follicular",
            phaseDescription: "Estrogen is rising, boosting your mood and energy.",
            nutritionTips: ["Focus on lean proteins"],
            recommendedFoods: ["Eggs", "Chicken"],
            foodsToLimit: ["Heavy foods"],
            workoutTips: ["Great time for high-intensity workouts"],
            workoutIntensity: "high",
            selfCareTips: ["Social activities"]
        ),
        onLogTap: {}
    )
}
