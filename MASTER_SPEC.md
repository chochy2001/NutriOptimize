# NutriOptimize MASTER_SPEC

## Executive Summary

`NutriOptimize` (`chochy2001/NutriOptimize`) is a native iOS 17+ clinical nutrition assistant built with Swift 5.9, SwiftUI, SwiftData, Swift Charts, PDFKit, and `UIGraphicsPDFRenderer` (`project.yml`, `MARKETING_VERSION = "1.0.0"`, `CURRENT_PROJECT_VERSION = "1"`, bundle prefix `com.nutrioptimize`). Designed around Human-Centered AI (HCAI) workflow principles, it enables nutritionists to manage patient records locally on device, generate personalized meal-plan **drafts** (via OpenRouter `google/gemini-2.5-flash` or offline demonstration templates), inspect raw prompts/responses, edit meals and macronutrients granularly, approve plans into longitudinal consultation records, import lab panels from PDF/JSON, and export branded US Letter PDFs for patient delivery.

Client readiness: **Partial**. The repository features a complete MVVM + SwiftData architecture, Keychain API-key storage, explicit PHI consent gating and pseudonymization, full EN/ES localization parity (`69/69` `Localizable.strings` keys), and **156** unit tests across **14** XCTest suites, while simulator/device test execution (`xcodebuild test` on macOS) and Apple Developer distribution signing remain external release steps.

## Current Capabilities

- **On-Device Patient & Clinical Lifecycle (`NutriOptimize/Models/`, `Services/PatientStore.swift`)**:
  - Full SwiftData CRUD (`PatientRecord` <-> `Patient`) with automatic antropometric calculations: BMI & classification, Mifflin-St Jeor BMR, PAL-weighted TDEE (`1.2`–`1.9`), macro gram/kcal percentages, and weekly/monthly food budget in MXN (`Models/Patient.swift`, `Models/Meal.swift`).
  - Cascade deletion (`PatientStore.delete(patientId:)`, lines `174-210`) removing linked `ConsultationRecord`, `LabResultRecord`, `PatientFeedbackRecord`, `PlanDraftRecord`, and on-disk progress photos (`Documents/ProgressPhotos/<uuid>_*.jpg`).
  - Preloaded 5-patient realistic clinical seed (`DemoDataSeeder.swift`, `MockPatientService.swift`) for offline evaluation.
- **Consent-Gated Meal-Plan Draft Engine (`Services/OpenRouterService.swift`, `Views/Draft/`)**:
  - Production `OpenRouterService` (`POST https://openrouter.ai/api/v1/chat/completions`, `google/gemini-2.5-flash`, `response_format: json_object`) decoupled behind `OptimizationEngineProtocol` with automatic offline fallback to `MockOptimizationService`.
  - Privacy & HCAI safeguards: stores API key in iOS Keychain (`com.nutrioptimize.api`), blocks off-device transmission unless `DataProcessingConsentView` (`hasDataProcessingConsent`) is accepted, transmits only patient initials (`patient.pseudonym`) rather than full names, exposes raw prompts/responses in `EngineDebugView`, and creates all plans in `pendingReview` status.
  - Granular `DraftEditorView` + `EditMealSheet` supporting meal creation/editing/deletion, macro recalculation, quick templates, food preference/exclusion feedback (`RecommendationFeedback.swift`), and automatic `ConsultationRecord` creation upon plan approval.
- **Longitudinal Tracking, Lab Import & PDF Export**:
  - Consultation history charts (`PatientHistoryView.swift` via Swift Charts), camera/gallery progress photos (`PhotoCaptureView.swift`, `ProgressPhotoView.swift`), 12-biomarker lab tracking (`LabResultsView.swift`), and PDF/JSON lab result extraction via PDFKit (`LabDocumentImporter.swift`, `LabImportView.swift`).
  - Multi-page US Letter (`612x792 pt`) clinical meal-plan PDF generation (`PDFExportService.swift`) with patient summary, sorted meals (`Desayuno`, `Snack`, `Comida`, `Cena`), macro breakdown, and clinical rationale.
