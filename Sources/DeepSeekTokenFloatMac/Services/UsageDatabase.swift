import Foundation
import SQLite3

enum UsageDatabaseError: LocalizedError {
    case applicationSupportUnavailable
    case openFailed(String)
    case prepareFailed(String)
    case stepFailed(String)

    var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            return "Application Support directory is unavailable."
        case .openFailed(let message):
            return "Could not open the local usage database: \(message)"
        case .prepareFailed(let message):
            return "Could not prepare a local usage database query: \(message)"
        case .stepFailed(let message):
            return "Local usage database operation failed: \(message)"
        }
    }
}

final class UsageDatabase {
    private var database: OpaquePointer?
    private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    let databaseURL: URL

    convenience init(fileManager: FileManager = .default) throws {
        guard let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw UsageDatabaseError.applicationSupportUnavailable
        }

        let directory = applicationSupport.appendingPathComponent(
            "DeepSeekTokenFloatMac",
            isDirectory: true
        )
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        try self.init(databaseURL: directory.appendingPathComponent("usage.sqlite3"))
    }

    init(databaseURL: URL) throws {
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        self.databaseURL = databaseURL

        guard sqlite3_open(databaseURL.path, &database) == SQLITE_OK else {
            throw UsageDatabaseError.openFailed(lastErrorMessage)
        }

        try createSchema()
    }

    deinit {
        sqlite3_close(database)
    }

    func insert(_ records: [UsageRecord]) throws {
        guard !records.isEmpty else {
            return
        }

        try execute("BEGIN TRANSACTION")
        do {
            for record in records {
                try insert(record)
            }
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    func summary(for span: TimeSpan, now: Date = Date()) throws -> UsageSummary {
        let startDate = span.startDate(now: now)
        var sql = """
        SELECT
            COALESCE(SUM(input_tokens), 0),
            COALESCE(SUM(output_tokens), 0),
            COALESCE(SUM(total_tokens), 0),
            SUM(estimated_cost),
            COUNT(*),
            COUNT(estimated_cost),
            MIN(timestamp),
            MAX(timestamp)
        FROM usage_records
        WHERE provider = ?
        """

        if startDate != nil {
            sql += " AND timestamp >= ?"
        }
        sql += " AND timestamp <= ?"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw UsageDatabaseError.prepareFailed(lastErrorMessage)
        }
        defer {
            sqlite3_finalize(statement)
        }

        sqlite3_bind_text(statement, 1, "deepseek", -1, sqliteTransient)
        var bindIndex: Int32 = 2
        if let startDate {
            sqlite3_bind_double(statement, bindIndex, startDate.timeIntervalSince1970)
            bindIndex += 1
        }
        sqlite3_bind_double(statement, bindIndex, now.timeIntervalSince1970)

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw UsageDatabaseError.stepFailed(lastErrorMessage)
        }

        let recordCount = Int(sqlite3_column_int64(statement, 4))
        let costRecordCount = Int(sqlite3_column_int64(statement, 5))
        let estimatedCost: Double?
        if sqlite3_column_type(statement, 3) == SQLITE_NULL {
            estimatedCost = nil
        } else {
            estimatedCost = sqlite3_column_double(statement, 3)
        }

        let firstRecordAt: Date?
        if sqlite3_column_type(statement, 6) == SQLITE_NULL {
            firstRecordAt = nil
        } else {
            firstRecordAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
        }

        let lastRecordAt: Date?
        if sqlite3_column_type(statement, 7) == SQLITE_NULL {
            lastRecordAt = nil
        } else {
            lastRecordAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))
        }

        return UsageSummary(
            inputTokens: sqlite3_column_int64(statement, 0),
            outputTokens: sqlite3_column_int64(statement, 1),
            totalTokens: sqlite3_column_int64(statement, 2),
            estimatedCost: estimatedCost,
            recordCount: recordCount,
            costRecordCount: costRecordCount,
            firstRecordAt: firstRecordAt,
            lastRecordAt: lastRecordAt
        )
    }

    func modelSummaries(for span: TimeSpan, now: Date = Date()) throws -> [ModelUsageSummary] {
        let rows = try groupedRows(
            for: span,
            now: now,
            groupExpression: "model",
            selectPrefix: "model"
        )

        return rows.map { row in
            ModelUsageSummary(
                model: row.groupValue,
                provider: "deepseek",
                inputTokens: row.inputTokens,
                outputTokens: row.outputTokens,
                totalTokens: row.totalTokens,
                estimatedCost: row.estimatedCost,
                requestCount: row.requestCount
            )
        }
    }

    func dailyUsage(for span: TimeSpan, now: Date = Date()) throws -> [DailyUsagePoint] {
        let rows = try groupedRows(
            for: span,
            now: now,
            groupExpression: "date(timestamp, 'unixepoch', 'localtime')",
            selectPrefix: "date(timestamp, 'unixepoch', 'localtime')"
        )

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"

        return rows.compactMap { row in
            guard let date = parser.date(from: row.groupValue) else {
                return nil
            }
            return DailyUsagePoint(
                date: date,
                inputTokens: row.inputTokens,
                outputTokens: row.outputTokens,
                totalTokens: row.totalTokens,
                estimatedCost: row.estimatedCost,
                requestCount: row.requestCount
            )
        }
        .sorted { $0.date < $1.date }
    }

    func deleteAllUsageRecords() throws {
        try execute("DELETE FROM usage_records")
    }

    private func createSchema() throws {
        try execute(
            """
            CREATE TABLE IF NOT EXISTS usage_records (
                id TEXT PRIMARY KEY,
                timestamp REAL NOT NULL,
                provider TEXT NOT NULL,
                model TEXT NOT NULL,
                input_tokens INTEGER NOT NULL,
                output_tokens INTEGER NOT NULL,
                total_tokens INTEGER NOT NULL,
                estimated_cost REAL,
                source TEXT NOT NULL,
                created_at REAL NOT NULL
            )
            """
        )
        try execute(
            """
            CREATE INDEX IF NOT EXISTS idx_usage_records_provider_timestamp
            ON usage_records(provider, timestamp)
            """
        )
        try execute(
            """
            CREATE INDEX IF NOT EXISTS idx_usage_records_provider_model_timestamp
            ON usage_records(provider, model, timestamp)
            """
        )
    }

    private struct GroupedUsageRow {
        let groupValue: String
        let inputTokens: Int64
        let outputTokens: Int64
        let totalTokens: Int64
        let estimatedCost: Double?
        let requestCount: Int
    }

    private func groupedRows(
        for span: TimeSpan,
        now: Date,
        groupExpression: String,
        selectPrefix: String
    ) throws -> [GroupedUsageRow] {
        let startDate = span.startDate(now: now)
        var sql = """
        SELECT
            \(selectPrefix),
            COALESCE(SUM(input_tokens), 0),
            COALESCE(SUM(output_tokens), 0),
            COALESCE(SUM(total_tokens), 0),
            SUM(estimated_cost),
            COUNT(*)
        FROM usage_records
        WHERE provider = ?
        """

        if startDate != nil {
            sql += " AND timestamp >= ?"
        }
        sql += """
         AND timestamp <= ?
        GROUP BY \(groupExpression)
        ORDER BY COALESCE(SUM(total_tokens), 0) DESC
        """

        if groupExpression.contains("date(") {
            sql += ", \(groupExpression) ASC"
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw UsageDatabaseError.prepareFailed(lastErrorMessage)
        }
        defer {
            sqlite3_finalize(statement)
        }

        sqlite3_bind_text(statement, 1, "deepseek", -1, sqliteTransient)
        var bindIndex: Int32 = 2
        if let startDate {
            sqlite3_bind_double(statement, bindIndex, startDate.timeIntervalSince1970)
            bindIndex += 1
        }
        sqlite3_bind_double(statement, bindIndex, now.timeIntervalSince1970)

        var rows: [GroupedUsageRow] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let estimatedCost: Double?
            if sqlite3_column_type(statement, 4) == SQLITE_NULL {
                estimatedCost = nil
            } else {
                estimatedCost = sqlite3_column_double(statement, 4)
            }

            let groupValue = sqlite3_column_text(statement, 0).map {
                String(cString: $0)
            } ?? "unknown"

            rows.append(
                GroupedUsageRow(
                    groupValue: groupValue,
                    inputTokens: sqlite3_column_int64(statement, 1),
                    outputTokens: sqlite3_column_int64(statement, 2),
                    totalTokens: sqlite3_column_int64(statement, 3),
                    estimatedCost: estimatedCost,
                    requestCount: Int(sqlite3_column_int64(statement, 5))
                )
            )
        }

        return rows
    }

    private func insert(_ record: UsageRecord) throws {
        let sql = """
        INSERT OR REPLACE INTO usage_records (
            id,
            timestamp,
            provider,
            model,
            input_tokens,
            output_tokens,
            total_tokens,
            estimated_cost,
            source,
            created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw UsageDatabaseError.prepareFailed(lastErrorMessage)
        }
        defer {
            sqlite3_finalize(statement)
        }

        sqlite3_bind_text(statement, 1, record.id, -1, sqliteTransient)
        sqlite3_bind_double(statement, 2, record.timestamp.timeIntervalSince1970)
        sqlite3_bind_text(statement, 3, record.provider, -1, sqliteTransient)
        sqlite3_bind_text(statement, 4, record.model, -1, sqliteTransient)
        sqlite3_bind_int64(statement, 5, record.inputTokens)
        sqlite3_bind_int64(statement, 6, record.outputTokens)
        sqlite3_bind_int64(statement, 7, record.totalTokens)
        if let estimatedCost = record.estimatedCost {
            sqlite3_bind_double(statement, 8, estimatedCost)
        } else {
            sqlite3_bind_null(statement, 8)
        }
        sqlite3_bind_text(statement, 9, record.source, -1, sqliteTransient)
        sqlite3_bind_double(statement, 10, record.createdAt.timeIntervalSince1970)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw UsageDatabaseError.stepFailed(lastErrorMessage)
        }
    }

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<Int8>?
        let status = sqlite3_exec(database, sql, nil, nil, &errorMessage)
        if status != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? lastErrorMessage
            sqlite3_free(errorMessage)
            throw UsageDatabaseError.stepFailed(message)
        }
    }

    private var lastErrorMessage: String {
        if let database {
            return String(cString: sqlite3_errmsg(database))
        }
        return "Unknown SQLite error"
    }
}
