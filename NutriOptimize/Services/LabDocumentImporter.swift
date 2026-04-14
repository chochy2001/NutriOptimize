import Foundation
import PDFKit
import UniformTypeIdentifiers

/// Imports laboratory results from PDF and JSON documents.
/// Extracts structured data from common lab report formats for review before saving.
final class LabDocumentImporter {

    /// Candidate result parsed from a document, pending user review.
    struct ParsedResult: Identifiable {
        let id = UUID()
        var testName: String
        var value: Double
        var unit: String
        var referenceRange: String
        var isOutOfRange: Bool
        var date: Date
        var isSelected: Bool = true
    }

    // MARK: - Public API

    /// Parses a file at the given URL and returns candidate lab results.
    /// Supports PDF (.pdf) and JSON (.json) file types.
    func importFile(at url: URL) throws -> [ParsedResult] {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        guard let utType = UTType(filenameExtension: url.pathExtension) else {
            throw ImportError.unsupportedFormat
        }

        if utType.conforms(to: .pdf) {
            return try parsePDF(at: url)
        } else if utType.conforms(to: .json) {
            return try parseJSON(at: url)
        } else {
            throw ImportError.unsupportedFormat
        }
    }

    // MARK: - PDF Parsing

    /// Extracts text from a PDF and searches for common lab result patterns.
    /// Handles formats like: "Glucosa    95    mg/dL    70-100"
    private func parsePDF(at url: URL) throws -> [ParsedResult] {
        guard let document = PDFDocument(url: url) else {
            throw ImportError.unreadableFile
        }

        var fullText = ""
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex),
                  let text = page.string else { continue }
            fullText += text + "\n"
        }

        guard !fullText.isEmpty else {
            throw ImportError.noResultsFound
        }

        return parseLabText(fullText)
    }

    /// Applies regex patterns to extract structured lab values from raw text.
    private func parseLabText(_ text: String) -> [ParsedResult] {
        var results: [ParsedResult] = []
        let lines = text.components(separatedBy: .newlines)
        let today = Date.now

        // Pattern: TestName ... Value Unit ReferenceRange
        // Matches lines like: "Glucosa en ayunas   95.0   mg/dL   70 - 100"
        let pattern = #"([A-ZÁÉÍÓÚa-záéíóú][\wÁÉÍÓÚáéíóú\s\-/]{2,40}?)\s{2,}(\d+\.?\d*)\s+([\w/%]+)\s+([\d.<>\-\s]+)"#

        let regex = try? NSRegularExpression(pattern: pattern, options: [])

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let range = NSRange(trimmed.startIndex..., in: trimmed)
            if let match = regex?.firstMatch(in: trimmed, range: range) {
                guard match.numberOfRanges >= 5,
                      let nameRange = Range(match.range(at: 1), in: trimmed),
                      let valueRange = Range(match.range(at: 2), in: trimmed),
                      let unitRange = Range(match.range(at: 3), in: trimmed),
                      let refRange = Range(match.range(at: 4), in: trimmed) else { continue }

                let testName = String(trimmed[nameRange]).trimmingCharacters(in: .whitespaces)
                guard let value = Double(String(trimmed[valueRange])) else { continue }
                let unit = String(trimmed[unitRange]).trimmingCharacters(in: .whitespaces)
                let reference = String(trimmed[refRange]).trimmingCharacters(in: .whitespaces)

                let outOfRange = checkOutOfRange(value: value, reference: reference)

                results.append(ParsedResult(
                    testName: testName,
                    value: value,
                    unit: unit,
                    referenceRange: reference,
                    isOutOfRange: outOfRange,
                    date: today
                ))
            }
        }

        // Fallback: try simpler pattern for tab/comma-separated formats
        if results.isEmpty {
            results = parseSimpleFormat(lines, date: today)
        }

        return results
    }

    /// Parses simpler tab or comma-separated lab formats.
    private func parseSimpleFormat(_ lines: [String], date: Date) -> [ParsedResult] {
        var results: [ParsedResult] = []
        let separators = CharacterSet(charactersIn: "\t;|")

        for line in lines {
            let parts = line.components(separatedBy: separators)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            guard parts.count >= 3,
                  let value = Double(parts[1]) else { continue }

            let testName = parts[0]
            let unit = parts[2]
            let reference = parts.count >= 4 ? parts[3] : ""

            // Skip header rows or non-test rows
            guard testName.rangeOfCharacter(from: .decimalDigits) == nil || testName.count > 3 else { continue }

            let outOfRange = !reference.isEmpty && checkOutOfRange(value: value, reference: reference)

            results.append(ParsedResult(
                testName: testName,
                value: value,
                unit: unit,
                referenceRange: reference,
                isOutOfRange: outOfRange,
                date: date
            ))
        }

        return results
    }

    // MARK: - JSON Parsing

    /// Parses a JSON file with the expected format:
    /// `[{"test": "Glucosa", "value": 95, "unit": "mg/dL", "date": "2024-01-15"}]`
    private func parseJSON(at url: URL) throws -> [ParsedResult] {
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        let entries = try decoder.decode([JSONLabEntry].self, from: data)

        guard !entries.isEmpty else {
            throw ImportError.noResultsFound
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "es_MX")

        return entries.map { entry in
            let date = dateFormatter.date(from: entry.date ?? "") ?? Date.now
            let reference = entry.referenceRange ?? ""
            let outOfRange = entry.isOutOfRange ?? (!reference.isEmpty && checkOutOfRange(value: entry.value, reference: reference))

            return ParsedResult(
                testName: entry.test,
                value: entry.value,
                unit: entry.unit,
                referenceRange: reference,
                isOutOfRange: outOfRange,
                date: date
            )
        }
    }

    // MARK: - Helpers

    /// Checks whether a value falls outside the given reference range string.
    /// Handles formats: "70-100", "< 200", "> 50", "0.4-4.0"
    private func checkOutOfRange(value: Double, reference: String) -> Bool {
        let cleaned = reference.replacingOccurrences(of: " ", with: "")

        // Format: "< 200" or "<200"
        if cleaned.hasPrefix("<"), let limit = Double(cleaned.dropFirst()) {
            return value >= limit
        }

        // Format: "> 50" or ">50"
        if cleaned.hasPrefix(">"), let limit = Double(cleaned.dropFirst()) {
            return value <= limit
        }

        // Format: "70-100" or "0.4-4.0"
        let parts = cleaned.split(separator: "-")
        if parts.count == 2, let low = Double(parts[0]), let high = Double(parts[1]) {
            return value < low || value > high
        }

        return false
    }

    // MARK: - Types

    enum ImportError: LocalizedError {
        case unsupportedFormat
        case unreadableFile
        case noResultsFound

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat:
                return "Formato de archivo no compatible. Usa PDF o JSON."
            case .unreadableFile:
                return "No se pudo leer el archivo. Verifica que no esté dañado."
            case .noResultsFound:
                return "No se encontraron resultados de laboratorio en el archivo."
            }
        }
    }

    /// Decodable model for JSON lab entries.
    private struct JSONLabEntry: Decodable {
        let test: String
        let value: Double
        let unit: String
        let date: String?
        let referenceRange: String?
        let isOutOfRange: Bool?

        enum CodingKeys: String, CodingKey {
            case test, value, unit, date
            case referenceRange = "reference_range"
            case isOutOfRange = "is_out_of_range"
        }
    }
}
