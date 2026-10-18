# SwiftUI Architecture Audit — IoS Scale

## Architecture Boundary Map
- Pattern: View + ViewModel per measurement modality (9 near-identical `*View`/`*ViewModel` pairs), but inconsistent app-wide: History/Settings/Export features have no ViewModel at all; an `AppRouter` coordinator exists but is completely unused (dead code) — navigation is actually ad hoc via `NavigationLink`/`.sheet` in `HomeView`.
- View count: ~49 View structs (incl. private subviews) vs 9 ViewModels (all Measurement-feature only) — most of the app (History, Settings, Export, Onboarding, Auth flows) has zero ViewModel layer.
- Logic location: mixed. Measurement ViewModels hold session/state logic (good), but gesture-to-value scientific measurement math lives untested inside ~9 "CirclesView" SwiftUI View structs; History/Settings put filtering, sorting, and SwiftData mutation directly in Views.
- Dependency injection: singletons (`.shared`) for all services (CloudSyncService, AuthenticationService, HapticManager, ExportService), injected into environment at root (`AppRootView`) for the @Observable ones, but referenced directly via `.shared` elsewhere too (mixed strategies).
- State management: mixed generations — Services use modern `@Observable`/`@Environment`; all 9 Measurement ViewModels use legacy `ObservableObject`/`@Published`/`@StateObject`; `AppRouter`/`ThemeManager` also legacy.
- Testability: 0 test files exist in the repo — 100% of business logic, including a confirmed behavioral bug, is untested.

## Summary
- CRITICAL: 2
- HIGH: 8
- MEDIUM: 5
- LOW: 1
- Total: 16

## Architecture Health Score

| Metric | Value |
|---|---|
| View/model ratio | ~49 views, 9 ViewModels (~5.4:1); History/Settings/Export/Onboarding have 0 ViewModels |
| Logic separation | Scientific gesture-to-value math lives in ~9 View structs (CirclesView family); History/Settings filter+mutate SwiftData directly in Views |
| Async boundary | Task{} mostly simple delegation; one FileManager side effect lives in a View (ExportSheet) instead of a service |
| Property wrapper correctness | No unauthorized non-private @State var copies found (clean) |
| Testability | 0 test files; core measurement formulas and a real Save&Exit divergence bug are completely unverified |
| Architecture consistency | Mixed: legacy ObservableObject ViewModels + modern @Observable services + a dead, unused coordinator (AppRouter) |
| Overall | MONOLITHIC (CRITICAL issues present: untested diverging business logic + a no-op destructive UI action) |

## Findings

### [CRITICAL] Diverging "Save & Exit" logic causes silent data loss in 5 of 9 modalities
**Files:**
- `IoS Scale/Features/Measurement/Observation/ObservationViewModel.swift:147-165`
- `IoS Scale/Features/Measurement/Proximity/ProximityViewModel.swift:159-179`
- `IoS Scale/Features/Measurement/Identification/IdentificationViewModel.swift:147-165`
- `IoS Scale/Features/Measurement/Attribution/AttributionViewModel.swift:147-165`
- `IoS Scale/Features/Measurement/Projection/ProjectionViewModel.swift:147-165`
(contrast with the correct behavior in `Basic/BasicIOSViewModel.swift:73-111`, `Advanced/AdvancedIOSViewModel.swift:82-163`, `Overlap/OverlapViewModel.swift:73-112`, `SetMembership/SetMembershipViewModel.swift:106-146`)

**Issue:** 9 ViewModels were built by copy-paste from a common template. In 4 of them, `handleExitAction(.saveAndExit)` always saves the current slider position as a new measurement. In the other 5, the logic diverged to `if measurementCount == 0 { saveMeasurement() }` — meaning once the user has saved at least one measurement in the session, tapping "Save & Exit" silently discards the current, unsaved position instead of saving it. The `ExitSessionSheet` button is labeled "Save & Exit" identically for all 9 modalities, so users have no way to know the behavior differs.
**Impact:** Research-grade measurement data loss for 5 of the app's 9 modalities; the bug is invisible in casual testing (only triggers after >=1 prior save in the same session) and has zero unit test coverage to catch it.
**Fix:** Extract the shared session-persistence logic (create/save/discard/exit) into one `MeasurementSessionController`/generic base ViewModel used by all 9 modalities, and make `saveAndExit` always persist the current value (matching the Basic/Advanced/Overlap/SetMembership behavior). Add unit tests for `handleExitAction` per modality.
**Cross-domain:** same bug flagged independently by ux-flow-auditor.

### [CRITICAL] "Clear All Data" destructive action is a no-op
**File:** `IoS Scale/Features/Settings/SettingsView.swift:64-71` (alert promising permanent deletion), `:238-247` (destructive button), `:367-371` (`clearAllData()`)
**Issue:** `clearAllData()` only plays a haptic (`HapticManager.shared.warning()`) and contains `// TODO: Implement actual data clearing with SwiftData` — `SettingsView` never injected `@Environment(\.modelContext)`, so no deletion is possible. The confirmation alert text ("This will permanently delete all sessions... cannot be undone") is false.
**Impact:** Users who explicitly confirm a destructive action believe their data was wiped when it wasn't — a privacy/trust-breaking bug with no test coverage.
**Fix:** Inject `@Environment(\.modelContext) private var modelContext` into `SettingsView` (or route through a `DataManagementService`), and implement `clearAllData()` to delete all `SessionModel`/`MeasurementModel` instances via the context, then `try context.save()`.
**Cross-domain:** same bug flagged independently by ux-flow-auditor and swiftdata-auditor.

