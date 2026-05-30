# AI Collaboration Log — Eulerity Dynamic Form Builder

> A record of how I used AI assistance to set up and begin this exercise. It covers how I
> prompted and iterated, where I accepted the AI's suggestions versus pushed back or corrected
> them, and the bugs we debugged together. It is written chronologically so the *process* is
> visible, not just the result.

## Tooling & setup

- **Tool**: Claude Code (CLI) running **Claude Opus 4.8**, with reasoning effort set to `xhigh`.
- **Why this tool**: I wanted an agent that can actually run the toolchain — edit files, drive
  `xcodebuild`, run the test suite — so every claim it makes is backed by real output, not just
  generated text. That "verify by running" loop is the core of how I worked.
- **My working method**: I drive with intent and constraints (MVVM, Big-O, offline, iOS 16),
  force the AI to **ask before assuming** via its question tool, and require a **green build +
  tests** before any task is considered done. The detailed build plan (`Plan.md`) and the
  product decisions are mine; the AI executes against them and I review every step.

---

## Phase 1 — Project setup, with clarification before code

**My prompt (paraphrased):** "Set up this SwiftUI app with MVVM, every function written
optimally with Big-O in mind. Build the basic file structure, update `CLAUDE.md` and the
spec-driven setup. Use the question tool to clarify doubts."

**What the AI did well:** Instead of dumping a generic scaffold, it explored the repo first and
surfaced things I hadn't flagged:
- The Xcode project mixed deployment targets (`IPHONEOS_DEPLOYMENT_TARGET = 16.0` in one config,
  `26.0` in another). It asked me to standardize.
- It noticed the project uses **Xcode 16 file-system-synchronized groups** (`objectVersion 77`),
  meaning new files under the target folder auto-include — so no `.pbxproj` surgery for sources.
- It checked that `xcodebuild` + an iOS 16 simulator were actually available before promising it
  could verify anything.

**Clarification round 1 (I answered its questions):**

| Question | My answer | Why |
|---|---|---|
| What does the app do? | "Skeleton only for now; full feature docs come next phase." | I wasn't ready to share the brief yet; I wanted a clean architecture first. |
| Min iOS version? | **16.0** | Broader device reach; I accepted the consequence that this rules out the iOS-17 `@Observable` macro, so view models use `ObservableObject`. |
| Dependencies? | **First-party only** | A take-home should show fundamentals, not glue around packages. |
| Testing? | **Swift Testing + TDD** | Modern framework; I want tests as a first-class gate. |

**Push-back / control:** The AI is wired to want a full brainstorming + written-design cycle. I
kept it scoped — "skeleton only, features later" — so it didn't over-build. It presented a short
design with two real decisions (how to add the test target; infra-only vs. a demo slice) and I
approved with "do what's best for the test environment."

---

## Phase 2 — Building the skeleton + a real isolation bug

The AI scaffolded an MVVM skeleton and added a unit-test target by hand-editing the `.pbxproj`
(new `PBXNativeTarget`, synchronized group, host-app dependency, and a **shared scheme** so
`xcodebuild test` is reproducible from the CLI). It verified with a real run: build + tests green.

**Debug #1 — `nonisolated` doesn't propagate to extension members.**
The first build threw a warning (an error under Swift 6 mode):

```
URLSessionAPIClient.swift: main actor-isolated instance method 'makeRequest(baseURL:)'
cannot be called from outside of the actor
```

