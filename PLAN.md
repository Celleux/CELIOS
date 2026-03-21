# Breathing Timer, Adherence Data, and Empty States for Daily Ritual


## What's Being Built

Three additions to the Daily Ritual / Circadian Timing screen:

---

### **Feature 1: Breathing Timer**
- A new **breathing guide section** that appears when a dose card is being completed — encouraging mindful supplement application
- **Gold ring animation**: expands over 4 seconds (inhale), contracts over 4 seconds (exhale), using KeyframeAnimator for smooth organic motion
- **Phase labels**: "Inhale..." and "Exhale..." text that fades between phases
- **Haptic pulse** on each inhale↔exhale transition (soft impact)
- **"Hold during application" countdown** — a 30-second timer with a circular progress ring; after 30s, it auto-dismisses with a success haptic
- Triggered via a "Start Ritual" button on the active dose card; appears as a full-width card above the dose cards

### **Feature 2: Adherence Data & Streak Celebrations**
- **Weekly adherence percentage** displayed in the clock hero section (e.g. "87% this week") — calculated from SupplementDose records in SwiftData for the current 7-day window
- **Streak counter** added to the Circadian Timing view — shows current day streak with the flame icon and gold styling (matching the Home screen's streak card design)
- **Milestone celebrations**: when streak hits 7, 14, 30, 60, or 90 days, a gold particle burst + bounce animation plays on the streak badge
- **Streak milestone progress bar** showing distance to next milestone
- All data sourced from existing SupplementDose SwiftData records — no new models needed

### **Feature 3: Empty States**
- If no Apple Watch sleep schedule is available, **default to 7:00 AM wake / 11:00 PM sleep** (already partially in place — will be made explicit with UI messaging)
- A subtle **"Connect Apple Watch for personalized timing"** banner appears at the top when HealthKit sleep data is unavailable — styled as a compact glass card with a watch icon
- All dose scheduling **remains fully functional** without watch data — the banner is informational only, not blocking
- If no doses have been completed today, show an encouraging message: "Start your ritual to build momentum"
