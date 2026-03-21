# Health Correlation Dashboard — Real Data Visualization (Requirements 1–3)

## Features

### 1. Correlation Cards (5 factors: Sleep, Stress, Hydration, UV, Activity)
- Each factor gets a premium GlassCard showing the factor name, icon, current value from HealthKit, and computed impact score
- 7-day sparkline chart (Swift Charts LineMark) using stored DailyLongevityScore records from SwiftData — no extra HealthKit queries
- Impact indicator label: "Strong positive", "Moderate positive", "Neutral", "Negative impact" — computed from the real score
- Color-coded: Gold tint for positive impact, Silver for neutral, Muted red for negative
- Tapping a card opens a **bottom sheet** with detailed breakdown, historical chart, and actionable insight for that factor
- Bottom sheet uses `.presentationDetents([.medium, .large])` so users can peek or dive deep
- Haptic feedback (`.sensoryFeedback(.selection)`) on card tap

### 2. Sleep–Skin Correlation
- New section with a **scatter plot** (Swift Charts PointMark) showing sleep hours vs. next-day skin score
- Data pulled from stored DailyLongevityScore + SkinScanRecord in SwiftData
- Gold dots for each data point
- Dashed gold **trend line** (LineMark regression) overlaid on the scatter
- Shaded **confidence band** (AreaMark) around the trend line
- Dynamically computed insight text: e.g. "Nights with 7.5+ hours → 8% better skin scores" — calculated from real stored data, never hardcoded
- Shows sleep breakdown: total hours, deep sleep %, REM %
- If fewer than 5 data points, shows a note: "Keep scanning to unlock sleep-skin insights"

### 3. Stress Visualization
- HRV trend chart: **AreaMark with gold gradient fill + LineMark** (catmullRom interpolation) — consistent with the rest of the app
- 7-day HRV data from stored DailyLongevityScore records
- State of Mind mood entries displayed as colored dots overlaid on the chart (if available)
- Combined stress risk level badge (Low / Moderate / High) from existing `SkinHealthCorrelationService` computation
- Insight generation from real mood + HRV correlation: e.g. "Low HRV + negative mood increases cortisol-driven skin damage"
- If no mood data: shows HRV-only stress assessment with prompt to log mood

## Design

- Keeps the existing luxury Celleux aesthetic: GlassCard, CelleuxColors, gold/silver/champagne palette
- Staggered appear animations on all new sections
- All charts use Swift Charts with gold gradient styling consistent with existing charts
- Bottom sheet detail views have a clean layout: icon header, metric value, full-width chart, and insight card
- Missing data shows elegant empty states with CTA (e.g. "Connect Apple Watch for stress insights") — never fake numbers
- `.sensoryFeedback(.selection)` on interactive elements

## Screens / Sections

- **Correlation Cards section** — Vertical stack of 5 GlassCards replacing the existing donut chart factor breakdown
- **Sleep–Skin Correlation section** — New section with scatter plot and computed insight
- **Stress & Recovery section** — Upgraded stress section with HRV area chart and mood overlay
- **Factor Detail Bottom Sheet** — Reusable sheet that shows deep-dive for any tapped factor
- Existing sections (Overall Score, Mood Trend, Insights, Skin Impact Guide) remain and are refined to work with the new layout

## Files Changed
- **HealthCorrelationView** — Major rewrite with new correlation cards, sleep-skin scatter, stress chart, and factor detail sheet
- **SkinHealthCorrelationService** — Add method to compute sleep-skin correlation stats from stored data, and a regression helper for the trend line
- **HealthKitService** — No changes needed (using stored DailyLongevityScore instead)
