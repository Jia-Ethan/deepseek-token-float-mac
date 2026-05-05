import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var apiKeyInput = ""
    @State private var confirmDeleteUsage = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            languageSection
            apiKeySection
            dataSourceSection
            localDataSection
            Spacer(minLength: 0)
            statusMessage
        }
        .padding(24)
        .frame(width: 520, height: 700)
        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
        .alert(strings.deleteLocalUsageAlertTitle, isPresented: $confirmDeleteUsage) {
            Button(strings.deleteButton, role: .destructive) {
                appState.deleteLocalUsageData()
            }
            Button(strings.cancelButton, role: .cancel) {}
        } message: {
            Text(strings.deleteLocalUsageAlertMessage)
        }
    }

    private var strings: LocalizedStrings {
        appState.strings
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(strings.settingsTitle)
                .font(.system(size: 28, weight: .semibold))
            Text(strings.settingsSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var languageSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.languageTitle)
                    .font(.system(size: 15, weight: .semibold))

                Text(strings.languageDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Picker(strings.languageTitle, selection: $appState.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName)
                            .tag(language)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
    }

    private var apiKeySection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(strings.apiKeyTitle)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(appState.apiKeySaved ? strings.savedInKeychain : strings.notSaved)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(appState.apiKeySaved ? .green : .secondary)
                }

                HStack(spacing: 8) {
                    PasteFriendlySecureField(
                        text: $apiKeyInput,
                        placeholder: appState.apiKeySaved ? strings.apiKeyReplacementPlaceholder : "sk-..."
                    )
                    .frame(height: 24)

                    Button(strings.pasteButton) {
                        if let pasted = NSPasteboard.general.string(forType: .string) {
                            apiKeyInput = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }

                HStack {
                    Button(strings.saveButton) {
                        appState.saveAPIKey(apiKeyInput)
                        apiKeyInput = ""
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button(strings.testConnectionButton) {
                        appState.testConnection(
                            candidateKey: apiKeyInput.isEmpty ? nil : apiKeyInput
                        )
                    }

                    Spacer()

                    Button(strings.clearAPIKeyButton, role: .destructive) {
                        appState.clearAPIKey()
                        apiKeyInput = ""
                    }
                    .disabled(!appState.apiKeySaved)
                }
            }
        }
    }

    private var dataSourceSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.dataSourceTitle)
                    .font(.system(size: 15, weight: .semibold))

                Text(strings.officialBalanceDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(strings.tokenUsageDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .textSelection(.enabled)
        }
    }

    private var localDataSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(strings.localUsageDataTitle)
                    .font(.system(size: 15, weight: .semibold))

                Text(strings.localUsageDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button(strings.importUsageCSVButton) {
                        appState.importUsageCSV()
                    }

                    Button(strings.reloadButton) {
                        appState.reloadUsage()
                    }

                    Spacer()

                    Button(strings.deleteLocalDataButton, role: .destructive) {
                        confirmDeleteUsage = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if let message = appState.settingsMessage {
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(appState.settingsMessageIsError ? .red : .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            )
    }
}
