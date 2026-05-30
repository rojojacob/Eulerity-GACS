# Plan.md — Eulerity iOS Take-Home: Dynamic Form Builder (Server-Driven UI)

> **Single source of truth for this project.** This file drives a spec-driven, test-after-each-task build.
> Read it top to bottom before writing any code. Do not skip the gating checkpoints.

---

## 0. How to use this file (instructions for the terminal/agent)

You are implementing a **single-screen SwiftUI app whose entire UI is driven by a local JSON payload.** Work **one task at a time, in order.** For every task follow the **5-gate loop** defined in §3. Never start a task before the previous task's gate G5 (verification) is green. Commit after every passed gate with the message prefix shown in each task.

**Golden rules**
- Architecture is **MVVM**. No business logic in Views. No SwiftUI imports in Models or pure logic.
- Every function you write gets a one-line complexity comment: `// O(n) — single pass over fields`. Justify anything worse than `O(n log n)`.
- Defensive by default: the app must **never crash** on malformed, missing, conflicting, or unknown JSON.
- Tests are written **in the same task** as the code they cover, not deferred. A task is not done until its tests pass.
- iOS **16.0** minimum, Swift + SwiftUI only, **fully offline**, no third-party packages.

---

## 1. Project context

| Item | Value |
|---|---|
| Company | Eulerity (GACS iOS role) |
| Exercise | Dynamic Form Builder — Server-Driven UI |
| Deadline | ~1 week from 2026-05-26 (target submit before **2026-06-02**) |
| Submit to | rahul.pawar+recruiting@eulerity.com |
| Deliverables | Public Git repo, README, 30–60s demo video, `AI_COLLABORATION_LOG.md` |
| Min target | iOS 16.0 |
| Language/UI | Swift + SwiftUI (no UIKit unless wrapping is unavoidable) |
| Networking | **None** — JSON loaded from app bundle |
| Test framework | **Swift Testing** (`import Testing`) |
| Scope | All required features **+ all 4 optional enhancements** |

---

## 2. Non-negotiable requirements (acceptance contract)

Derived line-by-line from the exercise brief. Each maps to a task in §6.

**Parsing & rendering**
- [ ] Parse `type` and render: `TEXT`, `DROPDOWN`, `TOGGLE`, `CHECKBOX`.
- [ ] `TEXT` parses `subtype`: `PLAIN`, `MULTILINE`, `NUMBER`, `URI`, `SECURE`.
- [ ] Optional fields (`placeholder`, supporting/`error_message`, `max_length`) apply **only if present**.
- [ ] `max_length`: prevent typing past the limit **and** show a live character counter.
- [ ] `DROPDOWN`: UI shows `label`, state stores `id`.
- [ ] `DROPDOWN` `allow_multiple == true`: multi-select (checkboxes inside a menu).
- [ ] `TOGGLE`: boolean switch, honor `default_value`.
- [ ] `CHECKBOX`: checkbox + label, honor `required`.

**Architecture & theming**
- [ ] Sort fields by the `order` integer before rendering. **Never** rely on array index.
- [ ] Parse `theme` hex codes → background, input borders/accents, text, error colors.
- [ ] Store dynamic field state in an **observable** view model.

**Validation & resilience**
- [ ] "Save" button validation: clearly flag missing required fields.
- [ ] On valid submit, print final key-value pairs (e.g. `{"campaign_name":"Summer Sale","target_network":["net_meta"]}`) to console **and** show a confirmation alert.
- [ ] Unknown `type` (e.g. `DATE_PICKER`, `COLOR_PICKER`) is **ignored gracefully**, no crash.

