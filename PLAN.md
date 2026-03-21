# Home Dashboard — Real-Time Intelligence (Hero, Score Card, Longevity Composite)


## What's Changing

Upgrading the first three sections of the Home screen to show **real data only** — no hardcoded numbers, no fake defaults.

---

### 1. Hero Section — Greeting + Narrative Insight Pill

**Features:**
- Time-of-day greeting ("Good morning, Sarah") using the design system's title typography
- Below the greeting: a small **pill/card** with an icon and a computed narrative insight
- The insight text is generated from real scan + HealthKit data (e.g. "Your skin is glowing today", "Hydration could use attention", "Great sleep is boosting your skin")
- If no data exists at all, the pill says "Complete your first scan to get insights"
- The insight updates every time the screen loads or refreshes

**Design:**
- Pill has a soft white/cream background with a subtle border, matching the existing chip style
- Left-aligned icon (SF Symbol matching the insight type — moon for sleep, drop for hydration, sparkles for skin)
- Text in the app's secondary text color, compact and elegant

---

### 2. Skin Score Card — Real Data Only

**Features:**
- Shows the latest scan score inside the existing luxury ring animation
- Displays the **last scan date and time** below the score (e.g. "Scanned 2h ago")
- **Trend arrow**: up/down/stable based on comparing 3+ scans — only shows if enough data exists
- If **no scan exists**: shows the "Take Your First Scan" empty state (already exists) — never a fake score
- If **no scan in 24 hours**: the score ring gets a **pulsing gold glow** and a "Scan Now" button appears below the score
- The fallback `guard stored > 0 else { return 72 }` in the longevity view model is **removed** — returns 0 instead
- Score animates in with the existing numeric text transition

**Design:**
- Pulsing glow on the ring when a scan is overdue (reuses the existing breathing shadow animation but more prominent)
- "Scan Now" button styled with the gold glass button style
- Last scan time shown as a subtle caption below the ring

---

### 3. Longevity Score Composite — 6-Factor Breakdown

**Features:**
- Shows the 6 longevity factors: Sleep (20%), HRV (15%), Skin (25%), Adherence (20%), Activity (10%), Circadian (10%)
- Each factor displayed as a row with: icon, name, mini progress ring, score value, and weight percentage
- **Real values only** from HealthKit — if a factor has no data, it shows "—" with a dimmed appearance and a subtle "Connect Apple Watch" link
- Tapping any factor opens a **bottom sheet** showing:
  - The factor's current score and source data details
  - A mini historical trend (last 7 entries from stored daily scores)
  - An explanation of how it affects skin health
- The composite score is calculated only from available factors (already handled in the view model)

**Design:**
- Factors arranged in a vertical list inside a GlassCard
- Each row: chrome icon badge on the left, factor name + detail text, mini ring on the right showing the score
- Unavailable factors (no Watch data) are dimmed with "—" score and a small "Connect Watch" text link
- Bottom sheet uses the app's presentation style with medium/large detents
- Historical trend shown as a simple line using Swift Charts

---

### Technical Changes

- **HomeViewModel**: Add narrative insight computation, last scan date tracking, scan-overdue detection, and per-factor data for the longevity breakdown
- **HomeView**: Replace greeting section with insight pill, add scan-overdue UI to score card, add longevity composite section with expandable factor sheets
- **SkinLongevityViewModel**: Remove the `guard stored > 0 else { return 72 }` fallback — return 0 when no scan exists
- **SkinHealthCorrelationService**: Add a method to generate the single most relevant narrative insight string from current data
