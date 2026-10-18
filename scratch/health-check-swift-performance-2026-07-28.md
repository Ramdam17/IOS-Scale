# Swift Performance Audit — IoS Scale

Scope: `IoS Scale/` (Core/Models, Core/Services, Features, App). SwiftUI view files excluded — deferred to swiftui-performance-analyzer.

Hotspot map: App has no actors, no `any` existentials, no unbounded data-loops — it's a manual-measurement UI app (9 near-identical modality ViewModels, one measurement saved per user tap). The one real Swift-level hazard is `MeasurementModel.secondaryValues`, an uncached computed property that JSON-decodes on every access, called 2-8x per measurement across export, detail-stats, and per-row visualization code.

## Summary
- CRITICAL: 1
- HIGH: 0
- MEDIUM: 2
- LOW: 3
- Total: 6

## Findings

### [CRITICAL] Uncached JSON decode in `secondaryValues`, amplified across loops/renders
**File:** `IoS Scale/Core/Models/Measurement.swift:99-102`
**Issue:** `MeasurementModel.secondaryValues` calls `JSONDecoder().decode(...)` from scratch on every access (no caching). Call sites read it 2-4x per measurement in a single call: `IoS Scale/Core/Services/ExportService.swift:106-111` (4 reads/row inside nested `for session in sessions { for measurement in ... }`) and `:206-207`; `IoS Scale/Features/History/SessionDetailView.swift:230-254,317,319` (up to 8 decodes/measurement, recomputed every view-body render); `IoS Scale/UI/Components/MeasurementVisualizations/MeasurementVisualizationView.swift:85,89,159,167` (selfScale/otherScale each read twice per render at lines 103/109); `IoS Scale/Features/History/MeasurementRowView.swift:65-87` (once per list row x N rows).
**Fix:** Cache the decode with `@Transient private var _secondaryValuesCache: [String: Double]??` set on first access (and invalidated when `secondaryValuesData` is written), or at minimum decode once into a local `let` at each call site before multiple subscript reads.

### [MEDIUM] UserDefaults read on every haptic call
**File:** `IoS Scale/Core/Services/HapticManager.swift:27-29` (`isHapticEnabled`)
**Issue:** Read via `UserDefaults.standard.object(forKey:)` inside every `guard` (lines 50,59,68,79,90,99,108,121,135), fired up to ~20x/drag from threshold-gated haptics in the interactive circle gestures.
**Fix:** Cache the flag, invalidate via `UserDefaults` change notification instead of reading per call.

### [MEDIUM] Missing reserveCapacity in nested export loop
**File:** `IoS Scale/Core/Services/ExportService.swift:75,94-125`
**Issue:** `lines`/`row` built via `.append` inside `for session in sessions { for measurement in ... }` with no capacity hint; grows unbounded for "export all sessions" over a long-running research study.
**Fix:** `lines.reserveCapacity(sessions.reduce(0) { $0 + ($1.measurements?.count ?? 0) } + 1)`.

### [LOW] Inconsistent `[weak self]` discipline in delayed dismissal closures
**Files:** `IoS Scale/Features/Measurement/Basic/BasicIOSViewModel.swift:136`, `Advanced/AdvancedIOSViewModel.swift:122`, `Overlap/OverlapViewModel.swift:137`, `SetMembership/SetMembershipViewModel.swift:172` use `Task { ...; showSaveConfirmation = false }` capturing `self` strongly, while the 5 sibling ViewModels (Projection, Proximity, Observation, Identification, Attribution) correctly use `DispatchQueue.main.asyncAfter { [weak self] in ... }`.
**Fix:** Standardize on `[weak self]`.
**Cross-domain:** same root cause flagged by memory-auditor and concurrency-auditor.

### [LOW] `async` function with no internal `await`, apparently unused
**File:** `IoS Scale/Core/Services/AuthenticationService.swift:305-308`
**Issue:** `unlockApp() async -> Bool { return true }` has no suspension point and no call sites found.
**Fix:** Remove or make synchronous.

### [LOW] Unnecessary `Task {}` around a synchronous no-op
**File:** `IoS Scale/App/IOSScaleApp.swift:52-55`
**Issue:** Wraps `AuthenticationService.shared.lockApp()` (a no-op stub) in `Task { @MainActor in ... }` on every background transition.
**Fix:** Call directly, no Task needed.

## Health
OVERHEAD (no critical issue in a genuinely hot loop, but the decode-caching bug compounds across export/render paths and should be fixed first).

Top priority: cache `MeasurementModel.secondaryValues` (Core/Models/Measurement.swift) — currently re-decodes JSON on every access, amplified across export, session-detail stats, and per-row visualizations.
