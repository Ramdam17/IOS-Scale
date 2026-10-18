# Security & Privacy Audit — IoS Scale

## Security & Privacy Map
- Privacy Manifest: present at `IoS Scale/PrivacyInfo.xcprivacy`. Declares `NSPrivacyAccessedAPICategoryUserDefaults` (reason `CA92.1`) — correctly matches actual usage (self-app-only UserDefaults, no App Group, no third-party SDK). `NSPrivacyTracking = false`, no tracking domains — consistent with no ATT usage in code.
- Credential/identity storage: no Keychain usage anywhere in the codebase (`import Security` absent). Sign in with Apple identifiers (user ID, email, name) persisted via `@AppStorage`/UserDefaults.
- Network surface: no custom `URLSession`/HTTP code at all. Only Apple-managed transports are used (SwiftData CloudKit `.automatic`, `ASAuthorizationController`). No ATS exceptions in build settings.
- Logging: `print()` used exclusively (12 call sites); zero `Logger`/`os_log`/`NSLog` usage. No literal secrets logged, but no privacy-level discipline either.
- ATT: not used; no `NSUserTrackingUsageDescription` needed — consistent.
- Export compliance: no CryptoKit/CommonCrypto in use; `ITSAppUsesNonExemptEncryption` not declared anywhere (build settings or Info.plist).
- Entitlements: `applesignin` and iCloud/CloudKit entitlements are both used in code. `aps-environment` + `UIBackgroundModes: remote-notification` are declared but have zero corresponding APNs implementation (no `registerForRemoteNotifications`, `UNUserNotificationCenter`, `CKSubscription`).
- Third-party SDKs: none (`project.pbxproj` has no `XCRemoteSwiftPackageReference`), so no bundled-SDK manifest risk.

## Summary
- CRITICAL: 0
- HIGH: 2
- MEDIUM: 2
- LOW: 4
- Total: 8

## App Store Readiness
READY (with recommended hardening — no automatic-rejection triggers found: manifest covers the one Required Reason API in use, no ATT gap, no hardcoded secrets, no HTTP/ATS violations).

## Security Posture

| Metric | Value |
|---|---|
| Hardcoded credentials | 0 |
| Privacy Manifest status | PARTIAL (Required Reason APIs 1/1 declared; collected-data-types list incomplete vs. actual PII collected) |
| Token storage | UserDefaults/@AppStorage (no Keychain anywhere) |
| Network transport | HTTPS-only (no custom networking) |
| Logging hygiene | MIXED (print()-only, no privacy levels, no direct secrets found) |
| ATT compliance | N/A |
| Export compliance | Missing declaration (no crypto in use) |
| Entitlement scope | Excessive (1 unused: push notifications) |
| Overall | GAPS |

## Findings

### [HIGH] Sign in with Apple identity data stored in plaintext UserDefaults, not Keychain
**File:** `IoS Scale/Core/Services/AuthenticationService.swift:52,54,56`
**Issue:** `storedAppleUserID`, `storedAppleUserEmail`, `storedAppleUserName` are `@AppStorage` (UserDefaults-backed) properties. This is the same identifier used every launch to call `credentialState(forUserID:)` (line 251) — it's identity data, unencrypted, included in unencrypted device backups, and readable by any code with sandbox access on a jailbroken device.
**Fix:** Store these three values in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; add a one-time migration in `loadStoredCredentials()` that reads any legacy UserDefaults values, writes them to Keychain, then deletes the UserDefaults keys.
**Cross-domain:** Same root cause as the storage-auditor's HIGH finding on this file.

### [HIGH] LocalAuthentication (Face ID) used with no NSFaceIDUsageDescription — dead-code crash landmine
**Files:** `IoS Scale/Core/Services/AuthenticationService.swift:61,74,130,170`; `IoS Scale/Features/Settings/LockScreenView.swift:105,164`
**Issue:** `evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics...)` is called, but no `NSFaceIDUsageDescription` exists anywhere (checked build settings and Info.plist — absent). Verified via grep that `state = .locked` is never set anywhere in the app (`AuthenticationService.lockApp()` at line 301-303 is a no-op stub: "Lock feature removed - do nothing"), so `LockScreenView`/`evaluatePolicy` is currently unreachable — not an active crash today, but a guaranteed crash the instant this code path is reactivated (e.g., a future "Require Face ID" toggle) on any Face-ID device.
**Fix:** Either delete the dead LocalAuthentication code entirely, or (safer) add `NSFaceIDUsageDescription` now regardless of reachability, since the framework is already linked.

### [MEDIUM] Privacy Manifest collected-data-types list omits name/email actually collected via Sign in with Apple
**Files:** `IoS Scale/PrivacyInfo.xcprivacy:9-23`; collection site `IoS Scale/Core/Services/AuthenticationService.swift:334-345`
**Issue:** Manifest only declares `NSPrivacyCollectedDataTypeUserID`. The app also collects and persists full name and email address from `ASAuthorizationAppleIDCredential`.
**Fix:** Add `NSPrivacyCollectedDataTypeName` and `NSPrivacyCollectedDataTypeEmailAddress` entries (linked=true, tracking=false, purpose=AppFunctionality), and cross-check the App Store Connect App Privacy questionnaire (separate from the manifest) reflects the same.

