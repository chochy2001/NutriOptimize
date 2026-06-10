# CLAUDE.md

NutriOptimize is a personal iOS/SwiftUI project (`chochy2001/NutriOptimize`). It
is a clinical nutrition assistant: nutritionists manage patients and generate
meal-plan proposals that they review, edit, approve, and export to PDF.

## Stack

- Xcode 16+ project generated from `project.yml` via `xcodegen`. The committed
  source of truth is `project.yml`; run `xcodegen generate` after adding or
  removing files, then commit the updated `NutriOptimize.xcodeproj`.
- SwiftUI + SwiftData (`@Model` records persisted locally on device).
- iOS 17 deployment target, Swift 5.9.
- Optimization engine: OpenRouter (`google/gemini-2.5-flash`). The API key is
  stored in the Keychain and is optional; without it the app generates clearly
  labeled local demonstration drafts.

## Build & test

- List schemes: `xcodebuild -list -project NutriOptimize.xcodeproj`
  (scheme: `NutriOptimize`).
- Build: `xcodebuild build -project NutriOptimize.xcodeproj -scheme NutriOptimize
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`.
- Test: same command with `test` and the `NutriOptimizeTests` target.

## CI

- CI runs on GitHub-hosted runners (`ubuntu-latest`) only. This is a personal
  repository with no self-hosted runner access; do not add self-hosted runner
  labels or external deployment infrastructure.
- The only workflow today is `gitleaks.yml` (secret scanning).

## Privacy

- Patient data is stored locally via SwiftData. When the optimization engine is
  configured, the patient's clinical profile (without their full name) is sent
  to OpenRouter/Gemini only after the professional accepts the in-app
  data-processing disclosure. Keep this consent gate intact.

## Conventions

- Do not modify signing settings, bundle IDs, provisioning profiles, or
  entitlements unless explicitly requested.
- Keep Swift/SwiftUI/UIKit style consistent with nearby files.
- Do not commit secrets, API keys, or local Xcode user data.
- User-facing copy is localized in `NutriOptimize/{en,es}.lproj/Localizable.strings`
  with typed accessors in `NutriOptimize/Theme/L10n.swift`.
