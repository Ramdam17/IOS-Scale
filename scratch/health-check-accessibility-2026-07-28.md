# Accessibility Audit — IoS Scale

Scope: `IoS Scale/` only (App, Core, Features, UI).

Positive baseline: the app's core "drag two circles" interaction is not gesture-only in most modalities — Attribution, Observation, Overlap, Projection, Identification, Proximity, Basic, and Advanced all pair the DragGesture-based `*CirclesView` with a fully accessible native Slider/IOSSlider (correct `accessibilityAdjustableAction`), and Set Membership has tappable toggle buttons. Every `*CirclesView` also carries `.accessibilityElement(children: .combine)` + label + value + hint — materially better than a typical first-pass SwiftUI app, avoiding the most severe possible finding (core scientific task unusable by VoiceOver).

## Summary
- CRITICAL: 1
- HIGH: 4
- MEDIUM: 9
- LOW: 2
- Total: 16

## Health Score

| Metric | Value |
|---|---|
| VoiceOver label coverage | Custom drag controls & primary actions: well covered (19 explicit .accessibilityLabel sites). Toolbar icon-only Exit buttons (9 files) and Home sync/settings icons rely on default SF Symbol labels only. |
| Dynamic Type support | Semantic (Typography.*) used for descriptions/body text. Fixed .font(.system(size:)): 47+ occurrences, zero @ScaledMetric/relativeTo: anywhere in the codebase. |
| Gesture accessibility | 9 drag-based measurement views; 8/9 have a redundant accessible Slider/button fallback. No core flow is VoiceOver-dead-ended. |
| WCAG Level A | 0 hard blockers found |
| WCAG Level AA | 2 (Dynamic Type 1.4.4, Contrast 1.4.3 — both systemic) |
| WCAG Level AAA | 2 (Reduce Motion 2.3.3, Touch Target 2.5.5) |
| Overall | GAPS (no CRITICAL app-store-blocking dead end, but a systemic AA violation pushes it out of COMPLIANT) |

## Findings

### [CRITICAL] Dynamic Type: primary measurement-result text never scales; zero @ScaledMetric in the codebase
**Files:** `IoS Scale/Features/Measurement/Attribution/AttributionView.swift:87`, `Observation/ObservationView.swift:87`, `Overlap/OverlapView.swift:63`, `SetMembership/SetMembershipView.swift:64`, `Projection/ProjectionView.swift:75`, `Identification/IdentificationView.swift:75`, `Proximity/ProximityView.swift:65`
**WCAG:** 1.4.4 Resize Text (AA)
**Issue:** The headline result label (e.g. `viewModel.similarityLabel`, `observationLabel`, `projectionLabel`) — the literal answer the user came to read — uses `.font(.system(size: isLandscape ? 22 : 28, weight: .bold, design: .rounded))`. A grep for @ScaledMetric across the whole app returns zero matches. Notably `BasicIOSView.swift:66` uses `Typography.title3` (semantic, scales correctly) for the equivalent label — so 7 of 9 modality screens regressed relative to the 8th.
**Impact:** Users who enable Larger Text/accessibility text sizes see the description text below grow while the actual result stays pinned at ~22-28pt — the most important text on the screen ignores their setting.
**Fix:** Replace with `Font.system(.title3, design: .rounded, weight: .bold)` (auto-scales) or `@ScaledMetric(relativeTo: .title3) private var labelSize: CGFloat = 28` driving `.font(.system(size: labelSize, weight: .bold, design: .rounded))`.
**Cross-domain:** overlaps with swiftui-layout-auditor (fixed-size layout risk at AX sizes).

