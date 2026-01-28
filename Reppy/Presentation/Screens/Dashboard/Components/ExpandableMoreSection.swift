import SwiftUI

/// Expandable section showing nutrition details, vitamins, supplements, etc.
struct ExpandableMoreSection: View {
    @State private var isExpanded = false
    @State private var isVitaminsExpanded = false

    // Nutrition data
    let fiber: Double
    let fiberTarget: Double
    let sugar: Double
    let sugarLimit: Double
    let sodium: Double
    let sodiumLimit: Double
    let saturatedFat: Double
    let saturatedFatLimit: Double

    // Vitamin/mineral data
    let vitaminMineralTotals: VitaminMineralTotals
    let vitaminMineralTargets: MicronutrientTargets?

    // Callbacks for navigation
    var onSupplementsTap: () -> Void
    var onBloodWorkTap: () -> Void
    var onCycleTap: (() -> Void)?
    var isFemale: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    Text("More Details")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    Spacer()

                    if !isExpanded {
                        Text("Vitamins, Supplements, Blood Work")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 16) {
                    // Nutrition limits grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        NutritionMiniCard(
                            label: "Fiber",
                            current: fiber,
                            target: fiberTarget,
                            unit: "g",
                            color: .green,
                            isLimit: false
                        )

                        NutritionMiniCard(
                            label: "Sugar",
                            current: sugar,
                            target: sugarLimit,
                            unit: "g",
                            color: .orange,
                            isLimit: true
                        )

                        NutritionMiniCard(
                            label: "Sodium",
                            current: sodium,
                            target: sodiumLimit,
                            unit: "mg",
                            color: .blue,
                            isLimit: true
                        )

                        NutritionMiniCard(
                            label: "Sat Fat",
                            current: saturatedFat,
                            target: saturatedFatLimit,
                            unit: "g",
                            color: .purple,
                            isLimit: true
                        )
                    }
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.horizontal, 16)

                    // Vitamins & Minerals Expandable Section
                    VStack(spacing: 0) {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isVitaminsExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "pill.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.purple)
                                    .frame(width: 24)

                                Text("Vitamins & Minerals")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: isVitaminsExpanded ? "chevron.down" : "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        if isVitaminsExpanded {
                            VitaminMineralDropdown(
                                totals: vitaminMineralTotals,
                                targets: vitaminMineralTargets
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                    }

                    // Other navigation links
                    VStack(spacing: 0) {
                        NavigationRow(
                            icon: "capsule.fill",
                            iconColor: .blue,
                            title: "Supplements",
                            action: onSupplementsTap
                        )

                        NavigationRow(
                            icon: "drop.fill",
                            iconColor: .red,
                            title: "Blood Work",
                            action: onBloodWorkTap
                        )

                        if isFemale, let onCycleTap = onCycleTap {
                            NavigationRow(
                                icon: "circle.hexagonpath.fill",
                                iconColor: .pink,
                                title: "Cycle Tracking",
                                action: onCycleTap
                            )
                        }
                    }
                }
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

/// Dropdown content showing vitamins and minerals
struct VitaminMineralDropdown: View {
    let totals: VitaminMineralTotals
    let targets: MicronutrientTargets?

    var body: some View {
        VStack(spacing: 12) {
            if let targets = targets {
                // Key nutrients - 2 column grid
                let keyNutrients = totals.keyNutrients(targets: targets)
                let rows = stride(from: 0, to: keyNutrients.count, by: 2).map { i in
                    Array(keyNutrients[i..<min(i + 2, keyNutrients.count)])
                }

                VStack(spacing: 8) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 8) {
                            ForEach(row) { nutrient in
                                KeyNutrientProgressRow(nutrient: nutrient)
                            }
                            if row.count == 1 {
                                Spacer()
                            }
                        }
                    }
                }

