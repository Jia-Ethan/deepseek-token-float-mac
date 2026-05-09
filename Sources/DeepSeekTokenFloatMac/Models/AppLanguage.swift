import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }

    static func saved(defaults: UserDefaults = .standard) -> AppLanguage {
        guard
            let rawValue = defaults.string(forKey: UserDefaultsKeys.language),
            let language = AppLanguage(rawValue: rawValue)
        else {
            return .english
        }
        return language
    }
}

enum UserDefaultsKeys {
    static let language = "appLanguage"
}

struct LocalizedStrings {
    let language: AppLanguage

    var settingsWindowTitle: String {
        switch language {
        case .english:
            return "DeepSeek Token Monitor Settings"
        case .simplifiedChinese:
            return "DeepSeek Token Monitor 设置"
        }
    }

    var settingsMenuTitle: String {
        switch language {
        case .english:
            return "Settings..."
        case .simplifiedChinese:
            return "设置..."
        }
    }

    var showWidgetMenuTitle: String {
        switch language {
        case .english:
            return "Show Widget"
        case .simplifiedChinese:
            return "显示小工具"
        }
    }

    var hideWidgetMenuTitle: String {
        switch language {
        case .english:
            return "Hide Widget"
        case .simplifiedChinese:
            return "隐藏小工具"
        }
    }

    var refreshBalanceMenuTitle: String {
        switch language {
        case .english:
            return "Refresh Balance"
        case .simplifiedChinese:
            return "刷新余额"
        }
    }

    var monthlySpend: String {
        switch language {
        case .english:
            return "Monthly spend"
        case .simplifiedChinese:
            return "本月消费"
        }
    }

    var apiRequests: String {
        switch language {
        case .english:
            return "API requests"
        case .simplifiedChinese:
            return "API 请求"
        }
    }

    var totalTokens: String {
        switch language {
        case .english:
            return "Total tokens"
        case .simplifiedChinese:
            return "总 tokens"
        }
    }

    var dailyTokenTrend: String {
        switch language {
        case .english:
            return "Daily token trend"
        case .simplifiedChinese:
            return "按日 token 趋势"
        }
    }

    var modelUsage: String {
        switch language {
        case .english:
            return "Model usage"
        case .simplifiedChinese:
            return "模型用量"
        }
    }

    var officialBalance: String {
        switch language {
        case .english:
            return "Official balance"
        case .simplifiedChinese:
            return "官方余额"
        }
    }

    var officialAPI: String {
        switch language {
        case .english:
            return "Official API"
        case .simplifiedChinese:
            return "官方 API"
        }
    }

    var localUsageSourceShort: String {
        switch language {
        case .english:
            return "Local records"
        case .simplifiedChinese:
            return "本地记录"
        }
    }

    var localAggregationNotice: String {
        switch language {
        case .english:
            return "Usage is aggregated from local records or imported CSV."
        case .simplifiedChinese:
            return "用量来自本地记录或导入 CSV 聚合。"
        }
    }

    var grantedShort: String {
        switch language {
        case .english:
            return "grant"
        case .simplifiedChinese:
            return "赠金"
        }
    }

    var toppedUpShort: String {
        switch language {
        case .english:
            return "top-up"
        case .simplifiedChinese:
            return "充值"
        }
    }

    var statusItemAccessibilityLabel: String {
        switch language {
        case .english:
            return "DeepSeek Token Monitor"
        case .simplifiedChinese:
            return "DeepSeek Token Monitor"
        }
    }

    var quitMenuTitle: String {
        switch language {
        case .english:
            return "Quit DeepSeek Token Monitor"
        case .simplifiedChinese:
            return "退出 DeepSeek Token Monitor"
        }
    }

    var editMenuTitle: String {
        switch language {
        case .english:
            return "Edit"
        case .simplifiedChinese:
            return "编辑"
        }
    }

    var cutMenuTitle: String {
        switch language {
        case .english:
            return "Cut"
        case .simplifiedChinese:
            return "剪切"
        }
    }

    var copyMenuTitle: String {
        switch language {
        case .english:
            return "Copy"
        case .simplifiedChinese:
            return "复制"
        }
    }

    var pasteMenuTitle: String {
        switch language {
        case .english:
            return "Paste"
        case .simplifiedChinese:
            return "粘贴"
        }
    }

    var selectAllMenuTitle: String {
        switch language {
        case .english:
            return "Select All"
        case .simplifiedChinese:
            return "全选"
        }
    }

    var settingsTitle: String {
        switch language {
        case .english:
            return "Settings"
        case .simplifiedChinese:
            return "设置"
        }
    }

    var settingsSubtitle: String {
        switch language {
        case .english:
            return "DeepSeek Token Monitor keeps secrets in Keychain and usage records in a local SQLite database."
        case .simplifiedChinese:
            return "DeepSeek Token Monitor 使用 Keychain 保存密钥，并用本地 SQLite 数据库保存用量记录。"
        }
    }

