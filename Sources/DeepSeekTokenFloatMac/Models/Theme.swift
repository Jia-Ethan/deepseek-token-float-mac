import SwiftUI

// MARK: - Theme Mode

enum ThemeMode: String, CaseIterable, Codable {
    case dark
    case light
}

// MARK: - Glass Configuration

struct GlassConfig: Equatable {
    let baseMaterial: MaterialStyle
    let gradientColors: [Color]
    let gradientOpacity: Double
    let noiseOpacity: Double
    let innerGlowColor: Color
    let innerGlowRadius: CGFloat
    let borderLightColor: Color
    let borderLightOpacity: Double
    let sweepColor: Color
    let sweepOpacity: Double

    enum MaterialStyle: String, Equatable {
        case ultraThin
        case regular
        case thick
    }
}

// MARK: - App Theme

struct AppTheme: Equatable, Identifiable {
    let id: String
    let name: String
    let mode: ThemeMode
    let glass: GlassConfig
    let accent: Color
    let accentSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let tileBackground: Color
    let tileBorder: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    let cardCornerRadius: CGFloat

    // MARK: - Static Presets

    static let deepOcean = AppTheme(
        id: "deepOcean",
        name: "Deep Ocean",
        mode: .dark,
        glass: GlassConfig(
            baseMaterial: .ultraThin,
            gradientColors: [
                Color(red: 0.14, green: 0.28, blue: 0.38),
                Color(red: 0.08, green: 0.20, blue: 0.30)
            ],
            gradientOpacity: 0.90,
            noiseOpacity: 0.04,
            innerGlowColor: Color(red: 0.63, green: 0.78, blue: 0.91),
            innerGlowRadius: 24,
            borderLightColor: Color(red: 0.63, green: 0.78, blue: 0.91),
            borderLightOpacity: 0.48,
            sweepColor: Color(red: 0.75, green: 0.88, blue: 0.98),
            sweepOpacity: 0.12
        ),
        accent: Color(red: 0.63, green: 0.78, blue: 0.91),
        accentSecondary: Color(red: 0.40, green: 0.60, blue: 0.78),
        textPrimary: Color.white.opacity(0.86),
        textSecondary: Color.white.opacity(0.78),
        tileBackground: Color(red: 0.08, green: 0.22, blue: 0.31).opacity(0.38),
        tileBorder: Color.white.opacity(0.08),
        shadowColor: Color.black.opacity(0.26),
        shadowRadius: 26,
        cardCornerRadius: 36
    )

    static let auroraNight = AppTheme(
        id: "auroraNight",
        name: "Aurora Night",
        mode: .dark,
        glass: GlassConfig(
            baseMaterial: .ultraThin,
            gradientColors: [
                Color(red: 0.18, green: 0.12, blue: 0.38),
                Color(red: 0.10, green: 0.08, blue: 0.28)
            ],
            gradientOpacity: 0.90,
            noiseOpacity: 0.05,
            innerGlowColor: Color(red: 0.50, green: 1.0, blue: 0.83),
            innerGlowRadius: 28,
            borderLightColor: Color(red: 0.50, green: 1.0, blue: 0.83),
            borderLightOpacity: 0.42,
            sweepColor: Color(red: 0.60, green: 1.0, blue: 0.90),
            sweepOpacity: 0.14
        ),
        accent: Color(red: 0.50, green: 1.0, blue: 0.83),
        accentSecondary: Color(red: 0.30, green: 0.75, blue: 0.60),
        textPrimary: Color.white.opacity(0.86),
        textSecondary: Color.white.opacity(0.78),
        tileBackground: Color(red: 0.10, green: 0.06, blue: 0.28).opacity(0.42),
        tileBorder: Color.white.opacity(0.08),
        shadowColor: Color.black.opacity(0.28),
        shadowRadius: 26,
        cardCornerRadius: 36
    )

    static let starlight = AppTheme(
        id: "starlight",
        name: "Starlight",
        mode: .light,
        glass: GlassConfig(
            baseMaterial: .regular,
            gradientColors: [
                Color(red: 0.96, green: 0.94, blue: 0.90),
                Color(red: 0.90, green: 0.88, blue: 0.84)
            ],
            gradientOpacity: 0.88,
            noiseOpacity: 0.035,
            innerGlowColor: Color(red: 0.96, green: 0.65, blue: 0.14),
            innerGlowRadius: 20,
            borderLightColor: Color(red: 0.96, green: 0.65, blue: 0.14),
            borderLightOpacity: 0.38,
            sweepColor: Color.white,
            sweepOpacity: 0.10
        ),
        accent: Color(red: 0.96, green: 0.65, blue: 0.14),
        accentSecondary: Color(red: 0.80, green: 0.50, blue: 0.08),
        textPrimary: Color(red: 0.18, green: 0.18, blue: 0.20),
        textSecondary: Color(red: 0.30, green: 0.30, blue: 0.34),
        tileBackground: Color.white.opacity(0.55),
        tileBorder: Color.black.opacity(0.06),
        shadowColor: Color.black.opacity(0.14),
        shadowRadius: 20,
        cardCornerRadius: 36
    )

