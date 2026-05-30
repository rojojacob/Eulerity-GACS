<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

# Eulerity — Dynamic Form Builder (Server-Driven UI)

A single-screen, **fully-offline** SwiftUI app whose entire UI is rendered from a **bundled
JSON payload** (`Resources/form_payload.json`). It parses a polymorphic field list, applies a
JSON-defined theme, collects input with live + on-save validation, and prints/alerts the
resulting key-value payload — never crashing on malformed or unknown input.

## Sources of truth (read these first)

- **`/Plan.md`** — the authoritative, task-by-task build plan (the *what*). Work through its
  §6/§10 task order; do not skip the §3 gates.
- **`.specify/memory/constitution.md`** — the governing principles (the *how*).
- This file — day-to-day operational guide; it MUST stay consistent with both.

## Tech Stack

- **Swift + SwiftUI**, MVVM. **Minimum deployment target: iOS 16.0** → ViewModels use
  `ObservableObject` + `@Published` (the iOS-17 `@Observable` macro is **not** used).
- **No networking, no third-party dependencies** (Constitution III). JSON is read from the app
  bundle. Apple frameworks only.
- **Concurrency**: main-actor-by-default isolation. UI/ViewModels are `@MainActor`; pure value
  types are `nonisolated` + `Sendable`. Note: `nonisolated` on a type does **not** propagate to
  members in a separate `extension` — annotate those members individually.
- **Testing**: Swift `Testing` framework (`@Suite` / `@Test` / `#expect`), written in the same
  task as the code (Plan.md §3 G4).
- Xcode 26 project (`objectVersion = 77`) with **file-system-synchronized groups** — files added
  under `Eulerity/` or `EulerityTests/` are auto-included; no `project.pbxproj` editing needed
  for sources or for bundling JSON in `Resources/`.

## Architecture & Project Structure

Strict one-directional MVVM (Views → ViewModels → Models/Parsing/Validation). **No
`import SwiftUI`** in Models, Parsing, Validation, or the model side of Theming.

```text
Eulerity/
├── App/EulerityApp.swift        # @main → FormScreen (composition root)
├── Resources/form_payload.json  # bundled payload (representative sample for now)
├── Models/                      # FormPayload, FormField, FieldType, FieldValue, ThemeModel …
├── Parsing/                     # FormDecoder (polymorphic, skip-unknown), FormLoader
├── Theming/                     # HexColorParser (pure), ResolvedTheme (SwiftUI presentation)
├── Validation/                  # Validator (required / regex / max_length / conflicts)
├── Support/ViewState.swift      # load-state enum (idle/loading/loaded/failed)
├── ViewModels/                  # FormViewModel (+ LoadableViewModel base protocol)
└── Views/
    ├── FormScreen.swift         # app root screen
    ├── Components/              # TextField/Dropdown/Toggle/Checkbox components
    └── Support/StateView.swift  # renders a ViewState (loading/empty/error)

EulerityTests/                   # Swift Testing: Bundle, Decoding, Validation, Ordering, …
```

(Folders for not-yet-built layers currently hold a comment-only placeholder documenting what
goes there; replace it when the real files arrive.)

**Layer rules** (Constitution I): Views declarative only; ViewModels own state via `@Published`
and expose intents; Models/Parsing/Validation pure and SwiftUI-free.

## Conventions (non-negotiable)

- **Big-O on every function** (Constitution IV): one-line `// O(...)` comment per function;
  justify anything worse than `O(n log n)`. Use pre-built `[id: …]` maps / `Set`s — **never** a
  nested loop over `fields`. See Plan.md §5 for per-operation targets.
- **Never crash** (Constitution V): no force-unwraps / `try!` on JSON paths. Unknown `type` →
  excluded from render; one malformed field → skipped, rest survive; invalid hex/regex/URL →
  safe fallback. Every edge case in Plan.md §7 has a test.
- **Rendering**: sort fields by the `order` integer (stable tie-break by decode index), never by
  array index. DROPDOWN shows `label`, stores `id`.
- **Validation timing**: `max_length` enforced live at input; required/regex validated on
  **Save** (Plan.md §7 #13).
- **Tests in the same task**: write the failing Swift `Testing` case alongside the code; a task
  isn't done until it passes (G5).

## Shell Commands

Run from the repo root; a simulator destination is required (iOS-only app).

```bash
# List targets and schemes
xcodebuild -list -project Eulerity.xcodeproj

# Build the app
xcodebuild build -project Eulerity.xcodeproj -scheme Eulerity \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run the unit tests (Swift Testing)
xcodebuild test -project Eulerity.xcodeproj -scheme Eulerity \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# If "iPhone 16 Pro" is unavailable, list installed simulators
xcrun simctl list devices available | grep iPhone
```

The shared scheme `Eulerity` (in `xcshareddata/xcschemes/`) wires `EulerityTests` into the Test
action, so `xcodebuild test -scheme Eulerity` builds and runs the suite.

## Workflow

`/Plan.md` drives the build, one task at a time through the **5-gate loop** (G1 Spec → G2
Approve → G3 Implement → G4 Test → G5 Verify); commit on green G5 with the task's conventional
prefix. The Spec Kit feature artifacts live at **`specs/001-dynamic-form-builder/`**
(`spec.md` → `plan.md` → `tasks.md`). Git auto-commit hooks are configured in
`.specify/extensions.yml`.
