# Environmental Factors, Interactive Charts & Missing Data Handling


## Features

### 4. Environmental Factors Section
- **UV Exposure Card**: Shows today's UV dose from HealthKit, risk level indicator (Low/Moderate/High/Very High), and a 7-day UV trend sparkline
- **Water Intake Card**: Shows today's water intake in mL/L vs. 2.5L target, progress ring, and 7-day hydration trend
- **Wrist Temperature Card**: Shows the latest wrist temperature delta from Apple Watch, with context ("Above/Below baseline"), and 7-day trend
- **Impact Over Time Chart**: Combined chart showing how UV, hydration, and temperature correlate with skin scores over time — AreaMark for skin score, LineMark overlays for each environmental factor

### 5. Interactive Charts Upgrade
- **Gold gradient AreaMark** as the primary metric layer on all historical charts
- **LineMark overlays** for secondary metrics with distinct colors (silver for sleep, blue for hydration, amber for UV)
- **Tap-to-select data points**: Tap any point on a chart to see a detail popover with exact date, value, and context
- **Time range toggle**: Segmented picker for 7D / 30D / 90D on all trend charts with smooth animated transitions
- **Haptic feedback** (`.sensoryFeedback(.selection)`) when switching time ranges

### 6. Missing Data Handling
- **No Apple Watch detected**: Show a dedicated banner at the top listing which factors need watch data (HRV, Sleep, Wrist Temp, Activity)
- **"Connect Apple Watch" prompt**: Explains benefits of watch data for skin-health insights, with a button to open the Health app
- **Partial data display**: Show scan-based data (skin scores) and manually logged data (water intake) even without a watch — never hide available data
- **Per-factor empty states**: Each card shows a clean empty state with the specific data source needed ("Requires Apple Watch" or "Log water in Health app")
- **Never fake data**: All empty states show "—" values and descriptive CTAs instead of placeholder numbers

## Design
- Environmental factor cards use the existing `GlassCard` and `CompactGlassCard` components
- UV card uses amber/gold tones, Hydration uses a soft blue accent, Temperature uses silver tones
- Charts follow the existing gold gradient style with catmullRom interpolation
- The "Connect Apple Watch" banner uses a subtle silver-bordered card with an Apple Watch icon
- Time range picker uses the native segmented control style consistent with the existing `FactorDetailSheet`

## Screens
- All changes are within the existing **Health Correlation** screen (`HealthCorrelationView.swift`)
- New **Environmental Factors** section added between the Stress section and Mood Trend chart
- New **Watch Connection** banner appears at the top when no watch data is detected
- Updated **Factor Detail Sheet** gets the interactive chart upgrade with time range toggle and tap-to-select
