# IoS Scale — Project Health Check (Full Audit)

**Scope:** full project audit — 63 Swift source files under `IoS Scale/` (App/, Core/Models/, Core/Services/, Features/, UI/). The `build/` directory (Xcode DerivedData artifacts) was excluded per instruction. No `DIFF SCOPE` was provided, so this is a whole-project scan, not a diff-scoped one.

**Context:** SwiftUI + SwiftData app targeting iOS 26/iPadOS 26.1, Liquid Glass design, CloudKit sync via SwiftData, Sign in with Apple, CSV/TSV/JSON export. Preparing for App Store submission. ~15,000 LOC. Zero test files exist anywhere in the repo (`XCTestCase`/`@Test`/`@Suite`: 0 matches) — all findings below concern completely untested code.

**Auditors run:** 17 (6 always-run + 11 conditional/explicitly-requested). See Summary Table for the full list, trigger reasons, and per-report links.

**Raw findings before dedup:** 178 across all 17 reports. **After deduplication by file:line/root-cause:** ~120 unique findings. Because the raw count exceeds 100, per output-limit rules this document contains full detail for all severities; the chat response accompanying this report shows CRITICAL/HIGH only in-line and points to this file (and the per-auditor `scratch/health-check-{area}-2026-07-28.md` files) for MEDIUM/LOW detail.

---

## Executive Summary — Top 5 Most Critical Findings

Ordered to foreground production-data-loss and App-Store-rejection risk, per the requester's explicit priorities.

1. **CRITICAL — Save & Exit silently discards unsaved data in 5 of 9 measurement modalities.** `Observation/ObservationViewModel.swift:147-165`, `Proximity/ProximityViewModel.swift:159-179`, `Identification/IdentificationViewModel.swift:147-165`, `Attribution/AttributionViewModel.swift:147-165`, `Projection/ProjectionViewModel.swift:147-165`. Once a user has saved ≥1 measurement in a session, tapping "Save & Exit" discards the current unsaved position instead of saving it — direct research-data loss, invisible in casual testing. (Domains: swiftui-architecture, ux-flow)
2. **CRITICAL — Edge-swipe gesture bypasses the mandatory exit-confirmation sheet on all 9 measurement screens**, discarding the in-progress measurement and leaving an orphaned, CloudKit-synced empty `SessionModel` behind. `.interactiveDismissDisabled(true)` has no effect on `NavigationStack`'s interactive pop gesture; no `UINavigationController.interactivePopGestureRecognizer` override exists anywhere. (Domains: swiftui-nav, ux-flow, swiftdata)
3. **CRITICAL — The "iCloud Sync" toggle in Settings does not control real sync, and its backing flag has three mutually contradictory defaults.** `CloudSyncService.swift:89` (default `true`) vs `SettingsView.swift:17` (default `false`) vs `AppSettings.swift:29` (default `false`); the SwiftData `ModelContainer` is built with `cloudKitDatabase: .automatic` unconditionally in `IOSScaleApp.swift:17-33` regardless of the toggle. Users who believe they disabled iCloud sync for privacy are still synced. (Domains: icloud, swiftdata, ux-flow)
4. **CRITICAL — Onboarding hard-gates the entire app behind Sign in with Apple with no skip/guest path.** `OnboardingView.swift:88-117,329-396`. Users without an Apple ID, or who decline/cancel, can never reach the (fully offline-capable) app — a real App Store rejection risk under Apple's account-gating guidance, since the app's core functionality does not require an account. (Domain: ux-flow)
5. **CRITICAL — No `VersionedSchema`/`SchemaMigrationPlan` exists despite active CloudKit sync, and `ModelContainer` creation calls `fatalError` with no recovery path.** `IOSScaleApp.swift:17-33,28-32`. Any future schema change risks crash-on-launch for every user and silent CloudKit desync across devices with mixed schema versions. (Domains: swiftdata, icloud)

Honorable mention (also CRITICAL, just outside the top 5): **"Clear All Data" in Settings is a no-op** — the confirmation alert claims permanent, irreversible deletion, but `clearAllData()` is an empty TODO stub with no `modelContext` wired in (`SettingsView.swift:64-71,238-247,367-371`). A trust-breaking bug very likely to surface during App Review testing of destructive actions. (Domains: swiftui-architecture, ux-flow, swiftdata)

---

## Findings by Domain

Findings are deduplicated: the same file:line/root-cause flagged by multiple auditors is listed once with all contributing domains tagged, at the highest severity reported.

### Data Integrity / Data Loss (cross-domain: swiftdata, icloud, storage, codable, swiftui-architecture, ux-flow, swiftui-nav)

