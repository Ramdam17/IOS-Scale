# Design Stances — IOS Scale

> Normative document. Version 1.0 (2026-07-28).
> Every stance ends with **Violations** — concrete changes that would break it.
> A pull request that contradicts a stance must propose a stance amendment
> (new version of this file), not slip the change through.

## Stance 1 — No a-priori valence

**Statement.** No state on any measurement continuum is better than another.
Being distant is as valid as being merged. The app never rewards, celebrates,
or visually privileges a region of any scale.

**Operational rule: "Celebrate the act of measuring, never the measured value."**

**Rationale.** IOS Scale is a descriptive instrument. Any affective feedback
tied to *where* a response lies teaches participants what the "good" answer is
(demand characteristics, operant reinforcement) and contaminates the measure.
Version 1 of this app violated this stance (hearts at high proximity/similarity,
"Immersed" badges) and those elements were removed deliberately, not lost.

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
- History and stats use "position", distributions, and ranges — never "score",
  progress, or improvement language.

**Violations.** Adding `if position > x { reward }` in any form; a confetti
burst at "merged"; a label ladder ending in an emotional climax; a chart whose
upward direction is framed as better; release notes praising "higher closeness".

## Stance 2 — The datum is the configuration the participant showed

**Statement.** The stored measurement is the geometry the participant produced,
in canonical instrument units, plus a `position` coordinate. Scalar composites
and literature-comparable indices are the analyst's business, computed offline.

**Rationale.** Storing only a derived number destroys re-analysis (v1 stored a
slider fraction that corresponded to no defined quantity). Storing raw geometry
makes every convention recomputable and every future re-scoring possible.

**Consequences.**
- Every degree of freedom offered to the participant is recorded as-is
  (e.g. Advanced IOS records `d`, `r_self`, `r_other` — radii are response
  variables, never context).
- `position` ∈ [0,1] is a *coordinate* on a continuum defined by two neutrally
  described poles; it is never called, displayed, or documented as a score.
- Domain constraints live in the manipulandum's geometry. Out-of-domain values
  are loud errors — never silent clamps (v1's Set Membership 0–3-clamped-to-1
  corruption is the cautionary tale).
- Set Membership stores an explicit category
  (`neither/self_only/other_only/both`, spelled here in its serialized form);
  no continuous score is fabricated from it, and categorical modalities have
  no `position`.
- Derivable formulas (overlap proportion, distance norms…) are documented in
  `docs/DATA_DICTIONARY.md`, not baked into the app.

**Violations.** Persisting a derived value without its geometry; adding a
composite "closeness index" column to exports; clamping instead of erroring;
renaming `position` to anything magnitude-flavored.

## Stance 3 — What the participant sees is a covariate

**Statement.** Any toggleable feedback (numeric value, verbal labels,
celebrations) and any rendering circumstance that could shape a response is
recorded in each measurement's context.

**Rationale.** A response given while watching a live numeric readout is not
the same measurement as one given without it. If display conditions are not in
the data, they are confounds in the researcher's memory.

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

**Rationale.** The app's frame is the descriptive/phenomenological tradition
(Ollagnier-Beldame & Coupé 2019; Coupé & Ollagnier-Beldame 2022). It departs
consciously from the self-expansion framing (Aron & Aron 1986) whose valence
had leaked into v1. Words like "connected" at one pole and deficit phrasing
("minimal connection") at the other impose an interpretation.

**Consequences.**
- State labels name geometry: e.g. "Separated / Touching / Partial overlap /
  Concentric".
- Long experiential descriptions are either removed or symmetric in richness
  and affective load across poles.
- Accessibility copy names the gesture and the stimulus ("change the circles'
  position"), not the construct ("adjust closeness").
- Each modality ships a `ModalityDocumentation` (what it measures, how, and a
  suggested instruction) — the instruction never hints at a preferred region.

**Violations.** A consigne like "bring the circles together to show how close
you feel" (directional); reintroducing "Merged" as a label climax; an a11y hint
that names closeness as the thing being adjusted.

## Stance 5 — Rendering conventions are explicit per instrument version

**Statement.** Fixed-diameter circles; full separated→concentric manipulable
domain; geometry constants (e.g. `D_max`) are per-modality constants versioned
under `instrument_version`. No comparability claim with other IOS
implementations without offline recomputation from stored geometry.

**Rationale.** Constant-total-area rendering (Aron's feature) is theoretically
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

**Rationale.** This is a research instrument that will hold participants'
responses. The researcher owns the correspondence table; the app never holds
identity. v1's mandatory Sign in with Apple served no function and was rejected
by App Review (Guideline 5.1.1) — the account concept is removed, not fixed.

**Consequences.** Participant codes are free-form; the *active* code is held
in memory only and reset at launch (a code is stamped onto the sessions it
labels — that stamp is the only persistence);
device identity is a device label, not a person; PIN gates data zones
(Settings, History, Export), not measurement; "Clear All Data" actually deletes
everything, verified by tests.

**Violations.** Reintroducing any account or persistent user identifier;
sync default ON; analytics/telemetry of any kind; a deletion flow that leaves
CloudKit records behind.

## Amendment process

Stances change by amending this file (new version number, dated changelog
entry, rationale for the change) in a dedicated commit — never as a side effect
of a feature PR.
