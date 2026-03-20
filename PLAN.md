# Enhance Design System — Luxury Typography, Shadows, Springs, Spacing & Glassmorphism

**What's changing:** Upgrading the existing design system file with new luxury design tokens and enhanced glass card visuals, while removing all purple/violet colors.

---

### **1. Typography System**
- Add a `CelleuxType` set of pre-built font styles: display (ultra-light 48pt), title (light 32pt), headline (regular 18pt), body (regular 16pt), caption (light 12pt), label (bold 8pt uppercase), and metric (thin 56pt)
- All letter-spacing and line-spacing baked in — no weight heavier than semibold anywhere

### **2. Three-Tier Shadow System**
- Add `CelleuxShadow` with three depth levels: tight (subtle close shadow), medium (card-level depth), and ambient (soft far shadow)
- All three shadows automatically applied to every glass card for a realistic depth illusion

### **3. Spring Animation Tokens**
- Add `CelleuxSpring` with three named animations: luxury (slow & smooth), snappy (quick & controlled), bouncy (playful with overshoot)
- Every transition in the app will use one of these — no linear or ease-in-out

### **4. Spacing Tokens**
- Add `CelleuxSpacing` with six sizes: xs (4), sm (8), md (16), lg (24), xl (32), xxl (48)
- Generous whitespace for that luxury feel

### **5. Enhanced Glass Cards**
- Upgrade the existing `GlassCard` with a chrome angular-gradient border (silver → gold → silver rotating around the edge)
- Add an inner white highlight glow at the top for a lit-from-above effect
- Apply all three shadow tiers automatically
- Optional subtle shimmer overlay (max 6% opacity)
- Same upgrade for `CompactGlassCard`

### **6. Haptic Tokens**
- Add `CelleuxHaptic` with four named feedback styles: selection, impact, success, and soft tap
- Ready-made view modifiers for consistent haptic feel across the app

### **7. Animated Number Modifier**
- Add a `.animatedNumber` view modifier that applies a smooth numeric content transition with the luxury spring animation
- For use on every score, percentage, and metric display

### **8. Color Cleanup**
- **Remove** the purple `accent` and `accentLight` colors entirely
- **Replace** the purple `dataViolet` and `dataVioletGradient` with gold-toned equivalents
- **Update** two references in HomeView and SkinLongevityScoreView that use `dataViolet` to use the new gold data color
- Convert any remaining non-P3 colors (like `background`, `cardSurface`, `textPrimary`) to Display P3
- Verify every color uses `Color(.displayP3, ...)` — no sRGB

### **What stays the same**
- All existing components (LuxuryBezelRing, ChromeRingView, CelleuxMeshBackground, particles, button styles, etc.) remain intact and functional
- Only enhanced with the new tokens where applicable
