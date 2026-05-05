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
}
