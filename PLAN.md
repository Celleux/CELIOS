# Streak & Achievements + Pull-to-Refresh Upgrade

## What's Changing

Upgrading the existing streak card and achievement card on the Home screen, and replacing the default pull-to-refresh with a custom gold-themed spinner with haptics.

---

### 7. Streak & Achievements

**Streak Card (upgrade existing):**
- Keep the current flame icon + day count with gold gradient
- Add a progress bar toward the next milestone (7 → 14 → 30 → 60 → 90 → 180 → 365 days)
- Show "X days to next milestone" label beneath the bar
- Haptic feedback on streak display

**Achievement Section (upgrade existing):**
- Show the latest unlocked achievement (existing) with a celebration shimmer on new unlocks
- Add "Next Achievement" card below: shows the closest locked achievement with a progress indicator
- Progress computed from real SwiftData data (scan count, streak length, longevity score, etc.)
- `.sensoryFeedback(.notification(.success))` triggers when a new achievement is detected during data load
- Particle burst animation (using existing `CelebrationParticleBurst` if available) on new unlock detection

**Achievement Checking Logic (in HomeViewModel):**
- On each `loadData`, check all `AchievementDefinition` cases against real data
- Auto-unlock achievements when conditions are met (e.g. streak ≥ 7 → unlock "Consistent")
- Track if a new unlock happened during this load to trigger celebration

---

### 8. Pull-to-Refresh

- Replace the default `.refreshable` with a custom implementation
- Gold-themed spinning ring animation at the top of the scroll view
- Ring uses the Celleux gold gradient, animates rotation while refreshing
- On pull trigger: `.sensoryFeedback(.impact)` fires
- Refreshes all HealthKit data + recalculates longevity scores + reloads SwiftData
- Smooth fade-in/out of the spinner
- Loading state tracked in HomeViewModel (`isRefreshing` flag)

---

### Files Modified
- **HomeView.swift** — Upgraded streak card, achievement section, custom pull-to-refresh spinner
- **HomeViewModel.swift** — Achievement checking logic, `isRefreshing` state, `nextAchievement` computed property, streak milestone computation