### [HIGH] Dead, unused navigation coordinator duplicates (and diverges from) real navigation logic
**Files:** `IoS Scale/Core/Services/AppRouter.swift:1-172` (entire file unused); actual navigation lives in `IoS Scale/Features/Home/HomeView.swift:230-252`
**Issue:** `AppRouter` defines a full `AppDestination`/`AppSheet` coordinator pattern with its own modality->view switch, but it's never instantiated or referenced anywhere except inside its own file. The app's real navigation is a second, independent modality->view switch in `HomeView.ModalityCardView.destinationView(for:)`.
**Impact:** Two competing, unsynchronized sources of truth for "which view does this modality push" — if one is updated and the other isn't, navigation silently breaks for new modalities.
**Fix:** Delete `AppRouter.swift` (and its placeholder views) or finish wiring it in as the single navigation source of truth.
**Cross-domain:** same finding reported by swiftui-nav-auditor.

### [HIGH] All 9 Measurement ViewModels duplicate ~200 lines of session-persistence boilerplate
**Files:** all 9 `IoS Scale/Features/Measurement/*/​*ViewModel.swift`
**Issue:** `createSession()`, `discardSessionIfEmpty()`, `applyResetBehavior()`, `saveCurrentPosition()`, `handleExitAction()` are copy-pasted near-verbatim across all 9 files with no shared base type.
**Impact:** Any bugfix (like the Save & Exit CRITICAL above) must be manually propagated to 9 files; already proven to silently diverge.
**Fix:** Introduce a generic `MeasurementSessionViewModel<Value>` base class (or a `SessionPersistenceController` composed into each ViewModel) owning session lifecycle, leaving only per-modality value/label logic in each concrete ViewModel.

### [HIGH] ViewModels import SwiftUI and call `withAnimation` directly, coupling business logic to the UI framework
**Files:** all 9, e.g. `Basic/BasicIOSViewModel.swift:184-188`, `Advanced/AdvancedIOSViewModel.swift:166-173`, `Overlap/OverlapViewModel.swift:184-189`, `SetMembership/SetMembershipViewModel.swift:223-229`, `Observation/ObservationViewModel.swift:187-192`, `Proximity/ProximityViewModel.swift:201-206`, `Identification/IdentificationViewModel.swift:187-192`, `Attribution/AttributionViewModel.swift:187-192`, `Projection/ProjectionViewModel.swift:187-192`
**Issue:** These are non-View types (`final class ...: ObservableObject`) with no body/view-building code, importing SwiftUI purely for `@AppStorage` and `withAnimation`. `resetToInitial()` wraps `@Published` mutation in `withAnimation(.spring(...))` inside the ObservableObject.
**Impact:** Makes the ViewModel's reset behavior untestable without SwiftUI, and gives the ViewModel (not the View) ownership of animation timing/curve.
**Fix:** Move `withAnimation` into the View's button action (`Button { withAnimation { viewModel.resetToInitial() } }`), and have `resetToInitial()` do a plain, synchronous value mutation with no SwiftUI dependency.
**Cross-domain:** overlaps with swiftui-performance (repeated withAnimation calls).

### [HIGH] History feature has no ViewModel; filtering/sorting/business logic and SwiftData mutation live directly in Views
**Files:** `IoS Scale/Features/History/HistoryView.swift:41-70` (`filteredSessions`), `:311-316` (`deleteSession` mutates SessionModel directly); `IoS Scale/Features/History/SessionDetailView.swift:23-39` (`sortedMeasurements`/`averageValue`/`minValue`/`maxValue` reimplemented, duplicating `Session.averageValue/minValue/maxValue` already defined in `Core/Models/Session.swift:50-63`), `:228-334`, `:373-377`, `:418-422`
**Issue:** Unlike every Measurement feature, History has zero ViewModel layer; a 4-branch sort switch and 2-stage filter chain are computed properties on the View struct, and stats math duplicates logic that already exists on the `Session` value type but is recomputed against `SessionModel` instead.
**Impact:** Filter/sort/stat logic can only be verified by rendering the view; the duplicated average/min/max calculations can drift from `Session`'s canonical implementation.
**Fix:** Introduce a `HistoryViewModel` (or `SessionListViewModel`) owning `filteredSessions`/`sortOption`/`searchText` and session mutation; route `SessionDetailView`'s stats through `session.toSession().averageValue` etc.