**[CRITICAL]** Save & Exit silently discards unsaved data in 5 of 9 modalities — see Executive Summary #1.
**Fix:** Extract shared session-persistence logic into one `MeasurementSessionController`/generic base ViewModel used by all 9 modalities; make `saveAndExit` always persist the current value (matching Basic/Advanced/Overlap/SetMembership's correct behavior). Add unit tests for `handleExitAction` per modality.

**[CRITICAL]** Edge-swipe bypasses exit confirmation + orphaned CloudKit-synced sessions — see Executive Summary #2.
**Fix:** Disable `interactivePopGestureRecognizer` via a `UIViewControllerRepresentable` bridge while the measurement view is on screen (restore on disappear), or convert these 9 screens to `.fullScreenCover` presentation where `.interactiveDismissDisabled(true)` actually works. Additionally, defer `context.insert(session)` until the first measurement is saved (or add an `.onDisappear` cleanup backstop) so an interrupted session can never leave an orphaned record.

**[CRITICAL]** iCloud Sync toggle non-functional + 3 conflicting `@AppStorage` defaults — see Executive Summary #3.
**Fix:** Either remove the toggle (state plainly "synced automatically while signed into iCloud") or implement it for real: read the flag before container creation, branch `cloudKitDatabase: iCloudSyncEnabled ? .automatic : .none`, require an app relaunch to rebuild the container, and unify all three `@AppStorage`/model declarations to one source of truth.

**[CRITICAL]** No VersionedSchema/SchemaMigrationPlan + fatalError on container creation — see Executive Summary #5.
**Fix:** Introduce `VersionedSchema` for the current model set now (even a single version), add a `SchemaMigrationPlan` with at least a lightweight stage, and test the upgrade path with production-shaped data before the next schema change ships. Replace `fatalError` with a recovery path (fallback store, user-facing message, telemetry).

**[CRITICAL]** "Clear All Data" is a no-op destructive action — see Executive Summary honorable mention.
**Fix:** Inject `@Environment(\.modelContext)` into `SettingsView` and implement `clearAllData()` to delete all `SessionModel`/`MeasurementModel` instances, then `try context.save()`.

**[HIGH]** 5 of 9 measurement ViewModels silently swallow `modelContext.save()` failures via `try?`, still showing a "Saved!" success haptic/UI regardless of failure. Files: `ProjectionViewModel.swift:123,153`, `ObservationViewModel.swift:123,153`, `IdentificationViewModel.swift:123,153`, `ProximityViewModel.swift:135,166`, `AttributionViewModel.swift:123,153`. The other 4 (`BasicIOSViewModel`, `AdvancedIOSViewModel`, `OverlapViewModel`, `SetMembershipViewModel`) correctly do/catch + error haptic.
**Fix:** Standardize all 9 on `do { try modelContext?.save() } catch { HapticManager.shared.error(); surface error; skip "saved" UI }`.
**Domains:** storage, icloud, swiftdata, swiftui-architecture.

**[HIGH]** Proximity scientific data (`selfPosition`/`otherPosition`) is silently and unrecoverably dropped when exporting to JSON (still present in CSV/TSV). `ExportService.swift:193-213` vs `ProximityViewModel.swift:120-129` — `ExportMeasurement` only declares `selfScale`/`otherScale`.
**Fix:** Make `ExportMeasurement` carry the full `secondaryValues` dictionary instead of two hand-picked named fields.
**Domain:** codable.

**[HIGH]** Set Membership secondary-value keys are hardcoded camelCase strings (`"selfInSet"`/`"otherInSet"`) that diverge from the app's own canonical `Measurement.SecondaryKey` enum (which defines unused snake_case equivalents). Five separate read sites depend on the undocumented literal matching. A "helpful" future refactor to use the enum would silently break every read site.
**File:** `SetMembershipViewModel.swift:70-75` vs `Measurement.swift:43-44`.
**Fix:** Delete the unused snake_case cases (or rename to match reality) and make `SetMembershipViewModel` reference the enum, establishing one source of truth.
**Domain:** codable.

**[HIGH]** `try?`-swallowed encode/decode of `MeasurementModel.secondaryValuesData` with zero logging, on a live path synced through CloudKit — see Findings/Performance cluster below (same lines, dual angle: performance + data safety). `Measurement.swift:94,99-102`.
**Fix:** Replace `try?` with logged `do/catch` in both the encode (init) and decode (`secondaryValues` computed property) paths.
**Domains:** codable, icloud, swift-performance.

**[HIGH]** No `CKError`-level handling anywhere; sync status is fabricated, not observed. `CloudSyncService.swift:157-184` unconditionally sets `status = .success` ("Synced") after any successful `accountStatus()` call, regardless of whether CloudKit actually pushed data or hit `.quotaExceeded`/`.zoneNotFound`/`.partialFailure`/etc.
**Fix:** Observe `NSPersistentCloudKitContainer.eventChangedNotification` and map the underlying `CKError` into a real `SyncStatus.error(...)`.
**Domain:** icloud.

**[HIGH]** `fatalError` on `ModelContainer` creation with no recovery path. `IOSScaleApp.swift:28-32`.
**Fix:** On catch, attempt a fallback (recreate store / recovery UI) and log via telemetry instead of crashing.
**Domain:** swiftdata.

**[MEDIUM]** Silent secondary-value decode mismatch could desync CloudKit-synced devices on a future schema change with zero diagnostics. `Measurement.swift:93-94,99-102`. **Domains:** icloud, codable.
**[MEDIUM]** `AppSettings.load()`/`.save()` (dead code, unreferenced elsewhere) swallow decode/encode errors via `try?` with no logging; landmine if ever wired up. `AppSettings.swift:134-152`. **Domains:** storage, codable, swiftui-architecture, icloud.
**[MEDIUM]** `ModalityType` decode fallback (`?? .basicIOS`) silently mislabels unknown future modalities on cross-version CloudKit sync with no logging. `Session.swift:104-106`; `ModalityType.swift:12`. **Domain:** codable.
**[MEDIUM]** Set Membership JSON export omits `selfInSet`/`otherInSet` fields (recoverable via `primaryValue`, but undocumented 0-3 encoding). `ExportService.swift:193-212`. **Domain:** codable.
**[MEDIUM]** Export filename `DateFormatter` has no explicit locale/timeZone. `ExportService.swift:58-60`. **Domain:** codable.
**[MEDIUM]** N+1 relationship access (`session.measurements ?? []` re-derived independently per row/loop). `SessionRowView.swift:16,57,114`, `HistoryView.swift:64,73`, `ExportSheet.swift:34`, `ExportService.swift:94-95`. **Domains:** swiftdata, swiftui-performance.
**[MEDIUM]** Eagerly-inserted empty `SessionModel`s have no cleanup safety net on abnormal termination (compounds CRITICAL #2). All 9 ViewModels' `createSession()`; filtering gap at `HistoryView.swift:25-29`. **Domains:** swiftdata, swiftui-nav.
**[MEDIUM]** `.CKAccountChanged` only re-checks status, never resets state/warns the user on account switch. `CloudSyncService.swift:206-218`. **Domain:** icloud.
**[LOW]** No indexing on `createdAt`/`deletedAt`/`modalityRawValue` — fine at current scale. `Session.swift:77-87`. **Domain:** swiftdata.
**[LOW]** `Measurement`/`Session` value-type `Codable` conformance is vestigial/unused (three overlapping schema representations exist: value structs, SwiftData models, export DTOs). **Domain:** codable.
**[LOW]** `aps-environment` hardcoded to `development`; verify it flips to `production` at Archive time. `IoS Scale.entitlements:6,11`. **Domain:** icloud.

### UX Flow / Navigation (cross-domain: ux-flow, swiftui-nav, swiftui-architecture)

**[CRITICAL]** Onboarding hard-gate — see Executive Summary #4.
**Fix:** Add a "Continue without account" action setting `state = .unauthenticated` + `hasCompletedOnboarding = true`.
**Domain:** ux-flow.

**[HIGH]** No state preservation for in-progress measurement sessions — zero `@SceneStorage` anywhere; system-initiated termination during an active session loses all unsaved state with no recovery. All 9 ViewModels.
**Fix:** Persist `currentSession.id` + in-progress value via `@SceneStorage` (Codable snapshot); restore on `.onAppear`/`.task`.
**Domain:** swiftui-nav.

**[HIGH]** `AppRouter.swift` (172 lines) is entirely dead, unused navigation coordinator that diverges from the app's real (ad hoc) navigation logic in `HomeView.swift:230-252` — two competing sources of truth for modality routing.
**Fix:** Delete it, or finish wiring it in as the single navigation source.
**Domains:** swiftui-architecture, swiftui-nav, ux-flow.

**[HIGH]** 9 Measurement ViewModels duplicate ~200 lines of session-persistence boilerplate (root cause enabling the Save & Exit divergence above). All 9 `*ViewModel.swift`.
**Fix:** Extract a generic `MeasurementSessionViewModel<Value>` base type.
**Domain:** swiftui-architecture.

**[HIGH]** ViewModels import SwiftUI and call `withAnimation` directly, coupling business logic to the UI framework and making reset behavior untestable. All 9 ViewModels.
**Fix:** Move `withAnimation` into the View's button action; keep ViewModels SwiftUI-free.
**Domain:** swiftui-architecture.

**[HIGH]** History feature has no ViewModel layer; filtering/sorting/mutation and duplicated stats math live directly in `HistoryView.swift`/`SessionDetailView.swift`, drifting from `Session`'s canonical `averageValue`/`minValue`/`maxValue`.
**Fix:** Introduce a `HistoryViewModel`; route stats through the canonical `Session` methods.
**Domain:** swiftui-architecture.

**[HIGH]** Core measurement gesture-to-value math (the actual scientific instrument) lives untested inside ~7 SwiftUI View structs (`InteractiveCirclesView`, `ProximityCirclesView`, `SetMembershipCirclesView`, etc.), with zero unit tests.
**Fix:** Extract each modality's mapping formula into a plain, SwiftUI-free calculator type and unit test it.
**Domain:** swiftui-architecture.

**[HIGH]** Set Membership "in-set" threshold rule (`>0.5`) reimplemented independently in 3 places, one (`MeasurementVisualizationView`) with a divergent, undocumented fallback the other two lack.
**Fix:** Add one canonical computed property on `Measurement`/`MeasurementModel`; have all 3 call sites use it.
**Domain:** swiftui-architecture.

**[HIGH]** File I/O side effect (temp file write) performed in a View's `Task` instead of the export service. `ExportSheet.swift:191-226,210-211`.
**Fix:** Add `ExportService.writeTemporaryFile(data:filename:) throws -> URL`; keep file I/O out of the View layer.
**Domain:** swiftui-architecture.

**[HIGH]** Onboarding's local Sign-in-with-Apple handler shows a false "Sign In Failed" alert on user cancellation (unlike `AuthenticationService`'s own delegate, which correctly suppresses this). `OnboardingView.swift:383-395`.
**Domain:** ux-flow.

**[HIGH]** `TrashView` permanent per-item swipe-delete has no confirmation/undo, inconsistent with the adjacent "Empty Trash" bulk action which does confirm. `TrashView.swift:110-116`.
**Domain:** ux-flow.

**[MEDIUM]** History/SessionDetail master-detail flow doesn't use `NavigationSplitView` on iPad, wasting available width. `HistoryView.swift:81,237`. **Domain:** swiftui-nav.
**[MEDIUM]** Sign Out (nested Settings sheet) triggers a root-level auth-state swap without first dismissing the presenting sheet chain — potential visual glitch. `SettingsView.swift:72-76`; root switch `IOSScaleApp.swift:82-101`. **Domains:** swiftui-nav, ux-flow.
**[MEDIUM]** Duplicate "Sign in with Apple" `UIViewRepresentable` wrapper exists in two places. `AuthenticationService.swift:449-477`, `OnboardingView.swift:530-571`. **Domains:** swiftui-architecture, ux-flow.
**[MEDIUM]** Monolithic, non-decomposed View bodies (~200+ lines) in several measurement views. `AdvancedIOSView.swift:18-241`, `ObservationView.swift:20-219`, `BasicIOSView.swift`. **Domain:** swiftui-architecture.
**[MEDIUM]** `SessionDetailView`'s delete alert says "permanently delete" but only soft-deletes (moves to Trash) — inaccurate destructive-action copy. `SessionDetailView.swift:90-97`. **Domain:** ux-flow.
**[MEDIUM]** 3 conflicting `@AppStorage`/model defaults for `iCloudSyncEnabled` (same cluster as CRITICAL #3 above). **Domains:** ux-flow, icloud, swiftdata.
**[LOW]** `HistoryPlaceholderView.swift` is dead, superseded code, only self-referenced in its own `#Preview`. **Domains:** swiftui-architecture, swiftui-nav, swiftdata, ux-flow.
**[LOW]** `LockScreenView.swift`/`AuthenticationState.locked` are dead/unreachable (`lockApp()` is a no-op stub). **Domains:** swiftui-nav, ux-flow (also see security-privacy HIGH on the related Face ID gap).
**[LOW]** `SessionDetailView`'s `NavigationLink` for detail is view-based, precluding future deep linking (not currently needed). **Domain:** swiftui-nav.

### SwiftUI Layout & Rendering (cross-domain: swiftui-layout, swiftui-performance, accessibility)

**[CRITICAL]** Per-row date/time formatters constructed on every re-render inside `List`/`ForEach`, compounded by a non-lazy, unbounded `ForEach` in session detail. `SessionRowView.swift:30`, `TrashView.swift:157`, `MeasurementRowView.swift:18` + `SessionDetailView.swift:398-411` (`measurementsSection`).
**Fix:** Hoist all formatters to `static let`; convert `measurementsSection`'s `VStack` to `LazyVStack`.
**Domains:** swiftui-performance, swiftui-layout.

**[HIGH]** Inconsistent circle-diameter clamping: 6 of 8 `*CirclesView` components size from `horizontalSizeClass` alone with no clamp to actual container size, risking clipping/overlap in iPad Split View 33%/Slide Over or iOS 26 free-form windows. `ProximityCirclesView.swift:43-45`, `IdentificationCirclesView.swift:30-32`, `ProjectionCirclesView.swift:31-33`, `ObservationCirclesView.swift:30-32`, `AttributionCirclesView.swift:30-32`, `SetMembershipCirclesView.swift:41-51`.
**Fix:** Apply the same `min(baseDiameter, maxDiameter)` clamp already used correctly in `InteractiveCirclesView.swift`/`OverlapCirclesView.swift`.
**Domain:** swiftui-layout.

**[HIGH]** `SetMembershipCirclesView` "outside" circle visually intrudes into the set boundary at container widths ~270-300pt. `SetMembershipCirclesView.swift:41-69`.
**Fix:** Derive `setWidth`/`circleSize` from `geometry.size` with a floor, not a fixed two-tier constant.
**Domain:** swiftui-layout.

**[HIGH]** Timer leak in production "expand card" preview animation — see CRITICAL cluster above (SetMembershipPreview.swift). Cross-listed here as a rendering/performance concern.
**Domains:** swiftui-performance, memory, energy.

**[HIGH]** Whole-screen `body` re-render on every drag frame (60-120Hz) across all 9 measurement screens — `ObservableObject` invalidates the entire observing view since nothing is factored into child View structs.
**Fix:** Extract static header/buttons/labels into child View structs; migrate ViewModels to `@Observable`.
**Domain:** swiftui-performance.

**[HIGH]** Modernization: legacy `ObservableObject`/`@Published` pattern across 11 classes (all 9 measurement ViewModels + `ThemeManager` + `AppRouter`), `@StateObject` should become `@State` (10 sites), `.environmentObject()`/`@EnvironmentObject` should migrate to `.environment()`/`@Environment` (5 sites: `ContentView.swift:18`, `SettingsView.swift:376,13`, `IOSScaleApp.swift:38`, `HomeView.swift:259`), 11 now-unnecessary `Combine` imports. `CloudSyncService`/`AuthenticationService` already use `@Observable` and can serve as reference implementations.
**Fix:** Migrate all 11 classes to `@Observable`; then `@StateObject`→`@State`; then `.environment()`; remove Combine imports. No breaking changes, ~7-11h estimated effort.
**Domains:** modernization, swiftui-performance, swiftui-architecture.

**[MEDIUM]** Hardcoded, non-adaptive `dragRange` constant (300pt literal) in 3 CirclesView components, inconsistent with 2 siblings that correctly scale by container width. `IdentificationCirclesView.swift:283`, `ObservationCirclesView.swift:274`, `AttributionCirclesView.swift:249`. **Domain:** swiftui-layout.
**[MEDIUM]** Stacked shadow/blur effects recomputed every drag frame; likely (unprofiled) contributor to dropped frames on older devices. `CircleView.swift:59-67`, `OverlapCirclesView.swift:130-146,150-176`, `ProximityCirclesView.swift:104,171,198,253`. **Domain:** swiftui-performance.
**[MEDIUM]** Duplicated `DateFormatter`/`RelativeDateTimeFormatter` construction across 4 History views. `SessionDetailView.swift:130-140`, `SessionRowView.swift:22-33`, `MeasurementRowView.swift:17-21`, `TrashView.swift:155-160`. **Domains:** swiftui-architecture, swiftui-performance.
**[MEDIUM]** `UserDefaults` read on every haptic call (up to ~20x/drag). `HapticManager.swift:27-29`. **Domain:** swift-performance.
**[MEDIUM]** Missing `reserveCapacity` in nested export loop. `ExportService.swift:75,94-125`. **Domain:** swift-performance.
**[MEDIUM]** 8 `DispatchQueue.main.asyncAfter` calls that should use `Task.sleep`; 4 `DateFormatter()` instances that should use `FormatStyle`; 5+ `Date()` instances that should use `Date.now`. **Domain:** modernization.
**[LOW]** Zero adoption of iOS 16+/17+ layout APIs (`onGeometryChange`, `ViewThatFits`, `AnyLayout`, `containerRelativeFrame`) app-wide. **Domain:** swiftui-layout.
**[LOW]** 10 `withAnimation` closures that could use the `.animation(value:)` modifier. **Domain:** modernization.
**[LOW]** `async` function with no internal `await`, apparently unused (`AuthenticationService.swift:305-308`); unnecessary `Task {}` around a synchronous no-op (`IOSScaleApp.swift:52-55`). **Domain:** swift-performance.

### Memory & Concurrency (cross-domain: memory, concurrency, swift-performance, energy)

**[CRITICAL]** Uninvalidated repeating `Timer` pair leaks unbounded on every Set Membership card expand/collapse — see Executive Summary cluster. `SetMembershipPreview.swift:60,67`.
**Fix:** Store timers and invalidate in `onDisappear`, or replace with `withAnimation(...repeatForever...)` matching the other 8 preview files.
**Domains:** memory, energy, swiftui-performance.

**[CRITICAL]** `ExportService`'s CSV/TSV/JSON generation runs on the `@MainActor` with no offload; `ExportSheet`'s `Task {}` doesn't detach isolation, so large exports freeze the UI. `ExportService.swift:73,132`; `ExportSheet.swift:195-226`.
**Fix:** Make the string-building methods `nonisolated`/move to a background actor; hop to `@MainActor` only for the final file write and UI update.
**Domains:** concurrency, swiftui-performance.

**[HIGH]** Non-Sendable delegate parameters (`ASAuthorization`/`Error`) captured across an isolation boundary inside `Task { @MainActor in ... }` — triggers strict-concurrency errors. `AuthenticationService.swift:365-395,397-426`.
**Fix:** Extract only Sendable primitives before entering the Task.
**Domain:** concurrency.

**[HIGH]** Home-screen preview animations (9 files) never stop — no `onDisappear` cancellation anywhere, worse on iPad where cards default-expand, running all 9 infinite loops concurrently and indefinitely.
**Fix:** Gate on visibility/`scenePhase`, or drive from a single shared state machine.
**Domain:** energy.

**[HIGH]** Continuous GPU blur inside the always-looping previews. `OverlapPreview.swift:36`, `ObservationPreview.swift:37`.
**Domain:** energy.

**[MEDIUM]** 4 ViewModels use a strong `self` capture in a `Task`-based save-confirmation delay instead of `[weak self]` (used correctly by the other 5 siblings). `BasicIOSViewModel.swift:136`, `OverlapViewModel.swift:137`, `SetMembershipViewModel.swift:172`, `AdvancedIOSViewModel.swift:122`.
**Fix:** Standardize on `[weak self]` across all 9.
**Domains:** memory, concurrency, swift-performance.

**[MEDIUM]** `HapticManager` wraps main-thread-only UIKit feedback generators without `@MainActor`/actor isolation — no active bug, but an isolation-coverage gap. `HapticManager.swift:15`. **Domain:** concurrency.
**[MEDIUM]** Inconsistent Reduce Motion handling — checked only in decorative Home-screen previews, never in the actual interactive circle-drag views; no `onDisappear` cleanup pattern anywhere. `ProjectionCirclesView.swift:238-244`, `ObservationCirclesView.swift:253-258`, `IdentificationCirclesView.swift:238-243`, `OnboardingView.swift:158-162`. **Domains:** energy, accessibility.
**[LOW]** Mixed GCD/async-await style for identical UI-timing logic across the ViewModel family. **Domain:** concurrency.

### Security & Privacy (cross-domain: security, storage)

**[HIGH]** Sign in with Apple identity (user ID, email, name) stored in plaintext `UserDefaults`/`@AppStorage` instead of Keychain — doesn't survive reinstall as intended, and PII sits without Keychain-level access control. `AuthenticationService.swift:52,54,56`.
**Fix:** Migrate to Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) with a one-time migration path.
**Domains:** storage, security.

**[HIGH]** LocalAuthentication (Face ID) is called with no `NSFaceIDUsageDescription` declared anywhere — a guaranteed crash the instant this currently-dead code path (`lockApp()` is a no-op stub) is reactivated. `AuthenticationService.swift:61,74,130,170`; `LockScreenView.swift:105,164`.
**Fix:** Delete the dead LocalAuthentication code, or add `NSFaceIDUsageDescription` now regardless of current reachability.
**Domain:** security.

**[MEDIUM]** Privacy Manifest (`PrivacyInfo.xcprivacy`) collected-data-types list omits name/email actually collected via Sign in with Apple (only declares User ID). **Domain:** security.
**[MEDIUM]** Unused Push Notification entitlement/background mode (`aps-environment`, `UIBackgroundModes: remote-notification`) with zero corresponding APNs implementation anywhere — unnecessary signing/provisioning friction and reviewer scrutiny. **Domain:** security.
**[MEDIUM]** Exported session data (including free-text notes) left in `tmp/` with no cleanup after Share Sheet use, and written without explicit file protection. `ExportSheet.swift:210-211`. **Domains:** storage, security.
**[LOW]** `ITSAppUsesNonExemptEncryption` not declared (app only uses exempt encryption) — would skip the manual export-compliance question on every submission. **Domain:** security.
**[LOW]** Logging via `print()` only, no `Logger`/privacy levels anywhere (12 call sites); no secrets found in current content, but no redaction discipline exists. **Domain:** security.
**[LOW]** `lockApp()`/scenePhase handler is a misleading no-op; no real snapshot/background-obscuring protection exists for screens that may show personal notes. **Domain:** security.
**[LOW]** Dead/duplicated settings-persistence path (`AppSettings.load()/save()`), unreferenced elsewhere in the codebase. **Domains:** storage, codable, swiftui-architecture.

### Liquid Glass Adoption (domain: liquid-glass)

Deployment target is iOS 26.1-only (no back-deploy), so every fix below can be applied unconditionally with no `#available` gating.

**[HIGH]** `LiquidGlassCard.swift` — the app's namesake "Liquid Glass" component — uses `.fill(.ultraThinMaterial)`/manual gradients, never `.glassEffect()`/`GlassEffectContainer`. Used in 9+ locations across Home/History/SessionDetail.
**[HIGH]** The primary "Save" action on all 9 measurement screens bypasses system/glass button styling entirely (plain `Button` + gradient background, no `.buttonStyle`/`.glassEffect()`).
**[HIGH]** Reset/Exit buttons and slider chrome use raw `.ultraThinMaterial` across ~7 files/20+ sites — direct, ship-ready migration candidates.
**[HIGH]** "Saved!" confirmation toast uses `.ultraThinMaterial` across all 9 measurement views — a flagship Liquid Glass use case currently unmigrated.
**[MEDIUM]** Zero native glass API usage anywhere in the codebase despite the 26.1-only target.
**[MEDIUM]** `SessionDetailView` stacks up to 7 independent glass panels with no `GlassEffectContainer` — will look like glass-on-glass mud once migrated unless grouped.
**[MEDIUM]** `ExitSessionSheet` buttons are fully custom, bypassing system/glass semantics.
**[MEDIUM]** Home screen's floating "stats" action button ignores glass treatment (solid gradient circle instead of `.glassEffect(.regular.interactive())`).
**[MEDIUM]** Onboarding decorative icon backgrounds use `.ultraThinMaterial`.
**[LOW]** One `.borderedProminent` button with no explicit `.tint()`.
**[LOW]** Search/tab architecture note — `.tabRole(.search)` N/A today (no app-wide TabView), flag only if that changes.

Full fix snippets and every file:line are in `scratch/health-check-liquid-glass-2026-07-28.md`.

### Accessibility (domain: accessibility)

**[CRITICAL]** Primary measurement-result headline text never scales with Dynamic Type — fixed `.font(.system(size:))` on 7 of 9 modality screens, zero `@ScaledMetric` anywhere in the app (the 8th screen, Basic, uses the correct semantic `Typography.title3` and shows the fix pattern). WCAG 1.4.4 (AA).
**Fix:** `Font.system(.title3, design: .rounded, weight: .bold)` or `@ScaledMetric(relativeTo: .title3)`.

**[HIGH]** Insufficient color contrast (as low as ~1.3:1, need 4.5:1) on measurement-counter text in light mode across 7 files — bright/pastel accent colors on a near-white background. WCAG 1.4.3 (AA).
**[HIGH]** Sync status icon on Home has no VoiceOver label despite a ready-made description string (`SyncStatus.displayText`) already used elsewhere.
**[HIGH]** Onboarding theme-selection cards use raw `onTapGesture` with no Button trait/label/selection-state — inconsistent with `HomeView`'s correctly-accessible card pattern.
**[HIGH]** (Compound) The fixed-font Dynamic Type gap co-occurs with fixed-pt spacing constants in the same 7 files, compounding misalignment risk once other text grows under Larger Text.

**[MEDIUM]** Reduce Motion gated only in decorative Home previews, never in actual interactive circle-drag views (WCAG 2.3.3, AAA).
**[MEDIUM]** CirclesView accessibility hints reference an impossible-for-VoiceOver "drag" gesture without mentioning the on-screen Slider alternative.
**[MEDIUM]** Touch targets below 44x44pt on 2 Set Membership toggle buttons (WCAG 2.5.5, AAA).
**[MEDIUM]** 9 toolbar "Exit session" buttons rely on default SF Symbol labels, inconsistent with their own labeled bottom-row twin.
**[MEDIUM]** Custom-drawn measurement visualizations expose no meaning to VoiceOver (neither labeled nor explicitly hidden).
**[MEDIUM]** No keyboard navigation affordances anywhere (no `.keyboardShortcut`/`.focusable`/`@FocusState`) despite iPadOS 26 target.
**[MEDIUM]** Export error message not announced/focus-managed for VoiceOver.
**[MEDIUM]** (Rollup) Accessibility discipline is inconsistent app-wide: rigorous on Home cards and CirclesView, absent on Onboarding theme cards, toolbar Exit buttons, and History visualizations.

**[LOW]** Utility icon-only buttons (Settings gear, History chart icon) rely on unexplained default SF Symbol labels.
**[LOW]** Decorative gradient result-label colors are visually close to the same failing palette as the HIGH contrast finding.

Full fix snippets, WCAG references, and a VoiceOver/Dynamic Type/Reduce Motion testing checklist are in `scratch/health-check-accessibility-2026-07-28.md`.

---

## Passed Audits

None of the 17 auditors returned zero findings — every domain surfaced at least one issue. This is expected for a first comprehensive audit of an untested (0 test files), pre-submission app; it is not itself alarming, but it does mean there is no domain that can be skipped in the remediation pass.

---

## Summary Table

| Auditor | Trigger Reason | Findings | Severity Breakdown | Report File |
|---------|---------------|----------|---------------------|--------------|
| memory-auditor | always | 2 | 1 CRITICAL, 1 MEDIUM | scratch/health-check-memory-2026-07-28.md |
| security-privacy-scanner | always | 8 | 2 HIGH, 2 MEDIUM, 4 LOW | scratch/health-check-security-2026-07-28.md |
| accessibility-auditor | always | 16 | 1 CRITICAL, 4 HIGH, 9 MEDIUM, 2 LOW | scratch/health-check-accessibility-2026-07-28.md |
| swift-performance-analyzer | always | 6 | 1 CRITICAL, 2 MEDIUM, 3 LOW | scratch/health-check-swift-performance-2026-07-28.md |
| modernization-helper | always | 38 | 23 HIGH, 10 MEDIUM, 5 LOW | scratch/health-check-modernization-2026-07-28.md |
| codable-auditor | always | 9 | 3 HIGH, 4 MEDIUM, 2 LOW | scratch/health-check-codable-2026-07-28.md |
| swiftdata-auditor | signal: @Model/SwiftData (29 files) | 10 | 1 CRITICAL, 3 HIGH, 3 MEDIUM, 3 LOW | scratch/health-check-swiftdata-2026-07-28.md |
| concurrency-auditor | signal: async/await (11 files) | 5 | 1 CRITICAL, 1 HIGH, 2 MEDIUM, 1 LOW | scratch/health-check-concurrency-2026-07-28.md |
| swiftui-performance-analyzer | signal: import SwiftUI (pervasive) | 10 | 3 CRITICAL, 2 HIGH, 3 MEDIUM, 2 LOW | scratch/health-check-swiftui-performance-2026-07-28.md |
| swiftui-architecture-auditor | signal: import SwiftUI | 16 | 2 CRITICAL, 8 HIGH, 5 MEDIUM, 1 LOW | scratch/health-check-swiftui-architecture-2026-07-28.md |
| swiftui-layout-auditor | signal: import SwiftUI | 5 | 2 HIGH, 2 MEDIUM, 1 LOW | scratch/health-check-swiftui-layout-2026-07-28.md |
| swiftui-nav-auditor | signal: import SwiftUI + NavigationStack/sheet/TabView (18 files) | 8 | 1 CRITICAL, 1 HIGH, 3 MEDIUM, 2 LOW | scratch/health-check-swiftui-nav-2026-07-28.md |
| icloud-auditor | signal: CloudKit/CKContainer (Session, Measurement, CloudSyncService, entitlements) | 10 | 2 CRITICAL, 2 HIGH, 3 MEDIUM, 3 LOW | scratch/health-check-icloud-2026-07-28.md |
| storage-auditor | signal: FileManager/UserDefaults (4 files) | 5 | 2 HIGH, 2 MEDIUM, 1 LOW | scratch/health-check-storage-2026-07-28.md |
| ux-flow-auditor | signal: NavigationStack/sheet/TabView (18 files) | 14 | 3 CRITICAL, 4 HIGH, 4 MEDIUM, 3 LOW | scratch/health-check-ux-flow-2026-07-28.md |
| energy-auditor | explicit user request | 4 | 1 CRITICAL, 2 HIGH, 1 MEDIUM | scratch/health-check-energy-2026-07-28.md |
| liquid-glass-auditor | explicit user request + signal (LiquidGlassCard.swift) | 12 | 4 HIGH, 6 MEDIUM, 2 LOW | scratch/health-check-liquid-glass-2026-07-28.md |
| **Total (raw, pre-dedup)** | | **178** | | |

Skipped (no signal, not requested): core-data-auditor, foundation-models-auditor, spritekit-auditor, camera-auditor, networking-auditor, database-schema-auditor, textkit-auditor, testing-auditor (notable: zero test files exist in the project), screenshot-validator (no Screenshots/marketing folder found).

---

## Recommended Remediation Order

1. **Before any further TestFlight/App Store activity:** fix the Save & Exit data-loss divergence, the exit-confirmation swipe-bypass, the non-functional iCloud Sync toggle (and its 3 conflicting defaults), the onboarding hard-gate, and the Clear All Data no-op. These five are the ones most likely to cause either real user data loss or App Store rejection/trust issues.
2. **Before the next schema change ships:** add `VersionedSchema`/`SchemaMigrationPlan` and replace `fatalError` container creation with a recovery path — this is not urgent for *this* release but becomes urgent the moment any `@Model` property changes.
3. **Short sprint:** standardize save-error handling across all 9 measurement ViewModels; fix the SetMembershipPreview timer leak; fix the Dynamic Type and contrast accessibility CRITICAL/HIGH findings; migrate the 4 HIGH Liquid Glass surfaces (Save button, Reset/Exit chrome, confirmation toast, LiquidGlassCard itself).
4. **Modernization sweep:** migrate all `ObservableObject` ViewModels + `ThemeManager`/`AppRouter` to `@Observable` (reference implementation already exists in `CloudSyncService`/`AuthenticationService`); this unblocks cleaner fixes for several of the architecture findings above.
5. **Longer-term:** add a test target (currently zero coverage for any business logic, including the scientific measurement formulas); extract the CirclesView gesture-to-value math into unit-testable calculator types; delete the accumulated dead code (`AppRouter.swift`, `HistoryPlaceholderView.swift`, `LockScreenView.swift`/`.locked` state, unused `AppSettings` persistence).
