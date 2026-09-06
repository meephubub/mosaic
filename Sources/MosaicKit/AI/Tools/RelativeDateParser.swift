import Foundation

/// Parses human date phrases like "today", "tomorrow", "in 3 days",
/// "next monday", or weekday names into concrete dates.
enum RelativeDateParser {
    static func parse(_ text: String?) -> Date? {
        guard let text, !text.isEmpty else { return nil }
        let lowered = text.lowercased().trimmingCharacters(in: .whitespaces)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        switch lowered {
        case "today", "tonight", "now":
            return today
        case "tomorrow", "tmr":
            return calendar.date(byAdding: .day, value: 1, to: today)
        case "yesterday":
            return calendar.date(byAdding: .day, value: -1, to: today)
        case "next week":
            return calendar.date(byAdding: .day, value: 7, to: today)
        default:
            break
        }

        let relativeParts = lowered.split(whereSeparator: { $0.isWhitespace })
        if relativeParts.count >= 3,
           relativeParts[0] == "in",
           let count = Int(relativeParts[1]),
           count > 0 {
            let unit = relativeParts[2]
            if unit.hasPrefix("day") {
                return calendar.date(byAdding: .day, value: count, to: today)
            }
            if unit.hasPrefix("week") {
                return calendar.date(byAdding: .day, value: count * 7, to: today)
            }
        }

        if lowered.hasPrefix("next ") {
            let weekdayName = String(lowered.dropFirst(5))
            if let weekday = weekdayIndex(weekdayName) {
                return nextWeekday(weekday, from: today, forceNextWeek: true)
            }
        }

        if let weekday = weekdayIndex(lowered) {
            return nextWeekday(weekday, from: today, forceNextWeek: false)
        }

        return nil
    }

    private static func weekdayIndex(_ name: String) -> Int? {
        let weekdays = [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7
        ]
        for (day, index) in weekdays where name.hasPrefix(day) {
            return index
        }
        return nil
    }

    private static func nextWeekday(_ weekday: Int, from today: Date, forceNextWeek: Bool) -> Date? {
        let calendar = Calendar.current
        var days = (weekday - calendar.component(.weekday, from: today) + 7) % 7
        if days == 0 { days = 7 }
        if forceNextWeek && days < 7 { days += 7 }
        return calendar.date(byAdding: .day, value: days, to: today)
    }
}
