# SwiftUI Navigation Audit — IoS Scale

Scope: `IoS Scale/` only (build/ excluded).

## Navigation Architecture Map
- Containers: 5 active `NavigationStack` roots (HomeView, HistoryView, TrashView, SettingsView, ExportSheet) — no `NavigationSplitView`, no app-level `TabView` (only a page-style `TabView` inside OnboardingView, not primary nav).
- `NavigationPath`: defined once in `Core/Services/AppRouter.swift` (a full singleton coordinator with `AppDestination`/`AppSheet` enums and `.navigationDestination(for:)`) but never referenced by any view — entirely dead code.
- Destination registration: 0 active `.navigationDestination(for:)` calls; all navigation is via `.sheet` (modals) or plain `NavigationLink(destination:)` (view-based push).
- Deep links: no `.onOpenURL`, no `CFBundleURLTypes`/URL scheme, no associated domains, no widget/extension target. Deep linking is not a current product requirement.
- State preservation: zero `@SceneStorage` usage anywhere; no navigation or in-progress-session persistence.
- Measurement flow: 9 modality views pushed via `NavigationLink` from `HomeView`, each hides the back button and sets `.interactiveDismissDisabled(true)`, routing exit through a custom `ExitSessionSheet`.
- History/Trash/Export/Settings are presented as `.sheet`s from `HomeView`, each with its own internal `NavigationStack` (correct pattern for modal-with-drill-down).

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 3
- LOW: 2
- Total: 8

## Navigation Health Score

| Metric | Value |
|--------|-------|
| Path coverage | 5 active NavigationStacks, 0 with NavigationPath binding (acceptable, no deep-link requirement) |
| Destination coverage | 0 types pushed via .navigationDestination; 1 unused registration in dead AppRouter.swift |
| Deep link coverage | 0/13 screens reachable via deep link (by design, not a gap) |
| State preservation | NavigationPath persisted: no. In-progress measurement state persisted: no |
| Deprecated APIs | 0 deprecated NavigationLink(isActive:)/tag:selection: usages |
| Container correctness | Mostly yes; History/SessionDetail master-detail flow doesn't use NavigationSplitView on iPad |
| Overall | BROKEN (CRITICAL exit-flow bypass causes silent data loss + orphaned records) |

## Findings

### [CRITICAL] Exit-flow bypass: edge-swipe-back circumvents ExitSessionSheet, causing silent data loss and orphaned SwiftData records
**Files** (identical pattern in all 9 measurement views):
- `IoS Scale/Features/Measurement/Basic/BasicIOSView.swift:165,201` + `BasicIOSViewModel.swift:148,156`
- `IoS Scale/Features/Measurement/Advanced/AdvancedIOSView.swift:203,239` + `AdvancedIOSViewModel.swift:177,185`
- `IoS Scale/Features/Measurement/Overlap/OverlapView.swift:183,219` + `OverlapViewModel.swift:149,157`
- `IoS Scale/Features/Measurement/SetMembership/SetMembershipView.swift:157,193` + `SetMembershipViewModel.swift:184,192`
- `IoS Scale/Features/Measurement/Proximity/ProximityView.swift:159,195` + `ProximityViewModel.swift:108,169-173`
- `IoS Scale/Features/Measurement/Identification/IdentificationView.swift:169,205` + `IdentificationViewModel.swift:102,156-160`
- `IoS Scale/Features/Measurement/Projection/ProjectionView.swift:169,205` + `ProjectionViewModel.swift:102,156-160`
- `IoS Scale/Features/Measurement/Attribution/AttributionView.swift:181,217` + `AttributionViewModel.swift:102,156-160`
- `IoS Scale/Features/Measurement/Observation/ObservationView.swift:181,217` + `ObservationViewModel.swift:102,156-160`

