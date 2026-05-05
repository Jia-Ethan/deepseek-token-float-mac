import Combine
import SwiftUI

/// Coordinates theme transitions across the app.
/// The primary theme state lives on AppState.theme; this manager
/// watches changes and applies system-level coordination.
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var currentTheme: AppTheme = .default

    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func bind(to appState: AppState) {
        appState.$theme
            .dropFirst()
            .sink { [weak self] theme in
                guard let self else { return }
                withAnimation(AppAnimation.themeTransition) {
                    self.currentTheme = theme
                }
            }
            .store(in: &cancellables)

        // Initial sync
        currentTheme = appState.theme
    }
}