    var languageTitle: String {
        switch language {
        case .english:
            return "Language"
        case .simplifiedChinese:
            return "语言"
        }
    }

    var languageDescription: String {
        switch language {
        case .english:
            return "Choose the display language for the widget, Settings, menus, and status messages."
        case .simplifiedChinese:
            return "选择小工具、设置、菜单和状态提示使用的显示语言。"
        }
    }

    var apiKeyTitle: String {
        "DeepSeek API Key"
    }

    var savedInKeychain: String {
        switch language {
        case .english:
            return "Saved in Keychain"
        case .simplifiedChinese:
            return "已保存到 Keychain"
        }
    }

    var notSaved: String {
        switch language {
        case .english:
            return "Not saved"
        case .simplifiedChinese:
            return "未保存"
        }
    }

    var apiKeyReplacementPlaceholder: String {
        switch language {
        case .english:
            return "Enter a new key to replace the saved key"
        case .simplifiedChinese:
            return "输入新密钥以替换已保存密钥"
        }
    }

    var pasteButton: String {
        switch language {
        case .english:
            return "Paste"
        case .simplifiedChinese:
            return "粘贴"
        }
    }

    var saveButton: String {
        switch language {
        case .english:
            return "Save"
        case .simplifiedChinese:
            return "保存"
        }
    }

    var testConnectionButton: String {
        switch language {
        case .english:
            return "Test Connection"
        case .simplifiedChinese:
            return "测试连接"
        }
    }

    var clearAPIKeyButton: String {
        switch language {
        case .english:
            return "Clear API Key"
        case .simplifiedChinese:
            return "清除 API Key"
        }
    }

    var dataSourceTitle: String {
        switch language {
        case .english:
            return "Data Source"
        case .simplifiedChinese:
            return "数据来源"
        }
    }

    var providerTitle: String {
        switch language {
        case .english:
            return "Providers"
        case .simplifiedChinese:
            return "Provider"
        }
    }

    var providerDescription: String {
        switch language {
        case .english:
            return "DeepSeek is the only enabled provider in this phase. The app keeps the provider layer explicit so Kimi, OpenAI, and Claude can be added later without changing the monitor surface."
        case .simplifiedChinese:
            return "第一阶段只启用 DeepSeek。当前保留 provider 层，后续可接入 Kimi、OpenAI、Claude，而不需要重做监控面板。"
        }
    }

    var enabledStatus: String {
        switch language {
        case .english:
            return "Enabled"
        case .simplifiedChinese:
            return "已启用"
        }
    }

    var plannedStatus: String {
        switch language {
        case .english:
            return "Planned"
        case .simplifiedChinese:
            return "预留"
        }
    }

    var providerReserved: String {
        switch language {
        case .english:
            return "Reserved for later integration"
        case .simplifiedChinese:
            return "为后续接入预留"
        }
    }

    var officialUsageAggregation: String {
        switch language {
        case .english:
            return "Official usage aggregation"
        case .simplifiedChinese:
            return "官方用量聚合"
        }
    }

    var officialBalanceDescription: String {
        switch language {
        case .english:
            return "Official balance comes from `GET https://api.deepseek.com/user/balance` with Bearer authentication."
        case .simplifiedChinese:
            return "官方余额来自 `GET https://api.deepseek.com/user/balance`，使用 Bearer 认证。"
        }
    }

    var tokenUsageDescription: String {
        switch language {
        case .english:
            return "Token usage, model usage, request count, daily trend, and monthly spend are currently local-only. DeepSeek public API docs do not expose a historical usage aggregation endpoint. Import CSV records or capture future requests locally to populate Today, Week, Month, 30D, and All."
        case .simplifiedChinese:
            return "Token 用量、模型用量、请求次数、按日趋势和本月消费目前仅来自本地记录。DeepSeek 公开 API 文档没有历史用量聚合接口。可导入 CSV 或后续通过本地采集来填充今天、本周、本月、30 天和全部数据。"
        }
    }

    var localUsageDataTitle: String {
        switch language {
        case .english:
            return "Local Usage Data"
        case .simplifiedChinese:
            return "本地用量数据"
        }
    }

    var localUsageDescription: String {
        switch language {
        case .english:
            return "CSV import accepts timestamp, input_tokens, output_tokens, and optional model, total_tokens, estimated_cost, source, provider, and id columns."
        case .simplifiedChinese:
            return "CSV 导入支持 timestamp、input_tokens、output_tokens，以及可选的 model、total_tokens、estimated_cost、source、provider、id 列。"
        }
    }

    var importUsageCSVButton: String {
        switch language {
        case .english:
            return "Import Usage CSV"
        case .simplifiedChinese:
            return "导入用量 CSV"
        }
    }

    var reloadButton: String {
        switch language {
        case .english:
            return "Reload"
        case .simplifiedChinese:
            return "重新加载"
        }
    }

    var deleteLocalDataButton: String {
        switch language {
        case .english:
            return "Delete Local Data"
        case .simplifiedChinese:
            return "删除本地数据"
        }
    }

