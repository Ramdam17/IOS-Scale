# SwiftUI Performance Audit — IoS Scale

## Summary
- CRITICAL: 3
- HIGH: 2
- MEDIUM: 3
- LOW: 2
- Total: 10

## Findings

### [CRITICAL] Formatter created per row in History list cell
**File:** `IoS Scale/Features/History/SessionRowView.swift:30` (called from body at :74)
**Issue:** `relativeDate` builds a fresh `RelativeDateTimeFormatter()` every time the row re-renders; the row is used inside `List > ForEach(filteredSessions)` at `IoS Scale/Features/History/HistoryView.swift:236`, so the cost multiplies by visible-row count on every scroll/update.
**Fix:** Hoist to a `static let` formatter or precompute the string once and store it on the session view-model/row-item.

### [CRITICAL] Formatter created per row in Trash list cell
**File:** `IoS Scale/Features/History/TrashView.swift:157` (called from body at :189)
**Issue:** Same pattern: `RelativeDateTimeFormatter()` built per row inside `List > ForEach(deletedSessions)` (`TrashView.swift:98`).
**Fix:** Same as above.

### [CRITICAL] Formatter-in-cell + missing lazy loading compound in session detail
**File:** `IoS Scale/Features/History/MeasurementRowView.swift:18` (used at :49), rendered by a non-lazy `VStack`+`ForEach` at `IoS Scale/Features/History/SessionDetailView.swift:398-411` (`measurementsSection`)
**Issue:** `SessionModel.measurements` (`Core/Models/Session.swift:86-87`) has no cap — users can keep saving measurements indefinitely within a session — so a long session pays per-row `DateFormatter()` construction for an unbounded, eagerly-materialized list.
**Fix:** Change `measurementsSection`'s VStack to LazyVStack, and hoist `MeasurementRowView`'s formatter to a `static let`.

### [HIGH] Timer leak in production "expand card" preview animation
**File:** `IoS Scale/UI/Components/Previews/SetMembershipPreview.swift:52-73`
**Issue:** `.onAppear { startAnimation() }` creates two `Timer.scheduledTimer(repeats: true)` instances that are never stored in @State/invalidated in .onDisappear. This is live UI, not just an Xcode preview: `ModalityPreviewView` routes to it whenever the user expands the "Set Membership" card on the Home screen (`HomeView.swift:183-226`, `ModalityCardView`). Every expand/collapse cycle leaks two more perpetual timers that keep firing withAnimation forever.
**Fix:** Store timers in `@State private var timer: Timer?`, invalidate both in .onDisappear, or replace with a declarative `.animation(...repeatForever...)`.
**Cross-domain:** same finding reported by memory-auditor and energy-auditor.

### [HIGH] Whole-screen body re-render on every drag frame, across all 9 measurement screens
**File (representative):** `IoS Scale/Features/Measurement/Basic/BasicIOSView.swift:16,22-203` (`@StateObject viewModel`, drag-bound at :52,71); same architecture in AdvancedIOSView.swift, OverlapView.swift, ProximityView.swift, IdentificationView.swift, ProjectionView.swift, AttributionView.swift, ObservationView.swift, SetMembershipView.swift
**Issue:** Each screen's body is one large, non-decomposed `GeometryReader { ScrollView { VStack { ... } } }`. `DragGesture.onChanged` writes `@Published var overlapValue` (etc.) at touch-sample frequency (60-120 Hz) directly through a @Binding. Because ObservableObject invalidates the whole observing view and nothing is factored into separate child View structs, every drag sample re-executes the entire body — header text, Save/Reset/Exit buttons, labels — not just the circles/slider that depend on the changed value.
**Fix:** Extract static header/buttons/labels into their own View structs, and migrate the view models to @Observable so SwiftUI can skip re-evaluating subviews that don't read the changed property.

### [MEDIUM] Stacked shadow/blur effects recomputed every drag frame
**Files:** `IoS Scale/UI/Components/CircleView.swift:59-67`; `OverlapCirclesView.swift:130-146,150-176`; `ProximityCirclesView.swift:104,171,198,253`
**Issue:** Each circle stacks 1-3 `.shadow()`/`.blur()` modifiers with state-driven radius/opacity/position, recomputed on every drag sample. Blur/shadow force offscreen compositing passes.
**Fix:** Profile with Instruments during active drag; if confirmed, use `.drawingGroup()` to flatten layers or reduce blur radius while isDragging.

### [MEDIUM] Export path blocks main thread despite Task wrapper
**File:** `IoS Scale/Core/Services/ExportService.swift:26` (`@MainActor final class`) + `IoS Scale/Features/Export/ExportSheet.swift:191-227`
**Issue:** CSV/JSON building iterates every measurement in every session with no size cap. Because ExportService is @MainActor, the Task{} in exportData() doesn't move this work off the main actor — a large history export will freeze the UI.
**Fix:** Make the string-building methods nonisolated/move to a background actor; hop to @MainActor only for the final file write and UI state update.
**Cross-domain:** same finding as concurrency-auditor's CRITICAL.

### [MEDIUM] Unbounded .repeatForever animations
**Files:** `IoS Scale/UI/Components/IdentificationCirclesView.swift:238-243`, `ProjectionCirclesView.swift:239-244`, `ObservationCirclesView.swift:253-258`
**Issue:** Animate indefinitely once a threshold (value > 0.7) is crossed, regardless of visibility.
**Fix:** Gate on scenePhase/visibility or cap repetition count.
**Cross-domain:** same finding as energy-auditor's MEDIUM.

### [LOW] ObservableObject/@Published used app-wide instead of @Observable
**Files:** `IoS Scale/UI/Themes/ThemeManager.swift:13`, `IoS Scale/Core/Services/AppRouter.swift:23`, and all 9 Features/Measurement/*/​*ViewModel.swift files
**Fix:** Migrate to @Observable (matters most where Finding #5 above is concerned).

### [LOW] Formatters recreated on every re-render of a single-instance header
**File:** `IoS Scale/Features/History/SessionDetailView.swift:130-140` (sessionHeader)
**Issue:** Two DateFormatter() built on any state change in the screen (e.g. isEditingNotes toggling). Not a scrolling cell, so low impact.
**Fix:** Hoist to static let.
**Minor nit:** `SessionRowView.swift:22-27`'s `formattedDate` is declared but never called — dead code.

## Recommendations
1. Immediate: hoist all per-row formatters (SessionRowView, TrashView, MeasurementRowView) to static let; switch SessionDetailView's measurementsSection to LazyVStack.
2. Short-term: fix the SetMembershipPreview timer leak; decompose the 9 measurement screens' bodies and migrate ViewModels to @Observable.
3. Long-term: profile shadow/blur cost with Instruments; move ExportService's CSV/JSON generation off the MainActor; gate unbounded repeatForever animations.
