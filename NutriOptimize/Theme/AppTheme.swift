import SwiftUI

/// Centralized design tokens for NutriOptimize.
/// Keeps visual consistency across the entire application.
enum AppTheme {
    // MARK: - Brand Colors
    static let primaryOrange = Color("PrimaryOrange", bundle: .main)
    static let deepOrange = Color(red: 0.90, green: 0.42, blue: 0.14)
    static let warmOrange = Color(red: 1.0, green: 0.60, blue: 0.20)
    static let lightOrange = Color("LightOrangeBackground", bundle: .main)
    static let surface = Color("Surface", bundle: .main)
    /// Backward-compatible alias used across dashboard and list backgrounds.
    static let surfaceWhite = surface
    static let cardBackground = Color("CardBackground", bundle: .main)

    // MARK: - Semantic Colors
    static let success = Color(red: 0.20, green: 0.72, blue: 0.40)
    static let warning = Color(red: 0.95, green: 0.75, blue: 0.15)
    static let danger = Color(red: 0.90, green: 0.25, blue: 0.20)
    static let info = Color(red: 0.22, green: 0.56, blue: 0.88)

    // MARK: - Macro Colors
    static let calorieColor = Color(red: 1.0, green: 0.52, blue: 0.10)
    static let proteinColor = Color(red: 0.85, green: 0.22, blue: 0.20)
    static let carbColor = Color(red: 0.22, green: 0.56, blue: 0.88)
    static let fatColor = Color(red: 0.95, green: 0.75, blue: 0.15)

    // MARK: - Typography
    static let headlineFont = Font.system(.title2, design: .rounded, weight: .bold)
    static let subheadFont = Font.system(.subheadline, design: .rounded, weight: .semibold)
    static let captionFont = Font.system(.caption, design: .rounded)

    // MARK: - Layout
    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
}

// MARK: - Reusable Card Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppTheme.cardPadding

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(
                color: Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.04),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = AppTheme.cardPadding) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
