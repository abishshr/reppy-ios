import SwiftUI

/// Muscle heat map showing workout intensity by muscle group
struct MuscleHeatMapView: View {
    let muscleData: [MuscleGroup: Double] // 0.0 - 1.0 intensity
    @State private var selectedMuscle: MuscleGroup?
    @State private var showingFront = true

    init(muscleData: [MuscleGroup: Double] = [:]) {
        self.muscleData = muscleData
    }

    var body: some View {
        VStack(spacing: 20) {
            // View Toggle
            Picker("View", selection: $showingFront) {
                Text("Front").tag(true)
                Text("Back").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Body Diagram
            ZStack {
                if showingFront {
                    FrontBodyView(
                        muscleData: muscleData,
                        selectedMuscle: $selectedMuscle
                    )
                } else {
                    BackBodyView(
                        muscleData: muscleData,
                        selectedMuscle: $selectedMuscle
                    )
                }
            }
            .frame(height: 400)
            .animation(.easeInOut, value: showingFront)

            // Selected Muscle Info
            if let muscle = selectedMuscle {
                MuscleInfoCard(
                    muscle: muscle,
                    intensity: muscleData[muscle] ?? 0
                )
                .padding(.horizontal)
            }

            // Legend
            HeatMapLegend()
                .padding(.horizontal)

            // Muscle List
            MuscleIntensityList(muscleData: muscleData)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - Muscle Group Enum

enum MuscleGroup: String, CaseIterable, Identifiable {
    // Front muscles
    case chest = "Chest"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case forearms = "Forearms"
    case abs = "Abs"
    case obliques = "Obliques"
    case quads = "Quadriceps"

    // Back muscles
    case traps = "Traps"
    case lats = "Lats"
    case upperBack = "Upper Back"
    case lowerBack = "Lower Back"
    case triceps = "Triceps"
    case glutes = "Glutes"
    case hamstrings = "Hamstrings"
    case calves = "Calves"

    var id: String { rawValue }

    var isFrontMuscle: Bool {
        switch self {
        case .chest, .shoulders, .biceps, .forearms, .abs, .obliques, .quads:
            return true
        default:
            return false
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .shoulders: return "figure.boxing"
        case .biceps: return "figure.strengthtraining.functional"
        case .forearms: return "hand.raised.fill"
        case .abs: return "figure.core.training"
        case .obliques: return "figure.flexibility"
        case .quads: return "figure.walk"
        case .traps: return "figure.roll"
        case .lats: return "figure.climbing"
        case .upperBack: return "figure.rowing"
        case .lowerBack: return "figure.strengthtraining.traditional"
        case .triceps: return "figure.arms.open"
        case .glutes: return "figure.run"
        case .hamstrings: return "figure.cooldown"
        case .calves: return "figure.step.training"
        }
    }

    static var frontMuscles: [MuscleGroup] {
        allCases.filter { $0.isFrontMuscle }
    }

    static var backMuscles: [MuscleGroup] {
        allCases.filter { !$0.isFrontMuscle }
    }
}

// MARK: - Front Body View

struct FrontBodyView: View {
    let muscleData: [MuscleGroup: Double]
    @Binding var selectedMuscle: MuscleGroup?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Body outline
                BodyOutlineFront()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)

                // Muscle regions (tappable)
                // Chest
                MuscleRegion(
                    path: chestPath(in: geo.size),
                    muscle: .chest,
                    intensity: muscleData[.chest] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Shoulders
                MuscleRegion(
                    path: shoulderLeftPath(in: geo.size),
                    muscle: .shoulders,
                    intensity: muscleData[.shoulders] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
                MuscleRegion(
                    path: shoulderRightPath(in: geo.size),
                    muscle: .shoulders,
                    intensity: muscleData[.shoulders] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Biceps
                MuscleRegion(
                    path: bicepLeftPath(in: geo.size),
                    muscle: .biceps,
                    intensity: muscleData[.biceps] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
                MuscleRegion(
                    path: bicepRightPath(in: geo.size),
                    muscle: .biceps,
                    intensity: muscleData[.biceps] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Abs
                MuscleRegion(
                    path: absPath(in: geo.size),
                    muscle: .abs,
                    intensity: muscleData[.abs] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Quads
                MuscleRegion(
                    path: quadLeftPath(in: geo.size),
                    muscle: .quads,
                    intensity: muscleData[.quads] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
                MuscleRegion(
                    path: quadRightPath(in: geo.size),
                    muscle: .quads,
                    intensity: muscleData[.quads] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
            }
        }
    }

    // Path generators for front muscles
    private func chestPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.32, y: h * 0.18,
                width: w * 0.36, height: h * 0.12
            ))
        }
    }

    private func shoulderLeftPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.22, y: h * 0.16,
                width: w * 0.12, height: h * 0.08
            ))
        }
    }

