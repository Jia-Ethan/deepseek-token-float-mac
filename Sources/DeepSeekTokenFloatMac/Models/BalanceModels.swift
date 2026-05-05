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
