import SwiftUI

/// Detailed view of a blood work panel with results and analysis
struct BloodWorkDetailSheet: View {
    let panel: BloodWorkPanel
    @ObservedObject var viewModel: BloodWorkViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    Text("Results").tag(0)
                    Text("Analysis").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $selectedTab) {
                    ResultsView(panel: panel)
                        .tag(0)

                    AnalysisView(panel: panel, viewModel: viewModel)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(panel.labName ?? "Lab Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if panel.aiAnalyzedAt == nil {
                        Button {
                            Task { await viewModel.analyzePanel(panel) }
                        } label: {
                            if viewModel.isAnalyzing {
                                ProgressView()
                            } else {
                                Text("Analyze")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Results View

struct ResultsView: View {
    let panel: BloodWorkPanel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Test info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Test Date")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(panel.testDate, style: .date)
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Source")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(panel.source.rawValue.capitalized)
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Marker categories
                CategoryResultCard(
                    title: "Vitamins & Minerals",
                    icon: "pills.fill",
                    color: .orange,
                    markers: [
                        ("Vitamin D", panel.vitaminDNgMl, "ng/mL", 30, 100),
                        ("Vitamin B12", panel.vitaminB12PgMl, "pg/mL", 200, 900),
                        ("Folate", panel.folateNgMl, "ng/mL", 3, 17),
                        ("Iron", panel.ironMcgDl, "mcg/dL", 60, 170),
                        ("Ferritin", panel.ferritinNgMl, "ng/mL", 12, 300),
                    ]
                )

                CategoryResultCard(
                    title: "Metabolic",
                    icon: "chart.bar.fill",
                    color: .blue,
                    markers: [
                        ("Fasting Glucose", panel.fastingGlucoseMgDl, "mg/dL", 70, 99),
                        ("HbA1c", panel.hba1cPercent, "%", 4.0, 5.6),
                        ("Insulin", panel.insulinMiuMl, "mIU/mL", 2.6, 24.9),
                    ]
                )

                CategoryResultCard(
                    title: "Lipids",
                    icon: "heart.fill",
                    color: .red,
                    markers: [
                        ("Total Cholesterol", panel.totalCholesterolMgDl, "mg/dL", 125, 200),
                        ("LDL", panel.ldlMgDl, "mg/dL", 0, 100),
                        ("HDL", panel.hdlMgDl, "mg/dL", 40, 100),
                        ("Triglycerides", panel.triglyceridesMgDl, "mg/dL", 0, 150),
                    ]
                )

                CategoryResultCard(
                    title: "Hormones",
                    icon: "waveform.path.ecg",
                    color: .purple,
                    markers: [
                        ("Testosterone", panel.testosteroneTotalNgDl, "ng/dL", 300, 1000),
                        ("TSH", panel.tshMiuL, "mIU/L", 0.4, 4.0),
                        ("Cortisol", panel.cortisolMcgDl, "mcg/dL", 6, 23),
                    ]
                )

                CategoryResultCard(
                    title: "Complete Blood Count",
                    icon: "drop.fill",
                    color: .pink,
                    markers: [
                        ("Hemoglobin", panel.hemoglobinGDl, "g/dL", 12, 17.5),
                        ("Hematocrit", panel.hematocritPercent, "%", 36, 50),
                    ]
                )

                CategoryResultCard(
                    title: "Liver & Kidney",
                    icon: "staroflife.fill",
                    color: .green,
                    markers: [
                        ("ALT", panel.altUL, "U/L", 7, 56),
                        ("AST", panel.astUL, "U/L", 10, 40),
                        ("Creatinine", panel.creatinineMgDl, "mg/dL", 0.7, 1.3),
                    ]
                )
            }
            .padding()
        }
    }
}

// MARK: - Category Result Card

struct CategoryResultCard: View {
    let title: String
    let icon: String
    let color: Color
    let markers: [(String, Double?, String, Double, Double)]

    var visibleMarkers: [(String, Double?, String, Double, Double)] {
        markers.filter { $0.1 != nil }
    }

    var body: some View {
        if !visibleMarkers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)

                    Text(title)
                        .font(.headline)
                }

                ForEach(visibleMarkers, id: \.0) { marker in
                    if let value = marker.1 {
                        MarkerResultRow(
                            name: marker.0,
                            value: value,
                            unit: marker.2,
                            referenceLow: marker.3,
                            referenceHigh: marker.4
                        )
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct MarkerResultRow: View {
    let name: String
    let value: Double
    let unit: String
    let referenceLow: Double
    let referenceHigh: Double

    var status: MarkerStatus {
        if value < referenceLow { return .low }
        if value > referenceHigh { return .high }
        return .optimal
    }

    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text(name)
                .font(.subheadline)

            Spacer()

            Text(String(format: "%.1f", value))
                .font(.subheadline)
                .fontWeight(.medium)

            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
        }
    }
}

// MARK: - Analysis View

struct AnalysisView: View {
    let panel: BloodWorkPanel
    @ObservedObject var viewModel: BloodWorkViewModel

    var body: some View {
        ScrollView {
            if let analysis = viewModel.analysis {
                VStack(spacing: 20) {
                    // Health score
                    VStack(spacing: 8) {
                        HealthScoreBadge(score: analysis.healthScore)

                        Text(analysis.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Supplement recommendations
                    if !analysis.supplementRecommendations.isEmpty {
                        BloodWorkRecommendationsCard(
                            title: "Supplement Recommendations",
                            icon: "pills.fill",
                            recommendations: analysis.supplementRecommendations.map {
                                ($0.supplementName, $0.reason, $0.priority)
                            }
                        )
                    }

                    // Nutrition recommendations
                    if !analysis.nutritionRecommendations.isEmpty {
                        NutritionRecommendationsCard(recommendations: analysis.nutritionRecommendations)
                    }

                    // Workout recommendations
                    if !analysis.workoutRecommendations.isEmpty {
                        WorkoutRecommendationsCard(recommendations: analysis.workoutRecommendations)
                    }

                    // Apply recommendations button
                    if !analysis.supplementRecommendations.isEmpty || !analysis.targetAdjustments.isEmpty {
                        ApplyRecommendationsButton(panelId: panel.id, viewModel: viewModel)
                    }
                }
                .padding()
            } else if panel.aiAnalyzedAt == nil {
                VStack(spacing: 16) {
                    Image(systemName: "brain")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Analysis Yet")
                        .font(.headline)

                    Text("Tap 'Analyze' to get AI-powered insights and recommendations based on your blood work results.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
            } else {
                // Analysis was done but not loaded
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading analysis...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(32)
                .task {
                    await viewModel.analyzePanel(panel)
                }
            }
        }
    }
}

// MARK: - Recommendations Cards

struct BloodWorkRecommendationsCard: View {
    let title: String
    let icon: String
    let recommendations: [(String, String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)

                Text(title)
                    .font(.headline)
            }

            ForEach(recommendations, id: \.0) { rec in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(priorityColor(rec.2))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(rec.0)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(rec.1)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
}

struct NutritionRecommendationsCard: View {
    let recommendations: [NutritionRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)

                Text("Nutrition Recommendations")
                    .font(.headline)
            }

            ForEach(recommendations) { rec in
                VStack(alignment: .leading, spacing: 8) {
                    Text(rec.recommendation)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if !rec.foodsToIncrease.isEmpty {
                        HStack {
                            Text("Increase:")
                                .font(.caption)
                                .foregroundColor(.green)

                            Text(rec.foodsToIncrease.joined(separator: ", "))
                                .font(.caption)
                        }
                    }

                    if !rec.foodsToLimit.isEmpty {
                        HStack {
                            Text("Limit:")
                                .font(.caption)
                                .foregroundColor(.orange)

                            Text(rec.foodsToLimit.joined(separator: ", "))
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct WorkoutRecommendationsCard: View {
    let recommendations: [WorkoutRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.blue)

                Text("Workout Adjustments")
                    .font(.headline)
            }

            ForEach(recommendations) { rec in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(Int(rec.intensityModifier * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(rec.intensityModifier < 0.9 ? Color.orange : Color.green)
                        .cornerRadius(6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(rec.recommendation)
                            .font(.subheadline)

                        Text(rec.reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ApplyRecommendationsButton: View {
    let panelId: String
    @ObservedObject var viewModel: BloodWorkViewModel

    @State private var showConfirm = false

    var body: some View {
        Button {
            showConfirm = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Apply Recommendations")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .confirmationDialog("Apply Recommendations", isPresented: $showConfirm) {
            Button("Create Suggested Supplements") {
                Task {
                    await viewModel.applyRecommendations(
                        panelId: panelId,
                        supplements: true,
                        targets: false
                    )
                }
            }

            Button("Update Nutrient Targets") {
                Task {
                    await viewModel.applyRecommendations(
                        panelId: panelId,
                        supplements: false,
                        targets: true
                    )
                }
            }

            Button("Apply All") {
                Task {
                    await viewModel.applyRecommendations(
                        panelId: panelId,
                        supplements: true,
                        targets: true
                    )
                }
            }

            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    BloodWorkDetailSheet(
        panel: BloodWorkPanel(
            id: "1",
            userId: "user",
            testDate: Date(),
            source: .manual,
            createdAt: Date(),
            updatedAt: Date()
        ),
        viewModel: BloodWorkViewModel()
    )
}
