# Codable Audit — IoS Scale

## Serialization Architecture Map
- 11 Codable types: `Measurement`/`Session` (value structs, synthesized, currently unused for actual encode/decode — dead value types, only their `SecondaryKey`/`ModalityType` enums are live), `ModalityType`, `ThemeMode`, `ResetBehavior`, `ExportFormat`, `DecimalSeparator` (client-only enums), `AppSettings` (struct, dead `.load()`/`.save()` path), `ExportData`/`ExportSession`/`ExportMeasurement` (export-only DTOs). 0 manual `init(from:)`/`encode(to:)`.
- Only two real serialization boundaries: (1) `MeasurementModel.secondaryValuesData` — a `[String: Double]` blob JSON-encoded/decoded on every SwiftData read/write, persisted and synced via CloudKit; (2) `ExportService` — JSON/CSV/TSV export, one-directional (no import feature exists).
- Decoder/encoder strategy: only one encoder configures `dateEncodingStrategy` (`ExportService.exportToJSON`, `.iso8601`) — correctly, since it's the only Codable path with a `Date`. No cross-file decode counterpart exists (export-only), so no strategy drift.
- No `JSONSerialization`, no manual JSON string building, no `CodingKeys`, no `keyDecodingStrategy` — app has no external/snake_case API boundary, so this is not a live risk.
- Custom wrapper: none.
- Round-trip pair of note: `MeasurementModel` encodes `secondaryValues` in `init` and decodes it in the `secondaryValues` computed property (same file, same format) — this is the one live persistence round-trip and it uses `try?` on both sides with zero logging.

## Summary
- CRITICAL: 0
- HIGH: 3
- MEDIUM: 4
- LOW: 2
- Total: 9

## Serialization Health Score

| Metric | Value |
|--------|-------|
| Codable coverage | 11 Codable types, 0 manual implementations |
| Strategy consistency | 1/1 decoders/encoders that touch Date set dateEncodingStrategy (100%); no decode counterpart exists |
| Silent-failure risk | 4 `try?` decode/encode sites, 0 wrapper-hidden fallbacks |
| CodingKeys coverage | N/A — no external snake_case API boundary |
| Enum future-proofing | 1/5 String Codable enums crosses a sync boundary (`ModalityType`); non-crashing fallback but silently mislabels unknown future cases as `.basicIOS` with no logging |
| Cross-file alignment | 0 decoder/encoder pairs to compare (export is one-directional) — 0 drift |
| Legacy serialization | 0 JSONSerialization call sites |
| Overall | HARDENING NEEDED (try? on decode without logging; no payment/auth data at risk, only scientific measurement data integrity) |

## Findings

### [HIGH] Silent loss of Proximity scientific data ("selfPosition"/"otherPosition") on JSON export
**Files:** `IoS Scale/Core/Services/ExportService.swift:193-213` (compare with `IoS Scale/Features/Measurement/Proximity/ProximityViewModel.swift:120-129`)
**Issue:** `ProximityViewModel.saveMeasurement()` explicitly captures `selfPositionNormalized`/`otherPositionNormalized` as secondary values "for scientific analysis" (comment at ProximityViewModel.swift:120). `ExportMeasurement` (ExportService.swift:193-212) only declares `selfScale`/`otherScale` fields — it never reads `Measurement.SecondaryKey.selfPosition`/`.otherPosition`. `primaryValue` (the slider-driven `proximityValue`) is an independent degree of freedom from the two raw circle positions (confirmed in ProximityView.swift:228, slider binds directly to `proximityValue`), so this data is not recoverable from `primaryValue` — it is genuinely and silently dropped, only for the `.json` export format (CSV/TSV still include it via the generic `secondaryValues` dictionary walk).
**Impact:** A researcher exporting Proximity sessions as JSON permanently loses the raw circle-position data with zero error, zero warning, and no indication that CSV/TSV would have preserved it.
**Fix:** Make `ExportMeasurement` generic over the full `secondaryValues` dictionary instead of hand-picking two named fields, e.g. `let secondaryValues: [String: Double]?` populated directly from `measurement.secondaryValues`, or add explicit `selfPosition`/`otherPosition` fields alongside `selfScale`/`otherScale` and set them when `modality == .proximity`.

