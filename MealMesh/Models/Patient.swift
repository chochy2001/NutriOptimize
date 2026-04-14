import Foundation

struct Patient: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var weight: Double
    var height: Double
    var allergies: [String]
    var conditions: [String]
    var preferences: [String]
    var goals: String
    var cookingTime: Int

    var bmi: Double {
        let heightInMeters = height / 100.0
        guard heightInMeters > 0 else { return 0 }
        return weight / (heightInMeters * heightInMeters)
    }

    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Bajo peso"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Sobrepeso"
        default: return "Obesidad"
        }
    }
}