### [HIGH] Core measurement gesture math lives untested inside SwiftUI View structs
**Files:** `IoS Scale/UI/Components/InteractiveCirclesView.swift:169-320`, `ProximityCirclesView.swift:327-413`, `SetMembershipCirclesView.swift:54-104,420-476` — same pattern repeats in `OverlapCirclesView`, `ProjectionCirclesView`, `ObservationCirclesView`, `IdentificationCirclesView`, `AttributionCirclesView`
**Issue:** The drag-delta-to-value and value-to-position mapping formulas — the actual scientific measurement instrument this app implements — are private methods on GeometryProxy-coupled View structs, duplicated with modality-specific variants across ~7 files, with 0 unit tests.
**Impact:** A miscalculation in any one mapping formula directly corrupts research data and cannot be verified without instantiating SwiftUI views.
**Fix:** Extract each modality's position<->value mapping into a plain, SwiftUI-free calculator type, unit test it, and have the View call into it.

### [HIGH] Duplicated Set Membership "in-set" threshold rule (>0.5) implemented independently in 3 places, one with a divergent fallback
**Files:** `IoS Scale/Features/History/SessionDetailView.swift:229-255`; `IoS Scale/Features/History/MeasurementRowView.swift:85-111,133-146`; `IoS Scale/UI/Components/MeasurementVisualizations/MeasurementVisualizationView.swift:158-172`
**Issue:** All three recompute `selfInSet`/`otherInSet` from `secondaryValues["selfInSet"]/["otherInSet"] > 0.5`, but `MeasurementVisualizationView`'s `SetMembershipVisualization` additionally has a different fallback (`primaryValue >= 0.5` / `>= 1.0`) when secondary values are absent, which the other two do not replicate.
**Fix:** Add a single computed property (e.g., on `Measurement`/`MeasurementModel`) exposing `selfInSet`/`otherInSet` with one canonical fallback rule; have all 3 views call it.

### [HIGH] File I/O side effect performed in a View's Task instead of the export service
**File:** `IoS Scale/Features/Export/ExportSheet.swift:191-226`, specifically `:210-211`
**Issue:** `ExportSheet.exportData()` calls `ExportService` for data generation and filename, but then performs the FileManager temp-file write directly in the View's Task block.
**Fix:** Add `ExportService.writeTemporaryFile(data:filename:) throws -> URL`; have the View's Task call only that.

### [MEDIUM] `AppSettings.swift` model (with load()/save()) is dead code; real settings persistence is ad hoc @AppStorage string keys duplicated across 10+ files
**Files:** `IoS Scale/Core/Models/AppSettings.swift:134-152`; duplicated string keys e.g. `"reset_behavior"` in `SettingsView.swift:18` and independently in all 9 `*ViewModel.swift` files
**Fix:** Either wire `AppSettings.load()/save()` in as the actual persistence mechanism, or delete the unused struct and centralize `@AppStorage` keys in one enum of string constants.

### [MEDIUM] `HistoryPlaceholderView.swift` is entirely dead code
**File:** `IoS Scale/Features/History/HistoryPlaceholderView.swift:1-115`
**Fix:** Delete; `HistoryView.swift` is the wired-up implementation.

### [MEDIUM] Duplicate "Sign in with Apple" UIViewRepresentable wrapper
**Files:** `IoS Scale/Core/Services/AuthenticationService.swift:449-477`; `IoS Scale/Features/Onboarding/OnboardingView.swift:530-571`
**Fix:** Consolidate into one shared representable.

### [MEDIUM] Monolithic, non-decomposed View bodies (~200+ lines) in Measurement views
**Files:** `IoS Scale/Features/Measurement/Advanced/AdvancedIOSView.swift:18-241` (~223-line body); `Observation/ObservationView.swift:20-219` (~200-line body); same pattern in `BasicIOSView.swift`
**Fix:** Extract `questionHeader`, `bottomControls`, `sliderSection`, `actionButtonsRow` into private computed properties/subviews.

### [MEDIUM] Inconsistent SwiftData save-error handling across ViewModels
**Files:** `Observation/ObservationViewModel.swift:123,153` (try? save, silent) vs. `Basic/BasicIOSViewModel.swift:103,124` (do/catch + haptic error)
**Fix:** Standardize on the do/catch + haptic-error pattern across all 9 ViewModels.
**Cross-domain:** same finding reported by storage-auditor, icloud-auditor, swiftdata-auditor.

### [LOW] Duplicated DateFormatter/RelativeDateTimeFormatter construction across History views
**Files:** `SessionDetailView.swift:130-140`, `SessionRowView.swift:22-33`, `MeasurementRowView.swift:17-21`, `TrashView.swift:155-160`
**Fix:** Extract to a shared Date formatting extension/utility.

## Recommendations
1. Immediate: fix the Save & Exit divergence (unify all 9 ViewModels' `handleExitAction`) and wire `modelContext` into `SettingsView.clearAllData()` — both are live correctness/trust bugs.
2. Short-term: extract session-persistence boilerplate into one shared base/controller for the 9 Measurement ViewModels; remove withAnimation/SwiftUI coupling from ViewModels; delete dead code (AppRouter.swift, HistoryPlaceholderView.swift, unused AppSettings persistence).
3. Long-term: give History/Settings/Export a proper ViewModel layer; extract the CirclesView gesture-to-value math into plain, unit-testable calculator types; add a test target (currently zero tests exist for any business logic).
