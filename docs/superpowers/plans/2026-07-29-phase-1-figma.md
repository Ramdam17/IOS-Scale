# Phase 1 — Figma Design System & Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline, with Rémy validation milestones) — this phase is interactive design work; per-task subagents would lose the visual iteration context. Steps use checkbox (`- [ ]`) syntax.

**Goal:** A validated Figma file containing the 4-mode design system (Classic/Rainbow × Light/Dark) and the key screens of both universes across all form factors — so Classic exists and is approved visually before any SwiftUI is written.

**Architecture:** One Figma file. Variable collections: `Primitives` (raw ramps), `Semantic` (4 modes), `Layout` (spacing/radius/type). Components bound to semantic variables only. Screens assembled from components, per form factor, audited programmatically (text bounds, no-scroll), then gated (figma-design-reviewer + stance gate + apple-liquid-glass) and validated by Rémy per milestone. Tokens flow one way: **Figma variables → phase 2 `Theme` code** (Polysomnia rule, kept).

**Tech Stack:** Figma MCP (`use_figma`, `generate_figma_design`, `create_new_file`) via the mandatory workflow skills; review agents.

**Source spec:** `docs/superpowers/specs/2026-07-28-ios-scale-v2-rebuild-design.md` §3 (theming), §5 (de-valencing), §9 (screens + platforms/no-scroll), §14 phase 1.

## Global Constraints

- **Stances apply to pixels** (`docs/DESIGN-STANCES.md`): symmetric slider (uniform track, plain handle — NO fill toward a pole); no value-conditional decoration anywhere; labels describe the stimulus ("Separated / Touching / Partial overlap / Concentric"); stats copy says "position", never "score"; celebrations exist only as a save-time overlay component, identical whatever the value.
- **No-scroll (spec §9)**: measurement frames must contain stimulus + all controls within the viewport on every form factor — iPhone landscape included.
- **Mandatory skill order** (Polysomnia method): `figma:figma-use` before ANY `use_figma` call; `figma:figma-generate-library` before tokens/components; `figma:figma-generate-design` before screens; `figma:figma-create-new-file` before file creation. `apple-liquid-glass` applies (iOS 26 target — unlike Polysomnia).
- Copy in frames: English placeholders, neutral wording; text-prone components must also be checked with FR-length strings (French runs ~20% longer).
- Frame sizes: iPhone portrait 393×852, iPhone landscape 852×393, iPad portrait 1032×1376, Mac window 1024×768 (min size).
- Rémy is the design owner: every milestone marked **JALON** stops for his validation before proceeding.

---

### Task 1: Create the file

- [ ] **Step 1:** Invoke `figma:figma-create-new-file` (mandatory prerequisite), then create a design file named **"IOS Scale v2 — Design System"** in Rémy's team (team::1396102690966057483).
- [ ] **Step 2:** Verify: file URL returned; report it to Rémy. Pages to create: `00 Cover`, `01 Foundations`, `02 Components`, `03 Screens — Classic`, `04 Screens — Rainbow`, `99 Scratch`.

### Task 2: Variables — Primitives, Semantic (4 modes), Layout

**Consumes:** `IoS Scale/UI/Themes/ColorPalette.swift`, `Spacing.swift`, `Typography.swift`, `Documentation/DESIGN_GUIDE.md` (Rainbow values are v1-validated; Classic values below are STARTING PROPOSALS to iterate with Rémy).
**Produces:** variable names consumed by Tasks 3–4 and by phase 2 code: `semantic/circle/self-fill`, `self-stroke`, `other-fill`, `other-stroke`, `overlap-fill`, `bg/canvas`, `surface/card`, `surface/card-border`, `text/primary`, `text/secondary`, `accent/primary`, `feedback/success`, `feedback/destructive`, `type/title-family`.

- [ ] **Step 1:** Invoke `figma:figma-use` + `figma:figma-generate-library`, then create collections.

