# Phase 0 — Method & Norms Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Commit the project's normative documents (design stances, agent guide, data dictionary skeleton) and install Rémy's private enforcement tooling, so that every later phase — starting with the Figma design system — is built under an explicit, reviewable referential.

**Architecture:** Three documents committed to the repo (the "law": `docs/DESIGN-STANCES.md`, `AGENTS.md` + `CLAUDE.md` include, `docs/DATA_DICTIONARY.md` draft) + one private plugin folder on Rémy's machine (the "police": `~/.claude/skills/remy-ios-scale/` with a read-only `stance-reviewer` gate agent and an `ios-scale-conventions` skill), following the existing `~/.claude/skills/remy-polysomnia/` convention. Private tooling reads the committed documents as its single source of truth — it never duplicates rules.

**Tech Stack:** Markdown only (no code in this phase). Git. Claude Code agent/skill formats (frontmatter + body).

**Source spec:** `docs/superpowers/specs/2026-07-28-ios-scale-v2-rebuild-design.md` (§2 stances, §12 governance, §14 phase 0, §15 tooling & method).

## Global Constraints

- All documents in **English** (repo convention; conversation with Rémy stays French).
- Vocabulary: **`position`**, never "score"; continua are defined by **two neutrally described poles**; canonical units (base radius r₀ = 1).
- Normative rule of the whole project: **"Celebrate the act of measuring, never the measured value."**
- Commits: imperative, scoped (e.g. `docs(stances): …`), ending with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Xcode scheme name is exactly `IoS Scale` (verified via `xcodebuild -list`).
- Private tooling path is exactly `~/.claude/skills/remy-ios-scale/` (mirrors `remy-polysomnia`). Nothing under `.claude/` is committed to the repo.
- License: CC0 (unchanged).

---

### Task 1: `docs/DESIGN-STANCES.md`

**Files:**
- Create: `docs/DESIGN-STANCES.md`

**Interfaces:**
- Consumes: spec §2 (stance summaries).
- Produces: the normative referential that Task 4's `stance-reviewer` agent and Task 2's `AGENTS.md` reference by path `docs/DESIGN-STANCES.md`. Section anchors used later: `#stance-1-no-a-priori-valence` … `#stance-6-participant-dignity--privacy`.

- [ ] **Step 1: Write the document** with exactly this content:

````markdown
# Design Stances — IOS Scale

> Normative document. Version 1.0 (2026-07-28).
> Every stance ends with **Violations** — concrete changes that would break it.
> A pull request that contradicts a stance must propose a stance amendment
> (new version of this file), not slip the change through.

## Stance 1 — No a-priori valence

**Statement.** No state on any measurement continuum is better than another.
Being distant is as valid as being merged. The app never rewards, celebrates,
or visually privileges a region of any scale.

**Operational rule: “Celebrate the act of measuring, never the measured value.”**

**Rationale.** IOS Scale is a descriptive instrument. Any affective feedback
tied to *where* a response lies teaches participants what the “good” answer is
(demand characteristics, operant reinforcement) and contaminates the measure.
Version 1 of this app violated this stance (hearts at high proximity/similarity,
“Immersed” badges) and those elements were removed deliberately, not lost.

**Consequences.**
- No indicator, animation, color shift, haptic, badge, or copy conditioned on
  the measured value or on reaching a region of the continuum.
- Celebrations (Rainbow style) fire only on value-neutral events: a measurement
  was saved, a session was completed. Governed by the `celebrations` toggle
  (preset: on in Rainbow, off in Classic).
- Sliders render symmetrically: uniform track, plain handle — no filling gauge
  toward a pole.
- Verbal labels describe the stimulus (see Stance 4), with no crescendo of
  intensity or richness toward one pole.
- History and stats use “position”, distributions, and ranges — never “score”,
  progress, or improvement language.

