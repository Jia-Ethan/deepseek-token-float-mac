import Foundation

enum TimeSpan: String, CaseIterable, Identifiable {
    case today
    case week
    case thirtyDays
    case all

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .today:
            return "Today"
        case .week:
            return "Week"
        case .thirtyDays:
            return "30D"
        case .all:
            return "All"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .today:
            return "Today"
        case .week:
            return "This week"
        case .thirtyDays:
            return "Last 30 days"
        case .all:
            return "All local records"
        }
    }

    func startDate(now: Date = Date(), calendar baseCalendar: Calendar = .current) -> Date? {
        var calendar = baseCalendar
        calendar.firstWeekday = 2
        calendar.timeZone = .current

        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .week:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            return calendar.date(from: components)
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .all:
            return nil
        }
    }
}
