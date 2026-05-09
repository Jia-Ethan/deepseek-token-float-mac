import Foundation

enum TimeSpan: String, CaseIterable, Identifiable {
    case today
    case week
    case month
    case thirtyDays
    case all

    var id: String {
        rawValue
    }

    var label: String {
        label(language: .english)
    }

    var accessibilityLabel: String {
        menuLabel(language: .english)
    }

    func label(language: AppLanguage) -> String {
        switch self {
        case .today:
            switch language {
            case .english:
                return "Today"
            case .simplifiedChinese:
                return "今天"
            }
        case .week:
            switch language {
            case .english:
                return "Week"
            case .simplifiedChinese:
                return "本周"
            }
        case .month:
            switch language {
            case .english:
                return "Month"
            case .simplifiedChinese:
                return "本月"
            }
        case .thirtyDays:
            return "30D"
        case .all:
            switch language {
            case .english:
                return "All"
            case .simplifiedChinese:
                return "全部"
            }
        }
    }

    func menuLabel(language: AppLanguage) -> String {
        switch self {
        case .today:
            switch language {
            case .english:
                return "Today"
            case .simplifiedChinese:
                return "今天"
            }
        case .week:
            switch language {
            case .english:
                return "This week"
            case .simplifiedChinese:
                return "本周"
            }
        case .month:
            switch language {
            case .english:
                return "This month"
            case .simplifiedChinese:
                return "本月"
            }
        case .thirtyDays:
            switch language {
            case .english:
                return "Last 30 days"
            case .simplifiedChinese:
                return "最近 30 天"
            }
        case .all:
            switch language {
            case .english:
                return "All local records"
            case .simplifiedChinese:
                return "全部本地记录"
            }
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
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: components)
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .all:
            return nil
        }
    }
}
