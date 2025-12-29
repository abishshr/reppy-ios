import SwiftUI

/// Progress tab - micronutrients, trends, and data export
struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var showExportData = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Micronutrients Section
                    MicronutrientsSection(
                        sugar: viewModel.todaySugar,
                        sugarTarget: viewModel.sugarTarget,
                        fiber: viewModel.todayFiber,
                        fiberTarget: viewModel.fiberTarget,
                        sodium: viewModel.todaySodium,
                        sodiumTarget: viewModel.sodiumTarget,
                        saturatedFat: viewModel.todaySaturatedFat,
                        saturatedFatTarget: viewModel.saturatedFatTarget,
                        cholesterol: viewModel.todayCholesterol,
                        cholesterolTarget: viewModel.cholesterolTarget
                    )
                    .padding(.horizontal)

                    // Weekly Overview
                    WeeklyOverviewCard(
                        averageCalories: viewModel.weeklyAvgCalories,
                        averageProtein: viewModel.weeklyAvgProtein,
                        workoutsCompleted: viewModel.weeklyWorkouts,
                        streakDays: viewModel.currentStreak
                    )
                    .padding(.horizontal)

                    // Export Section
                    ExportSection(onExport: { showExportData = true })
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showExportData) {
                ExportDataSheet(apiClient: DependencyContainer.shared.apiClient)
            }
        }
    }
}

// MARK: - Micronutrients Section

struct MicronutrientsSection: View {
    let sugar: Double
    let sugarTarget: Double
    let fiber: Double
    let fiberTarget: Double
    let sodium: Double
    let sodiumTarget: Double
    let saturatedFat: Double
    let saturatedFatTarget: Double
    let cholesterol: Double
    let cholesterolTarget: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Micronutrients")
                    .font(.headline)
                Spacer()
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 14) {
                NutrientProgressRow(
                    name: "Sugar",
                    value: sugar,
                    target: sugarTarget,
                    unit: "g",
                    color: .pink,
                    icon: "cube.fill"
                )

                NutrientProgressRow(
                    name: "Fiber",
                    value: fiber,
                    target: fiberTarget,
                    unit: "g",
                    color: .green,
                    icon: "leaf.fill"
                )

                NutrientProgressRow(
                    name: "Sodium",
                    value: sodium,
                    target: sodiumTarget,
                    unit: "mg",
                    color: .blue,
                    icon: "drop.fill"
                )

                NutrientProgressRow(
                    name: "Saturated Fat",
                    value: saturatedFat,
                    target: saturatedFatTarget,
                    unit: "g",
                    color: .orange,
                    icon: "flame.fill"
                )

                NutrientProgressRow(
                    name: "Cholesterol",
                    value: cholesterol,
                    target: cholesterolTarget,
                    unit: "mg",
                    color: .red,
                    icon: "heart.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct NutrientProgressRow: View {
    let name: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color
    let icon: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.5)
    }

    private var isOverTarget: Bool {
        value > target
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(Int(value)) / \(Int(target)) \(unit)")
                        .font(.caption)
                        .foregroundColor(isOverTarget ? .red : .secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(isOverTarget ? Color.red : color)
                            .frame(width: geometry.size.width * min(progress, 1.0))
                    }
                }
                .frame(height: 8)
            }
        }
    }
}

// MARK: - Weekly Overview Card

struct WeeklyOverviewCard: View {
    let averageCalories: Int
    let averageProtein: Double
    let workoutsCompleted: Int
    let streakDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("This Week")
                    .font(.headline)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                WeeklyStatCard(title: "Avg. Calories", value: "\(averageCalories)", subtitle: "per day", color: .orange)
                WeeklyStatCard(title: "Avg. Protein", value: "\(Int(averageProtein))g", subtitle: "per day", color: .blue)
                WeeklyStatCard(title: "Workouts", value: "\(workoutsCompleted)", subtitle: "completed", color: .green)
                WeeklyStatCard(title: "Streak", value: "\(streakDays)", subtitle: "days", color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct WeeklyStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Export Section

struct ExportSection: View {
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.gray)
                Text("Export Data")
                    .font(.headline)
            }

            Text("Export your meals, workouts, and progress data in CSV format.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: onExport) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Export to CSV")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    StatsView()
}
