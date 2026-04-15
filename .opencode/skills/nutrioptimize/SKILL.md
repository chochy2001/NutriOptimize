---
name: nutrioptimize
description: Guidelines for NutriOptimize iOS nutrition app (Swift 5.9 + SwiftUI + SwiftData + MVVM)
---

# NutriOptimize Development Guidelines

iOS app for nutritionists. AI generates meal plan drafts that professionals review and approve.

## Tech Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI (iOS 17+)
- **Persistence**: SwiftData (local on-device)
- **Architecture**: MVVM with Protocols
- **Project Gen**: XcodeGen (project.yml)
- **Charts**: Swift Charts
- **AI Backend**: OpenRouter API (Gemini 2.5 Flash)
- **PDF**: UIGraphicsPDFRenderer (native)

## Commands
- Generate project: `xcodegen generate`
- Build: `xcodebuild -project NutriOptimize.xcodeproj -scheme NutriOptimize build`
- Test: `xcodebuild -project NutriOptimize.xcodeproj -scheme NutriOptimize -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`

## Structure
- `NutriOptimize/Models/`: 8 model files (Patient, Meal, etc.)
- `NutriOptimize/Services/`: 5 services + Mock/ + Protocols/
- `NutriOptimize/ViewModels/`: 3 view models
- `NutriOptimize/Views/`: Dashboard, Patient, Draft, Help, Settings, Components
- `NutriOptimizeTests/`: 84 unit tests across 6 test suites

## Conventions
- MVVM with Protocols for testability. All services have protocol abstractions.
- "Human-Centered AI": AI proposes drafts, nutritionist decides. Never auto-apply AI output.
- Use struct for models, enum with associated values for states.
- English for code, Spanish for UI text.
- Conventional commits (feat:, fix:, docs:).
- Never commit API keys. Use bun (not npm) for any JS tooling.
- 84 existing tests. All new code must have tests.
