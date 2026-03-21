# Skin Longevity Score — Real HealthKit Integration (Parts 1-3)

## What's Changing

### 1. Fix Hardcoded Fallback — Optional Skin Score
- The longevity composite score will become **optional** — if no skin scan exists, the score shows as empty instead of a misleading number
- The longevity score view will show a **"Take Your First Scan"** call-to-action card when no scan data is available, with a viewfinder icon and styled in the existing GlassCard design
- The hero ring will show an empty/dashed state when no composite score exists
- Factor cards for "Skin Analysis" will show "No scan yet" with a prompt to scan, instead of displaying 0

### 2. Real Composite Scoring with Proper Mappings
- **Sleep Score**: Maps total hours to a curve — 7-9h = 90-100, 6h = 60, <5h = 20-40. Deep sleep and REM percentages weighted in (40% deep, 30% REM, 30% duration)
- **HRV Score**: Age-adjusted percentile mapping — HRV ≥60ms = 85+, 40-60ms = 55-85, 20-40ms = 25-55, <20ms = low. Uses personal baseline when available
- **Skin Score**: Reads latest scan's `overallScore` from SwiftData (not just UserDefaults). Returns nil if no scan → triggers empty state
- **Adherence Score**: Percentage of today's supplement doses completed from SwiftData `SupplementDose` records. Streak bonus: +5 for 7+ days, +10 for 14+, +15 for 30+
- **Activity Score**: Maps active calories toward WHO target (300 kcal/day ≈ 150min/week moderate). VO₂ max component weighted 50/50 with calories
- **Circadian Score**: Measures how close supplement timing matches circadian windows. Uses wrist temperature rhythm + sleep schedule consistency

### 3. Real-Time Updates
- HealthKit data **auto-refreshes on view appear** and then **every 15 minutes** via a background timer while the view is visible
- When scores recompute, values animate smoothly using spring animations and `.contentTransition(.numericText)`
- A **"Last updated" timestamp** appears below the hero score — e.g. "Updated 2 min ago" — and updates live
- The timer pauses when the view disappears and resumes when it reappears
- A subtle pulse animation on the ring when data refreshes to signal freshness

### Files Modified
- **SkinLongevityViewModel** — Optional composite score, improved scoring algorithms, refresh timer, last-updated tracking
- **SkinLongevityScoreView** — Empty state CTA, animated transitions, last-updated label, timer lifecycle
- **LongevityModels** — No structural changes needed
