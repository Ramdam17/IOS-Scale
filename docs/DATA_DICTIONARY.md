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

> The four "finalized in phase 2" rows are drafts by design: their v1
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
