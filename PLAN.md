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