    var deleteLocalUsageAlertTitle: String {
        switch language {
        case .english:
            return "Delete local usage data?"
        case .simplifiedChinese:
            return "删除本地用量数据？"
        }
    }

    var deleteButton: String {
        switch language {
        case .english:
            return "Delete"
        case .simplifiedChinese:
            return "删除"
        }
    }

    var cancelButton: String {
        switch language {
        case .english:
            return "Cancel"
        case .simplifiedChinese:
            return "取消"
        }
    }

    var deleteLocalUsageAlertMessage: String {
        switch language {
        case .english:
            return "This removes imported/local usage records from this Mac. It does not affect DeepSeek."
        case .simplifiedChinese:
            return "这会从本机删除已导入或本地记录的用量数据，不会影响 DeepSeek 账户。"
        }
    }

    var noLocalRecords: String {
        switch language {
        case .english:
            return "No local records"
        case .simplifiedChinese:
            return "无本地记录"
        }
    }

    var tokens: String {
        switch language {
        case .english:
            return "tokens"
        case .simplifiedChinese:
            return "tokens"
        }
    }

    var balance: String {
        switch language {
        case .english:
            return "Balance"
        case .simplifiedChinese:
            return "余额"
        }
    }

    var tapToRefresh: String {
        switch language {
        case .english:
            return "Tap to refresh"
        case .simplifiedChinese:
            return "点击刷新"
        }
    }

    var addAPIKey: String {
        switch language {
        case .english:
            return "Add API Key"
        case .simplifiedChinese:
            return "添加 API Key"
        }
    }

    var refreshing: String {
        switch language {
        case .english:
            return "Refreshing"
        case .simplifiedChinese:
            return "刷新中"
        }
    }

    var error: String {
        switch language {
        case .english:
            return "Error"
        case .simplifiedChinese:
            return "错误"
        }
    }

    var unavailable: String {
        switch language {
        case .english:
            return "Unavailable"
        case .simplifiedChinese:
            return "不可用"
        }
    }

    var updated: String {
        switch language {
        case .english:
            return "Updated"
        case .simplifiedChinese:
            return "更新于"
        }
    }

    var widgetHelp: String {
        switch language {
        case .english:
            return "Drag to move. Double-click for Settings. Right-click for time span."
        case .simplifiedChinese:
            return "可拖动面板。双击打开设置。右键选择时间跨度。"
        }
    }

    var enterAPIKeyBeforeSaving: String {
        switch language {
        case .english:
            return "Enter a DeepSeek API Key before saving."
        case .simplifiedChinese:
            return "保存前请先输入 DeepSeek API Key。"
        }
    }

    var apiKeySavedMessage: String {
        switch language {
        case .english:
            return "API Key saved to macOS Keychain."
        case .simplifiedChinese:
            return "API Key 已保存到 macOS Keychain。"
        }
    }

    var apiKeyRemovedMessage: String {
        switch language {
        case .english:
            return "API Key removed from Keychain."
        case .simplifiedChinese:
            return "API Key 已从 Keychain 移除。"
        }
    }

    var saveOrEnterAPIKeyBeforeTesting: String {
        switch language {
        case .english:
            return "Save or enter an API Key before testing."
        case .simplifiedChinese:
            return "测试前请先保存或输入 API Key。"
        }
    }

    var testingDeepSeekConnection: String {
        switch language {
        case .english:
            return "Testing DeepSeek connection..."
        case .simplifiedChinese:
            return "正在测试 DeepSeek 连接..."
        }
    }

    func connectionOK(isAvailable: Bool) -> String {
        switch language {
        case .english:
            return "Connection OK. Account is \(isAvailable ? "available" : "not available")."
        case .simplifiedChinese:
            return "连接成功。账户\(isAvailable ? "可用" : "不可用")。"
        }
    }

    var addDeepSeekAPIKeyInSettings: String {
        switch language {
        case .english:
            return "Add a DeepSeek API Key in Settings first."
        case .simplifiedChinese:
            return "请先在设置中添加 DeepSeek API Key。"
        }
    }

    var importUsageCSVPanelTitle: String {
        switch language {
        case .english:
            return "Import DeepSeek Usage CSV"
        case .simplifiedChinese:
            return "导入 DeepSeek 用量 CSV"
        }
    }

    var localUsageDatabaseUnavailable: String {
        switch language {
        case .english:
            return "Local usage database is unavailable."
        case .simplifiedChinese:
            return "本地用量数据库不可用。"
        }
    }

    func importedLocalUsageRecords(_ count: Int) -> String {
        switch language {
        case .english:
            return "Imported \(count) local usage record(s)."
        case .simplifiedChinese:
            return "已导入 \(count) 条本地用量记录。"
        }
    }

    var localUsageRecordsDeleted: String {
        switch language {
        case .english:
            return "Local usage records deleted."
        case .simplifiedChinese:
            return "本地用量记录已删除。"
        }
    }
}
