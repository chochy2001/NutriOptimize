import Foundation
import SwiftData

/// Seeds demonstration data for consultation history and lab results.
/// Only populates records on first launch when no existing data is found.
enum DemoDataSeeder {

    /// Entry point called on app launch. Seeds all demo datasets if needed.
    static func seedIfNeeded(context: ModelContext) {
        seedConsultationHistory(context: context)
        seedLabResults(context: context)
        seedPatientFeedback(context: context)
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

        // Patient 3: Ana Martínez - athlete seeking muscle gain
        guard patients.count >= 5 else {
            try? context.save()
            return
        }

        let p3 = patients[2].id
        let p3Consultations: [(dayOffset: Int, weight: Double, bf: Double, waist: Double, hip: Double, arm: Double,
                                cal: Double, pro: Double, carb: Double, fat: Double, summary: String, notes: String)] = [
            (-82, 55.0, 18.0, 66.0, 90.0, 25.0,
             2400, 140, 310, 65,
             "Plan hipercalórico con prioridad en proteína para ganancia muscular",
             "Primera consulta. Paciente deportista de alto rendimiento, entrena 6 días/semana. Composición corporal saludable. Objetivo: ganancia de 3-4 kg de masa magra en 3 meses. Se establece superávit de 300 kcal."),
            (-68, 55.4, 17.8, 66.0, 90.2, 25.3,
             2450, 145, 315, 66,
             "Ajuste de proteína post-entrenamiento y carbohidratos periféricos",
             "Ganancia de 400g. Se aumenta proteína en ventana anabólica post-entrenamiento. Paciente tolera bien las porciones. Se agregan carbohidratos de rápida absorción pre-entreno."),
            (-52, 56.1, 17.5, 66.2, 90.5, 25.8,
             2500, 150, 320, 68,
             "Incorporación de suplementación con proteína de suero y creatina",
             "Progreso constante en masa muscular. Se incorpora batido post-entreno. Medidas de brazo aumentaron 0.8cm. Sin aumento significativo de grasa corporal."),
            (-35, 56.8, 17.2, 66.5, 91.0, 26.2,
             2520, 155, 318, 70,
             "Periodización nutricional según tipo de entrenamiento",
             "1.8 kg ganados. Se implementa ciclado de carbohidratos: más altos en días de fuerza, moderados en días de cardio. Paciente refiere mejor rendimiento."),
            (-14, 57.5, 16.8, 66.8, 91.5, 26.8,
             2550, 158, 322, 72,
             "Fase de consolidación con énfasis en recuperación y sueño",
             "Excelente progreso: 2.5 kg de ganancia total, grasa corporal disminuyó. Se optimiza última comida del día para mejorar recuperación nocturna.")
        ]

        for c in p3Consultations {
            let date = calendar.date(byAdding: .day, value: c.dayOffset, to: now) ?? now
            let record = ConsultationRecord(
                patientId: p3, date: date, weight: c.weight,
                bodyFatPercentage: c.bf, waistCircumference: c.waist,
                hipCircumference: c.hip, armCircumference: c.arm,
                totalCaloriesPrescribed: c.cal, totalProtein: c.pro,
                totalCarbs: c.carb, totalFat: c.fat,
                planSummary: c.summary, clinicalNotes: c.notes)
            context.insert(record)
        }

        // Patient 4: Roberto Hernández - fatty liver, weight loss
        let p4 = patients[3].id
        let p4Consultations: [(dayOffset: Int, weight: Double, bf: Double, waist: Double, hip: Double, arm: Double,
                                cal: Double, pro: Double, carb: Double, fat: Double, summary: String, notes: String)] = [
            (-85, 105.3, 35.0, 112.0, 110.0, 34.0,
             1800, 110, 190, 60,
             "Plan de reducción calórica moderada para hígado graso",
             "Primera consulta. Paciente con esteatosis hepática grado II. IMC 34.4. Se inicia déficit de 500 kcal con restricción de grasas saturadas y fructosa. Meta: perder 15 kg en 6 meses."),
            (-72, 104.0, 34.5, 111.0, 109.5, 33.8,
             1780, 115, 182, 58,
             "Eliminación de bebidas azucaradas y reducción de fructosa",
             "Pérdida de 1.3 kg. Paciente reporta que eliminó refrescos y jugos. Se enfatiza el consumo de verduras crucíferas para apoyo hepático. Enzimas hepáticas pendientes."),
            (-56, 102.5, 33.8, 109.5, 108.5, 33.5,
             1750, 118, 175, 57,
             "Incremento de fibra y verduras crucíferas para apoyo hepático",
             "Buena tendencia de peso. ALT bajó de 68 a 52 U/L. Se incluyen brócoli, col rizada y alcachofa como fuentes de fibra y antioxidantes hepáticos."),
            (-40, 101.0, 33.0, 108.0, 107.5, 33.2,
             1720, 120, 168, 56,
             "Ajuste de grasas: omega-3 y eliminación de aceites refinados",
             "4.3 kg perdidos acumulados. Se priorizan grasas antiinflamatorias: pescados grasos, aguacate, aceite de oliva. Se eliminan aceites de maíz y canola refinados."),
            (-22, 99.5, 32.0, 106.0, 106.5, 33.0,
             1700, 122, 162, 55,
             "Protocolo de ayuno intermitente 16:8 opcional",
             "Paciente interesado en ayuno intermitente. Se implementa ventana de alimentación de 8 horas. GGT normalizada. Ultrasonido de control muestra mejoría en esteatosis."),
            (-8, 98.0, 31.2, 104.5, 106.0, 32.8,
             1680, 125, 158, 54,
             "Consolidación del plan con evaluación de hígado graso",
             "7.3 kg perdidos en 3 meses. Enzimas hepáticas normalizadas. Ultrasonido muestra esteatosis grado I, mejoría notable. Paciente motivado para continuar.")
        ]

        for c in p4Consultations {
            let date = calendar.date(byAdding: .day, value: c.dayOffset, to: now) ?? now
            let record = ConsultationRecord(
                patientId: p4, date: date, weight: c.weight,
                bodyFatPercentage: c.bf, waistCircumference: c.waist,
                hipCircumference: c.hip, armCircumference: c.arm,
                totalCaloriesPrescribed: c.cal, totalProtein: c.pro,
                totalCarbs: c.carb, totalFat: c.fat,
                planSummary: c.summary, clinicalNotes: c.notes)
            context.insert(record)
        }

        // Patient 5: Laura Sánchez - IBS, stable weight
        let p5 = patients[4].id
        let p5Consultations: [(dayOffset: Int, weight: Double, bf: Double, waist: Double, hip: Double, arm: Double,
                                cal: Double, pro: Double, carb: Double, fat: Double, summary: String, notes: String)] = [
            (-78, 62.0, 25.0, 72.0, 94.0, 26.0,
             1850, 85, 240, 58,
             "Plan bajo en FODMAPs para manejo de síntomas digestivos",
             "Primera consulta. Paciente con SII diagnosticado hace 2 años. Síntomas frecuentes: distensión, dolor abdominal, alternancia diarrea/estreñimiento. Se inicia dieta baja en FODMAPs con reintroducción gradual."),
            (-63, 61.8, 24.8, 71.8, 93.8, 26.0,
             1860, 88, 238, 59,
             "Eliminación de lácteos y trigo durante fase de eliminación",
             "Paciente reporta 50% menos episodios de distensión. Se confirma sensibilidad a lactosa y fructanos del trigo. Se sustituyen con alternativas toleradas: arroz, avena sin gluten."),
            (-48, 62.2, 25.0, 72.0, 94.0, 26.0,
             1870, 90, 235, 61,
             "Reintroducción controlada: sorbitol y fructosa aislada",
             "Peso estable como se desea. Se inicia fase de reintroducción. Sorbitol en manzanas tolerado en porciones pequeñas. Fructosa aislada en miel genera síntomas, se mantiene excluida."),
            (-30, 62.0, 24.8, 71.5, 93.8, 26.0,
             1880, 92, 232, 63,
             "Incorporación de probióticos y fibra soluble progresiva",
             "Buena tolerancia a la fibra soluble de avena y plátano verde. Se agrega probiótico con cepas Bifidobacterium. Paciente refiere mejor regularidad intestinal."),
            (-12, 62.3, 25.0, 72.0, 94.2, 26.2,
             1880, 90, 235, 62,
             "Plan de mantenimiento con FODMAPs tolerados identificados",
             "Síntomas controlados al 80%. Se establece lista definitiva de alimentos tolerados y no tolerados. Plan de mantenimiento a largo plazo con revisión trimestral.")
        ]

        for c in p5Consultations {
            let date = calendar.date(byAdding: .day, value: c.dayOffset, to: now) ?? now
            let record = ConsultationRecord(
                patientId: p5, date: date, weight: c.weight,
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

        // Patient 3: Ana Martínez - athlete, performance panel
        guard patients.count >= 5 else {
            try? context.save()
            return
        }

        let p3l = patients[2].id
        let p3Labs: [(dayOffset: Int, tests: [(name: String, value: Double, unit: String, range: String, outOfRange: Bool)])] = [
            (-82, [
                ("Hemoglobina", 13.8, "g/dL", "12.0-16.0", false),
                ("Ferritina", 28, "ng/mL", "20-200", false),
                ("Glucosa en ayunas", 78, "mg/dL", "70-100", false),
                ("Creatinina", 0.8, "mg/dL", "0.5-1.1", false),
                ("Colesterol total", 175, "mg/dL", "< 200", false),
                ("Triglicéridos", 68, "mg/dL", "< 150", false),
                ("Vitamina D", 22, "ng/mL", "30-100", true),
            ]),
            (-35, [
                ("Hemoglobina", 14.2, "g/dL", "12.0-16.0", false),
                ("Ferritina", 35, "ng/mL", "20-200", false),
                ("Glucosa en ayunas", 76, "mg/dL", "70-100", false),
                ("Creatinina", 0.9, "mg/dL", "0.5-1.1", false),
                ("Colesterol total", 172, "mg/dL", "< 200", false),
                ("Triglicéridos", 62, "mg/dL", "< 150", false),
                ("Vitamina D", 38, "ng/mL", "30-100", false),
            ]),
        ]

        for labDate in p3Labs {
            let date = calendar.date(byAdding: .day, value: labDate.dayOffset, to: now) ?? now
            for test in labDate.tests {
                let record = LabResultRecord(
                    patientId: p3l, testDate: date, testName: test.name,
                    value: test.value, unit: test.unit,
                    referenceRange: test.range, isOutOfRange: test.outOfRange)
                context.insert(record)
            }
        }

        // Patient 4: Roberto Hernández - liver function and metabolic panel
        let p4l = patients[3].id
        let p4Labs: [(dayOffset: Int, tests: [(name: String, value: Double, unit: String, range: String, outOfRange: Bool)])] = [
            (-85, [
                ("ALT (TGP)", 68, "U/L", "7-56", true),
                ("AST (TGO)", 52, "U/L", "10-40", true),
                ("GGT", 78, "U/L", "9-48", true),
                ("Glucosa en ayunas", 112, "mg/dL", "70-100", true),
                ("Colesterol total", 248, "mg/dL", "< 200", true),
                ("Triglicéridos", 225, "mg/dL", "< 150", true),
                ("HDL", 35, "mg/dL", "> 40", true),
                ("LDL", 152, "mg/dL", "< 100", true),
            ]),
            (-40, [
                ("ALT (TGP)", 52, "U/L", "7-56", false),
                ("AST (TGO)", 38, "U/L", "10-40", false),
                ("GGT", 55, "U/L", "9-48", true),
                ("Glucosa en ayunas", 102, "mg/dL", "70-100", true),
                ("Colesterol total", 218, "mg/dL", "< 200", true),
                ("Triglicéridos", 185, "mg/dL", "< 150", true),
                ("HDL", 40, "mg/dL", "> 40", false),
                ("LDL", 132, "mg/dL", "< 100", true),
            ]),
            (-8, [
                ("ALT (TGP)", 42, "U/L", "7-56", false),
                ("AST (TGO)", 32, "U/L", "10-40", false),
                ("GGT", 45, "U/L", "9-48", false),
                ("Glucosa en ayunas", 95, "mg/dL", "70-100", false),
                ("Colesterol total", 198, "mg/dL", "< 200", false),
                ("Triglicéridos", 155, "mg/dL", "< 150", true),
                ("HDL", 44, "mg/dL", "> 40", false),
                ("LDL", 118, "mg/dL", "< 100", true),
            ]),
        ]

        for labDate in p4Labs {
            let date = calendar.date(byAdding: .day, value: labDate.dayOffset, to: now) ?? now
            for test in labDate.tests {
                let record = LabResultRecord(
                    patientId: p4l, testDate: date, testName: test.name,
                    value: test.value, unit: test.unit,
                    referenceRange: test.range, isOutOfRange: test.outOfRange)
                context.insert(record)
            }
        }

        // Patient 5: Laura Sánchez - digestive markers and nutritional status
        let p5l = patients[4].id
        let p5Labs: [(dayOffset: Int, tests: [(name: String, value: Double, unit: String, range: String, outOfRange: Bool)])] = [
            (-78, [
                ("Hemoglobina", 12.2, "g/dL", "12.0-16.0", false),
                ("Ferritina", 18, "ng/mL", "20-200", true),
                ("Vitamina B12", 280, "pg/mL", "200-900", false),
                ("Albúmina", 4.0, "g/dL", "3.5-5.5", false),
                ("PCR", 3.8, "mg/L", "< 3.0", true),
                ("Glucosa en ayunas", 82, "mg/dL", "70-100", false),
                ("Colesterol total", 185, "mg/dL", "< 200", false),
            ]),
            (-30, [
                ("Hemoglobina", 12.8, "g/dL", "12.0-16.0", false),
                ("Ferritina", 24, "ng/mL", "20-200", false),
                ("Vitamina B12", 310, "pg/mL", "200-900", false),
                ("Albúmina", 4.2, "g/dL", "3.5-5.5", false),
                ("PCR", 2.1, "mg/L", "< 3.0", false),
                ("Glucosa en ayunas", 80, "mg/dL", "70-100", false),
                ("Colesterol total", 182, "mg/dL", "< 200", false),
            ]),
        ]

        for labDate in p5Labs {
            let date = calendar.date(byAdding: .day, value: labDate.dayOffset, to: now) ?? now
            for test in labDate.tests {
                let record = LabResultRecord(
                    patientId: p5l, testDate: date, testName: test.name,
                    value: test.value, unit: test.unit,
                    referenceRange: test.range, isOutOfRange: test.outOfRange)
                context.insert(record)
            }
        }

        try? context.save()
    }

    // MARK: - Patient Feedback

    static func seedPatientFeedback(context: ModelContext) {
        let descriptor = FetchDescriptor<PatientFeedbackRecord>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let patients = MockPatientService.samplePatients
        guard patients.count >= 5 else { return }

        let feedbackData: [(index: Int, liked: [String], disliked: [String], banned: [String])] = [
            (0, ["Ensaladas", "Frutas"], ["Comida frita"], ["Gluten", "Mariscos"]),
            (1, ["Pollo", "Verduras al vapor"], ["Pan blanco"], ["Lactosa"]),
            (2, ["Salmón", "Quinoa", "Proteína de suero"], ["Alimentos procesados"], []),
            (3, ["Ensaladas", "Carnes magras"], ["Bebidas azucaradas"], ["Nueces", "Soya"]),
            (4, ["Sopas", "Caldos"], ["Picante", "Alimentos grasos"], ["Huevo"]),
        ]

        for data in feedbackData {
            let record = PatientFeedbackRecord(
                patientId: patients[data.index].id,
                likedFoods: data.liked,
                dislikedFoods: data.disliked,
                bannedFoods: data.banned
            )
            context.insert(record)
        }

        try? context.save()
    }
}
