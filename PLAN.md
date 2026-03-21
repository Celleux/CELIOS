# Upgrade Insight Tone & Data Validation Rules

## What's Changing

Two focused improvements to the Insights & AI Coach feature:

---

### **Feature 1: Encouraging, Personal Narrative Tone**

- **Rewrite all insight messages** to feel warm and encouraging (like Gentler Streak), never clinical or judgmental
- Every insight will **reference the user's specific data** — e.g. "Your skin responded well to last night's 8.2 hours of sleep" instead of generic "Sleep is good"
- Every insight will include a **concrete, actionable next step** — e.g. "Try adding 15 minutes to tonight's sleep" instead of "Consider adjusting your routine"
- Celebration messages will feel genuinely delightful — "You've been on a roll! Your texture just hit a new personal best"
- Negative trends framed as opportunities — "Your hydration dipped a bit — a glass of water now can help your skin bounce back"
- Weekly summaries read like a friendly coach recap, not a data report

### **Feature 2: Strict Data Validation Rules**

- **Less than 3 scans**: Only show the "Scan more to unlock insights" prompt — no trend alerts, no celebrations, no correlation discoveries generated
- **No HealthKit / no Apple Watch**: Skip all health-dependent insights (sleep, HRV, hydration, UV, activity). Show only scan-based insights (trends, celebrations, personal bests)
- **No supplement tracking data**: Skip adherence-related insights entirely
- **Mixed availability**: Show whatever insights have real backing data, never fill gaps with defaults or estimates
- Add a small **"Data Sources" indicator** at the bottom of the insight feed showing which sources are active (Scans ✓, HealthKit ✓, Supplements ✗) so the user understands why certain insights are missing
- If zero data sources are available, show a friendly empty state with clear next steps to get started
