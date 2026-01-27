import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct MacrosEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct MacrosProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacrosEntry {
        MacrosEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MacrosEntry) -> Void) {
        let data = WidgetDataManager.shared.load() ?? .placeholder
        completion(MacrosEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacrosEntry>) -> Void) {
        let data = WidgetDataManager.shared.load() ?? .placeholder
        let entry = MacrosEntry(date: Date(), data: data)

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct MacrosWidgetEntryView: View {
    var entry: MacrosEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        MediumMacrosView(data: entry.data)
    }
}

// MARK: - Medium Macros View

struct MediumMacrosView: View {
    let data: WidgetData

    var body: some View {
        HStack(spacing: 16) {
            // Left: Calories ring
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: min(data.caloriesProgress, 1.0))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(data.caloriesRemaining)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("cal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80, height: 80)

                Text("remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Right: Macros + extras
            VStack(alignment: .leading, spacing: 8) {
                // Macros
                MacroRow(name: "Protein", value: Int(data.proteinConsumed), target: Int(data.proteinTarget), color: .red)
                MacroRow(name: "Carbs", value: Int(data.carbsConsumed), target: Int(data.carbsTarget), color: .blue)
                MacroRow(name: "Fat", value: Int(data.fatConsumed), target: Int(data.fatTarget), color: .yellow)

                Divider()

                // Bottom row: Streak + Water
                HStack(spacing: 16) {
                    // Streak
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(data.currentStreak)")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)

                    // Water
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.blue)
                        Text("\(data.waterConsumedMl / 1000).\((data.waterConsumedMl % 1000) / 100)L")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)

                    Spacer()
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Macro Row

struct MacroRow: View {
    let name: String
    let value: Int
    let target: Int
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(value) / Double(target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)/\(target)g")
                    .font(.caption2)
                    .fontWeight(.medium)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Widget Configuration

struct MacrosWidget: Widget {
    let kind: String = "MacrosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacrosProvider()) { entry in
            MacrosWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Macros")
        .description("Track your macros, streak, and water intake")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    MacrosWidget()
} timeline: {
    MacrosEntry(date: .now, data: .placeholder)
}
