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
            appearanceSection
            apiKeySection
            dataSourceSection
            localDataSection
            Spacer(minLength: 0)
            statusMessage
        }
        .padding(24)
        .frame(width: 560, height: 860)
        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
        .animation(AppAnimation.themeTransition, value: appState.theme.id)
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

    // MARK: - Header

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

    // MARK: - Language

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

    // MARK: - Appearance (NEW)

    private var appearanceSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(appearanceTitle)
                    .font(.system(size: 15, weight: .semibold))

                Text(appearanceDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(AppTheme.allThemes) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: appState.theme.id == theme.id
                        ) {
                            withAnimation(AppAnimation.themeTransition) {
                                appState.theme = theme
                            }
                        }
                    }
                }
            }
        }
    }

    private var appearanceTitle: String {
        switch appState.language {
        case .english:
            return "Appearance"
        case .simplifiedChinese:
            return "外觀"
        }
    }

    private var appearanceDescription: String {
        switch appState.language {
        case .english:
            return "Choose a theme for the floating widget. Changes apply immediately."
        case .simplifiedChinese:
            return "選擇懸浮小工具的主題。更改立即生效。"
        }
    }

    // MARK: - API Key

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
                        placeholder: appState.apiKeySaved
                            ? strings.apiKeyReplacementPlaceholder
                            : "sk-..."
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

    // MARK: - Data Source

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

    // MARK: - Local Data

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

    // MARK: - Status

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

// MARK: - Theme Preview Card

private struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Mini preview
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: theme.glass.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(theme.glass.borderLightColor.opacity(0.4), lineWidth: 0.8)
                    )
                    .overlay(
                        // Tiny number tiles
                        HStack(spacing: 4) {
                            miniTile(color: theme.accent, text: "888")
                            miniTile(color: theme.accent.opacity(0.6), text: "123")
                        }
                    )
                    .frame(height: 46)
                    .shadow(
                        color: theme.shadowColor.opacity(0.5),
                        radius: 4,
                        x: 0, y: 2
                    )

                Text(themeDisplayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected
                        ? Color.accentColor.opacity(0.08)
                        : Color.white.opacity(isHovering ? 0.7 : 0.4)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected
                            ? Color.accentColor.opacity(0.5)
                            : Color.black.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private var themeDisplayName: String {
        // Use Chinese names when app language is Simplified Chinese
        let nameMap: [String: String] = [
            "deepOcean": "深海",
            "auroraNight": "極光",
            "starlight": "星光",
            "frostMorning": "晨霜",
            "ember": "餘燼",
            "midnight": "午夜"
        ]
        return nameMap[theme.id] ?? theme.name
    }

    private func miniTile(color: Color, text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.8))
            .frame(width: 42, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.3))
            )
    }
}

// MARK: - Settings Card

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
