# Prepare project for WidgetKit target addition

## Completed
- [x] Fix unicode escape syntax in HealthCorrelationView.swift
- [x] Fix Color init(hex:) nonisolated for concurrency safety
- [x] Fix ARFaceTrackingView MTLDevice access from nonisolated context
- [x] Fix HealthKitService readTypes let constant
- [x] Add widget extension target to project.pbxproj
- [x] Set up App Groups for data sharing (both main app + widget entitlements)
- [x] Create minimal widget Swift files in separate CelleuxWidget/ directory
- [x] Create widget Info.plist with NSExtensionPointIdentifier

- [x] Upgrade widget views (circular, rectangular, systemSmall) with premium gold design
- [x] Add widget data writing from HomeViewModel with WidgetCenter refresh
- [x] Verify clean build

- [x] Upgrade systemMedium widget with Texture/Hydration/Radiance metrics + mini bars
- [x] Add interactive "Scan Now" AppIntent button to systemMedium widget
- [x] Add systemLarge StandBy widget with full-screen score ring on dark background
- [x] Create ScanActivityAttributes for Live Activity (shared between app + widget)
- [x] Implement ScanLiveActivity with Dynamic Island (compact/expanded/minimal)
- [x] Implement Lock Screen Live Activity view with progress bar + metric pills
- [x] Integrate Live Activity start/update/end into SkinScanViewModel scan flow
- [x] Add NSSupportsLiveActivities to Info.plist via pbxproj
- [x] Share actual scan metric scores (texture, hydration, radiance) to widget via App Group
- [x] Update widget data after each scan completion in SkinScanViewModel
