import SwiftUI
import PhotosUI

/// Main blood work tracking screen
struct BloodWorkView: View {
    @StateObject private var viewModel = BloodWorkViewModel()

    @State private var showAddOptions = false
    @State private var showManualEntry = false
    @State private var showOCRReview = false
    @State private var showDetail = false
    @State private var selectedImage: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Card
                    if let summary = viewModel.summary, summary.hasData {
                        BloodWorkSummaryCard(summary: summary)
                    } else {
                        EmptyStateCard()
                    }

                    // Quick Actions
                    BloodWorkQuickActions(
                        onUploadPhoto: { showAddOptions = true },
                        onManualEntry: { showManualEntry = true }
                    )

                    // History
                    if !viewModel.panels.isEmpty {
                        BloodWorkHistorySection(
                            panels: viewModel.panels,
                            onSelect: { panel in
                                viewModel.selectedPanel = panel
                                showDetail = true
                            },
                            onDelete: { panel in
                                Task { await viewModel.deletePanel(panel) }
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Blood Work")
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
            .confirmationDialog("Add Blood Work", isPresented: $showAddOptions) {
                PhotosPicker(
                    selection: $selectedImage,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Upload Lab Report Photo")
                }
                Button("Enter Manually") {
                    showManualEntry = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: selectedImage) { _, newValue in
                if let item = newValue {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await viewModel.uploadImage(image)
                            if viewModel.ocrResponse?.success == true {
                                showOCRReview = true
                            }
                        }
                    }
                    selectedImage = nil
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntrySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showOCRReview) {
                OCRReviewSheet(viewModel: viewModel, isPresented: $showOCRReview)
            }
            .sheet(isPresented: $showDetail) {
                if let panel = viewModel.selectedPanel {
                    BloodWorkDetailSheet(panel: panel, viewModel: viewModel)
                }
            }
            .overlay {
                if viewModel.isUploading {
                    ProgressOverlay(message: "Analyzing lab report...")
                }
            }
        }
    }
}

// MARK: - Summary Card

struct BloodWorkSummaryCard: View {
    let summary: BloodWorkSummary

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Health Score
                if let score = summary.healthScore {
                    HealthScoreBadge(score: score)
                }

                Spacer()

                // Last test info
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Test")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let date = summary.latestTestDate {
                        Text(date, style: .date)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if let days = summary.daysSinceTest {
                        Text("\(days) days ago")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Marker counts
            HStack(spacing: 24) {
                MarkerCountBadge(
                    count: summary.optimalCount,
                    label: "Optimal",
                    color: .green
                )

                MarkerCountBadge(
                    count: summary.suboptimalCount,
                    label: "Suboptimal",
                    color: .orange
                )

                MarkerCountBadge(
                    count: summary.outOfRangeCount,
                    label: "Out of Range",
                    color: .red
                )
            }

            // Top concerns
            if !summary.topConcerns.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Needs Attention")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(summary.topConcerns.prefix(3), id: \.self) { concern in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(concern)
                                .font(.subheadline)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Blood Work Health Score Badge

struct BloodWorkHealthScore: View {
    let score: Int

    var body: some View {
        VStack(spacing: 4) {
            HealthScoreBadge(score: score, size: .large)

            Text("Health Score")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Marker Count Badge

struct MarkerCountBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty State

struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.6))

            Text("No Blood Work Yet")
                .font(.headline)

            Text("Upload a lab report photo or enter your results manually to track your health markers.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Quick Actions

struct BloodWorkQuickActions: View {
    let onUploadPhoto: () -> Void
    let onManualEntry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Results")
                .font(.headline)

            HStack(spacing: 12) {
                BloodWorkActionButton(
                    icon: "camera.fill",
                    title: "Upload Photo",
                    subtitle: "AI extracts values",
                    color: .blue,
                    action: onUploadPhoto
                )

                BloodWorkActionButton(
                    icon: "pencil",
                    title: "Manual Entry",
                    subtitle: "Enter values",
                    color: .purple,
                    action: onManualEntry
                )
            }
        }
    }
}

struct BloodWorkActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - History Section

struct BloodWorkHistorySection: View {
    let panels: [BloodWorkPanel]
    let onSelect: (BloodWorkPanel) -> Void
    let onDelete: (BloodWorkPanel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)

            ForEach(panels) { panel in
                BloodWorkHistoryRow(panel: panel)
                    .onTapGesture { onSelect(panel) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(panel)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
}

struct BloodWorkHistoryRow: View {
    let panel: BloodWorkPanel

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.red.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "drop.fill")
                        .foregroundColor(.red)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(panel.labName ?? "Lab Results")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(panel.testDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(panel.markerCount) markers")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if panel.aiAnalyzedAt != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Progress Overlay

struct ProgressOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
        }
    }
}

#Preview {
    BloodWorkView()
}
