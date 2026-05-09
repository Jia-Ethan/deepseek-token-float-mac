import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel?
    private var statusItem: NSStatusItem?
    private let appState = AppState.shared
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildApplicationMenu()
        buildStatusItem()
        observeLanguageChanges()
        showFloatingPanel()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private var isFloatingPanelVisible: Bool {
        panel?.isVisible == true
    }

    private func showFloatingPanel() {
        if let panel {
            panel.orderFrontRegardless()
            rebuildStatusMenu()
            return
        }

        let contentView = FloatingCardView()
            .environmentObject(appState)

        let hostingController = NSHostingController(rootView: contentView)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panelSize = NSSize(width: 640, height: 430)
        let origin = NSPoint(
            x: screenFrame.maxX - panelSize.width - 28,
            y: screenFrame.maxY - panelSize.height - 28
        )

        let panel = FloatingPanel(
            contentRect: NSRect(origin: origin, size: panelSize),
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.orderFrontRegardless()
        self.panel = panel
        rebuildStatusMenu()
    }

    private func hideFloatingPanel() {
        panel?.orderOut(nil)
        rebuildStatusMenu()
    }

    private func buildStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.toolTip = appState.strings.statusItemAccessibilityLabel
            button.setAccessibilityLabel(appState.strings.statusItemAccessibilityLabel)
            if let image = NSImage(
                systemSymbolName: "chart.bar.xaxis",
                accessibilityDescription: appState.strings.statusItemAccessibilityLabel
            ) {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "DS"
            }
        }

        self.statusItem = statusItem
        rebuildStatusMenu()
    }

    private func rebuildStatusMenu() {
        guard let statusItem else {
            return
        }

        let strings = appState.strings
        let menu = NSMenu()
        statusItem.button?.toolTip = strings.statusItemAccessibilityLabel
        statusItem.button?.setAccessibilityLabel(strings.statusItemAccessibilityLabel)

        let widgetItem = NSMenuItem(
            title: isFloatingPanelVisible ? strings.hideWidgetMenuTitle : strings.showWidgetMenuTitle,
            action: #selector(toggleFloatingPanel),
            keyEquivalent: ""
        )
        widgetItem.target = self
        menu.addItem(widgetItem)

        let refreshItem = NSMenuItem(
            title: strings.refreshBalanceMenuTitle,
            action: #selector(refreshBalance),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        refreshItem.isEnabled = appState.apiKeySaved
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: strings.settingsMenuTitle,
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: strings.quitMenuTitle,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func buildApplicationMenu() {
        let strings = appState.strings
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: strings.editMenuTitle)

        appMenu.addItem(
            NSMenuItem(
                title: strings.settingsMenuTitle,
                action: #selector(openSettings),
                keyEquivalent: ","
            )
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: strings.quitMenuTitle,
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        editMenu.addItem(
            NSMenuItem(
                title: strings.cutMenuTitle,
                action: #selector(NSText.cut(_:)),
                keyEquivalent: "x"
            )
        )
        editMenu.addItem(
            NSMenuItem(
                title: strings.copyMenuTitle,
                action: #selector(NSText.copy(_:)),
                keyEquivalent: "c"
            )
        )
        editMenu.addItem(
            NSMenuItem(
                title: strings.pasteMenuTitle,
                action: #selector(NSText.paste(_:)),
                keyEquivalent: "v"
            )
        )
        editMenu.addItem(.separator())
        editMenu.addItem(
            NSMenuItem(
                title: strings.selectAllMenuTitle,
                action: #selector(NSText.selectAll(_:)),
                keyEquivalent: "a"
            )
        )

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func toggleFloatingPanel() {
        if isFloatingPanelVisible {
            hideFloatingPanel()
        } else {
            showFloatingPanel()
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show(appState: appState)
    }

    @objc private func refreshBalance() {
        appState.fetchBalance()
    }

    private func observeLanguageChanges() {
        appState.$language
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                buildApplicationMenu()
                rebuildStatusMenu()
                SettingsWindowController.shared.updateTitle(appState: appState)
            }
            .store(in: &cancellables)

        appState.$apiKeySaved
            .dropFirst()
            .sink { [weak self] _ in
                self?.rebuildStatusMenu()
            }
            .store(in: &cancellables)
    }
}
