import SwiftUI

/// Sheet for logging daily cycle data
struct CycleLoggerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let apiClient: APIClient
    let date: Date
    let existingLog: MenstrualCycleLog?
    let onSaved: (MenstrualCycleLog) -> Void

    @State private var isPeriodDay: Bool = false
    @State private var flowIntensity: FlowIntensity? = nil
    @State private var selectedSymptoms: Set<CycleSymptom> = []
    @State private var mood: Int = 3
    @State private var energyLevel: Int = 3
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        apiClient: APIClient,
        date: Date = Date(),
        existingLog: MenstrualCycleLog? = nil,
        onSaved: @escaping (MenstrualCycleLog) -> Void
    ) {
        self.apiClient = apiClient
        self.date = date
        self.existingLog = existingLog
        self.onSaved = onSaved

        // Initialize state from existing log
        if let log = existingLog {
            _isPeriodDay = State(initialValue: log.isPeriodDay)
            _flowIntensity = State(initialValue: log.flowIntensityEnum)
            _selectedSymptoms = State(initialValue: Set(log.symptomEnums))
            _mood = State(initialValue: log.mood ?? 3)
            _energyLevel = State(initialValue: log.energyLevel ?? 3)
            _notes = State(initialValue: log.notes ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date display
                    dateHeader

                    // Period toggle
                    periodSection

                    // Flow intensity (if period day)
                    if isPeriodDay {
                        flowSection
                    }

                    // Symptoms
                    symptomsSection

                    // Mood & Energy
                    moodEnergySection

                    // Notes
                    notesSection

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Log Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Sections

    private var dateHeader: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.accentColor)

            Text(date, style: .date)
                .font(.headline)

            Spacer()

            if Calendar.current.isDateInToday(date) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isPeriodDay) {
                HStack(spacing: 12) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.red)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Period Day")
                            .font(.headline)

                        Text("Is today a period day?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.red)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flow Intensity")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(FlowIntensity.allCases, id: \.self) { intensity in
                    Button {
                        flowIntensity = intensity
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: intensity.icon)
                                .font(.title2)

                            Text(intensity.displayName)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            flowIntensity == intensity
                                ? Color.red.opacity(0.2)
                                : Color(.tertiarySystemBackground)
                        )
                        .foregroundColor(
                            flowIntensity == intensity ? .red : .primary
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptoms")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(CycleSymptom.allCases) { symptom in
                    Button {
                        if selectedSymptoms.contains(symptom) {
                            selectedSymptoms.remove(symptom)
                        } else {
                            selectedSymptoms.insert(symptom)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: symptom.icon)
                                .font(.title3)

                            Text(symptom.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedSymptoms.contains(symptom)
                                ? Color.purple.opacity(0.2)
                                : Color(.tertiarySystemBackground)
                        )
                        .foregroundColor(
                            selectedSymptoms.contains(symptom) ? .purple : .primary
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var moodEnergySection: some View {
        VStack(spacing: 16) {
            // Mood
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mood")
                        .font(.headline)

                    Spacer()

                    Text(moodEmoji)
                        .font(.title2)
                }

                HStack {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            mood = level
                        } label: {
                            Circle()
                                .fill(mood >= level ? Color.yellow : Color(.tertiarySystemBackground))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(moodEmojiFor(level))
                                        .font(.title3)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Energy
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Energy Level")
                        .font(.headline)

                    Spacer()

                    Image(systemName: energyIcon)
                        .font(.title2)
                        .foregroundColor(energyColor)
                }

                HStack {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            energyLevel = level
                        } label: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(energyLevel >= level ? energyColorFor(level) : Color(.tertiarySystemBackground))
                                .frame(height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private var moodEmoji: String {
        moodEmojiFor(mood)
    }

    private func moodEmojiFor(_ level: Int) -> String {
        switch level {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }

    private var energyIcon: String {
        switch energyLevel {
        case 1: return "battery.0"
        case 2: return "battery.25"
        case 3: return "battery.50"
        case 4: return "battery.75"
        case 5: return "battery.100"
        default: return "battery.50"
        }
    }

    private var energyColor: Color {
        energyColorFor(energyLevel)
    }

    private func energyColorFor(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .yellow
        }
    }

    // MARK: - Actions

    private func save() async {
        isSaving = true
        errorMessage = nil

        let logData = MenstrualLogCreate(
            date: date,
            isPeriodDay: isPeriodDay,
            flowIntensity: isPeriodDay ? flowIntensity : nil,
            symptoms: Array(selectedSymptoms),
            mood: mood,
            energyLevel: energyLevel,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let savedLog = try await apiClient.logCycleData(logData)
            onSaved(savedLog)
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }

        isSaving = false
    }
}

#Preview {
    CycleLoggerSheet(
        apiClient: DependencyContainer.shared.apiClient,
        date: Date(),
        existingLog: nil,
        onSaved: { _ in }
    )
}
