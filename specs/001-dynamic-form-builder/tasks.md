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
- [ ] **B2** `feat: polymorphic Codable decoding` — `FormField` flat struct + computed `kind`;
  element-by-element decode, malformed/`.unsupported` collected & excluded, never aborts payload;
  per-dropdown `[id:label]` map; `default_value` String|Bool|array handling.
  **Tests**: `DecodingTests` (sample → 4 fields; All-in-One excludes `COLOR_PICKER`;
  `test_emptyOptionsArray_decodes()`, `test_malformedSingleField_isSkipped_othersSurvive()`,
  `test_missingFieldsArray_yieldsEmptyForm()`). Depends on B1.
- [ ] **B3** `feat: bundle JSON loader` — `FormLoader.load(resource:) -> Result<FormPayload, FormLoadError>`;
  missing/unreadable/corrupt → typed error, no crash.
  **Tests**: `LoaderTests.test_missingResource_returnsFileNotFound()`, `test_corruptJSON_returnsDecodingError()`. Depends on B2.

## Phase C — State & ViewModel

- [ ] **C1** `feat: field value state + defaults` — `FieldValue` enum; `FormViewModel.orderedFields`
  (sorted by `order`, stable tie-break) + `values` seeded from defaults (text truncated to
  `max_length`; selection filtered to valid option ids).
  **Tests**: `OrderingTests.test_fieldsSortedByOrderNotIndex()`; `ViewModelTests.test_defaultsSeeded()`,
  `test_defaultSelectionFilteredToValidOptions()`, `test_textDefaultTruncatedToMaxLength()`. Depends on B2.
- [ ] **C2** `feat: value updates + max length guard` — `updateText`/`toggle`/`select`
  (single replace vs multi membership), O(1) dictionary writes, prefix truncation.
  **Tests**: `ViewModelTests.test_maxLengthBlocksOverflow()`, `test_singleSelectReplaces()`,
  `test_multiSelectTogglesMembership()`. Depends on C1.

## Phase D — Validation

- [ ] **D1** `feat: validation engine` — `Validator.validate(fields:values:) -> [String:String]`;
  required, regex (compile once), max_length re-check, multi-select-required, empty-options-required
  conflict; invalid regex pattern ignored safely.
  **Tests**: `ValidationTests` (required missing/present, regex pass/fail, multiselect-required-empty,
  invalid-regex-ignored). Depends on C1.
- [ ] **D2** `feat: submit + payload print` — `validateAndSubmit()` sets `errors`; if empty, build
  `[String:Any]` of non-empty values, print JSON shape, set confirmation; scalars vs arrays preserved.
  **Tests**: `ViewModelTests.test_submitBlockedWhenInvalid()`, `test_submitPayloadShapeMatchesValues()`. Depends on C2, D1.

## Phase E — Views

- [ ] **E1** `feat: themed form screen` — `FormScreen` paints `ResolvedTheme`, renders `form_title`,
  scrollable `FieldRowView` list + Save; load-failure/empty states via `StateView`. Depends on A2, C1, D2.
  **Tests**: manual G5 (state logic already covered by C/D).
- [ ] **E2** `feat: text field component` — route 5 subtypes; `placeholder`/counter only if present;
  SECURE masks. Depends on E1, C2.
- [ ] **E3** `feat: dropdown component` — `Menu` showing labels, stores id; `allow_multiple` rows;
  empty options disabled + hint. Depends on E1, C2.
- [ ] **E4** `feat: toggle + checkbox components` — honor default/required. Depends on E1, C2.

## Phase F — Optional enhancements (in scope)

- [ ] **F1** `feat: clickable metadata links in checkbox` — `AttributedString`, style matched
  substrings with `clickable_text_color`/accent, open URL in Safari; missing key/malformed URL safe.
  **Tests**: `RichTextTests.test_linkRangesResolved()`, `test_missingSubstringIgnored()`,
  `test_malformedURLNotClickable()`. Depends on E4.
- [ ] **F2** `feat: regex validation UX` — surface D1 regex errors inline; compile once; bad pattern ignored.
  **Tests**: extends `ValidationTests` (D1). Depends on D1, E2.
- [ ] **F3** `feat: keyboard Next/Done toolbar` — `@FocusState` over ordered text-field ids; Next advances, Done dismisses.
  **Tests**: `FocusTests.test_focusOrderMatchesVisualOrder()`. Depends on E2.
- [ ] **F4** `test: polymorphic parsing edge cases` — consolidate/extend decoding tests to cover the
  full §7 matrix (missing arrays, conflicts, unknown types). Depends on B2.

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
