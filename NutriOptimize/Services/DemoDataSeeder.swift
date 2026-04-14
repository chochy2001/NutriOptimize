import Foundation
import SwiftData

/// Seeds demonstration data for consultation history and lab results.
/// Only populates records on first launch when no existing data is found.
enum DemoDataSeeder {

    /// Entry point called on app launch. Seeds all demo datasets if needed.
    static func seedIfNeeded(context: ModelContext) {
        seedConsultationHistory(context: context)
        seedLabResults(context: context)
    }

    // MARK: - Consultation History

    static func seedConsultationHistory(context: ModelContext) {
        let descriptor = FetchDescriptor<ConsultationRecord>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let patients = MockPatientService.samplePatients
        guard patients.count >= 2 else { return }

        let calendar = Calendar.current
        let now = Date.now

        // Patient 1: Maria Garcia - progressive weight loss with hypothyroidism management
        let p1 = patients[0].id
        let p1Consultations: [(dayOffset: Int, weight: Double, bf: Double, waist: Double, hip: Double, arm: Double,
                                cal: Double, pro: Double, carb: Double, fat: Double, summary: String, notes: String)] = [
            (-84, 68.5, 32.0, 82.0, 100.0, 28.5,
             1650, 95, 185, 55,
             "Plan hipocalórico moderado con restricción de gluten",
             "Primera consulta. Paciente refiere fatiga constante y dificultad para bajar de peso. Se inicia plan con déficit de 300 kcal. Se solicitan estudios de perfil tiroideo."),
            (-70, 68.0, 31.5, 81.5, 99.5, 28.3,
             1620, 98, 178, 54,
             "Ajuste de carbohidratos complejos, se mantiene proteína",
             "Buena adherencia al plan. Reporta mejoría en niveles de energía. Se ajustan fuentes de carbohidratos a opciones sin gluten más variadas."),
            (-56, 67.3, 31.0, 80.8, 99.0, 28.0,
             1600, 100, 172, 53,
             "Incremento de fibra soluble y verduras de hoja verde",
             "Pérdida de peso constante. Se incrementa consumo de verduras para mejorar saciedad. Perfil tiroideo muestra TSH en rango con medicamento actual."),
            (-42, 66.8, 30.2, 80.0, 98.5, 27.8,
             1580, 102, 168, 52,
             "Introducción de snacks proteicos entre comidas",
             "Paciente reporta mejor control del apetito. Se agregan colaciones proteicas para mantener glucemia estable entre comidas principales."),
            (-21, 66.0, 29.5, 79.0, 98.0, 27.5,
             1560, 105, 162, 51,
             "Consolidación del plan con énfasis en micronutrientes",
             "Excelente progreso. Se ajusta plan para asegurar ingesta adecuada de selenio y zinc dado el hipotiroidismo. Paciente muy motivada."),
            (-7, 65.2, 28.8, 78.2, 97.5, 27.2,
             1550, 108, 158, 50,
             "Fase de mantenimiento progresivo",
             "Pérdida total de 3.3 kg en 3 meses. Se planea transición gradual a plan de mantenimiento. Composición corporal mejorada significativamente.")
        ]

        for c in p1Consultations {
            let date = calendar.date(byAdding: .day, value: c.dayOffset, to: now) ?? now
            let record = ConsultationRecord(
                patientId: p1, date: date, weight: c.weight,
                bodyFatPercentage: c.bf, waistCircumference: c.waist,
                hipCircumference: c.hip, armCircumference: c.arm,
                totalCaloriesPrescribed: c.cal, totalProtein: c.pro,
                totalCarbs: c.carb, totalFat: c.fat,
                planSummary: c.summary, clinicalNotes: c.notes)
            context.insert(record)
        }

        // Patient 2: Carlos Rodriguez - diabetes management with gradual calorie reduction
        let p2 = patients[1].id
        let p2Consultations: [(dayOffset: Int, weight: Double, bf: Double, waist: Double, hip: Double, arm: Double,
                                cal: Double, pro: Double, carb: Double, fat: Double, summary: String, notes: String)] = [
            (-80, 92.0, 28.0, 104.0, 106.0, 33.0,
             1900, 120, 200, 63,
             "Plan para control glucémico con restricción moderada de carbohidratos",
             "Paciente con DM2 e hipertensión. HbA1c en 7.8%. Se establece plan con carbohidratos de bajo índice glucémico y reducción de sodio. Meta: bajar HbA1c a <7%."),
            (-66, 91.2, 27.5, 103.0, 105.5, 32.8,
             1850, 125, 190, 62,
             "Redistribución de carbohidratos a lo largo del día",
             "Glucosa en ayunas mejoró de 145 a 128 mg/dL. Se fracciona la ingesta de carbohidratos en 5 tiempos para evitar picos postprandiales."),
            (-50, 90.0, 27.0, 102.0, 105.0, 32.5,
             1800, 128, 182, 60,
             "Incorporación de verduras en cada tiempo de comida",
             "Buena respuesta al fraccionamiento. Presión arterial estable con medicamento. Se enfatiza consumo de potasio a través de verduras y frutas permitidas."),
            (-35, 89.0, 26.2, 101.0, 104.0, 32.2,
             1780, 130, 175, 59,
             "Ajuste de grasas: priorizar monoinsaturadas",
             "Pérdida de 3 kg acumulados. Triglicéridos bajaron de 210 a 178 mg/dL. Se sustituyen grasas saturadas por aceite de oliva y aguacate."),
            (-18, 88.0, 25.5, 100.0, 103.5, 32.0,
             1750, 132, 168, 58,
             "Plan con mayor proporción proteica para preservar masa magra",
             "HbA1c control en 7.2%, bajó 0.6 puntos. Se incrementa proteína para evitar pérdida muscular durante el déficit calórico."),
            (-5, 87.2, 25.0, 99.0, 103.0, 31.8,
             1720, 135, 162, 57,
             "Consolidación metabólica y planificación a largo plazo",
             "Resultados muy positivos: 4.8 kg menos, HbA1c en meta. Triglicéridos normalizados. Se mantiene plan actual con revisión mensual.")
        ]

        for c in p2Consultations {
            let date = calendar.date(byAdding: .day, value: c.dayOffset, to: now) ?? now
            let record = ConsultationRecord(
                patientId: p2, date: date, weight: c.weight,
                bodyFatPercentage: c.bf, waistCircumference: c.waist,
                hipCircumference: c.hip, armCircumference: c.arm,
                totalCaloriesPrescribed: c.cal, totalProtein: c.pro,
                totalCarbs: c.carb, totalFat: c.fat,
                planSummary: c.summary, clinicalNotes: c.notes)
            context.insert(record)
        }

        try? context.save()
    }