    private func shoulderRightPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.66, y: h * 0.16,
                width: w * 0.12, height: h * 0.08
            ))
        }
    }

    private func bicepLeftPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.18, y: h * 0.24,
                width: w * 0.08, height: h * 0.10
            ))
        }
    }

    private func bicepRightPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.74, y: h * 0.24,
                width: w * 0.08, height: h * 0.10
            ))
        }
    }

    private func absPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addRoundedRect(
                in: CGRect(x: w * 0.40, y: h * 0.30, width: w * 0.20, height: h * 0.18),
                cornerSize: CGSize(width: 8, height: 8)
            )
        }
    }

    private func quadLeftPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.32, y: h * 0.52,
                width: w * 0.14, height: h * 0.18
            ))
        }
    }

    private func quadRightPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.54, y: h * 0.52,
                width: w * 0.14, height: h * 0.18
            ))
        }
    }
}

// MARK: - Back Body View

struct BackBodyView: View {
    let muscleData: [MuscleGroup: Double]
    @Binding var selectedMuscle: MuscleGroup?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Body outline
                BodyOutlineBack()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)

                // Traps
                MuscleRegion(
                    path: trapsPath(in: geo.size),
                    muscle: .traps,
                    intensity: muscleData[.traps] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Lats
                MuscleRegion(
                    path: latLeftPath(in: geo.size),
                    muscle: .lats,
                    intensity: muscleData[.lats] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
                MuscleRegion(
                    path: latRightPath(in: geo.size),
                    muscle: .lats,
                    intensity: muscleData[.lats] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Triceps
                MuscleRegion(
                    path: tricepLeftPath(in: geo.size),
                    muscle: .triceps,
                    intensity: muscleData[.triceps] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
                MuscleRegion(
                    path: tricepRightPath(in: geo.size),
                    muscle: .triceps,
                    intensity: muscleData[.triceps] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Lower Back
                MuscleRegion(
                    path: lowerBackPath(in: geo.size),
                    muscle: .lowerBack,
                    intensity: muscleData[.lowerBack] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Glutes
                MuscleRegion(
                    path: glutesPath(in: geo.size),
                    muscle: .glutes,
                    intensity: muscleData[.glutes] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Hamstrings
                MuscleRegion(
                    path: hamstringLeftPath(in: geo.size),
                    muscle: .hamstrings,
                    intensity: muscleData[.hamstrings] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
                MuscleRegion(
                    path: hamstringRightPath(in: geo.size),
                    muscle: .hamstrings,
                    intensity: muscleData[.hamstrings] ?? 0,
                    selectedMuscle: $selectedMuscle
                )

                // Calves
                MuscleRegion(
                    path: calfLeftPath(in: geo.size),
                    muscle: .calves,
                    intensity: muscleData[.calves] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
                MuscleRegion(
                    path: calfRightPath(in: geo.size),
                    muscle: .calves,
                    intensity: muscleData[.calves] ?? 0,
                    selectedMuscle: $selectedMuscle
                )
            }
        }
    }

    // Path generators for back muscles
    private func trapsPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.38, y: h * 0.12,
                width: w * 0.24, height: h * 0.10
            ))
        }
    }

    private func latLeftPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.28, y: h * 0.22,
                width: w * 0.14, height: h * 0.16
            ))
        }
    }

    private func latRightPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.58, y: h * 0.22,
                width: w * 0.14, height: h * 0.16
            ))
        }
    }

    private func tricepLeftPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.18, y: h * 0.24,
                width: w * 0.08, height: h * 0.10
            ))
        }
    }

    private func tricepRightPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.74, y: h * 0.24,
                width: w * 0.08, height: h * 0.10
            ))
        }
    }

    private func lowerBackPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addRoundedRect(
                in: CGRect(x: w * 0.40, y: h * 0.36, width: w * 0.20, height: h * 0.10),
                cornerSize: CGSize(width: 8, height: 8)
            )
        }
    }

    private func glutesPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.32, y: h * 0.46,
                width: w * 0.36, height: h * 0.10
            ))
        }
    }

    private func hamstringLeftPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.32, y: h * 0.56,
                width: w * 0.14, height: h * 0.16
            ))
        }
    }

    private func hamstringRightPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.54, y: h * 0.56,
                width: w * 0.14, height: h * 0.16
            ))
        }
    }

    private func calfLeftPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.34, y: h * 0.74,
                width: w * 0.10, height: h * 0.12
            ))
        }
    }

    private func calfRightPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height
            path.addEllipse(in: CGRect(
                x: w * 0.56, y: h * 0.74,
                width: w * 0.10, height: h * 0.12
            ))
        }
    }
}

