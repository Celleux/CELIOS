# Region Detail Bottom Sheet + Top 6 Comparison Metrics

**What's changing:**

Two targeted upgrades to the scan results screen based on your design decisions.

---

### 1. Region Card → Bottom Sheet Expansion

**Current:** Tapping a region card expands it inline, pushing other cards down (causes layout jank in the 2×3 grid).

**New:**
- Tapping a region card opens a **bottom sheet** with `.medium` and `.large` detents
- Sheet shows the region name, overall region score with a ring, and all applicable metric scores for that region
- Each metric row shows: icon, name, score bar, and score value
- Haptic feedback (`.selection`) on tap
- Drag indicator visible at top
- The results grid stays untouched behind the dimmed overlay — no layout shifts
- Sheet uses the existing `GlassCard` and `CompactGlassCard` design components
- `.presentationContentInteraction(.scrolls)` so content scrolls naturally in the sheet

### 2. Comparison Sheet → Top 6 Metrics

**Current:** The scan comparison sheet shows all 10 metrics, causing scroll fatigue.

**New:**
- Show only 6 key metrics by default: **Texture, Hydration, Brightness, Redness, Pore Visibility, Tone Uniformity**
- Leave out Under-Eye, Wrinkles, Elasticity (niche), and Overall (already shown as hero number)
- Add a **"See All Metrics"** expand button at the bottom
- Tapping it reveals the remaining metrics with a smooth animation
- Keeps the comparison scannable at a glance while still offering full detail on demand

---

*No changes needed for Share Image (already uses ImageRenderer) or Charts (already uses Swift Charts with AreaMark + gold gradient + catmullRom).*