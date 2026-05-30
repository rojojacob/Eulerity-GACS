# Eulerity — Dynamic Form Builder (Server-Driven UI)

A single-screen, **fully-offline** SwiftUI app whose entire UI is rendered from a bundled JSON
payload. It decodes a polymorphic field list, applies a JSON-defined theme, collects input across
five text subtypes plus dropdowns, toggles, and checkboxes, validates live + on Save, and emits the
final key-value payload — and it's built to **never crash** on malformed, missing, conflicting, or
unknown JSON.

Stack: **SwiftUI · MVVM · iOS 16+ · Swift Testing · zero third-party dependencies.**

---

## Getting Started

**Requirements**
- Xcode 26 (Swift 6.2 toolchain); deployment target **iOS 16.0+**.
- No dependencies to resolve — pure Apple frameworks (SwiftUI, Foundation). Just open and run.

**Build & run**
- Open `Eulerity.xcodeproj`, pick an iPhone simulator, and Run. Or from the CLI:
  ```bash
  xcodebuild build -project Eulerity.xcodeproj -scheme Eulerity \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
  ```

**Run the tests** (~79 Swift Testing cases covering decoding, theming, validation, view-model
behavior, and the edge-case matrix):
  ```bash
  xcodebuild test -project Eulerity.xcodeproj -scheme Eulerity \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
  ```

**Swap the payload** — the whole form is driven by `Eulerity/Resources/form_payload.json`. Replace
its `theme`/`fields` and re-run; no code changes needed.

---

## Approach & Architecture

The guiding idea is a one-directional pipeline that turns untrusted JSON into a themed, validated
form without ever letting bad data reach the UI or crash the app:

```
form_payload.json
   → FormLoader            (bundle → Data, typed Result, never throws to the UI)
   → FormPayload/FormField (defensive, element-by-element decode; skip unknown/malformed)
   → FormViewModel         (sort by `order`, seed defaults, hold @Published state)
   → FormScreen/FieldRowView (themed render via ResolvedTheme; route each field to a component)
   → Validator             (on Save → field-id → error map)
   → submit payload        (typed [String: SubmitValue] → printed JSON + confirmation alert)
```

**MVVM with strict layers.** Views are declarative and dumb; the `FormViewModel`
(`@MainActor`, `ObservableObject`) owns all mutable state and the intent methods; the
**Models, Parsing, Theming (model side), and Validation are pure Swift with no `import SwiftUI`** —
so the core is deterministic and unit-testable in isolation. Colors only materialize in a thin
presentation type (`ResolvedTheme`).

**Fully offline by design.** The payload ships in the app bundle; there is deliberately no
networking layer and no third-party packages. The "server-driven" behavior is entirely
local JSON → defensive decode → state → UI.

**Defensive resilience is the core principle.** There are **no force-unwraps or `try!` on any
JSON-derived path.** Unknown field `type`s decode to `.unsupported` and are excluded from render; a
single malformed field element is skipped while the rest of the form decodes; invalid hex, regex,
or URLs each fall back to a documented safe behavior. The form is only as trustworthy as its worst
payload, so the worst payload is handled.

**Performance / Big-O discipline.** Every function carries a one-line complexity comment. Lookups
use pre-built `[id: label]` and `[id: FieldValue]` maps and `Set`s rather than scanning `fields`
(no `O(n²)`), regexes are compiled once and reused, and the field order is a single `O(n log n)`
stable sort.

**Concurrency.** The project uses Xcode 26's main-actor-by-default isolation: UI and the view model
are `@MainActor`, while the pure value/logic types are explicitly `nonisolated` + `Sendable` so they
can be exercised from the (nonisolated) test target without ceremony.

---

## Project Structure