### [HIGH] Insufficient color contrast on measurement-counter accent text (light mode)
**Files:** `Overlap/OverlapView.swift:104` (#FFD700), `SetMembership/SetMembershipView.swift:84` (#FFD700), `Proximity/ProximityView.swift:86` (#FFD700), `Identification/IdentificationView.swift:96` (#FFD700), `Projection/ProjectionView.swift:96` (#00CED1), `Observation/ObservationView.swift:108` (#81ECEC), `Attribution/AttributionView.swift:108` (#FAB1A0)
**WCAG:** 1.4.3 Contrast Minimum (AA) — normal text needs 4.5:1
**Issue:** `Text("\(count) measurement(s) saved")` at Typography.caption (12pt, normal text) is colored with bright/pastel hex accents rendered over the app's near-white lightBackgroundGradient. Computed contrast ratios: gold #FFD700 ~1.4:1, cyan #81ECEC <1.3:1, turquoise #00CED1 ~1.95:1, salmon #FAB1A0 ~1.77:1 — all fail the 4.5:1 floor by a wide margin (dark mode variants likely pass; light mode is the failure).
**Impact:** In light mode/Increase Contrast/bright sunlight, low-vision users effectively cannot read the measurement counter.
**Fix:** Swap to a color that meets 4.5:1 against the light gradient, or bump size to >=18pt (3:1 threshold) and verify with Accessibility Inspector's Audit tab.

### [HIGH] Sync status icon has no VoiceOver label despite a ready-made description string
**File:** `IoS Scale/Features/Home/HomeView.swift:43-55`; state model at `IoS Scale/Core/Services/CloudSyncService.swift:23-53`
**WCAG:** 4.1.2 Name, Role, Value (A)
**Issue:** `Button { ... } label: { Image(systemName: syncService.status.icon) ... }` has no `.accessibilityLabel`. `SyncStatus.displayText` already produces exactly the right string ("Up to date", "Syncing...", "Synced", error message, "Offline", "Sync disabled") but it's used only for SettingsView's row (line 207), never on this Home toolbar button.
**Impact:** VoiceOver reads only the raw SF Symbol name on the Home screen's sync indicator — no information about current sync state.
**Fix:** `.accessibilityLabel(syncService.status.displayText)` on the button in `HomeView.swift:45-55`.

### [HIGH] Onboarding theme-selection cards use raw onTapGesture with no Button trait or label
**File:** `IoS Scale/Features/Onboarding/OnboardingView.swift:291,294` (gesture), `:488-525` (`ThemePreviewCard` definition)
**WCAG:** 4.1.2 Name, Role, Value (A) / 2.5.1 Pointer Gestures
**Issue:** `ThemePreviewCard(...).onTapGesture { selectedTheme = 0 }` — no `.accessibilityAddTraits(.isButton)`, no `.accessibilityLabel`, no `.accessibilityValue` for selection state. Compare to `HomeView.swift:210-220`'s `ModalityCardView`, which does exactly this correctly for the same "tappable card" pattern.
**Impact:** VoiceOver users on the onboarding Customize page get an ambiguous "Light"/"Dark" text element with no indication it's interactive or which one is currently selected.
**Fix:** Wrap in `Button { selectedTheme = 0 } label: { ThemePreviewCard(...) }` or add `.accessibilityElement(children: .combine).accessibilityLabel("Light theme").accessibilityAddTraits(.isButton).accessibilityValue(isSelected ? "Selected" : "")`. Not launch-blocking since theme is also changeable via the fully-accessible Picker in Settings.
**Cross-domain:** overlaps with swiftui-nav-auditor/onboarding flow review.

### [HIGH] Compound: fixed-font Dynamic Type gap co-occurs with zero @ScaledMetric spacing anywhere
**Files:** same 7 files as the CRITICAL finding above
**Issue:** "Fixed font sizes + no @ScaledMetric for spacing" elevates to a more severe, systemic gap — the surrounding `VStack(spacing: isLandscape ? Spacing.xs : 0)` layouts also use fixed pt spacing constants rather than any scaled equivalent, compounding misalignment risk once other text grows under Larger Text while this block does not.
**Fix:** Same as CRITICAL fix, plus consider @ScaledMetric for the tightest spacing constants used alongside AX-scaling text blocks.

### [MEDIUM] Reduce Motion is checked only in decorative home-screen preview loops, never in the actual interactive views
**Files (representative):** `IoS Scale/UI/Components/AttributionCirclesView.swift:112,146,148,184,207-212,233`; `OverlapCirclesView.swift:146,218,288,293`; `IoS Scale/Features/Measurement/SetMembership/SetMembershipView.swift:66-67,194`
**WCAG:** 2.3.3 Animation from Interactions (AAA)
**Issue:** `@Environment(\.accessibilityReduceMotion)` is read and correctly gated in all 10 `UI/Components/Previews/*.swift` auto-playing loops, but every explicit spring/easeInOut/interactiveSpring animation that fires during actual circle dragging in production measurement screens has no such check.
**Fix:** Gate spring parameters via a helper that returns a reduced-motion-safe Animation, e.g. `withAnimation(UIAccessibility.isReduceMotionEnabled ? .linear(duration: 0.1) : .interactiveSpring(response: 0.15, dampingFraction: 0.8)) { ... }`.
**Cross-domain:** overlaps with energy-auditor's Reduce Motion findings on the same Previews folder.

### [MEDIUM] CirclesView accessibility hints reference an impossible-for-VoiceOver gesture without mentioning the on-screen alternative
**Files:** `AttributionCirclesView.swift:67`, `OverlapCirclesView.swift:81`, `ObservationCirclesView.swift:66`, `ProximityCirclesView.swift:87`, `ProjectionCirclesView.swift:67`, `IdentificationCirclesView.swift:66`
**Issue:** Hint text is literally "Drag to adjust..." — an action VoiceOver users cannot perform on a plain DragGesture. Mitigated by a preceding "Drag circles or use the slider" Text, but rotor/heading-based navigation could land a user on the CirclesView element without that context.
**Fix:** Change hint to something like "Adjustable via the slider below" or add a redundant `accessibilityAdjustableAction` directly on the CirclesView.

### [MEDIUM] Touch targets below 44x44pt
**File:** `IoS Scale/Features/Measurement/SetMembership/SetMembershipView.swift:235,272`
**WCAG:** 2.5.5 Target Size (AAA) / HIG minimum
**Issue:** The "Toggle Self"/"Toggle Other" Buttons wrap a `Circle().frame(width: 32, height: 32)` plus a caption label; effective tappable width is ~32pt.
**Fix:** `.frame(minWidth: 44, minHeight: 44)` on the button while keeping the visual circle at 32pt.

### [MEDIUM] Toolbar "Exit session" buttons rely on default SF Symbol label; inconsistent with their own bottom-row twin
**Files (9 occurrences):** `Projection/ProjectionView.swift:184-189`, `Observation/ObservationView.swift:196-201`, `Basic/BasicIOSView.swift:180-185`, `SetMembership/SetMembershipView.swift:172-177`, `Attribution/AttributionView.swift:196-201`, `Identification/IdentificationView.swift:184-189`, `Overlap/OverlapView.swift:198-203`, `Advanced/AdvancedIOSView.swift:218-223`, `Proximity/ProximityView.swift:174-179`
**Issue:** `ToolbarItem(.topBarTrailing) { Button { viewModel.requestExit() } label: { Image(systemName: "xmark.circle.fill") } }` has no `.accessibilityLabel`/`.accessibilityHint`, whereas the semantically identical bottom-row Exit button in `OverlapView.swift:162-163` explicitly sets `.accessibilityLabel("Exit session")` and `.accessibilityHint(...)`.
**Fix:** Add the same label/hint pair to all 9 toolbar buttons.

### [MEDIUM] Custom-drawn measurement visualizations expose no meaning to VoiceOver
**Files:** `IoS Scale/UI/Components/MeasurementVisualizations/MeasurementVisualizationView.swift` (used at `Features/History/MeasurementRowView.swift:35-39`), `IoS Scale/Features/History/SessionRowView.swift:112-122` (miniChart)
**Issue:** These Circle/Ellipse/Rectangle compositions carry no `.accessibilityLabel` and aren't marked `.accessibilityHidden(true)` either — silently invisible to VoiceOver. Non-blocking today since a numeric % Text sits alongside, but it's an inconsistent, undecided accessibility state.
**Fix:** Either add `.accessibilityHidden(true)` explicitly, or give it a real label, e.g. `.accessibilityLabel("Visualization: \(Int(measurement.primaryValue*100)) percent overlap")`.

### [MEDIUM] No keyboard navigation affordances anywhere in the app (iPadOS 26 target)
**Issue:** Zero matches for `.keyboardShortcut`, `.focusable(`, `@FocusState`, `.focused(` across all of `IoS Scale/`. Standard Button/NavigationLink/Slider get default Tab-focus for free, so the app is not keyboard-dead-ended, but no primary action (Save/Reset/Exit) has a `.keyboardShortcut`, and the custom drag circles have no `.focusable()`/visible focus ring.
**WCAG:** 2.1.1 Keyboard (A, iPadOS/macOS context)
**Fix:** Add `.keyboardShortcut(.defaultAction)` to primary Save buttons and `.keyboardShortcut(.cancelAction)` to Exit/Cancel buttons at minimum.

### [MEDIUM] Export error message not announced/focus-managed for VoiceOver
**File:** `IoS Scale/Features/Export/ExportSheet.swift:97-102`
**Issue:** `Label(error, systemImage: "exclamationmark.triangle")` appears in a new Form Section when exportData() fails, with no `.accessibilityAddTraits(.updatesFrequently)` and no announcement posted.
**Fix:** Post `AccessibilityNotification.Announcement("Export failed: \(error)")` (or `.layoutChanged` targeting the error element) when errorMessage is set.

### [MEDIUM] Inconsistent accessibility pattern across the app (rollup)
**Issue:** HomeView's card, all `*CirclesView` components, and SetMembershipView's toggle buttons follow a rigorous combine+label+value+hint(+traits) discipline, while the Onboarding theme cards, the toolbar Exit buttons, and the History-row visualizations do not.
**Fix:** Adopt the `HomeView.ModalityCardView` pattern as the house style and apply it to the flagged gaps above.

### [LOW] Utility icon-only buttons rely on unexplained default SF Symbol labels
**File:** `IoS Scale/Features/Home/HomeView.swift:58-65` (gearshape Settings button), `:104-116` (chart.bar.fill History button)
**Fix:** `.accessibilityLabel("Settings")` / `.accessibilityLabel("View history")` for clarity.

### [LOW] Decorative gradient status labels use non-semantic bright colors for large text
**Issue:** Same 7 files as the HIGH contrast finding — the large (>=28pt) result headline itself sometimes uses Color.yellow/gold gradients close to the same failing palette. Worth re-checking with Accessibility Inspector once the HIGH contrast fix is applied.

## Recommendations
1. Immediate (CRITICAL/HIGH): fix the 7-file Dynamic Type regression on primary result labels; fix the 7-file light-mode contrast failures on measurement counters; add the sync-status accessibility label; fix onboarding theme-card semantics.
2. Short-term (MEDIUM): gate all interaction-driven withAnimation/.animation() calls behind accessibilityReduceMotion; enlarge the two 32pt SetMembership toggle buttons; add labels to the 9 toolbar Exit buttons; decide and implement accessibility exposure (label or hidden) for the History visualizations.
3. Longer-term: add keyboard shortcuts to primary actions; add VoiceOver announcements for export errors; standardize the "combine + label + value + hint + traits" pattern app-wide.

## Testing Checklist
- VoiceOver pass on all 9 measurement screens, focusing on the toolbar Exit button and the Slider/CirclesView pair
- Dynamic Type at AX5 on Attribution/Observation/Overlap/SetMembership/Projection/Identification/Proximity result labels
- Accessibility Inspector Audit tab in light mode on all "measurement(s) saved" counters and gradient result labels
- Reduce Motion toggle ON while dragging circles in any modality
- External keyboard Tab-traversal through a full measurement + save flow on iPad