- **UX, Localization & In-App Guidance**:
  - Contextual clinical question/insight banner (`ContextualAssistantView.swift`), searchable 9-guide / 6-FAQ help center (`HelpView.swift`), onboarding (`OnboardingView.swift`), system/light/dark appearance switcher (`AppearancePreference.swift`), haptic feedback (`HapticManager.swift`), and full English/Spanish localization (`NutriOptimize/{en,es}.lproj/Localizable.strings` + `Theme/L10n.swift`).

## Architecture and Source Map

- **Repository**: `chochy2001/NutriOptimize` (root `.`)
- **Nearest guidance**: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`
- **Manifests**: `project.yml` (canonical XcodeGen spec), `NutriOptimize.xcodeproj/project.pbxproj`, `.github/workflows/gitleaks.yml`, `.gitleaks.toml`, `.pre-commit-config.yaml`
- **Source root (`NutriOptimize/`)**:
  - `NutriOptimizeApp.swift` — `@main` entry point initializing `ModelContainer` (`PatientRecord`, `PatientFeedbackRecord`, `ConsultationRecord`, `LabResultRecord`, `PlanDraftRecord`) and `DemoDataSeeder`
  - `Models/` — `Patient.swift`, `Meal.swift`, `PlanOptimizationDraft.swift`, `ConsultationRecord.swift`, `LabResult.swift`, `RecommendationFeedback.swift`, `Professional.swift`, `ServiceError.swift`
  - `Services/` — `OpenRouterService.swift`, `PatientStore.swift`, `PDFExportService.swift`, `LabDocumentImporter.swift`, `DemoDataSeeder.swift`, `Protocols/`, `Mock/`
  - `ViewModels/` — `OptimizationDashboardViewModel.swift`, `PatientDetailViewModel.swift`, `DraftEditorViewModel.swift`
  - `Views/` — `RootCoordinatorView.swift`, `Splash/`, `Onboarding/`, `Dashboard/`, `Patient/`, `Draft/`, `Settings/` (`SettingsView.swift`, `DataProcessingConsentView.swift`), `Help/`, `Components/`
  - `Theme/` — `AppTheme.swift`, `AppearancePreference.swift`, `HapticManager.swift`, `L10n.swift`
  - `en.lproj/` & `es.lproj/` — `Localizable.strings` (`69` keys each) and `InfoPlist.strings` (`2` keys each)
- **Test root (`NutriOptimizeTests/`)**:
  - **14** XCTest suites (**156** unit tests): `DraftEditorViewModelTests.swift` (9), `LabDocumentImporterTests.swift` (18), `LocalizationTests.swift` (2), `MealModelTests.swift` (17), `MockOptimizationServiceTests.swift` (19), `OpenRouterServiceTests.swift` (21), `OptimizationDashboardViewModelTests.swift` (9), `PDFExportServiceTests.swift` (8), `PatientModelTests.swift` (17), `PatientStoreCRUDTests.swift` (10), `PatientStoreCascadeTests.swift` (2), `PlanDraftRecordRoundTripTests.swift` (5), `PlanOptimizationDraftTests.swift` (15), `ServiceErrorTests.swift` (4).

## Key Workflows

1. **Project Generation & Simulator Build/Test (macOS + Xcode 16+)**:
   - Regenerate project after file structure changes: `xcodegen generate`
   - Build: `xcodebuild build -project NutriOptimize.xcodeproj -scheme NutriOptimize -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`
   - Run all 14 unit-test suites: `xcodebuild test -project NutriOptimize.xcodeproj -scheme NutriOptimize -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`
2. **Clinical Plan Generation & Approval Flow**:
   - Select or create patient -> tap Generate Plan -> accept `DataProcessingConsentView` if using `OpenRouterService` (or use local `MockOptimizationService`) -> inspect/modify meals in `DraftEditorView` -> approve to persist `ConsultationRecord` -> export PDF via `PDFExportService`.
3. **Secret Scanning CI**:
   - `.github/workflows/gitleaks.yml` scans full repository history with `gitleaks 8.24.0` (`--config .gitleaks.toml --exit-code 1`) on every push and pull request.

## Integration Boundaries

| Boundary | Source Evidence | Target Evidence | Status |
|----------|-----------------|-----------------|--------|
| `OpenRouterService` -> OpenRouter Chat Completions API | `NutriOptimize/Services/OpenRouterService.swift:76-158` (`POST https://openrouter.ai/api/v1/chat/completions`, `google/gemini-2.5-flash`, JSON schema response, Keychain key, consent gate, `patient.pseudonym`) | External `https://openrouter.ai/api/v1/chat/completions` endpoint; offline fallback via `MockOptimizationService.swift` | `partial` (21 unit tests in `OpenRouterServiceTests.swift`; live calls require user BYO OpenRouter API key) |
| ViewModels / `PatientStore` <-> On-Device SwiftData & App Sandbox | `NutriOptimize/NutriOptimizeApp.swift:15-22`, `NutriOptimize/Services/PatientStore.swift`, `NutriOptimize/Views/Patient/ProgressPhotoView.swift` | On-device SwiftData SQLite store + `Documents/ProgressPhotos/` directory | `pass` (covered by `PatientStoreCRUDTests`, `PatientStoreCascadeTests`, `PlanDraftRecordRoundTripTests`) |
| `LabDocumentImporter` & `PDFExportService` <-> Local PDF/JSON Documents | `NutriOptimize/Services/LabDocumentImporter.swift`, `NutriOptimize/Services/PDFExportService.swift` | Local iOS file picker (`PDFKit` / `JSONDecoder`) & shareable US Letter PDF output (`UIGraphicsPDFRenderer`) | `pass` (covered by 18 + 8 unit tests) |

