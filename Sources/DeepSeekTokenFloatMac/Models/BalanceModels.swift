import Foundation

struct DeepSeekBalanceResponse: Codable, Equatable {
    let isAvailable: Bool
    let balanceInfos: [BalanceInfo]

    enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case balanceInfos = "balance_infos"
    }
}

struct BalanceInfo: Codable, Equatable, Identifiable {
    var id: String {
        currency
    }

    let currency: String
    let totalBalance: String
    let grantedBalance: String
    let toppedUpBalance: String

    enum CodingKeys: String, CodingKey {
        case currency
        case totalBalance = "total_balance"
        case grantedBalance = "granted_balance"
        case toppedUpBalance = "topped_up_balance"
    }
}

struct BalanceSnapshot: Equatable {
    let response: DeepSeekBalanceResponse
    let updatedAt: Date
}

enum BalanceStatus: Equatable {
    case idle
    case loading
    case loaded(BalanceSnapshot)
    case failed(String)
}

struct BalanceDisplaySnapshot: Equatable {
    let isAvailable: Bool
    let currency: String
    let totalBalance: Decimal?
    let grantedBalance: Decimal?
    let toppedUpBalance: Decimal?
    let updatedAt: Date

    init(snapshot: BalanceSnapshot) {
        let primary = snapshot.response.balanceInfos.first
        self.isAvailable = snapshot.response.isAvailable
        self.currency = primary?.currency ?? "CNY"
        self.totalBalance = primary.flatMap { Decimal(string: $0.totalBalance) }
        self.grantedBalance = primary.flatMap { Decimal(string: $0.grantedBalance) }
        self.toppedUpBalance = primary.flatMap { Decimal(string: $0.toppedUpBalance) }
        self.updatedAt = snapshot.updatedAt
    }
}
