# Memory Leak Audit — IoS Scale

**Scope:** `IoS Scale/` source only (App/, Core/, Features/, UI/), excluding `build/`, tests, and preview-provider boilerplate.

## Resource Ownership Map

- 5 app-lifetime singletons (`AppRouter`, `CloudSyncService`, `ExportService`, `AuthenticationService`, `HapticManager`) — all `static let shared`, no `deinit` needed/present; correct by design.
- `CloudSyncService` (singleton) registers one `NotificationCenter` observer (`.CKAccountChanged`) in `init`; never removed, but exempt since the singleton never deallocates.
- `AuthenticationService` conforms to `ASAuthorizationControllerDelegate`; delegate is set on locally-scoped `ASAuthorizationController` instances (self-retained by the system for the duration of the request) — no stored delegate cycle.
- 9 measurement ViewModels (Basic, Advanced, Overlap, SetMembership, Proximity, Identification, Projection, Attribution, Observation) each own a `ModelContext` reference + transient `SessionModel`; cleanup is explicit (`discardSessionIfEmpty()` / `context.delete`) on exit-without-saving rather than via `deinit` — consistent pattern except for one sub-pattern (see MEDIUM finding).
- `SetMembershipPreview` (a SwiftUI view used inside `HomeView`'s expandable `ModalityCardView`) creates two repeating `Timer.scheduledTimer` instances in `onAppear` with no `onDisappear`/`invalidate` counterpart. It is the only modality preview using raw `Timer` — the other 8 previews (`ProximityPreview`, `ObservationPreview`, etc.) all animate via SwiftUI-native `withAnimation(...repeatForever...)`, cleanly tied to view lifecycle.
- No PhotoKit/PHImageManager usage anywhere in the app.
- No stored Combine `.sink`/`.assign` subscriptions anywhere; `import Combine` appears only for `ObservableObject` conformance.
- No unbounded in-memory collections; SwiftData `measurements` arrays are user-driven, and the Trash feature (soft-delete) has an explicit "Empty Trash" user action.

## Summary
- CRITICAL: 1
- HIGH: 0
- MEDIUM: 1 (bundled across 4 files — same root cause)
- LOW: 0

## Memory Health Score

| Metric | Value |
|--------|-------|
| Resource ownership coverage | 14 classes own resources (5 singletons + 9 ViewModels); 14/14 have an explicit cleanup path — but 1 struct-based view lacks any cleanup for the resource it creates |
| Timer lifecycle | 2 repeating timers, 0 invalidate calls |
| Observer lifecycle | 1 observer (singleton, exempt), 0 removals (by design, not a bug) |
| Task lifecycle | ~19 `Task {}` sites; 4 in class-based ViewModels lack `[weak self]` (bounded ~1.5s duration), 5 equivalent sites correctly use `[weak self]` |
| Combine subscriptions | 0 found — N/A |
| Unbounded collections | 0 potential accumulation points |
| Overall | LEAKING (one CRITICAL unmatched timer pair) |

## Findings

### [CRITICAL] Timer leak: repeating `Timer.scheduledTimer` never invalidated, in a repeatedly-shown interactive view
**File:** `IoS Scale/UI/Components/Previews/SetMembershipPreview.swift:60` and `:67`
**Issue:** `startAnimation()` (called from `.onAppear`) creates two `Timer.scheduledTimer(withTimeInterval:repeats: true)` instances that toggle `@State` properties forever. There is no `onDisappear`, no stored `Timer` reference, and no `.invalidate()` anywhere in the file. This view is rendered by `ModalityPreviewView` inside `HomeView`'s `ModalityCardView` (`IoS Scale/Features/Home/HomeView.swift:183`), which the user can repeatedly expand/collapse via `.onTapGesture { isExpanded.toggle() }` (`HomeView.swift:215-220`). Every expand re-runs `onAppear`, spawning 2 more orphaned timers that are never stopped, even after the card collapses.
**Impact:** Each expand/collapse cycle of the Set Membership card leaks 2 running timers permanently. Repeated toggling — a completely normal user interaction — causes an unbounded, ever-growing number of live timers firing every ~1.5s against stale state closures, driving continuous CPU/battery drain and measurable memory growth. Real risk during App Store review testing (reviewers commonly poke UI repeatedly) and for post-launch battery complaints.
**Fix:** Store the timers and invalidate them in `onDisappear`, or (preferred, consistent with the other 8 preview files) replace with SwiftUI-native `withAnimation(.easeInOut(duration:).repeatForever(autoreverses: true))`, tying animation lifecycle to the view automatically:
```swift
@State private var selfInSetTimer: Timer?
@State private var otherInSetTimer: Timer?

private func startAnimation() {
    selfInSetTimer = Timer.scheduledTimer(withTimeInterval: PreviewConstants.cycleDuration / 2, repeats: true) { _ in
        withAnimation(.easeInOut(duration: 0.5)) { selfInSet.toggle() }
    }
    // schedule otherInSetTimer similarly
}

private func stopAnimation() {
    selfInSetTimer?.invalidate()
    otherInSetTimer?.invalidate()
}
// .onAppear { startAnimation() } .onDisappear { stopAnimation() }
```
**Cross-domain:** None (SwiftUI-only, no concurrency/actor implications).

### [MEDIUM] Closure capture: inconsistent `[weak self]` usage in save-confirmation delay across measurement ViewModels
**Files:**
- `IoS Scale/Features/Measurement/Basic/BasicIOSViewModel.swift:136`
- `IoS Scale/Features/Measurement/Overlap/OverlapViewModel.swift:137`
- `IoS Scale/Features/Measurement/SetMembership/SetMembershipViewModel.swift:172`
- `IoS Scale/Features/Measurement/Advanced/AdvancedIOSViewModel.swift:122`

**Issue:** These 4 `final class ... ObservableObject` ViewModels use `Task { try? await Task.sleep(...); showSaveConfirmation = false }` with a strong, implicit `self` capture. The 5 sibling ViewModels (`ProjectionViewModel.swift:136`, `IdentificationViewModel.swift:136`, `ProximityViewModel.swift:148`, `AttributionViewModel.swift:136`, `ObservationViewModel.swift:136`) implement the same "hide confirmation after delay" feature using `DispatchQueue.main.asyncAfter(deadline:) { [weak self] in self?.showSaveConfirmation = false }`, correctly avoiding the strong capture.
**Impact:** Bounded (~1-1.5s) — not an unbounded leak, since the `Task` self-resolves once the sleep completes. But it keeps the ViewModel alive slightly past the point the user could otherwise dismiss it (e.g., rapid save-then-exit), and is an inconsistent lifecycle strategy across 9 structurally-identical classes — the kind of ad-hoc pattern likely to regress into a real leak the next time this code is copy-pasted for a 10th modality.
**Fix:** Standardize all 9 ViewModels on the `[weak self]` pattern already used by the other 5:
```swift
Task { [weak self] in
    try? await Task.sleep(for: .seconds(1.5))
    self?.showSaveConfirmation = false
}
```
**Cross-domain:** Overlaps with concurrency (Task capture semantics) — worth confirming no Sendable/actor-isolation issue from adding `[weak self]` to `@MainActor`-isolated classes (there shouldn't be any).

## Recommendations
1. Immediate (CRITICAL): fix `SetMembershipPreview.swift` — store the two `Timer` references and invalidate in `onDisappear`, or convert to `withAnimation(...repeatForever...)` to match the other 8 preview files. Verify with Instruments Allocations while repeatedly tapping the Set Membership card on `HomeView` before submission.
2. Short-term (MEDIUM): standardize the 4 outlier ViewModels (Basic, Overlap, SetMembership, Advanced) on the `[weak self]` pattern already used by the other 5, for consistency and to close the gap before a 10th modality is added.
3. Long-term: since all 9 measurement ViewModels are near-identical boilerplate (session creation, save/exit, reset behavior, confirmation-hide delay), consider extracting a shared base/protocol to guarantee the fix in #2 can't regress per-modality again.
4. Instruments verification: run the Allocations instrument on `HomeView`, expand/collapse the "Set Membership" card 10+ times, and confirm `Timer` object count returns to 0 after the fix.
