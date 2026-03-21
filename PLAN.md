# Aging Simulation — Predict Your Skin's Future


## Features

- **Aging Trajectory Projection** — Uses your current skin metrics (wrinkle depth, elasticity, hydration, texture, radiance) to simulate how your face may age over 5, 10, and 20 years
- **Dual Scenario Comparison** — See two futures side-by-side via a drag slider: "At Current Rate" (no routine) vs. "With CELLEUX Routine" (optimistic improvement trajectory)
- **Year Selector** — Tap between 5, 10, and 20 year projections; each applies progressively stronger aging effects
- **Simulated Score Projections** — Below the face comparison, see projected overall score and key metric scores for each scenario at the selected year
- **Medical Disclaimer** — Clear banner at the bottom: "Simulation only. Not a medical prediction."
- **Share Comparison** — Export the current slider view as an image to share

## Design

- **Dark cinematic background** matching the existing Before/After comparison screen (deep navy/black with subtle gold radial glow)
- **Slider overlay** — Draggable vertical divider splitting the face photo; left side shows "At Current Rate", right side shows "With CELLEUX Routine"
- **Year selector** — Three gold-accented capsule buttons (5Y / 10Y / 20Y) horizontally centered below the slider
- **Scenario labels** — "AT CURRENT RATE" on the left in amber/warm tone, "WITH CELLEUX" on the right in green/gold tone, using the app's signature uppercase tracking style
- **Projected scores section** — Two compact glass cards side by side showing projected overall score with a mini ring, plus 3 key metrics (Wrinkles, Elasticity, Hydration) as mini bars
- **Disclaimer** — Subtle caption text at the very bottom in the app's tertiary text color
- **Entry animation** — Face fades in with a subtle scale spring, year buttons stagger in, scores animate with number counting
- **Haptic feedback** on year selection changes

## Screens

- **Aging Simulation Sheet** — Full-screen sheet presented from the Scan Results screen via a new "Aging Simulation" button (placed near the existing comparison/share buttons). Contains:
  - Top header bar with title "AGING SIMULATION" and close button
  - Face photo with slider overlay comparing two aging scenarios
  - Year selector (5 / 10 / 20)
  - Projected score cards for both scenarios
  - Disclaimer text
  - Share button

## How It Works

- The simulation uses image processing filters (blur, contrast adjustment, noise, desaturation, sharpening) applied to the user's actual scan photo, calibrated by their real skin metric scores
- Lower current scores = more aggressive aging in the "At Current Rate" scenario
- The "With CELLEUX Routine" scenario assumes gradual metric improvement, resulting in a gentler aging progression
- No external AI model needed — all processing happens locally on-device using built-in image filters
