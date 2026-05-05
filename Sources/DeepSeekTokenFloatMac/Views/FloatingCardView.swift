import AppKit
import SwiftUI

struct FloatingCardView: View {
    @EnvironmentObject private var appState: AppState

    @State private var widgetMode: WidgetMode = .usage
    @State private var isPressed = false

    var body: some View {
        ZStack {
            cardBackground

            VStack(spacing: 18) {
                Spacer(minLength: 0)
                numberStrip
                footer
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .frame(width: 360, height: 170)
        .scaleEffect(isPressed ? 0.985 : 1)
        .animation(.spring(response: 0.18, dampingFraction: 0.82), value: isPressed)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: widgetMode)
        .overlay(
            WidgetClickLayer(
                selectedSpan: appState.selectedSpan,
                language: appState.language,
                onPressChanged: { isPressed = $0 },
                onSingleClick: toggleMode,
                onDoubleClick: {
                    SettingsWindowController.shared.show(appState: appState)
                },
                onSelectSpan: { span in
                    appState.selectedSpan = span
                    if widgetMode == .usage {
                        appState.reloadUsage()
                    }
                }
            )
        )
        .help(appState.strings.widgetHelp)
    }

    private var numberStrip: some View {
        HStack(spacing: 14) {
            ForEach(Array(display.segments.enumerated()), id: \.offset) { _, segment in
                NumberTile(text: segment, segmentCount: display.segments.count)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .id(display.identity)
    }

    private var footer: some View {
        Text(display.footer)
            .font(.system(size: 19, weight: .semibold, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(Color.white.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .contentTransition(.opacity)
    }

    private var display: WidgetDisplay {
        switch widgetMode {
        case .usage:
            let totalTokens = appState.usageSummary.totalTokens
            let footer = appState.usageSummary.recordCount == 0
                ? "\(appState.selectedSpan.label(language: appState.language)) / \(appState.strings.noLocalRecords)"
                : "\(appState.selectedSpan.label(language: appState.language)) / \(appState.strings.tokens)"

            return WidgetDisplay(
                segments: tokenSegments(totalTokens),
                footer: footer,
                identity: "usage-\(appState.selectedSpan.rawValue)-\(totalTokens)-\(appState.usageSummary.recordCount)"
            )

        case .balance:
            switch appState.balanceStatus {
            case .idle:
                return WidgetDisplay(
                    segments: ["0"],
                    footer: appState.apiKeySaved
                        ? "\(appState.strings.balance) / \(appState.strings.tapToRefresh)"
                        : "\(appState.strings.balance) / \(appState.strings.addAPIKey)",
                    identity: "balance-idle-\(appState.apiKeySaved)"
                )
            case .loading:
                return WidgetDisplay(
                    segments: ["..."],
                    footer: "\(appState.strings.balance) / \(appState.strings.refreshing)",
                    identity: "balance-loading"
                )
            case .failed:
                return WidgetDisplay(
                    segments: ["0"],
                    footer: appState.apiKeySaved
                        ? "\(appState.strings.balance) / \(appState.strings.error)"
                        : "\(appState.strings.balance) / \(appState.strings.addAPIKey)",
                    identity: "balance-failed-\(appState.apiKeySaved)"
                )
            case .loaded(let snapshot):
                guard let first = snapshot.response.balanceInfos.first else {
                    return WidgetDisplay(
                        segments: ["0"],
                        footer: "\(appState.strings.balance) / \(appState.strings.unavailable)",
                        identity: "balance-empty"
                    )
                }

                return WidgetDisplay(
                    segments: [trimBalance(first.totalBalance)],
                    footer: "\(first.currency) / \(appState.strings.updated) \(shortTime(snapshot.updatedAt))",
                    identity: "balance-loaded-\(first.currency)-\(first.totalBalance)-\(snapshot.updatedAt.timeIntervalSince1970)"
                )
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.28, blue: 0.38).opacity(0.92),
                                Color(red: 0.08, green: 0.20, blue: 0.30).opacity(0.86)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color(red: 0.63, green: 0.78, blue: 0.91).opacity(0.48), lineWidth: 1.2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
                    .padding(1)
            )
            .shadow(color: Color.black.opacity(0.26), radius: 26, x: 0, y: 16)
    }

    private func toggleMode() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            widgetMode = widgetMode == .usage ? .balance : .usage
        }

        if widgetMode == .balance {
            appState.fetchBalance()
        }
    }

    private func tokenSegments(_ value: Int64) -> [String] {
        if value <= 0 {
            return ["0"]
        }
        if value > 999_999_999 {
            return [compactTokens(value)]
        }

        let raw = String(value)
        var segments: [String] = []
        var index = raw.endIndex

        while index > raw.startIndex {
            let start = raw.index(index, offsetBy: -3, limitedBy: raw.startIndex) ?? raw.startIndex
            segments.insert(String(raw[start..<index]), at: 0)
            index = start
        }

        return segments
    }

    private func compactTokens(_ value: Int64) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%.1fB", Double(value) / 1_000_000_000)
        }
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        return String(value)
    }

    private func trimBalance(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 8, let decimal = Double(trimmed) else {
            return trimmed.isEmpty ? "0" : trimmed
        }
        return String(format: "%.2f", decimal)
    }

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private enum WidgetMode: Equatable {
    case usage
    case balance
}

private struct WidgetDisplay {
    let segments: [String]
    let footer: String
    let identity: String
}

private struct NumberTile: View {
    let text: String
    let segmentCount: Int

    private var tileWidth: CGFloat {
        switch segmentCount {
        case 1:
            return 154
        case 2:
            return 128
        default:
            return 96
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: segmentCount == 1 ? 66 : 62, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.42)
            .foregroundStyle(Color.white.opacity(0.86))
            .frame(width: tileWidth, height: 78)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.22, blue: 0.31).opacity(0.38))
            )
            .contentTransition(.numericText())
    }
}

private struct WidgetClickLayer: NSViewRepresentable {
    let selectedSpan: TimeSpan
    let language: AppLanguage
    let onPressChanged: (Bool) -> Void
    let onSingleClick: () -> Void
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
        private var singleClickWorkItem: DispatchWorkItem?

        init(parent: WidgetClickLayer) {
            self.parent = parent
        }

        func pressChanged(_ pressed: Bool) {
            parent.onPressChanged(pressed)
        }

        func scheduleSingleClick() {
            singleClickWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.parent.onSingleClick()
            }
            singleClickWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + NSEvent.doubleClickInterval, execute: workItem)
        }

        func doubleClick() {
            singleClickWorkItem?.cancel()
            parent.onPressChanged(false)
            parent.onDoubleClick()
        }

        func showMenu(from view: NSView, at point: NSPoint) {
            singleClickWorkItem?.cancel()
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
        private var suppressNextMouseUp = false

        override var acceptsFirstResponder: Bool {
            true
        }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount >= 2 {
                suppressNextMouseUp = true
                coordinator?.doubleClick()
                return
            }
            coordinator?.pressChanged(true)
        }

        override func mouseUp(with event: NSEvent) {
            coordinator?.pressChanged(false)
            if suppressNextMouseUp {
                suppressNextMouseUp = false
                return
            }
            if event.clickCount >= 2 {
                coordinator?.doubleClick()
            } else {
                coordinator?.scheduleSingleClick()
            }
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
