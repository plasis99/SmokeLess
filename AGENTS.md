# QuitFlow (SmokeLess) — Codex Instructions

## Project Overview
- **App**: SmokeLess — cigarette tracking app to help quit smoking
- **Bundle ID**: `com.perelygin.quitflow`
- **Stack**: Swift 6.1, SwiftUI, SwiftData, iOS 17+, SPM workspace
- **Architecture**: MV pattern (no ViewModels per global rules)

## Project Structure
```
QuitFlow/
├── QuitFlowPackage/        # All source code (SPM)
│   ├── Sources/
│   └── Tests/
├── QuitFlow.xcworkspace    # Open this in Xcode
└── .entire/                # Entire CLI (do not modify)
```

## Key Technical Details
- **App Group**: `group.com.perelygin.quitflow` (shared SwiftData for widget)
- **Widget**: `com.perelygin.quitflow.widget` (small + medium + interactive)
- **Watch App**: `com.perelygin.quitflow.watchkitapp` (WatchConnectivity sync)
- **Live Activity**: ActivityKit — wrapped in `#if os(iOS)` for watchOS compat
- **Localizations**: EN, RU, UK — all in-code (no .strings files)

## Platform Guards
All iOS-only APIs must be wrapped in `#if os(iOS)`:
- ActivityKit (Live Activity)
- StoreKit `requestReview`
- `.keyboardType` modifier
- `.persistentSystemOverlays`

## Build & Test
```bash
# Build (via XcodeBuildMCP or xcodebuild)
xcodebuild -workspace QuitFlow.xcworkspace -scheme QuitFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Tests
swift test --package-path QuitFlowPackage
```

## TODO(human)
<!-- Codex: Add project-specific priorities or focus areas here -->
