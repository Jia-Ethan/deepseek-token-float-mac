import AppKit
import SwiftUI

struct FloatingCardView: View {
    @EnvironmentObject private var appState: AppState

    @State private var widgetMode: WidgetMode = .usage
    @State private var isPressed = false
    @State private var rippleOrigin: CGPoint = .zero
    @State private var showRipple = false

    var body: some View {
        ZStack {
            // Dynamic background behind the glass
            ZStack {
                AnimatedGradientBackground(theme: appState.theme)
                ParticleField(theme: appState.theme)
            }
            .frame(width: 360, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: appState.theme.cardCornerRadius, style: .continuous))

            // Glass card wraps the content
            GlassCard(theme: appState.theme) {
                VStack(spacing: 18) {
                    Spacer(minLength: 0)
                    numberStrip
                    footer
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            // Click ripple overlay
            if showRipple {
                RippleEffect(origin: rippleOrigin, accent: appState.theme.accent)
            }
        }
        .frame(width: 360, height: 170)
        .scaleEffect(isPressed ? AppAnimation.pressScaleAmount : 1)
        .animation(AppAnimation.pressScale, value: isPressed)
        .animation(AppAnimation.themeTransition, value: widgetMode)
        .overlay(
            WidgetClickLayer(
                selectedSpan: appState.selectedSpan,
                language: appState.language,
                onPressChanged: { pressed in
                    withAnimation(AppAnimation.pressScale) {
                        isPressed = pressed
                    }
                },
                onSingleClick: toggleMode,
                onDoubleClick: {
                    SettingsWindowController.shared.show(appState: appState)
                },
                onSelectSpan: { span in
                    appState.selectedSpan = span
                    if widgetMode == .usage {
                        appState.reloadUsage()
                    }
                },
                onRippleAt: { point in
                    rippleOrigin = point
                    showRipple = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + AppAnimation.rippleDuration) {
                        showRipple = false
                    }
                }
            )
        )
        .help(appState.strings.widgetHelp)
    }

    // MARK: - Number Strip

    private var numberStrip: some View {
        HStack(spacing: 14) {
            ForEach(Array(display.segments.enumerated()), id: \.offset) { _, segment in
                NumberTile(
                    text: segment,
                    segmentCount: display.segments.count,
                    theme: appState.theme
                )
                .numberChangeAnimation(trigger: display.identity)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .id(display.identity)
    }

    // MARK: - Footer

    private var footer: some View {
        Text(display.footer)
            .font(.system(size: 19, weight: .semibold, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(appState.theme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .contentTransition(.opacity)
    }

    // MARK: - Display Logic (unchanged from original)

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

    // MARK: - Helpers

    private func toggleMode() {
        withAnimation(AppAnimation.themeTransition) {
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

// MARK: - Widget Mode

private enum WidgetMode: Equatable {
    case usage
    case balance
}

private struct WidgetDisplay {
    let segments: [String]
    let footer: String
    let identity: String
}

// MARK: - Enhanced Number Tile

private struct NumberTile: View {
    let text: String
    let segmentCount: Int
    let theme: AppTheme

    @State private var isHovering = false

    private var tileWidth: CGFloat {
        switch segmentCount {
        case 1:  return 154
        case 2:  return 128
        default: return 96
        }
    }

    var body: some View {
        Text(text)
            .font(.system(
                size: segmentCount == 1 ? 66 : 62,
                weight: .bold,
                design: .rounded
            ))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.42)
            .foregroundStyle(theme.textPrimary)
            .frame(width: tileWidth, height: 78)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.tileBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isHovering
                            ? theme.accent.opacity(0.35)
                            : theme.tileBorder,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: theme.accent.opacity(isHovering ? 0.12 : 0),
                radius: isHovering ? 8 : 0
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.22)) {
                    isHovering = hovering
                }
            }
    }
}

// MARK: - Click Ripple Effect

private struct RippleEffect: View {
    let origin: CGPoint
    let accent: Color

    @State private var scale: CGFloat = 0
    @State private var opacity: Double = AppAnimation.rippleStartOpacity

    var body: some View {
        Circle()
            .fill(accent.opacity(opacity))
            .frame(width: AppAnimation.rippleMaxRadius * 2, height: AppAnimation.rippleMaxRadius * 2)
            .scaleEffect(scale)
            .position(origin)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: AppAnimation.rippleDuration)) {
                    scale = 1.0
                    opacity = 0
                }
            }
    }
}

// MARK: - Widget Click Layer

private struct WidgetClickLayer: NSViewRepresentable {
    let selectedSpan: TimeSpan
    let language: AppLanguage
    let onPressChanged: (Bool) -> Void
    let onSingleClick: () -> Void
    let onDoubleClick: () -> Void
    let onSelectSpan: (TimeSpan) -> Void
    let onRippleAt: (CGPoint) -> Void

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

        func ripple(at point: NSPoint, in view: NSView) {
            let converted = view.convert(point, from: nil)
            parent.onRippleAt(CGPoint(x: converted.x, y: converted.y))
        }

        func scheduleSingleClick() {
            singleClickWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.parent.onSingleClick()
            }
            singleClickWorkItem = workItem
            DispatchQueue.main.asyncAfter(
                deadline: .now() + NSEvent.doubleClickInterval,
                execute: workItem
            )
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

        override var acceptsFirstResponder: Bool { true }

        override func mouseDown(with event: NSEvent) {
            coordinator?.ripple(at: event.locationInWindow, in: self)

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
