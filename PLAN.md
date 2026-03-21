# Correlation Insights, Historical View & Missing Data Handling

## Features

### 4. Correlation Insights
- Real-time insight cards generated from actual HealthKit data via `SkinHealthCorrelationService`
- Each insight shows an icon, descriptive text, and an action button (e.g. "Improve Sleep", "Hydrate", "Apply SPF")
- Insights include: poor sleep warning (sleep < 6h), HRV recovery status (vs personal average), UV overexposure alert (UV > 5), hydration reminder (water < 2L), activity boost, stress flare-up risk
- Cards appear in priority order — most urgent first
- Tap action button for contextual advice (navigates to relevant section or shows tip)
- Each insight card uses the existing `GlassCard` design with severity-based accent colors (gold for positive, amber for warning, red for critical)

### 5. Historical View
- Swift Charts `AreaMark` + `LineMark` showing composite longevity score over time
- Time range toggle: 7 days / 30 days / 90 days (added 7-day option to existing picker)
- Toggle individual factors on/off as chart overlays (sleep, HRV, skin, adherence, activity, circadian)
- Gold gradient fill under the main line, catmullRom interpolation for smooth curves
- Tap on a data point to see that day's full breakdown in a tooltip
- Computed correlation insight: e.g. "When you sleep 8+ hours, your skin score is 12% higher" — calculated from real stored `DailyLongevityScore` data, not a template

### 6. Missing Data Handling
- No Apple Watch: Show available factors (skin + adherence), gray out watch-dependent ones with a lock icon and "Requires Apple Watch" label
- No scan data: Show health-only factors, prominent "Take Your First Scan" card with scan button
- No supplement tracking: Show biometric factors only, hide adherence with a setup prompt
- Every missing source shows a clean empty state with a specific call-to-action
- Never display fake/default numbers — use `nil` and show "—" placeholder

## Design
- Insight cards: `CompactGlassCard` with severity-colored icon circle (radial gradient), bold title, descriptive body text, and a small action button
- Historical chart: Full-width `GlassCard` with the Swift Charts area chart, factor toggle chips as horizontally scrollable capsule buttons below the chart
- Correlation stat: A small highlighted callout card below the chart with a lightbulb icon and the computed correlation text
- Missing data states: Centered icon + message + CTA button, consistent with existing empty states in the app
- All animations use `CelleuxSpring.luxury`, staggered appearance delays, `.sensoryFeedback` on interactions

## Changes
- **SkinHealthCorrelationService**: Add method to generate actionable insight cards with action labels and computed correlations from stored data
- **SkinLongevityViewModel**: Add factor toggle state, correlation computation from `DailyLongevityScore` history, and missing-data detection helpers
- **SkinLongevityScoreView**: Add correlation insights section, upgraded historical chart with factor overlays + toggles, correlation callout, and improved missing-data empty states throughout
- **LongevityModels**: Add 7-day option to `HistoryPeriod` enum