                // Vitamins section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vitamins")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    VStack(spacing: 2) {
                        MicronutrientMiniRow(name: "Vitamin A", value: totals.vitaminA, target: targets.vitaminA, unit: "mcg")
                        MicronutrientMiniRow(name: "Vitamin C", value: totals.vitaminC, target: targets.vitaminC, unit: "mg")
                        MicronutrientMiniRow(name: "Vitamin D", value: totals.vitaminD, target: targets.vitaminD, unit: "mcg")
                        MicronutrientMiniRow(name: "Vitamin E", value: totals.vitaminE, target: targets.vitaminE, unit: "mg")
                        MicronutrientMiniRow(name: "Vitamin K", value: totals.vitaminK, target: targets.vitaminK, unit: "mcg")
                        MicronutrientMiniRow(name: "Thiamin (B1)", value: totals.thiamin, target: targets.thiamin, unit: "mg")
                        MicronutrientMiniRow(name: "Riboflavin (B2)", value: totals.riboflavin, target: targets.riboflavin, unit: "mg")
                        MicronutrientMiniRow(name: "Niacin (B3)", value: totals.niacin, target: targets.niacin, unit: "mg")
                        MicronutrientMiniRow(name: "Vitamin B6", value: totals.vitaminB6, target: targets.vitaminB6, unit: "mg")
                        MicronutrientMiniRow(name: "Folate (B9)", value: totals.folate, target: targets.folate, unit: "mcg")
                        MicronutrientMiniRow(name: "Vitamin B12", value: totals.vitaminB12, target: targets.vitaminB12, unit: "mcg")
                    }
                }

                // Minerals section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Minerals")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    VStack(spacing: 2) {
                        MicronutrientMiniRow(name: "Calcium", value: totals.calcium, target: targets.calcium, unit: "mg")
                        MicronutrientMiniRow(name: "Iron", value: totals.iron, target: targets.iron, unit: "mg")
                        MicronutrientMiniRow(name: "Magnesium", value: totals.magnesium, target: targets.magnesium, unit: "mg")
                        MicronutrientMiniRow(name: "Phosphorus", value: totals.phosphorus, target: targets.phosphorus, unit: "mg")
                        MicronutrientMiniRow(name: "Potassium", value: totals.potassium, target: targets.potassium, unit: "mg")
                        MicronutrientMiniRow(name: "Zinc", value: totals.zinc, target: targets.zinc, unit: "mg")
                        MicronutrientMiniRow(name: "Selenium", value: totals.selenium, target: targets.selenium, unit: "mcg")
                        MicronutrientMiniRow(name: "Copper", value: totals.copper, target: targets.copper, unit: "mcg")
                        MicronutrientMiniRow(name: "Manganese", value: totals.manganese, target: targets.manganese, unit: "mg")
                    }
                }
            } else {
                Text("Complete your profile to see personalized targets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Row showing a key micronutrient with progress
struct KeyNutrientProgressRow: View {
    let nutrient: KeyNutrientProgress

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: nutrient.icon)
                .font(.system(size: 14))
                .foregroundColor(nutrient.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(nutrient.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text(nutrient.formattedActual)
                        .font(.caption.bold())
                        .foregroundColor(.primary)

                    Text("/")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(nutrient.formattedTarget)\(nutrient.unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Mini progress circle
            ZStack {
                Circle()
                    .stroke(nutrient.color.opacity(0.2), lineWidth: 3)
                    .frame(width: 24, height: 24)

                Circle()
                    .trim(from: 0, to: nutrient.progress)
                    .stroke(nutrient.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

/// Compact row for all vitamins/minerals list
struct MicronutrientMiniRow: View {
    let name: String
    let value: Double
    let target: Double
    let unit: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }

    private var statusColor: Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.5 { return .orange }
        return .secondary
    }

    private var formattedValue: String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    private var nutrientIcon: (String, Color) {
        switch name.lowercased() {
        // Vitamins
        case "vitamin a": return ("eye.fill", .orange)
        case "vitamin c": return ("leaf.fill", .orange)
        case "vitamin d": return ("sun.max.fill", .yellow)
        case "vitamin e": return ("shield.fill", .green)
        case "vitamin k": return ("bandage.fill", .green)
        case "thiamin (b1)", "thiamin": return ("bolt.fill", .yellow)
        case "riboflavin (b2)", "riboflavin": return ("flame.fill", .orange)
        case "niacin (b3)", "niacin": return ("heart.fill", .red)
        case "vitamin b6": return ("brain.head.profile", .purple)
        case "folate (b9)", "folate": return ("leaf.arrow.circlepath", .green)
        case "vitamin b12": return ("drop.fill", .red)
        // Minerals
        case "calcium": return ("bone", .gray)
        case "iron": return ("drop.fill", .red)
        case "magnesium": return ("sparkles", .purple)
        case "phosphorus": return ("atom", .blue)
        case "potassium": return ("bolt.fill", .blue)
        case "zinc": return ("shield.checkerboard", .teal)
        case "selenium": return ("sparkle", .cyan)
        case "copper": return ("circle.hexagongrid.fill", .orange)
        case "manganese": return ("leaf.circle.fill", .brown)
        default: return ("circle.fill", .gray)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: nutrientIcon.0)
                .font(.system(size: 10))
                .foregroundColor(nutrientIcon.1)
                .frame(width: 14)

            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            Text("\(formattedValue)/\(Int(target))\(unit)")
                .font(.caption2.bold())
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 4)
    }
}

/// Mini card for nutrition limits
struct NutritionMiniCard: View {
    let label: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    let isLimit: Bool // true = stay under, false = reach target

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    private var statusColor: Color {
        if isLimit {
            return current > target ? .red : (progress > 0.8 ? .orange : .green)
        } else {
            return progress >= 1.0 ? .green : (progress > 0.5 ? .orange : color)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(current))/\(Int(target))\(unit)")
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Navigation row for detail screens
struct NavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        ExpandableMoreSection(
            fiber: 18,
            fiberTarget: 25,
            sugar: 32,
            sugarLimit: 50,
            sodium: 1200,
            sodiumLimit: 2300,
            saturatedFat: 12,
            saturatedFatLimit: 20,
            vitaminMineralTotals: VitaminMineralTotals(),
            vitaminMineralTargets: nil,
            onSupplementsTap: {},
            onBloodWorkTap: {},
            onCycleTap: {},
            isFemale: true
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
