# IOS Scale v2 — Rebuild Design

> **Status:** validated section by section with Rémy on 2026-07-28 · phase 0 (method & norms) completed on 2026-07-28
> **Scope:** full rebuild of the app (engine-first, in-repo), v2.0 App Store resubmission
> **Coexists with:** `IoSScaale` (the frozen discrete-scale study app) — the two apps live in parallel; v2 borrows its research patterns but does NOT include a discrete scale

## 1. Context & Goals

IOS Scale measures intersubjective experience with 9 continuous circle-based modalities
(Basic IOS, Advanced IOS, Overlap, Set Membership, Proximity, Identification, Projection,
Attribution, Observation). v1 was rejected by App Review (Guideline 5.1.1: mandatory
Sign in with Apple; 5.1.1(v): no account deletion) and a full audit found critical
data-integrity defects (Set Membership clamp corruption, divergent save semantics,
lossy exports, fake "Clear All Data", cosmetic sync toggle, zero tests).

v2 goals:

1. **Two universes, one app.** *Rainbow* — the playful pastel experience. *Classic* —
   a sober, near-monochrome, methodologically neutral research instrument that
   colleagues can put in participants' hands (they currently use the discrete 7-item
   scale and want a continuous measure; bias/suggestion control is the driving concern).
2. **Scientifically sound data.** Canonical geometry as ground truth, valence-free
   encoding, contractual exports, tests on everything that makes this an instrument.
3. **Research workflow.** Participant codes, researcher PIN, device identity,
   FR/EN localization — patterns transposed from `IoSScaale`.
4. **Clean App Store resubmission** (one shot, v2.0): no account at all, real data
   deletion, honest sync.
5. **Open-source governance**: the repo will be public; design stances and agent-facing
   guidance are first-class deliverables.

Decisions locked with Rémy: coexistence with `IoSScaale` (no absorption, no discrete
scale); iPads run iOS 26 → target iOS 26.x; single resubmission with v2 (no quick-fix
v1.0.1 — publishing v1 would freeze the flawed schema); approach A (engine-first
rebuild in the current repo, app always buildable).

## 2. Design Stances (normative core)

These become `docs/DESIGN-STANCES.md` (English), each with rationale and
"what would count as a violation". Summarized here:

1. **No a-priori valence.** No state on any continuum is better than another. Being
   distant is as valid as being merged. The app never rewards, celebrates, or
   visually privileges a region of any scale.
   **Operational rule: "Celebrate the act of measuring, never the measured value."**
   Consequences: no value-conditional indicators (hearts/sparkles/glows at poles are
   removed, not redistributed); celebrations fire only on value-neutral events
   (measurement saved, session completed), governed by the `celebrations` toggle
   (preset: on in Rainbow, off in Classic); symmetric slider
   rendering (no filling gauge toward a pole); stats speak of "position", never "score".
2. **The datum is the configuration the participant showed.** Geometry in canonical
   units is ground truth; `position` is a coordinate, not a magnitude; every degree of
   freedom offered to the participant is recorded as-is; scalar composites are the
   analyst's business (formulas documented, never baked in).
3. **What the participant sees is a covariate.** Any feedback that can be toggled
   (numeric value, verbal labels, celebrations) is recorded in each measurement's
   context. Changing what is shown changes the measurement conditions.
4. **Descriptive, not normative.** Labels describe the stimulus (geometry), not the
   relationship. Instructions (consignes) describe the manipulation and the judgment
   asked — never a desirable outcome. Grounding: the app's frame is the descriptive/
   phenomenological tradition (Ollagnier-Beldame & Coupé), consciously departing from
   the self-expansion framing (Aron) whose valence had leaked into v1 (acknowledged
   as such).
5. **Rendering conventions are explicit and non-negotiable per instrument version.**
   Fixed-diameter circles (constant-area rendering rejected: theoretically motivated
   but empirically untested, violated by the canonical instrument itself, and bad UX);
   full separated→concentric domain; no comparability claim with other implementations
   without offline recomputation from stored geometry.
6. **Participant dignity & privacy.** Anonymous participant codes, no accounts, no
   tracking, optional local-only storage (sync default OFF).

## 3. Theming & Behavior System

Two orthogonal axes, two distinct objects:

