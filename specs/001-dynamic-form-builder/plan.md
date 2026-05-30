# Implementation Plan: Dynamic Form Builder (Server-Driven UI)

**Branch**: `feature/001-dynamic-form-builder` | **Date**: 2026-05-30 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `./spec.md` + `/Plan.md` (authoritative task plan).

## Summary

Render a single SwiftUI screen entirely from a bundled JSON payload: decode a polymorphic field
list defensively, sort by `order`, apply a JSON theme, collect input with live `max_length` +
on-Save required/regex validation, and emit the resulting key-value payload. The whole system is
offline, dependency-free, MVVM-layered, and resilient to malformed/unknown input.

## Technical Context

**Language/Version**: Swift 5 language mode (toolchain Swift 6.2), Xcode 26.

**Primary Dependencies**: None — Apple frameworks only (SwiftUI, Foundation). No networking.

**Storage**: App bundle JSON (`Resources/form_payload.json`); no persistence.

**Testing**: Swift `Testing` framework (`@Suite`/`@Test`/`#expect`), host-app unit test target
`EulerityTests`, written in the same task as the code (Plan.md §3 G4).

**Target Platform**: iOS 16.0+ (iPhone/iPad).

**Project Type**: Single mobile app (one target + one unit-test target).

**Performance Goals**: Smooth 60 fps; all per-operation costs at their Plan.md §5 targets.

**Constraints**: No crashes on any payload; no force-unwraps/`try!` on JSON paths; no
`import SwiftUI` in Models/Parsing/Validation; every function carries a `// O(...)` comment.

**Scale/Scope**: One screen; ~4 base field types + 5 text subtypes; ≤ ~15 fields per payload;
all 4 optional enhancements in scope.

## Constitution Check

*GATE: Must pass before implementation. Re-check after each task's G5.*

- [x] **I. MVVM Architecture** — Views declarative; `FormViewModel` (`@MainActor`,
      `ObservableObject`) owns state; Models/Parsing/Theming(model)/Validation are SwiftUI-free.
- [x] **II. Tests In The Same Task** — every parser/validator/view-model task ships its Swift
      `Testing` cases in the same task; fixtures only, no live I/O.
- [x] **III. First-Party & Fully Offline** — no dependencies, no networking; JSON from bundle.
- [x] **IV. Algorithmic Efficiency** — pre-built `[id:label]` / `[id:FieldValue]` maps and
      `Set`s; `// O(...)` on every function; see Complexity Tracking.
- [x] **V. Defensive Resilience** — unknown type excluded; malformed element skipped; invalid
      hex/regex/URL fall back safely; typed `FormLoadError`.
- [x] **VI. Simplicity & YAGNI** — flat `FormField` struct + computed `kind`; no speculative
      abstraction.

No violations — Complexity Tracking is informational (Plan.md §5 targets), not justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-dynamic-form-builder/
├── spec.md      # the what/why
├── plan.md      # this file
└── tasks.md     # dependency-ordered tasks (mirrors /Plan.md §6)
```

### Source Code (repository root)

```text
Eulerity/
├── App/EulerityApp.swift          # @main → FormScreen
├── Resources/form_payload.json    # bundled payload
├── Models/                        # FormPayload, FormField, FieldType, FieldValue, ThemeModel, DropdownOption
├── Parsing/                       # FormDecoder (polymorphic, skip-unknown), FormLoader (Result<…, FormLoadError>)
├── Theming/                       # HexColorParser (pure), ResolvedTheme (SwiftUI presentation)
├── Validation/                    # Validator (required / regex / max_length / conflicts)
├── Support/ViewState.swift        # load-state enum
├── ViewModels/                    # FormViewModel (+ LoadableViewModel base)
└── Views/
    ├── FormScreen.swift
    ├── Components/                # TextField / Dropdown / Toggle / Checkbox components
    └── Support/                   # StateView, CharacterCounterView, KeyboardToolbar

EulerityTests/                     # Bundle / Decoding / Validation / HexColorParser / Ordering / ViewModel / RichText / Focus
```

**Structure Decision**: Single-app MVVM with pure model/parsing/validation layers (no SwiftUI)
and a thin presentation layer for theming. Matches Plan.md §4 inside the existing `Eulerity`
target (kept name; no rename). The networking layer from the initial generic skeleton was
removed — this app is offline by design.

## Complexity Tracking

> No Constitution violations. Table records the §5 per-operation complexity contract.

| Operation | Target | Approach |
|-----------|--------|----------|
| Sort fields by `order` | O(n log n) | one `sorted(by:)`, stable tie-break on decode index |
| Field lookup / update by `id` | O(1) | `[String: FieldValue]` dictionary, never linear scan |
| Dropdown label for selected `id` | O(1) | pre-built `[id: label]` map per dropdown at decode |
| Validation pass on Save | O(n) | single pass; each rule O(1)/O(len); regex compiled once |
| `max_length` enforcement | O(1) amortized | `onChange` prefix-truncate |
| Build submit payload | O(n) | single pass over non-empty values |
| Rich-text link ranges | O(L·k) | L = label length, k = metadata keys (documented) |
