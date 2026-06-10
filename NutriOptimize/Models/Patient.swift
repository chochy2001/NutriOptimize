import Foundation

/// Clinical patient profile with anthropometric data and dietary constraints.
/// The optimization engine uses these fields to calculate macro distributions
/// and filter out contraindicated ingredients.
struct Patient: Identifiable, Codable, Hashable {
    let id: UUID
    var fullName: String
    var age: Int
    var sex: BiologicalSex
    var weight: Double
    var height: Double
    var bodyFatPercentage: Double?
    var allergies: [String]
    var medicalConditions: [String]
    var dietaryPreferences: [String]
    var clinicalGoals: String
    var availableCookingTime: Int
    var activityLevel: ActivityLevel
    var monthlyFoodBudget: Double? = nil

    /// Weekly budget derived from the monthly allocation, used for per-week plan costing.
    var weeklyFoodBudget: Double? {
        guard let monthly = monthlyFoodBudget else { return nil }
        return monthly / 4.0
    }

    enum BiologicalSex: String, Codable, CaseIterable {
        case female = "Femenino"
        case male = "Masculino"
    }

    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentario"
        case lightlyActive = "Actividad ligera"
        case moderatelyActive = "Actividad moderada"
        case veryActive = "Muy activo"
        case athlete = "Atleta"

        /// Multiplier applied to BMR for TDEE estimation.
        var palFactor: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .athlete: return 1.9
            }
        }
    }

    // MARK: - Computed Anthropometric Values

    var bmi: Double {
        let h = height / 100.0
        guard h > 0 else { return 0 }
        return weight / (h * h)
    }

    var bmiClassification: String {
        switch bmi {
        case ..<18.5: return "Bajo peso"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Sobrepeso"
        default: return "Obesidad"
        }
    }

    /// Basal metabolic rate using Mifflin-St Jeor equation.
    var estimatedBMR: Double {
        let base = (10 * weight) + (6.25 * height) - (5 * Double(age))
        return sex == .male ? base + 5 : base - 161
    }

    var estimatedTDEE: Double {
        estimatedBMR * activityLevel.palFactor
    }

    // MARK: - Privacy

    /// A non-identifying reference for the patient, used when sending the
    /// clinical profile to an external optimization engine. We transmit the
    /// patient's initials (e.g. "C.R.V.") rather than the full name so that
    /// personally identifiable information stays on the device.
    var pseudonym: String {
        let initials = fullName
            .split(whereSeparator: { $0 == " " })
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined(separator: ".")
        return initials.isEmpty ? "Paciente" : initials + "."
    }
}