- **`Theme` (appearance).** Resolved from `(style, colorScheme)`:
  `.classic`/`.rainbow` × light/dark = 4 token sets. Injected via SwiftUI Environment;
  views consume tokens only — no direct `ColorPalette` statics anywhere. Carries:
  Self/Other circle colors (Rainbow: current blue/magenta gradients; Classic: two
  grays differentiated by value + stroke, distinguishable without color), background
  (pastel 4-stop gradient vs neutral flat), card materials, button styles, typography
  accents (`.rounded` in Rainbow, neutral system in Classic). Spacing grid and base
  typography are shared across both universes so layouts never diverge.
- **`FeedbackOptions` (behavior).** Three independent persisted toggles:
  `showsValue`, `showsLabels`, `celebrations`. Picking a style applies a preset
  (Rainbow → all on; Classic → all off), each toggle individually adjustable after.
  A `CelebrationLayer` listens to value-neutral events only; renders nothing when
  disabled. Zero `if style ==` in measurement views.

Settings surface: Style picker, Appearance (Light/Dark/System), "Measurement feedback"
group with the three toggles + "reset to style defaults".

## 4. Measurement Encoding

### Canonical instrument space

The instrument is defined in a device-independent canonical space, per modality:
base circle radius r₀ = 1 unit; manipulable center distance `d ∈ [0, D_max]` where
**`D_max` is a constant of the modality** (part of `ModalityConfig`), not a consequence
of available screen space. Rendering applies a **uniform scale** (points-per-unit) to
fit any screen/orientation/window — same instrument everywhere, only bigger or smaller
(A4 vs A5 print). Below a legibility floor, scale down uniformly; never crop the domain,
never change proportions. Rotation mid-measurement is safe by construction (state lives
in canonical space).

For Advanced IOS (radii are participant-controlled, 0.2–2.0): `D_max` is chosen for the
worst case (e.g. 5.0 ≥ max r_self + r_other = 4.0) so full separation is always
achievable. Consequence (assumed, geometrically honest): the tangency point falls at
different `position` values depending on radii; the stored vector disambiguates.

### What is stored per measurement

1. **Response** — typed, versioned Codable payload, all in canonical units. The radii
   in Advanced IOS are *response variables* (participant-controlled), never context:

   ```json
   "response": { "d": 1.83, "r_self": 1.40, "r_other": 0.60 }
   ```

   Per modality: Basic/Overlap `(d, r)` with r constant at 1 (homogeneous payload);
   Advanced `(d, r_self, r_other)`; Proximity: both positions on its axis;
   Identification/Projection: geometry + direction; Attribution/Observation: their own
   geometry; **Set Membership: explicit enum** `.neither/.selfOnly/.otherOnly/.both`
   (+ positions) — the category IS the datum, no forced continuous score (kills the
   0–3-clamped-to-1 corruption).
2. **`position` ∈ [0,1]** — a *coordinate* on the modality's continuum, defined by two
   **neutrally described poles** (e.g. Basic IOS: "circles fully separated" ↔
   "circles concentric"). One derived value only; covers a single axis (for Advanced,
   the distance axis — no arbitrary 3D→1D composite).
3. **Context** — active style, the three feedback toggles, language, start value +
   reset behavior (initial-position anchoring is a documented bias), measurement
   duration, rendering context (device model, orientation, window size in points,
   points-per-unit), `app_version`, `schema_version`, `instrument_version`.

`instrument_version` covers geometry constants (D_max…) and modality documentation
text; positions are only comparable at equal instrument version.

Nothing else is baked in: overlap proportion, 7-point conversions, familiarization
sweeps, restricted-domain protocol options — all dropped. Everything is recomputable
offline from stored geometry; `DATA_DICTIONARY.md` provides the formulas.

### Validation lives in geometry

Domain constraints are enforced by the manipulandum (an overlap cannot exceed its
geometric maximum); out-of-domain values are loud errors, never silent clamps.

## 5. De-valencing Inventory (from the v1 analysis)

Mechanisms found in v1 and their replacements:

