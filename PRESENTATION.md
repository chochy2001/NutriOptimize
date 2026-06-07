# NutriOptimize - Pitch Final Shark Tank

> Presentación rápida para copiar en Gamma, Canva o PowerPoint. Cada bloque separado por `---` es una slide. Duración objetivo: 5 minutos máximo.

---

## Slide 1: NutriOptimize

**Planes nutricionales personalizados en minutos, con el nutriólogo siempre al mando.**

NutriOptimize es una app iOS para nutriólogos que convierte datos clínicos del paciente en un borrador de plan alimenticio editable, verificable y listo para entregar.

**Equipo**
- Jorge Salgado Miranda
- Michelle Paola González Martínez
- Arroyo Ramírez Carlos Alberto

**Guion, 30 segundos**

Hoy no venimos a vender una IA que reemplaza nutriólogos. Venimos a presentar una herramienta que les devuelve tiempo, orden y control. NutriOptimize toma el perfil clínico del paciente, propone un plan alimenticio como borrador y deja la decisión final en manos del profesional.

---

## Slide 2: El Problema

**La necesidad nutricional es enorme, pero el flujo clínico sigue siendo lento.**

- En México, **76.2% de los adultos** vive con sobrepeso u obesidad, según ENSANUT Continua 2023.
- La OCDE estima que el sobrepeso representa **8.9% del gasto en salud** y reduce el PIB de México en **5.3%**.
- Cada paciente requiere cálculos, restricciones, alergias, presupuesto, preferencias, historial y una entrega clara.
- El nutriólogo termina invirtiendo tiempo fuera de consulta en tareas repetitivas que sí se pueden acelerar.

**Guion, 45 segundos**

El problema no es solo hacer una dieta. Es transformar información clínica en un plan personalizado, seguro y comprensible. En la práctica, el nutriólogo debe calcular IMC, TMB, TDEE, revisar alergias, adaptar comidas al presupuesto y redactar algo que el paciente sí pueda seguir. Esa carga limita cuántos pacientes puede atender y qué tan rápido puede responder.

