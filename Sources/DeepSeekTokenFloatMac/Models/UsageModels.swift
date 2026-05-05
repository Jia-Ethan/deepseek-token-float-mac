import Foundation

struct UsageRecord: Equatable {
    let id: String
    let timestamp: Date
    let provider: String
    let model: String
    let inputTokens: Int64
    let outputTokens: Int64
    let totalTokens: Int64
    let estimatedCost: Double?
    let source: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        timestamp: Date,
        provider: String = "deepseek",
        model: String,
        inputTokens: Int64,
        outputTokens: Int64,
        totalTokens: Int64? = nil,
        estimatedCost: Double?,
        source: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.provider = provider
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens ?? inputTokens + outputTokens
        self.estimatedCost = estimatedCost
        self.source = source
        self.createdAt = createdAt
    }
}

struct UsageSummary: Equatable {
    let inputTokens: Int64
    let outputTokens: Int64
    let totalTokens: Int64
    let estimatedCost: Double?
    let recordCount: Int
    let costRecordCount: Int
    let firstRecordAt: Date?
    let lastRecordAt: Date?

    static let empty = UsageSummary(
        inputTokens: 0,
        outputTokens: 0,
        totalTokens: 0,
        estimatedCost: nil,
        recordCount: 0,
        costRecordCount: 0,
        firstRecordAt: nil,
        lastRecordAt: nil
    )
}