| # | Mechanism | v1 instances | Replacement |
|---|---|---|---|
| 1 | Value-conditional affective rewards | gold heart+halo at proximity ≥ 0.95 (`ProximityCirclesView:144`); pink/red heart at similarity > 0.8 (`AttributionCirclesView:190`); sparkles + "Immersed" + glowing border at participation > 0.85 (`ObservationCirclesView:234`) | **Removed entirely** (not redistributed). Celebrations: save-time only, Rainbow only |
| 2 | Crescendo label ladders, asymmetric experiential descriptions | "Distant→…→Merged"; "Far apart, minimal connection" vs "Feeling connected" (Proximity); "Slightly→Strongly Identified" | Labels **describe the stimulus**: e.g. "Separated / Touching / Partial overlap / Concentric". Long experiential descriptions removed or symmetric in richness |
| 3 | Directional micro-copy | a11y hint "drag to adjust closeness"; "Self absorbs qualities of Other" | Name the gesture and the stimulus ("change the circles' position"), not the construct |
| 4 | Accumulation metaphors | slider track filling toward fusion; `chart.line.uptrend` icon; "average value" stats | Symmetric slider (uniform track, plain handle); neutral stats ("mean position", distributions); neutral icons |
| 5 | Converging welcome narrative | onboarding circles animate one-shot toward each other; App Store copy "capturing closeness" | Onboarding animation **oscillates across the full range**; store copy reframed as "position on a descriptive continuum" |
| 6 | Code/data naming | `overlapValue`, `primaryValue`, "Merged" state names | `position`, pole-documented continua (covered by §4) |

## 6. Measurement Engine & Session Semantics

- **One engine, nine configs.** `MeasurementSession` (`@Observable @MainActor`) owns
  session lifecycle, save, reset, exit flow, feedback state. `ModalityConfig` declares:
  identity (name, description, poles), geometry→position pure function, typed payload
  builder, reset defaults, D_max and instrument constants, `ModalityDocumentation`.
  Visualization views stay modality-specific but obey a minimal contract: render a
  canonical geometry state, emit changes — zero business logic.
- **Adaptive exit sheet** (validated): engine tracks `hasUnsavedChanges`
  (position moved since last save/reset). Unsaved changes → *Save & exit / Discard &
  exit / Cancel*; nothing unsaved → *End session / Cancel*. Kills both v1 defects
  (gen-B silent data loss; gen-A duplicate measurement). Cancel closes the sheet by
  construction (presentation state lives in the engine, reset in one place).
- **Lazy sessions.** `SessionModel` inserted at first successful save — no more empty
  orphan sessions synced to CloudKit. Participant/device context stamped at creation.
  Every save is a real `context.save()`.
- **Loud errors.** `os.Logger` per subsystem (no `print`); failed save = error haptic +
  alert with retry + log. A silently lost data point is impossible by construction.
- **Concurrency.** Engine on MainActor; export CPU work off the main thread;
  Swift 6 language mode with strict concurrency (v1 compiled in Swift 5 mode).

## 7. Research Flow

- **Participant context** (from `IoSScaale`): in-memory, reset on every launch
  (yesterday's code must never leak onto today's data). Sessions are "guest" by
  default. Toolbar affordance on Home opens a *Session context* sheet: participant
  code + custom device name; active code shown as a chip, stamped on new sessions.
- **Researcher PIN** (optional, 4 digits, Keychain): gates the **data zones** —
  Settings, History/Trash, Export — not measurement. A participant holding the iPad
  can measure, not browse or re-configure. (Deliberate difference from `IoSScaale`
  where the PIN protects saves.)
- **Device identity**: auto `deviceName` + user-set `deviceCustomId`
  (e.g. "iPad-Labo-2") per session.

## 8. Data Model, Sync, Export

- **SwiftData v2 models** (CloudKit-compatible: defaults on all attributes, optional
  relationships): `SessionModel` (id, createdAt, participantCode, deviceName,
  deviceCustomId, notes, deletedAt soft-delete) + `MeasurementModel` (id, timestamp,
  modality, position, payloadData, context fields, versions). Property names avoid
  shadowing `PersistentModel` members (`isInTrash`, not `isDeleted`). Measurements
  sorted by timestamp everywhere (SwiftData relationships are unordered).
- **Honest sync toggle** (validated): container recreated with
  `cloudKitDatabase: .automatic/.none` when toggled; **default OFF** until an explicit
  choice — research contexts may require local-only participant data.
- **Real "Clear All Data"**: deletes local store content AND CloudKit-synced records;
  confirmation flow; verified in tests.
