# Progress Tracking & 90-Day Skin Transformation Challenge

## Features

### 4. Progress Tracking (Achievement Auto-Check)
- **After every dose completion**, achievements are automatically re-evaluated (scan milestones, streaks, ritual adherence, etc.)
- **After HealthKit data refreshes**, sleep tracking days and HRV tracking days are counted and stored, then achievements are re-checked
- **Popup queue system** ensures only one achievement unlock overlay shows at a time — additional unlocks wait in line and appear sequentially with a short delay between each
- Achievement checks also trigger after mood check-ins and protocol toggles

### 5. 90-Day Skin Transformation Challenge
- **Start the challenge** from a card on the Home tab or a dedicated section in the Profile tab
- **Daily check-in** counts as either completing a skin scan OR a protocol dose that day
- **Progress ring** shows days completed out of 90, with percentage and days remaining
- **Milestone markers** at days 7, 14, 30, 60, and 90 — each milestone shows a special badge and celebratory message when reached
- **Before/after comparison** at completion: starting score vs. ending score, a trend chart of the full 90-day journey, and individual metric changes (texture, hydration, radiance, etc.)
- **Restart anytime** — users can abandon and restart, or start a new challenge after completing one

---

## Design

### Progress Tracking
- No new UI needed — works silently in the background
- The existing gold achievement unlock overlay and queue system handles the display

### 90-Day Challenge — Home Card
- A compact gold-accented card on the Home tab (below the streak/achievement section)
- Shows a circular progress ring (gold gradient) with "Day X / 90" in the center
- Below the ring: current streak within the challenge + next milestone label
- If not started: a "Begin Your Transformation" call-to-action card with a subtle shimmer

### 90-Day Challenge — Full View (from Profile)
- Large hero progress ring at the top with day count and percentage
- **Milestone timeline** — a vertical line with 5 milestone dots (7, 14, 30, 60, 90), filled gold when reached, silver when locked
- Each reached milestone shows the date it was achieved
- **Daily check-in calendar** — a grid of the last 30 days showing green dots for checked-in days, gray for missed
- **Before/After section** (visible after day 7+): side-by-side score comparison with animated number transitions
- **Metric breakdown**: each metric (texture, hydration, radiance, tone, under-eye, elasticity) with start → current values and delta arrows
- **90-day trend chart** showing overall score progression
- "Restart Challenge" button at the bottom (with confirmation)

---

## Pages / Screens

- **Home Tab** — new compact challenge card added to the existing scroll content
- **Profile Tab** — new "90-Day Challenge" navigation link opening the full challenge detail view
- **ChallengeDetailView** — full-screen view with progress ring, milestone timeline, calendar, before/after comparison, and trend chart

---

## New Data

- A new data model to store: challenge start date, baseline score, baseline metrics, milestone dates, whether it's active/completed, and daily check-in records
- Registered in the app's data container alongside existing models
