import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct DailySummaryEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct DailySummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailySummaryEntry {
        DailySummaryEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailySummaryEntry) -> Void) {
        let data = WidgetDataManager.shared.load() ?? .placeholder
        completion(DailySummaryEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailySummaryEntry>) -> Void) {
        let data = WidgetDataManager.shared.load() ?? .placeholder
        let entry = DailySummaryEntry(date: Date(), data: data)

        // For fasting, update more frequently
        let refreshMinutes = data.isFasting ? 1 : 15
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: refreshMinutes, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct DailySummaryWidgetEntryView: View {
    var entry: DailySummaryEntry

    var body: some View {
        LargeDailySummaryView(data: entry.data)
    }
}

// MARK: - Large Daily Summary View

struct LargeDailySummaryView: View {
    let data: WidgetData

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Progress")
                        .font(.headline)
                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(data.currentStreak)")
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
            }

            Divider()

            // Main content
            HStack(spacing: 16) {
                // Left: Calories Ring
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)

                        Circle()
                            .trim(from: 0, to: min(data.caloriesProgress, 1.0))
                            .stroke(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(data.caloriesConsumed)")
                                .font(.title2.bold())
                            Text("/ \(data.caloriesTarget)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 100, height: 100)

                    Text("Calories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Right: Stats grid
                VStack(spacing: 12) {
                    // Macros row
                    HStack(spacing: 12) {
                        StatTile(
                            icon: "p.circle.fill",
                            value: "\(Int(data.proteinConsumed))g",
                            label: "Protein",
                            progress: data.proteinProgress,
                            color: .red
                        )
                        StatTile(
                            icon: "c.circle.fill",
                            value: "\(Int(data.carbsConsumed))g",
                            label: "Carbs",
                            progress: data.carbsProgress,
                            color: .blue
                        )
                        StatTile(
                            icon: "f.circle.fill",
                            value: "\(Int(data.fatConsumed))g",
                            label: "Fat",
                            progress: data.fatProgress,
                            color: .yellow
                        )
                    }

                    // Water & Steps row
                    HStack(spacing: 12) {
                        StatTile(
                            icon: "drop.fill",
                            value: "\(data.waterConsumedMl)ml",
                            label: "Water",
                            progress: data.waterProgress,
                            color: .cyan
                        )
                        StatTile(
                            icon: "figure.walk",
                            value: "\(data.stepsToday)",
                            label: "Steps",
                            progress: data.stepsProgress,
                            color: .green
                        )
                    }
                }
            }

            // Fasting section (if active)
            if data.isFasting {
                Divider()

                FastingSection(data: data)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Fasting Section

struct FastingSection: View {
    let data: WidgetData

    private var formattedRemaining: String {
        guard let remaining = data.fastingTimeRemaining else { return "0:00" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    var body: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Fasting: \(data.fastingProtocol ?? "Active")")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(formattedRemaining) remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: data.fastingProgress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(data.fastingProgress * 100))%")
                    .font(.system(size: 8, weight: .bold))
            }
            .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Widget Configuration

struct DailySummaryWidget: Widget {
    let kind: String = "DailySummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailySummaryProvider()) { entry in
            DailySummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Summary")
        .description("Complete overview of your daily nutrition and activity")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    DailySummaryWidget()
} timeline: {
    DailySummaryEntry(date: .now, data: WidgetData(
        caloriesConsumed: 1200,
        caloriesTarget: 2000,
        proteinConsumed: 80,
        proteinTarget: 150,
        carbsConsumed: 120,
        carbsTarget: 200,
        fatConsumed: 40,
        fatTarget: 65,
        waterConsumedMl: 1500,
        waterTargetMl: 2500,
        currentStreak: 7,
        stepsToday: 6500,
        stepsGoal: 10000,
        isFasting: true,
        fastingProtocol: "16:8",
        fastingStartedAt: Date().addingTimeInterval(-6 * 3600),
        fastingTargetEndAt: Date().addingTimeInterval(10 * 3600),
        lastUpdated: Date()
    ))
}
