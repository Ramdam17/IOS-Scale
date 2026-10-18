# Swift Concurrency Audit — IoS Scale

## Isolation Architecture Map
- Default strategy: per-type `@MainActor` isolation. 14/15 non-SwiftUI classes (`ThemeManager`, `AppRouter`, `CloudSyncService`, `AuthenticationService`, `ExportService`, and all 9 measurement ViewModels) are explicitly `@MainActor`. No `actor` types exist anywhere in the codebase — SwiftData `ModelContext` is only ever touched from `@MainActor` code (Views via `@Environment(\.modelContext)`, ViewModels via `configure(with:)`), so no cross-isolation `ModelContext` races were found.
- Entry points: unstructured `Task {}` (13 occurrences) and one `.task {}` — no `TaskGroup`/`async let`/`AsyncStream` usage anywhere (no batch-parallel work exists in the app).
- Cancellation: no stored `Task<...>?` properties exist; all Tasks are fire-and-forget with bounded (~1.5s) lifetimes, so no zombie-task risk.
- Escape hatches: zero `@unchecked Sendable`, `@preconcurrency`, or `nonisolated(unsafe)` in the codebase.
- Legacy bridge: `DispatchQueue.main.asyncAfter` is used in 5 ViewModels + `HomeView`, coexisting with `Task { try? await Task.sleep(...) }` used for the identical purpose in 4 sibling ViewModels — an inconsistent-but-not-unsafe mix.

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 2
- LOW: 1
- Total: 5

## Concurrency Health Score

| Metric | Value |
|--------|-------|
| Isolation coverage | ~93% (14/15 classes explicitly `@MainActor`; `HapticManager` is the gap) |
| Structured concurrency | N/A — no parallel batch work exists; all async entry points are single-purpose unstructured Tasks |
| Escape hatches | 0 `@unchecked Sendable`, 0 `@preconcurrency`, 0 `nonisolated(unsafe)` |
| Cancellation coverage | N/A — no stored Tasks found |
| GCD legacy | 6 production `DispatchQueue.main.asyncAfter` usages (all correctly `[weak self]`-safe) |
| Readiness | NOT READY (one CRITICAL: unbounded CPU work on MainActor in export path) |

## Findings

### [CRITICAL] Missing background offload for CPU-bound export work blocks UI
**Files:** `IoS Scale/Core/Services/ExportService.swift:73` (`exportToDelimited`) and `:132` (`exportToJSON`); call site `IoS Scale/Features/Export/ExportSheet.swift:195-226`
**Issue:** `ExportService` is `@MainActor` with no `@concurrent`/`nonisolated` offload. `ExportSheet.exportData()` wraps the call in `Task { }`, which inherits `@MainActor` isolation from the calling Button action (no explicit detachment). The loop over every session/measurement building CSV/TSV rows, the `JSONEncoder().encode(...)` call, and the synchronous `data.write(to: tempURL)` at line 211 all run with zero suspension points until the first `await MainActor.run` — so for large datasets this freezes the main thread/UI for the full export duration.
**Fix:**
```swift
// ExportService.swift
@MainActor
final class ExportService {
    nonisolated func exportSessions(_ sessions: [SessionModel], format: ExportFormat, includeMetadata: Bool) async -> Data? {
        // move to a Sendable snapshot struct first, then do the heavy string/JSON work off-actor
    }
}
```
Or simplest fix at the call site: `Task.detached(priority: .userInitiated) { ... }` after extracting a `Sendable` snapshot of the session data on MainActor, then hop back with `await MainActor.run` to update UI state.
**Cross-domain:** overlaps with SwiftUI performance (main-thread stall class).

