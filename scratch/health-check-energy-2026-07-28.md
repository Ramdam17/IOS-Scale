# Energy Audit — IoS Scale

Scope: `IoS Scale/` only (build/ excluded). No `Timer` polling loop, no `CLLocationManager`, no manual `URLSession` usage found anywhere — CloudKit sync is fully automatic via SwiftData (`cloudKitDatabase: .automatic`) and status refresh is triggered only by scene-phase change / user tap / `CKAccountChanged` notification, not a timer. `UIBackgroundModes: remote-notification` (IoS-Scale-Info.plist:5-8) is legitimate and required for SwiftData's automatic CloudKit sync — not a misuse.

The real findings are all in the animation layer: 9 "modality preview" mini-animations shown on the Home screen, plus 2 stray `Timer.scheduledTimer` calls, none of which have any stop/cleanup path (0 `onDisappear`, 0 `.tolerance`, 0 `invalidate()` calls exist in the entire codebase).

## Summary
- CRITICAL: 1
- HIGH: 2
- MEDIUM: 1
- Total: 4

## Findings

### [CRITICAL] Perpetual, un-invalidatable Timer loop
**File:** `IoS Scale/UI/Components/Previews/SetMembershipPreview.swift:60,67`
**Issue:** Two `Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true)` calls started in `.onAppear`, never stored in a variable, no `.tolerance`, and no `invalidate()` anywhere in the codebase — once the "Set Membership" card is expanded on the Home screen these two timers fire every 1.5s forever (surviving card collapse and backgrounding, since nothing can stop them), each triggering a `withAnimation` transaction.
**Fix:** Replace with `withAnimation(...).repeatForever(autoreverses: true)` staggered via a single `.onAppear`/`.onDisappear` pair (store no `Timer` at all), or if a `Timer` is truly needed, keep a reference, set `.tolerance = timeInterval * 0.1`, and `invalidate()` in `onDisappear`.
**Cross-domain:** same finding reported by memory-auditor and swiftui-performance-analyzer.

### [HIGH] Home-screen preview animations never stop, compounded by iPad default-expand
**Files:** `IoS Scale/UI/Components/Previews/BasicIOSPreview.swift:46-52`, `AdvancedIOSPreview.swift:49-75`, `OverlapPreview.swift:63-70`, `SetMembershipPreview.swift:58-73`, `ProximityPreview.swift:69-76`, `IdentificationPreview.swift:67-74`, `ProjectionPreview.swift:67-74`, `AttributionPreview.swift:60-67`, `ObservationPreview.swift:58-65`; entry point `IoS Scale/Features/Home/HomeView.swift:133-135,183` (`ModalityCardView.defaultExpanded = horizontalSizeClass == .regular`)
**Issue:** All 9 modality-card preview animations use `.repeatForever(autoreverses: true)` started in `onAppear` with no corresponding `onDisappear` cancellation anywhere in the app. On iPad, cards default to `isExpanded = true`, so all 9 infinite animation loops (plus the 2 timers above) run concurrently and continuously for as long as the Home screen exists in the navigation stack — not gated to actual visibility.
**Fix:** Add `.onDisappear { withAnimation(nil) { /* reset state */ } }` to each preview, or better, drive them from a single shared `TimelineView`/state machine owned by `ModalityCardView` that pauses when `isExpanded == false` or when the app enters background (`\.scenePhase`).

### [HIGH] Continuous GPU blur inside the always-looping previews
**Files:** `IoS Scale/UI/Components/Previews/OverlapPreview.swift:36` (`.blur(radius: 2)`), `IoS Scale/UI/Components/Previews/ObservationPreview.swift:37` (`.blur(radius: (1 - immersionLevel) * 2)`)
**Issue:** These blurs recompute every frame as part of the same never-stopping repeatForever loops above, adding sustained GPU compositing cost on top of the CPU animation cost, for as long as the card is expanded (indefinite on iPad).
**Fix:** Same fix as the HIGH finding above — gating the animation lifecycle also removes the recurring blur cost.

### [MEDIUM] Inconsistent Reduce Motion handling / systemic lack of animation lifecycle discipline
**Files:** `IoS Scale/Features/Onboarding/OnboardingView.swift:158-162` (WelcomePage, no reduceMotion check), `IoS Scale/UI/Components/ProjectionCirclesView.swift:238-244`, `ObservationCirclesView.swift:253-258`, `IdentificationCirclesView.swift:238-243`
**Issue:** These 4 sites also start repeatForever loops (gated by drag-derived thresholds, so lower risk in isolation) but, unlike the 9 files in the Previews folder, do not check `@Environment(\.accessibilityReduceMotion)`, and have no onDisappear cleanup if the user backgrounds or navigates away mid-threshold.
**Fix:** Add the same accessibilityReduceMotion guard used in the Previews folder, and add onDisappear to force `showEffect`/`participationValue`-driven animations to stop.

## Verification counts
- Timers: 2 created, 0 with tolerance, 0 invalidated
- `repeatForever` animation sites: 14 total (10 in Previews/, 4 in production Circles/Onboarding views), 0 with onDisappear cleanup, 10/14 reduceMotion-gated
- Location APIs: none found
- Manual networking (URLSession): none found
- Background modes: 1 registered (remote-notification), justified by SwiftData CloudKit auto-sync

## Recommendations
1. Immediate: fix the SetMembershipPreview Timer leak (CRITICAL).
2. Short-term: gate all 9 preview animations + the 2 blur sites on visibility/scenePhase.
3. Long-term: add Reduce Motion checks to the 4 production circle-view repeatForever sites and add onDisappear cleanup app-wide as a standard pattern.
