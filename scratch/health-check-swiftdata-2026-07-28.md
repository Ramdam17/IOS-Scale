# SwiftData Audit — IoS Scale

## SwiftData Map
- @Model classes (2): `SessionModel`, `MeasurementModel` (`Core/Models/Session.swift`, `Core/Models/Measurement.swift`) — both correctly `final class`, both CloudKit-compliant (all attributes defaulted, both relationships optional with defaults, no unique constraints, inverse declared).
- ModelContainer: 1 production container in `IoS Scale/App/IOSScaleApp.swift:17-33`, `cloudKitDatabase: .automatic`, `isStoredInMemoryOnly: false`. ~20 preview/#Preview in-memory containers scattered across Feature views (excluded as false positives).
- Schema versioning: none. No VersionedSchema, no SchemaMigrationPlan, no willMigrate/didMigrate anywhere in the codebase.
- CloudKit: enabled unconditionally at container level; entitlements confirm `iCloud.com.remyramadour.iosscale` container + CloudKit service.
- Context usage: exclusively `@Environment(\.modelContext)` consumed by @MainActor ViewModels — no background ModelContext, no Task{} touching the context off-actor. No widget/extension target.
- External storage/indexing: none (@Attribute never used in the codebase).

## Summary
- CRITICAL: 1
- HIGH: 3
- MEDIUM: 3
- LOW: 3
- Total: 10

## Health Score

| Metric | Value |
|---|---|
| @Model count | 2 (SessionModel, MeasurementModel) |
| Schema registration coverage | N/A — no VersionedSchema exists at all |
| Migration plan coverage | 0 stages defined |
| Context isolation | Yes — all mutation paths are MainActor-bound |
| Mutation/save ratio | ~1:1 (saves present) but 5/9 ViewModels swallow save errors |
| CloudKit conformance | Yes — models meet all CloudKit requirements |
| Index discipline | N/A (no indexes at all) |
| Overall | DANGEROUS (one CRITICAL: no migration plan on an actively CloudKit-synced app) |

## Findings

### [CRITICAL] No VersionedSchema / SchemaMigrationPlan despite active CloudKit sync
**File:** `IoS Scale/App/IOSScaleApp.swift:17-33`
**Issue:** The container is built from a bare `Schema([SessionModel.self, MeasurementModel.self])` with no VersionedSchema/SchemaMigrationPlan. The models already underwent one non-trivial shape change (per git history: "make SwiftData models CloudKit compatible"). Any future schema change (rename, type change, relationship restructuring) with no migration plan will either fail SwiftData's automatic lightweight migration inference or, worse, desync CloudKit-synced devices silently. Container creation calls `fatalError` on failure (line 31), so a failed migration is a guaranteed crash-on-launch for every affected user, with CloudKit making rollback/recovery far harder.
**Fix:** Introduce VersionedSchema for the current model set now (even a single version), add a SchemaMigrationPlan with at least a lightweight stage, and test the upgrade path with production-shaped data before the next schema change ships.
**Cross-domain:** compounds with icloud-auditor (CloudKit schema constraints) and database-schema-auditor (migration safety).

### [HIGH] fatalError on ModelContainer creation with no recovery path
**File:** `IoS Scale/App/IOSScaleApp.swift:28-32`
**Issue:** If the container fails to open (corrupted store, migration failure, disk full, CloudKit misconfiguration), the app crashes unconditionally with no fallback store, no user-facing message, and no telemetry.
**Fix:** On catch, attempt a fallback (e.g., recreate store, or surface a recovery/reset UI) and log via telemetry rather than fatalError in production builds.

### [HIGH] "iCloud Sync" Settings toggle does not actually control SwiftData/CloudKit sync
**Files:** `IoS Scale/Features/Settings/SettingsView.swift:17,182-195`, `IoS Scale/Core/Services/CloudSyncService.swift:89,124,159,188`, `IoS Scale/App/IOSScaleApp.swift:22-26`
**Issue:** `ModelConfiguration(cloudKitDatabase: .automatic)` is fixed at container-creation time and always on. `CloudSyncService.toggleSync(_:)` only flips an @AppStorage flag and changes status display/polling — it never reconfigures or tears down the container's CloudKit database. Additionally, two independent `@AppStorage("iCloudSyncEnabled")` declarations exist with contradictory defaults — `CloudSyncService.swift:89` defaults to true, `SettingsView.swift:17` defaults to false.
**Fix:** Either remove the toggle or implement real gating: rebuild ModelContainer with `cloudKitDatabase: .none` when disabled, and unify the two @AppStorage declarations to a single default.
**Cross-domain:** same finding reported by icloud-auditor.