**Fuentes**
- [ENSANUT Continua 2023, INSP](https://ensanut.insp.mx/encuestas/ensanutcontinua2023/doctos/informes/ensanut_23_112024.pdf): sobrepeso + obesidad en adultos.
- [OECD, The Heavy Burden of Obesity: México](https://www.oecd.org/content/dam/oecd/en/publications/reports/2025/07/the-heavy-burden-of-obesity-country-notes_da068cb5/mexico_358a8aef/b2906d73-en.pdf).

---

## Slide 3: La Solución

**Un flujo Human-Centered AI: el sistema propone, el profesional decide.**

1. Se registra el paciente con datos clínicos, objetivo, alergias, preferencias, actividad, presupuesto y tiempo de cocina.
2. El motor genera una propuesta con comidas, porciones, macros y razonamiento clínico.
3. El nutriólogo revisa el borrador, edita cualquier comida y ajusta macros o ingredientes.
4. Al aprobarlo, la app guarda la consulta y genera un PDF profesional compartible desde la hoja del sistema.

**Diferencial central**

NutriOptimize no automatiza decisiones clínicas. Acelera el primer borrador y conserva revisión humana, trazabilidad y control granular.

**Guion, 45 segundos**

La clave es que no entregamos un plan directo al paciente. Entregamos un borrador al profesional. El motor considera alergias, condiciones, presupuesto en pesos mexicanos, preferencias y feedback previo. Después, el nutriólogo puede cambiar una comida, borrar ingredientes, ajustar porciones o descartar todo. Esto cumple el principio más importante de nuestra app: la IA asiste, pero el criterio profesional manda.

---

## Slide 4: Demo del Prototipo

**Mostrar solo el flujo que convence.**

**1. Dashboard**
- Pacientes registrados.
- Borradores pendientes.
- Búsqueda rápida.

**2. Perfil del paciente**
- IMC, TMB y TDEE calculados automáticamente.
- Historial, fotos, laboratorios y feedback.
- Botón para generar propuesta optimizada.

**3. Editor del plan**
- Comidas ordenadas por tipo: desayuno, snack, comida y cena.
- Totales de calorías, proteína, carbohidratos y grasa.
- Edición granular, aprobación, descarte, guardado en pendientes y PDF.

**Capturas sugeridas**
- `docs/screenshots/dashboard.png`
- `docs/screenshots/patient_detail.png`
- `docs/screenshots/processing.png`
- `docs/screenshots/draft_editor.png`

**Guion, 1 minuto 20 segundos**

Aquí se ve el prototipo funcionando. Primero, el dashboard concentra pacientes y planes pendientes. Después entramos al perfil: la app ya calcula métricas clínicas y abre herramientas de seguimiento como laboratorios, fotos y retroalimentación. Al generar el plan, si hay API key usa OpenRouter; si no, funciona con datos demo y motor mock para que la exposición no dependa de internet. Finalmente, en el editor se revisa el razonamiento, se ajustan comidas y se exporta un PDF profesional.

---

## Slide 5: Tecnología y Viabilidad

**Es una app nativa, no una maqueta.**

| Capa | Implementación | Por qué importa |
|---|---|---|
| App | SwiftUI + iOS 17 | Experiencia móvil fluida para consulta real |
| Datos | SwiftData local | Privacidad y disponibilidad sin backend obligatorio |
| Arquitectura | MVVM + protocolos | Código separable, testeable y mantenible |
| Motor | OpenRouter + Gemini 2.5 Flash | Generación estructurada en JSON |
| Seguridad | Keychain para API key | No se guarda la clave como texto plano |
| Entrega | PDF nativo + share sheet | Documento profesional listo para paciente |
| Respaldo | Motor mock + datos demo | Demo estable aún sin API externa |

**Validación técnica**
- Build en simulador: exitoso.
- 86 pruebas unitarias cubren modelos, prompts, PDF, mocks, drafts y localización.

**Guion, 50 segundos**

La tecnología fue elegida por pertinencia. SwiftData mantiene datos locales; MVVM permite separar vista, estado y servicios; OpenRouter genera el borrador; UIGraphicsPDFRenderer produce una entrega profesional. Además, la app tiene modo demo, lo cual es crítico para hackathon y para ventas: podemos mostrar el flujo completo aunque falle la red o no haya API key configurada.

---

## Slide 6: Impacto, Escala y Cierre

**NutriOptimize convierte tiempo administrativo en tiempo clínico.**

**Impacto para el nutriólogo**
- Menos trabajo repetitivo al crear el primer borrador.
- Mayor consistencia en cálculos y distribución de macronutrientes.
- Entrega más profesional para el paciente.
- Mejor seguimiento con historial, laboratorios, fotos y feedback.

**Escalabilidad**
- MVP funcional en iOS.
- Siguiente etapa: agenda, sincronización, multi-nutriólogo y pilotos con consultorios.
- Modelo viable: suscripción para nutriólogos independientes y clínicas pequeñas.

**Cierre**

NutriOptimize no reemplaza al nutriólogo: amplifica su criterio con una herramienta rápida, verificable, editable y centrada en el flujo clínico mexicano.

**Guion, 40 segundos**

Si esto escala, el impacto es claro: nutriólogos con más tiempo para consulta, pacientes con planes más personalizados y una herramienta profesional accesible para clínicas pequeñas. Nuestro siguiente paso es pilotear con nutriólogos reales, medir tiempo ahorrado, adherencia del paciente y calidad percibida del plan. NutriOptimize es factible, ya funciona y está diseñado para crecer.

---

## Notas de Rúbrica

- **Relevancia:** problema respaldado con datos nacionales y carga real del flujo clínico.
- **Datos:** ENSANUT 2023 y OCDE justifican necesidad e impacto económico.
- **Originalidad:** Human-Centered AI, presupuesto en MXN, español mexicano y revisión humana.
- **Pitch:** historia simple: paciente complejo, borrador rápido, revisión profesional, PDF.
- **UX/UI:** dashboard, perfil clínico, editor granular, seguimiento y ayuda in-app.
- **Implementación:** SwiftUI, SwiftData, MVVM, OpenRouter, PDF nativo, mocks y 86 tests.
- **Factibilidad:** MVP funcional, build validado, demo estable sin dependencia externa.
