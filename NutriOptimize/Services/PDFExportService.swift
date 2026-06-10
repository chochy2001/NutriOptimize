import UIKit
import CoreText

/// Generates professional PDF documents from approved meal plan drafts.
/// Uses UIGraphicsPDFRenderer for native PDF composition with branded layout.
final class PDFExportService {

    // MARK: - Layout Constants

    private let pageWidth: CGFloat = 612   // US Letter
    private let pageHeight: CGFloat = 792
    private let margin: CGFloat = 50
    private let lineSpacing: CGFloat = 6

    private var contentWidth: CGFloat { pageWidth - (margin * 2) }

    // MARK: - Colors

    private let brandOrange = UIColor(red: 0.90, green: 0.42, blue: 0.14, alpha: 1.0)
    private let darkText = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
    private let secondaryText = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
    private let lightBackground = UIColor(red: 0.97, green: 0.95, blue: 0.92, alpha: 1.0)
    private let dividerColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)

    // MARK: - Fonts

    private let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
    private let headingFont = UIFont.systemFont(ofSize: 14, weight: .bold)
    private let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
    private let bodySemibold = UIFont.systemFont(ofSize: 11, weight: .semibold)
    private let captionFont = UIFont.systemFont(ofSize: 9, weight: .regular)
    private let captionBold = UIFont.systemFont(ofSize: 9, weight: .bold)

    /// Bottom of the usable content area (above the footer band).
    private var contentBottom: CGFloat { pageHeight - margin - 40 }

    // MARK: - Page Cursor

    /// Tracks the active PDF page, the running page number, and the current
    /// drawing y-offset, and owns page breaks so the footer of the page being
    /// left is always stamped with the correct page number before a new page
    /// starts.
    private final class PageCursor {
        let context: UIGraphicsPDFRendererContext
        var yOffset: CGFloat
        private(set) var pageNumber = 1
        private let topMargin: CGFloat
        private let drawFooter: (Int) -> Void

        init(context: UIGraphicsPDFRendererContext, topMargin: CGFloat, drawFooter: @escaping (Int) -> Void) {
            self.context = context
            self.yOffset = topMargin
            self.topMargin = topMargin
            self.drawFooter = drawFooter
        }

        /// Stamps the footer on the current page and begins a fresh one.
        func newPage() {
            drawFooter(pageNumber)
            context.beginPage()
            pageNumber += 1
            yOffset = topMargin
        }

        /// Finalizes the document by stamping the footer on the last page.
        func finish() {
            drawFooter(pageNumber)
        }
    }

    // MARK: - Public API

    /// Renders the meal plan draft into a formatted PDF document.
    ///
    /// Long content (many meals or a verbose engine rationale) is paginated:
    /// each block is measured before drawing and pushed to a new page when it
    /// will not fit, the rationale is split across pages, and every page footer
    /// shows its real page number. Nothing is silently clipped off the page.
    func generatePDF(for draft: PlanOptimizationDraft, patient: Patient) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()
            let cursor = PageCursor(context: context, topMargin: margin) { [self] page in
                drawFooter(in: context.cgContext, page: page)
            }
            let cg = context.cgContext

            // Header
            cursor.yOffset = drawHeader(in: cg, at: cursor.yOffset)
            cursor.yOffset = drawDivider(in: cg, at: cursor.yOffset + 10)

            // Patient info
            cursor.yOffset = drawPatientInfo(patient: patient, in: cg, at: cursor.yOffset + 14)
            cursor.yOffset = drawDivider(in: cg, at: cursor.yOffset + 10)

            // Daily summary
            cursor.yOffset = drawDailySummary(draft: draft, patient: patient, in: cg, at: cursor.yOffset + 14)
            cursor.yOffset += 16

            // Meals — measure each block and page-break when it won't fit.
            let sortedMeals = draft.meals.sorted { $0.type.sortOrder < $1.type.sortOrder }
            for meal in sortedMeals {
                let blockHeight = mealHeight(meal)
                // Only break if the block doesn't fit AND we are not already at
                // the top of a fresh page (a block taller than a full page is
                // drawn anyway, starting from the top, to avoid an infinite loop).
                if cursor.yOffset + blockHeight > contentBottom && cursor.yOffset > margin {
                    cursor.newPage()
                }
                cursor.yOffset = drawMeal(meal, in: cg, at: cursor.yOffset)
                cursor.yOffset += 10
            }

            // Rationale — split across pages so nothing overflows.
            cursor.yOffset += 6
            drawRationale(draft.calculatedRationale, cursor: cursor)

            cursor.finish()
        }
    }

    // MARK: - Drawing Methods

    private func drawHeader(in context: CGContext, at y: CGFloat) -> CGFloat {
        let title = "NutriOptimize"
        let subtitle = "Plan Alimenticio Optimizado"
        let dateStr = formattedDate(.now)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: brandOrange
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: darkText
        ]
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryText
        ]

        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        dateStr.draw(
            at: CGPoint(x: pageWidth - margin - dateStr.size(withAttributes: dateAttrs).width, y: y + 6),
            withAttributes: dateAttrs
        )

        let subtitleY = y + titleFont.lineHeight + 4
        subtitle.draw(at: CGPoint(x: margin, y: subtitleY), withAttributes: subtitleAttrs)

        return subtitleY + headingFont.lineHeight
    }

    private func drawPatientInfo(patient: Patient, in context: CGContext, at y: CGFloat) -> CGFloat {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: captionBold,
            .foregroundColor: secondaryText
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: bodySemibold,
            .foregroundColor: darkText
        ]

        let colWidth = contentWidth / 3
        var currentY = y

        // Row 1: Name, Age/Sex, Activity
        drawLabelValue("PACIENTE", patient.fullName, at: CGPoint(x: margin, y: currentY), colWidth: colWidth, labelAttrs: labelAttrs, valueAttrs: valueAttrs)
        drawLabelValue("EDAD / SEXO", "\(patient.age) a\u{00F1}os / \(patient.sex.rawValue)", at: CGPoint(x: margin + colWidth, y: currentY), colWidth: colWidth, labelAttrs: labelAttrs, valueAttrs: valueAttrs)
        drawLabelValue("ACTIVIDAD", patient.activityLevel.rawValue, at: CGPoint(x: margin + colWidth * 2, y: currentY), colWidth: colWidth, labelAttrs: labelAttrs, valueAttrs: valueAttrs)

        currentY += 36

        // Row 2: Weight, Height, BMI
        drawLabelValue("PESO", String(format: "%.1f kg", patient.weight), at: CGPoint(x: margin, y: currentY), colWidth: colWidth, labelAttrs: labelAttrs, valueAttrs: valueAttrs)
        drawLabelValue("ALTURA", String(format: "%.0f cm", patient.height), at: CGPoint(x: margin + colWidth, y: currentY), colWidth: colWidth, labelAttrs: labelAttrs, valueAttrs: valueAttrs)
        drawLabelValue("IMC", String(format: "%.1f (%@)", patient.bmi, patient.bmiClassification), at: CGPoint(x: margin + colWidth * 2, y: currentY), colWidth: colWidth, labelAttrs: labelAttrs, valueAttrs: valueAttrs)

        currentY += 36

        // Row 3: Clinical goal
        drawLabelValue("OBJETIVO CL\u{00CD}NICO", patient.clinicalGoals, at: CGPoint(x: margin, y: currentY), colWidth: contentWidth, labelAttrs: labelAttrs, valueAttrs: valueAttrs)

        currentY += 36

        // Allergies and conditions (if any)
        if !patient.allergies.isEmpty {
            drawLabelValue("ALERGIAS", patient.allergies.joined(separator: ", "), at: CGPoint(x: margin, y: currentY), colWidth: contentWidth / 2, labelAttrs: labelAttrs, valueAttrs: valueAttrs)
        }
        if !patient.medicalConditions.isEmpty {
            let xPos = patient.allergies.isEmpty ? margin : margin + contentWidth / 2
            drawLabelValue("CONDICIONES", patient.medicalConditions.joined(separator: ", "), at: CGPoint(x: xPos, y: currentY), colWidth: contentWidth / 2, labelAttrs: labelAttrs, valueAttrs: valueAttrs)
        }

        if !patient.allergies.isEmpty || !patient.medicalConditions.isEmpty {
            currentY += 36
        }

        return currentY
    }

    private func drawDailySummary(draft: PlanOptimizationDraft, patient: Patient, in context: CGContext, at y: CGFloat) -> CGFloat {
        let sectionTitle = "RESUMEN DIARIO"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: brandOrange
        ]
        sectionTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)

        let summaryY = y + headingFont.lineHeight + 8

        // Background box
        let boxRect = CGRect(x: margin, y: summaryY, width: contentWidth, height: 40)
        context.setFillColor(lightBackground.cgColor)
        context.fill(boxRect)

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryText
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: bodySemibold,
            .foregroundColor: darkText
        ]

        let colW = contentWidth / 5
        let items: [(String, String)] = [
            ("Calor\u{00ED}as", "\(Int(draft.totalCalories)) kcal"),
            ("Prote\u{00ED}na", "\(Int(draft.totalProtein)) g"),
            ("Carbohidratos", "\(Int(draft.totalCarbs)) g"),
            ("Grasa", "\(Int(draft.totalFat)) g"),
            ("% TDEE", String(format: "%.0f%%", draft.calorieAdherencePercentage(tdee: patient.estimatedTDEE)))
        ]

        for (index, item) in items.enumerated() {
            let x = margin + CGFloat(index) * colW + 8
            item.0.draw(at: CGPoint(x: x, y: summaryY + 4), withAttributes: labelAttrs)
            item.1.draw(at: CGPoint(x: x, y: summaryY + 18), withAttributes: valueAttrs)
        }

        return summaryY + 40
    }

    /// Computes the rendered height of a meal block so the caller can decide
    /// whether it fits on the current page before drawing it. Mirrors the layout
    /// performed by `drawMeal`.
    private func mealHeight(_ meal: Meal) -> CGFloat {
        let detailAttrs: [NSAttributedString.Key: Any] = [.font: captionFont]

        var height: CGFloat = 0
        height += captionBold.lineHeight + 2          // meal type label
        height += bodySemibold.lineHeight + 2         // name + macros row

        // Ingredients (wrapped)
        let ingredientsStr = "Ingredientes: \(meal.ingredients.joined(separator: ", "))"
        height += measuredHeight(ingredientsStr, maxWidth: contentWidth, attributes: detailAttrs) + 2

        // Portion (single line, if present)
        if !meal.portionDescription.isEmpty {
            height += captionFont.lineHeight + 2
        }

        // Divider (drawDivider adds +4, called at currentY + 4)
        height += 8
        return height
    }

    private func drawMeal(_ meal: Meal, in context: CGContext, at y: CGFloat) -> CGFloat {
        let typeAttrs: [NSAttributedString.Key: Any] = [
            .font: captionBold,
            .foregroundColor: brandOrange
        ]
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: bodySemibold,
            .foregroundColor: darkText
        ]
        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryText
        ]
        let macroAttrs: [NSAttributedString.Key: Any] = [
            .font: captionBold,
            .foregroundColor: darkText
        ]

        var currentY = y

        // Meal type label
        meal.type.rawValue.uppercased().draw(at: CGPoint(x: margin, y: currentY), withAttributes: typeAttrs)
        currentY += captionBold.lineHeight + 2

        // Meal name
        meal.name.draw(at: CGPoint(x: margin, y: currentY), withAttributes: nameAttrs)

        // Macros on the right
        let macroStr = "P: \(Int(meal.macros.protein))g | C: \(Int(meal.macros.carbohydrates))g | G: \(Int(meal.macros.fat))g | \(Int(meal.macros.totalCalories)) kcal"
        let macroSize = macroStr.size(withAttributes: macroAttrs)
        macroStr.draw(at: CGPoint(x: pageWidth - margin - macroSize.width, y: currentY), withAttributes: macroAttrs)
        currentY += bodySemibold.lineHeight + 2

        // Ingredients
        let ingredientsStr = "Ingredientes: \(meal.ingredients.joined(separator: ", "))"
        let ingredientsBounds = drawWrappedText(ingredientsStr, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth, attributes: detailAttrs)
        currentY += ingredientsBounds.height + 2

        // Portion
        if !meal.portionDescription.isEmpty {
            let portionStr = "Porci\u{00F3}n: \(meal.portionDescription)"
            portionStr.draw(at: CGPoint(x: margin, y: currentY), withAttributes: detailAttrs)
            currentY += captionFont.lineHeight + 2
        }

        // Separator line
        currentY = drawDivider(in: context, at: currentY + 4, light: true)

        return currentY
    }

    /// Draws the engine rationale, paginating it so long content is never
    /// clipped. The text is split into paragraphs (and, where a single
    /// paragraph is taller than a page, into lines) and flowed across pages via
    /// the `cursor`.
    private func drawRationale(_ rationale: String, cursor: PageCursor) {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: brandOrange
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: secondaryText
        ]
        let cg = cursor.context.cgContext

        // Title — keep it with at least one body line on the same page.
        let titleBlock = headingFont.lineHeight + 6 + bodyFont.lineHeight
        if cursor.yOffset + titleBlock > contentBottom && cursor.yOffset > margin {
            cursor.newPage()
        }
        "AN\u{00C1}LISIS DEL MOTOR DE OPTIMIZACI\u{00D3}N".draw(at: CGPoint(x: margin, y: cursor.yOffset), withAttributes: titleAttrs)
        cursor.yOffset += headingFont.lineHeight + 6

        // Flow the rationale paragraph by paragraph.
        let paragraphs = rationale
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        for (index, paragraph) in paragraphs.enumerated() {
            if paragraph.isEmpty {
                cursor.yOffset += bodyFont.lineHeight / 2
                continue
            }
            drawFlowingText(paragraph, attributes: bodyAttrs, in: cg, cursor: cursor)
            if index < paragraphs.count - 1 {
                cursor.yOffset += 4
            }
        }
    }

    /// Draws wrapped text that may span multiple pages. If the whole block fits
    /// on the current page it is drawn in one pass; otherwise it is split at
    /// line boundaries (computed via CoreText) so words and diacritics stay
    /// intact, breaking to a new page as space runs out.
    private func drawFlowingText(_ text: String, attributes: [NSAttributedString.Key: Any], in context: CGContext, cursor: PageCursor) {
        let fullHeight = measuredHeight(text, maxWidth: contentWidth, attributes: attributes)

        // Fast path: the block fits in the remaining space on this page.
        if cursor.yOffset + fullHeight <= contentBottom {
            drawWrappedText(text, at: CGPoint(x: margin, y: cursor.yOffset), maxWidth: contentWidth, attributes: attributes)
            cursor.yOffset += fullHeight
            return
        }

        // Slow path: split into lines and flow them, page-breaking as needed.
        let lines = wrappedLines(text, maxWidth: contentWidth, attributes: attributes)
        let lineHeight = (attributes[.font] as? UIFont ?? bodyFont).lineHeight
        for line in lines {
            if cursor.yOffset + lineHeight > contentBottom && cursor.yOffset > margin {
                cursor.newPage()
            }
            (line as NSString).draw(
                at: CGPoint(x: margin, y: cursor.yOffset),
                withAttributes: attributes
            )
            cursor.yOffset += lineHeight
        }
    }

    /// Returns the rendered height of wrapped text without drawing it.
    private func measuredHeight(_ text: String, maxWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let attrString = NSAttributedString(string: text, attributes: attributes)
        return attrString.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height
    }

    /// Splits a string into visual lines as they would wrap inside `maxWidth`,
    /// using CoreText line breaking so words and accented characters are not cut.
    private func wrappedLines(_ text: String, maxWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) -> [String] {
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let typesetter = CTTypesetterCreateWithAttributedString(attrString)
        let nsText = text as NSString
        let length = nsText.length

        var lines: [String] = []
        var start = 0
        while start < length {
            let count = CTTypesetterSuggestLineBreak(typesetter, start, Double(maxWidth))
            guard count > 0 else { break }
            let range = NSRange(location: start, length: count)
            lines.append(nsText.substring(with: range))
            start += count
        }
        return lines
    }

    private func drawFooter(in context: CGContext, page: Int) {
        let footerY = pageHeight - margin + 10
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryText
        ]

        _ = drawDivider(in: context, at: footerY - 6)

        let footerText = "Generado por NutriOptimize \u{00B7} \(formattedDate(.now)) \u{00B7} P\u{00E1}gina \(page)"
        footerText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttrs)

        let disclaimer = "Este plan debe ser revisado y aprobado por un profesional de nutrici\u{00F3}n certificado."
        let disclaimerSize = disclaimer.size(withAttributes: footerAttrs)
        disclaimer.draw(at: CGPoint(x: pageWidth - margin - disclaimerSize.width, y: footerY), withAttributes: footerAttrs)
    }

    // MARK: - Utilities

    private func drawDivider(in context: CGContext, at y: CGFloat, light: Bool = false) -> CGFloat {
        context.setStrokeColor((light ? dividerColor.withAlphaComponent(0.5) : dividerColor).cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        context.strokePath()
        return y + 4
    }

    private func drawLabelValue(_ label: String, _ value: String, at point: CGPoint, colWidth: CGFloat, labelAttrs: [NSAttributedString.Key: Any], valueAttrs: [NSAttributedString.Key: Any]) {
        label.draw(at: point, withAttributes: labelAttrs)
        let valueY = point.y + (captionBold.lineHeight) + 2
        let valueRect = CGRect(x: point.x, y: valueY, width: colWidth - 8, height: bodySemibold.lineHeight * 2)
        value.draw(in: valueRect, withAttributes: valueAttrs)
    }

    @discardableResult
    private func drawWrappedText(_ text: String, at point: CGPoint, maxWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGSize {
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let boundingRect = attrString.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        attrString.draw(in: CGRect(origin: point, size: CGSize(width: maxWidth, height: boundingRect.height)))
        return boundingRect.size
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: date)
    }
}