### [HIGH] `try?` decode/encode of `secondaryValuesData` with zero logging on a live, frequently-read persistence path
**File:** `IoS Scale/Core/Models/Measurement.swift:94, 99-102`
**Issue:** `MeasurementModel.init` does `self.secondaryValuesData = try? JSONEncoder().encode(values)` and the `secondaryValues` computed property does `return try? JSONDecoder().decode([String: Double].self, from: data)`. Both silently return nil/skip on any failure. This blob is persisted through SwiftData and synced via CloudKit (`cloudKitDatabase: .automatic` in `IoS Scale/App/IOSScaleApp.swift:25`), so any future encoding-format change, or a partially-synced/corrupted blob, causes all secondary values for that measurement (Advanced IOS scale factors, Set Membership state, Proximity positions) to vanish with no error surfaced anywhere.
**Impact:** `SessionDetailView`'s statistics (bothIn/selfOnly/otherOnly counts, average scale values — `IoS Scale/Features/History/SessionDetailView.swift:229-251, 317-319`) and every export path silently degrade to "no secondary data" for affected measurements, with no way to know data was lost.
**Fix:**
```swift
var secondaryValues: [String: Double]? {
    guard let data = secondaryValuesData else { return nil }
    do {
        return try JSONDecoder().decode([String: Double].self, from: data)
    } catch {
        print("MeasurementModel: failed to decode secondaryValues for \(id): \(error)")
        return nil
    }
}
```

### [HIGH] Set Membership secondary-value keys are hardcoded camelCase, diverging from the app's own `SecondaryKey` enum
**Files:** `IoS Scale/Features/Measurement/SetMembership/SetMembershipViewModel.swift:70-75` (writer) vs. `IoS Scale/Core/Models/Measurement.swift:43-44` (`SecondaryKey.selfInSet = "self_in_set"`, `.otherInSet = "other_in_set"`, unused dead cases) vs. readers at `IoS Scale/Core/Services/ExportService.swift:110-111`, `IoS Scale/Features/History/MeasurementRowView.swift:86-87`, `IoS Scale/Features/History/SessionDetailView.swift:231-247`, `IoS Scale/UI/Components/MeasurementVisualizations/MeasurementVisualizationView.swift:159,167`
**Issue:** `SetMembershipViewModel.secondaryValues` writes literal keys `"selfInSet"`/`"otherInSet"` (no CodingKeys, no enum reference), while `Measurement.SecondaryKey` — the app's own canonical key registry used by every other modality (`self_scale`, `other_scale`, `self_position`, `other_position`) — defines snake_case `selfInSet`/`otherInSet` cases (`"self_in_set"`/`"other_in_set"`) that are never actually used to write data. Five separate read sites depend on matching the undocumented literal camelCase string instead of the enum. The codebase already shows evidence this exact class of bug has bitten it before: `MeasurementVisualizationView.swift:85,89` and `SessionDetailView.swift:317,319` defensively look up both `"selfScale"` and `"self_scale"` (`?? "self_scale"`) — a dual-key fallback patch added after a prior key-mismatch. No such fallback exists for the Set Membership keys.
**Impact:** Any future refactor that "fixes" `SetMembershipViewModel` to use `Measurement.SecondaryKey.selfInSet.rawValue` (the seemingly-correct, enum-backed choice) will silently break every read site — CSV export, JSON semantics, history stats, and mini-visualizations — turning Set Membership session data into nil/false everywhere, with no crash and no error.
**Fix:** Delete the unused snake_case `selfInSet`/`otherInSet` cases from `SecondaryKey` (or rename them to match reality), and make `SetMembershipViewModel.secondaryValues` reference the enum instead of hardcoded strings.