This is subtle and worth understanding: the project sets `SWIFT_DEFAULT_ACTOR_ISOLATION =
MainActor` (Xcode 26's "approachable concurrency" default), so everything is `@MainActor` unless
opted out. I had marked the `Endpoint` **type** `nonisolated`, but `makeRequest` lived in a
separate `extension` — and **`nonisolated` on a type does not propagate to members declared in an
extension.** The fix was to mark those members `nonisolated` individually. I had the AI confirm
the fix with a clean rebuild (zero warnings) rather than trusting it. This insight got written
into `CLAUDE.md` so it doesn't bite again.

---

## Phase 3 — Constitution + docs, and skipping a pointless hook

The AI used the spec-kit constitution workflow to fill in the project constitution (MVVM,
Test-First, First-Party, Big-O, Simplicity) and rewrote `CLAUDE.md` with the architecture map and
the exact verified build/test commands.

**Push-back:** The spec-kit flow wanted to run a mandatory `git.initialize` hook "before
constitution." The repo was already a git repo with commits, so I had it **skip the redundant
hook** rather than risk an unwanted commit on a dirty tree. Blindly following tool ceremony when
the precondition is already met is a mistake; I'd rather reason about *why* a step exists.

**Debug #2:** The AI introduced a stray full-width character (`【`) into `CLAUDE.md` while writing.
Caught it on review and had it fixed — a reminder that AI output needs proofreading, not just
compiling.

---

## Phase 4 — Handing over my real plan, and reconciling conflicts

This is the most important collaboration moment. I gave the AI **`Plan.md`** — my own detailed,
task-by-task build plan for the actual exercise (a fully-offline, server-driven **Dynamic Form
Builder**: render a single screen entirely from a bundled JSON payload, defensively, never
crashing). It contains the architecture, a per-operation **Big-O table**, a 13-row **edge-case /
product-decision matrix**, and a **5-gate loop** (Spec → Approve → Implement → Test → Verify) to
run every task through.

**The AI's best move:** rather than blindly applying it, it diffed `Plan.md` against the existing
repo and surfaced five concrete conflicts before changing anything:

1. **Test framework** — `Plan.md` said XCTest, but I'd already chosen Swift Testing.
2. **No networking** — the app is offline (JSON from bundle), so the entire networking layer it
   had just built was dead weight contradicting the design.
3. **Project name** — `Plan.md` used `DynamicFormBuilder/`; the real target is `Eulerity`.
4. **Test timing** — my 5-gate loop is implement-then-test-in-same-task, not strict red-green.
5. `Plan.md` lived outside the repo and needed importing as the source of truth.

**Clarification round 2 (my calls — several were deliberate push-backs against my own plan):**

| Question | My answer | Reasoning |
|---|---|---|
| Test framework? | **Keep Swift Testing** (override `Plan.md`'s XCTest) | I prefer the modern framework; I had the AI *correct `Plan.md`* to match rather than downgrade the code. |
| Project name? | **Keep `Eulerity`** | Renaming a target/bundle-id is invasive churn for no benefit; the group layout lives inside it. |
| Realign skeleton now? | **Yes** | The networking layer was wrong for an offline app — delete it now, don't let it rot. |
| Generate spec-kit artifacts? | **Full artifacts** | I want `spec.md` / `plan.md` / `tasks.md` so the spec-driven process is real, not decorative. |

The AI then: removed the networking layer; restructured to my `Plan.md §4` layout
(`Parsing/`, `Theming/`, `Validation/`, `Resources/`, etc.); added a representative
`form_payload.json` exercising the tricky edge cases (default longer than `max_length`, empty-
options-required dropdown, unknown `COLOR_PICKER`, metadata links); imported `Plan.md` into the
repo **with my corrections applied** (XCTest→Swift Testing, name kept); rewrote the constitution
to v1.0.0 with a **sixth principle, Defensive Resilience (Never Crash)** — which is the heart of
this exercise; and generated the three spec-kit documents from `Plan.md`. Verified green again.

---

## Phase 5 — Branch hygiene, commit, and first real feature (A2)

I had it rename the branch to `feature/001-dynamic-form-builder`, untrack a stray `xcuserdata`
plist that violated `.gitignore`, and commit the setup as one milestone. Then we started the
first real feature task through the 5-gate loop.

**Task A2 — hex color parsing + theme model:**
- `ThemeModel` — pure `Decodable`, optional hex channels (so a missing channel degrades, not
  crashes).
- `HexColorParser.rgba(from:)` — handles `#RGB` / `#RRGGBB` / `#RRGGBBAA`, with or without `#`;
  any malformed input returns `nil`; **O(1)** (bounded-length input). I deliberately route every
  failure (bad length, non-hex digits, empty) to `nil` so the UI can fall back — never a force-
  unwrap.
- `ResolvedTheme` — the *only* theming type that imports SwiftUI; resolves each channel to a
  `Color` with a **safe per-channel fallback**, so a broken `theme` block can never make the form
  illegible.
- Tests: 7 parser cases + 3 `ResolvedTheme` cases → 13 tests / 4 suites, zero warnings.

**Debug #3 — a SourceKit false positive.** While writing `ResolvedTheme`, the editor flagged
`No such module 'UIKit'`. I recognized this as **SourceKit indexing in a host (macOS) context**,
not a real build error — UIKit is available for the iOS-simulator target. Rather than guess, I
had the AI run the actual `xcodebuild test`: it succeeded. Knowing the difference between an
editor's background-index diagnostic and the authoritative compiler result saved a pointless
"fix."

**A design choice I directed:** everything pure (parser, models, resolved theme) is marked
`nonisolated` so it's callable from the **nonisolated test target** synchronously. If I'd left it
main-actor-isolated, the tests would have needed `await`/`@MainActor` ceremony for no reason. This
ties back to the isolation lesson from Phase 2.

---

## Phase 6 — Phase B parsing, and a compiler crash

B1 added the `FieldType` / `TextSubtype` taxonomy (unknown type → `.unsupported`, unknown subtype
→ `.plain`). B2 is the core: `FormField` (flat struct + computed `kind`) and a `FormPayload` that
decodes the `fields` array **element-by-element** via a lossy `Failable` wrapper, so one bad field
is skipped while the rest survive — the resilience this exercise is really testing.

**Debug #4 — the Swift compiler itself crashed.** The first B2 build didn't fail with a normal
error; it produced a compiler **ICE** (`bad_optional_access`) while type-checking
`FormPayload.init(from:)`. I read the crash backtrace, saw it named that initializer, and
recognized the cause: I'd stacked too many nested optional-`try?` expressions
(`((try? c.decodeIfPresent(...)) ?? nil) ?? "")`) and it tipped the type-checker over —
tellingly, `FormField.init` used the same pattern and compiled, so it was the *extra* nesting in
`FormPayload`. The fix was to flatten to clean single-optional forms
(`try container.decodeIfPresent(...) ?? ""`); per-element resilience stays in `Failable`, and a
corrupt *top-level* shape is left to throw and be handled by the loader (B3). Lesson: when the
compiler crashes, the bug is still usually *your* expression — simplify it, don't fight it.

**Debug #5 — the isolation lesson, again.** With the crash gone, three warnings appeared (errors
under Swift 6): `Failable.value` and `FieldType.isSupported` were main-actor-isolated and
referenced from nonisolated decode code. Same root cause as Phase 2 — a struct I hadn't marked
`nonisolated`, and a computed property living in an `extension` (where the type's `nonisolated`
doesn't reach). Marking both `nonisolated` cleared it. I treat every warning as an error and read
it; that discipline is what keeps this class of bug out of the submission.

Result: B1 + B2 green — **31 tests / 8 suites, zero warnings** — including the resilience cases
(malformed field skipped, unknown type excluded, empty options, missing-fields array, and the
bundled payload decoding to 6 renderable fields with 1 excluded).

## Where I accept AI vs. where I push back — the pattern

- **Accept**: mechanical scaffolding, `.pbxproj` editing, boilerplate, test wiring, and anything
  it can immediately **verify by running**. These are where the AI is fastest and lowest-risk.
- **Push back / own the decision**: product and architecture calls (offline vs. networked,
  framework choice, project naming, deployment target), and anything where the AI's default
  ceremony doesn't fit the situation (skipping the redundant git hook, scoping it to a skeleton).
- **Always verify, never trust on faith**: every "done" is gated on a real `xcodebuild test` run
  with the output shown. I treat compiler warnings as errors and read them — that's how the
  isolation bug and the SourceKit false positive were correctly classified.

## My understanding of the code I'm submitting

A few non-obvious things I can speak to directly:
- **MainActor-by-default isolation** (Xcode 26): UI/ViewModels are `@MainActor`; pure
  value/logic types are explicitly `nonisolated` + `Sendable`. The gotcha is that `nonisolated`
  on a type **doesn't** cover members in a separate `extension`.
- **Why no networking**: the payload is bundled; there is deliberately no `URLSession`/API layer
  (Constitution III). The whole "server-driven" behavior is local JSON → defensive decode → state
  → UI.
- **Big-O discipline**: every non-trivial function documents its cost (a `- Complexity: O(...)`
  annotation, e.g. on `HexColorParser.rgba` and `ResolvedTheme.init`); lookups use pre-built
  `[id: …]` maps and `Set`s, never nested scans over `fields` (Constitution IV / `Plan.md §5`).
- **Defensive resilience**: no force-unwraps/`try!` on any JSON path; unknown types are excluded
  from render, a single malformed field is skipped, invalid hex/regex/URL fall back safely
  (Constitution V / `Plan.md §7`).

## Status & next steps

- **Done & verified**: A1–A2, B1–B3 (parsing core), C1–C2 (`FormViewModel`), and D1–D2 (validation
  + submit) — all green through the 5-gate loop (**60 tests / 14 suites**). **The entire non-UI core
  is built and tested** — model, parsing, loading, state, updates, validation, and a submit that
  preserves scalars/arrays/bools — fully offline, no force-unwraps on JSON paths, every function
  complexity-annotated.
- **Next**: Phase E — the SwiftUI views (themed `FormScreen` + the four field components), where the
  isolation split (pure `nonisolated` core vs `@MainActor` UI) finally renders on screen.
- I will keep appending to this log as the build progresses, capturing prompts, accepted
  suggestions, push-backs, and any bugs the AI gets wrong.
