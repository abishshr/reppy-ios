import SwiftUI

/// Sheet to copy a previous meal to today
struct CopyMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var meals: [Meal] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var copyingMealId: String?
    @State private var selectedMealType: MealType = .snack

    let apiClient: APIClient
    let onCopied: (Meal) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if meals.isEmpty {
                    emptyView
                } else {
                    mealsList
                }
            }
            .navigationTitle("Copy Recent Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadMeals()
            }
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading recent meals...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Recent Meals")
                .font(.headline)

            Text("Log some meals first, then you can quickly copy them here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mealsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Meal type selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log as")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Meals list
                ForEach(meals) { meal in
                    RecentMealRow(
                        meal: meal,
                        isCopying: copyingMealId == meal.id,
                        onCopy: {
                            Task { await copyMeal(meal) }
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Actions

    private func loadMeals() async {
        isLoading = true
        errorMessage = nil

        do {
            meals = try await apiClient.getRecentUniqueMeals(days: 14, limit: 20)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func copyMeal(_ meal: Meal) async {
        copyingMealId = meal.id

        do {
            let copiedMeal = try await apiClient.copyMeal(
                mealId: meal.id,
                mealType: selectedMealType.rawValue
            )

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            onCopied(copiedMeal)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            copyingMealId = nil
        }
    }
}

// MARK: - Recent Meal Row

private struct RecentMealRow: View {
    let meal: Meal
    let isCopying: Bool
    let onCopy: () -> Void

    private var mealName: String {
        meal.items.first?.name ?? "Meal"
    }

    private var mealIcon: String {
        meal.mealType?.icon ?? "fork.knife"
    }

    private var mealColor: Color {
        switch meal.mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        case .none: return .gray
        }
    }

    private var daysAgo: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: meal.loggedAt, to: Date()).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(days) days ago"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(mealColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: mealIcon)
                        .font(.system(size: 20))
                        .foregroundColor(mealColor)
                )

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(mealName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let calories = meal.calories {
                        Text("\(calories) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(daysAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Copy Button
            Button {
                onCopy()
            } label: {
                if isCopying {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 60)
                } else {
                    Text("Copy")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(isCopying)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}

#Preview {
    CopyMealSheet(apiClient: DependencyContainer.shared.apiClient) { meal in
        print("Copied: \(meal.items.first?.name ?? "?")")
    }
}