```text
Eulerity/
├── App/            EulerityApp — composition root (@main → FormScreen)
├── Resources/      form_payload.json — the bundled, swappable payload
├── Models/         FormPayload, FormField (+ FieldKind), FieldType, TextSubtype,
│                   DropdownOption, FieldValue, ThemeModel, SubmitValue, BillingCard
├── Parsing/        FormLoader (+ FormLoadError); polymorphic decode lives in the model inits
├── Theming/        HexColorParser (pure, O(1)) · ResolvedTheme (JSON hex → SwiftUI Color)
├── Validation/     Validator (required / regex / max_length / multi-select / conflicts)
├── Persistence/    CardStore — local billing cards (UserDefaults)
├── Support/        ViewState · RichTextLabel (clickable metadata links)
├── ViewModels/     FormViewModel (ordering, seeding, intents, validation, submit)
└── Views/          FormScreen · FormContentView · FieldRowView
    ├── Components/  TextField · Dropdown · Toggle · Checkbox · BillingAccount
    └── Support/     StateView · CharacterCounterView · ThemedFieldStyle

EulerityTests/      ~79 Swift Testing cases
```

---

## Product Decisions

The brief asked for 2–3 non-obvious calls; I ended up making several, since a resilient
server-driven form has a lot of "what should happen when…" gaps. The most interesting:

1. **A `default_value` longer than `max_length` is truncated on seed.** The pre-filled state must
   itself obey the field's constraint, so a 47-character default in a `max_length: 20` field seeds
   as exactly 20 characters (and the counter reads `20/20`). The alternative — showing an
   over-limit value the user can't have typed — would be inconsistent the moment they edited.

2. **A required dropdown with empty `options` can't be satisfied from the payload, so I added a
   local "add a billing account" flow.** Rather than silently passing an unsatisfiable field (a
   data bug hidden from the user) or leaving it permanently invalid, tapping the field opens a
   bottom sheet to enter a card (name / number / exp / CVV), saved cards are listed and selectable,
   and a selected card satisfies the field. Cards are **persisted locally** (`UserDefaults`). Until
   a card is added, validation still surfaces the field as incomplete, so submit stays blocked.

3. **Validation timing: required/regex on Save, `max_length` live.** Required fields and custom
   regex are validated on the **Save press** — predictable, and it matches the brief's "Save button"
   guidance — while `max_length` is enforced live at input (you can't type past the limit). Mixing
   "block on input" for the hard constraint with "flag on submit" for the soft ones keeps the form
   from nagging mid-typing.

4. **Unknown/malformed JSON degrades gracefully, never fatally.** An unknown field `type`
   (`COLOR_PICKER`, `DATE_PICKER`) decodes to `.unsupported` and is excluded from render; one
   malformed field element is skipped while the rest of the payload decodes; invalid theme hex,
   regex patterns, and metadata URLs each fall back to a safe default. The fields render sorted by
   the `order` integer (stable tie-break, missing order → last), never by array position.

5. **A missing `placeholder` falls back to the field's label.** Leaving an input visually blank is
   ambiguous, so when a text field declares no placeholder I use its `label` as the placeholder —
   the field always tells the user what it's for.

6. **Placeholder color is standardized from the theme.** Placeholders looked inconsistent (some
   light, some dark) because SwiftUI's default depends on the environment. I derive one consistent
   placeholder color from the theme's text color (a faded variant) so every field reads the same on
   any background.

---

## What I'd Improve With More Time

- **Card security.** The local billing flow stores the full PAN and CVV in `UserDefaults` purely to
  satisfy the "save locally" requirement — this is **not** secure. A real implementation would
  tokenize through a payment SDK (or at minimum store a token in the Keychain) and never persist the
  raw card number or CVV. I flagged this in `BillingCard`'s doc comment so it isn't mistaken for
  production-ready.
- **Snapshot / UI-automation tests.** The logic layer is well covered by unit tests, but the SwiftUI
  views are verified by hand/screenshot. I'd add snapshot tests for each component and a small
  XCUITest happy-path so UI regressions are caught automatically.
- **Theme adaptivity + iOS 26 polish.** Auto-derive the navigation-bar and keyboard color scheme
  from the theme background's luminance (so a light payload theme gets dark controls and vice
  versa), and continue hardening the dropdown behavior reported on iOS 26 — I already moved it off
  `Menu` to a sheet, but I'd test across more device/OS combinations.

