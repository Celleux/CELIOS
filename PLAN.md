# Home Dashboard — Protocol, Health Snapshot & Weekly Trend

## Features

### 4. Today's Protocol (Upgrade existing card)
- Add a **next dose countdown timer** that shows time remaining until the next incomplete dose (e.g. "Next in 2h 14m")
- Animated checkmarks use `.symbolEffect(.bounce)` on completion toggle
- `.sensoryFeedback(.success)` fires when marking a dose complete
- Real completion status pulled from SwiftData `SupplementDose` records (already wired)
- Morning/Midday/Post-Workout/Evening doses from circadian schedule

### 5. Health Snapshot (New section)
- **3-card horizontal scroll** below the protocol card: **Sleep**, **HRV**, **Hydration**
- Each card is a compact GlassCard showing:
  - Icon + metric name header
  - Real value from HealthKit (e.g. "7.2h", "42 ms", "1200 mL")
  - A mini sparkline chart (tiny LineMark from Swift Charts) showing recent trend
- If no Apple Watch / no data: show a single elegant empty state card with "Connect Apple Watch for deeper insights"
- Never shows mock or fake data — only real HealthKit readings

### 6. Weekly Trend (Replace existing chart)
- Replace the custom Path-based chart with **Swift Charts** `AreaMark` + `LineMark`
- Gold gradient fill under the line with `.catmullRom` interpolation for smooth curves
- Tap on a data point to highlight that day's score in an overlay annotation
- If fewer than 7 data points, show available data with a subtle note
- Time range stays at 7 days (matching existing behavior)

## Design
- All new sections use the existing Celleux design system: GlassCard, CompactGlassCard, CelleuxColors (gold, silver palette), CelleuxType, CelleuxSpring animations
- Health snapshot cards use horizontal ScrollView with `.contentMargins(.horizontal, 16)`
- Countdown timer text in warm gold with a pulsing dot indicator
- Weekly chart uses gold gradient fill (`CelleuxColors.goldGradient` tones) with a selected-day annotation bubble
- Staggered appear animations continue the existing sequence timing
- Haptic feedback on all interactive elements

## Changes
- **HomeView.swift** — Upgrade `todaysProtocolCard` with countdown timer + haptics; add new `healthSnapshotSection`; replace `weeklySnapshotCard` chart with Swift Charts implementation
- **HomeViewModel.swift** — Add computed properties for next dose countdown, health snapshot data (sleep/HRV/hydration values + mini history), and selected day state for the weekly chart
