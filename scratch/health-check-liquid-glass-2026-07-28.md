# Liquid Glass Adoption Audit — IoS Scale

## Visual Treatment Map
- Deployment target: iOS 26.1 (single target, `IPHONEOS_DEPLOYMENT_TARGET = 26.1` in both build configs) — no back-deploy, so `if #available(iOS 26,*)` gating is never required.
- Native Liquid Glass API usage: 0 occurrences of `.glassEffect(`, `.glassBackgroundEffect(`, `GlassEffectContainer`, or `.interactive()` anywhere under `IoS Scale/`.
- Legacy effect surface: 33 `.background(.ultraThinMaterial)` / `.fill(.ultraThinMaterial)` / `.fill(.regularMaterial)` call sites across 11 files.
- "Liquid Glass" branded component (`LiquidGlassCard.swift`) is entirely built from `Material` + manual gradients/shadows/borders — no real glass API.
- Toolbars: 16 files define `.toolbar { }`; all rely on automatic system chrome (fine), but primary actions inside content (not toolbars) are hand-styled, bypassing `.buttonStyle(.borderedProminent)`/glass entirely.
- No app-wide `TabView`/`.tabRole(.search)`; navigation is `NavigationStack` + sheets, so search-tab guidance is N/A.
- No media (photo/video/map) surfaces in the app — Regular-vs-Clear variant discipline is not applicable here.
- Adoption status: NOT ADOPTED — zero native glass API calls despite an iOS-26.1-only deployment target that could adopt it unconditionally.

## Summary
- HIGH: 4 (grouped, ~30 locations)
- MEDIUM: 6
- LOW: 2
- Total: 12

## Findings

### [HIGH] LiquidGlassCard.swift is not real Liquid Glass (Material-only implementation)
**File:** `IoS Scale/UI/Components/LiquidGlassCard.swift:53-105, 204-231`
**Issue:** The app's namesake "Liquid Glass" component (`LiquidGlassCard`, `GlassBackgroundModifier`/`.glassBackground()`) uses `.fill(.ultraThinMaterial)`/`.fill(.regularMaterial)` plus manual `LinearGradient` overlays, `strokeBorder`, and custom shadows — never `.glassEffect()` or `GlassEffectContainer`. Used at: `IoS Scale/Features/Home/HomeView.swift:138`; `IoS Scale/Features/History/HistoryView.swift:338`; `IoS Scale/Features/History/SessionDetailView.swift:127,154,293,393,413,448`; `IoS Scale/Features/History/SessionRowView.swift:93`; `IoS Scale/Features/History/TrashView.swift:203`.
**Fix:**
```swift
content
    .padding(Spacing.md)
    .glassEffect(.regular.tint(tintColor), in: .rect(cornerRadius: LayoutConstants.cardCornerRadius))
```
Wrap groups of adjacent cards (e.g. the 3 `StatCard`s in SessionDetailView) in a single `GlassEffectContainer` for morphing/merging instead of independent materials.
**Variant guidance:** Regular (no media surfaces in this app).

### [HIGH] Primary "Save" action on every measurement screen bypasses system/glass button styling
**Files:** `IoS Scale/Features/Measurement/Basic/BasicIOSView.swift:94-107`; `AdvancedIOSView.swift:136-149`; `Overlap/OverlapView.swift:110-123`; `SetMembership/SetMembershipView.swift:90-103`; `Proximity/ProximityView.swift:92-105`; `Identification/IdentificationView.swift:102-115`; `Projection/ProjectionView.swift:102-115`; `Attribution/AttributionView.swift:114-127`; `Observation/ObservationView.swift:114-127`
**Issue:** The single most-used action in the app (Save measurement, 9 files) is a plain `Button` with `.background(ColorPalette.primaryButtonGradient)` — never `.buttonStyle(.borderedProminent)`/`.tint()`, and no `.glassEffect()`. It gets zero Liquid Glass press/material feedback.
**Fix:**
```swift
Button { viewModel.saveMeasurement() } label: { Label("Save", systemImage: "checkmark.circle.fill") }
    .buttonStyle(.glassProminent)   // or .borderedProminent
    .tint(ColorPalette.selfCircleCore)
```
**Cross-domain:** overlaps with accessibility (custom buttons should be checked for contrast/hit-target after restyling).

### [HIGH] Reset/Exit buttons and slider chrome use raw `.ultraThinMaterial` (direct, ship-ready migration)
**Files:** `Projection/ProjectionView.swift:131,147,262`; `Proximity/ProximityView.swift:121,137,268`; `Observation/ObservationView.swift:143,159,274`; `SetMembership/SetMembershipView.swift:119,135,291`; `Identification/IdentificationView.swift:131,147,262`; `Attribution/AttributionView.swift:143,159,274`; `Overlap/OverlapView.swift:141`
**Issue:** Since deployment target is iOS 26.1 only, these are direct-replacement candidates (no availability gate needed).
**Fix:** `.glassEffect(.regular, in: .rect(cornerRadius: LayoutConstants.buttonCornerRadius))` in place of `.background(.ultraThinMaterial).clipShape(...)`.

