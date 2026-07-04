import XCTest
@testable import NutriOptimize

/// Verifies the localized, user-facing descriptions of `ServiceError`. These
/// strings are shown directly to the professional, so a regression is a
/// visible defect.
final class ServiceErrorTests: XCTestCase {

    func testAllCasesHaveNonEmptyDescriptions() {
        let cases: [ServiceError] = [.notFound, .networkFailure, .invalidData,
                                     .optimizationFailed, .consentRequired]
        for error in cases {
            let description = error.errorDescription
            XCTAssertNotNil(description)
            XCTAssertFalse(description?.isEmpty ?? true, "\(error) must have a description")
        }
    }

    func testSpecificDescriptions() {
        XCTAssertEqual(ServiceError.notFound.errorDescription,
                       "El recurso solicitado no fue encontrado.")
        XCTAssertEqual(ServiceError.networkFailure.errorDescription,
                       "Error de conexión. Verifica tu red e intenta de nuevo.")
        XCTAssertEqual(ServiceError.invalidData.errorDescription,
                       "Los datos recibidos no son válidos.")
        XCTAssertEqual(ServiceError.optimizationFailed.errorDescription,
                       "No fue posible generar la propuesta. Intenta de nuevo.")
    }

    func testConsentRequiredMentionsDataProcessing() {
        let description = ServiceError.consentRequired.errorDescription ?? ""
        XCTAssertTrue(description.contains("tratamiento de datos"),
                      "Consent error must reference the data-processing notice")
    }

    func testEquatableConformance() {
        XCTAssertEqual(ServiceError.notFound, ServiceError.notFound)
        XCTAssertNotEqual(ServiceError.notFound, ServiceError.networkFailure)
    }
}
