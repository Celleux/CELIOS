# Rebuild Luxury Onboarding Flow with Premium Animations

## Overview
Complete rebuild of the 6-page onboarding experience with luxury "Cartier jewelry display" aesthetic, phased animations, and polished transitions throughout.

---

### **Screen 1 — Welcome**
- Full-screen mesh background with floating gold/silver particles
- "CELLEUX" displayed in ultra-light 48pt with 8pt letter-spacing, gold color
- Subtitle "Your Skin's Daily Intelligence" in light 32pt, silver color
- Animated gold line divider that draws itself on (trim animation)
- "Begin" button with premium 3D press effect and gold gradient border
- Phased entrance: text fades in → line draws → button scales up (sequential)
- QR scanner button ("I have AeonDerm") kept as secondary option
- Slow-rotating decorative chrome rings around central logo icon

### **Screen 2 — "Real Skin Analysis" (Value Prop 1)**
- Animated face mesh wireframe using the "faceid" icon with pulsing scan grid
- Scan line sweeps vertically across the card with gold glow
- Text: "10 metrics. Zero guesswork. Powered by ARKit + Computer Vision."
- Entrance animation: card scales from 0.8→1 with opacity fade using keyframes
- Gold dot indicators at bottom with sliding matched geometry effect

### **Screen 3 — "Your Body's Story" (Value Prop 2)**
- Animated health ring that fills to 82% with gold angular gradient
- Score counter animates up from 0 to 82 with numeric text transition
- HealthKit-style icons (heart, sleep, activity) arranged around the ring
- Text: "Sleep, HRV, stress, hydration — all connected to your skin."
- Pulsing gold glow effect on the ring

### **Screen 4 — "Intelligent Timing" (Value Prop 3)**
- Animated timeline with 3 dose cards (Morning/Midday/Night)
- Each card activates sequentially with gold checkmarks bouncing in
- Gold arc clock visualization with dose time indicators
- Text: "Your supplements, timed to your circadian rhythm."
- Cards use glass material with chrome gold borders

### **Screen 5 — Personalization**
- Name input with glass-material text field and gold chrome border
- Age range selector with pill buttons (existing flow preserved)
- Skin concerns: multi-select chips with gold highlight when selected
- Primary goals: single-select with gold accent
- All sections in glass card containers with staggered entrance
- Haptic feedback on every selection
- Continue button disabled until required fields filled

### **Screen 6 — Permissions (Consolidated)**
- Three permission cards in glass containers:
  - Camera → "Face Scan Engine" with faceid icon
  - HealthKit → "Body Intelligence" with heart icon  
  - Notifications → "Smart Reminders" with bell icon
- Each card has icon, title, description, and toggle
- Granted state: gold checkmark with bounce symbol effect
- Denied state: silver outline
- "Get Started" gold CTA button + "Skip for now" secondary link

### **Screen 7 — Completion**
- "You're Ready" heading with celebration particle burst (gold/champagne)
- Personalized message: "Your first scan will establish your personal baseline"
- Gold CTA: "Take Your First Scan" → navigates to scan tab
- Success haptic feedback on completion
- Confetti-style gold particles animate outward

---

### **Animations & Transitions**
- All page transitions use blur-replace effect between pages
- Gold progress line at top showing current step (1/6 through 6/6)
- Page dot indicators use matched geometry for smooth sliding gold dot
- Skip button in top-right corner, small silver text
- All spring animations use the luxury preset (0.7 response, 0.85 damping)
- Staggered content appearance on each page

### **Data & Persistence**
- Save skin type, concerns, goals, age range, gender to SwiftData UserProfile
- Mark onboarding complete in UserDefaults (existing pattern preserved)
- All existing ViewModel logic and permission handling kept intact
