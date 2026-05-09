import AppKit
import Foundation

struct AppPreferences: Equatable {
    var keepsPanelOnTop: Bool
    var panelVisible: Bool
    var panelOrigin: NSPoint?

    static func saved(defaults: UserDefaults = .standard) -> AppPreferences {
        let keepsPanelOnTop = defaults.object(forKey: UserDefaultsKeys.keepsPanelOnTop) as? Bool ?? true
        let panelVisible = defaults.object(forKey: UserDefaultsKeys.panelVisible) as? Bool ?? true
        let panelOrigin: NSPoint?

        if defaults.object(forKey: UserDefaultsKeys.panelOriginX) != nil,
           defaults.object(forKey: UserDefaultsKeys.panelOriginY) != nil {
            panelOrigin = NSPoint(
                x: defaults.double(forKey: UserDefaultsKeys.panelOriginX),
                y: defaults.double(forKey: UserDefaultsKeys.panelOriginY)
            )
        } else {
            panelOrigin = nil
        }

        return AppPreferences(
            keepsPanelOnTop: keepsPanelOnTop,
            panelVisible: panelVisible,
            panelOrigin: panelOrigin
        )
    }

    func save(defaults: UserDefaults = .standard) {
        defaults.set(keepsPanelOnTop, forKey: UserDefaultsKeys.keepsPanelOnTop)
        defaults.set(panelVisible, forKey: UserDefaultsKeys.panelVisible)

        if let panelOrigin {
            defaults.set(panelOrigin.x, forKey: UserDefaultsKeys.panelOriginX)
            defaults.set(panelOrigin.y, forKey: UserDefaultsKeys.panelOriginY)
        } else {
            defaults.removeObject(forKey: UserDefaultsKeys.panelOriginX)
            defaults.removeObject(forKey: UserDefaultsKeys.panelOriginY)
        }
    }
}