### [MEDIUM] `AppSettings.load()`/`.save()` swallow decode/encode errors via `try?` with no logging (currently dead code, latent landmine)
**File:** `IoS Scale/Core/Models/AppSettings.swift:138-151`
**Issue:** `try? JSONDecoder().decode(AppSettings.self, from: data)` (line 140) silently falls back to `AppSettings()` defaults on any decode failure; `try? JSONEncoder().encode(self)` (line 148) silently drops the write on failure. Confirmed via grep that `AppSettings`/`.load()`/`.save()` are referenced nowhere else in the codebase — actual settings persistence goes through `@AppStorage` with raw enum values.
**Impact:** Not a live risk today since this code path is unreached. If a future refactor wires `AppSettings.load()/.save()` into real persistence, any schema change would silently reset all user settings to defaults with zero error visibility.
**Fix:** Delete this dead struct/methods, or replace `try?` with logged do/catch before wiring it up.

### [MEDIUM] `ModalityType` (String, Codable) has no unknown-case handling; the one live decode fallback silently mislabels
**Files:** `IoS Scale/Core/Models/Session.swift:104-106`; `IoS Scale/Core/Models/ModalityType.swift:12`
**Issue:** `ModalityType` is persisted as a raw string and synced across devices/app versions via CloudKit automatic sync. The read site has a fallback — `ModalityType(rawValue: modalityRawValue) ?? .basicIOS` — so it does not crash, but silently mislabels any future/unknown modality as Basic IOS with no logging.
**Impact:** Cross-version CloudKit sync scenario: an older client would silently re-tag/re-display/export a session under the wrong modality, corrupting downstream research categorization without any error.
**Fix:** Log via print/Logger when the fallback path is hit, or add an `.unknown(String)` case.

### [MEDIUM] `ExportMeasurement` JSON export omits Set Membership `selfInSet`/`otherInSet` fields (data technically redundant, but undocumented)
**File:** `IoS Scale/Core/Services/ExportService.swift:193-212`
**Issue:** Same DTO gap as the Proximity finding above, but for Set Membership: `primaryValue` (0=neither, 1=self, 2=other, 3=both) is a complete bijective encoding of the same two booleans, but this encoding is nowhere documented in the JSON output.
**Fix:** Same generic-DTO fix as the Proximity finding, or add a documented `membershipState` string field.

### [MEDIUM] `DateFormatter()` with `.dateFormat` set but no `.locale`/`.timeZone` in filename generation
**File:** `IoS Scale/Core/Services/ExportService.swift:58-60`
**Issue:** `dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"` set with no explicit locale/timeZone, so it uses the device's current locale/calendar and time zone. Only affects the generated export filename, not any parsed/persisted data.
**Fix:**
```swift
dateFormatter.locale = Locale(identifier: "en_US_POSIX")
dateFormatter.timeZone = TimeZone(identifier: "UTC")
dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
```

### [LOW] `Measurement`/`Session` value-type `Codable` conformance is vestigial (no live encode/decode call site)
**Files:** `IoS Scale/Core/Models/Measurement.swift:12`, `IoS Scale/Core/Models/Session.swift:12`
**Issue:** No live encode/decode call site found anywhere. Actual serialization goes through the separate `ExportSession`/`ExportMeasurement` DTOs and the SwiftData `SessionModel`/`MeasurementModel` classes — three overlapping representations of the same concepts.
**Fix:** Remove unused Codable conformance, or consolidate on a single DTO layer for export.

### [LOW] `MeasurementModel.secondaryValuesData` is JSON-decoded on every property access (no caching)
**File:** `IoS Scale/Core/Models/Measurement.swift:99-102`
**Issue:** Performance overhead, not correctness — cross-reference with swift-performance-analyzer's matching CRITICAL finding on the same lines.
**Fix:** Cache the decoded dictionary.

## Recommendations
1. Immediate: fix the Proximity/Set-Membership JSON export gap (HIGH) by making `ExportMeasurement` carry the full `secondaryValues` dictionary; add logged do/catch around `MeasurementModel`'s `secondaryValuesData` encode/decode (HIGH, live path).
2. Short-term: consolidate the Set Membership key naming onto `Measurement.SecondaryKey`; add a logged fallback for `ModalityType` decode.
3. Long-term: delete or wire up `AppSettings.load()/.save()` properly; decide whether `Session`/`Measurement` value-type Codable conformance should be removed; set locale/timeZone on the filename DateFormatter; cache decoded secondaryValues.
