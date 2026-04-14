import Foundation

final class MockPatientService: PatientServiceProtocol {

    static let samplePatients: [Patient] = [
        Patient(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            name: "María García López",
            weight: 68.5,
            height: 162,
            allergies: ["Gluten", "Mariscos"],
            conditions: ["Hipotiroidismo"],
            preferences: ["Comida mexicana", "Ensaladas"],
            goals: "Pérdida de peso gradual y mejora de energía",
            cookingTime: 30
        ),
        Patient(
            id: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!,
            name: "Carlos Rodríguez Vega",
            weight: 92.0,
            height: 178,
            allergies: ["Lactosa"],
            conditions: ["Diabetes tipo 2", "Hipertensión"],
            preferences: ["Pollo", "Arroz", "Verduras al vapor"],
            goals: "Control de glucosa y reducción de peso",
            cookingTime: 45
        ),
        Patient(
            id: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!,
            name: "Ana Martínez Ruiz",
            weight: 55.0,
            height: 165,
            allergies: [],
            conditions: [],
            preferences: ["Mediterránea", "Frutas", "Pescado"],
            goals: "Ganancia de masa muscular para rendimiento deportivo",
            cookingTime: 60
        ),
        Patient(
            id: UUID(uuidString: "D4E5F6A7-B8C9-0123-DEFA-234567890123")!,
            name: "Roberto Hernández Díaz",
            weight: 105.3,
            height: 175,
            allergies: ["Nueces", "Soya"],
            conditions: ["Hígado graso"],
            preferences: ["Carnes magras", "Ensaladas"],
            goals: "Reducción de grasa hepática y pérdida de 15 kg",
            cookingTime: 20
        ),
        Patient(
            id: UUID(uuidString: "E5F6A7B8-C9D0-1234-EFAB-345678901234")!,
            name: "Laura Sánchez Flores",
            weight: 62.0,
            height: 158,
            allergies: ["Huevo"],
            conditions: ["Síndrome de intestino irritable"],
            preferences: ["Comida baja en FODMAP", "Sopas"],
            goals: "Reducir síntomas digestivos y mantener peso estable",
            cookingTime: 40
        )
    ]

    func fetchPatients() async throws -> [Patient] {
        // Simulates network latency for realistic UI behavior during development
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
