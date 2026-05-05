import AppKit
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedSpan: TimeSpan = .today {
        didSet {
            reloadUsage()
        }
    }
    @Published private(set) var usageSummary: UsageSummary = .empty
    @Published private(set) var balanceStatus: BalanceStatus = .idle
    @Published private(set) var apiKeySaved: Bool = false
    @Published var settingsMessage: String?
    @Published var settingsMessageIsError: Bool = false
    @Published var language: AppLanguage = AppLanguage.saved() {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: UserDefaultsKeys.language)
        }
    }

    var strings: LocalizedStrings {
        LocalizedStrings(language: language)
    }

    private let keychain = KeychainStore()
    private let balanceClient = DeepSeekBalanceClient()
    private let database: UsageDatabase?
    private let importer = UsageCSVImporter()

    private init() {
        do {
            database = try UsageDatabase()
        } catch {
            database = nil
            settingsMessage = error.localizedDescription
            settingsMessageIsError = true
        }
        apiKeySaved = keychain.apiKeyExists()
        reloadUsage()
    }

    func fetchBalance() {
        guard balanceStatus != .loading else {
            return
        }

        let apiKey: String
        do {
            guard let savedKey = try keychain.readAPIKey(), !savedKey.isEmpty else {
                balanceStatus = .failed(strings.addDeepSeekAPIKeyInSettings)
                return
            }
            apiKey = savedKey
        } catch {
            balanceStatus = .failed(error.localizedDescription)
            return
        }

        balanceStatus = .loading
        Task {
            do {
                let response = try await balanceClient.fetchBalance(apiKey: apiKey)
                balanceStatus = .loaded(
                    BalanceSnapshot(response: response, updatedAt: Date())
                )
            } catch {
                balanceStatus = .failed(error.localizedDescription)
            }
        }
    }

    func saveAPIKey(_ rawValue: String) {
        let apiKey = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            showSettingsMessage(strings.enterAPIKeyBeforeSaving, isError: true)
            return
        }

        do {
            try keychain.saveAPIKey(apiKey)
            apiKeySaved = true
            balanceStatus = .idle
            showSettingsMessage(strings.apiKeySavedMessage, isError: false)
        } catch {
            showSettingsMessage(error.localizedDescription, isError: true)
        }
    }

    func clearAPIKey() {
        do {
            try keychain.deleteAPIKey(allowMissing: true)
            apiKeySaved = false
            balanceStatus = .idle
            showSettingsMessage(strings.apiKeyRemovedMessage, isError: false)
        } catch {
            showSettingsMessage(error.localizedDescription, isError: true)
        }
    }

    func testConnection(candidateKey: String?) {
        let apiKey: String
        let trimmedCandidate = candidateKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !trimmedCandidate.isEmpty {
            apiKey = trimmedCandidate
        } else {
            do {
                guard let savedKey = try keychain.readAPIKey(), !savedKey.isEmpty else {
                    showSettingsMessage(strings.saveOrEnterAPIKeyBeforeTesting, isError: true)
                    return
                }
                apiKey = savedKey
            } catch {
                showSettingsMessage(error.localizedDescription, isError: true)
                return
            }
        }

        showSettingsMessage(strings.testingDeepSeekConnection, isError: false)
        Task {
            do {
                let response = try await balanceClient.fetchBalance(apiKey: apiKey)
                balanceStatus = .loaded(
                    BalanceSnapshot(response: response, updatedAt: Date())
                )
                showSettingsMessage(strings.connectionOK(isAvailable: response.isAvailable), isError: false)
            } catch {
                showSettingsMessage(error.localizedDescription, isError: true)
            }
        }
    }

    func importUsageCSV() {
        let panel = NSOpenPanel()
        panel.title = strings.importUsageCSVPanelTitle
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.commaSeparatedText, .plainText]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let records = try importer.records(from: url)
            guard let database else {
                showSettingsMessage(strings.localUsageDatabaseUnavailable, isError: true)
                return
            }
            try database.insert(records)
            reloadUsage()
            showSettingsMessage(strings.importedLocalUsageRecords(records.count), isError: false)
        } catch {
            showSettingsMessage(error.localizedDescription, isError: true)
        }
    }

    func deleteLocalUsageData() {
        do {
            guard let database else {
                showSettingsMessage(strings.localUsageDatabaseUnavailable, isError: true)
                return
            }
            try database.deleteAllUsageRecords()
            reloadUsage()
            showSettingsMessage(strings.localUsageRecordsDeleted, isError: false)
        } catch {
            showSettingsMessage(error.localizedDescription, isError: true)
        }
    }

    func reloadUsage() {
        do {
            guard let database else {
                usageSummary = .empty
                return
            }
            usageSummary = try database.summary(for: selectedSpan)
        } catch {
            usageSummary = .empty
            showSettingsMessage(error.localizedDescription, isError: true)
        }
    }

    private func showSettingsMessage(_ message: String, isError: Bool) {
        settingsMessage = message
        settingsMessageIsError = isError
    }
}