**Issue:** Every measurement view is pushed via `NavigationLink` (not presented as a sheet), then applies `.navigationBarBackButtonHidden(true)` and `.interactiveDismissDisabled(true)` to force all exits through `ExitSessionSheet` (via `viewModel.requestExit()`/`handleExitAction`). Neither modifier disables the system's interactive edge-swipe-to-pop gesture on `NavigationStack` — `interactiveDismissDisabled` only affects sheet/fullScreenCover swipe-dismissal, and `navigationBarBackButtonHidden` only hides the button, not the gesture. No `UINavigationController.interactivePopGestureRecognizer` override exists anywhere in the codebase (verified: zero matches). A user can swipe from the left edge to pop the view directly, completely bypassing `ExitSessionSheet`.
**Impact:** (1) The user's current unsaved slider/measurement position is discarded without the "Save & Exit" prompt ever appearing — silent data loss for a research-data-collection tool. (2) Each view creates an empty `SessionModel` unconditionally in `onAppear` (`configure(with:)` -> `createSession()`); the empty-session cleanup (`discardSessionIfEmpty()` / inline equivalent) only runs inside `handleExitAction`, which the swipe gesture never triggers. The empty `SessionModel` is therefore persisted permanently, appears in `HistoryView`'s unfiltered `@Query` (no `measurementCount > 0` filter) as a "0 measurements" session polluting session/stat counts, and syncs to CloudKit via the automatic SwiftData sync.
**Fix:** Wrap the pushed measurement view in a `UIViewControllerRepresentable` (or a `.background` helper) that finds the hosting `UINavigationController` and sets `interactivePopGestureRecognizer.isEnabled = false` while the view is on screen, restoring it on disappear — or convert the flow to `.fullScreenCover`/sheet presentation (where `.interactiveDismissDisabled(true)` actually works) instead of a `NavigationLink` push. Additionally, make `createSession()` defer the SwiftData insert until the first `saveMeasurement()` call (or run the empty-session cleanup from `.onDisappear` as a backstop) so an interrupted session can never leave an orphaned record regardless of how the view is dismissed.

### [HIGH] No state preservation for in-progress measurement session
**Files:** all 9 `*ViewModel.swift` files listed above (e.g. `IoS Scale/Features/Measurement/Basic/BasicIOSViewModel.swift:27-42`)
**Issue:** `overlapValue`/equivalent primary value, `measurementCount`, and `currentSession` live only in `@Published`/in-memory ViewModel state with zero `@SceneStorage` or Codable persistence anywhere in the app.
**Impact:** If iOS terminates the app while a measurement session is active (backgrounding + memory pressure/jetsam), the entire in-progress session state — including any measurements not yet explicitly saved — is lost on relaunch with no recovery path and no user warning. This compounds the CRITICAL finding above: because there is no route to persist or recover mid-session state, any unplanned exit (system-initiated or gesture-bypass) is unrecoverable data loss.
**Fix:** Persist `currentSession.id` + `overlapValue`/measurement-in-progress fields via `@SceneStorage` (Codable snapshot), and restore on `.task`/`.onAppear` by resolving the SwiftData session ID.
**Cross-domain:** overlaps with ux-flow (silent loss of user progress / no recovery UX).

### [MEDIUM] Centralized navigation coordinator (`AppRouter.swift`) is entirely dead code
**File:** `IoS Scale/Core/Services/AppRouter.swift:1-172`
**Issue:** `AppRouter` defines a complete NavigationPath-based coordinator (`AppDestination`, `AppSheet`, `navigate(to:)`, `withAppNavigation()`, plus placeholder views `SettingsPlaceholderView`/`ComingSoonView`). Grep confirms zero references to `AppRouter`, `AppDestination`, `AppSheet`, or `withAppNavigation()` outside this file itself. Actual navigation is instead done ad hoc per-view with local `@State` booleans and `.sheet`/`NavigationLink`.
**Impact:** Maintenance risk — a future contributor may assume this is the live navigation layer and wire new destinations into it, silently producing screens that never appear.
**Fix:** Either delete `AppRouter.swift` (and its placeholder views) or actually adopt it if centralized routing/deep-linking is planned.