---

## What I Got Stuck On

**The character that wouldn't go away.** For a `max_length` field, my first implementation routed
keystrokes through the view model, which truncated the value — and the unit tests passed, because
the *value* was correctly capped. But when I ran the app and typed past the limit, the field
**visibly showed more than 20 characters while the counter still read `20/20`.** The value was
right; the display wasn't.

The cause is a subtle SwiftUI trap: when a binding's setter produces a value equal to the previous
one (truncating "20 chars + 1" back to the same 20 chars), SwiftUI sees "no change" and doesn't push
the corrected text back into the field — so the extra keystroke lingers on screen even though it
never reaches the model.

Two things got me through it. First, **I only caught it because I was verifying on-device with a
screenshot, not just trusting the green tests** — the divergence between value and display was
invisible to the test suite. Second, the fix was to stop fighting the binding: I bound the text
field to **local `@State`** and, on any over-limit edit, rewrote that state to the capped value —
which *forces* the field to drop the extra character — while still mirroring the capped value into
the view model so validation and submit stay correct. After that, typing 16 extra characters into a
full field changes nothing on screen. The lesson I took: tests prove logic, but UI needs to be
*seen*, and when a control won't reflect your model, take ownership of its local state rather than
hoping the binding reverts.

---

## AI Tools Used

This project was built with heavy, deliberate AI assistance, with each tool assigned a specific
role rather than used interchangeably:

- **Claude Code (Anthropic, Opus 4.8)** — the primary agent, used in two modes:
  - In the **Cowork** app to draft `Plan.md` — driving requirement-gathering through its
    **AskUserQuestion** tool to turn a loosely-defined brief into a concrete, task-by-task plan,
    complete with a per-operation Big-O table and an edge-case / product-decision matrix.
  - As the **coding agent** — scaffolding the Xcode project, structuring the MVVM folders, and
    implementing each task through a *spec → implement → test → verify* loop, running the toolchain
    itself so every change was backed by a real build and test run rather than just generated code.
- **Claude Code via the VS Code IDE (integrated terminal)** — to run the same agent from inside the
  editor/terminal workflow, keeping the code, the terminal, and the AI loop in one place.
- **Spec Kit (spec-driven development)** — to author the project **constitution** and generate the
  `spec.md` / `plan.md` / `tasks.md` artifacts. Working spec-first keeps the agent token-efficient
  and makes every change traceable back to a stated requirement.
- **XcodeBuildMCP** — to build, boot a simulator, install/launch the app, drive **UI automation**
  (taps and typing), capture **screenshots**, and connect to testing agents — so UI behavior was
  verified live on a device instead of assumed.
- **ChatGPT** (with the **Adobe Photoshop** and **Make-a-Viz** add-ons) — to generate the project's
  architecture / flow diagram.
- **Google Gemini** — to generate representative **test JSON payloads** (varied field types,
  subtypes, and edge cases) for exercising the decoder and validator.
- **Google Gemini** — to help draft project **documentation**.

Practices that shaped how these tools were used:

- **Human-in-the-loop decisions.** AskUserQuestion was used at every fork — iOS version,
  dependencies, test framework, project naming, which product decisions to feature — so the AI
  *proposed* and I *decided*; it never made product calls on its own.
- **Verify by running, not by faith.** Every task was gated on a green build and the Swift Testing
  suite (~79 cases) before being considered done, and compiler warnings were treated as errors.
- **A full collaboration record.** The prompt-by-prompt history — including where I accepted the
  AI's suggestions versus pushed back, and the bugs it got wrong and how they were fixed — is in
  [`AI_COLLABORATION_LOG.md`](AI_COLLABORATION_LOG.md), with a chronological timeline in
  [`SESSION_HISTORY.md`](SESSION_HISTORY.md).
