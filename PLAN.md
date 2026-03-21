# AR Before/After Comparison — Slider, Time-lapse & Branded Export

## Features

- **Slider Comparison** — Drag a gold-accented slider left and right over two scan photos to reveal "before" vs "after" in real time
- **Metric Badges Overlay** — Small floating badges appear over face regions (forehead, cheeks, chin, etc.) showing score changes with green ↑ or amber ↓ arrows
- **Time-lapse Mode** — Auto-play button crossfades through all historical scans, plus a manual scrubber timeline slider to drag through scan history
- **Compare from History** — Select any two scans from Scan History to open the comparison view
- **Branded Export** — Generate a shareable image card with the CELLEUX logo, dates, overall scores, side-by-side photos, and gold/chrome accents
- **Share Sheet** — Export the branded comparison card via the standard iOS share sheet

---

## Design

- **Dark, cinematic background** — Deep near-black background matching the existing scan aesthetic, with subtle gold radial glows
- **Slider handle** — A vertical gold line with a circular chrome drag handle in the center; the "BEFORE" and "AFTER" labels float at the top corners
- **Metric badges** — Small glass-pill badges (translucent white with gold border) positioned near each face region, showing the score delta (e.g. "+5 ↑" in green or "−3 ↓" in amber)
- **Time-lapse scrubber** — A horizontal timeline bar at the bottom with gold dots for each scan date; a play/pause button centered below the photo area
- **Branded export card** — White card with chrome border, CELLEUX wordmark top-center, side-by-side scan photos with dates underneath, overall scores in large typography with a delta badge between them, and gold gradient accent line at the bottom
- **Transitions** — Spring animations for slider, crossfade for time-lapse, staggered appear for badges

---

## Screens

### Before/After Comparison (Full-screen sheet)
- **Entry**: "Compare" button added to each scan row in Scan History — tap one scan, then pick a second scan to compare
- **Top bar**: "BEFORE / AFTER" label centered, close button top-right, date labels for each scan
- **Photo area**: Full-width photo with the drag slider overlaying "before" (left) and "after" (right)
- **Toggle bar**: Switch between "Slider", "Side by Side", and "Time-lapse" modes
- **Metric badges**: Toggle button to show/hide floating score-change badges on the photo
- **Bottom actions**: "Share Comparison" button to generate and share the branded export card

### Time-lapse Sub-mode
- Replaces the slider with a single photo view that crossfades between scans
- Horizontal scrubber with dots for each scan, draggable
- Play/pause button for auto-cycling (2-second intervals)
- Date and score update as the active scan changes

### Scan History (Updated)
- Each scan row gets a small "Compare" button (or long-press context menu)
- After tapping Compare on one scan, a selection mode highlights the second scan to compare against
- Selecting the second scan opens the Before/After Comparison sheet

### Branded Export Card (Generated image for sharing)
- CELLEUX wordmark at top
- Two scan photos side by side with rounded corners
- Dates below each photo
- Large overall scores with a delta indicator between them
- Gold accent line at bottom
- Rendered as a UIImage for sharing via the existing share sheet
