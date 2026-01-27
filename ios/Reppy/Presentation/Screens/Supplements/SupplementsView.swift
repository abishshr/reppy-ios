import SwiftUI

/// Main view for managing supplements and logging intake
struct SupplementsView: View {
    @StateObject private var viewModel = SupplementsViewModel()
    @State private var showAddSupplement = false
    @State private var showLogSheet = false
    @State private var selectedSupplement: Supplement?
    @State private var editingSupplement: Supplement?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Summary Card
                    if viewModel.todaySummary?.hasData == true {
                        TodaySupplementCard(summary: viewModel.todaySummary!)
                    }

                    // Quick Log Section
                    if !viewModel.supplements.isEmpty {
                        quickLogSection
                    }

                    // My Supplements Section
                    mySupplementsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Supplements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSupplement = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showAddSupplement) {
                AddSupplementSheet(viewModel: viewModel)
            }
            .sheet(item: $editingSupplement) { supplement in
                AddSupplementSheet(viewModel: viewModel, editingSupplement: supplement)
            }
            .sheet(item: $selectedSupplement) { supplement in
                LogSupplementSheet(supplement: supplement, viewModel: viewModel)
            }
        }
    }

    // MARK: - Quick Log Section

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.supplements.prefix(4)) { supplement in
                    QuickLogSupplementCard(supplement: supplement) {
                        selectedSupplement = supplement
                    }
                }
            }
        }
    }

    // MARK: - My Supplements Section

    private var mySupplementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Supplements")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.supplements.isEmpty {
                    Button {
                        showAddSupplement = true
                    } label: {
                        Text("Add First")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            if viewModel.isLoading && viewModel.supplements.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.supplements.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.supplements) { supplement in
                    SupplementRow(
                        supplement: supplement,
                        onLog: { selectedSupplement = supplement },
                        onEdit: { editingSupplement = supplement },
                        onDelete: {
                            Task { await viewModel.deleteSupplement(supplement) }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple.opacity(0.6))

            Text("No Supplements Yet")
                .font(.headline)

            Text("Add your vitamins and supplements\nto track your daily intake")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddSupplement = true
            } label: {
                Label("Add Supplement", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Today's Supplement Card

struct TodaySupplementCard: View {
    let summary: TodaySupplementSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
                Text("\(summary.totalLogs) taken")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !summary.supplementsTaken.isEmpty {
                FlowLayoutSupplements(items: summary.supplementsTaken)
            }

            // Key nutrients from supplements
            HStack(spacing: 16) {
                if summary.totalVitaminDMcg > 0 {
                    NutrientPill(name: "Vit D", value: "\(Int(summary.totalVitaminDMcg)) mcg", color: .orange)
                }
                if summary.totalVitaminCMg > 0 {
                    NutrientPill(name: "Vit C", value: "\(Int(summary.totalVitaminCMg)) mg", color: .yellow)
                }
                if summary.totalCalciumMg > 0 {
                    NutrientPill(name: "Calcium", value: "\(Int(summary.totalCalciumMg)) mg", color: .blue)
                }
                if summary.totalIronMg > 0 {
                    NutrientPill(name: "Iron", value: "\(Int(summary.totalIronMg)) mg", color: .red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Nutrient Pill

struct NutrientPill: View {
    let name: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Flow Layout for supplement names

struct FlowLayoutSupplements: View {
    let items: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Quick Log Card

struct QuickLogSupplementCard: View {
    let supplement: Supplement
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "pills.fill")
                        .font(.title2)
                        .foregroundColor(.purple)

                    Spacer()

                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.purple, .purple.opacity(0.2))
                }

                Text(supplement.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let brand = supplement.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supplement Row

struct SupplementRow: View {
    let supplement: Supplement
    let onLog: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "pills.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.purple)
                )

            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(supplement.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if let brand = supplement.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let servingSize = supplement.servingSize {
                        Text(servingSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(supplement.nutrientSummary)
                    .font(.caption2)
                    .foregroundColor(.purple)
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: onLog) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green, .green.opacity(0.2))
                }

                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
        .confirmationDialog("Delete \(supplement.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SupplementsView()
}