**Violations.** Adding `if position > x { reward }` in any form; a confetti
burst at “merged”; a label ladder ending in an emotional climax; a chart whose
upward direction is framed as better; release notes praising “higher closeness”.

## Stance 2 — The datum is the configuration the participant showed

**Statement.** The stored measurement is the geometry the participant produced,
in canonical instrument units, plus a `position` coordinate. Scalar composites
and literature-comparable indices are the analyst’s business, computed offline.

**Rationale.** Storing only a derived number destroys re-analysis (v1 stored a
slider fraction that corresponded to no defined quantity). Storing raw geometry
makes every convention recomputable and every future re-scoring possible.

**Consequences.**
- Every degree of freedom offered to the participant is recorded as-is
  (e.g. Advanced IOS records `d`, `r_self`, `r_other` — radii are response
  variables, never context).
- `position` ∈ [0,1] is a *coordinate* on a continuum defined by two neutrally
  described poles; it is never called, displayed, or documented as a score.
- Domain constraints live in the manipulandum’s geometry. Out-of-domain values
  are loud errors — never silent clamps (v1’s Set Membership 0–3-clamped-to-1
  corruption is the cautionary tale).
- Set Membership stores an explicit category (`neither/selfOnly/otherOnly/both`);
  no continuous score is fabricated from it.
- Derivable formulas (overlap proportion, distance norms…) are documented in
  `docs/DATA_DICTIONARY.md`, not baked into the app.

**Violations.** Persisting a derived value without its geometry; adding a
composite “closeness index” column to exports; clamping instead of erroring;
renaming `position` to anything magnitude-flavored.

## Stance 3 — What the participant sees is a covariate

**Statement.** Any toggleable feedback (numeric value, verbal labels,
celebrations) and any rendering circumstance that could shape a response is
recorded in each measurement’s context.

**Rationale.** A response given while watching a live numeric readout is not
the same measurement as one given without it. If display conditions are not in
the data, they are confounds in the researcher’s memory.

**Consequences.** Each measurement records: active style, the three feedback
toggles, language, start value + reset behavior, measurement duration, device
model, orientation, window size, points-per-unit, `app_version`,
`schema_version`, `instrument_version`.

**Violations.** Adding a visible feedback element without adding it to the
measurement context; changing a default (e.g. reset behavior) without a
schema/dictionary update.

## Stance 4 — Descriptive, not normative

**Statement.** Labels describe the stimulus (geometry), not the relationship.
Instructions (consignes) describe the manipulation and the judgment asked —
never a desirable outcome.

**Rationale.** The app’s frame is the descriptive/phenomenological tradition
(Ollagnier-Beldame & Coupé 2019; Coupé & Ollagnier-Beldame 2022). It departs
consciously from the self-expansion framing (Aron & Aron 1986) whose valence
had leaked into v1. Words like “connected” at one pole and deficit phrasing
(“minimal connection”) at the other impose an interpretation.

**Consequences.**
- State labels name geometry: e.g. “Separated / Touching / Partial overlap /
  Concentric”.
- Long experiential descriptions are either removed or symmetric in richness
  and affective load across poles.
- Accessibility copy names the gesture and the stimulus (“change the circles’
  position”), not the construct (“adjust closeness”).
- Each modality ships a `ModalityDocumentation` (what it measures, how, and a
  suggested instruction) — the instruction never hints at a preferred region.

**Violations.** A consigne like “bring the circles together to show how close
you feel” (directional); reintroducing “Merged” as a label climax; an a11y hint
that names closeness as the thing being adjusted.

## Stance 5 — Rendering conventions are explicit per instrument version

**Statement.** Fixed-diameter circles; full separated→concentric manipulable
domain; geometry constants (e.g. `D_max`) are per-modality constants versioned
under `instrument_version`. No comparability claim with other IOS
implementations without offline recomputation from stored geometry.

**Rationale.** Constant-total-area rendering (Aron’s feature) is theoretically
motivated but empirically untested, violated by the canonical instrument
itself, and poor interaction design. We choose fixed diameters — and we say so,
because honest comparability requires knowing the stimulus.

