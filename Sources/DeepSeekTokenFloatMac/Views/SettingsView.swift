import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var apiKeyInput = ""
    @State private var confirmDeleteUsage = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            apiKeySection
            dataSourceSection
            localDataSection
            Spacer(minLength: 0)
            statusMessage
        }
        .padding(24)
        .frame(width: 520, height: 610)
        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
        .alert("Delete local usage data?", isPresented: $confirmDeleteUsage) {
            Button("Delete", role: .destructive) {
                appState.deleteLocalUsageData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes imported/local usage records from this Mac. It does not affect DeepSeek.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 28, weight: .semibold))
            Text("DeepSeek Token Monitor keeps secrets in Keychain and usage records in a local SQLite database.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var apiKeySection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("DeepSeek API Key")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(appState.apiKeySaved ? "Saved in Keychain" : "Not saved")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(appState.apiKeySaved ? .green : .secondary)
                }

                HStack(spacing: 8) {
                    PasteFriendlySecureField(
                        text: $apiKeyInput,
                        placeholder: appState.apiKeySaved ? "Enter a new key to replace the saved key" : "sk-..."
                    )
                    .frame(height: 24)

                    Button("Paste") {
                        if let pasted = NSPasteboard.general.string(forType: .string) {
                            apiKeyInput = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }

                HStack {
                    Button("Save") {
                        appState.saveAPIKey(apiKeyInput)
                        apiKeyInput = ""
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Test Connection") {
                        appState.testConnection(
                            candidateKey: apiKeyInput.isEmpty ? nil : apiKeyInput
                        )
                    }

                    Spacer()

                    Button("Clear API Key", role: .destructive) {
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
                Text("Data Source")
                    .font(.system(size: 15, weight: .semibold))

                Text("Official balance comes from `GET https://api.deepseek.com/user/balance` with Bearer authentication.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text("Token usage is currently local-only. DeepSeek public API docs do not expose a historical usage aggregation endpoint. Import CSV records to populate Today, Week, 30D, and All.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .textSelection(.enabled)
        }
    }

    private var localDataSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Local Usage Data")
                    .font(.system(size: 15, weight: .semibold))

                Text("CSV import accepts timestamp, input_tokens, output_tokens, and optional model, total_tokens, estimated_cost, source, provider, and id columns.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("Import Usage CSV") {
                        appState.importUsageCSV()
                    }

                    Button("Reload") {
                        appState.reloadUsage()
                    }

                    Spacer()

                    Button("Delete Local Data", role: .destructive) {
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
