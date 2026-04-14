import UIKit

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

    // MARK: - Public API

    /// Renders the meal plan draft into a formatted PDF document.
    func generatePDF(for draft: PlanOptimizationDraft, patient: Patient) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()
            var yOffset = margin

            // Header
            yOffset = drawHeader(in: context.cgContext, at: yOffset)
            yOffset = drawDivider(in: context.cgContext, at: yOffset + 10)

            // Patient info
            yOffset = drawPatientInfo(patient: patient, in: context.cgContext, at: yOffset + 14)
            yOffset = drawDivider(in: context.cgContext, at: yOffset + 10)

            // Daily summary
            yOffset = drawDailySummary(draft: draft, patient: patient, in: context.cgContext, at: yOffset + 14)
            yOffset += 16

            // Meals
            let sortedMeals = draft.meals.sorted { $0.type.sortOrder < $1.type.sortOrder }
            for meal in sortedMeals {
                // Check if we need a new page (reserve space for a meal block)
                if yOffset + 120 > pageHeight - margin - 40 {
                    drawFooter(in: context.cgContext, page: 1)
                    context.beginPage()
                    yOffset = margin
                }
                yOffset = drawMeal(meal, in: context.cgContext, at: yOffset)
                yOffset += 10
            }

            // Rationale section
            if yOffset + 100 > pageHeight - margin - 40 {
                drawFooter(in: context.cgContext, page: 1)
                context.beginPage()
                yOffset = margin
            }
            yOffset = drawRationale(draft.calculatedRationale, in: context.cgContext, at: yOffset + 6)

            // Footer
            drawFooter(in: context.cgContext, page: 1)
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

    private func drawRationale(_ rationale: String, in context: CGContext, at y: CGFloat) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: brandOrange
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: secondaryText
        ]

        var currentY = y

        "AN\u{00C1}LISIS DEL MOTOR DE OPTIMIZACI\u{00D3}N".draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttrs)
        currentY += headingFont.lineHeight + 6

        let bounds = drawWrappedText(rationale, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth, attributes: bodyAttrs)
        currentY += bounds.height

        return currentY
    }

    private func drawFooter(in context: CGContext, page: Int) {
        let footerY = pageHeight - margin + 10
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryText
        ]

        _ = drawDivider(in: context, at: footerY - 6)

        let footerText = "Generado por NutriOptimize \u{00B7} \(formattedDate(.now))"
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
