import Foundation

protocol PatientServiceProtocol: Sendable {
    func fetchPatients() async throws -> [Patient]
    func fetchPatient(id: UUID) async throws -> Patient
}