## Data, Storage, and Deployment

- **Local-only clinical persistence**: All patient profiles, consultations, lab results, plan drafts, feedback, and progress photos remain on the local iOS device (`SwiftData` + `Documents/ProgressPhotos/`). No cloud database or multi-tenant backend exists yet.
- **Credential & preference separation**: The OpenRouter API key is stored in the iOS Keychain (`kSecClassGenericPassword`, service `com.nutrioptimize.api`, `kSecAttrAccessibleAfterFirstUnlock`), while non-secret preferences (`custom_optimization_prompt`, `data_processing_consent_accepted`, `show_engine_debug`, `AppearancePreference`) reside in `UserDefaults`.
- **Distribution**: Currently configured as an XcodeGen iOS 17+ source project (`MARKETING_VERSION = 1.0.0`) without App Store / TestFlight provisioning profiles committed. Zero secrets or API keys appear in git or in this specification.

## Validation Evidence

Full validation records reside in `specs/001-ecosystem-doc-audit/audit/drift/nutrioptimize.md`.

| scope | command | status | reason | next_action |
|-------|---------|--------|--------|-------------|
| `docs` | Python localization & XCTest inventory check (`en.lproj` vs `es.lproj`, `NutriOptimizeTests/*.swift`, `project.yml`) | `pass` | Verified exact EN/ES key parity (`69/69` `Localizable.strings`, `2/2` `InfoPlist.strings`) and **156** unit tests across **14** XCTest suites wired in `project.yml`. | `none` |
| `swift` | `xcodebuild test -project NutriOptimize.xcodeproj -scheme NutriOptimize -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` | `blocked` | Requires macOS + Xcode 16+ + iOS Simulator (`xcodebuild` unavailable on Windows audit host; CI currently runs only `gitleaks.yml` on `ubuntu-latest`). | Run `xcodebuild test` on macOS (and optionally add a `macos-latest` test job in GitHub Actions). |
| `security` | `manual-review` + `git diff --check` | `pass` | Verified Keychain storage, consent gate (`ServiceError.consentRequired`), PHI pseudonymization (`patient.pseudonym`), cascade deletion, and zero committed secrets. | `none` |

## Documentation Drift Findings

### False pending items