**Consequences.**
- The instrument lives in canonical space (r₀ = 1); the screen only applies a
  uniform scale. Same instrument on every device, orientation, and window.
- Changing any geometry constant or modality documentation bumps
  `instrument_version`; positions are only comparable at equal version.
- The rendering convention is stated in `docs/DATA_DICTIONARY.md`.

**Violations.** Making `D_max` depend on screen size; cropping the domain in a
small window instead of scaling; silently changing a constant without a version
bump.

## Stance 6 — Participant dignity & privacy

**Statement.** Anonymous participant codes, no accounts, no tracking. iCloud
sync is optional and defaults to OFF; local-only operation is a first-class
mode. Data deletion is real (local and CloudKit).

**Rationale.** This is a research instrument that will hold participants’
responses. The researcher owns the correspondence table; the app never holds
identity. v1’s mandatory Sign in with Apple served no function and was rejected
by App Review (Guideline 5.1.1) — the account concept is removed, not fixed.

**Consequences.** Participant codes are free-form, in-memory, reset at launch;
device identity is a device label, not a person; PIN gates data zones
(Settings, History, Export), not measurement; “Clear All Data” actually deletes
everything, verified by tests.

**Violations.** Reintroducing any account or persistent user identifier;
sync default ON; analytics/telemetry of any kind; a deletion flow that leaves
CloudKit records behind.

## Amendment process

Stances change by amending this file (new version number, dated changelog
entry, rationale for the change) in a dedicated commit — never as a side effect
of a feature PR.
````

- [ ] **Step 2: Verify against spec §2** — checklist: 6 stances present; each has Statement/Rationale/Consequences/Violations; the operational rule sentence appears verbatim in Stance 1; amendment process section present.

Run: `grep -c "^## Stance" docs/DESIGN-STANCES.md`
Expected: `6`

- [ ] **Step 3: Commit**

```bash
git add docs/DESIGN-STANCES.md
git commit -m "docs(stances): add DESIGN-STANCES.md v1.0 — the project's normative referential

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: `AGENTS.md` + `CLAUDE.md` include + Copilot pointer

**Files:**
- Create: `AGENTS.md` (repo root)
- Create: `CLAUDE.md` (repo root)
- Modify: `.github/copilot-instructions.md` (replace content with a pointer)

**Interfaces:**
- Consumes: `docs/DESIGN-STANCES.md` (Task 1), scheme name `IoS Scale`.
- Produces: `AGENTS.md` — referenced by Task 4's agent and by every future phase plan. `CLAUDE.md` contains exactly one include line.

- [ ] **Step 1: Write `AGENTS.md`** with exactly this content:

````markdown
# AGENTS.md — IOS Scale

Guide for anyone (human or AI) modifying this repository.

## What this is

An iOS/iPadOS research instrument measuring intersubjective experience with 9
continuous circle-based modalities. Two visual universes (Classic: sober
research instrument; Rainbow: playful) over one shared measurement engine.
Currently mid-rebuild (v2): see
`docs/superpowers/specs/2026-07-28-ios-scale-v2-rebuild-design.md`.

## Read before touching anything

| If you touch… | Read first |
|---|---|
| Anything user-visible, labels, feedback, animations | `docs/DESIGN-STANCES.md` (**normative, prevails over everything**) |
| Measurement encoding, models, export | `docs/DATA_DICTIONARY.md` + stances 2, 3, 5 |
| Architecture, phases, scope | `docs/superpowers/specs/2026-07-28-ios-scale-v2-rebuild-design.md` |

Conflict hierarchy: `DESIGN-STANCES.md` > `DATA_DICTIONARY.md` > spec > README.
If you detect a conflict, report it — do not arbitrate silently.

## Commands

```bash
# Build (scheme name contains a space — keep the quotes)
xcodebuild -project "IoS Scale.xcodeproj" -scheme "IoS Scale" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Tests (test target lands in phase 2 of the rebuild; command is stable)
xcodebuild -project "IoS Scale.xcodeproj" -scheme "IoS Scale" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Hard invariants

