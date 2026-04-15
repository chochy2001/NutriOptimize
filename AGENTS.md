# NutriOptimize Agent Guidelines

This repository is an Apple/Xcode project.

## Stack
- Xcode project under `NutriOptimize.xcodeproj`.
- Treat signing, bundle IDs, provisioning, entitlements, and store metadata as sensitive.

## Commands
- Inspect schemes with Xcode or `xcodebuild -list -project NutriOptimize.xcodeproj`.
- Build only when the target/scheme is known: `xcodebuild -project NutriOptimize.xcodeproj -scheme <scheme> build`.

## Rules
- Do not modify signing settings, bundle IDs, provisioning profiles, or entitlements unless explicitly requested.
- Keep Swift/SwiftUI/UIKit style consistent with nearby files.
- Do not commit secrets, API keys, or local Xcode user data.
- Validate with the narrowest available scheme/build command and report any missing simulator/signing requirement.