- `FEATURES.md:343` places items **15–27** (`Historial de Consultas`, `Fotos de Progreso`, `Estudios de Laboratorio`, `Datos Demo`, `Verificación de Conexión API`, `Accesibilidad`, `Comidas Ordenadas`, `Registro de Consulta`, `Asistente Clínico Contextual`, `Importación PDF/JSON`, `Plantillas Rápidas`, `Centro de Ayuda`, `Guía de Contribución`) under a `## Funcionalidades Planificadas` heading even though all 13 are marked `✅ Implementado` and exist in `NutriOptimize/`. Only items **28–31** (`FEATURES.md:501-527`: appointments/calendar, per-patient engine config, remote backend sync, NOM-051/COFEPRIS compliance) are genuinely planned future work.

### Ghost code

- Documented Keychain API-key storage (`KeychainHelper`), mandatory `DataProcessingConsentView` (`hasDataProcessingConsent`), PHI pseudonymization (`patient.pseudonym`), `PatientStore` cascade deletion, `RootCoordinatorView` / `OnboardingView` / `SplashView`, `AppearancePreference`, full EN/ES localization (`L10n.swift` + `.lproj` files), and **8** additional XCTest suites (`DraftEditorViewModelTests`, `LabDocumentImporterTests`, `LocalizationTests`, `OptimizationDashboardViewModelTests`, `PatientStoreCRUDTests`, `PatientStoreCascadeTests`, `PlanDraftRecordRoundTripTests`, `ServiceErrorTests`) omitted from `README.md`.

### Stale claims

- `README.md:88,104-113,209-216` understated the test suite as `"84 pruebas unitarias organizadas en 6 suites"`, whereas `NutriOptimizeTests/` now contains **156** unit tests across **14** suites.
- `README.md:72,74` duplicated the 5-patient demo data bullet, and `NutriOptimize/NutriOptimize.xcodeproj/project.xcworkspace/contents.xcworkspacedata` remains as a minor nested workspace artifact inside the source folder alongside root `NutriOptimize.xcodeproj`.

### Unresolved claims

- Presentation time-savings estimates (`PRESENTATION.md:170`: `"de 45 minutos a 5 minutos"`) represent hackathon workflow targets rather than empirical clinical trial measurements, and macOS simulator test pass status + App Store signing remain pending execution on an Apple workstation.

## Known Limits and Risks

- All patient records reside strictly on the local iOS device (`SwiftData` without CloudKit or remote backup); uninstalling the app deletes local clinical data unless exported to PDF.
- Live meal-plan generation depends on a user-supplied OpenRouter API key and internet connectivity (gracefully falling back to local mock drafts when unconfigured).
- GitHub Actions currently validates secret scanning (`gitleaks.yml`) on `ubuntu-latest` but does not yet run `xcodebuild test` on `macos-latest`.

## Client Readiness

Readiness label: **Partial**.

NutriOptimize is feature-complete for single-practitioner iOS clinical demonstrations, pilot evaluations, and HCAI portfolio presentations, with strong privacy defaults (Keychain, explicit consent disclosure, PHI pseudonymization, cascade deletion) and 156 unit tests; promoting to **Ready** requires executing `xcodebuild test` on macOS, configuring Apple Developer signing/TestFlight, and completing clinical/regulatory review for commercial deployment.

## Next Steps

1. Execute `xcodebuild test -project NutriOptimize.xcodeproj -scheme NutriOptimize -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` on macOS (or add a `macos-latest` GitHub Actions workflow) to record live test pass evidence for all 156 unit tests.
2. Update `README.md` test counts (`156` tests / `14` suites) and remove the duplicate `## Funcionalidades Planificadas` heading in `FEATURES.md:343` plus the stray nested `NutriOptimize/NutriOptimize.xcodeproj/` metadata file.
3. Configure Apple Developer bundle signing and `PrivacyInfo.xcprivacy` declarations prior to TestFlight or App Store submission.

## Superseded or Historical Documentation

- `PRESENTATION.md` is a 10-slide hackathon pitch deck; where feature counts, test totals, or roadmap bullets differ from current source files, `project.yml`, `NutriOptimize/`, `NutriOptimizeTests/`, and this `MASTER_SPEC.md` take precedence.
