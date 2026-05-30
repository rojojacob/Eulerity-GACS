<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 (finalized to match Plan.md — supersedes the same-session initial draft)
Bump rationale: First ratified constitution, aligned to the now-known project (Plan.md:
  Dynamic Form Builder — server-driven, fully offline SwiftUI app).

Principles (6 — added Defensive Resilience; reframed First-Party for an offline app):
  - I.   MVVM Architecture (Strict Layering)
  - II.  Tests In The Same Task (NON-NEGOTIABLE)
  - III. First-Party & Fully Offline
  - IV.  Algorithmic Efficiency (Big-O Discipline)
  - V.   Defensive Resilience (Never Crash)
  - VI.  Simplicity & YAGNI

Sections:
  - Technology & Platform Constraints (updated: offline, bundled JSON, validation-on-Save)
  - Development Workflow (Spec-Driven + Plan.md 5-gate loop)

Source of truth: /Plan.md (in repo root) drives the build; this constitution governs how.

Templates reviewed / updated:
  - .specify/templates/plan-template.md ............ ✅ Constitution Check lists all 6 principles
  - .specify/templates/tasks-template.md ........... ✅ tests REQUIRED (Principle II)
  - .specify/templates/spec-template.md ............ ✅ no change needed (technology-agnostic)

Runtime guidance:
  - CLAUDE.md ...................................... ✅ updated alongside this constitution

Deferred TODOs: none
-->

# Eulerity Constitution

Eulerity is a **single-screen, fully-offline SwiftUI app whose entire UI is driven by a
bundled JSON payload** (a "Dynamic Form Builder" / server-driven UI). The detailed,
task-by-task build plan lives in `/Plan.md` — the single source of truth for *what* to build.
This constitution governs *how* it is built. When the two appear to conflict, raise it; they
must be kept consistent.

## Core Principles

### I. MVVM Architecture (Strict Layering)

Four layers, one-directional dependencies (Views → ViewModels → Models/Services), each with a
single responsibility:

- **Views** are declarative. They render ViewModel state and forward user intents. No parsing,
  validation, or business logic inline.
- **ViewModels** are `@MainActor`, `ObservableObject` types that own all mutable state via
  `@Published`, orchestrate services, and expose intent methods (e.g. `updateText`,
  `validateAndSubmit`). They hold no `View` types.
- **Models, Parsing, Theming (model side), Validation** are pure Swift with **no
  `import SwiftUI`** — deterministic and unit-testable in isolation. The only theming code that
  imports SwiftUI is the thin `ResolvedTheme` presentation extension.

**Rationale**: Clear seams make each unit understandable and testable alone, and keep the JSON
→ state → UI pipeline honest.

### II. Tests In The Same Task (NON-NEGOTIABLE)

Tests are written with the Swift `Testing` framework **in the same task as the code they
cover** — never deferred. A task is not done until its named tests pass (Plan.md §3, gate G4).

- Every ViewModel, parser, validator, and pure helper has tests exercised through its API or
  protocol seam; tests perform no live network or disk I/O beyond reading bundled fixtures.
- Any bug found while implementing gets a regression test before it is fixed.
- A behavior change without accompanying passing tests MUST NOT be merged.

**Rationale**: Tests are the executable specification and the gate that lets the next task
start on solid ground.

### III. First-Party & Fully Offline

The app uses **only Apple frameworks** (Swift, SwiftUI, Foundation) with **zero third-party
dependencies** and **no networking**. The form payload is loaded from a JSON file in the app
bundle — there is deliberately no `URLSession`/API layer.

Introducing any external dependency or network call REQUIRES a constitution amendment with
explicit justification.

**Rationale**: Keeps the project lean and auditable, demonstrates command of the fundamentals,
and matches the exercise's offline, bundle-driven design.

### IV. Algorithmic Efficiency (Big-O Discipline)

Every function carries a one-line complexity comment (e.g. `// O(n) — single pass over
fields`). Anything worse than `O(n log n)` MUST be justified in the comment.

- Choose the right data structure deliberately: pre-built `[id: label]` / `[id: FieldValue]`
  maps and `Set` membership instead of linear scans. **Forbidden**: nested `O(n²)` scans over
  `fields` (a loop inside a loop over fields → replace with a pre-built map).