**Optional enhancements (all in scope)**
- [ ] Rich-text checkbox: `metadata` keys are clickable substrings in the label → open URL in Safari; honor `clickable_text_color` override.
- [ ] Custom `regex` validation for `TEXT`.
- [ ] `@FocusState` keyboard toolbar with **Next**/**Done** cycling text fields.
- [ ] Swift Testing cases for polymorphic parsing + malformed data.

---

## 3. The spec-driven 5-gate loop (run for EVERY task)

This is the process. Do not collapse it. Each task in §6 is executed through these gates.

```
G1  SPEC      Write/refresh the task spec: inputs, outputs, behavior, edge cases,
              data model touched, acceptance criteria, and the test list.
              Output a short spec block in /Specs/<TaskID>.md.

G2  APPROVE   Self-review the spec against §2 contract + edge-case matrix (§7).
              Confirm: Does this contradict any other field/spec? Is the Big-O
              optimal? STOP and surface to the user if a real ambiguity exists.

G3  IMPLEMENT Write the code. MVVM boundaries respected. Every function gets a
              complexity comment. No dead code, no force-unwraps on JSON paths.

G4  TEST      Write the Swift Testing cases named in G1. Run them. They must pass.
              Add a regression test for any bug found while implementing.

G5  VERIFY    Build succeeds for iOS 16 sim. Run the task's manual check (if UI).
              Re-read the spec: every acceptance criterion demonstrably met.
              Commit. Mark task done. Only now move on.
```

A task is **DONE** only when G5 is green. If G4 fails, return to G3. If G2 finds a contradiction you cannot resolve from the brief, pause and ask.

---

## 4. Architecture — MVVM

```
┌─────────────────────────────────────────────────────────────┐
│  View layer (SwiftUI) — dumb, declarative, no logic          │
│   FormScreen → FieldRowView → {Text/Dropdown/Toggle/Checkbox}│
└───────────────▲───────────────────────────┬─────────────────┘
                │ @Published bindings        │ user intents
┌───────────────┴───────────────────────────▼─────────────────┐
│  ViewModel layer — ObservableObject                          │
│   FormViewModel: holds ordered fields, field state map,      │
│   theme, validation results, submit logic                    │
└───────────────▲───────────────────────────┬─────────────────┘
                │ decoded models             │ calls services
┌───────────────┴───────────────────────────▼─────────────────┐
│  Model + Service layer — pure Swift, no SwiftUI              │
│   FormPayload, FormField (+ kind enum), FieldType,           │
│   ThemeModel, FieldValue;  FormLoader, FormDecoder,          │
│   Validator, HexColorParser                                  │
└──────────────────────────────────────────────────────────────┘
```

**Boundary rules**
- Models/Services: **no `import SwiftUI`**. Pure, unit-testable, deterministic.
- ViewModel: owns all mutable state via `@Published`. Exposes intent methods (`updateValue`, `validateAndSubmit`). Holds no `View` types.
- Views: read from ViewModel, send intents. Zero parsing, zero validation logic inline.
- Theme is resolved once into a `ResolvedTheme` (SwiftUI `Color`s live in a thin presentation extension, not in the model).

### Proposed folder / group structure (empty Xcode project → create these groups)

```
Eulerity/
├── App/
│   └── EulerityApp.swift
├── Resources/
│   └── form_payload.json            // bundled sample / test payload
├── Models/
│   ├── FormPayload.swift            // top-level: theme, form_title, fields
│   ├── FormField.swift              // polymorphic field + FieldKind enum
│   ├── FieldType.swift             // TEXT/DROPDOWN/TOGGLE/CHECKBOX + subtypes
│   ├── DropdownOption.swift
│   ├── ThemeModel.swift
│   └── FieldValue.swift             // enum: .text/.bool/.selection([String])
├── Parsing/
│   ├── FormDecoder.swift            // polymorphic Codable decode + skip-unknown
│   └── FormLoader.swift             // bundle file → Data → FormPayload
├── Theming/
│   ├── HexColorParser.swift         // "#RRGGBB"/"#RGB"/"#RRGGBBAA" → RGBA
│   └── ResolvedTheme.swift          // ThemeModel → SwiftUI Colors (presentation)
├── Validation/
│   └── Validator.swift             // required, max_length, regex rules
├── ViewModels/
│   └── FormViewModel.swift
├── Views/
│   ├── FormScreen.swift
│   ├── FieldRowView.swift           // routes a field to its component view
│   ├── Components/
│   │   ├── TextFieldComponent.swift // handles all 5 subtypes
│   │   ├── DropdownComponent.swift  // single + multi
│   │   ├── ToggleComponent.swift
│   │   └── CheckboxComponent.swift  // + rich-text links
│   └── Support/
│       ├── CharacterCounterView.swift
│       └── KeyboardToolbar.swift    // @FocusState Next/Done
└── EulerityTests/
    ├── DecodingTests.swift
    ├── ValidationTests.swift
    ├── HexColorParserTests.swift
    ├── OrderingTests.swift
    └── ViewModelTests.swift
```

> **Adjustments to this plan (decided during setup):**
> - The Xcode project keeps its existing name **`Eulerity`** (target, scheme, and bundle id
>   `com.wac.Eulerity` unchanged) — the group layout above lives *inside* it.
> - Tests use **Swift Testing** (`import Testing`, `@Suite`/`@Test`/`#expect`), not XCTest.
>   The test file names above are unchanged; only the framework differs.
> - Reusable infra is kept beyond the tree: `Support/ViewState.swift` (load-state enum),
>   `Views/Support/StateView.swift` (renders a `ViewState`), and
>   `ViewModels/LoadableViewModel.swift` (a `@MainActor` load-state base protocol).
> - `FormScreen` is the app root (there is no separate `RootView`).
> - The bundled `Resources/form_payload.json` is currently a representative sample covering
>   the §7 edge cases; replace it with the brief's official "sample" and "All-in-One" payloads.

---

## 5. Big-O guidelines (apply to every function)

| Operation | Target complexity | Approach |
|---|---|---|
| Sort fields by `order` | `O(n log n)` | Single `sorted(by:)`, stable tie-break on array index |
| Field lookup by `id` | `O(1)` | Maintain `[String: FieldValue]` dictionary, not linear search |
| Dropdown `label` for selected `id` | `O(1)` | Pre-build `[id: label]` map per dropdown at decode time |
| Validation pass on submit | `O(n)` | One pass over fields; each rule check is `O(1)`/`O(len)` |
| `max_length` enforcement | `O(1)` amortized | Check on each keystroke via `onChange`, truncate prefix |
| Regex match | `O(len)` | Compile `NSRegularExpression` **once**, reuse |
| Build submit payload | `O(n)` | Single pass collecting non-empty values |
| Rich-text link ranges | `O(L·k)` | L=label length, k=keys; acceptable, document it |

**Forbidden:** nested `O(n²)` scans over fields (e.g. "for each field, search all fields"). If you ever write a loop inside a loop over `fields`, replace with a pre-built map. Every function header carries a `// O(...)` comment justifying its cost.

---

## 6. Task breakdown (each runs through the §3 5-gate loop)

> Order is dependency-correct. Commit prefix shown per task. Each task lists its **Spec essentials**, **Big-O notes**, **Acceptance**, and **Tests** (the Swift Testing cases you must write in G4).

### Phase A — Foundation

#### A1 · Scaffold project & MVVM groups
**Commit:** `chore: scaffold MVVM structure`
- Spec: Configure deployment target iOS 16.0. Create the folder groups from §4. Add an empty `form_payload.json` to a real **Resources** group that is in the app target's *Copy Bundle Resources*. Create the unit test target.
- Big-O: n/a.
- Acceptance: App builds & launches to an empty screen; test target runs an empty passing test; JSON file is confirmed in the bundle at runtime.
- Tests: `BundleTests.test_payloadFileExistsInBundle()` — asserts `Bundle.main.url(forResource:)` is non-nil.

#### A2 · Theme & color model + Hex parser
**Commit:** `feat: hex color parsing + theme model`
- Spec: `ThemeModel { background_color, text_color, border_color, error_color }` all `String`. `HexColorParser.rgba(from:) -> (r,g,b,a)?` supports `#RGB`, `#RRGGBB`, `#RRGGBBAA`, with/without `#`. Invalid hex → `nil` → caller falls back to a safe default (define `ResolvedTheme.fallback`). `ResolvedTheme` maps to SwiftUI `Color` in the Theming/presentation layer only.
- Big-O: `O(1)` parse (fixed-length string).
- Acceptance: Missing/garbage hex never crashes; defaults applied.
- Tests: `HexColorParserTests`: valid 6-digit, 3-digit, 8-digit, missing `#`, empty string, `"#GGGGGG"` (invalid) → nil, `nil` theme field → fallback used.

### Phase B — Polymorphic parsing (the core)

#### B1 · Field type taxonomy
**Commit:** `feat: field type + subtype enums`
- Spec: `FieldType` enum with cases for known types; **unknown decodes to `.unsupported(rawValue:)`** rather than throwing. `TextSubtype: PLAIN/MULTILINE/NUMBER/URI/SECURE`, unknown subtype → default `.plain` (document this product decision). Map `type`/`subtype` case-insensitively? **Decision:** match exactly as in brief (uppercase), unknown → unsupported.
- Big-O: `O(1)` per field.
- Acceptance: `COLOR_PICKER`, `DATE_PICKER` → `.unsupported`. No throw.
- Tests: `DecodingTests.test_unknownType_mapsToUnsupported()`, `test_unknownSubtype_defaultsToPlain()`.

#### B2 · Polymorphic field decoding (skip-unknown, defensive)
**Commit:** `feat: polymorphic Codable decoding`
- Spec: `FormField` decodes shared keys (`id`, `order`, `type`, `label`, `required`) + optional type-specific keys (`subtype`, `placeholder`, `max_length`, `error_message`, `options`, `allow_multiple`, `default_value`/`default_values`, `metadata`, `clickable_text_color`, `regex`). Use a `FieldKind` payload enum or a flat struct with optionals — **decision: flat struct + computed `kind`** for simpler state mapping. Decode `fields` array element-by-element: a field that fails to decode (or is `.unsupported`) is **collected separately and excluded from render**, never aborts the whole payload. `default_value` may be `String` or `Bool` or array → handle with a small `AnyDefault` decoder or per-type optional keys (`default_value` String/Bool, `default_values` [String]).
- Big-O: `O(n)` decode; building per-dropdown `[id:label]` map is `O(m)` per dropdown.
- Acceptance: All-in-One payload (§ brief) decodes; `COLOR_PICKER` excluded; `billing_account` with **empty `options:[]`** decodes fine. A single malformed element does not nuke the rest.
- Tests: `DecodingTests`: decode sample payload → 4 fields; decode All-in-One → known-type count excludes `COLOR_PICKER`; `test_emptyOptionsArray_decodes()`; `test_malformedSingleField_isSkipped_othersSurvive()`; `test_missingFieldsArray_yieldsEmptyForm()`.

#### B3 · Loader
**Commit:** `feat: bundle JSON loader`
- Spec: `FormLoader.load(resource:) -> Result<FormPayload, FormLoadError>`. Missing file / unreadable / top-level malformed → typed error surfaced to a friendly UI error state, not a crash.
- Big-O: `O(n)`.
- Acceptance: Missing file → `.fileNotFound` handled; corrupt top-level JSON → `.decoding` handled.
- Tests: `LoaderTests.test_missingResource_returnsFileNotFound()`, `test_corruptJSON_returnsDecodingError()`.

### Phase C — State & ViewModel

#### C1 · Field value model + initial state
**Commit:** `feat: field value state + defaults`
- Spec: `FieldValue` enum: `.text(String)`, `.bool(Bool)`, `.selection([String])` (ids). `FormViewModel` builds `orderedFields` (sorted by `order`, stable tie-break) and `values: [String: FieldValue]` seeded from defaults: `TEXT.default_value` (truncated to `max_length` if present — **decision**, see §7), `TOGGLE/CHECKBOX.default_value` bool, `DROPDOWN.default_values`/`default_value` ids filtered to existing option ids.
- Big-O: sort `O(n log n)`; seed `O(n)`; selection filter `O(s)` against an option-id `Set` (`O(1)` membership).
- Acceptance: Defaults appear pre-filled; a default id not in options is dropped; ordering correct (e.g., All-in-One renders order 1..10).
- Tests: `OrderingTests.test_fieldsSortedByOrderNotIndex()`; `ViewModelTests.test_defaultsSeeded()`, `test_defaultSelectionFilteredToValidOptions()`, `test_textDefaultTruncatedToMaxLength()`.

#### C2 · Update intents + max_length enforcement
**Commit:** `feat: value updates + max length guard`
- Spec: `updateText(id:String, newValue:)` truncates to `max_length` (prefix) and stores. `toggle(id:)`, `select(id:optionId:)` (respects `allow_multiple`: replace vs toggle-in-set). All updates `O(1)` dictionary writes.
- Big-O: `O(1)` per update (string truncation `O(len)`).
- Acceptance: Cannot exceed max_length; single-select replaces, multi-select accumulates/removes.
- Tests: `ViewModelTests.test_maxLengthBlocksOverflow()`, `test_singleSelectReplaces()`, `test_multiSelectTogglesMembership()`.

### Phase D — Validation

#### D1 · Validator
**Commit:** `feat: validation engine`
- Spec: `Validator.validate(fields:values:) -> [String: String]` (fieldId → error message). Rules: `required` empty → use `error_message` or a sensible default; `TEXT` with `regex` → must match (compile once); `max_length` already enforced at input but re-checked. Multi-select required → at least one. Empty-options required dropdown → it's unselectable; **decision**: mark invalid with a clear message (see §7).
- Big-O: `O(n)` over fields; regex compile cached per field `O(1)` reuse.
- Acceptance: Missing required → mapped error; bad regex value → error; valid form → empty error map.
- Tests: `ValidationTests`: required-missing, required-present, regex-pass, regex-fail, multiselect-required-empty, invalid-regex-pattern-in-json-is-ignored-safely.

#### D2 · Submit
**Commit:** `feat: submit + payload print`
- Spec: `validateAndSubmit()` sets `errors`; if empty, build `[String: Any]` of non-empty values, `print` JSON, set `confirmation` for an alert. Scalars vs arrays preserved (`campaign_name:String`, `ad_networks:[String]`, `accept_legal:Bool`).
- Big-O: `O(n)` build.
- Acceptance: Console prints valid JSON-shaped dict; alert shows; invalid blocks submit and surfaces errors.
- Tests: `ViewModelTests.test_submitBlockedWhenInvalid()`, `test_submitPayloadShapeMatchesValues()`.

### Phase E — Views (component rendering)

#### E1 · Theming applied + FormScreen shell
**Commit:** `feat: themed form screen`
- Spec: `FormScreen` reads `orderedFields`, paints `ResolvedTheme` background/text, renders `form_title`, a scrollable list of `FieldRowView`, and a Save button. Error/empty/load-failure states handled.
- Acceptance: Dark All-in-One theme renders; light sample renders; load failure shows friendly message.
- Tests: snapshot-free — manual check in G5 + `ViewModelTests` already cover state. (No fragile UI tests required.)

#### E2 · Text components (5 subtypes) + character counter
**Commit:** `feat: text field component`
- Spec: route subtype → PLAIN `TextField`; MULTILINE `TextField(axis:.vertical)` or `TextEditor`; NUMBER `.keyboardType(.decimalPad)`; URI `.keyboardType(.URL)` + no autocap; SECURE `SecureField`. Show `placeholder` only if present. Show `CharacterCounterView` only if `max_length` present (`count/max`, error color when at limit). Bind to ViewModel via intent.
- Acceptance: Each subtype behaves; counter appears only with max_length; SECURE masks.
- Tests: covered by C2/D1 for logic; manual G5 for keyboard types.

#### E3 · Dropdown (single + multi)
**Commit:** `feat: dropdown component`
- Spec: `Menu`/`Picker` showing `label`s; selecting stores `id`. `allow_multiple` → checkmark rows, multi membership. Closed state shows resolved labels (`O(1)` via id→label map). Empty options → disabled control with a hint.
- Acceptance: Label shown / id stored; multi works; empty options safe.
- Tests: logic covered in C2/D1.

#### E4 · Toggle & Checkbox
**Commit:** `feat: toggle + checkbox components`
- Spec: `ToggleComponent` = `Toggle` honoring default. `CheckboxComponent` = tappable box + label honoring `required`.
- Acceptance: both reflect & mutate state.

### Phase F — Optional enhancements (all in scope)

#### F1 · Rich-text checkbox links
**Commit:** `feat: clickable metadata links in checkbox`
- Spec: Build `AttributedString` from label; for each `metadata` key found as a substring, style it with `clickable_text_color` (override) else theme accent, attach the URL; tap opens in Safari (`openURL`/`SFSafariViewController`). Keys not found in label → ignored. Malformed URL → non-clickable, no crash.
- Big-O: `O(L·k)` substring scan, documented.
- Acceptance: ToS/Privacy links clickable & colored; opening works; missing substring safe.
- Tests: `RichTextTests.test_linkRangesResolved()`, `test_missingSubstringIgnored()`, `test_malformedURLNotClickable()`.

#### F2 · Regex validation wired to UI
**Commit:** `feat: regex validation UX`
- Spec: D1 regex rule surfaced inline under the field; compile once and cache. Invalid regex *pattern* in JSON → treat field as having no regex (log, don't crash).
- Acceptance: URI regex example passes/fails correctly; bad pattern ignored.
- Tests: extend `ValidationTests` (done in D1) + UI manual check.

#### F3 · Focus management toolbar
**Commit:** `feat: keyboard Next/Done toolbar`
- Spec: `@FocusState` over an ordered list of text-field ids; toolbar **Next** advances, **Done** dismisses. Order follows `orderedFields` text fields only.
- Big-O: `O(1)` next via index map.
- Acceptance: Next cycles through text fields in visual order; Done dismisses.
- Tests: focus order derivation unit-tested: `FocusTests.test_focusOrderMatchesVisualOrder()`.

#### F4 · Parsing test hardening
**Commit:** `test: polymorphic parsing edge cases`
- Spec: Consolidate/extend decoding tests to cover the full edge-case matrix (§7). Add fixtures for missing arrays, conflicting constraints, unknown types.
- Acceptance: All §7 rows have a passing test.

### Phase G — Polish & submission

#### G-DOC · README + AI log + demo
**Commit:** `docs: README, AI log, demo`
- Spec: `README.md` with: approach & architecture, **2–3 product/edge-case decisions** (pull from §7) + rationale, "what I'd improve with more time," and "what I got stuck on." `AI_COLLABORATION_LOG.md` capturing prompts/iterations/pushbacks. Record 30–60s demo (sample + All-in-One payloads, validation, link tap, focus toolbar). Make repo **public**.
- Acceptance: All four deliverables present; repo public; demo shows resilience on All-in-One payload.

---

## 7. Edge-case & product-decision matrix (decide once, cite in README)

| # | Situation (from brief / All-in-One payload) | Decision | Where enforced |
|---|---|---|---|
| 1 | `default_value` longer than `max_length` (campaign_name: 49 chars vs max 20) | **Truncate to max_length** on seed; counter shows `20/20`. Pre-filled state must itself obey the constraint. | C1 |
| 2 | Unknown `type` (`COLOR_PICKER`, `DATE_PICKER`) | Decode to `.unsupported`, **exclude from render**, keep rest of form. | B1/B2 |
| 3 | `DROPDOWN` with empty `options:[]` but `required:true` (billing_account) | Render disabled control + hint; on submit mark **invalid** ("No options available — cannot satisfy required field"). Surfaces the conflict instead of silently passing. | D1/E3 |
| 4 | Unknown `subtype` for TEXT | Fallback to `PLAIN`. | B1 |
| 5 | Missing optional keys (placeholder, max_length, error_message) | Render without them; no counter, generic required message. | E2 |
| 6 | Missing/empty `fields` array | Render empty form with title, Save disabled or no-op valid. | B2 |
| 7 | Duplicate/garbage `order` or missing `order` | Stable sort; missing order → treat as `Int.max` (renders last), tie-break by decode index. | C1 |
| 8 | Invalid hex in theme | Fall back to safe default color per channel. | A2 |
| 9 | `default` selection id not in `options` | Drop it from initial selection. | C1 |
| 10 | Malformed `metadata` URL or key not in label | Render text non-clickable; ignore unmatched key. | F1 |
| 11 | Invalid `regex` pattern string in JSON | Ignore the rule (log), never crash. | D1/F2 |
| 12 | Single malformed field element mid-array | Skip that element only; decode the rest. | B2 |
| 13 | Validation timing | Validate **on Save press** (not live) for required/regex; max_length enforced live at input. Clear, predictable, matches brief's "Save button" guidance. | D1/C2 |

**README must explicitly discuss at least #1, #3, and #13** (the most interesting non-obvious calls).

---

## 8. Definition of Done (final gate before submit)

- [ ] All §2 checkboxes satisfied.
- [ ] App runs on a clean iOS 16.0 simulator; no crashes on sample **and** All-in-One payloads.
- [ ] Every function has a complexity comment; no `O(n²)` field scans.
- [ ] Models/Parsing/Validation contain **no `import SwiftUI`**.
- [ ] Test suite green; covers every row in §7.
- [ ] No force-unwraps or `try!` on any JSON-derived path.
- [ ] Theme applied from JSON (verified by swapping payloads).
- [ ] Submit prints correct key-value JSON + shows alert.
- [ ] README, `AI_COLLABORATION_LOG.md`, demo video done; repo **public**; emailed to rahul.pawar+recruiting@eulerity.com.

---

## 9. Suggested commit / branch hygiene

- One feature branch per phase (`phaseB-parsing`), squash-or-merge to `main` after G5.
- Conventional commits (`feat:`, `test:`, `fix:`, `docs:`, `chore:`) — already shown per task.
- Tag `v1.0-submission` at the end. Keep history readable; reviewers will look.

---

## 10. Quick build order checklist (TL;DR for the terminal)

```
A1 scaffold ─▶ A2 theme/hex ─▶ B1 types ─▶ B2 decode ─▶ B3 loader
   ─▶ C1 state/defaults ─▶ C2 updates/maxlen ─▶ D1 validator ─▶ D2 submit
   ─▶ E1 screen ─▶ E2 text ─▶ E3 dropdown ─▶ E4 toggle/checkbox
   ─▶ F1 links ─▶ F2 regex ─▶ F3 focus ─▶ F4 parse-hardening
   ─▶ G-DOC readme/log/demo ─▶ §8 Definition of Done ─▶ submit
```

Run each through the §3 five gates. Write the tests in the same task. Don't move on until G5 is green.
