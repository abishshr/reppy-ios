import SwiftUI

/// Dedicated Profile tab - combines profile, progress, and settings
struct ProfileTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileTabViewModel()
    @State private var showExportData = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderSection(
                        profile: appState.userProfile,
                        streak: viewModel.currentStreak,
                        onEdit: { showEditProfile = true }
                    )
                    .padding(.horizontal)

                    // Daily Targets
                    DailyTargetsSection(profile: appState.userProfile)
                        .padding(.horizontal)

                    // Micronutrients
                    MicronutrientsProgressSection(
                        sugar: viewModel.todaySugar,
                        sugarTarget: viewModel.sugarTarget,
                        fiber: viewModel.todayFiber,
                        fiberTarget: viewModel.fiberTarget,
                        sodium: viewModel.todaySodium,
                        sodiumTarget: viewModel.sodiumTarget
                    )
                    .padding(.horizontal)

                    // Weekly Overview
                    WeeklyStatsCard(
                        averageCalories: viewModel.weeklyAvgCalories,
                        averageProtein: viewModel.weeklyAvgProtein,
                        workoutsCompleted: viewModel.weeklyWorkouts,
                        streakDays: viewModel.currentStreak
                    )
                    .padding(.horizontal)

                    // Health Integration
                    HealthSection(
                        status: viewModel.healthKitStatus,
                        onSync: {
                            Task { await viewModel.syncSteps() }
                        }
                    )
                    .padding(.horizontal)

                    // Export Data
                    DataExportSection(onExport: { showExportData = true })
                        .padding(.horizontal)

                    // About & Sign Out
                    AboutSection(onSignOut: { viewModel.showSignOutConfirmation = true })
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showExportData) {
                ExportDataSheet(apiClient: DependencyContainer.shared.apiClient)
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile = appState.userProfile {
                    ProfileEditSheet(profile: profile)
                }
            }
            .alert("Sign Out", isPresented: $viewModel.showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Profile Header Section

struct ProfileHeaderSection: View {
    let profile: UserProfile?
    let streak: Int
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(profile?.name?.prefix(1).uppercased() ?? "?")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.name ?? "User")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let goals = profile?.goals, !goals.isEmpty {
                        Text(goals.map { $0.displayName }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Streak Badge
                    if streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(streak) day streak")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Daily Targets Section

struct DailyTargetsSection: View {
    let profile: UserProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.green)
                Text("Daily Targets")
                    .font(.headline)
            }

            if let profile = profile {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    TargetCard(name: "Calories", value: profile.dailyCalorieTarget, unit: "cal", color: .orange)
                    TargetCard(name: "Protein", value: Int(profile.dailyProteinTarget ?? 0), unit: "g", color: .blue)
                    TargetCard(name: "Carbs", value: Int(profile.dailyCarbsTarget ?? 0), unit: "g", color: .green)
                    TargetCard(name: "Fat", value: Int(profile.dailyFatTarget ?? 0), unit: "g", color: .purple)
                }

                if let steps = profile.dailyStepsGoal {
                    TargetCard(name: "Steps", value: steps, unit: "", color: .pink)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct TargetCard: View {
    let name: String
    let value: Int?
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)

            if let value = value {
                Text("\(value)\(unit)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            } else {
                Text("--")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Micronutrients Section

struct MicronutrientsProgressSection: View {
    let sugar: Double
    let sugarTarget: Double
    let fiber: Double
    let fiberTarget: Double
    let sodium: Double
    let sodiumTarget: Double

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

            VStack(spacing: 12) {
                MicronutrientRow(name: "Sugar", value: sugar, target: sugarTarget, unit: "g", color: .pink, icon: "cube.fill", isWarning: sugar > sugarTarget)
                MicronutrientRow(name: "Fiber", value: fiber, target: fiberTarget, unit: "g", color: .green, icon: "leaf.fill", isWarning: false)
                MicronutrientRow(name: "Sodium", value: sodium, target: sodiumTarget, unit: "mg", color: .blue, icon: "drop.fill", isWarning: sodium > sodiumTarget)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Weekly Stats Card

struct WeeklyStatsCard: View {
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

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                WeeklyStat(title: "Avg. Calories", value: "\(averageCalories)", subtitle: "per day", color: .orange)
                WeeklyStat(title: "Avg. Protein", value: "\(Int(averageProtein))g", subtitle: "per day", color: .blue)
                WeeklyStat(title: "Workouts", value: "\(workoutsCompleted)", subtitle: "completed", color: .green)
                WeeklyStat(title: "Streak", value: "\(streakDays)", subtitle: "days", color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct WeeklyStat: View {
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

// MARK: - Health Section

struct HealthSection: View {
    let status: String
    let onSync: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Health Integration")
                    .font(.headline)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health")
                        .fontWeight(.medium)
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onSync) {
                    Text("Sync")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Data Export Section

struct DataExportSection: View {
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
                .font(.caption)
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

// MARK: - About Section

struct AboutSection: View {
    let onSignOut: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            Link(destination: URL(string: "https://reppy.app/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Divider()

            Link(destination: URL(string: "https://reppy.app/terms")!) {
                HStack {
                    Text("Terms of Service")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Divider()

            Button(action: onSignOut) {
                HStack {
                    Text("Sign Out")
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Placeholder Views

struct ProfileEditSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Edit Profile Coming Soon")
                .navigationTitle("Edit Profile")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileTabView()
        .environmentObject(AppState())
}