- Compile expensive resources once and reuse (e.g. `NSRegularExpression`).
- This is not a license for premature optimization: pick the simplest correct design
  (Principle VI), then ensure it is also asymptotically sound. See Plan.md §5 for the per-
  operation complexity targets.

**Rationale**: Predictable performance and a responsive UI are core goals; complexity made
explicit is complexity that can be reviewed.

### V. Defensive Resilience (Never Crash)

The app MUST never crash on malformed, missing, conflicting, or unknown JSON.

- **No force-unwraps (`!`) or `try!` on any JSON-derived path.** Failures surface as typed
  errors or safe fallbacks, never traps.
- Unknown `type`/`subtype` decode to a `.unsupported`/default case and are excluded from
  render rather than aborting the payload. A single malformed field element is skipped; the
  rest of the form still decodes.
- Missing optional keys, invalid hex, out-of-range defaults, bad regex patterns, and malformed
  URLs each degrade to a documented safe behavior (see the edge-case matrix, Plan.md §7).

**Rationale**: Resilience to hostile/server-driven input is the heart of this exercise; the UI
is only as trustworthy as its worst payload.

### VI. Simplicity & YAGNI

Build the smallest thing that satisfies the spec. No speculative abstraction and no feature
that cannot be traced to a requirement in Plan.md §2 or §6. Prefer value types and composition.

**Rationale**: Unused flexibility is pure cost — read, maintained, and reasoned about while
delivering nothing.

## Technology & Platform Constraints

- **Language/UI**: Swift + SwiftUI, MVVM. **Minimum deployment target: iOS 16.0** (no UIKit
  unless wrapping is unavoidable). Because iOS 16 is the floor, ViewModels use
  `ObservableObject` + `@Published` (the iOS-17 `@Observable` macro is not used).
- **Data**: JSON loaded from the app bundle (`Resources/form_payload.json`); no network.
- **Concurrency**: the app target uses main-actor-by-default isolation; UI and ViewModels are
  `@MainActor`, while pure value types are explicitly `nonisolated`/`Sendable`. Note:
  `nonisolated` on a type does not propagate to members in a separate `extension` — annotate
  those members individually.
- **Rendering rules**: fields are sorted by the `order` integer (stable tie-break by decode
  index) — never by array position. DROPDOWN shows `label` but stores `id`.
- **Validation timing**: `max_length` is enforced live at input; required/regex validation runs
  on **Save** (Plan.md §7 row 13).
- **Quality bar**: warning-free build for the iOS 16 simulator; every §7 edge case has a test.

## Development Workflow (Spec-Driven + 5-Gate)

- **`/Plan.md` is the single source of truth.** Work proceeds one task at a time in the
  dependency order of Plan.md §6/§10, each task run through the **5-gate loop** (Plan.md §3):
  **G1 Spec → G2 Approve → G3 Implement → G4 Test → G5 Verify.** A task is done only when G5 is
  green; commit then, using the task's `feat:`/`test:`/`fix:`/`chore:` prefix.
- **Spec Kit artifacts** formalize the feature for tooling: this feature lives at
  `specs/001-dynamic-form-builder/` (`spec.md` → `plan.md` → `tasks.md`), generated from
  Plan.md. The plan's **Constitution Check** gate MUST pass before implementation.
- If gate G2 surfaces a contradiction in the brief that cannot be resolved, **pause and ask the
  user** rather than guessing.

## Governance

This constitution supersedes other practices; when guidance conflicts, the constitution wins.

- **Amendments** MUST be proposed in writing with rationale, approved, and accompanied by any
  migration notes before taking effect.
- **Versioning** follows semantic versioning:
  - **MAJOR** — backward-incompatible governance changes or removal/redefinition of a principle.
  - **MINOR** — a new principle or section, or materially expanded guidance.
  - **PATCH** — clarifications and wording fixes with no semantic change.
- **Compliance** is verified at code review and at gate G5; unjustified violations block the
  task. Complexity that appears to break a principle MUST be justified in the plan's Complexity
  Tracking table or removed.
- **Runtime guidance** for day-to-day development and AI agents lives in `CLAUDE.md`, which MUST
  stay consistent with this constitution and with `/Plan.md`.

**Version**: 1.0.0 | **Ratified**: 2026-05-30 | **Last Amended**: 2026-05-30