1. **Never condition any feedback (visual, haptic, verbal) on the measured
   value.** “Celebrate the act of measuring, never the measured value.”
2. **Never persist a derived value without its canonical geometry.** `position`
   is a coordinate, not a score; out-of-domain = loud error, never a clamp.
3. **Never change export columns or payload fields without bumping
   `schema_version` and updating `docs/DATA_DICTIONARY.md`** in the same PR.
4. **Never change a geometry constant or modality documentation without
   bumping `instrument_version`.**
5. **Every user-visible string goes through localization (EN + FR).** No
   hardcoded display strings.
6. **A new modality is a `ModalityConfig` + tests — never a forked view or
   view model.**
7. **No accounts, no tracking, no analytics. Sync stays optional,
   default OFF.**

A PR that needs to break an invariant must first amend `DESIGN-STANCES.md`
(see its amendment process).

## Conventions

- Swift 6 strict concurrency; SwiftUI; SwiftData (+ optional CloudKit).
- Code, comments, commits, identifiers: English. Commits: imperative, scoped
  (`feat(engine): …`, `docs(stances): …`).
- License: CC0. Different people, different methods: this file documents the
  project's law, not anyone's personal tooling.
````

- [ ] **Step 2: Write `CLAUDE.md`** with exactly this content:

```markdown
@AGENTS.md
```

- [ ] **Step 3: Replace `.github/copilot-instructions.md` content** with exactly:

```markdown
See [AGENTS.md](../AGENTS.md) — the single guide for AI-assisted changes to
this repository.
```

- [ ] **Step 4: Verify the build command in `AGENTS.md` is real**

Run: `xcodebuild -project "IoS Scale.xcodeproj" -scheme "IoS Scale" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -1`
Expected: `** BUILD SUCCEEDED **` (v1 code still builds; if the named simulator is absent, substitute any installed iPhone simulator and update AGENTS.md accordingly — the command must be copy-pasteable as committed).

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md CLAUDE.md .github/copilot-instructions.md
git commit -m "docs(agents): add AGENTS.md with hard invariants; CLAUDE.md includes it

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: `docs/DATA_DICTIONARY.md` (draft skeleton)

**Files:**
- Create: `docs/DATA_DICTIONARY.md`

**Interfaces:**
- Consumes: spec §4 (encoding), §8 (export); stances 2, 3, 5.
- Produces: the contract document that phase 2 implements and that invariant 3 of `AGENTS.md` points to. Field names defined here are binding for phase 2: `position`, `response`, `context`, `schema_version`, `instrument_version`, `center_distance_norm`.

- [ ] **Step 1: Write the document** with exactly this content:

````markdown
# Data Dictionary — IOS Scale

> **Status: DRAFT** — schema_version target: `2` (first shipping version of the
> v2 rebuild). This document is the single source of truth for what the app
> records and exports. Any change to it requires a `schema_version` or
> `instrument_version` bump (see AGENTS.md invariants 3–4).

## Measurement record

Every measurement has three parts:

| Part | Content |
|---|---|
| `response` | The configuration the participant produced, in canonical units (base circle radius r₀ = 1). Typed per modality (below). |
| `position` | A coordinate in [0,1] on the modality's continuum, defined by two neutrally described poles. A coordinate — never a score. |
| `context` | Passation conditions: `style` (classic/rainbow), `shows_value`, `shows_labels`, `celebrations`, `language`, `start_value`, `reset_behavior`, `duration_ms`, `device_model`, `orientation`, `window_width_pt`, `window_height_pt`, `points_per_unit`, `app_version`, `schema_version`, `instrument_version`. |

