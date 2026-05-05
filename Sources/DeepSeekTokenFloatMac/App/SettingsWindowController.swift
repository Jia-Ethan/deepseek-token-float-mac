import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func show(appState: AppState) {
        if let window {
            window.title = appState.strings.settingsWindowTitle
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = SettingsView()
            .environmentObject(appState)

        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = appState.strings.settingsWindowTitle
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 860))
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("DeepSeekTokenMonitorSettings")
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func updateTitle(appState: AppState) {
        window?.title = appState.strings.settingsWindowTitle
    }
}