### [HIGH] "Saved!" confirmation toast uses `.ultraThinMaterial` across all 9 measurement views
**Files:** `Basic/BasicIOSView.swift:217`; `Advanced/AdvancedIOSView.swift:255`; `Projection/ProjectionView.swift:292`; `Proximity/ProximityView.swift:298`; `Observation/ObservationView.swift:304`; `SetMembership/SetMembershipView.swift:311`; `Identification/IdentificationView.swift:292`; `Attribution/AttributionView.swift:304`; `Overlap/OverlapView.swift:239`
**Issue:** A floating, transient confirmation overlay is a flagship Liquid Glass use case; currently a static material card.
**Fix:** `.glassEffect(.regular, in: .rect(cornerRadius: LayoutConstants.cardCornerRadius))` — no `if #available` needed given the 26.1 deployment target.

### [MEDIUM] Codebase-wide: zero native glass API adoption despite iOS-26.1-only target
**File:** whole `IoS Scale/` tree (grep confirms 0 matches for `.glassEffect(`, `.glassBackgroundEffect(`, `GlassEffectContainer`)
**Fix:** Establish a glass-adoption rubric (which surfaces get glass: primary chrome/toasts/floating controls vs. plain list rows) and roll it out via the fixes above.

### [MEDIUM] Stacked independent glass panels on one scroll screen without `GlassEffectContainer`
**File:** `IoS Scale/Features/History/SessionDetailView.swift:127` (sessionHeader), `154` (chartSection), `293` (setMembershipStats), `393` (notesSection), `413` (measurementsSection), `448` (StatCard x3 in statsSection)
**Issue:** Up to 7 separate `.glassBackground()` panels render independently on one screen — once migrated to real glass this becomes glass-on-glass visual mud unless merged.
**Fix:** Group with a single `GlassEffectContainer(spacing:)` so panels morph/merge rather than each rendering isolated blur.

### [MEDIUM] ExitSessionSheet modal buttons fully custom, bypass system/glass semantics
**File:** `IoS Scale/Features/Measurement/ExitSessionSheet.swift:55-69` (Save & Exit), `72-86` (Exit Without Saving), `89-98` (Cancel)
**Fix:** Use `.buttonStyle(.borderedProminent).tint(...)` for Save & Exit, `.buttonStyle(.bordered).tint(.red)` for the destructive option, plain `.buttonStyle(.plain)`/`.cancellationAction` for Cancel.

### [MEDIUM] Floating action button (FAB) ignores glass treatment
**File:** `IoS Scale/Features/Home/HomeView.swift:104-122`
**Issue:** Circular "stats" FAB floating over a ScrollView uses a solid gradient `Circle()` + manual shadow — a canonical `.glassEffect()` + `.interactive()` candidate.
**Fix:** `.glassEffect(.regular.interactive(), in: .circle)`.

### [MEDIUM] Decorative onboarding icon backgrounds use `.ultraThinMaterial`
**File:** `IoS Scale/Features/Onboarding/OnboardingView.swift:466` (`ExportIconView`)
**Fix:** `.glassEffect(.regular, in: .rect(cornerRadius: 16))` — low traffic but easy win; also `HomeView.swift:113/204` and `HistoryPlaceholderView.swift:70` share the same custom-gradient primary-button pattern as the Save buttons above.

### [LOW] `.borderedProminent` without explicit `.tint()`
**File:** `IoS Scale/Features/Onboarding/OnboardingView.swift:113`
**Fix:** `.buttonStyle(.borderedProminent).tint(.accentColor)` (or brand color) to make prominence intentional rather than implicit.

### [LOW] Search/tab architecture note (informational, not a defect)
**File:** `IoS Scale/Features/History/HistoryView.swift:92` (`.searchable`)
**Issue:** App has no app-wide `TabView`; search lives in a sheet-presented `NavigationStack`, so `.tabRole(.search)` doesn't apply today. Flag only if the app later adopts tab-based root navigation.

## Recommendations
1. Immediate: migrate the 4 HIGH items — replace `.ultraThinMaterial`/`.regularMaterial` in `LiquidGlassCard.swift`, the Save buttons, Reset/Exit controls, and confirmation toasts with `.glassEffect()`/`GlassEffectContainer` (no availability gating needed, target is 26.1-only).
2. Short-term: consolidate SessionDetailView's stacked glass panels under one `GlassEffectContainer`, restyle ExitSessionSheet and the HomeView FAB, add explicit `.tint()` to the Onboarding CTA.
3. Long-term: write a glass-adoption rubric; re-run accessibility-auditor for text-on-glass contrast once migrated; add snapshot tests for the restyled Save/toast surfaces.
