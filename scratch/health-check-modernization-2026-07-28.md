# Modernization Audit — IoS Scale (iOS 26 target)

## Summary
Total Findings: 38
- CRITICAL: 0
- HIGH: 23 (ObservableObject pattern, @StateObject, @EnvironmentObject, .environmentObject usage)
- MEDIUM: 10 (DispatchQueue.main.asyncAfter, DateFormatter, Date() vs Date.now)
- LOW: 5 (withAnimation closures)

Baseline: the app already targets iOS 26 and has begun modernization — CloudSyncService and AuthenticationService already use `@Observable`. The majority of ViewModels still use the legacy `ObservableObject` pattern, so these two files serve as reference implementations for the rest of the migration.

## HIGH Findings

1. **Legacy `ObservableObject` pattern across 11 observable classes** (~57 total `@Published` declarations)
   - Files: `Features/Measurement/Advanced/AdvancedIOSViewModel.swift`, `Features/Measurement/Basic/BasicIOSViewModel.swift`, `Features/Measurement/Overlap/OverlapViewModel.swift`, `Features/Measurement/Attribution/AttributionViewModel.swift`, `Features/Measurement/Identification/IdentificationViewModel.swift`, `Features/Measurement/Observation/ObservationViewModel.swift`, `Features/Measurement/Proximity/ProximityViewModel.swift`, `Features/Measurement/SetMembership/SetMembershipViewModel.swift`, `Features/Measurement/Projection/ProjectionViewModel.swift`, `UI/Themes/ThemeManager.swift`, `Core/Services/AppRouter.swift`
   - Pattern: `final class X: ObservableObject { @Published var property }`
   - Fix: migrate to the `@Observable` macro; remove `@Published`. Do this before touching `@StateObject` call sites (item 2 depends on this).

2. **10 `@StateObject` usages that should become `@State`** (dependent on fix #1)
   - Files: all 9 measurement feature Views (one `@StateObject private var viewModel = ViewModel()` each) plus `App/IOSScaleApp.swift`
   - Fix: once the corresponding ViewModel is `@Observable`, change `@StateObject` to `@State`.

3. **4 deprecated `.environmentObject()` calls** (legacy pattern for ThemeManager)
   - `IoS Scale/ContentView.swift:18`
   - `IoS Scale/Features/Settings/SettingsView.swift:376`
   - `IoS Scale/App/IOSScaleApp.swift:38`
   - `IoS Scale/Features/Home/HomeView.swift:259`
   - Fix: change to `.environment(ThemeManager.self)` (requires ThemeManager to be `@Observable` per fix #1).

4. **1 `@EnvironmentObject` declaration**
   - `IoS Scale/Features/Settings/SettingsView.swift:13` — `@EnvironmentObject private var themeManager: ThemeManager`
   - Fix: `@Environment(ThemeManager.self) var themeManager`

5. **11 unnecessary `Combine` imports**
   - All `*ViewModel.swift` files and services retained for `ObservableObject`/`@Published`; removable once fix #1 lands.

## MEDIUM Findings

1. **8 `DispatchQueue.main.asyncAfter()` calls** (should use `Task.sleep` + async/await)
   - `IoS Scale/Features/Measurement/Projection/ProjectionViewModel.swift:136`
   - `IoS Scale/Features/Measurement/Observation/ObservationViewModel.swift:136`
   - `IoS Scale/Features/Measurement/Identification/IdentificationViewModel.swift:136`
   - `IoS Scale/Features/Measurement/Attribution/AttributionViewModel.swift:136`
   - `IoS Scale/Features/Measurement/Proximity/ProximityViewModel.swift:148`
   - `IoS Scale/Features/Home/HomeView.swift:81`
   - `IoS Scale/UI/Components/Previews/AdvancedIOSPreview.swift:67`
   - `IoS Scale/UI/Components/Previews/SetMembershipPreview.swift:66`
   - Pattern: `DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in ... }`
   - Fix: `try await Task.sleep(nanoseconds: 1_500_000_000)` inside an async context.

2. **4 `DateFormatter()` instances** (should use `FormatStyle`)
   - `IoS Scale/Features/History/SessionDetailView.swift`, `IoS Scale/Features/History/SessionRowView.swift`, `IoS Scale/Core/Services/ExportService.swift`, `IoS Scale/Features/History/MeasurementRowView.swift`
   - Fix: `date.formatted(.dateTime.year().month().day())` (supported since iOS 15.1, safe for iOS 26 target).

3. **5+ `Date()` instances that should use `Date.now`**
   - `IoS Scale/Core/Services/CloudSyncService.swift:172-173`, `IoS Scale/Core/Models/Measurement.swift:25`, `:85`, `IoS Scale/Core/Models/Session.swift:24`
   - Fix: replace `Date()` with `Date.now`.

## LOW Findings

1. **10 `withAnimation` closures that could use the `.animation(value:)` modifier**
   - `IoS Scale/Features/Onboarding/OnboardingView.swift:93,103,159`
   - `IoS Scale/Features/Home/HomeView.swift:217`
   - `IoS Scale/Features/History/TrashView.swift:127`
   - `IoS Scale/Features/History/HistoryView.swift:312`
   - 5 additional component files (ProximityCirclesView, ObservationCirclesView, etc. — exact lines not captured by auditor)
   - Fix: replace closure-based `withAnimation { ... }` with `.animation(.spring(), value: state)` where a single state transition drives the animation.

## Migration Path (suggested order)

1. **Observable models**: migrate all ViewModels + ThemeManager + AppRouter from `ObservableObject`/`@Published` to `@Observable`; drop Combine imports.
2. **Property wrappers**: `@StateObject` → `@State`, `@EnvironmentObject` → `@Environment`, `.environmentObject()` → `.environment()`.
3. **Async/await**: replace `DispatchQueue.main.asyncAfter` with `Task.sleep`.
4. **Modern APIs**: `DateFormatter` → `FormatStyle`, `Date()` → `Date.now`, refactor `withAnimation` closures.

Estimated effort: 7-11 hours total across the four phases, no breaking changes — all migrations are API-compatible with iOS 26 and should not change user-facing behavior. CloudSyncService.swift and AuthenticationService.swift are already `@Observable` and can serve as reference implementations.
