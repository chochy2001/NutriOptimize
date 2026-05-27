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

    /// Localized label for the appearance picker (EN/ES via Localizable.strings).
    var localizedLabel: String {
        switch self {
        case .system: return L10n.appearanceSystem
        case .light: return L10n.appearanceLight
        case .dark: return L10n.appearanceDark
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