### [MEDIUM] History/SessionDetail master-detail flow doesn't use NavigationSplitView on iPad
**File:** `IoS Scale/Features/History/HistoryView.swift:81,237`
**Issue:** The app targets iPad (`TARGETED_DEVICE_FAMILY = "1,2,7"`, and `HomeView` already adapts its grid to 2 columns on `.regular` size class), yet `HistoryView` — a canonical list+detail scenario — is presented as a full-screen `.sheet` containing a plain `NavigationStack` with a view-based `NavigationLink(destination: SessionDetailView(session: session))` push, rather than a `NavigationSplitView` sidebar+detail layout.
**Impact:** On iPad, opening History pushes the detail full-screen inside the modal instead of showing session list and detail side-by-side.
**Fix:** Convert `HistoryView` to `NavigationSplitView { sessionList } detail: { SessionDetailView(session:) }` with a selection binding.

### [MEDIUM] Sign Out (nested sheet) triggers root-level auth-state swap without dismissing the presenting sheet chain
**Files:** `IoS Scale/Features/Settings/SettingsView.swift:72-76` (calls `authService.resetOnboarding()`), presented via `IoS Scale/Features/Home/HomeView.swift:75` (`.sheet(isPresented: $showingSettings)`), root switch in `IoS Scale/App/IOSScaleApp.swift:82-101`
**Issue:** `resetOnboarding()` sets `AuthenticationService.state = .onboarding`, which causes the app root `Group` to swap `ContentView()` (containing `HomeView` and its active `SettingsView` sheet) for `OnboardingView()`. This removes the entire presenting hierarchy — including the still-open Settings sheet — instead of first calling `dismiss()` and letting it close before the root transitions.
**Impact:** Undefined/uncoordinated interaction between the sheet's dismissal and the root's `.easeInOut(duration: 0.3)` opacity transition — potential visual glitch on sign-out.
**Fix:** In the Sign Out alert action, call `dismiss()` on `SettingsView` first, then trigger `authService.resetOnboarding()`.
**Cross-domain:** overlaps with ux-flow.

### [LOW] Additional dead-code / unreachable navigation branches
**Files:** `IoS Scale/Features/History/HistoryPlaceholderView.swift` (superseded by HistoryView, referenced only by its own #Preview), `IoS Scale/Features/Settings/LockScreenView.swift` + `AuthenticationState.locked` case (`IoS Scale/App/IOSScaleApp.swift:93`) — `lockApp()` in `AuthenticationService.swift:301-303` is a no-op stub, so `.locked` is never assigned and `LockScreenView` is unreachable.
**Fix:** Remove `HistoryPlaceholderView.swift`, and either remove the `.locked` case/`LockScreenView` or restore the lock feature if still intended.

### [LOW] View-based NavigationLink for SessionDetailView precludes future deep linking
**File:** `IoS Scale/Features/History/HistoryView.swift:237`
**Issue:** `NavigationLink(destination: SessionDetailView(session: session))` is view-based rather than value-based. Currently harmless, but would need refactoring for future deep-link features.
**Fix:** If deep linking to a session is ever planned, migrate to `NavigationLink(value: session.id)` + `.navigationDestination(for: SessionModel.ID.self)`.

## Recommendations
1. Immediate (CRITICAL): fix the swipe-back gesture bypass across all 9 measurement views — either disable `interactivePopGestureRecognizer` via UIKit bridging or switch these screens to `.fullScreenCover` presentation, and make empty-session cleanup defer-insert-based so it can't be skipped.
2. Short-term (HIGH/MEDIUM): add `@SceneStorage`-based persistence for in-progress measurement state; decide the fate of `AppRouter.swift` (adopt or delete); fix the Settings sign-out/root-swap sequencing.
3. Longer-term: convert History to `NavigationSplitView` for iPad; remove remaining dead code (`HistoryPlaceholderView`, unreachable `.locked` state); consider value-based navigation for `SessionDetailView` if any deep-link feature is roadmapped.
