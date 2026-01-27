import SwiftUI

/// Sheet to view and manage custom foods
struct MyFoodsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foods: [CustomFood] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreateFood = false
    @State private var deletingFoodId: String?

    let apiClient: APIClient

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if foods.isEmpty {
                    emptyView
                } else {
                    foodsList
                }
            }
            .navigationTitle("My Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateFood = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .task {
                await loadFoods()
            }
            .sheet(isPresented: $showCreateFood) {
                CreateCustomFoodSheet(
                    apiClient: apiClient,
                    onCreated: { newFood in
                        foods.insert(newFood, at: 0)
                    }
                )
            }
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading your foods...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Custom Foods")
                .font(.headline)

            Text("Create your own foods with custom nutrition info.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showCreateFood = true
            } label: {
                Label("Create Food", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var foodsList: some View {
        List {
            ForEach(foods) { food in
                CustomFoodRow(
                    food: food,
                    isDeleting: deletingFoodId == food.id
                )
            }
            .onDelete { indexSet in
                Task {
                    await deleteFoods(at: indexSet)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func loadFoods() async {
        isLoading = true
        errorMessage = nil

        do {
            foods = try await apiClient.getMyCustomFoods()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func deleteFoods(at offsets: IndexSet) async {
        for index in offsets {
            let food = foods[index]
            deletingFoodId = food.id

            do {
                try await apiClient.deleteCustomFood(id: food.id)
                foods.remove(at: index)
            } catch {
                errorMessage = error.localizedDescription
            }

            deletingFoodId = nil
        }
    }
}

// MARK: - Custom Food Row

private struct CustomFoodRow: View {
    let food: CustomFood
    let isDeleting: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "takeoutbag.and.cup.and.straw")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                )

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let servingSize = food.servingSize {
                        Text(servingSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Nutrition
            VStack(alignment: .trailing, spacing: 4) {
                if let calories = food.calories {
                    Text("\(Int(calories)) cal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text(food.macroSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Testosterone impact badge
                if let impact = food.testosteroneImpact {
                    TestosteroneImpactBadge(impact: impact)
                }
            }

            if isDeleting {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
        .opacity(isDeleting ? 0.5 : 1)
    }
}

#Preview {
    MyFoodsSheet(apiClient: DependencyContainer.shared.apiClient)
}
