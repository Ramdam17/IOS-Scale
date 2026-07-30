# Phase 1 (Figma) — Execution State

> Cold-resume file. Updated 2026-07-30 after Task 5 gates ran and majors were fixed.
> Plan: `2026-07-29-phase-1-figma.md` · Spec: `../specs/2026-07-28-ios-scale-v2-rebuild-design.md`

## Figma file

- **URL:** https://www.figma.com/design/hNWYGtMXDiqAYNDEsoWdqX
- fileKey: `hNWYGtMXDiqAYNDEsoWdqX` (team::1396102690966057483, drafts)
- Pages: `00 Cover` 0:1 · `01 Foundations` 1:2 · `02 Components` 1:3 · `03 Screens — Classic` 1:4 · `04 Screens — Rainbow` 1:5 · `99 Scratch` 1:6

## Jalons

- ✅ JALON 1 (foundations/palette Classic) — validated
- ✅ JALON 2 (components + 4-mode demo) — validated
- ✅ JALON 3 (screen matrix, 30 frames, post-fixes) — validated
- ⬜ JALON 4 — gates ran 2026-07-30, majors fixed; **awaiting Rémy's arbitration + validation**

## Task 5 status (2026-07-30)

1. ✅ `@figma-design-reviewer` ran (verdict NEEDS WORK) — all Criticals fixed same day:
   - Safe-area repositioning on every iPhone frame: portrait paddings 24/24 → **59 top / 34
     bottom**; landscape → **59 sides / 21 bottom** (+ stimulus content group recentered);
     scrollable screens (Home/Settings/History) top padding → 59. iPad already compliant (24/20).
   - **No-scroll audit re-run against the SAFE-AREA rect** (not the frame): 0 violations / 30
     frames. Audit classes: iphone-portrait 59/34, iphone-landscape 59+59/21, ipad 24/20, mac 0.
   - Slider centered on cross-axis (`counterAxisAlignItems: CENTER` on measurement frames).
   - PositionSlider master: handle moved to 0.62 (both variants) + On-label default "0.62" —
     value/handle/geometry now agree (was 0.50/0.62/0.607).
   - 37 texts linked to text styles (exact fontName+size matches only).
   - Verified for reviewer: Set Membership frames have NO PositionSlider (categorical ✓);
     landscape render confirms controls-beside-stimulus; 99 Scratch is empty.
2. ✅ Stance gate ran (simulated stance-reviewer): **GATE: FAIL (1 BLOCK)** — the BLOCK is
   normative, not pixel-level: dark mode alters the stimulus (Classic Self/Other relative
   luminance inverts) but context records no `color_scheme`. Needs Rémy: DATA_DICTIONARY
   (draft) addition + stance-3 consequence amendment. V1–V4 + V7 all clean.
3. ✅ Liquid-glass pass: core compliant (4-mode vars, scopes, aliases, gradient stops bound,
   effect styles used, touch targets ≥44 except 28pt chip visual). Documented deviations, not
   mutated: no glass materials (measurement screens are no-scroll/content-first = "Clear";
   system chrome supplies glass in code) and Unicode glyphs standing in for SF Symbols
   (info.circle, gearshape, trash, chevron.up/down — annotate in phase 3).
4. ⬜ JALON 4 (Rémy): arbitrations listed in the JALON 4 synthesis (conversation 2026-07-30):
   color_scheme BLOCK; Classic Self/Other fill convention across modes; typography drift
   (12 off-ramp combos vs SwiftUI ramp); spacing/radius not bound to Layout vars (values 5/6/
   10/999 off token scale); coverage additions (FR frames, Dynamic Type XL, extreme-state
   frames, 9-card Home, dark counterparts, Mac chrome, SF-Symbol icon set, Rainbow button
   contrast 3.8:1, occlusion convention, InfoSheet TEXT props, History detail, onboarding
   affordances) — phase-1 addendum vs phase-2/3 deferral per item.

## Key IDs

- Collections: Primitives `VariableCollectionId:2:2` · Semantic `VariableCollectionId:2:3`
  (modes: classic-light `2:1`, classic-dark `2:2`, rainbow-light `2:3`, rainbow-dark `2:4`)
  · Layout `VariableCollectionId:2:4`
- Semantic vars: `VariableID:3:2..3:21` (color) + `text/on-accent 9:10` + `modality/* 7:2..7:10`
  + `type/title-family 4:12` · Layout `4:2..4:11` · Primitives `2:5..2:43`
- Components (page 1:3): Circle `7:19` · CirclePair `8:22` · Button `9:17` ·
  PositionSlider `15:17` · ParticipantChip `15:24` · SaveToast `15:25` ·
  ModalityCard `16:33` · FeedbackToggleRow `17:24` · InfoSheet `18:16` ·
  ExitSheet `18:43` · ModeDemo `19:21`
- Screens Classic (1:4): basic P/L/iPad/Mac `21:2 22:7 23:13 23:28` · SM `26:24 26:37 27:31 27:44` ·
  home P/iPad `31:38 33:65` · settings `33:137` · history `34:135` · basic-dark `34:160` · onboarding-proof `34:170`
- Screens Rainbow (1:5): basic `24:2 24:20 25:13 25:31` · SM `28:24 28:39 30:31 30:46` ·
  home `32:38 35:65` · settings `35:137` · history `36:135` · basic-dark `36:160` ·
  onboarding `36:173 36:196 36:208`

## Hard-won gotchas (do not relearn)

- "SF Pro" is listed but renders zero-width in this context → mockup stand-ins:
  **Inter** (SF Pro) and **Nunito** (SF Pro Rounded); real fonts live in code.
- Text fills bound to variables: set paint base color to
  `variable.resolveForConsumer(node).value` + apply via fills AND setRangeFills.
- `instance.resize()` does NOT reflow children — master components need explicit
  constraints (Circle/CirclePair: SCALE; slider track: STRETCH, handle: CENTER);
  after changing master constraints, nudge-resize existing instances to reflow.
- Overflow audits must use `absoluteBoundingBox` (raw), not `absoluteRenderBounds`
  (post-clipping hides overflows).
- Audits green at JALON 3: 0 no-scroll violations, 0 zero-width text, 0 non-round
  ellipses across 30 frames.
- Session scratchpad ledger (same content, richer):
  `/private/tmp/claude-502/-Users-remyramadour-Workspace-Apps-IoS-Scale/92f5dbe9-a95a-480d-81e1-afde50651fd4/scratchpad/dsb-state-ios-scale-v2-figma-p1.json`
