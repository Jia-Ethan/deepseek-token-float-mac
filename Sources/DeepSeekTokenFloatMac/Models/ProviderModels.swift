import Foundation

enum ProviderID: String, CaseIterable, Identifiable {
    case deepseek
    case kimi
    case openAI
    case claude

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .deepseek:
            return "DeepSeek"
        case .kimi:
            return "Kimi"
        case .openAI:
            return "OpenAI"
        case .claude:
            return "Claude"
        }
    }

    var isEnabledInCurrentPhase: Bool {
        self == .deepseek
    }
}

struct ProviderCapability: Equatable, Identifiable {
    let id: ProviderID
    let supportsBalance: Bool
    let supportsOfficialUsageAggregation: Bool
    let supportsLocalUsageAggregation: Bool

    static let current: [ProviderCapability] = [
        ProviderCapability(
            id: .deepseek,
            supportsBalance: true,
            supportsOfficialUsageAggregation: false,
            supportsLocalUsageAggregation: true
        ),
        ProviderCapability(
            id: .kimi,
            supportsBalance: false,
            supportsOfficialUsageAggregation: false,
            supportsLocalUsageAggregation: false
        ),
        ProviderCapability(
            id: .openAI,
            supportsBalance: false,
            supportsOfficialUsageAggregation: false,
            supportsLocalUsageAggregation: false
        ),
        ProviderCapability(
            id: .claude,
            supportsBalance: false,
            supportsOfficialUsageAggregation: false,
            supportsLocalUsageAggregation: false
        )
    ]
}
