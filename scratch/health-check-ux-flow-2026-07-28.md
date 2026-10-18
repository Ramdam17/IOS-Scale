# UX Flow Audit — IoS Scale

## Summary
- CRITICAL: 3
- HIGH: 4
- MEDIUM: 4
- LOW: 3
- Total: 14

## Findings

### [CRITICAL] Onboarding hard-gates the app behind Sign in with Apple, no skip/guest path
**File:** `IoS Scale/Features/Onboarding/OnboardingView.swift:88-117,329-396`
**Issue:** The Skip button only exists on pages 0-3; the final `GetStartedPage` offers only Sign in with Apple. `hasCompletedOnboarding` is only set true inside `handleAppleSignIn` (`AuthenticationService.swift:328-351`). Users without an Apple ID, or who decline/cancel, can never reach the (fully offline-capable) app.
**Fix:** Add a "Continue without account" action that sets `state = .unauthenticated` (already handled) and `hasCompletedOnboarding = true`.

### [CRITICAL] "iCloud Sync" Settings toggle doesn't control actual sync
**Files:** `IoS Scale/App/IOSScaleApp.swift:22-26` sets `cloudKitDatabase: .automatic` unconditionally; `CloudSyncService`/`SettingsView.swift:182-195` only gate a status display, never the real sync.
**Issue:** Users who disable it for privacy still have data synced to CloudKit.
**Fix:** Actually gate the ModelConfiguration, or remove the toggle.
**Cross-domain:** same finding reported by icloud-auditor and swiftdata-auditor (both CRITICAL/HIGH).

### [CRITICAL] "Clear All Data" is a no-op stub behind a destructive confirmation
**File:** `IoS Scale/Features/Settings/SettingsView.swift:64-71,367-371`
**Issue:** Alert promises permanent, irreversible deletion; `clearAllData()` body is `// TODO`, does nothing but a haptic.
**Fix:** Wire `modelContext.delete()` for all sessions.
**Cross-domain:** same finding reported by swiftui-architecture-auditor and swiftdata-auditor (both CRITICAL/LOW).

### [HIGH] Exit-confirmation bypass via edge-swipe on all 9 measurement views
**Files:** all 9 `Features/Measurement/*/*.swift`
**Issue:** All 9 measurement views hide the back button + set `.interactiveDismissDisabled(true)`, which is a no-op on pushed (non-sheet) views — edge-swipe-to-pop still bypasses `ExitSessionSheet` confirmation entirely.
**Cross-domain:** same finding reported by swiftui-nav-auditor (CRITICAL there, given the orphaned-session/data-loss angle).

### [HIGH] Inconsistent "Save & Exit" logic causes data-integrity bug
**Issue:** `BasicIOSViewModel`, `AdvancedIOSViewModel`, `OverlapViewModel`, `SetMembershipViewModel` unconditionally append a duplicate measurement on exit; the other 5 modalities correctly guard with `if measurementCount == 0`. Data-integrity bug in a research measurement tool.
**Cross-domain:** same finding reported by swiftui-architecture-auditor (CRITICAL there).

### [HIGH] Onboarding's local Sign-in-with-Apple handler shows a false "Sign In Failed" alert on user cancellation
**File:** `IoS Scale/Features/Onboarding/OnboardingView.swift:383-395`
**Issue:** Unlike `AuthenticationService`'s own delegate which correctly suppresses this, Onboarding's local handler surfaces an error alert even when the user simply cancelled.
**Fix:** Check for `ASAuthorizationError.canceled` and suppress the alert in that case, matching `AuthenticationService`'s behavior.

### [HIGH] TrashView permanent per-item delete via swipe has no confirmation/undo
**File:** `IoS Scale/Features/History/TrashView.swift:110-116`
**Issue:** Inconsistent with the adjacent "Empty Trash" bulk action which does confirm.
**Fix:** Add a confirmation alert to the per-item swipe-delete action, matching the bulk "Empty Trash" flow.

### [MEDIUM] Two duplicated, diverging Sign-in-with-Apple implementations
**Files:** `IoS Scale/Features/Onboarding/OnboardingView.swift:530-571` vs `IoS Scale/Core/Services/AuthenticationService.swift:429-477`
**Fix:** Consolidate into one shared representable.
**Cross-domain:** same finding reported by swiftui-architecture-auditor.

### [MEDIUM] @AppStorage("iCloudSyncEnabled") has three conflicting default values
**Files:** `CloudSyncService.swift:89` (=true), `SettingsView.swift:17` (=false), `AppSettings.swift:29` (=false)
**Fix:** Unify to a single source of truth.
**Cross-domain:** same finding reported by icloud-auditor and swiftdata-auditor.

### [MEDIUM] Orphaned empty SessionModels accumulate in History if exit flow is bypassed
**Issue:** Compounds with the HIGH exit-bypass finding above.
**Cross-domain:** same finding reported by swiftui-nav-auditor and swiftdata-auditor.

### [MEDIUM] SessionDetailView alert says "permanently delete" but only soft-deletes
**File:** `IoS Scale/Features/History/SessionDetailView.swift:90-97`
**Issue:** Alert copy says "permanently delete" but `deleteSession()` only calls `moveToTrash()` (reversible soft-delete) — inaccurate destructive-action copy.
**Fix:** Correct the alert copy to reflect the actual (reversible, trash-based) behavior.

### [LOW] Core/Services/AppRouter.swift — entire coordinator (172 lines) is dead code
**Fix:** Delete or adopt.
**Cross-domain:** same finding reported by swiftui-architecture-auditor and swiftui-nav-auditor.

### [LOW] LockScreenView.swift / AuthenticationState.locked / lockApp() are dead/no-op
**Issue:** Biometric lock was removed but the screen and state remain unreachable.
**Cross-domain:** same finding reported by security-privacy-scanner and swiftui-nav-auditor.

### [LOW] Features/History/HistoryPlaceholderView.swift is a superseded, unreferenced leftover
**Fix:** Delete.
**Cross-domain:** same finding reported by swiftui-architecture-auditor, swiftui-nav-auditor, swiftdata-auditor.

## Recommendations
1. Immediate: add a guest/skip path past onboarding; make the iCloud Sync toggle real or remove it; implement Clear All Data for real.
2. Short-term: fix the exit-confirmation swipe-bypass; unify Save & Exit logic across all 9 ViewModels; fix the false "Sign In Failed" cancellation alert; add confirmation to TrashView's per-item delete.
3. Long-term: consolidate the duplicated Sign-in-with-Apple representables; unify the 3 conflicting iCloudSyncEnabled defaults; correct SessionDetailView's delete-alert copy; remove dead code (AppRouter, LockScreenView, HistoryPlaceholderView).
