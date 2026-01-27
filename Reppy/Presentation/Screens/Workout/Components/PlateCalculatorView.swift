import SwiftUI

/// Plate calculator for barbell loading
struct PlateCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var targetWeight: Double = 60
    @State private var barWeight: Double = 20
    @State private var useMetric: Bool = true

    // Available plates (per side)
    private let metricPlates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]
    private let imperialPlates: [Double] = [45, 35, 25, 10, 5, 2.5]

    private var plates: [Double] {
        useMetric ? metricPlates : imperialPlates
    }

    private var unit: String {
        useMetric ? "kg" : "lbs"
    }

    private var defaultBars: [(String, Double)] {
        if useMetric {
            return [
                ("Olympic (20kg)", 20),
                ("Women's (15kg)", 15),
                ("EZ Bar (10kg)", 10),
                ("No Bar", 0)
            ]
        } else {
            return [
                ("Olympic (45lbs)", 45),
                ("Women's (35lbs)", 35),
                ("EZ Bar (25lbs)", 25),
                ("No Bar", 0)
            ]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Unit Toggle
                    Picker("Unit", selection: $useMetric) {
                        Text("Kilograms").tag(true)
                        Text("Pounds").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Target Weight Input
                    VStack(spacing: 12) {
                        Text("Target Weight")
                            .font(.headline)

                        HStack(spacing: 16) {
                            Button {
                                targetWeight = max(barWeight, targetWeight - 2.5)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }

                            Text("\(String(format: "%.1f", targetWeight)) \(unit)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()

                            Button {
                                targetWeight += 2.5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }

                        // Quick weight buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickWeights, id: \.self) { weight in
                                    Button {
                                        targetWeight = weight
                                    } label: {
                                        Text("\(Int(weight))\(unit)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(targetWeight == weight ? .white : .primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(targetWeight == weight ? Color.blue : Color(.secondarySystemBackground))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Bar Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bar Type")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(defaultBars, id: \.0) { bar in
                                    Button {
                                        barWeight = bar.1
                                        if targetWeight < barWeight {
                                            targetWeight = barWeight
                                        }
                                    } label: {
                                        Text(bar.0)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(barWeight == bar.1 ? .white : .primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(barWeight == bar.1 ? Color.blue : Color(.secondarySystemBackground))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Barbell Visualization
                    BarbellVisualization(
                        plates: calculatePlates(),
                        barWeight: barWeight,
                        unit: unit
                    )
                    .padding(.horizontal)

                    // Plate Breakdown
                    PlateBreakdown(
                        plates: calculatePlates(),
                        barWeight: barWeight,
                        targetWeight: targetWeight,
                        unit: unit
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Plate Calculator")
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

    private var quickWeights: [Double] {
        if useMetric {
            return [20, 40, 60, 80, 100, 120, 140, 160, 180, 200]
        } else {
            return [45, 95, 135, 185, 225, 275, 315, 365, 405, 495]
        }
    }

    private func calculatePlates() -> [(plate: Double, count: Int)] {
        var remaining = (targetWeight - barWeight) / 2 // Per side
        var result: [(Double, Int)] = []

        if remaining <= 0 {
            return []
        }

        for plate in plates {
            let count = Int(remaining / plate)
            if count > 0 {
                result.append((plate, count))
                remaining -= Double(count) * plate
            }
        }

        return result
    }
}

// MARK: - Barbell Visualization

struct BarbellVisualization: View {
    let plates: [(plate: Double, count: Int)]
    let barWeight: Double
    let unit: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Load Each Side")
                .font(.headline)

            GeometryReader { geo in
                let centerX = geo.size.width / 2
                let barHeight: CGFloat = 12
                let maxPlateHeight: CGFloat = 100

                ZStack {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray)
                        .frame(width: geo.size.width * 0.9, height: barHeight)
                        .position(x: centerX, y: geo.size.height / 2)

                    // Collar indicators
                    ForEach([0.15, 0.85], id: \.self) { position in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 8, height: 24)
                            .position(x: geo.size.width * position, y: geo.size.height / 2)
                    }

                    // Left side plates
                    HStack(spacing: 2) {
                        ForEach(Array(plates.enumerated()), id: \.offset) { _, item in
                            ForEach(0..<item.count, id: \.self) { _ in
                                PlateView(
                                    weight: item.plate,
                                    maxHeight: maxPlateHeight,
                                    unit: unit
                                )
                            }
                        }
                    }
                    .position(x: geo.size.width * 0.15 - 20, y: geo.size.height / 2)

                    // Right side plates (mirrored)
                    HStack(spacing: 2) {
                        ForEach(Array(plates.reversed().enumerated()), id: \.offset) { _, item in
                            ForEach(0..<item.count, id: \.self) { _ in
                                PlateView(
                                    weight: item.plate,
                                    maxHeight: maxPlateHeight,
                                    unit: unit
                                )
                            }
                        }
                    }
                    .position(x: geo.size.width * 0.85 + 20, y: geo.size.height / 2)
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct PlateView: View {
    let weight: Double
    let maxHeight: CGFloat
    let unit: String

    var height: CGFloat {
        // Scale plate height based on weight
        let maxWeight: Double = unit == "kg" ? 25 : 45
        let minHeight: CGFloat = 30
        let scale = min(1, weight / maxWeight)
        return minHeight + (maxHeight - minHeight) * scale
    }

    var plateColor: Color {
        // Standard Olympic plate colors
        if unit == "kg" {
            switch weight {
            case 25: return .red
            case 20: return .blue
            case 15: return .yellow
            case 10: return .green
            case 5: return .white
            case 2.5: return .red.opacity(0.6)
            case 1.25: return .gray
            default: return .gray
            }
        } else {
            switch weight {
            case 45: return .blue
            case 35: return .yellow
            case 25: return .green
            case 10: return .white
            case 5: return .red.opacity(0.6)
            case 2.5: return .gray
            default: return .gray
            }
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(plateColor)
            .frame(width: 14, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Plate Breakdown

struct PlateBreakdown: View {
    let plates: [(plate: Double, count: Int)]
    let barWeight: Double
    let targetWeight: Double
    let unit: String

    var totalPlateWeight: Double {
        plates.reduce(0) { $0 + $1.plate * Double($1.count) } * 2 // Both sides
    }

    var achievedWeight: Double {
        barWeight + totalPlateWeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plate Breakdown (per side)")
                .font(.headline)

            if plates.isEmpty {
                Text("No plates needed - just the bar!")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(plates.enumerated()), id: \.offset) { _, item in
                        HStack {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(plateColor(for: item.plate))
                                    .frame(width: 16, height: 16)

                                Text("\(String(format: "%.1f", item.plate)) \(unit)")
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            Text("x\(item.count)")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }

            Divider()

            // Summary
            VStack(spacing: 8) {
                HStack {
                    Text("Bar")
                    Spacer()
                    Text("\(String(format: "%.1f", barWeight)) \(unit)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Plates (total)")
                    Spacer()
                    Text("\(String(format: "%.1f", totalPlateWeight)) \(unit)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Total Weight")
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(String(format: "%.1f", achievedWeight)) \(unit)")
                        .fontWeight(.bold)
                        .foregroundColor(achievedWeight == targetWeight ? .green : .orange)
                }
            }

            if achievedWeight != targetWeight {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("Closest possible: \(String(format: "%.1f", achievedWeight)) \(unit)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func plateColor(for weight: Double) -> Color {
        if unit == "kg" {
            switch weight {
            case 25: return .red
            case 20: return .blue
            case 15: return .yellow
            case 10: return .green
            case 5: return .white
            case 2.5: return .red.opacity(0.6)
            case 1.25: return .gray
            default: return .gray
            }
        } else {
            switch weight {
            case 45: return .blue
            case 35: return .yellow
            case 25: return .green
            case 10: return .white
            case 5: return .red.opacity(0.6)
            case 2.5: return .gray
            default: return .gray
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PlateCalculatorView()
}
