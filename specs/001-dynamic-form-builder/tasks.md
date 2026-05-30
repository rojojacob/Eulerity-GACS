---
description: "Dependency-ordered tasks for the Dynamic Form Builder feature"
---

# Tasks: Dynamic Form Builder (Server-Driven UI)

**Input**: `./spec.md`, `./plan.md`, and `/Plan.md` (§6 is authoritative; this mirrors it).

**Tests**: REQUIRED. Per Constitution II, each task ships its Swift `Testing` cases in the SAME
task and is not done until they pass (Plan.md §3 gate G4 → G5).

**Process**: Run EVERY task through the Plan.md §3 five-gate loop — G1 Spec → G2 Approve →
G3 Implement → G4 Test → G5 Verify. Commit on green G5 with the shown prefix. Do not start a
task before the previous task's G5 is green.

**Legend**: `[ ]` todo · `[x]` done · `[P]` parallelizable (different files, no dependency).

---

## Phase A — Foundation

- [x] **A1** `chore: scaffold MVVM structure` — Xcode iOS 16 target, the §4 group layout,
  `Resources/form_payload.json` bundled, `EulerityTests` target + scheme.
  **Tests**: `BundleTests.payloadFileExistsInBundle()`. **✅ Done & verified** (build + test green).
- [x] **A2** `feat: hex color parsing + theme model` — `ThemeModel` (raw hex strings),
  `HexColorParser.rgba(from:)` for `#RGB`/`#RRGGBB`/`#RRGGBBAA` (± `#`), invalid → `nil` →
  `ResolvedTheme.fallback` (per-channel).
  **Tests**: `HexColorParserTests` + `ResolvedThemeTests` (3/6/8-digit, missing `#`, empty/blank,
  invalid `#GGGGGG` → nil, wrong length → nil, nil model → fallback, invalid channel → fallback,
  valid channel → parsed). **✅ Done & verified** (13 tests / 4 suites green).

## Phase B — Polymorphic parsing (core)

- [x] **B1** `feat: field type + subtype enums` — `FieldType` (`.text/.dropdown/.toggle/.checkbox`
  + `.unsupported(rawValue:)`), exact case-sensitive match, unknown → unsupported (no throw);
  `TextSubtype` PLAIN/MULTILINE/NUMBER/URI/SECURE, unknown → `.plain`. Both pure, defensive `Decodable`.
  **Tests**: `DecodingTests` — known types/subtypes, unknown type → `.unsupported`, case-sensitivity,
  `isSupported`, unknown subtype → `.plain`. **✅ Done & verified** (19 tests / 6 suites green).
- [x] **B2** `feat: polymorphic Codable decoding` — `FormField` flat struct + computed `kind` +
  `DropdownOption`; `FormPayload` decodes `fields` element-by-element via a lossy `Failable`
  wrapper, excluding malformed/`.unsupported` fields without aborting (counted in
  `skippedFieldCount`); per-dropdown `[id:label]` map (O(1) lookup); `default_value`
  String|Bool|array handling.
  **Tests**: `DecodingTests` — 4 known types, unknown excluded, empty options, malformed-skipped,
  missing-fields → empty, bundled payload → 6 renderable / 1 skipped. **✅ Done & verified**
  (31 tests / 8 suites green; required flattening a compiler-crashing nested-optional expression).
- [x] **B3** `feat: bundle JSON loader` — `FormLoader.load(resource:) -> Result<FormPayload, FormLoadError>`
  (typed `FormLoadError`: fileNotFound / unreadable / decoding, `LocalizedError` messages);
  decoding split into a testable `decode(_:)`. Missing/unreadable/corrupt → typed error, no crash.
  **Tests**: `LoaderTests` — bundled load success, missing → `.fileNotFound`, corrupt → `.decoding`,
  valid data → payload. **✅ Done & verified** (35 tests / 9 suites green).

## Phase C — State & ViewModel

