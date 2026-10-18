# SwiftUI Layout Audit — IoS Scale

Scope: `IoS Scale/` only (build/ excluded). No CRITICAL issues found: zero `UIScreen.main`/`UIDevice.current.orientation` usage, no `UIRequiresFullScreen`, no GeometryReader-in-unconstrained-stack, no conditional VStack/HStack identity loss (grep clean across all 65 source files).

## Layout Strategy Map
All 9 measurement screens (`Features/Measurement/*/*.swift`) share one pattern: root `GeometryReader` -> `isLandscape = width>height` + `isPad = horizontalSizeClass == .regular` -> percentage-based `circlesHeight`, passed via `.frame(height:)` to a child `*CirclesView`. This root-GeometryReader usage is safe (no siblings to collapse). 8 `*CirclesView` components (`UI/Components/*CirclesView.swift`) each have their own root GeometryReader (also safe, constrained by parent). Size class is used correctly for device-scale adaptation, never as an orientation proxy. Zero usage of `onGeometryChange`, `ViewThatFits`, `AnyLayout`, `containerRelativeFrame` anywhere — 100% of adaptive logic is hand-rolled GeometryReader math. `HistoryView`/`TrashView`/`SettingsView`/`ExportSheet` correctly use `List`/`Section` (lazy). `HomeView` uses `LazyVGrid`.

## Summary
- CRITICAL: 0
- HIGH: 2
- MEDIUM: 2
- LOW: 1
- Total: 5

## Findings

### [HIGH] Inconsistent circle-diameter clamping
**Files:** `UI/Components/ProximityCirclesView.swift:43-45`, `IdentificationCirclesView.swift:30-32`, `ProjectionCirclesView.swift:31-33`, `ObservationCirclesView.swift:30-32`, `AttributionCirclesView.swift:30-32`, `SetMembershipCirclesView.swift:41-51`
**Issue:** 6 of 8 `*CirclesView` components size circles from `horizontalSizeClass` alone with no clamp to actual container size. Contrast: `InteractiveCirclesView.swift:169-177` and `OverlapCirclesView.swift:91-99` correctly do `min(baseDiameter, min(size.width/2.5, size.height*0.6))`.
**Impact:** iPad Split View 33%/Slide Over and iOS 26 free-form resizable windows can produce containers narrower than the two-tier compact/regular assumption anticipates, causing circle clipping/overlap.
**Fix:** Apply the same `min(baseDiameter, maxDiameter)` clamp used in Interactive/OverlapCirclesView to the other 6 components.

### [HIGH] SetMembershipCirclesView overlap at narrow widths
**File:** `UI/Components/SetMembershipCirclesView.swift:41-69`
**Issue:** Fixed `setWidth`(200)/`circleSize`(70) combined with the `outsideLeftX`/`outsideRightX` floor clamps means at container widths around 270-300pt (plausible in iPad Split View/Slide Over or iOS 26 free-form windows), the "outside" circle visually intrudes into the set rectangle boundary — undermining the in/out set-membership visualization.
**Fix:** Derive `setWidth`/`circleSize` from `geometry.size` with a floor, not a fixed two-tier constant.

### [MEDIUM] Non-lazy ForEach over unbounded list
**File:** `Features/History/SessionDetailView.swift:398-410` (`measurementsSection`)
**Issue:** Plain `VStack` + `ForEach` over all session measurements, no cap. Research sessions with many repeated saves could exceed comfortable non-lazy size.
**Fix:** Switch to `LazyVStack` inside the existing `ScrollView`.

### [MEDIUM] Hardcoded, non-adaptive drag-range constant
**Files:** `UI/Components/IdentificationCirclesView.swift:283`, `ObservationCirclesView.swift:274`, `AttributionCirclesView.swift:249`
**Issue:** All use `let dragRange: CGFloat = 300` independent of container width, while sibling components (`InteractiveCirclesView.swift:228`, `OverlapCirclesView.swift:257`) correctly scale via `containerWidth * 0.4`. Causes drag-sensitivity to feel inconsistent across iPhone vs iPad vs Split View.
**Fix:** Replace the literal with `geometry.size.width * 0.4` as done in the other two components.

### [LOW] Zero adoption of iOS 16+/17+ layout APIs
**Issue:** No `onGeometryChange`, `ViewThatFits`, `AnyLayout`, `containerRelativeFrame` anywhere despite an iOS 26 minimum target — app-wide modernization gap. Current GeometryReader-only approach works but some non-position-critical computations (e.g., `circlesHeight` percentage split) could move to `onGeometryChange` to avoid GeometryReader's layout-phase side effects.

## Recommendations
1. Apply the `min(baseDiameter, maxDiameter)` clamp to the 6 unclamped CirclesView components.
2. Derive SetMembership's set/circle sizing from actual geometry with a floor.
3. Switch SessionDetailView's measurements list to LazyVStack; scale the 3 hardcoded drag-range constants by container width.
4. Consider modernizing GeometryReader usage to `onGeometryChange` where side-effect-free.