- [ ] **Step 2: `Primitives` collection (1 mode).** Rainbow (from v1 code): `rainbow/self-core #4A90D9`, `rainbow/self-glow #7BB3FF`, `rainbow/other-core #9B59B6`, `rainbow/other-glow #D98EDB`, bg-light stops `#F8F9FF #E8F4F8 #FFF8F0 #F0FFF4`, bg-dark stops `#1A1A2E #16213E #1F1135 #0F0F23`, `card-dark #2A2A3E`, `success #27AE60/#6BCB77`, `destructive #E74C3C/#FF6B6B`, the 9 modality tints (`#74B9FF #FD79A8 #A29BFE #636E72 #00CEC9 #FDCB6E #E17055 #FAB1A0 #81ECEC`). Classic (neutral ramp = Apple system grays): `gray-50 #F5F5F7`, `gray-100 #E5E5EA`, `gray-200 #D1D1D6`, `gray-300 #AEAEB2`, `gray-400 #8E8E93`, `gray-500 #636366`, `gray-600 #48484A`, `gray-700 #3A3A3C`, `gray-800 #2C2C2E`, `gray-900 #1C1C1E`, `white #FFFFFF`.

- [ ] **Step 3: `Semantic` collection — exactly 4 modes** `classic-light`, `classic-dark`, `rainbow-light`, `rainbow-dark`:

| Variable | classic-light | classic-dark | rainbow-light | rainbow-dark |
|---|---|---|---|---|
| circle/self-fill (55%) | gray-500 | gray-300 | self-core→glow gradient | idem + glow stroke |
| circle/self-stroke | gray-700 | gray-100 | self-core | self-glow |
| circle/other-fill (55%) | gray-300 | gray-500 | other-core→glow gradient | idem |
| circle/other-stroke | gray-400 | gray-400 | other-core | other-glow |
| overlap-fill | gray-600 @ 70% | gray-200 @ 70% | blended self+other 70% | idem |
| bg/canvas | gray-50 (flat) | gray-900 (flat) | 4-stop light gradient | 4-stop dark gradient |
| surface/card | white | gray-800 | white @ 80% | card-dark @ 60% |
| text/primary | gray-900 | gray-50 | system primary | system primary |
| text/secondary | gray-500 | gray-300 | secondary | secondary |
| accent/primary | gray-700 | gray-200 | self-core→other-core gradient | idem |
| type/title-family | SF Pro | SF Pro | SF Pro Rounded | SF Pro Rounded |

Classic self/other identity rule (starting point): **Self is always the higher-contrast circle** relative to canvas. Iterated at JALON 1.

- [ ] **Step 4: `Layout` collection:** spacing `xxs 4, xs 8, sm 12, md 16, lg 24, xl 32, xxl 48`; radius `sm 12, md 16, lg 20`; type scale from DESIGN_GUIDE (LargeTitle 34 bold / Title 28 / Headline 17 semibold / Body 17 / Caption 12 / Numeric mono 24).

- [ ] **Step 5: Verify programmatically** (read-only `use_figma`): Semantic collection has exactly 4 modes; every semantic variable resolves in all 4; no orphan primitives. Build a `01 Foundations` page: swatch grids per mode + type ramp.

- [ ] **Step 6 — JALON 1 (Rémy):** present Foundations (esp. the proposed Classic palette and Self/Other differentiation) — iterate until validated. Do not start components before this gate.

### Task 3: Core components (`02 Components`)

- [ ] **Step 1:** With `figma-component-quality` + `figma:figma-use` loaded, build (all fills/strokes bound to `Semantic` variables — zero hardcoded values; each with variants):
  1. `Circle/Self`, `Circle/Other` — variants: state `default/dragging` (dragging = scale 1.05 + shadow, NOT value-dependent).
  2. `CirclePair` — property `overlap: separated/touching/partial/concentric` (display states for docs/cards).
  3. `PositionSlider` — **uniform track both sides of the handle** (stance 1); variants: `showsValue on/off`.
  4. `ModalityCard` — variants `collapsed/expanded`; tint dot bound per-modality.
  5. `Button/Primary`, `Button/Secondary`, `Button/Destructive`.
  6. `ParticipantChip` — variants `guest/coded`.
  7. `FeedbackToggleRow` (Settings), `SaveToast` (the neutral celebration surface: "Measurement saved"), `InfoSheet` scaffold (what/how/consigne sections), `ExitSheet` (3-button and 2-button variants — adaptive semantics from spec §6).
