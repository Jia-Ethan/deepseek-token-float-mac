import AppKit
import SwiftUI

private let panelCornerRadius: CGFloat = 26

struct FloatingCardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isPressed = false

    private var snapshot: MonitorSnapshot {
        appState.monitorSnapshot
    }

    private var theme: AppTheme {
        appState.theme
    }

    var body: some View {
        ZStack {
            panelBackground
            VStack(spacing: 14) {
                header
                metricsGrid
                HStack(alignment: .top, spacing: 12) {
                    chartSection
                    modelSection
                }
                footer
            }
            .padding(18)
        }
        .frame(width: 640, height: 430)
        .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous))
        .compositingGroup()
        .shadow(color: theme.shadowColor.opacity(0.95), radius: 34, x: 0, y: 18)
        .scaleEffect(isPressed ? AppAnimation.pressScaleAmount : 1)
        .animation(AppAnimation.pressScale, value: isPressed)
        .animation(AppAnimation.themeTransition, value: theme.id)
        .overlay(
            WidgetClickLayer(
                selectedSpan: appState.selectedSpan,
                language: appState.language,
                onPressChanged: { isPressed = $0 },
                onDoubleClick: {
                    SettingsWindowController.shared.show(appState: appState)
                },
                onSelectSpan: { span in
                    appState.selectedSpan = span
                }
            )
        )
        .help(appState.strings.widgetHelp)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: statusColor.opacity(0.65), radius: 8)
                    Text("DeepSeek Monitor")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                }
                Text(dataBoundaryText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary.opacity(0.72))
                    .lineLimit(1)
            }

            Spacer()

            spanPicker

            Button {
                appState.fetchBalance()
                appState.reloadUsage()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(MonitorIconButtonStyle())
            .disabled(snapshot.balanceStatus == .loading)
            .help(appState.strings.refreshBalanceMenuTitle)

            Button {
                SettingsWindowController.shared.show(appState: appState)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(MonitorIconButtonStyle())
            .help(appState.strings.settingsMenuTitle)
        }
    }

    private var spanPicker: some View {
        HStack(spacing: 4) {
            ForEach(TimeSpan.allCases) { span in
                Button {
                    appState.selectedSpan = span
                } label: {
                    Text(span.label(language: appState.language))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(minWidth: 44, minHeight: 26)
                }
                .buttonStyle(SpanButtonStyle(isSelected: appState.selectedSpan == span))
            }
        }
            .padding(3)
            .background(
                Capsule(style: .continuous)
                .fill(theme.tileBackground.opacity(0.45))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(theme.tileBorder.opacity(0.9), lineWidth: 1)
                )
        )
    }

    private var metricsGrid: some View {
        HStack(spacing: 10) {
            MetricTile(
                title: appState.strings.balance,
                value: balanceValue,
                detail: balanceDetail,
                iconName: "creditcard",
                accent: theme.accent
            )
            MetricTile(
                title: appState.strings.monthlySpend,
                value: DisplayFormatters.cost(snapshot.usageSummary.estimatedCost),
                detail: appState.strings.localUsageSourceShort,
                iconName: "chart.line.uptrend.xyaxis",
                accent: MonitorPalette.green
            )
            MetricTile(
                title: appState.strings.apiRequests,
                value: DisplayFormatters.compactNumber(snapshot.usageSummary.recordCount),
                detail: snapshot.span.label(language: appState.language),
                iconName: "arrow.left.arrow.right",
                accent: theme.accentSecondary
            )
            MetricTile(
                title: appState.strings.totalTokens,
                value: DisplayFormatters.compactTokens(snapshot.usageSummary.totalTokens),
                detail: "\(DisplayFormatters.compactTokens(snapshot.usageSummary.inputTokens)) in / \(DisplayFormatters.compactTokens(snapshot.usageSummary.outputTokens)) out",
                iconName: "number",
                accent: MonitorPalette.amber
            )
        }
    }

    private var chartSection: some View {
        MonitorPanel(title: appState.strings.dailyTokenTrend, systemImage: "waveform.path.ecg", theme: theme) {
            UsageTrendChart(points: snapshot.dailyUsage, theme: theme)
                .frame(height: 132)
            HStack {
                Text(appState.strings.localAggregationNotice)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary.opacity(0.68))
                    .lineLimit(2)
                Spacer()
                Text(lastUpdatedText)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .frame(width: 374)
    }

    private var modelSection: some View {
        MonitorPanel(title: appState.strings.modelUsage, systemImage: "cpu", theme: theme) {
            VStack(spacing: 8) {
                if snapshot.modelSummaries.isEmpty {
                    EmptyMonitorState(text: appState.strings.noLocalRecords, theme: theme)
                        .frame(height: 162)
                } else {
                    ForEach(snapshot.modelSummaries.prefix(4)) { model in
                        ModelUsageRow(
                            model: model,
                            maxTokens: max(snapshot.modelSummaries.map(\.totalTokens).max() ?? 1, 1),
                            theme: theme
                        )
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 180)
        }
        .frame(width: 216)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            ForEach(appState.providerCapabilities) { capability in
                ProviderPill(capability: capability, theme: theme)
            }
            Spacer()
            Text(errorText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(errorText.isEmpty ? theme.textSecondary.opacity(0.65) : MonitorPalette.danger)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
            .fill(materialFor(theme.glass.baseMaterial))
            .overlay(
                LinearGradient(
                    colors: theme.glass.gradientColors.map { $0.opacity(theme.glass.gradientOpacity) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RadialGradient(
                    colors: [
                        theme.accent.opacity(0.24),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 380
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: panelCornerRadius - 1, style: .continuous)
                    .stroke(theme.glass.borderLightColor.opacity(0.18), lineWidth: 1)
                    .padding(1)
            )
    }

    private func materialFor(_ style: GlassConfig.MaterialStyle) -> Material {
        switch style {
        case .ultraThin:
            return .ultraThinMaterial
        case .regular:
            return .regularMaterial
        case .thick:
            return .thickMaterial
        }
    }

    private var statusColor: Color {
        switch snapshot.balanceStatus {
        case .loading:
            return MonitorPalette.amber
        case .failed:
            return MonitorPalette.danger
        case .loaded(let balance):
            return balance.response.isAvailable ? MonitorPalette.green : MonitorPalette.amber
        case .idle:
            return appState.apiKeySaved ? theme.accent : theme.textSecondary.opacity(0.55)
        }
    }

    private var dataBoundaryText: String {
        switch snapshot.balanceStatus {
        case .loading:
            return appState.strings.refreshing
        case .failed(let message):
            return message
        case .loaded(let balance):
            return "\(appState.strings.officialBalance) / \(appState.strings.updated) \(shortTime(balance.updatedAt))"
        case .idle:
            return appState.apiKeySaved ? appState.strings.tapToRefresh : appState.strings.addDeepSeekAPIKeyInSettings
        }
    }

    private var balanceValue: String {
        guard let balance = snapshot.balance else {
            return snapshot.balanceStatus == .loading ? "..." : "0"
        }
        return DisplayFormatters.balance(balance.totalBalance, currency: balance.currency)
    }

    private var balanceDetail: String {
        guard let balance = snapshot.balance else {
            return appState.apiKeySaved ? appState.strings.officialAPI : appState.strings.addAPIKey
        }
        let granted = DisplayFormatters.balance(balance.grantedBalance, currency: balance.currency)
        let topped = DisplayFormatters.balance(balance.toppedUpBalance, currency: balance.currency)
        return "\(appState.strings.grantedShort) \(granted) / \(appState.strings.toppedUpShort) \(topped)"
    }

    private var lastUpdatedText: String {
        guard snapshot.updatedAt.timeIntervalSince1970 > 0 else {
            return ""
        }
        return "\(appState.strings.updated) \(shortTime(snapshot.updatedAt))"
    }

    private var errorText: String {
        if case .failed(let message) = snapshot.balanceStatus {
            return message
        }
        return ""
    }

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let detail: String
    let iconName: String
    let accent: Color
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(appState.theme.textSecondary.opacity(0.68))
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(appState.theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(detail)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(appState.theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(width: 143, height: 104, alignment: .leading)
        .background(appState.theme.tileBackground.opacity(0.42))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.075), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(accent.opacity(0.55))
                .frame(height: 1)
                .padding(.horizontal, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct MonitorPanel<Content: View>: View {
    let title: String
    let systemImage: String
    let theme: AppTheme
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.accent)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
            }
            content
        }
        .padding(13)
        .background(theme.tileBackground.opacity(0.42))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.075), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct UsageTrendChart: View {
    let points: [DailyUsagePoint]
    let theme: AppTheme

    var body: some View {
        GeometryReader { proxy in
            if points.isEmpty {
                EmptyMonitorState(text: "No local data", theme: theme)
            } else {
                let maxValue = max(points.map(\.totalTokens).max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(points) { point in
                        VStack(spacing: 5) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            theme.accent,
                                            theme.accentSecondary
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: max(8, min(18, proxy.size.width / CGFloat(max(points.count, 1)) - 5)),
                                    height: max(8, CGFloat(point.totalTokens) / CGFloat(maxValue) * (proxy.size.height - 22))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(Color.white.opacity(0.16), lineWidth: 0.6)
                                )
                            Text(dayLabel(point.date))
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(MonitorPalette.mutedText)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

private struct ModelUsageRow: View {
    let model: ModelUsageSummary
    let maxTokens: Int64
    let theme: AppTheme

    private var progress: CGFloat {
        max(0.04, CGFloat(model.totalTokens) / CGFloat(max(maxTokens, 1)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(model.model)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(DisplayFormatters.compactTokens(model.totalTokens))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.055))
                    Capsule(style: .continuous)
                        .fill(theme.accent.opacity(0.75))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 6)
            Text("\(DisplayFormatters.compactNumber(model.requestCount)) req / \(DisplayFormatters.compactTokens(model.inputTokens)) in")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary.opacity(0.65))
                .lineLimit(1)
        }
        .padding(9)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct EmptyMonitorState: View {
    let text: String
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.textSecondary.opacity(0.6))
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.022))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

private struct ProviderPill: View {
    let capability: ProviderCapability
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(capability.id.isEnabledInCurrentPhase ? MonitorPalette.green : MonitorPalette.mutedText.opacity(0.55))
                .frame(width: 6, height: 6)
            Text(capability.id.displayName)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(capability.id.isEnabledInCurrentPhase ? theme.textSecondary : theme.textSecondary.opacity(0.55))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(capability.id.isEnabledInCurrentPhase ? 0.055 : 0.028))
        .clipShape(Capsule(style: .continuous))
    }
}

private struct MonitorIconButtonStyle: ButtonStyle {
    @EnvironmentObject private var appState: AppState

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(appState.theme.textPrimary)
            .background(
                Circle()
                    .fill(appState.theme.tileBackground.opacity(configuration.isPressed ? 0.72 : 0.42))
                    .overlay(
                        Circle()
                            .stroke(appState.theme.tileBorder, lineWidth: 1)
                    )
            )
    }
}

private struct SpanButtonStyle: ButtonStyle {
    let isSelected: Bool
    @EnvironmentObject private var appState: AppState

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? appState.theme.textPrimary : appState.theme.textSecondary.opacity(0.66))
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? appState.theme.accent.opacity(configuration.isPressed ? 0.58 : 0.42) : Color.clear)
            )
    }
}

private enum MonitorPalette {
    static let primaryText = Color(red: 0.965, green: 0.982, blue: 0.992)
    static let secondaryText = Color(red: 0.72, green: 0.78, blue: 0.84)
    static let mutedText = Color(red: 0.48, green: 0.56, blue: 0.64)
    static let cyan = Color(red: 0.31, green: 0.82, blue: 0.94)
    static let violet = Color(red: 0.45, green: 0.43, blue: 0.95)
    static let green = Color(red: 0.22, green: 0.84, blue: 0.54)
    static let amber = Color(red: 0.94, green: 0.72, blue: 0.28)
    static let danger = Color(red: 0.98, green: 0.36, blue: 0.42)
    static let panelFill = Color.white.opacity(0.045)
}

private struct WidgetClickLayer: NSViewRepresentable {
    let selectedSpan: TimeSpan
    let language: AppLanguage
    let onPressChanged: (Bool) -> Void
    let onDoubleClick: () -> Void
    let onSelectSpan: (TimeSpan) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> ClickCaptureView {
        let view = ClickCaptureView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: ClickCaptureView, context: Context) {
        context.coordinator.parent = self
        nsView.coordinator = context.coordinator
    }

    final class Coordinator: NSObject {
        var parent: WidgetClickLayer

        init(parent: WidgetClickLayer) {
            self.parent = parent
        }

        func pressChanged(_ pressed: Bool) {
            parent.onPressChanged(pressed)
        }

        func doubleClick() {
            parent.onPressChanged(false)
            parent.onDoubleClick()
        }

        func showMenu(from view: NSView, at point: NSPoint) {
            parent.onPressChanged(false)

            let menu = NSMenu()
            for span in TimeSpan.allCases {
                let item = NSMenuItem(
                    title: span.menuLabel(language: parent.language),
                    action: #selector(selectSpan(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = span.rawValue
                item.state = span == parent.selectedSpan ? .on : .off
                item.target = self
                menu.addItem(item)
            }

            menu.popUp(positioning: nil, at: point, in: view)
        }

        @objc private func selectSpan(_ sender: NSMenuItem) {
            guard
                let rawValue = sender.representedObject as? String,
                let span = TimeSpan(rawValue: rawValue)
            else {
                return
            }
            parent.onSelectSpan(span)
        }
    }

    final class ClickCaptureView: NSView {
        weak var coordinator: Coordinator?

        override var acceptsFirstResponder: Bool {
            true
        }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount >= 2 {
                coordinator?.doubleClick()
                return
            }
            coordinator?.pressChanged(true)
        }

        override func mouseUp(with event: NSEvent) {
            coordinator?.pressChanged(false)
        }

        override func mouseExited(with event: NSEvent) {
            coordinator?.pressChanged(false)
        }

        override func rightMouseDown(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            coordinator?.showMenu(from: self, at: point)
        }
    }
}
