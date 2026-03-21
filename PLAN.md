# Insights Feed — Personalized Intelligence Engine & Card UI

## Features

**1. Insight Generation Engine**
- New `InsightEngine` class that pulls real data from four sources: skin scan history, HealthKit correlations, supplement dose records, and circadian timing alignment
- Generates insights only when underlying data exists — never fabricates numbers
- Sorts insights by relevance (highest impact + newest first)

**2. Five Insight Types — All Data-Driven**
- **Trend Alerts**: Detects when any skin metric (texture, hydration, redness, etc.) changes by 3+ points across 3 or more scans, e.g. "Your texture score improved 5 points this week"
- **Correlation Discoveries**: Finds statistical patterns in historical data (sleep vs. skin, hydration vs. redness), e.g. "When you sleep 8+ hours, your redness drops 15%"
- **Action Items**: Flags when current metrics fall below your personal baseline (low hydration, poor sleep, high UV), with a specific next step
- **Celebrations**: Triggers when you hit a new personal best on any score
- **Weekly Summary**: Auto-generated every Sunday evening summarizing skin score change, sleep quality trend, and adherence percentage

**3. Insight Card Feed UI**
- Vertical scrolling feed of glass cards, each showing: themed icon, title, body text, relative timestamp, and an optional action button
- Cards appear with staggered entrance animation
- Tap a card to expand it with a smooth matched geometry transition, revealing full detail and suggested action
- Pull-to-refresh regenerates all insights with the gold spinner animation
- Haptic feedback on card tap
- If fewer than 3 scans exist: shows a friendly "Scan more to unlock personalized insights" prompt instead of the feed
- If no HealthKit data: shows scan-only insights with a prompt to connect Apple Watch
- Existing chart sections (skin score trend, mood correlation, score breakdown, health correlation link, recent activity) remain below the new insight feed

**4. Encouraging Narrative Tone**
- All text is warm and supportive — "Your skin is responding well" not "Score: 78"
- References your specific patterns and habits
- Every insight includes a concrete next step

## Design

- Each insight card uses the existing `GlassCard` with a colored accent strip on the left edge: gold for celebrations, silver for trends, soft amber for action items, champagne for correlations, muted for weekly summaries
- Icon badge uses `ChromeIconBadge` with context-appropriate SF Symbol
- Expanded card shows additional detail text and an action button styled with `GlassButtonStyle`
- The existing timeframe picker, charts, correlation card, mood section, score breakdown, and recent activity sections remain at the bottom of the scroll — the insight feed sits at the top as the new hero content
- Maintains the existing Celleux mesh background and design system throughout
