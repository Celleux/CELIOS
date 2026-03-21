# Performance Audit & Accessibility Polish

## What's Changing

A comprehensive polish pass across the entire app focusing on **performance optimization** and **full accessibility support**.

---

### 1. Performance Audit

**Gradient & Shadow Optimization**
- Move all inline gradients (gold, silver, chrome, glass borders) to static constants in the design system so they're created once, not on every view render
- Group shadow application to container cards instead of individual sub-elements where stacking occurs

**ARKit Session Management**
- Pause the AR face tracking session when the user navigates away from the Scan tab
- Resume the session when the user returns — saves battery and GPU resources

**Lazy Loading for All Scrollable Content**
- Convert remaining `VStack` inside `ScrollView` to `LazyVStack` in history views, insights, health correlation, and profile
- Ensures only visible content is rendered, especially for long lists

**Chart Data Precomputation**
- Precompute chart data arrays in the view model before passing to Chart views, avoiding recalculation on every render

---

### 2. Accessibility

**VoiceOver Labels on All Interactive Elements**
- Add descriptive labels to every button, card, tab bar item, score ring, metric display, and chart
- Add `accessibilityValue` for all scores and metrics (e.g. "82 out of 100")
- Add `accessibilityHint` for key actions (e.g. "Opens scan history")

**Meaningful Chart & Ring Descriptions**
- Score rings will announce their value and context (e.g. "Skin score 82 out of 100, improving")
- Charts will have summary descriptions (e.g. "Weekly skin score trend, ranging from 75 to 88")
- Factor rows will combine icon, name, and score into a single accessible element

**Minimum 44pt Tap Targets**
- Audit all buttons and tappable areas to ensure minimum 44×44pt touch targets
- Fix any undersized chip/tag buttons in mood check-in and time range selectors

**Dynamic Type Support**
- Replace all fixed `.system(size:)` fonts in the design system (`CelleuxType`) with scaled variants using `.font(.system(size:).leading(.tight))` combined with `@ScaledMetric` where needed
- Key content areas (greeting, protocol items, insights, metric values) will respect the user's preferred text size

**Reduce Motion Support**
- Detect the system "Reduce Motion" preference
- Replace spring animations with simple opacity fades when Reduce Motion is enabled
- Disable the particle view, shimmer effects, and pulsing dots when Reduce Motion is on
- The `staggeredAppear` modifier will use a simple fade instead of offset + scale

**Contrast Improvements**
- Audit all text colors against their backgrounds for WCAG AA minimum
- Adjust `textLabel` and `textTertiary` opacity to ensure readability on light card surfaces
- Ensure gold-on-white elements have sufficient contrast

---

### Files That Will Be Modified
- Design system (gradients, typography, accessibility helpers)
- All main views (Home, Scan, Insights, Ritual, Profile, and their sub-views)
- Content view (tab bar accessibility)
- AR face tracking view (session pause/resume)
- View models (chart data precomputation)
