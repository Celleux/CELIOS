# Fix 6 Critical Bugs in Skin Scan Engine — Remove All Mock Data

## Summary
Fix all 6 critical bugs in the skin scan engine to ensure every displayed number comes from real pixel measurements — never random or hardcoded data.

---

### Bug Fix 1: Remove Random Mock Data Fallback
**What:** When no camera frame is captured, the app currently generates random scores. This will be replaced with a proper error state that tells the user the scan failed and to try again.

### Bug Fix 2: Remove First Hardcoded Fallback in Analysis
**What:** When pixel data can't be read from a face region, the service returns fake numbers. This will be changed to return nothing (nil), and the scan will show an error instead of fake results.

### Bug Fix 3: Remove Second Hardcoded Fallback in Analysis
**What:** Same issue as Bug 2 — a second place where fake numbers are returned when sampling fails. Same fix: return nothing and handle gracefully upstream.

### Bug Fix 4: Fix ITA Formula (Wrong Color Channel)
**What:** The skin brightness calculation uses the wrong color channel (a* instead of b*). The ITA (Individual Typology Angle) formula requires the b* channel from the L\*a\*b\* color space. This is a one-character fix but critical for accuracy. Also need to track b* mean value alongside existing data.

### Bug Fix 5: Replace Position-Based Heat Map with Real Scores
**What:** The AR heat map overlay currently uses hardcoded face zones (e.g. "if cheek area, show redness"). This will be replaced with actual per-region analysis scores from the scan, so the heat map reflects real measured data. Each vertex will be colored based on which face region it belongs to and that region's actual scores — with smooth interpolation between regions.

### Bug Fix 6: Independent Per-Region Scores
**What:** Left cheek and right cheek currently share the same scores. The analysis service already computes separate regions (forehead, left cheek, right cheek, chin), but the results mapping reuses the same global score for both cheeks. This will be fixed so each of the 6 display regions (forehead, left cheek, right cheek, chin, under-eyes, nose/T-zone) gets independently computed metrics.

---

### Changes by File

**SkinAnalysisService.swift**
- `computeRegionMetrics` returns optional (`RegionMetrics?`) instead of hardcoded fallback
- Fix ITA formula: `atan2(meanL - 50, meanB)` instead of `meanA`
- Track b\* mean value in RegionMetrics
- New method to analyze 6 named regions (forehead, left cheek, right cheek, chin, under-eyes, nose) independently
- Return a new `PerRegionAnalysis` structure with named region results
- `analyze()` returns optional `SkinAnalysisData?` — nil means analysis failed

**SkinScan.swift (Models)**
- `SkinAnalysisData` gains per-region score storage (dictionary of region name → metrics)
- Add `bStarMean` field to track the b\* channel value

**SkinScanRecord.swift (SwiftData)**
- Add per-region score fields so history preserves independent region data
- Add `bStarMean` field

**SkinScanViewModel.swift**
- Remove the entire `else` block with `Double.random(...)` — if no pixel buffer captured, set an error state and show "Scan failed — please try again in better lighting"
- Add `scanError: String?` property for displaying error states
- `buildResult` and `buildRegions` use real per-region scores from the analysis data instead of reusing global scores
- `buildMetrics` also pulls from per-region data

**ARFaceTrackingView.swift**
- `heatMapColorForVertex` accepts real region scores instead of using position-based placeholders
- Coordinator stores the latest per-region scores from the view model
- Vertex-to-region mapping uses actual vertex positions to determine which face region each vertex belongs to
- Colors derived from actual scores: gold = high score, warm red = low score, with smooth blending between regions
- Add retry logic for frame capture: try at 80%, 85%, 90%, 95% progress