- **Export** (CSV/TSV/JSON): JSON = full fidelity (nested payloads, context, versions);
  CSV/TSV = tidy long format, fixed snake_case column superset (empty when N/A),
  deterministic ordering (session createdAt, then measurement timestamp), RFC 4180
  escaping, decimal point always (the dead "decimal separator" setting is removed).
  Excludes trash. Filename `ios-scale_{participant|all}_{date}.{ext}`. Option to
  attach `DATA_DICTIONARY.md`. Export runs off the main thread.

## 9. Screens & Navigation

1. **Onboarding** — rewritten: 3 informational pages + "Get Started"; **no Sign in
   with Apple anywhere** (resolves both 5.1.1 findings: no account exists at all);
   welcome animation oscillates across the full range.
2. **Home** — grid of 9 modality cards (symmetric preview animations, timers
   invalidated), participant chip, History/Settings access.
3. **Generic measurement screen** (instantiated 9×) — canonical visualization,
   toggle-conditional feedback, ⓘ → modality info sheet, adaptive exit sheet.
4. **Modality info sheet** — from `ModalityDocumentation` (FR/EN, versioned):
   what it measures, how it measures, suggested instruction (consigne). Same content
   feeds `DATA_DICTIONARY.md` (single source of truth).
5. **History** — sessions (participant, device, modality), detail, trash;
   "position" language, distribution stats.
6. **Export sheet** — as §8.
7. **Settings** — Style · Appearance · Measurement feedback · Language (FR/EN) ·
   Session context · PIN · iCloud sync · Data (real Clear All Data) · About
   (stances, licences, references).
8. **PIN entry** (sheet).

**Removed:** SIWA (service + both duplicate button wrappers), `LockScreenView` +
`.locked` state + `lockApp()` vestiges, `AppRouter`, `Settings.bundle`,
decimal-separator setting, Catalyst (native macOS destination instead — see
Platforms below), push entitlement, the dead value-type `Session`/`Measurement`
layer, `AppSettings`.

### Platforms & display constraint (added 2026-07-28, validated with Rémy)

- **Destinations:** iPhone, iPad, **macOS native (SwiftUI destination — no
  Catalyst, Apple Silicon only)**, and **Apple Vision Pro via Designed-for-iPad
  compatibility** (device family 1,2 + vision compatibility). A native visionOS
  destination is a possible post-v2 milestone; the compatibility mode is the
  supported path for v2.
- **Distribution:** one app record (universal purchase). The iOS/iPadOS binary
  serves iPhone, iPad, and Vision Pro (compatibility); macOS ships as its own
  platform build. TestFlight on all four.
- **No-scroll constraint: measurement screens never scroll.** On every device
  and orientation — iPhone portrait AND landscape included — the full stimulus
  and its controls fit one viewport: canonical-space visualization uniformly
  scaled, compact chrome that reorganizes in landscape (controls beside the
  stimulus, not below it). This replaces v1's ScrollView approach (sprints
  18-19). Mac and visionOS windows enforce a minimum size; `points_per_unit`
  in the measurement context already records the resulting stimulus scale as
  a covariate.

## 10. Localization