### [MEDIUM] Unused Push Notification capability (over-broad entitlement)
**Files:** `IoS Scale/IoS Scale.entitlements:5-6,11-12`; `IoS-Scale-Info.plist:5-8`
**Issue:** `aps-environment`/`com.apple.developer.aps-environment` entitlements and `UIBackgroundModes: remote-notification` are declared, but no `registerForRemoteNotifications`, `UNUserNotificationCenter`, or `CKSubscription` code exists anywhere in the app.
**Fix:** Remove the push entitlement and background mode unless push is actually planned soon; unused capabilities add signing/provisioning friction and reviewer scrutiny for no benefit.
**Cross-domain:** overlaps build/code-signing (provisioning profile scope).

### [LOW] ITSAppUsesNonExemptEncryption not declared
**File:** no key present in `IoS Scale.xcodeproj/project.pbxproj` build settings or `IoS-Scale-Info.plist`
**Issue:** App uses only exempt encryption (HTTPS via CloudKit/Sign in with Apple; no CryptoKit/CommonCrypto found anywhere), but this isn't explicitly declared.
**Fix:** Add `ITSAppUsesNonExemptEncryption = NO` to skip the manual export-compliance question on every submission.

### [LOW] Logging via print() only, no Logger privacy levels
**Files:** `IoS Scale/Features/Onboarding/OnboardingView.swift:392`; `IoS Scale/Features/Measurement/Advanced/AdvancedIOSViewModel.swift:133,158`; `IoS Scale/Features/Measurement/Basic/BasicIOSViewModel.swift:106,141`; `IoS Scale/Core/Services/ExportService.swift:142`; `IoS Scale/Features/Measurement/SetMembership/SetMembershipViewModel.swift:141,177`; `IoS Scale/Features/Measurement/Overlap/OverlapViewModel.swift:107,142`; `IoS Scale/Features/Measurement/ExitSessionSheet.swift:119,128`
**Issue:** No secrets found in these specific statements, but none of the app's ~12 log call sites use `os.Logger`, so nothing benefits from `.private`/`.sensitive` redaction, and raw `error.localizedDescription` is retained unredacted in Console/sysdiagnose.
**Fix:** Replace `print(...)` with `Logger(subsystem:category:)` and mark any variable content `privacy: .private`.

### [LOW] Exported temp file never cleaned up after share sheet
**File:** `IoS Scale/Features/Export/ExportSheet.swift:210`
**Issue:** `data.write(to: tempURL)` writes to `FileManager.default.temporaryDirectory`; the file (which can include user-authored session notes) is never deleted after `UIActivityViewController` completes or is cancelled.
**Fix:** Use `UIActivityViewController`'s `completionWithItemsHandler` to delete `tempURL` via `FileManager.default.removeItem(at:)` once sharing finishes.
**Cross-domain:** Same root cause as the storage-auditor's MEDIUM finding on this file.

### [LOW] lockApp()/scenePhase handler is a misleading no-op
**Files:** `IoS Scale/App/IOSScaleApp.swift:51-55`; `IoS Scale/Core/Services/AuthenticationService.swift:300-303`
**Issue:** `handleScenePhaseChange(.background)` calls `AuthenticationService.shared.lockApp()`, which is stubbed to do nothing ("Lock feature removed"). No snapshot-blur/obscuring is implemented, so task-switcher snapshots of measurement screens (which can show personal notes) are unprotected, and the dead call site could mislead future maintainers into thinking protection exists.
**Fix:** Either implement a blur overlay on `.inactive`/`.background` scenePhase, or remove the dead `lockApp()` call/reference to avoid false confidence.

## Privacy Manifest Checklist

| API Category | Found in Code | Declared in Manifest | Status |
|---|---|---|---|
| UserDefaults | Y | Y (CA92.1) | OK |
| FileTimestamp | N | N | OK |
| SystemBootTime | N | N | OK |
| DiskSpace | N | N | OK |
| ActiveKeyboards | N | N | OK |

## Recommendations
1. Immediate: migrate Sign in with Apple identity data to Keychain with a UserDefaults-to-Keychain migration path (HIGH-1); resolve the Face ID usage-description gap by either deleting dead LocalAuthentication code or adding `NSFaceIDUsageDescription` (HIGH-2).
2. Short-term: extend `PrivacyInfo.xcprivacy` collected-data-types for name/email; remove the unused push notification entitlement/background mode; declare `ITSAppUsesNonExemptEncryption = NO`.
3. Long-term: migrate `print()` to `Logger` with privacy levels; clean up exported temp files after sharing; either implement real snapshot/background protection or remove the misleading `lockApp()` no-op.
