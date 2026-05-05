import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel?
    private let appState = AppState.shared
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildApplicationMenu()
        observeLanguageChanges()
        showFloatingPanel()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showFloatingPanel() {
        let contentView = FloatingCardView()
            .environmentObject(appState)

        let hostingController = NSHostingController(rootView: contentView)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panelSize = NSSize(width: 360, height: 170)
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

    @objc private func openSettings() {
        SettingsWindowController.shared.show(appState: appState)
    }

    private func observeLanguageChanges() {
        appState.$language
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                buildApplicationMenu()
                SettingsWindowController.shared.updateTitle(appState: appState)
            }
            .store(in: &cancellables)
    }
}
