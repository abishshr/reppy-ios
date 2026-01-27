import SwiftUI

struct MealDetailSheet: View {
    let meal: PlannedMeal
    @Environment(\.dismiss) private var dismiss
    @State private var recipe: MealRecipe?
    @State private var isLoadingRecipe = false
    @State private var errorMessage: String?

    private let container = DependencyContainer.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Meal Image
                    mealImageSection

                    // Quick Info
                    quickInfoSection

                    // Macros
                    macrosSection

                    // Recipe Section - prefer pre-fetched, fallback to API
                    if meal.hasRecipe {
                        // Show pre-fetched recipe directly
                        prefetchedRecipeSection
                    } else if isLoadingRecipe {
                        recipeLoadingSection
                    } else if let recipe = recipe {
                        recipeSection(recipe)
                    } else {
                        loadRecipeButton
                    }
                }
                .padding()
            }
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Image Section

    private var mealImageSection: some View {
        Group {
            if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .frame(height: 220)

                            ProgressView()
                                .scaleEffect(1.5)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [mealColor.opacity(0.3), mealColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)

            VStack(spacing: 12) {
                Image(systemName: meal.typeIcon)
                    .font(.system(size: 50))
                    .foregroundColor(mealColor)

                Text(meal.type.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var mealColor: Color {
        switch meal.type.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .blue
        }
    }

    // MARK: - Quick Info Section

    private var quickInfoSection: some View {
        HStack(spacing: 16) {
            if let prepTime = meal.prepTimeMin ?? meal.readyInMinutes {
                QuickInfoPill(icon: "clock.fill", value: "\(prepTime) min", label: "Prep", color: .blue)
            }

            if let servings = meal.servings {
                QuickInfoPill(icon: "person.2.fill", value: "\(servings)", label: "Servings", color: .green)
            }

            QuickInfoPill(icon: "flame.fill", value: "\(meal.calories)", label: "kcal", color: .orange)
        }
    }

    // MARK: - Macros Section

    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.headline)

            HStack(spacing: 12) {
                MacroPill(name: "Protein", value: meal.proteinG, unit: "g", color: .red)
                MacroPill(name: "Carbs", value: meal.carbsG, unit: "g", color: .blue)
                MacroPill(name: "Fat", value: meal.fatG, unit: "g", color: .yellow)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Recipe Loading

    private var recipeLoadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Generating personalized recipe...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var loadRecipeButton: some View {
        Button {
            Task {
                await loadRecipe()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Get Recipe")
                        .font(.headline)

                    Text("AI-generated cooking instructions")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                Image(systemName: "chevron.right")
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
            .cornerRadius(12)
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Pre-fetched Recipe Section

    private var prefetchedRecipeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            if let description = meal.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }

            // Time & Difficulty
            HStack(spacing: 16) {
                if let prepTime = meal.prepTimeMin {
                    RecipeInfoCard(icon: "clock", title: "Prep", value: "\(prepTime) min")
                }
                if let cookTime = meal.cookTimeMin {
                    RecipeInfoCard(icon: "flame", title: "Cook", value: "\(cookTime) min")
                }
                if let difficulty = meal.difficulty {
                    RecipeInfoCard(icon: "chart.bar", title: "Level", value: difficulty.capitalized)
                }
            }

            // Ingredients
            if let ingredients = meal.ingredients, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(.green)
                        Text("Ingredients")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(ingredients) { ingredient in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(ingredient.amount) \(ingredient.item)")
                                        .font(.subheadline)

                                    if let notes = ingredient.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            // Instructions
            if let instructions = meal.instructions, !instructions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.justify.left")
                            .foregroundColor(.blue)
                        Text("Instructions")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.blue))

                                Text(instruction)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            // Tips
            if let tips = meal.tips, !tips.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Tips")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)

                                Text(tip)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            // Nutrition Notes
            if let nutritionNotes = meal.nutritionNotes, !nutritionNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Health Benefits")
                            .font(.headline)
                    }

                    Text(nutritionNotes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Recipe Section

    @ViewBuilder
    private func recipeSection(_ recipe: MealRecipe) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            if !recipe.description.isEmpty {
                Text(recipe.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }

            // Time & Difficulty
            HStack(spacing: 16) {
                RecipeInfoCard(icon: "clock", title: "Prep", value: "\(recipe.prepTimeMinutes) min")
                RecipeInfoCard(icon: "flame", title: "Cook", value: "\(recipe.cookTimeMinutes) min")
                RecipeInfoCard(icon: "chart.bar", title: "Level", value: recipe.difficulty.capitalized)
            }

            // Ingredients
            if !recipe.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(.green)
                        Text("Ingredients")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recipe.ingredients) { ingredient in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(ingredient.amount) \(ingredient.item)")
                                        .font(.subheadline)

                                    if let notes = ingredient.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            // Instructions
            if !recipe.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.justify.left")
                            .foregroundColor(.blue)
                        Text("Instructions")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.blue))

                                Text(instruction)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            // Tips
            if !recipe.tips.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Tips")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recipe.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)

                                Text(tip)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            // Nutrition Notes
            if !recipe.nutritionNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Health Benefits")
                            .font(.headline)
                    }

                    Text(recipe.nutritionNotes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Load Recipe

    private func loadRecipe() async {
        isLoadingRecipe = true
        errorMessage = nil

        do {
            recipe = try await container.mealPlanRepository.getRecipe(
                mealName: meal.name,
                mealType: meal.type
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingRecipe = false
    }
}

// MARK: - Helper Views

struct QuickInfoPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MacroPill: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.0f%@", value, unit))
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.15))
        .cornerRadius(10)
    }
}

struct RecipeInfoCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    MealDetailSheet(
        meal: PlannedMeal(
            type: "lunch",
            name: "Grilled Chicken Salad",
            description: "A healthy and delicious salad with fresh vegetables",
            calories: 450,
            proteinG: 35,
            carbsG: 25,
            fatG: 18,
            sugarG: 5,
            fiberG: 8,
            sodiumMg: 350,
            saturatedFatG: 3,
            cholesterolMg: 85,
            ingredients: [
                RecipeIngredient(item: "chicken breast", amount: "200g", notes: "grilled"),
                RecipeIngredient(item: "mixed greens", amount: "2 cups", notes: nil),
                RecipeIngredient(item: "cherry tomatoes", amount: "1 cup", notes: "halved")
            ],
            instructions: [
                "Season chicken with salt and pepper",
                "Grill chicken for 6-7 minutes per side until cooked through",
                "Let chicken rest for 5 minutes, then slice",
                "Arrange greens on a plate and top with sliced chicken",
                "Add tomatoes and drizzle with dressing"
            ],
            prepTimeMin: 10,
            cookTimeMin: 15,
            difficulty: "easy",
            tips: ["Use a meat thermometer to ensure chicken reaches 165°F"],
            nutritionNotes: "High in protein and fiber, low in carbs",
            imageUrl: nil,
            imageSource: nil,
            imagePhotographer: nil,
            readyInMinutes: 25,
            servings: 2
        )
    )
}
