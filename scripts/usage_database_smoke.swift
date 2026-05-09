import Foundation
import SQLite3

@main
struct UsageDatabaseSmoke {
    static func main() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let databaseURL = tempDirectory.appendingPathComponent("usage.sqlite3")
        let database = try UsageDatabase(databaseURL: databaseURL)

        try database.insert([
            UsageRecord(
                id: "request-1",
                timestamp: fixtureDate("2026-05-01T09:00:00Z"),
                model: "deepseek-chat",
                inputTokens: 1_000,
                outputTokens: 500,
                estimatedCost: 0.0012,
                source: "smoke"
            ),
            UsageRecord(
                id: "request-2",
                timestamp: fixtureDate("2026-05-01T13:00:00Z"),
                model: "deepseek-reasoner",
                inputTokens: 2_000,
                outputTokens: 1_500,
                estimatedCost: 0.0040,
                source: "smoke"
            ),
            UsageRecord(
                id: "request-3",
                timestamp: fixtureDate("2026-05-02T11:00:00Z"),
                model: "deepseek-chat",
                inputTokens: 700,
                outputTokens: 300,
                estimatedCost: 0.0008,
                source: "smoke"
            ),
            UsageRecord(
                id: "old-request",
                timestamp: fixtureDate("2026-04-30T12:00:00Z"),
                model: "deepseek-chat",
                inputTokens: 9_000,
                outputTokens: 9_000,
                estimatedCost: 9,
                source: "smoke"
            )
        ])

        let now = fixtureDate("2026-05-10T12:00:00Z")
        let summary = try database.summary(for: .month, now: now)
        check(summary.recordCount == 3, "monthly request count")
        check(summary.inputTokens == 3_700, "monthly input tokens")
        check(summary.outputTokens == 2_300, "monthly output tokens")
        check(summary.totalTokens == 6_000, "monthly total tokens")
        check(abs((summary.estimatedCost ?? 0) - 0.006) < 0.000_001, "monthly estimated cost")

        let modelSummaries = try database.modelSummaries(for: .month, now: now)
        check(modelSummaries.map(\.model) == ["deepseek-reasoner", "deepseek-chat"], "model order")
        check(modelSummaries.map(\.requestCount) == [1, 2], "model request counts")
        check(modelSummaries.map(\.totalTokens) == [3_500, 2_500], "model total tokens")

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dayFormatter.dateFormat = "yyyy-MM-dd"
        let dailyUsage = try database.dailyUsage(for: .month, now: now)
        check(dailyUsage.map { dayFormatter.string(from: $0.date) } == ["2026-05-01", "2026-05-02"], "daily dates")
        check(dailyUsage.map(\.requestCount) == [2, 1], "daily request counts")
        check(dailyUsage.map(\.totalTokens) == [5_000, 1_000], "daily total tokens")

        print("usage_database_smoke: ok")
    }

    private static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fputs("FAIL: \(message)\n", stderr)
            exit(1)
        }
    }

    private static func fixtureDate(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: value) else {
            fputs("FAIL: invalid fixture date \(value)\n", stderr)
            exit(1)
        }
        return date
    }
}
