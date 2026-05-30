# Feature Specification: Dynamic Form Builder (Server-Driven UI)

**Feature Branch**: `feature/001-dynamic-form-builder`

**Created**: 2026-05-30

**Status**: Draft

**Input**: `/Plan.md` (single source of truth) + the Eulerity GACS iOS take-home brief.

> This spec is the technology-agnostic *what/why*. The *how* (Swift/SwiftUI, layering, Big-O)
> lives in `plan.md`; the executable task order lives in `tasks.md` and `/Plan.md` §6/§10.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fill out and submit a server-defined form (Priority: P1)

A user opens the app and is shown a form they have never seen compiled into the app: its title,
fields, ordering, options, default values, and colors all come from a JSON payload. The user
edits the fields and taps **Save**; on success the collected values are emitted.

**Why this priority**: This is the product. Without faithful rendering + submit there is no app.

**Independent Test**: Load the bundled sample payload; verify every field renders with the right
control and the values from `default_value`/`default_values`; edit a field; tap Save; confirm
the printed key-value payload matches the on-screen state and a confirmation alert appears.

**Acceptance Scenarios**:

1. **Given** a payload with `TEXT`, `DROPDOWN`, `TOGGLE`, `CHECKBOX` fields, **When** the screen
   loads, **Then** each renders with its correct control, label, and (if present) placeholder,
   in ascending `order`.
2. **Given** a `TEXT` field with `max_length`, **When** the user types past the limit, **Then**
   input is blocked at the limit and a live `count/max` counter is shown.
3. **Given** a `DROPDOWN`, **When** the user selects an option, **Then** the UI shows the
   option's `label` while the stored state holds its `id`.
4. **Given** a valid, fully-filled form, **When** the user taps Save, **Then** the final
   key-value pairs are printed to the console (scalars vs arrays preserved) **and** a
   confirmation alert is shown.
5. **Given** a form with a missing required field, **When** the user taps Save, **Then** submit
   is blocked and the missing field is clearly flagged.

### User Story 2 - Survive hostile / unknown payloads (Priority: P2)

A user (or QA) loads a payload containing unknown field types, missing keys, conflicting
constraints, and malformed values. The app renders what it can and **never crashes**.

**Why this priority**: Resilience to server-driven input is the core engineering signal of the
exercise (Plan.md §0, §5–§7).

**Independent Test**: Load the "All-in-One" payload; confirm unknown types are absent from the
UI, the rest of the form renders, and no path crashes.

**Acceptance Scenarios**:

1. **Given** a field with an unknown `type` (`COLOR_PICKER`, `DATE_PICKER`), **When** decoding,
   **Then** it is excluded from render and the remaining fields still appear.
2. **Given** a single malformed field element mid-array, **When** decoding, **Then** that element
   is skipped and the other fields decode successfully.
3. **Given** invalid theme hex, an invalid `regex` pattern, or a malformed metadata URL, **When**
   rendering/validating, **Then** a documented safe fallback is used and nothing crashes.
4. **Given** a `DROPDOWN` that is `required` but has empty `options`, **When** the user taps Save,
   **Then** it is surfaced as invalid with a clear message rather than silently passing.
5. **Given** a missing/empty `fields` array, **When** loading, **Then** an empty titled form is
   shown without error.

### User Story 3 - Enhanced interactions (Priority: P3)

The user benefits from rich-text legal links, custom regex validation, and a keyboard toolbar
that cycles text fields.

**Why this priority**: Optional enhancements; all in scope but layered on the working core.

**Acceptance Scenarios**:

1. **Given** a `CHECKBOX` whose `metadata` keys appear as substrings of the label, **When** the
   user taps a key, **Then** that styled substring opens its URL in Safari.
2. **Given** a `TEXT` field with a `regex`, **When** the value does not match on Save, **Then** an
   inline error is shown.
3. **Given** multiple text fields, **When** the keyboard is shown, **Then** a **Next** button
   advances through them in visual order and **Done** dismisses the keyboard.

### Edge Cases

