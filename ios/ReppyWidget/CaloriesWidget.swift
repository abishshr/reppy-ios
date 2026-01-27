import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct CaloriesEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct CaloriesProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaloriesEntry {
        CaloriesEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CaloriesEntry) -> Void) {
        let data = WidgetDataManager.shared.load() ?? .placeholder
        completion(CaloriesEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CaloriesEntry>) -> Void) {
        let data = WidgetDataManager.shared.load() ?? .placeholder
        let entry = CaloriesEntry(date: Date(), data: data)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct CaloriesWidgetEntryView: View {
    var entry: CaloriesEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCaloriesView(data: entry.data)
        default:
            SmallCaloriesView(data: entry.data)
        }
    }
}

// MARK: - Small Calories View

struct SmallCaloriesView: View {
    let data: WidgetData

    private var progressColor: Color {
        if data.caloriesProgress >= 1.0 {
            return .red
        } else if data.caloriesProgress >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black.opacity(0.1), Color.black.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 4) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: min(data.caloriesProgress, 1.0))
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: data.caloriesProgress)

                    VStack(spacing: 0) {
                        Text("\(data.caloriesRemaining)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.5)

                        Text("cal left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)

                // Label
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Reppy")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct CaloriesWidget: Widget {
    let kind: String = "CaloriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaloriesProvider()) { entry in
            CaloriesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calories")
        .description("Track your remaining calories for the day")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    CaloriesWidget()
} timeline: {
    CaloriesEntry(date: .now, data: .placeholder)
}
