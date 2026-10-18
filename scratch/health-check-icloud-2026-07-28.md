# iCloud/CloudKit Sync Audit — IoS Scale

Scope: `IoS Scale/` (App, Core/Models, Core/Services, Features, UI). Build/, tests, previews excluded.

## Summary
- CRITICAL: 2
- HIGH: 2
- MEDIUM: 3
- LOW: 3
- Total: 10

## Findings

### [CRITICAL] Two `@AppStorage("iCloudSyncEnabled")` declarations, same key, different defaults
**Files:** `IoS Scale/Core/Services/CloudSyncService.swift:89` (`= true`) vs `IoS Scale/Features/Settings/SettingsView.swift:17` (`= false`)
**Issue:** On a fresh install, before the key is ever written, each property wrapper falls back to its own default — so the Settings toggle can display OFF while `CloudSyncService` behaves as if sync is ON (or vice versa depending on read order). User-visible state contradicts actual behavior.
**Fix:** Define one shared source of truth (e.g., a `static let key` + single default, or bind the SettingsView Toggle directly to `CloudSyncService.shared.iCloudSyncEnabled`) instead of two independent `@AppStorage` declarations.

### [CRITICAL] The "iCloud Sync" toggle does not control real CloudKit sync
**File:** `IoS Scale/App/IOSScaleApp.swift:17-33` builds `sharedModelContainer` once at launch with `cloudKitDatabase: .automatic` unconditionally. `toggleSync()` (`CloudSyncService.swift:187-195`) and the Settings toggle (`SettingsView.swift:182-195`) only flip a UserDefaults flag and change status-label UI. Actual SwiftData->CloudKit sync keeps running regardless of the toggle's state.
**Impact:** User believes they disabled iCloud sync (privacy expectation) but data keeps pushing to CloudKit — a correctness/App Review risk.
**Fix:** Either remove the toggle (state plainly "synced automatically while signed into iCloud") or implement it for real: read the flag before container creation, branch `cloudKitDatabase: iCloudSyncEnabled ? .automatic : .none`, and require an app relaunch to rebuild the container (ModelContainer can't be swapped live under an active view hierarchy).

### [HIGH] No CKError-level handling anywhere; status is fabricated, not observed
**File:** `IoS Scale/Core/Services/CloudSyncService.swift:157-184` (`refreshStatus()`)
**Issue:** After any successful `accountStatus()` call, it unconditionally sets `status = .success` ("Synced") after a 2s delay — regardless of whether SwiftData's internal CloudKit engine actually pushed anything or hit `.quotaExceeded`, `.zoneNotFound`, `.partialFailure`, `.serverRecordChanged`, etc. No `catch let error as CKError` switch exists in the codebase.
**Fix:** Observe `NSPersistentCloudKitContainer.eventChangedNotification` (SwiftData's CloudKit-backed store still posts it) and map the underlying `CKError` into `SyncStatus.error(...)`; stop conflating "account available" with "data synced."

### [HIGH] Inconsistent, partly-silent local save error handling across measurement ViewModels
**Files:** `ProjectionViewModel.swift:123,153`, `ObservationViewModel.swift:123,153`, `IdentificationViewModel.swift:123,153`, `ProximityViewModel.swift:135,166`, `AttributionViewModel.swift:123,153` swallow save errors via `try? modelContext?.save()` and still show a "saved" confirmation regardless of failure. Contrast with the correct pattern (do/catch + haptic error feedback) in `BasicIOSViewModel.swift:102-108,124`, `OverlapViewModel.swift`, `SetMembershipViewModel.swift`, `AdvancedIOSViewModel.swift`.
**Fix:** Make all 9 use `do { try modelContext?.save() } catch { HapticManager.shared.error(); /* surface error, skip "saved" UI */ }`.
**Cross-domain:** Same root cause as the storage-auditor's HIGH finding on these same ViewModels.

### [MEDIUM] Silent secondary-value data loss on decode mismatch
**File:** `IoS Scale/Core/Models/Measurement.swift:93-94` (encode) / `:99-102` (decode)
**Issue:** `try? JSONEncoder/Decoder` on `secondaryValuesData`. If a future app version's secondary-value schema changes and CloudKit syncs a differently-shaped blob between devices, `secondaryValues` silently returns nil with zero diagnostics.
**Fix:** Log decode failures (os_log) and consider versioning the payload.
**Cross-domain:** Same finding reported by codable-auditor.

### [MEDIUM] Dead, third representation of the sync flag
**File:** `IoS Scale/Core/Models/AppSettings.swift:29` (`var iCloudSyncEnabled: Bool = false`)
**Issue:** Unused anywhere except its own struct — a third source of truth that compounds the CRITICAL finding above if someone wires it up later.
**Fix:** Remove it, or make it the single source of truth consumed by both CloudSyncService and SettingsView.

### [MEDIUM] `.CKAccountChanged` only re-checks status, never resets state
**File:** `IoS Scale/Core/Services/CloudSyncService.swift:206-218`
**Issue:** Switching the signed-in iCloud account mid-session only re-runs `checkiCloudStatus()`; nothing warns the user or rebuilds the container, per Apple's guidance for CloudKit-mirrored stores.
**Fix:** On account change, prompt for app restart rather than silently continuing with a container built against the old account context.

### [LOW] No VersionedSchema/SchemaMigrationPlan defined yet
**Issue:** Not a bug today (single schema) — flag as a guardrail: future `SessionModel`/`MeasurementModel` changes must stay additive-only since CloudKit mirroring doesn't support heavyweight migrations.

### [LOW] `aps-environment` hardcoded to `development`
**File:** `IoS Scale/IoS Scale.entitlements:6,11`; `CODE_SIGN_STYLE = Automatic` (`project.pbxproj:250,296`)
**Issue:** Should rewrite to `production` at Archive time — verify the actual shipped entitlements before submission, since CloudKit background push (`remote-notification` background mode present, confirmed in root `IoS-Scale-Info.plist:5-8`) depends on it.

### [LOW] "Clear All Data" is an unimplemented TODO
**File:** `IoS Scale/Features/Settings/SettingsView.swift:367-371`
**Issue:** Haptic-only, no actual delete. When implemented it must go through `modelContext.delete` (not raw file wipe) so CloudKit tombstone propagation works.

## Verified Safe (no issue)
- Container identifier `iCloud.com.remyramadour.iosscale` is consistent between `IoS Scale.entitlements:15` and `CloudSyncService.swift:95`.
- `SessionModel`/`MeasurementModel` are correctly CloudKit-compatible: no `@Attribute(.unique)` anywhere in the repo; all non-optional attributes have defaults; both `@Relationship`s are optional with defaults — matches the "make SwiftData models CloudKit compatible" fix from git history.
- No raw iCloud Drive / `NSMetadataQuery` / `NSFileCoordinator` usage — uncoordinated ubiquitous I/O not applicable.

## Recommendations
1. Immediate: fix the two conflicting `@AppStorage` defaults for the sync toggle, and make the toggle actually gate CloudKit sync (or remove it) — both CRITICAL.
2. Short-term: add real CKError handling via `NSPersistentCloudKitContainer.eventChangedNotification`; standardize all 9 ViewModels on do/catch for `modelContext.save()`.
3. Long-term: remove the dead `AppSettings.iCloudSyncEnabled`; add account-change restart prompt; verify `aps-environment` flips to production at Archive time; implement "Clear All Data" via `modelContext.delete`.
