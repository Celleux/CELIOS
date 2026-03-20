# Fix pixel buffer capture retry logic

## What's Already Done
- All 6 face regions (Forehead, Left Cheek, Right Cheek, Chin, Under-Eyes, Nose) are fully implemented with independent metrics per region
- Region detection uses Vision face landmarks
- No random/mock data anywhere — proper error states exist

## What Needs Fixing

### Pixel Buffer Capture Retry Logic
The retry thresholds `[0.8, 0.85, 0.9, 0.95]` are defined but the retry mechanism is broken:

- **Current bug**: When a frame is captured at 80%, `hasCapturedFrame` is set to `true` immediately. If the analysis later fails (nil result), there's no way to retry at 85%, 90%, or 95% because the flag is already set.
- **Fix**: Restructure the capture flow so the scan view model can signal back to the AR view that the captured buffer was invalid, allowing it to try the next threshold. If all 4 retries fail, show the error "Unable to capture — try better lighting".

### Specific Changes
1. [x] **AR Face Tracking View** — Captures at ALL thresholds (80%, 85%, 90%, 95%), incrementing `captureRetryCount` at each
2. [x] **AR Face Tracking View** — `onAllCapturesFailed` callback fires when all thresholds exhausted
3. [x] **Scan View Model** — Stores all captured buffers, tries analysis on each (latest first)
4. [x] **Scan View Model** — Only shows error after trying all captured buffers

### No Other Changes
- The 6-region system is complete and working
- All 10 metrics are implemented per region
- Heat map already uses real region scores with smooth blending between regions

## Lighting Normalization (Completed)

### Changes Made
1. [x] **LightingConditions struct** — Added to SkinScan.swift with ambientIntensity, colorTemperature, correctionApplied, quality level computation
2. [x] **ARFaceTrackingView** — Reads ARLightEstimate.ambientIntensity and ambientColorTemperature every 0.5s, fires onLightingUpdated callback
3. [x] **SkinScanViewModel** — Updates lightingQuality from real AR data; warns "Find better lighting" when intensity < 500 or > 2000 lumens
4. [x] **Bradford chromatic adaptation** — Full implementation in SkinAnalysisService: color temp → XYZ white point → Bradford M matrix → adaptation matrix → RGB correction before L*a*b* conversion. Only applied when color temperature deviates > 1000K from D65 (6500K)
5. [x] **SkinScanRecord** — Stores lightingAmbientIntensity, lightingColorTemperature, lightingCorrectionApplied per scan for comparison validity
6. [x] **SkinAnalysisData** — Stores lightingConditions on analysis result