// MARK: - Muscle Region

struct MuscleRegion: View {
    let path: Path
    let muscle: MuscleGroup
    let intensity: Double
    @Binding var selectedMuscle: MuscleGroup?

    var isSelected: Bool {
        selectedMuscle == muscle
    }

    var body: some View {
        path
            .fill(intensityColor)
            .overlay(
                path.stroke(
                    isSelected ? Color.white : Color.clear,
                    lineWidth: 3
                )
            )
            .contentShape(path)
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    if selectedMuscle == muscle {
                        selectedMuscle = nil
                    } else {
                        selectedMuscle = muscle
                    }
                }
            }
    }

    var intensityColor: Color {
        if intensity == 0 {
            return Color.gray.opacity(0.2)
        }

        // Gradient from green (low) -> yellow -> orange -> red (high)
        let hue = 0.33 - (intensity * 0.33) // 0.33 = green, 0 = red
        return Color(hue: max(0, hue), saturation: 0.8, brightness: 0.9)
            .opacity(0.4 + intensity * 0.5)
    }
}

// MARK: - Body Outlines

struct BodyOutlineFront: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Head
        path.addEllipse(in: CGRect(x: w * 0.42, y: h * 0.02, width: w * 0.16, height: h * 0.10))

        // Neck
        path.move(to: CGPoint(x: w * 0.46, y: h * 0.12))
        path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.15))
        path.move(to: CGPoint(x: w * 0.54, y: h * 0.12))
        path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.15))

        // Torso
        path.move(to: CGPoint(x: w * 0.30, y: h * 0.16))
        path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.50),
                          control: CGPoint(x: w * 0.28, y: h * 0.35))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.50))
        path.addQuadCurve(to: CGPoint(x: w * 0.70, y: h * 0.16),
                          control: CGPoint(x: w * 0.72, y: h * 0.35))
        path.addLine(to: CGPoint(x: w * 0.30, y: h * 0.16))

        // Arms
        path.move(to: CGPoint(x: w * 0.30, y: h * 0.16))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.40))
        path.move(to: CGPoint(x: w * 0.70, y: h * 0.16))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.40))

        // Legs
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.50))
        path.addLine(to: CGPoint(x: w * 0.32, y: h * 0.90))
        path.move(to: CGPoint(x: w * 0.65, y: h * 0.50))
        path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.90))

        return path
    }
}

struct BodyOutlineBack: Shape {
    func path(in rect: CGRect) -> Path {
        // Same as front for simplicity
        BodyOutlineFront().path(in: rect)
    }
}

// MARK: - Heat Map Legend

struct HeatMapLegend: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Low")
                .font(.caption2)
                .foregroundColor(.secondary)

            LinearGradient(
                colors: [.green, .yellow, .orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 12)
            .cornerRadius(6)

            Text("High")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Muscle Info Card

struct MuscleInfoCard: View {
    let muscle: MuscleGroup
    let intensity: Double

    var intensityLabel: String {
        switch intensity {
        case 0: return "Not worked"
        case 0..<0.3: return "Lightly worked"
        case 0.3..<0.6: return "Moderately worked"
        case 0.6..<0.8: return "Well worked"
        default: return "Heavily worked"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: muscle.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(muscle.rawValue)
                    .font(.headline)

                Text(intensityLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Intensity percentage
            Text("\(Int(intensity * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(intensity > 0.6 ? .orange : .blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Muscle Intensity List

struct MuscleIntensityList: View {
    let muscleData: [MuscleGroup: Double]

    var sortedMuscles: [(MuscleGroup, Double)] {
        muscleData.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Breakdown")
                .font(.headline)

            if muscleData.isEmpty {
                Text("No muscle data available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedMuscles, id: \.0) { muscle, intensity in
                        HStack {
                            Text(muscle.rawValue)
                                .font(.subheadline)

                            Spacer()

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))

                                    Capsule()
                                        .fill(intensityGradient(for: intensity))
                                        .frame(width: geo.size.width * intensity)
                                }
                            }
                            .frame(width: 100, height: 8)

                            Text("\(Int(intensity * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func intensityGradient(for value: Double) -> LinearGradient {
        let color: Color = {
            switch value {
            case 0..<0.3: return .green
            case 0.3..<0.6: return .yellow
            case 0.6..<0.8: return .orange
            default: return .red
            }
        }()

        return LinearGradient(
            colors: [color.opacity(0.6), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MuscleHeatMapView(
            muscleData: [
                .chest: 0.9,
                .shoulders: 0.7,
                .triceps: 0.8,
                .biceps: 0.3,
                .abs: 0.4,
                .quads: 0.2,
                .lats: 0.6,
                .traps: 0.5
            ]
        )
    }
    .background(Color(.systemGroupedBackground))
}
