# Storage Audit — IoS Scale

## Storage Map
- Locations in use: `tmp/` (NSTemporaryDirectory) — used exactly once, for export share-sheet handoff. SwiftData/CloudKit local store — framework-managed, lives in the app's Application Support container, not touched directly by app code. No direct `Documents/`, `Caches/`, or App Group usage found anywhere in `IoS Scale/`.
- What goes where: user-generated content (sessions/measurements/notes) -> SwiftData+CloudKit (`.automatic`) store. Small settings/scalars -> `UserDefaults`/`@AppStorage` (~20 keys). Export files (CSV/TSV/JSON) -> `tmp/`, handed to `UIActivityViewController`.
- Backup-exclusion discipline: N/A — no manually-managed backed-up files exist to exclude (only write site is `tmp/`, which is inherently outside backup).
- File-protection discipline: missing — zero explicit `FileProtectionType`/`isExcludedFromBackup` usage anywhere in the codebase (confirmed via grep, 0 matches).
- Secrets in Keychain: no — zero Keychain/`kSecClass`/`SecItem` usage found; Sign in with Apple identifiers are stored in `UserDefaults` instead.
- App Group / extensions: none present, none required (single-target app, no widgets/extensions).

## Summary
- CRITICAL: 0
- HIGH: 2
- MEDIUM: 2
- LOW: 1

## Storage Health Score
| Metric | Value |
|---|---|
| Locations in use | tmp/ (export only) + SwiftData/CloudKit-managed store |
| Backup-exclusion coverage | N/A (no Documents/App Support writes by app code) |
| File-protection coverage | 0 of 1 direct file writes set explicit protection (0%) |
| Sensitive data in Keychain | No — Sign in with Apple identifiers in UserDefaults, 0 Keychain usages |
| App Group usage | Not present, not required |
| tmp/ usage | Mixed — intended as scratch, never explicitly cleaned up after use |
| UserDefaults size discipline | Small scalars only |
| Overall | FRAGILE |

## Findings

### [HIGH] Silent/weak handling of SwiftData save failures risks measurement data loss
**Files:**
- `IoS Scale/Features/Measurement/Projection/ProjectionViewModel.swift:123,153`
- `IoS Scale/Features/Measurement/Observation/ObservationViewModel.swift:123,153`
- `IoS Scale/Features/Measurement/Identification/IdentificationViewModel.swift:123,153`
- `IoS Scale/Features/Measurement/Proximity/ProximityViewModel.swift:135,166`
- `IoS Scale/Features/Measurement/Attribution/AttributionViewModel.swift:123,153`
- (better but still weak) `IoS Scale/Features/Measurement/Basic/BasicIOSViewModel.swift:103-108,124-144`, `Advanced/AdvancedIOSViewModel.swift:116-134,155-159`, `Overlap/OverlapViewModel.swift:104-108,125-143`, `SetMembership/SetMembershipViewModel.swift:138-142,160-178`

**Issue:** 5 of 8 measurement ViewModels call `try? modelContext?.save()` and swallow the error entirely. In `ProjectionViewModel.saveMeasurement()`/`AttributionViewModel.saveMeasurement()` (and the 3 siblings), `measurementCount` is incremented and `HapticManager.shared.success()` fires unconditionally, before/regardless of whether `save()` succeeded — the UI reports success even if persistence failed (e.g., a full disk, or a CloudKit/SwiftData constraint error). The other 4 ViewModels use `do/catch` but only `print(...)` to console and fire a generic error haptic — no user-visible message, no retry, no persisted "pending save" flag.
**Impact:** On a low-storage device or any transient SwiftData/CloudKit save error, a participant's measurement can be silently dropped while the UI confirms it was saved — the session data is unrecoverable and the user has no indication anything went wrong. Direct production data-loss risk.
**Fix:** Replace `try?` with `do/catch`, gate the optimistic UI updates (`measurementCount`, success haptic) on save success, and surface a user-facing error with a fix hint on failure:
```swift
do {
    try modelContext?.save()
    measurementCount = (session.measurements ?? []).count
    HapticManager.shared.success()
} catch {
    logger.error("Measurement save failed: \(error)")
    self.saveErrorMessage = "Couldn't save this measurement. Check available storage and try again."
    HapticManager.shared.error()
}
```

