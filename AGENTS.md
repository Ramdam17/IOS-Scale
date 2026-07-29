# AGENTS.md — IOS Scale

Guide for anyone (human or AI) modifying this repository.

## What this is

An iOS/iPadOS research instrument measuring intersubjective experience with 9
circle-based modalities (8 continuous, 1 categorical). Two visual universes (Classic: sober
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
   value.** "Celebrate the act of measuring, never the measured value."
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
