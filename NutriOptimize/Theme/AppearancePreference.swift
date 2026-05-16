import SwiftUI

/// User-facing appearance preference persisted in UserDefaults.
///
/// Three options keep parity with iOS system Settings: follow the device,
/// force light, or force dark. Stored as a string under
/// ``AppearancePreference/storageKey`` so the value remains stable across
/// app updates even if the enum cases change order.
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "colorScheme"

    var id: String { rawValue }

    /// SwiftUI ColorScheme to feed into `.preferredColorScheme`. Returning
    /// `nil` lets SwiftUI inherit the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Localized label for the picker. NutriOptimize ships Spanish UI today,
    /// so labels are kept in Spanish to match the rest of the app.
    var localizedLabel: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }

    /// SF Symbol used inside the picker rows.
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}
