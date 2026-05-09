import Foundation

enum DisplayFormatters {
    static func tokens(_ value: Int64) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func cost(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }
        return "Est. " + currencyFormatter.string(from: NSNumber(value: value))!
    }

    static func compactTokens(_ value: Int64) -> String {
        compact(Double(value), suffixes: ["", "K", "M", "B"])
    }

    static func compactNumber(_ value: Int) -> String {
        compact(Double(value), suffixes: ["", "K", "M", "B"])
    }

    static func balance(_ value: Decimal?, currency: String) -> String {
        guard let value else {
            return "0"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0

        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    static func timestamp(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 4
        return formatter
    }()

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static func compact(_ value: Double, suffixes: [String]) -> String {
        var current = value
        var suffixIndex = 0
        while abs(current) >= 1_000, suffixIndex < suffixes.count - 1 {
            current /= 1_000
            suffixIndex += 1
        }

        if suffixIndex == 0 {
            return integerFormatter.string(from: NSNumber(value: Int(current))) ?? "\(Int(current))"
        }
        if current >= 100 {
            return String(format: "%.0f%@", current, suffixes[suffixIndex])
        }
        return String(format: "%.1f%@", current, suffixes[suffixIndex])
    }
}
