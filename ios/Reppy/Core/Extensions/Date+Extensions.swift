import Foundation

// MARK: - Cached Formatters (expensive to create)

private enum DateFormatters {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    static let iso8601Formatter = ISO8601DateFormatter()
}

extension Date {
    /// Start of the day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Format as relative time (e.g., "2 hours ago")
    var relativeTime: String {
        DateFormatters.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }

    /// Format as time only (e.g., "2:30 PM")
    var timeString: String {
        DateFormatters.timeFormatter.string(from: self)
    }

    /// Format as date only (e.g., "Dec 25")
    var shortDateString: String {
        DateFormatters.shortDateFormatter.string(from: self)
    }

    /// ISO8601 string for API
    var iso8601String: String {
        DateFormatters.iso8601Formatter.string(from: self)
    }
}
