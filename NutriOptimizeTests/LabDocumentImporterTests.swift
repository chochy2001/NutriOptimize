import XCTest
@testable import NutriOptimize

/// Exercises the real lab-import pipeline through its public entry point
/// (`importFile(at:)`) using on-disk fixtures. This drives the JSON decoder,
/// the `checkOutOfRange` range logic, and the file-type dispatch without
/// touching production code. Clinical risk: a broken range check silently
/// mislabels an out-of-range lab value as normal.
final class LabDocumentImporterTests: XCTestCase {

    private var tempDir: URL!
    private let importer = LabDocumentImporter()

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LabImportTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
    }

    private func writeFixture(_ contents: String, ext: String) throws -> URL {
        let url = tempDir.appendingPathComponent("fixture.\(ext)")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - File type dispatch

    func testUnsupportedExtensionThrows() throws {
        let url = try writeFixture("irrelevant", ext: "txt")
        XCTAssertThrowsError(try importer.importFile(at: url)) { error in
            XCTAssertEqual(error as? LabDocumentImporter.ImportError, .unsupportedFormat)
        }
    }

    func testNoExtensionThrowsUnsupported() throws {
        let url = tempDir.appendingPathComponent("fixture")
        try "irrelevant".write(to: url, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try importer.importFile(at: url)) { error in
            XCTAssertEqual(error as? LabDocumentImporter.ImportError, .unsupportedFormat)
        }
    }

    // MARK: - JSON happy path

    func testJSONImportParsesAllFields() throws {
        let json = """
        [
          {"test": "Glucosa", "value": 95, "unit": "mg/dL", "date": "2024-01-15", "reference_range": "70-100"}
        ]
        """
        let url = try writeFixture(json, ext: "json")
        let results = try importer.importFile(at: url)

        XCTAssertEqual(results.count, 1)
        let r = try XCTUnwrap(results.first)
        XCTAssertEqual(r.testName, "Glucosa")
        XCTAssertEqual(r.value, 95, accuracy: 0.0001)
        XCTAssertEqual(r.unit, "mg/dL")
        XCTAssertEqual(r.referenceRange, "70-100")
        XCTAssertFalse(r.isOutOfRange, "95 is inside 70-100")
        XCTAssertTrue(r.isSelected, "Parsed results default to selected")
    }

    func testJSONImportParsesExplicitDate() throws {
        let json = #"[{"test":"HbA1c","value":5.4,"unit":"%","date":"2023-11-02"}]"#
        let url = try writeFixture(json, ext: "json")
        let r = try XCTUnwrap(try importer.importFile(at: url).first)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let comps = cal.dateComponents([.year, .month, .day], from: r.date)
        XCTAssertEqual(comps.year, 2023)
        XCTAssertEqual(comps.month, 11)
        XCTAssertEqual(comps.day, 2)
    }

    func testJSONImportFallsBackToNowForInvalidOrMissingDate() throws {
        let json = #"[{"test":"Colesterol","value":180,"unit":"mg/dL"}]"#
        let url = try writeFixture(json, ext: "json")
        let before = Date.now
        let r = try XCTUnwrap(try importer.importFile(at: url).first)
        // Missing date falls back to Date.now, so it must be very recent.
        XCTAssertGreaterThanOrEqual(r.date.timeIntervalSince1970, before.timeIntervalSince1970 - 5)
    }

    // MARK: - checkOutOfRange via reference strings

    func testRangeLowHigh_belowLowIsOutOfRange() throws {
        let json = #"[{"test":"Hierro","value":40,"unit":"ug/dL","reference_range":"60-170"}]"#
        let r = try XCTUnwrap(try importer.importFile(at: writeFixture(json, ext: "json")).first)
        XCTAssertTrue(r.isOutOfRange, "40 is below the 60-170 range")
    }

    func testRangeLowHigh_aboveHighIsOutOfRange() throws {
        let json = #"[{"test":"Glucosa","value":140,"unit":"mg/dL","reference_range":"70-100"}]"#
        let r = try XCTUnwrap(try importer.importFile(at: writeFixture(json, ext: "json")).first)
        XCTAssertTrue(r.isOutOfRange, "140 exceeds the 70-100 range")
    }

    func testRangeLowHigh_boundaryValuesAreInRange() throws {
        let json = """
        [
          {"test":"Low","value":70,"unit":"mg/dL","reference_range":"70-100"},
          {"test":"High","value":100,"unit":"mg/dL","reference_range":"70-100"}
        ]
        """
        let results = try importer.importFile(at: writeFixture(json, ext: "json"))
        XCTAssertEqual(results.count, 2)
        XCTAssertFalse(results[0].isOutOfRange, "70 is the inclusive lower bound")
        XCTAssertFalse(results[1].isOutOfRange, "100 is the inclusive upper bound")
    }

    func testLessThanReference() throws {
        let json = """
        [
          {"test":"LDL_ok","value":90,"unit":"mg/dL","reference_range":"< 100"},
          {"test":"LDL_high","value":100,"unit":"mg/dL","reference_range":"< 100"}
        ]
        """
        let results = try importer.importFile(at: writeFixture(json, ext: "json"))
        XCTAssertFalse(results[0].isOutOfRange, "90 < 100 is in range")
        XCTAssertTrue(results[1].isOutOfRange, "100 is not strictly < 100")
    }

    func testGreaterThanReference() throws {
        let json = """
        [
          {"test":"HDL_ok","value":60,"unit":"mg/dL","reference_range":"> 50"},
          {"test":"HDL_low","value":50,"unit":"mg/dL","reference_range":"> 50"}
        ]
        """
        let results = try importer.importFile(at: writeFixture(json, ext: "json"))
        XCTAssertFalse(results[0].isOutOfRange, "60 > 50 is in range")
        XCTAssertTrue(results[1].isOutOfRange, "50 is not strictly > 50")
    }

    func testDecimalRangeParsesCorrectly() throws {
        let json = #"[{"test":"TSH","value":2.5,"unit":"uUI/mL","reference_range":"0.4-4.0"}]"#
        let r = try XCTUnwrap(try importer.importFile(at: writeFixture(json, ext: "json")).first)
        XCTAssertFalse(r.isOutOfRange, "2.5 is within 0.4-4.0")
    }

    func testEmptyReferenceRangeIsNeverOutOfRange() throws {
        let json = #"[{"test":"Custom","value":9999,"unit":"x","reference_range":""}]"#
        let r = try XCTUnwrap(try importer.importFile(at: writeFixture(json, ext: "json")).first)
        XCTAssertFalse(r.isOutOfRange, "No reference range means we cannot flag it")
    }

    func testUnparseableReferenceRangeIsNotOutOfRange() throws {
        let json = #"[{"test":"Note","value":5,"unit":"x","reference_range":"consultar médico"}]"#
        let r = try XCTUnwrap(try importer.importFile(at: writeFixture(json, ext: "json")).first)
        XCTAssertFalse(r.isOutOfRange, "A non-numeric range cannot be evaluated")
    }

    func testExplicitIsOutOfRangeOverridesReferenceCheck() throws {
        // Value 95 sits inside 70-100, but the payload asserts it is out of range;
        // the explicit flag must win.
        let json = #"[{"test":"Flagged","value":95,"unit":"mg/dL","reference_range":"70-100","is_out_of_range":true}]"#
        let r = try XCTUnwrap(try importer.importFile(at: writeFixture(json, ext: "json")).first)
        XCTAssertTrue(r.isOutOfRange, "Explicit is_out_of_range=true overrides the computed check")
    }

    // MARK: - JSON error paths

    func testEmptyJSONArrayThrowsNoResults() throws {
        let url = try writeFixture("[]", ext: "json")
        XCTAssertThrowsError(try importer.importFile(at: url)) { error in
            XCTAssertEqual(error as? LabDocumentImporter.ImportError, .noResultsFound)
        }
    }

    func testMalformedJSONThrows() throws {
        let url = try writeFixture("{ this is not valid json", ext: "json")
        XCTAssertThrowsError(try importer.importFile(at: url),
                             "A decoding error must propagate, not be swallowed")
    }

    func testMultipleEntriesAllParsed() throws {
        let json = """
        [
          {"test":"Glucosa","value":95,"unit":"mg/dL","reference_range":"70-100"},
          {"test":"Colesterol","value":210,"unit":"mg/dL","reference_range":"< 200"},
          {"test":"HDL","value":45,"unit":"mg/dL","reference_range":"> 50"}
        ]
        """
        let results = try importer.importFile(at: writeFixture(json, ext: "json"))
        XCTAssertEqual(results.count, 3)
        XCTAssertFalse(results[0].isOutOfRange)
        XCTAssertTrue(results[1].isOutOfRange, "210 exceeds < 200")
        XCTAssertTrue(results[2].isOutOfRange, "45 is not > 50")
    }

    // MARK: - Error descriptions (LocalizedError)

    func testImportErrorDescriptionsAreLocalized() {
        XCTAssertEqual(LabDocumentImporter.ImportError.unsupportedFormat.errorDescription,
                       "Formato de archivo no compatible. Usa PDF o JSON.")
        XCTAssertEqual(LabDocumentImporter.ImportError.unreadableFile.errorDescription,
                       "No se pudo leer el archivo. Verifica que no esté dañado.")
        XCTAssertEqual(LabDocumentImporter.ImportError.noResultsFound.errorDescription,
                       "No se encontraron resultados de laboratorio en el archivo.")
    }
}
