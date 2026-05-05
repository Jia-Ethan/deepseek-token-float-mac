import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel?
    private let appState = AppState.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildApplicationMenu()
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
        let panelSize = NSSize(width: 344, height: 372)
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
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()

        appMenu.addItem(
            NSMenuItem(
                title: "Settings...",
                action: #selector(openSettings),
                keyEquivalent: ","
            )
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit DeepSeek Token Monitor",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show(appState: appState)
    }
}
