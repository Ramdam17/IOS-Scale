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
4. ✅ Rémy arbitrated 2026-07-30 (1: reco / 2: document / 3: consolidate / 4: ok / 5: full
   scope, no deferral) — **addendum T5b executed same day**:
   - Normative: DESIGN-STANCES **v1.1** (stance 3 + `color_scheme`) + DATA_DICTIONARY
     (context `color_scheme`; per-appearance fill convention + opaque-occlusion convention
     under `instrument_version`) — commit 69b68a3.
   - T5b-1 typo: 14 new Apple-ramp styles (incl. rounded); 142 texts consolidated, 0 unmapped
     (Foundations spec-sheet labels intentionally excluded).
   - T5b-2 tokens: radius/sm 12→10 (matches reality), + radius/xs=4, radius/full=999; radius
     code syntax fixed to `Radius.*`; ~180 paddings/115 gaps/32 radii bound. Literals kept by
     design: device insets (59/34/21), composition margins (40/80, iPad gutter 20), r28/32/40.
   - T5b-3 icons: `Icon` set (8 glyphs incl. chevron.left, SF-Symbol-named vectors, bound to
     text/primary) + `IconButton` 44×44; all ⓘ/⚙/🗑/▼/▲ replaced (24 IconButtons, 4 chevrons);
     "Value ›" composites split into text + chevron.right (10 rows).
   - T5b-4: new primitives rainbow/accent-start #3A6FC4 (4.9:1) / accent-end #86489E (5.6:1),
     semantic accent/stop-* realiased in rainbow modes only (circles untouched); TEXT props
     added: InfoSheet ×4, SaveToast ×1, ExitSheet Title.
   - T5b-5 coverage (56 frames total: Classic 30 / Rainbow 26): 9-card Home on iPhone (clipped
     stack = scroll)/iPad 3×3/Mac; pole frames Separated+Concentric ×2 universes (PositionSlider
     gained Position=Start/Mid/End axis); FR: Home iPad + Settings + ExitSheet (passes);
     Dynamic Type XL measurement frame (passes no-scroll at 135%); 10 dark counterparts;
     Mac window chrome (traffic lights + title) on 4 measurement windows + 2 new Home Mac;
     History session-detail ("mean position" stats) + empty state ×2 universes; onboarding
     dots + Continue + screen-2 alignment + Classic parity (3 screens).
   - Final audit vs safe rects: **56 frames, 0 real violations** (1 documented false positive:
     full-screen scrim on Exit Sheet FR overlay frame).
5. ⬜ JALON 4 re-validation (Rémy, in Figma) → spec §14 update + final commit.

## Known leftovers (phase 2/3, deliberate)

- Modality descriptors for Proximity/Identification/Projection/Attribution/Observation are
  stimulus-descriptive **placeholders** — finalize with ModalityDocumentation at phase-2 gate
  (EN+FR); Attribution/Observation stimuli themselves are phase-2 design decisions.
- ParticipantChip Guest variant text not linked to its Code prop (P-07 variant is).
- Card tint swatches: new Home cards use default swatch; per-modality tint binding = phase 3.
- Onboarding hero animation must oscillate, never "arrive" at concentric (stance gate NOTE).
- A11y strings + celebration visual: re-gate at phase-2/3 (V3/V1 forward guards).

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
