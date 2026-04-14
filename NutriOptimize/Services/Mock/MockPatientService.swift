import Foundation

final class MockPatientService: PatientServiceProtocol {

    static let samplePatients: [Patient] = [
        Patient(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            fullName: "María García López",
            age: 35,
            sex: .female,
            weight: 68.5,
            height: 162,
            bodyFatPercentage: 32,
            allergies: ["Gluten", "Mariscos"],
            medicalConditions: ["Hipotiroidismo"],
            dietaryPreferences: ["Comida mexicana", "Ensaladas"],
            clinicalGoals: "Pérdida de peso gradual y mejora de energía",
            availableCookingTime: 30,
            activityLevel: .lightlyActive,
            monthlyFoodBudget: 4500
        ),
        Patient(
            id: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!,
            fullName: "Carlos Rodríguez Vega",
            age: 52,
            sex: .male,
            weight: 92.0,
            height: 178,
            bodyFatPercentage: 28,
            allergies: ["Lactosa"],
            medicalConditions: ["Diabetes tipo 2", "Hipertensión"],
            dietaryPreferences: ["Pollo", "Arroz", "Verduras al vapor"],
            clinicalGoals: "Control de glucosa y reducción de peso",
            availableCookingTime: 45,
            activityLevel: .sedentary,
            monthlyFoodBudget: 6000
        ),
        Patient(
            id: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!,
            fullName: "Ana Martínez Ruiz",
            age: 24,
            sex: .female,
            weight: 55.0,
            height: 165,
            bodyFatPercentage: 18,
            allergies: [],
            medicalConditions: [],
            dietaryPreferences: ["Mediterránea", "Frutas", "Pescado"],
            clinicalGoals: "Ganancia de masa muscular para rendimiento deportivo",
            availableCookingTime: 60,
            activityLevel: .veryActive
        ),
        Patient(
            id: UUID(uuidString: "D4E5F6A7-B8C9-0123-DEFA-234567890123")!,
            fullName: "Roberto Hernández Díaz",
            age: 45,
            sex: .male,
            weight: 105.3,
            height: 175,
            bodyFatPercentage: 35,
            allergies: ["Nueces", "Soya"],
            medicalConditions: ["Hígado graso"],
            dietaryPreferences: ["Carnes magras", "Ensaladas"],
            clinicalGoals: "Reducción de grasa hepática y pérdida de 15 kg",
            availableCookingTime: 20,
            activityLevel: .lightlyActive
        ),
        Patient(
            id: UUID(uuidString: "E5F6A7B8-C9D0-1234-EFAB-345678901234")!,
            fullName: "Laura Sánchez Flores",
            age: 30,
            sex: .female,
            weight: 62.0,
            height: 158,
            bodyFatPercentage: 25,
            allergies: ["Huevo"],
            medicalConditions: ["Síndrome de intestino irritable"],
            dietaryPreferences: ["Comida baja en FODMAP", "Sopas"],
            clinicalGoals: "Reducir síntomas digestivos y mantener peso estable",
            availableCookingTime: 40,
            activityLevel: .moderatelyActive
        )
    ]

    func fetchPatients() async throws -> [Patient] {
        try await Task.sleep(for: .milliseconds(600))
        return Self.samplePatients
    }

    func fetchPatient(id: UUID) async throws -> Patient {
        try await Task.sleep(for: .milliseconds(300))
        guard let patient = Self.samplePatients.first(where: { $0.id == id }) else {
            throw ServiceError.notFound
        }
        return patient
    }
}