Rendering convention (stance 5): fixed-diameter circles; uniform scaling to the
window; manipulable domain = full separation → concentric; per-modality
constants (`D_max`, …) versioned under `instrument_version`.

## Per-modality response payloads (canonical units)

| Modality | Payload fields | Poles of `position` (0 ↔ 1) |
|---|---|---|
| `basic_ios` | `d` (center distance), `r` (= 1) | fully separated ↔ concentric |
| `advanced_ios` | `d`, `r_self` (0.2–2.0), `r_other` (0.2–2.0) | fully separated ↔ concentric (distance axis only; radii are co-equal response variables, not folded into `position`) |
| `overlap` | `d`, `r` (= 1) | fully separated ↔ concentric |
| `set_membership` | `state` ∈ {`neither`,`self_only`,`other_only`,`both`} + `self_position`, `other_position` | — (categorical; no `position`) |
| `proximity` | `self_position`, `other_position` on the axis | maximal separation ↔ contact |
| `identification` | geometry + direction (finalized in phase 2 from v1 geometry) | pole descriptions finalized with phase 2, neutrally worded |
| `projection` | geometry + direction (finalized in phase 2) | idem |
| `attribution` | geometry (finalized in phase 2) | idem |
| `observation` | geometry (finalized in phase 2) | idem |

> The four “finalized in phase 2” rows are drafts by design: their v1
> geometries must be transposed to canonical space before their payloads are
> frozen. Freezing them is a phase 2 deliverable; this table is updated and
> `schema_version` finalized there.

## Derived quantities (computed offline — never stored by the app)

- `center_distance_norm = d / (r_self + r_other)` — 1 at tangency, 0 at
  concentric, > 1 when separated. Defined on the whole domain, monotone.
- `overlap_proportion` — proportion of circle overlap; 0 whenever separated
  (honest censoring). For equal circles of radius r at distance d < 2r:
  `A(d) = 2r² · cos⁻¹(d/2r) − (d/2) · √(4r² − d²)`; proportion = A / (πr²).
  For unequal circles, use the standard circular-lens formula; the reference
  denominator (smaller circle vs union) is the analyst's explicit choice.
- 7-point conversions or any literature-comparability index: analyst-side,
  from stored geometry, with the reminder that this app's stimulus is
  fixed-diameter (stance 5).

## Export formats

- **JSON**: full fidelity — nested `response`/`context`, versions, session
  metadata (participant code, device name/custom id, notes, timestamps).
- **CSV/TSV**: tidy long format (one row per measurement), fixed snake_case
  column superset (columns empty when N/A), deterministic order (session
  `created_at`, then measurement `timestamp`), RFC 4180 escaping, decimal
  point always. Excludes trashed sessions.
- Filename: `ios-scale_{participant|all}_{yyyy-MM-dd_HHmmss}.{ext}`.

The exact CSV column list is frozen in phase 2 together with the payloads;
it will enumerate: session fields, measurement identity fields, per-modality
payload columns, and every `context` field listed above.

## Changelog

- 2026-07-28 — draft created (phase 0). Targets `schema_version 2`,
  `instrument_version 1`.
````

- [ ] **Step 2: Verify internal consistency** — checklist: every field named in the `context` row also appears in stance 3's consequences (cross-check against `docs/DESIGN-STANCES.md`); formula for `center_distance_norm` matches spec §4; `set_membership` has no `position`.

Run: `grep -c "instrument_version" docs/DATA_DICTIONARY.md`
Expected: `≥ 3`

- [ ] **Step 3: Commit**

