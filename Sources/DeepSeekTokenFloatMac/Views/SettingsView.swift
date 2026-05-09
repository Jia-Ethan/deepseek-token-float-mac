import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var apiKeyInput = ""
    @State private var confirmDeleteUsage = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                languageSection
                appearanceSection
                apiKeySection
                providerSection
                dataSourceSection
                localDataSection
                statusMessage
            }
            .padding(24)
        }
        .frame(width: 560, height: 860)
        .background(SettingsPalette.background)
        .preferredColorScheme(.light)
        .tint(SettingsPalette.appleBlue)
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

    private var providerSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.providerTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsPalette.primaryText)

                Text(strings.providerDescription)
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(2)
                    .foregroundStyle(SettingsPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 8) {
                    ForEach(appState.providerCapabilities) { capability in
                        ProviderCapabilityRow(capability: capability, strings: strings)
                    }
                }
            }
        }
    }

    private var strings: LocalizedStrings {
        appState.strings
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(strings.settingsTitle)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(SettingsPalette.primaryText)
            Text(strings.settingsSubtitle)
                .font(.system(size: 13, weight: .regular))
                .lineSpacing(2)
                .foregroundStyle(SettingsPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var languageSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.languageTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsPalette.primaryText)

                Text(strings.languageDescription)
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(2)
                    .foregroundStyle(SettingsPalette.secondaryText)
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

    private var appearanceSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(appearanceTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsPalette.primaryText)

                Text(appearanceDescription)
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(2)
                    .foregroundStyle(SettingsPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
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
            return "外观"
        }
    }

    private var appearanceDescription: String {
        switch appState.language {
        case .english:
            return "Choose a theme for the floating monitor. Changes apply immediately."
        case .simplifiedChinese:
            return "选择悬浮监控面板的主题。更改会立即生效。"
        }
    }

    private var apiKeySection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(strings.apiKeyTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SettingsPalette.primaryText)
                    Spacer()
                    Text(appState.apiKeySaved ? strings.savedInKeychain : strings.notSaved)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(appState.apiKeySaved ? SettingsPalette.success : SettingsPalette.tertiaryText)
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
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 10) {
                    Button(strings.saveButton) {
                        appState.saveAPIKey(apiKeyInput)
                        apiKeyInput = ""
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button(strings.testConnectionButton) {
                        appState.testConnection(
                            candidateKey: apiKeyInput.isEmpty ? nil : apiKeyInput
                        )
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(strings.clearAPIKeyButton, role: .destructive) {
                        appState.clearAPIKey()
                        apiKeyInput = ""
                    }
                    .buttonStyle(.bordered)
                    .tint(SettingsPalette.danger)
                    .disabled(!appState.apiKeySaved)
                }
                .controlSize(.regular)
            }
        }
    }

    private var dataSourceSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.dataSourceTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsPalette.primaryText)

                Text(strings.officialBalanceDescription)
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(2)
                    .foregroundStyle(SettingsPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(strings.tokenUsageDescription)
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(2)
                    .foregroundStyle(SettingsPalette.secondaryText)
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
                    .foregroundStyle(SettingsPalette.primaryText)

                Text(strings.localUsageDescription)
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(2)
                    .foregroundStyle(SettingsPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    SummaryChip(title: strings.apiRequests, value: DisplayFormatters.compactNumber(appState.usageSummary.recordCount))
                    SummaryChip(title: strings.totalTokens, value: DisplayFormatters.compactTokens(appState.usageSummary.totalTokens))
                    SummaryChip(title: strings.modelUsage, value: DisplayFormatters.compactNumber(appState.modelSummaries.count))
                }

                HStack(spacing: 10) {
                    Button(strings.importUsageCSVButton) {
                        appState.importUsageCSV()
                    }
                    .buttonStyle(.borderedProminent)

                    Button(strings.reloadButton) {
                        appState.reloadUsage()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(strings.deleteLocalDataButton, role: .destructive) {
                        confirmDeleteUsage = true
                    }
                    .buttonStyle(.bordered)
                    .tint(SettingsPalette.danger)
                }
                .controlSize(.regular)
            }
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if let message = appState.settingsMessage {
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(appState.settingsMessageIsError ? SettingsPalette.danger : SettingsPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }
}

private struct ProviderCapabilityRow: View {
    let capability: ProviderCapability
    let strings: LocalizedStrings

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(capability.id.isEnabledInCurrentPhase ? SettingsPalette.success : SettingsPalette.tertiaryText)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(capability.id.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SettingsPalette.primaryText)
                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(SettingsPalette.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Text(capability.id.isEnabledInCurrentPhase ? strings.enabledStatus : strings.plannedStatus)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(capability.id.isEnabledInCurrentPhase ? SettingsPalette.success : SettingsPalette.tertiaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill((capability.id.isEnabledInCurrentPhase ? SettingsPalette.success : SettingsPalette.tertiaryText).opacity(0.12))
                )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.025))
        )
    }

    private var detail: String {
        var parts: [String] = []
        if capability.supportsBalance {
            parts.append(strings.officialBalance)
        }
        if capability.supportsLocalUsageAggregation {
            parts.append(strings.localUsageSourceShort)
        }
        if capability.supportsOfficialUsageAggregation {
            parts.append(strings.officialUsageAggregation)
        }
        return parts.isEmpty ? strings.providerReserved : parts.joined(separator: " / ")
    }
}

private struct SummaryChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SettingsPalette.tertiaryText)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SettingsPalette.primaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.025))
        )
    }
}

private struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
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
                        HStack(spacing: 4) {
                            miniTile(color: theme.accent, text: "88")
                            miniTile(color: theme.accent.opacity(0.65), text: "12K")
                        }
                    )
                    .frame(height: 46)
                    .shadow(color: theme.shadowColor.opacity(0.5), radius: 4, x: 0, y: 2)

                Text(theme.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? SettingsPalette.primaryText : SettingsPalette.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? SettingsPalette.appleBlue.opacity(0.08) : Color.white.opacity(isHovering ? 0.78 : 0.46))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? SettingsPalette.appleBlue.opacity(0.5) : Color.black.opacity(0.08),
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

    private func miniTile(color: Color, text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(theme.textPrimary)
            .frame(width: 24, height: 16)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.18))
            )
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SettingsPalette.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SettingsPalette.cardStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)
    }
}

private enum SettingsPalette {
    static let background = Color(red: 0.9608, green: 0.9608, blue: 0.9686)
    static let cardBackground = Color.white.opacity(0.92)
    static let cardStroke = Color.black.opacity(0.05)
    static let primaryText = Color(red: 0.1137, green: 0.1137, blue: 0.1216)
    static let secondaryText = Color(red: 0.1137, green: 0.1137, blue: 0.1216).opacity(0.72)
    static let tertiaryText = Color(red: 0.1137, green: 0.1137, blue: 0.1216).opacity(0.54)
    static let appleBlue = Color(red: 0, green: 0.4431, blue: 0.8902)
    static let success = Color(red: 0.1412, green: 0.5412, blue: 0.2353)
    static let danger = Color(red: 0.8431, green: 0, blue: 0.0824)
}