### [HIGH] Non-Sendable delegate parameters captured across isolation boundary
**File:** `IoS Scale/Core/Services/AuthenticationService.swift:365-395` and `:397-426`
**Issue:** `nonisolated func authorizationController(controller:didCompleteWithAuthorization:)` and the `didCompleteWithError:` counterpart wrap their bodies in `Task { @MainActor in ... }`, referencing the non-Sendable `authorization`/`error` parameters inside the Task closure. Under `-strict-concurrency=complete` this produces "capture of non-Sendable type in a @Sendable closure" since `AuthenticationServices` types aren't Sendable-annotated.
**Fix:**
```swift
nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    let credential = authorization.credential as? ASAuthorizationAppleIDCredential
    Task { @MainActor in
        isAuthenticating = false
        if let credential { handleAppleSignIn(credential: credential) }
    }
}
```
Extract only Sendable primitives before entering the Task.

### [MEDIUM] Inconsistent unsafe Task self-capture in confirmation-hide timers
**Files:** `IoS Scale/Features/Measurement/Basic/BasicIOSViewModel.swift:136-139`, `IoS Scale/Features/Measurement/Advanced/AdvancedIOSViewModel.swift:122-125`, `IoS Scale/Features/Measurement/Overlap/OverlapViewModel.swift:137-140`, `IoS Scale/Features/Measurement/SetMembership/SetMembershipViewModel.swift:172-175`
**Issue:** `Task { try? await Task.sleep(...); showSaveConfirmation = false }` strongly captures `self` with no `[weak self]`, while 5 sibling ViewModels (Attribution:136, Identification:136, Observation:136, Proximity:148, Projection:136) correctly use `DispatchQueue.main.asyncAfter(...) { [weak self] in ... }` for the same feature. Impact is low (bounded 1.5s lifetime extension, Task isn't stored) but signals an incomplete fix applied to only half the ViewModel family.
**Fix:** `Task { [weak self] in try? await Task.sleep(for: .seconds(1.5)); self?.showSaveConfirmation = false }` in all four files.
**Note:** Same root cause as the memory-auditor's MEDIUM finding on these same 4 files — merge in the unified report.

### [MEDIUM] HapticManager wraps main-thread-only UIKit objects without isolation
**File:** `IoS Scale/Core/Services/HapticManager.swift:15`
**Issue:** `final class HapticManager` holds `UIImpactFeedbackGenerator`/`UISelectionFeedbackGenerator`/`UINotificationFeedbackGenerator` (UIKit, main-thread-confined) but is neither an `actor` nor `@MainActor`. All current call sites happen to run from `@MainActor` code, so there's no active bug — but nothing in the type enforces that, and it's the one isolation-coverage gap among the app's service singletons.
**Fix:** Add `@MainActor` to the class declaration.

### [LOW] Mixed GCD/async-await for identical UI-timing logic
**Files:** `IoS Scale/Features/Measurement/Attribution/AttributionViewModel.swift:136`, `Identification/IdentificationViewModel.swift:136`, `Observation/ObservationViewModel.swift:136`, `Proximity/ProximityViewModel.swift:148`, `Projection/ProjectionViewModel.swift:136`, `IoS Scale/Features/Home/HomeView.swift:81` vs. `Task`-based sleep in the 4 ViewModels above
**Issue:** Two different concurrency primitives (`DispatchQueue.main.asyncAfter` vs `Task { try? await Task.sleep }`) implement the same "hide save confirmation after ~1.5s" behavior across a templated family of 9 near-identical ViewModels. Not unsafe (both target MainActor state correctly), but an inconsistent concurrency style that should be unified.
**Fix:** Standardize on the async/await version repo-wide.

## Recommendations
1. Immediate: offload `ExportService`'s CSV/TSV/JSON generation off the MainActor (or explicitly detach the Task in `ExportSheet.exportData()`) before shipping to users with large session histories.
2. Short-term: fix the `AuthenticationService` delegate captures; add `@MainActor` to `HapticManager`; add `[weak self]` to the 4 outlier ViewModels.
3. Long-term: unify the GCD/Task.sleep split for the save-confirmation-hide pattern across all 9 measurement ViewModels.

Zero escape hatches (`@unchecked Sendable`/`@preconcurrency`/`nonisolated(unsafe)`), no `ModelContext` cross-isolation races found. Readiness: NOT READY pending the CRITICAL fix.