```bash
git add docs/DATA_DICTIONARY.md
git commit -m "docs(data): add DATA_DICTIONARY.md draft — measurement record, payloads, export contract

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Private tooling — `~/.claude/skills/remy-ios-scale/`

**Files (outside the repo — NOT committed):**
- Create: `~/.claude/skills/remy-ios-scale/README.md`
- Create: `~/.claude/skills/remy-ios-scale/agents/stance-reviewer.md`
- Create: `~/.claude/skills/remy-ios-scale/skills/ios-scale-conventions/SKILL.md`

**Interfaces:**
- Consumes: the three committed documents (Tasks 1–3) — read at review time from the repo, never copied.
- Produces: agent invocable as `@stance-reviewer` (namespaced `remy-ios-scale:stance-reviewer`); skill `remy-ios-scale:ios-scale-conventions`.

- [ ] **Step 1: Write `README.md`** with exactly this content:

```markdown
# remy-ios-scale — private tooling for the IOS Scale project

Personal enforcement layer ("the police") for the norms committed in the
IOS Scale repo ("the law"): DESIGN-STANCES.md, DATA_DICTIONARY.md, AGENTS.md.
Not shared, not required by contributors — different people, different methods.
```

- [ ] **Step 2: Write `agents/stance-reviewer.md`** with exactly this content:

````markdown
---
name: stance-reviewer
description: MANDATORY gate for the IOS Scale project (~/Workspace/Apps/IoS Scale) — invoke with @stance-reviewer on any feature that changes something user-visible (views, labels, feedback, animations, copy) or the data layer (models, export), BEFORE the feature is considered done. Read-only; returns violations with severity, never modifies code.
tools: Read, Glob, Grep
---

You are the stance gate for the IOS Scale project at
`/Users/remyramadour/Workspace/Apps/IoS Scale`.

## Procedure

1. Read `docs/DESIGN-STANCES.md`, `docs/DATA_DICTIONARY.md`, and `AGENTS.md`
   from the repo — they are the referential; you enforce THEM, current version,
   not your memory of them.
2. Review the files/diff you were pointed at.
3. Report findings and nothing else. Never edit files.

## What you check (violation taxonomy)

- **V1 value-conditional feedback** (stance 1): any indicator, animation,
  haptic, badge, color, or copy conditioned on the measured value or a region
  of a continuum. Includes subtle forms: asymmetric glow, thresholds in view
  code (`if position > …`), celebration triggers other than save/session-end.
- **V2 valenced language** (stances 1, 4): label ladders with intensity
  crescendos; deficit phrasing at one pole; experiential descriptions richer at
  one pole; "score"/progress/improvement language anywhere user-visible or in
  code identifiers.
- **V3 directional copy** (stance 4): instructions, hints, or a11y strings
  naming the construct as the thing manipulated ("adjust closeness") or hinting
  at a preferred region.
- **V4 accumulation metaphors** (stance 1): filling gauges, uptrend icons,
  progress framing of positions.
- **V5 data-contract breach** (stances 2, 3, 5; AGENTS invariants 2–4):
  derived values persisted without geometry; silent clamps; export/payload
  changes without schema_version bump + DATA_DICTIONARY update; geometry
  constants changed without instrument_version bump; feedback element added
  without a matching context field.
- **V6 localization gap** (AGENTS invariant 5): user-visible hardcoded strings.
- **V7 consigne bias** (stance 4): ModalityDocumentation instructions that
  suggest a desirable outcome.

## Output format

For each finding: `SEVERITY — file:line — stance/invariant ref — one-sentence
description — concrete fix suggestion.`
Severities: **BLOCK** (violates a stance/invariant), **WARN** (borderline,
needs a human call), **NOTE** (improvement).
End with a verdict line: `GATE: PASS` (no BLOCK) or `GATE: FAIL (n BLOCK)`.
If the referential documents conflict with each other, report it as a finding
and do not arbitrate.
````

- [ ] **Step 3: Write `skills/ios-scale-conventions/SKILL.md`** with exactly this content:

````markdown
---
name: ios-scale-conventions
description: Auto-load when editing measurement views, ModalityConfigs, models, labels, feedback, or export code in the IOS Scale project (~/Workspace/Apps/IoS Scale). Digest of the project's committed norms — vocabulary, canonical encoding, export rules.
---

# IOS Scale conventions (digest — the repo documents prevail)

Source of truth: `docs/DESIGN-STANCES.md`, `docs/DATA_DICTIONARY.md`,
`AGENTS.md` in the project repo. If this digest disagrees with them, they win.

## Vocabulary
- `position`, never "score". Continua have two neutrally described poles.
- Labels describe the stimulus (geometry): "Separated / Touching / Partial
  overlap / Concentric" — never relationship quality, never a crescendo.

## The one sentence
**Celebrate the act of measuring, never the measured value.** No feedback of
any kind conditioned on the measured value. Celebrations only on save/session
end, only via the `celebrations` toggle.

## Encoding
- Canonical units: base radius r₀ = 1; per-modality constants (`D_max`) are
  instrument constants (never screen-derived), versioned by
  `instrument_version`.
- Store the full response (every participant-controlled degree of freedom,
  e.g. Advanced IOS: `d`, `r_self`, `r_other`) + `position` + `context`
  (style, 3 feedback toggles, language, start_value, reset_behavior,
  duration_ms, device/orientation/window/points_per_unit, versions).
- Out-of-domain = loud error. Never clamp. Set Membership is categorical.

## Export
- Any change to columns/payloads = `schema_version` bump + DATA_DICTIONARY
  update in the same PR. CSV: snake_case superset, deterministic order,
  RFC 4180, decimal point, excludes trash.

## Strings
- Every user-visible string is localized (EN + FR), including
  ModalityDocumentation and consignes.
````

- [ ] **Step 4: Functional test of the gate** — create a seeded-violation file OUTSIDE the repo at exactly `~/.claude/skills/remy-ios-scale/gate-selftest.swift` (kept next to the tooling so the test is re-runnable after edits) containing:

```swift
// Seeded violations for gate testing
var scoreLabel = "Score: \(value)"                    // V2: "score"
if position > 0.9 { showHeartAnimation() }            // V1: value-conditional
Text("Bring the circles together to show closeness")  // V3: directional copy
```

Invoke `@stance-reviewer` on that file. Expected: `GATE: FAIL` with ≥ 3 BLOCK findings mapping to V1, V2, V3. If the agent is not found, restart the Claude Code session (new agents are discovered at session start) and retry.

- [ ] **Step 5: No commit** (private tooling lives outside the repo). Keep `gate-selftest.swift` in place — it documents the expected failure modes and lets the gate be re-validated after any edit to the referential documents.

---

### Task 5: Phase-0 gate and wrap-up

**Files:**
- Modify: `docs/superpowers/specs/2026-07-28-ios-scale-v2-rebuild-design.md` (status header)

**Interfaces:**
- Consumes: everything above.
- Produces: phase 0 declared done; phase 1 (Figma) unblocked.

- [ ] **Step 1: Run the gate on the committed documents themselves** — invoke `@stance-reviewer` on `docs/DESIGN-STANCES.md`, `docs/DATA_DICTIONARY.md`, `AGENTS.md` (consistency pass: no contradictions between the three, no valenced language that slipped into examples outside quoted violation illustrations). Expected: `GATE: PASS`. Fix any BLOCK finding and re-run before proceeding.

- [ ] **Step 2: Update the spec status header** — change the `> **Status:**` line to:

```markdown
> **Status:** validated 2026-07-28 · phase 0 (method & norms) completed on <date>
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-07-28-ios-scale-v2-rebuild-design.md
git commit -m "docs(spec): mark phase 0 complete — norms committed, private gate installed

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Not in this plan

- **Phase 1 (Figma)** gets its own plan once phase 0 is done — the Figma work
  must be reviewed against the *committed* stances, and its plan will follow
  the figma-generate-library / figma-generate-design workflow skills.
- **Phases 2–5** get their plans when their dependencies exist (design tokens
  from Figma for phase 2's Theme; frozen payloads for the export column list).
- The global `remy-ios-method` plugin (distillation) is a phase 5 deliverable.
