# QuitFlow (SmokeLess) — Project Instructions

> For shared iOS/Swift coding guidelines, see `~/.claude/CLAUDE.md`

## Project
- **App**: SmokeLess (SmokeLessMD on App Store)
- **Bundle ID**: `com.perelygin.quitflow`
- **Path**: `/Users/plasis/Developer/QuitFlow`
- **Package**: `/Users/plasis/Developer/QuitFlow/QuitFlowPackage`
- **Stack**: Swift 6.1, SwiftUI, SwiftData, iOS 17+, SPM workspace
- **Architecture**: MV pattern (no ViewModels, but `MainViewModel` exists historically)
- **App Group**: `group.com.perelygin.quitflow`

## Targets
- `QuitFlow` — iOS app
- `QuitFlowWatch` — watchOS app (`com.perelygin.quitflow.watchkitapp`)
- `QuitFlowWidgetExtension` — Widgets + Interactive Widget (`com.perelygin.quitflow.widget`)

## Key Features
- Cigarette logging with SwiftData persistence
- 30-day statistics (bar chart, trends)
- Achievements page (streak + 6 health milestones)
- Settings (language, price, pack size, notifications, reset)
- Money saved card (when cigarette price set)
- Siri shortcuts, VoiceOver, 3 languages (EN/RU/UK)
- Widget (small + medium + interactive toggle)
- Live Activity (Lock Screen + Dynamic Island)
- Apple Watch (one-tap log, timer, WatchConnectivity sync)
- StoreKit review prompt (3+ days, 10+ cigarettes, 90-day cooldown)

## Platform Guards
All iOS-only APIs wrapped in `#if os(iOS)`:
- ActivityKit, StoreKit `requestReview`, `.keyboardType`, `.persistentSystemOverlays`

## Build & Run
- Use XcodeBuildMCP tools (not raw xcodebuild)
- `build_sim` with `preferXcodebuild: true`
- Simulator: iPhone 17 Pro (UUID: 02F05091-7A97-4C92-948D-6EAE5129DF75)
- If DerivedData corrupt: `rm -rf ~/Library/Developer/Xcode/DerivedData/Build`

## Key Files
- `QuitFlowPackage/Sources/QuitFlowFeature/` — all feature code
- `LiveActivityManager.swift`, `CigaretteActivityAttributes.swift` — Live Activity
- `WatchConnectivityService.swift` — Watch sync (Sendable-safe)
- `WatchMainView.swift` — Watch UI with haptic feedback
