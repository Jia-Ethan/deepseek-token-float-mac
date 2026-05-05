import Foundation

enum UsageCSVImporterError: LocalizedError {
    case emptyFile
    case missingRequiredColumns
    case noValidRows

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The selected CSV file is empty."
        case .missingRequiredColumns:
            return "CSV must include timestamp plus input/output token columns."
        case .noValidRows:
            return "No valid usage rows were found in the CSV file."
        }
    }
}

struct UsageCSVImporter {
    func records(from url: URL) throws -> [UsageRecord] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = parseCSV(content)
            .filter { row in
                row.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }

        guard let header = rows.first else {
            throw UsageCSVImporterError.emptyFile
        }

        let normalizedHeader = header.map { normalize($0) }
        let bodyRows = rows.dropFirst()

        guard
            index(in: normalizedHeader, for: ["timestamp", "created", "created_at", "date"]) != nil,
            index(in: normalizedHeader, for: ["input_tokens", "prompt_tokens"]) != nil,
            index(in: normalizedHeader, for: ["output_tokens", "completion_tokens"]) != nil
        else {
            throw UsageCSVImporterError.missingRequiredColumns
        }

        let records = bodyRows.compactMap { row -> UsageRecord? in
            record(from: row, header: normalizedHeader)
        }

        guard !records.isEmpty else {
            throw UsageCSVImporterError.noValidRows
        }

        return records
    }

    private func record(from row: [String], header: [String]) -> UsageRecord? {
        guard
            let timestampValue = value(in: row, header: header, keys: ["timestamp", "created", "created_at", "date"]),
            let timestamp = parseDate(timestampValue),
            let inputValue = value(in: row, header: header, keys: ["input_tokens", "prompt_tokens"]),
            let outputValue = value(in: row, header: header, keys: ["output_tokens", "completion_tokens"]),
            let inputTokens = Int64(inputValue.trimmingCharacters(in: .whitespacesAndNewlines)),
            let outputTokens = Int64(outputValue.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return nil
        }

        let totalTokens = value(in: row, header: header, keys: ["total_tokens"])
            .flatMap { Int64($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let estimatedCost = value(in: row, header: header, keys: ["estimated_cost", "cost", "amount"])
            .flatMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let provider = value(in: row, header: header, keys: ["provider"]) ?? "deepseek"
        let model = value(in: row, header: header, keys: ["model"]) ?? "unknown"
        let source = value(in: row, header: header, keys: ["source"]) ?? "manual_csv_import"
        let id = value(in: row, header: header, keys: ["id"]) ?? UUID().uuidString

        return UsageRecord(
            id: id,
            timestamp: timestamp,
            provider: provider.isEmpty ? "deepseek" : provider,
            model: model.isEmpty ? "unknown" : model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            totalTokens: totalTokens,
            estimatedCost: estimatedCost,
            source: source.isEmpty ? "manual_csv_import" : source
        )
    }

    private func parseCSV(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false
        var iterator = content.makeIterator()

        while let character = iterator.next() {
            if character == "\"" {
                if insideQuotes, let next = iterator.next() {
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        insideQuotes = false
                        if next == "," {
                            row.append(field)
                            field = ""
                        } else if next == "\n" {
                            row.append(field)
                            rows.append(row)
                            row = []
                            field = ""
                        } else if next != "\r" {
                            field.append(next)
                        }
                    }
                } else {
                    insideQuotes.toggle()
                }
            } else if character == ",", !insideQuotes {
                row.append(field)
                field = ""
            } else if character == "\n", !insideQuotes {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else if character != "\r" {
                field.append(character)
            }
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    private func parseDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let seconds = Double(trimmed) {
            return Date(timeIntervalSince1970: seconds)
        }

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: trimmed) {
            return date
        }

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        if let date = standard.date(from: trimmed) {
            return date
        }

        let dateOnly = DateFormatter()
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.timeZone = .current
        dateOnly.dateFormat = "yyyy-MM-dd"
        return dateOnly.date(from: trimmed)
    }

    private func value(in row: [String], header: [String], keys: [String]) -> String? {
        guard let fieldIndex = index(in: header, for: keys), fieldIndex < row.count else {
            return nil
        }
        return row[fieldIndex].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func index(in header: [String], for keys: [String]) -> Int? {
        let normalizedKeys = keys.map(normalize)
        return header.firstIndex { normalizedKeys.contains($0) }
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}
