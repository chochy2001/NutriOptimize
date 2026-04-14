import Foundation

/// Represents the licensed nutrition professional using the platform.
/// Credentials and system preferences drive how the optimization engine
/// weights its recommendations for each patient.
struct Professional: Identifiable, Codable {
    let id: UUID
    var fullName: String
    var licenseNumber: String
    var specialty: Specialty
    var systemPreferences: SystemPreferences

    enum Specialty: String, Codable, CaseIterable {
        case clinicalNutrition = "Nutrición Clínica"
        case sportsNutrition = "Nutrición Deportiva"
        case pediatricNutrition = "Nutrición Pediátrica"
        case bariatric = "Nutrición Bariátrica"
        case generalPractice = "Práctica General"
    }

    struct SystemPreferences: Codable {
        var defaultMealCount: Int
        var preferMetricSystem: Bool
        var autoGenerateRationale: Bool

        static let defaults = SystemPreferences(
            defaultMealCount: 4,
            preferMetricSystem: true,
            autoGenerateRationale: true
        )
    }
}
