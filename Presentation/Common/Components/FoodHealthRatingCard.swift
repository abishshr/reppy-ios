import SwiftUI

/// Displays the health rating badge for a food item
struct FoodHealthRatingBadge: View {
    let rating: FoodHealthRating

    var ratingColor: Color {
        switch rating {
        case .excellent: return .green
        case .good: return Color(red: 0.5, green: 0.8, blue: 0.2)  // Lime
        case .okay: return .yellow
        case .poor: return .orange
        case .bad: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(ratingColor)
                .frame(width: 44, height: 44)

            Text(rating.rawValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

/// Large health rating card shown after barcode scan
struct FoodHealthRatingCard: View {
    let food: CustomFood
    @State private var showAllWarnings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with rating
            headerSection

            // Warnings section
            if let analysis = food.ingredientAnalysis, analysis.hasWarnings {
                warningsSection(analysis)
            }

            // Positives section
            if let analysis = food.ingredientAnalysis, !analysis.positives.isEmpty {
                positivesSection(analysis)
            }

            // Macros summary
            macrosSection
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Product image or placeholder
            if let imageUrl = food.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(height: 120)
                .cornerRadius(12)
            }

            // Rating badge and name
            HStack(spacing: 16) {
                if let rating = food.healthRating {
                    FoodHealthRatingBadge(rating: rating)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .lineLimit(2)

                    if let brand = food.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let analysis = food.ingredientAnalysis {
                        HStack(spacing: 4) {
                            Text(analysis.rating.label)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(ratingColor(for: analysis.rating))

                            Text("•")
                                .foregroundColor(.secondary)

                            Text("Score: \(analysis.score)/100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [backgroundGradientColor.opacity(0.1), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func warningsSection(_ analysis: IngredientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Concerns Found")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()

                if analysis.warnings.count > 3 {
                    Button(showAllWarnings ? "Show Less" : "Show All") {
                        withAnimation { showAllWarnings.toggle() }
                    }
                    .font(.caption)
                }
            }

            let warningsToShow = showAllWarnings ? analysis.warnings : Array(analysis.warnings.prefix(3))

            ForEach(warningsToShow) { warning in
                WarningRow(warning: warning)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
    }

    private func positivesSection(_ analysis: IngredientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Good Ingredients")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            FlowLayout(spacing: 8) {
                ForEach(analysis.positives, id: \.self) { positive in
                    Text(positive)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }

    private var macrosSection: some View {
        HStack(spacing: 0) {
            MacroItem(
                value: food.calories.map { "\(Int($0))" } ?? "-",
                label: "Cal",
                color: .orange
            )
            Divider().frame(height: 40)
            MacroItem(
                value: food.proteinG.map { "\(Int($0))g" } ?? "-",
                label: "Protein",
                color: .blue
            )
            Divider().frame(height: 40)
            MacroItem(
                value: food.carbsG.map { "\(Int($0))g" } ?? "-",
                label: "Carbs",
                color: .green
            )
            Divider().frame(height: 40)
            MacroItem(
                value: food.fatG.map { "\(Int($0))g" } ?? "-",
                label: "Fat",
                color: .purple
            )
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    private var backgroundGradientColor: Color {
        guard let rating = food.healthRating else { return .gray }
        return ratingColor(for: rating)
    }

    private func ratingColor(for rating: FoodHealthRating) -> Color {
        switch rating {
        case .excellent: return .green
        case .good: return Color(red: 0.5, green: 0.8, blue: 0.2)
        case .okay: return .yellow
        case .poor: return .orange
        case .bad: return .red
        }
    }
}

struct WarningRow: View {
    let warning: IngredientWarning

    var severityColor: Color {
        switch warning.severity {
        case 3: return .red
        case 2: return .orange
        default: return .yellow
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: warning.category.icon)
                .font(.caption)
                .foregroundColor(severityColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(warning.ingredient.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(warning.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Severity indicator
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < warning.severity ? severityColor : Color(.systemGray4))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct MacroItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }

            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Compact Badge for Lists

struct FoodHealthBadgeSmall: View {
    let rating: FoodHealthRating

    var ratingColor: Color {
        switch rating {
        case .excellent: return .green
        case .good: return Color(red: 0.5, green: 0.8, blue: 0.2)
        case .okay: return .yellow
        case .poor: return .orange
        case .bad: return .red
        }
    }

    var body: some View {
        Text(rating.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 22, height: 22)
            .background(ratingColor)
            .clipShape(Circle())
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        FoodHealthRatingCard(
            food: CustomFood(
                id: "1",
                name: "Protein Bar",
                brand: "Quest",
                servingSize: "1 bar (60g)",
                servingSizeG: 60,
                calories: 200,
                proteinG: 21,
                carbsG: 22,
                fatG: 8,
                fiberG: 14,
                sugarG: 1,
                barcode: "123456789",
                source: "openfoodfacts",
                isVerified: true,
                createdAt: Date(),
                ingredients: "Protein Blend, Soluble Corn Fiber, Almonds, Water, Unsweetened Chocolate, Erythritol, Cocoa Butter, Palm Oil",
                ingredientAnalysis: IngredientAnalysis(
                    rating: .okay,
                    score: 65,
                    warnings: [
                        IngredientWarning(
                            ingredient: "Palm Oil",
                            category: .seedOil,
                            severity: 2,
                            reason: "Processed seed oil high in saturated fat"
                        ),
                        IngredientWarning(
                            ingredient: "Erythritol",
                            category: .artificialSweetener,
                            severity: 1,
                            reason: "Sugar alcohol, generally safe but may cause digestive issues"
                        )
                    ],
                    positives: ["High Protein", "High Fiber", "Low Sugar"],
                    ingredientsList: nil
                )
            )
        )
        .padding()
    }
}
