import Foundation

enum ServiceError: LocalizedError, Equatable {
    case notFound
    case networkFailure
    case invalidData
    case optimizationFailed
    case consentRequired

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "El recurso solicitado no fue encontrado."
        case .networkFailure:
            return "Error de conexión. Verifica tu red e intenta de nuevo."
        case .invalidData:
            return "Los datos recibidos no son válidos."
        case .optimizationFailed:
            return "No fue posible generar la propuesta. Intenta de nuevo."
        case .consentRequired:
            return "Debes aceptar el aviso de tratamiento de datos antes de enviar información clínica al motor de optimización."
        }
    }
}
