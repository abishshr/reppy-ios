import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MealPlanViewModel()
    @State private var showingAllPlans = false
    @State private var showingGroceryLists = false
    @State private var showingCreateSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedMeal: PlannedMeal?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading meal plan...")
                        .padding(.top, 50)
                } else if let plan = viewModel.activePlan {
                    activePlanContent(plan)
                } else {
                    emptyPlanView
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Meal Plan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if viewModel.activePlan != nil {
                        Button {
                            smartCreateMealPlan()
                        } label: {
                            Label("Smart Create", systemImage: "brain.head.profile")
                        }

                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("Customize New Plan", systemImage: "slider.horizontal.3")
                        }

                        Divider()
                    }

                    Button {
                        showingAllPlans = true
                    } label: {
                        Label("All Plans", systemImage: "list.bullet")
                    }

                    Button {
                        showingGroceryLists = true
                    } label: {
                        Label("Grocery Lists", systemImage: "cart")
                    }

                    if viewModel.activePlan != nil {
                        Divider()

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Plan", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete Meal Plan?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let plan = viewModel.activePlan {
                    Task {
                        await viewModel.deletePlan(id: plan.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(viewModel.activePlan?.name ?? "this plan")\" and all its meals. This cannot be undone.")
        }
        .refreshable {
                await viewModel.loadActivePlan()
            }
            .task {
                await viewModel.loadActivePlan()
            }
            .sheet(isPresented: $showingAllPlans) {
                AllPlansSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingGroceryLists) {
                GroceryListsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCreateSheet) {
                UnifiedPlanCreationSheet(
                    planType: .meal,
                    apiClient: DependencyContainer.shared.apiClient,
                    chatRepository: DependencyContainer.shared.chatRepository,
                    appState: appState
                )
            }
            .sheet(item: $selectedMeal) { meal in
                MealDetailSheet(meal: meal)
            }
    }

    // MARK: - Active Plan Content

    @ViewBuilder
    private func activePlanContent(_ plan: MealPlan) -> some View {
        VStack(spacing: 16) {
            // Plan Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(plan.dayCount) day plan")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let goal = plan.goal {
                        Text(goal.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)

            // Day Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(plan.days) { day in
                        DayPill(
                            day: day,
                            isSelected: viewModel.selectedDay?.id == day.id
                        ) {
                            viewModel.selectDay(day)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Day Summary
            if let selectedDay = viewModel.selectedDay {
                DaySummaryCard(day: selectedDay)
                    .padding(.horizontal)
            }

            // Meals for Selected Day
            VStack(spacing: 12) {
                ForEach(viewModel.todaysMeals) { meal in
                    PlannedMealCard(meal: meal)
                        .onTapGesture {
                            selectedMeal = meal
                        }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State

    private var emptyPlanView: some View {
        VStack(spacing: 28) {
            Spacer()
                .frame(height: 20)

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .mint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "fork.knife")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No Meal Plan Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create a personalized plan based on your goals and preferences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Two Options
            VStack(spacing: 12) {
                // Smart Create - AI decides everything
                Button {
                    smartCreateMealPlan()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 20))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Smart Create")
                                .font(.headline)

                            Text("AI builds the perfect plan for you")
                                .font(.caption)
                                .opacity(0.9)
                        }

                        Spacer()

                        Image(systemName: "sparkles")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(BounceButtonStyle())

                // Customize - User chooses
                Button {
                    showingCreateSheet = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 44, height: 44)

                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Customize")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Choose duration, focus, and more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .buttonStyle(BounceButtonStyle())
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func smartCreateMealPlan() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigateToChatWith(
                message: "Create a 7-day meal plan for me based on my profile. Use my dietary preferences, calorie targets, and any allergies. Do NOT ask questions - just generate the complete plan now."
            )
        }
    }

    // MARK: - Actions

    private func createNewPlan() {
        showingCreateSheet = true
    }
}

// MARK: - Day Pill

struct DayPill: View {
    let day: MealPlanDay
    let isSelected: Bool
    let action: () -> Void

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day.date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(dayNumber)
                    .font(.headline)
            }
            .frame(width: 50, height: 60)
            .background(
                isSelected
                    ? Color.accentColor
                    : Color(.secondarySystemBackground)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Day Summary Card

struct DaySummaryCard: View {
    let day: MealPlanDay

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(day.meals.count) meals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                MacroSummaryPill(
                    icon: "flame.fill",
                    value: "\(day.totalCalories ?? 0)",
                    label: "cal",
                    color: .orange
                )

                MacroSummaryPill(
                    icon: "p.circle.fill",
                    value: "\(Int(day.totalProtein ?? 0))",
                    label: "g",
                    color: .blue
                )

                MacroSummaryPill(
                    icon: "c.circle.fill",
                    value: "\(Int(day.totalCarbs ?? 0))",
                    label: "g",
                    color: .green
                )

                MacroSummaryPill(
                    icon: "f.circle.fill",
                    value: "\(Int(day.totalFat ?? 0))",
                    label: "g",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Macro Summary Pill

struct MacroSummaryPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Planned Meal Card

struct PlannedMealCard: View {
    let meal: PlannedMeal
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Meal Type Icon
                Circle()
                    .fill(mealTypeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: meal.mealType?.icon ?? "fork.knife")
                            .foregroundColor(mealTypeColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.type.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(meal.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("\(meal.calories) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Recipe indicator
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.green)

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                Divider()

                // Description
                if let description = meal.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Macros
                HStack(spacing: 12) {
                    StatChip(icon: "p.circle.fill", value: "\(Int(meal.proteinG))", label: "g", color: .blue)
                    StatChip(icon: "c.circle.fill", value: "\(Int(meal.carbsG))", label: "g", color: .green)
                    StatChip(icon: "f.circle.fill", value: "\(Int(meal.fatG))", label: "g", color: .purple)

                    if let prepTime = meal.prepTimeMin {
                        StatChip(icon: "clock.fill", value: "\(prepTime)", label: "min", color: .gray)
                    }
                }

                // Ingredients
                if let ingredients = meal.ingredients, !ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ingredients")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        ForEach(ingredients) { ingredient in
                            HStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.5))
                                    .frame(width: 6, height: 6)

                                Text("\(ingredient.amount) \(ingredient.item)")
                                    .font(.caption)

                                Spacer()
                            }
                        }
                    }
                }

                // Instructions
                if let instructions = meal.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Instructions")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 6) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)

                                Text(step)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var mealTypeColor: Color {
        switch meal.type {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .gray
        }
    }
}

// MARK: - All Plans Sheet

struct AllPlansSheet: View {
    @ObservedObject var viewModel: MealPlanViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: MealPlan?
    @State private var loadingPlanId: String?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.allPlans.isEmpty {
                    ContentUnavailableView(
                        "No Meal Plans",
                        systemImage: "calendar",
                        description: Text("Your meal plans will appear here")
                    )
                } else {
                    ForEach(viewModel.allPlans) { plan in
                        Button {
                            Task {
                                loadingPlanId = plan.id
                                if let fullPlan = await viewModel.loadPlan(id: plan.id) {
                                    selectedPlan = fullPlan
                                }
                                loadingPlanId = nil
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.name)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text("\(plan.dayCount) days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if loadingPlanId == plan.id {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if plan.isActive {
                                    Text("Active")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deletePlan(id: plan.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadAllPlans()
            }
            .sheet(item: $selectedPlan) { plan in
                MealPlanDetailSheet(plan: plan)
            }
        }
    }
}

// MARK: - Meal Plan Detail Sheet

struct MealPlanDetailSheet: View {
    let plan: MealPlan
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: MealPlanDay?
    @State private var selectedMeal: PlannedMeal?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Plan header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            Label("\(plan.dayCount) days", systemImage: "calendar")
                            if let goal = plan.goal {
                                Label(goal.capitalized, systemImage: "target")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Days list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Days")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(plan.days) { day in
                            Button {
                                selectedDay = day
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Day \(day.dayNumber)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text("\(day.meals.count) meals")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(day.totalCalories ?? 0) kcal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Plan Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedDay) { day in
                DayDetailSheet(day: day, onMealTap: { meal in
                    selectedDay = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedMeal = meal
                    }
                })
            }
            .sheet(item: $selectedMeal) { meal in
                MealDetailSheet(meal: meal)
            }
        }
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let day: MealPlanDay
    let onMealTap: (PlannedMeal) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Day summary
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(day.totalCalories ?? 0)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text(String(format: "%.0f", day.totalProtein ?? 0))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text(String(format: "%.0f", day.totalCarbs ?? 0))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text(String(format: "%.0f", day.totalFat ?? 0))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("fat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Meals list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meals")
                            .font(.headline)

                        ForEach(day.meals) { meal in
                            Button {
                                onMealTap(meal)
                            } label: {
                                HStack {
                                    if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color(.systemGray5)
                                        }
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(meal.type.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Text(meal.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text("\(meal.calories) kcal")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Day \(day.dayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Grocery Lists Sheet

struct GroceryListsSheet: View {
    @ObservedObject var viewModel: MealPlanViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedList: GroceryList?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.groceryLists.isEmpty {
                    ContentUnavailableView(
                        "No Grocery Lists",
                        systemImage: "cart",
                        description: Text("Generate a grocery list from your meal plan")
                    )
                } else {
                    ForEach(viewModel.groceryLists) { list in
                        Button {
                            selectedList = list
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(list.name)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text("\(list.checkedCount)/\(list.totalCount) items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteGroceryList(id: list.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Grocery Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadGroceryLists()
            }
            .sheet(item: $selectedList) { list in
                GroceryListDetailSheet(list: list, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Grocery List Detail Sheet

struct GroceryListDetailSheet: View {
    let list: GroceryList
    @ObservedObject var viewModel: MealPlanViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(GroceryCategory.allCases, id: \.self) { category in
                    let categoryItems = list.items.enumerated().filter { $0.element.category == category }

                    if !categoryItems.isEmpty {
                        Section {
                            ForEach(categoryItems, id: \.offset) { index, item in
                                HStack {
                                    Button {
                                        Task {
                                            await viewModel.toggleGroceryItem(
                                                listId: list.id,
                                                itemIndex: index,
                                                checked: !item.checked
                                            )
                                        }
                                    } label: {
                                        Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.checked ? .green : .secondary)
                                    }

                                    Text(item.name)
                                        .strikethrough(item.checked)
                                        .foregroundColor(item.checked ? .secondary : .primary)

                                    Spacer()

                                    Text("\(item.quantity, specifier: "%.1f") \(item.unit)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                        }
                    }
                }
            }
            .navigationTitle(list.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Create Meal Plan Sheet

struct CreateMealPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (String) -> Void

    @State private var selectedDays = 7
    @State private var selectedFocus = "balanced"
    @State private var includeSnacks = true

    private let dayOptions = [3, 5, 7, 14]
    private let focusOptions = [
        ("balanced", "Balanced", "scale.3d", Color.green),
        ("high_protein", "High Protein", "bolt.fill", Color.blue),
        ("low_carb", "Low Carb", "leaf.fill", Color.orange),
        ("quick_meals", "Quick & Easy", "clock.fill", Color.purple),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Customize Your Plan")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("We'll create meals based on your dietary preferences and goals")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Focus Selection
                    OptionSection(title: "Focus") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(focusOptions, id: \.0) { focus in
                                MealFocusCard(
                                    title: focus.1,
                                    icon: focus.2,
                                    isSelected: selectedFocus == focus.0,
                                    color: focus.3
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFocus = focus.0
                                    }
                                }
                            }
                        }
                    }

                    // Duration
                    OptionSection(title: "Duration") {
                        HStack(spacing: 12) {
                            ForEach(dayOptions, id: \.self) { day in
                                DayChip(
                                    days: day,
                                    isSelected: selectedDays == day
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedDays = day
                                    }
                                }
                            }
                        }
                    }

                    // Snacks Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Include Snacks")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Add healthy snack ideas between meals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $includeSnacks)
                            .labelsHidden()
                            .tint(.green)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    Spacer(minLength: 20)

                    // Create Button
                    Button {
                        let prompt = buildPrompt()
                        dismiss()
                        onCreate(prompt)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Create Plan")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func buildPrompt() -> String {
        let focusText = focusOptions.first { $0.0 == selectedFocus }?.1 ?? "balanced"
        let snackText = includeSnacks ? " with snacks" : ""

        return "Create a \(selectedDays)-day \(focusText.lowercased()) meal plan\(snackText)"
    }
}

// MARK: - Meal Focus Card

struct MealFocusCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color(.secondarySystemBackground))
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Day Chip

struct DayChip: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void

    private var label: String {
        if days == 7 {
            return "1 Week"
        } else if days == 14 {
            return "2 Weeks"
        } else {
            return "\(days) Days"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color(.secondarySystemBackground))
                )
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MealPlanView()
}