### [HIGH] Silent error swallowing + false-positive "Saved" feedback on save()
**Files:** `ProjectionViewModel.swift:123,153`, `ProximityViewModel.swift:135,166`, `ObservationViewModel.swift:123,153`, `IdentificationViewModel.swift:123,153`, `AttributionViewModel.swift:123,153`
**Issue:** 5 of the 9 modality ViewModels call `try? modelContext?.save()`, discarding any error, then unconditionally fire `showSaveConfirmation = true` and `HapticManager.shared.success()` right after. The other 4 (`BasicIOSViewModel.swift:102-108`, `AdvancedIOSViewModel.swift:115-135`, `OverlapViewModel.swift:103-109`, `SetMembershipViewModel.swift:137-144`) correctly do/catch and fire an error haptic.
**Fix:** Replace `try? modelContext?.save()` with `do { try modelContext?.save() } catch { ... surface error, error haptic ... }` uniformly across all 9 ViewModels.
**Cross-domain:** same finding reported by storage-auditor and icloud-auditor.

### [MEDIUM] N+1 relationship access in List-bound rows
**Files:** `IoS Scale/Features/History/SessionRowView.swift:16,57,114` (rendered per-row inside `HistoryView.swift:236` ForEach), `HistoryView.swift:64,73`, `IoS Scale/Features/Export/ExportSheet.swift:34`, `IoS Scale/Core/Services/ExportService.swift:94-95`
**Issue:** `session.measurements ?? []` is independently re-derived in 3 separate computed properties per row, each triggering its own relationship fault; `ExportService.exportToDelimited` nests `for measurement in session.measurements ?? []` inside `for session in sessions`.
**Fix:** Compute `let measurements = session.measurements ?? []` once per row/loop iteration and reuse it; consider precomputing aggregates at save-time.
**Cross-domain:** overlaps with swiftui-performance-analyzer.

### [MEDIUM] Eagerly-inserted empty sessions have no cleanup safety net on abnormal termination
**Files:** all 9 `*ViewModel.swift`, e.g. `Basic/BasicIOSViewModel.swift:148-154,156-163`; filtering gap at `IoS Scale/Features/History/HistoryView.swift:25-29`
**Issue:** Every measurement screen calls `context.insert(session)` the instant it opens, before any measurement exists. The empty session is only deleted if the user explicitly taps Exit -> "Discard" — there is no cleanup if the app is killed, evicted in the background, or crashes mid-session. HistoryView's @Query only filters `deletedAt == nil` (not measurement count).
**Fix:** Defer `context.insert(session)` until the first measurement is actually saved, or add a startup/maintenance pass that purges sessions with zero measurements older than some threshold.
**Cross-domain:** same finding reported by swiftui-nav-auditor (CRITICAL, via the swipe-back exit-bypass angle).

### [LOW] No indexing on properties used in every filter/sort, given growing session volume
**File:** `IoS Scale/Core/Models/Session.swift:77-87` (no @Attribute(.indexed) on createdAt/deletedAt/modalityRawValue)
**Fix:** Add @Attribute(.indexed) to deletedAt and createdAt if session counts grow into the thousands.

### [LOW] Dead/orphaned duplicate persistence surface
**File:** `IoS Scale/Features/History/HistoryPlaceholderView.swift`
**Issue:** Declares its own @Query duplicating HistoryView.swift, but is not referenced anywhere else.
**Fix:** Delete the file.

### [LOW] "Clear All Data" is an unimplemented stub
**File:** `IoS Scale/Features/Settings/SettingsView.swift:367-371`
**Issue:** `clearAllData()` only fires a haptic; never touches modelContext.
**Fix:** Wire to a real `context.delete` pass over all SessionModels + `try context.save()`, or remove the control until implemented.
**Cross-domain:** same finding reported by swiftui-architecture-auditor and ux-flow-auditor (both CRITICAL from their angle).

## Recommendations
1. Before next release: add VersionedSchema + SchemaMigrationPlan now (CRITICAL); replace fatalError container-creation with a recovery path; fix or remove the non-functional iCloud Sync toggle.
2. Short-term: unify save-error handling across all 9 measurement ViewModels.
3. Medium-term: cache relationship arrays once per row to remove N+1 access; defer session insertion until first measurement; delete HistoryPlaceholderView.swift.
4. Test plan: before shipping any future model change, test upgrade from the current CloudKit-compatible schema on a device with pre-existing local (and CloudKit-synced) data.
