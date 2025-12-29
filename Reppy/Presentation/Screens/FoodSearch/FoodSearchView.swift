import SwiftUI

/// Food search view for finding foods from the database
struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FoodSearchViewModel

    let onFoodSelected: (CustomFood) -> Void
    let onCreateFood: () -> Void
    let onScanBarcode: () -> Void

    init(
        foodRepository: FoodRepository,
        onFoodSelected: @escaping (CustomFood) -> Void,
        onCreateFood: @escaping () -> Void,
        onScanBarcode: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: FoodSearchViewModel(foodRepository: foodRepository))
        self.onFoodSelected = onFoodSelected
        self.onCreateFood = onCreateFood
        self.onScanBarcode = onScanBarcode
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search foods...", text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .onSubmit {
                                viewModel.search()
                            }
                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Barcode button
                    Button {
                        onScanBarcode()
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Segment picker
                Picker("Source", selection: $viewModel.selectedTab) {
                    Text("Search").tag(FoodSearchTab.search)
                    Text("Recent").tag(FoodSearchTab.recent)
                    Text("Frequent").tag(FoodSearchTab.frequent)
                    Text("My Foods").tag(FoodSearchTab.myFoods)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider()

                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.displayedFoods.isEmpty {
                    emptyStateView
                } else {
                    foodListView
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onCreateFood()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadInitialData()
        }
        .onChange(of: viewModel.selectedTab) { _, _ in
            viewModel.loadDataForTab()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: viewModel.selectedTab == .search ? "magnifyingglass" : "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(viewModel.emptyStateMessage)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.selectedTab == .search && !viewModel.searchQuery.isEmpty {
                Button("Create Custom Food") {
                    onCreateFood()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
    }

    private var foodListView: some View {
        List {
            ForEach(viewModel.displayedFoods) { food in
                FoodRowView(food: food) {
                    onFoodSelected(food)
                    dismiss()
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Food Row View

struct FoodRowView: View {
    let food: CustomFood
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Food image or placeholder
                if let imageUrl = food.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        foodPlaceholder
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    foodPlaceholder
                }

                // Food info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let brand = food.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let serving = food.servingSize {
                            Text("• \(serving)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Macros
                    HStack(spacing: 8) {
                        if let cal = food.calories {
                            Text("\(Int(cal)) cal")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        Text(food.macroSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Source badge
                    if food.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }

                    // Testosterone impact badge
                    if let impact = food.testosteroneImpact {
                        TestosteroneImpactBadge(impact: impact)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var foodPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 50, height: 50)
            .overlay {
                Image(systemName: "fork.knife")
                    .foregroundColor(.secondary)
            }
    }
}

// MARK: - ViewModel

enum FoodSearchTab {
    case search
    case recent
    case frequent
    case myFoods
}

@MainActor
final class FoodSearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var selectedTab: FoodSearchTab = .search
    @Published var isLoading = false
    @Published var displayedFoods: [CustomFood] = []

    private let foodRepository: FoodRepository
    private var searchTask: Task<Void, Never>?

    init(foodRepository: FoodRepository) {
        self.foodRepository = foodRepository
    }

    var emptyStateMessage: String {
        switch selectedTab {
        case .search:
            return searchQuery.isEmpty
                ? "Search for foods by name or brand"
                : "No foods found for \"\(searchQuery)\""
        case .recent:
            return "No recently logged foods"
        case .frequent:
            return "No frequently logged foods"
        case .myFoods:
            return "No custom foods created yet"
        }
    }

    func loadInitialData() {
        loadDataForTab()
    }

    func loadDataForTab() {
        switch selectedTab {
        case .search:
            if !searchQuery.isEmpty {
                search()
            } else {
                displayedFoods = []
            }
        case .recent:
            loadRecentFoods()
        case .frequent:
            loadFrequentFoods()
        case .myFoods:
            loadMyFoods()
        }
    }

    func search() {
        guard !searchQuery.isEmpty else {
            displayedFoods = []
            return
        }

        searchTask?.cancel()
        searchTask = Task {
            isLoading = true
            do {
                let foods = try await foodRepository.searchFoods(query: searchQuery, limit: 30)
                if !Task.isCancelled {
                    displayedFoods = foods
                }
            } catch {
                if !Task.isCancelled {
                    print("Search error: \(error)")
                    displayedFoods = []
                }
            }
            isLoading = false
        }
    }

    private func loadRecentFoods() {
        Task {
            isLoading = true
            do {
                displayedFoods = try await foodRepository.getRecentFoods(limit: 50)
            } catch {
                print("Load recent error: \(error)")
                displayedFoods = []
            }
            isLoading = false
        }
    }

    private func loadFrequentFoods() {
        Task {
            isLoading = true
            do {
                displayedFoods = try await foodRepository.getFrequentFoods(limit: 50)
            } catch {
                print("Load frequent error: \(error)")
                displayedFoods = []
            }
            isLoading = false
        }
    }

    private func loadMyFoods() {
        Task {
            isLoading = true
            do {
                displayedFoods = try await foodRepository.getMyFoods()
            } catch {
                print("Load my foods error: \(error)")
                displayedFoods = []
            }
            isLoading = false
        }
    }
}