The full matrix is Plan.md §7 (13 rows). Highlights: default value longer than `max_length`
(truncate on seed); unknown `type`/`subtype` (exclude / fall back to `PLAIN`); empty-options
required dropdown (mark invalid); duplicate/missing `order` (stable sort, missing → last);
invalid hex/regex/URL (safe fallback); default selection id not in options (drop it).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST parse `type` and render `TEXT`, `DROPDOWN`, `TOGGLE`, and `CHECKBOX`.
- **FR-002**: System MUST parse `TEXT` `subtype` `PLAIN`, `MULTILINE`, `NUMBER`, `URI`, `SECURE`
  and present the appropriate input affordance; unknown subtype falls back to `PLAIN`.
- **FR-003**: System MUST apply optional keys (`placeholder`, `error_message`, `max_length`)
  only when present.
- **FR-004**: System MUST prevent input beyond `max_length` and show a live character counter.
- **FR-005**: `DROPDOWN` MUST display option `label` while storing option `id`; with
  `allow_multiple == true` it MUST support multi-select.
- **FR-006**: `TOGGLE` and `CHECKBOX` MUST honor `default_value`; `CHECKBOX` MUST honor `required`.
- **FR-007**: System MUST sort fields by the integer `order` (stable tie-break by decode index),
  never by array position.
- **FR-008**: System MUST parse `theme` hex codes into background, text, border/accent, and error
  colors, with a safe fallback per channel on invalid hex.
- **FR-009**: System MUST hold all dynamic field state in an observable view model.
- **FR-010**: On Save, System MUST flag missing required fields and block submit.
- **FR-011**: On a valid Save, System MUST print the final key-value pairs (scalars vs arrays
  preserved) to the console AND show a confirmation alert.
- **FR-012**: System MUST ignore unknown `type` gracefully (exclude from render, never crash).
- **FR-013**: System MUST never crash on malformed, missing, conflicting, or unknown JSON, and
  MUST contain no force-unwraps/`try!` on any JSON-derived path.
- **FR-014** *(enhancement)*: `CHECKBOX` rich text — `metadata` keys found in the label become
  clickable links opening in Safari, honoring `clickable_text_color`.
- **FR-015** *(enhancement)*: `TEXT` MUST support custom `regex` validation surfaced inline.
- **FR-016** *(enhancement)*: A keyboard toolbar MUST provide Next/Done cycling of text fields in
  visual order.
- **FR-017** *(enhancement)*: Test suite MUST cover polymorphic parsing and malformed data.

### Key Entities

- **FormPayload**: top-level — `form_title`, `theme`, ordered `fields`.
- **FormField**: a single field — shared keys (`id`, `order`, `type`, `label`, `required`) plus
  optional type-specific keys; exposes a computed `kind`.
- **FieldType / TextSubtype**: the known type/subtype taxonomy plus an `.unsupported` case.
- **DropdownOption**: `{ id, label }`.
- **ThemeModel**: raw hex strings for background/text/border/error.
- **FieldValue**: the runtime value of a field — text, bool, or a selection of option ids.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The app renders both the brief's sample payload and the "All-in-One" payload with
  zero crashes on a clean iOS 16 simulator.
- **SC-002**: 100% of the Plan.md §7 edge-case rows are covered by a passing automated test.
- **SC-003**: Every required-field and validation rule is enforced on Save (no invalid submit
  succeeds; no valid submit is blocked).
- **SC-004**: Swapping the bundled JSON for a differently-themed payload changes the rendered
  theme with no code changes.
- **SC-005**: No function exceeds its Plan.md §5 complexity target; no nested O(n²) scan over
  `fields` exists.

## Assumptions

- The form is a single screen; payloads are loaded from the app bundle (no network).
- The bundled `Resources/form_payload.json` is currently a representative sample; the official
  "sample" and "All-in-One" payloads from the brief will replace/supplement it.
- Field `id`s are unique within a payload.
- Validation runs on Save for required/regex; `max_length` is enforced live at input.
- Minimum iOS 16.0; Swift + SwiftUI only; no third-party packages.