- [ ] **Step 2: Text-bounds audit (mandatory, programmatic)** — run the read-only sweep below on `02 Components` with EN and FR-length sample strings; fix every hit in the **main component**:

```javascript
for (const screen of figma.currentPage.children.filter(n => n.type === 'FRAME')) {
  const sb = screen.absoluteBoundingBox;
  for (const t of screen.findAllWithCriteria({ types: ['TEXT'] })) {
    const b = t.absoluteRenderBounds || t.absoluteBoundingBox;
    if (!b) continue;
    const overL = sb.x + 16 - b.x, overR = (b.x + b.width) - (sb.x + sb.width - 16);
    if (overL > 0.5 || overR > 0.5) { /* report t.id, t.characters, overflow */ }
  }
}
```

- [ ] **Step 3: Binding audit** (read-only sweep): every fill/stroke/text style on `02 Components` references a variable; report and fix hardcoded values.
- [ ] **Step 4 — JALON 2 (Rémy):** components in both universes (mode switch demo), iterate until validated.

### Task 4: Screens (`03 Screens — Classic`, `04 Screens — Rainbow`)

- [ ] **Step 1:** Invoke `figma:figma-generate-design`. Build this exact frame matrix (light mode; dark = mode-switch spot-checks in Step 3):

| Screen | Universes | Form factors |
|---|---|---|
| Measurement — Basic IOS | Classic + Rainbow | iPhone portrait, **iPhone landscape**, iPad, Mac window |
| Measurement — Set Membership (categorical UI) | Classic + Rainbow | iPhone portrait, **iPhone landscape**, iPad, Mac window |
| Home | Classic + Rainbow | iPhone portrait, iPad |
| Settings | Classic + Rainbow | iPhone portrait |
| History (list + session detail) | Classic + Rainbow | iPhone portrait |
| Onboarding (3 pages) | Rainbow (Classic = same layout, sober tokens: 1 frame as proof) | iPhone portrait |

Measurement frame contract: stimulus centered in canonical proportions; ⓘ (info) + exit in toolbar; save button; feedback zone (value+label ON in Rainbow frames, OFF in Classic frames — both variants shown for Basic iPhone portrait); **landscape reorganizes chrome beside the stimulus, never below it, nothing cut**. Classic measurement frames contain circles + minimal chrome only.

- [ ] **Step 2: No-scroll + text-bounds audits (programmatic)** on both screen pages: the text sweep above + a bounds sweep asserting every child node lies fully inside its screen frame (no clipped/overflowing content). Fix every hit.
- [ ] **Step 3: Dark-mode spot-checks:** duplicate Basic IOS iPhone portrait (Classic + Rainbow) and switch to dark modes; fix contrast issues at the variable level (not per-frame).
- [ ] **Step 4 — JALON 3 (Rémy):** walk through the matrix, iterate until validated.

### Task 5: Review gates & wrap-up

- [ ] **Step 1:** Run `@figma-design-reviewer` on the file; fix majors, re-run until clean.
- [ ] **Step 2: Stance gate on pixels** — `@stance-reviewer` (registered since this session) on a written inventory of the file (frame list + component behaviors + all copy extracted via read-only sweep): checks V1 (no value-conditional decoration), V2 (label wording), V3 (copy direction), V4 (no gauges/uptrend icons). Fix BLOCKs.
- [ ] **Step 3:** `apple-liquid-glass` compliance pass (iOS 26 idioms: materials, toolbar treatment) — apply where it doesn't conflict with a stance; stances win conflicts (report any).
- [ ] **Step 4 — JALON 4 (Rémy): final validation of the file.**
- [ ] **Step 5:** Update spec status line (`phase 1 (Figma) completed on <date>`), note the Figma file URL in the spec §14 phase-1 row; commit:

```bash
git add docs/superpowers/specs/2026-07-28-ios-scale-v2-rebuild-design.md
git commit -m "docs(spec): mark phase 1 complete — Figma design system and screens validated

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Not in this plan

- Motion/micro-interactions specs (phase 3, with `figma:figma-implement-motion` if needed).
- Token export to Swift (phase 2 consumes the variables via `figma:figma-swiftui` / `get_design_context`).
- App Store screenshots (phase 5).