### [HIGH] Sign in with Apple identity stored in UserDefaults instead of Keychain
**File:** `IoS Scale/Core/Services/AuthenticationService.swift:50-56` (declarations), used at lines 243, 256-258, 280-286, 291-295, 330-343, 374-388
**Issue:** `storedAppleUserID`, `storedAppleUserEmail`, `storedAppleUserName` are declared via `@AppStorage`, persisted as plaintext strings in the app's `UserDefaults` plist rather than Keychain. This identifier is used as the functional session credential (`provider.credentialState(forUserID: userID)` in `checkAppleSignInStatus()`, line 251) to decide whether the user is `.authenticated`.
**Impact:** (1) `UserDefaults` is wiped on app deletion, so every reinstall forces the user back through onboarding/Sign-In even though Apple still reports the credential as `.authorized` server-side — Keychain items can be configured to survive reinstall, which is why Apple recommends Keychain for this identifier. (2) The user's name/email (PII) sits in a plaintext UserDefaults plist with only default file protection instead of Keychain's per-item access control/encryption.
**Fix:** Move `appleUserID`/`appleUserEmail`/`appleUserName` into Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), keep only the non-sensitive `hasCompletedOnboarding` flag in `@AppStorage`.
**Cross-domain:** overlaps with security-privacy (Keychain vs. UserDefaults for credentials).

### [MEDIUM] Exported session data left in tmp/ with no cleanup after Share Sheet use
**File:** `IoS Scale/Features/Export/ExportSheet.swift:210-211` (write), `:248-256` (`ShareSheet`/`UIActivityViewController`)
**Issue:** Every export writes a new timestamped file to `FileManager.default.temporaryDirectory` and hands it to `UIActivityViewController`, but there is no `completionWithItemsHandler` and no cleanup on sheet dismiss. Nothing ever calls `FileManager.default.removeItem(at:)` on these files.
**Impact:** Repeated exports in one app session accumulate multiple orphaned files in `tmp/` until the OS purges it (timing unpredictable) — not a data-loss risk, but unnecessary disk usage on constrained devices.
**Fix:**
```swift
let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
activityVC.completionWithItemsHandler = { _, _, _, _ in
    try? FileManager.default.removeItem(at: url)
}
```

### [MEDIUM] No explicit file protection on exported data containing free-text notes
**File:** `IoS Scale/Features/Export/ExportSheet.swift:211`
**Issue:** `data.write(to: tempURL)` is called without `options: [.completeFileProtection]`; the export payload (via `ExportService.swift`) includes `session.notes` — free-text user input in a sociometric/psychological measurement app, which may record personal/relationship details.
**Impact:** Relies solely on default `NSFileProtectionCompleteUntilFirstUserAuthentication`; minor hardening gap for a short-lived file.
**Fix:** `try data.write(to: tempURL, options: [.completeFileProtection, .atomic])`.

### [LOW] Dead/duplicated settings-persistence path
**File:** `IoS Scale/Core/Models/AppSettings.swift:134-152` (`AppSettings.load()`/`.save()`, key `"app_settings"`)
**Issue:** This Codable-blob-in-UserDefaults path is never called anywhere in the codebase (confirmed via grep) — real settings are persisted through ~20 separate `@AppStorage` keys scattered across `SettingsView.swift` and each measurement ViewModel. Two parallel, inconsistent persistence mechanisms exist for overlapping keys (e.g., `exportFormat`, `decimalSeparator`).
**Impact:** No current data-loss/backup risk, but a future call to `AppSettings.load()`/`.save()` would silently diverge from the live `@AppStorage` values, causing confusing "settings reverted" bug reports.
**Fix:** Remove the unused `AppSettings.load()/save()` UserDefaults blob, or consolidate all settings behind a single `AppSettings` source of truth.

## Recommendations
1. Immediate: fix the 5 `try? modelContext?.save()` sites so success feedback is gated on actual persistence, and add user-visible error messaging (data-loss risk).
2. Short-term: migrate Sign in with Apple identifiers to Keychain; add `completionWithItemsHandler` cleanup to the export Share Sheet; set `.completeFileProtection` on the export write.
3. Long-term: remove the dead `AppSettings` UserDefaults blob to avoid future divergence; consider a lightweight "pending save" retry/backoff for SwiftData writes under low-storage conditions.
4. Test plan: force a `context.save()` failure (e.g., simulate full disk) in each of the 8 measurement flows and confirm the user is notified rather than seeing a false "saved" haptic; delete-and-reinstall the app to confirm Sign-In state after the Keychain migration; export several sessions in one app run and confirm `tmp/` doesn't accumulate files after the fix.