FR/EN via String Catalogs from day one; all user-visible strings localized, including
modality documentation and consignes. French uses inclusive forms where applicable
(cf. `IoSScaale`'s "connecté·e") — subject to the stimulus-descriptive labeling rule.

## 11. Quality

- **Unit tests** (the priority — this is what makes it an instrument): geometry→position
  functions per modality (golden values + monotonicity/domain properties), payload
  round-trips across versions, engine state machine (save/exit/hasUnsavedChanges/lazy
  session, on in-memory ModelContainer), export contract (columns, ordering, escaping,
  trash exclusion, determinism), PIN, participant context, Clear All Data.
- **UI tests**: a few smoke tests only.
- **CI**: GitHub Actions — build + tests on every PR.
- Final pass: re-run the Axiom audit suite (accessibility incl. Dynamic Type on result
  text and contrast fixes; performance; energy — preview timers).

## 12. OSS Governance

- `docs/DESIGN-STANCES.md` — the stances of §2, each with rationale and "what would
  count as a violation" (English).
- `AGENTS.md` — repo map, build/test commands, hard invariants: never condition
  feedback on measured value; never touch export columns without bumping
  `schema_version` + updating `DATA_DICTIONARY.md`; all user-visible strings
  localized; a new modality is a config + tests, never a forked view; PRs that
  contradict a stance must propose a stance amendment. `CLAUDE.md` includes it.
- `DATA_DICTIONARY.md` — every column, every derivable formula, versioned.
- README rewritten (descriptive framing).
- Final `agent-ready-repo` skill pass. License stays CC0.

## 13. App Store Resubmission (v2.0)

Checklist: SIWA removed (5.1.1 + 5.1.1(v) both moot — no account exists);
real Clear All Data; privacy nutrition label updated (no collected identifiers);
new screenshots (both universes); review notes explaining the research instrument;
**category decision pending** (recommendation: Education instead of Medical —
lower scrutiny, better fit; to decide at submission time).

## 14. Build Order

| Phase | Content |
|---|---|
| 0 | **Method & norms first** (the referential must exist before the artifacts it judges): `DESIGN-STANCES.md`, `AGENTS.md` v1, `DATA_DICTIONARY.md` skeleton committed; private tooling installed (stance-reviewer gate agent + project conventions skill, reading the committed documents) |
| 1 | **Figma**, governed by the stances: design-system file with 4-mode variables (Classic/Rainbow × Light/Dark), components (card, symmetric slider, circles, buttons, participant chip), key screens in both universes (Home, 2-3 measurement screens, Settings, History, Onboarding) **and per form factor: iPhone portrait AND landscape (no-scroll), iPad, Mac window**; review pass (figma-design-reviewer + apple-liquid-glass + stance gate). Classic is *designed and validated here* before any SwiftUI |
| 2 | Tested core, no UI: Theme, canonical geometry + 9 `ModalityConfig`s, data model v2, engine, export; CI bootstrap (build + tests on PR) |
| 3 | Generic measurement screen + Home + Settings |
| 4 | History, Export, Onboarding, research flow (participant, PIN), FR/EN |
| 5 | Legacy purge, final audits (Axiom re-run), `remy-ios-method` distillation (global method skills, written from this project's experience), resubmission |

Old code is deleted as new code replaces it; the app stays buildable throughout.

## 15. Tooling & Method (reusable across apps)

Scoping rule: **the repo carries the product's norms as documents; personal tooling
stays personal** ("différentes personnes, différentes méthodes").

- **In the repo (shared, tool-agnostic):** `AGENTS.md` (invariants, build/test
  commands, doc map), `DESIGN-STANCES.md`, `DATA_DICTIONARY.md`, `CLAUDE.md`
  (includes AGENTS.md). No executable agent/skill tooling is committed. Shared
  enforcement that imposes no method: **CI tests** (export contract, engine
  semantics, Clear All Data).
- **On Rémy's machine (private plugins):**
  - Project layer: `stance-reviewer` agent (read-only, mandatory gate before any
    user-facing feature is "done": valence, data contract, localization, consignes)
    + a conventions skill (canonical encoding, `position` vocabulary, export rules) —
    both read the repo's committed documents as their referential (single source of
    truth; the private tooling enforces the public law).
  - Global layer, plugin `remy-ios-method`, distilled in phase 5 from this project's
    experience (a method is generalized after being proven once, not before): `ios-app-lifecycle` (existing-code audit → brainstorm/spec →
    Figma-first → engine-first tested build → milestone audits → App Store checklist)
    and `research-instrument-apps` (valence audit, stimulus standardization/canonical
    space, data provenance/dictionary, participant/PIN/device flows).
- Roles map: build companion (main session) · stance gate (private agent) ·
  code review (`swift-reviewer`, global) · specialized audits (Axiom, milestones) ·
  design (`figma-design-reviewer` + `apple-liquid-glass`) · build/CI (`xcode-build`
  + GitHub Actions).
- Lesson from Polysomnia (verified 2026-07-28): the method (doc hierarchy + mandated
  review gate + Figma-first + tested engine) demonstrably worked; plugin packaging
  leaks across projects and lives outside the repo — hence: norms committed,
  tooling private, enforcement shared via CI.

## 16. Out of Scope / Open Items

- **Discrete scale**: never — that is `IoSScaale`'s job (coexistence).
- **App Store category** (Medical vs Education): decide at submission.
- Advanced composite metrics (overlap area, radius ratios…): offline, documented
  formulas only.
- v1 test data on CloudKit: considered disposable (fresh v2 store; container unchanged);
  confirm before first v2 install on a device holding data worth keeping.
- Existing `scratch/health-check-*.md` audit reports: keep/move/delete — Rémy's call.