- [x] **C1** `feat: field value state + defaults` — `FieldValue` enum (`.text`/`.bool`/`.selection`);
  `FormViewModel` (`@MainActor ObservableObject`, no SwiftUI) builds `orderedFields` (sort by `order`
  with explicit stable tie-break on decode index) + `@Published values` seeded from defaults (text
  truncated to `max_length` #1; dropdown selection filtered to valid option ids via a `Set` #9).
  Removed the unused `LoadableViewModel` (YAGNI).
  **Tests**: `OrderingTests` (sort-not-index, stable tie-break); `ViewModelTests` (defaults seeded,
  absent → empty/false, selection filtered, text truncated). **✅ Done & verified** (41 tests / 11 suites green).
- [x] **C2** `feat: value updates + max length guard` — `updateText` (live prefix-truncate to
  `max_length`), `toggle`, `select` (single replace vs multi membership toggle); O(1) field
  metadata lookup via a `fieldsByID` map. **Tests**: `ViewModelUpdateTests` — max-length blocks
  overflow, no-max stores full, toggle flips, single-select replaces, multi-select toggles.
  **✅ Done & verified** (46 tests / 12 suites green). Phase C complete.

## Phase D — Validation

- [x] **D1** `feat: validation engine` — pure `Validator.validate(fields:values:) -> [String:String]`;
  required (text/checkbox/dropdown), `TEXT` regex, max_length re-check, multi-select-required,
  empty-options-required conflict surfaced (#3); invalid regex pattern ignored safely (#11). O(n).
  **Tests**: `ValidationTests` (10) — required missing/present, regex pass/fail/invalid-ignored,
  optional-empty-with-regex valid, multiselect-required-empty, empty-options conflict, required
  checkbox, fully-valid form. **✅ Done & verified** (56 tests / 13 suites green).
- [x] **D2** `feat: submit + payload print` — `validateAndSubmit()` sets `@Published errors`; if empty,
  builds a typed `[String: SubmitValue]` of non-empty values (text→scalar, single-select→scalar id,
  multi-select→array, toggle/checkbox→bool), prints pretty JSON, sets `@Published confirmation`.
  **Tests**: `ViewModelSubmitTests` — invalid blocks + surfaces errors, payload shape preserves
  scalars/arrays/bools, empty values omitted, dismiss clears. **✅ Done & verified** (60 tests / 14
  suites green). **Phase D complete — entire non-UI core done.**

## Phase E — Views

- [x] **E1** `feat: themed form screen` — `FormScreen` loads via `FormLoader` into a `ViewState`
  (loading/error via `StateView`); `FormContentView` owns the `FormViewModel`, paints `ResolvedTheme`
  (background/text/border/error), renders `form_title` + ordered `FieldRowView` list + Save + the
  confirmation alert. `FieldRowView` routes on `kind` (themed placeholders now; real controls in E2–E4).
  **Verified (G5):** built + **ran on iPhone 16 Pro simulator** — dark theme renders from JSON, 6
  fields in order, `COLOR_PICKER` excluded (screenshot). 60 tests / 14 suites still green, no warnings.
- [x] **E2** `feat: text field component` — `TextFieldComponent` routes PLAIN/MULTILINE/NUMBER/URI/
  SECURE (keyboard, masking, multiline); `placeholder` + `CharacterCounterView` only when present
  (error color at limit); `ThemedFieldStyle`. Binds via `updateText`. **✅ Built green.**
- [x] **E3** `feat: dropdown component` — `DropdownComponent`: `Menu` of labels → stores id via
  `select` (single replace / multi checkmark-toggle); closed label resolved via O(1) map; empty
  options → disabled hint (§7 #3). **✅ Built green.**
- [x] **E4** `feat: toggle + checkbox components` — `ToggleComponent` (labeled switch, honors default)
  + `CheckboxComponent` (tappable box + inline label, honors required); `FieldRowView` omits the top
  label for them. **✅ Verified on simulator** (screenshot): all 4 component types render, default
  truncated to 20/20 (red counter), multi-dropdown shows resolved label, empty-options disabled.
  **Phase E complete — the full form renders and works.** 60 tests / 14 suites green, no warnings.

## Phase F — Optional enhancements (in scope)

- [x] **F1** `feat: clickable metadata links in checkbox` — pure `RichTextLabel` builds an
  `AttributedString` linking each matched `metadata` key; `CheckboxComponent` renders box + links as
  separate tap targets (links open Safari), tinted with `clickable_text_color`/accent; missing key or
  malformed URL left as plain text (§7 #10). **Tests**: `RichTextTests` (4) — link ranges, missing
  ignored, malformed URL, nil metadata. **✅ Verified on simulator** (Terms/Privacy render blue &
  linked). 64 tests / 15 suites green.
- [x] **F2** `feat: regex validation UX` — regex errors already surface inline (D1 `Validator` +
  `FieldRowView`); F2 adds **compile-once caching**: `FormViewModel` precompiles each pattern at init
  and passes it to `Validator` (which falls back to inline compile, so D1 tests stand). Invalid
  pattern ignored end-to-end (§7 #11). **Tests**: `ViewModelRegexTests` (3) — fail blocks submit,
  match submits, invalid pattern ignored. **✅ Done & verified** (67 tests / 16 suites green).
- [x] **F3** `feat: keyboard Next/Done toolbar` — `FormViewModel.textFieldIDsInOrder` (text fields in
  visual order); a `@FocusState` binding threaded `FormContentView → FieldRowView → TextFieldComponent`;
  a keyboard `ToolbarItemGroup` with **Next** (advances, disabled on last) and **Done** (dismisses).
  **Tests**: `FocusTests.focusOrderMatchesVisualOrder` (text-only, visual order). **✅ Done & verified**
  (builds + 68 tests / 17 suites green).
- [x] **F4** `test: polymorphic parsing edge cases` — `EdgeCaseTests` consolidates §7 coverage: garbage
  order → Int.max (#7), missing optional keys → nil (#5), a hostile mixed payload (unknown type +
  id-less element + empty-options dropdown → 3 renderable / 2 skipped) (#2/#3/#6/#12), all-invalid
  theme → fallback (#8), no-fields → empty titled form (#6). **✅ Done & verified** (73 tests / 18
  suites green). **Phase F complete — all 4 enhancements in.**

## Phase G — Polish & submission

- [ ] **G-DOC** `docs: README, AI log, demo` — `README.md` (architecture + §7 decisions #1/#3/#13 +
  "what I'd improve" + "what I got stuck on"), `AI_COLLABORATION_LOG.md`, 30–60s demo video, repo public.
  **Gate**: Plan.md §8 Definition of Done.

---

## Dependency order (TL;DR — Plan.md §10)

```
A1 ✅ ─▶ A2 ─▶ B1 ─▶ B2 ─▶ B3
        └▶ C1 (needs B2) ─▶ C2 ─▶ D1 ─▶ D2
                 └▶ E1 (needs A2,C1,D2) ─▶ E2/E3/E4 [P after E1]
                          └▶ F1/F2/F3 [P] ─▶ F4 ─▶ G-DOC ─▶ Definition of Done ─▶ submit
```

## Notes

- Phases gate sequentially; within Phase E the components (E2–E4) and within Phase F (F1–F3) are
  largely `[P]` once their shared screen/state exists.
- Every function gets a `// O(...)` comment; no nested O(n²) scans over `fields` (Constitution IV).
- No force-unwraps/`try!` on JSON paths (Constitution V). Tests precede "done", not deferred.
