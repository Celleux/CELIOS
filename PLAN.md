# Fix unicode escape syntax in HealthCorrelationView.swift

**What's wrong:** Unicode characters (em-dash, arrows, middle dot) use JavaScript-style `\uXXXX` instead of Swift's `\u{XXXX}` syntax.

**Fix:** Replace all 9 occurrences:
- `\u2194` → `\u{2194}` (↔ arrow)
- `\u2014` → `\u{2014}` (— em-dash) — 7 occurrences
- `\u00B7` → `\u{00B7}` (· middle dot)

No other changes needed.