    // MARK: - Lab Results

    static func seedLabResults(context: ModelContext) {
        let descriptor = FetchDescriptor<LabResultRecord>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let patients = MockPatientService.samplePatients
        guard patients.count >= 2 else { return }

        let calendar = Calendar.current
        let now = Date.now

        // Patient 1: Maria Garcia - thyroid and general metabolic panel
        let p1 = patients[0].id
        let p1Labs: [(dayOffset: Int, tests: [(name: String, value: Double, unit: String, range: String, outOfRange: Bool)])] = [
            (-84, [
                ("Glucosa en ayunas", 92, "mg/dL", "70-100", false),
                ("Colesterol total", 215, "mg/dL", "< 200", true),
                ("Triglicéridos", 168, "mg/dL", "< 150", true),
                ("HDL", 48, "mg/dL", "> 50", true),
                ("LDL", 118, "mg/dL", "< 100", true),
                ("TSH", 4.8, "mU/L", "0.4-4.0", true),
                ("T4 libre", 0.9, "ng/dL", "0.8-1.8", false),
                ("Hemoglobina", 13.2, "g/dL", "12.0-16.0", false),
            ]),
            (-42, [
                ("Glucosa en ayunas", 88, "mg/dL", "70-100", false),
                ("Colesterol total", 198, "mg/dL", "< 200", false),
                ("Triglicéridos", 142, "mg/dL", "< 150", false),
                ("HDL", 52, "mg/dL", "> 50", false),
                ("LDL", 108, "mg/dL", "< 100", true),
                ("TSH", 3.5, "mU/L", "0.4-4.0", false),
                ("T4 libre", 1.1, "ng/dL", "0.8-1.8", false),
                ("Hemoglobina", 13.5, "g/dL", "12.0-16.0", false),
            ]),
            (-7, [
                ("Glucosa en ayunas", 85, "mg/dL", "70-100", false),
                ("Colesterol total", 188, "mg/dL", "< 200", false),
                ("Triglicéridos", 128, "mg/dL", "< 150", false),
                ("HDL", 56, "mg/dL", "> 50", false),
                ("LDL", 98, "mg/dL", "< 100", false),
                ("TSH", 2.8, "mU/L", "0.4-4.0", false),
                ("T4 libre", 1.2, "ng/dL", "0.8-1.8", false),
                ("Hemoglobina", 13.8, "g/dL", "12.0-16.0", false),
            ]),
        ]

        for labDate in p1Labs {
            let date = calendar.date(byAdding: .day, value: labDate.dayOffset, to: now) ?? now
            for test in labDate.tests {
                let record = LabResultRecord(
                    patientId: p1, testDate: date, testName: test.name,
                    value: test.value, unit: test.unit,
                    referenceRange: test.range, isOutOfRange: test.outOfRange)
                context.insert(record)
            }
        }

        // Patient 2: Carlos Rodriguez - diabetes and metabolic syndrome panel
        let p2 = patients[1].id
        let p2Labs: [(dayOffset: Int, tests: [(name: String, value: Double, unit: String, range: String, outOfRange: Bool)])] = [
            (-80, [
                ("Glucosa en ayunas", 145, "mg/dL", "70-100", true),
                ("HbA1c", 7.8, "%", "< 7.0", true),
                ("Colesterol total", 242, "mg/dL", "< 200", true),
                ("Triglicéridos", 210, "mg/dL", "< 150", true),
                ("HDL", 38, "mg/dL", "> 40", true),
                ("LDL", 145, "mg/dL", "< 100", true),
                ("Creatinina", 1.0, "mg/dL", "0.7-1.3", false),
                ("Albúmina", 4.2, "g/dL", "3.5-5.5", false),
            ]),
            (-35, [
                ("Glucosa en ayunas", 118, "mg/dL", "70-100", true),
                ("HbA1c", 7.2, "%", "< 7.0", true),
                ("Colesterol total", 218, "mg/dL", "< 200", true),
                ("Triglicéridos", 178, "mg/dL", "< 150", true),
                ("HDL", 42, "mg/dL", "> 40", false),
                ("LDL", 125, "mg/dL", "< 100", true),
                ("Creatinina", 0.9, "mg/dL", "0.7-1.3", false),
                ("Albúmina", 4.3, "g/dL", "3.5-5.5", false),
            ]),
            (-5, [
                ("Glucosa en ayunas", 105, "mg/dL", "70-100", true),
                ("HbA1c", 6.8, "%", "< 7.0", false),
                ("Colesterol total", 195, "mg/dL", "< 200", false),
                ("Triglicéridos", 148, "mg/dL", "< 150", false),
                ("HDL", 45, "mg/dL", "> 40", false),
                ("LDL", 110, "mg/dL", "< 100", true),
                ("Creatinina", 0.9, "mg/dL", "0.7-1.3", false),
                ("Albúmina", 4.4, "g/dL", "3.5-5.5", false),
            ]),
        ]

        for labDate in p2Labs {
            let date = calendar.date(byAdding: .day, value: labDate.dayOffset, to: now) ?? now
            for test in labDate.tests {
                let record = LabResultRecord(
                    patientId: p2, testDate: date, testName: test.name,
                    value: test.value, unit: test.unit,
                    referenceRange: test.range, isOutOfRange: test.outOfRange)
                context.insert(record)
            }
        }

        try? context.save()
    }
}