    static let frostMorning = AppTheme(
        id: "frostMorning",
        name: "Frost Morning",
        mode: .light,
        glass: GlassConfig(
            baseMaterial: .regular,
            gradientColors: [
                Color(red: 0.88, green: 0.94, blue: 0.98),
                Color(red: 0.82, green: 0.90, blue: 0.96)
            ],
            gradientOpacity: 0.85,
            noiseOpacity: 0.03,
            innerGlowColor: Color(red: 0.29, green: 0.56, blue: 0.85),
            innerGlowRadius: 22,
            borderLightColor: Color(red: 0.29, green: 0.56, blue: 0.85),
            borderLightOpacity: 0.36,
            sweepColor: Color.white,
            sweepOpacity: 0.11
        ),
        accent: Color(red: 0.29, green: 0.56, blue: 0.85),
        accentSecondary: Color(red: 0.20, green: 0.40, blue: 0.70),
        textPrimary: Color(red: 0.15, green: 0.20, blue: 0.30),
        textSecondary: Color(red: 0.28, green: 0.34, blue: 0.42),
        tileBackground: Color.white.opacity(0.58),
        tileBorder: Color.black.opacity(0.05),
        shadowColor: Color.black.opacity(0.12),
        shadowRadius: 18,
        cardCornerRadius: 36
    )

    static let ember = AppTheme(
        id: "ember",
        name: "Ember",
        mode: .dark,
        glass: GlassConfig(
            baseMaterial: .ultraThin,
            gradientColors: [
                Color(red: 0.38, green: 0.18, blue: 0.10),
                Color(red: 0.28, green: 0.12, blue: 0.06)
            ],
            gradientOpacity: 0.92,
            noiseOpacity: 0.06,
            innerGlowColor: Color(red: 1.0, green: 0.55, blue: 0.26),
            innerGlowRadius: 26,
            borderLightColor: Color(red: 1.0, green: 0.55, blue: 0.26),
            borderLightOpacity: 0.44,
            sweepColor: Color(red: 1.0, green: 0.70, blue: 0.40),
            sweepOpacity: 0.15
        ),
        accent: Color(red: 1.0, green: 0.55, blue: 0.26),
        accentSecondary: Color(red: 0.85, green: 0.35, blue: 0.10),
        textPrimary: Color.white.opacity(0.86),
        textSecondary: Color.white.opacity(0.78),
        tileBackground: Color(red: 0.20, green: 0.10, blue: 0.06).opacity(0.42),
        tileBorder: Color.white.opacity(0.08),
        shadowColor: Color.black.opacity(0.28),
        shadowRadius: 26,
        cardCornerRadius: 36
    )

    static let midnight = AppTheme(
        id: "midnight",
        name: "Midnight",
        mode: .dark,
        glass: GlassConfig(
            baseMaterial: .ultraThin,
            gradientColors: [
                Color(red: 0.08, green: 0.08, blue: 0.14),
                Color(red: 0.04, green: 0.04, blue: 0.10)
            ],
            gradientOpacity: 0.94,
            noiseOpacity: 0.05,
            innerGlowColor: Color(red: 0.75, green: 0.75, blue: 0.82),
            innerGlowRadius: 20,
            borderLightColor: Color(red: 0.75, green: 0.75, blue: 0.82),
            borderLightOpacity: 0.36,
            sweepColor: Color(red: 0.55, green: 0.55, blue: 0.65),
            sweepOpacity: 0.10
        ),
        accent: Color(red: 0.75, green: 0.75, blue: 0.82),
        accentSecondary: Color(red: 0.55, green: 0.55, blue: 0.65),
        textPrimary: Color.white.opacity(0.86),
        textSecondary: Color.white.opacity(0.76),
        tileBackground: Color(red: 0.06, green: 0.06, blue: 0.12).opacity(0.40),
        tileBorder: Color.white.opacity(0.06),
        shadowColor: Color.black.opacity(0.30),
        shadowRadius: 28,
        cardCornerRadius: 36
    )

    static let allThemes: [AppTheme] = [
        .deepOcean, .auroraNight, .starlight, .frostMorning, .ember, .midnight
    ]

    static let `default`: AppTheme = .deepOcean
}

// MARK: - UserDefaults Persistence

extension AppTheme {
    private static let savedThemeKey = "appTheme"

    static func saved(defaults: UserDefaults = .standard) -> AppTheme {
        guard
            let rawID = defaults.string(forKey: savedThemeKey),
            let theme = allThemes.first(where: { $0.id == rawID })
        else {
            return .default
        }
        return theme
    }

    func save(defaults: UserDefaults = .standard) {
        defaults.set(id, forKey: AppTheme.savedThemeKey)
    }
}
