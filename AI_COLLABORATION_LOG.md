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

- **Done & verified**: A1–A2, B1–B3, C1–C2, D1–D2 (the whole non-UI core), and **E1 — the themed
  `FormScreen`, which now renders on a real simulator**: the bundled JSON drives the dark theme,
  the title, and 6 ordered fields, with the unknown `COLOR_PICKER` correctly excluded. For E1 the
  5-gate G5 was a literal **`xcodebuild build` + boot/install/launch + screenshot**, not just unit
  tests — verifying the server-driven pipeline end-to-end on screen. 60 tests / 14 suites still green.
- **E2–E4 done — the full form renders and works.** Replaced `FieldRowView`'s placeholders with the
  real components (5-subtype text field + live counter, single/multi dropdown, toggle, checkbox). A
  simulator screenshot confirmed the whole pipeline together: the campaign-name default truncated to
  `20/20` (counter in the theme's error color at the limit), the multi-dropdown showing the default
  id resolved to its label, the empty-options dropdown disabled with a hint, the toggle on by default.
  Every §7 decision I implemented blind in the core is now visibly correct on screen. 60 tests still green.
- **Phase F done — all four enhancements in.** F1 rich-text checkbox links (pure `RichTextLabel`
  builder + a checkbox whose box and links are separate tap targets, verified blue on-device); F2
  regex UX (precompile-once caching in the VM, with the validator falling back to inline compile so
  D1's tests stand); F3 `@FocusState` Next/Done keyboard toolbar (binding threaded through three
  views, focus-order unit-tested); F4 a consolidated `EdgeCaseTests` suite closing out the §7 matrix
  (hostile mixed payload → 3 renderable / 2 skipped, all-invalid theme → fallback). **73 tests / 18
  suites, zero warnings.** The app is feature-complete (required + all optional).
- **Next**: Phase G — README, finalize this log, and the 30–60s demo video; then Definition of Done.
- I will keep appending to this log as the build progresses, capturing prompts, accepted
  suggestions, push-backs, and any bugs the AI gets wrong.

---

# BugFixes

After the app was feature-complete I ran several rounds of polish and bug-fixing, all on a
`feature/bug-fix-improvements` branch. For this whole phase I had the AI drive **XcodeBuildMCP**
(the `xcodebuildmcp` CLI) instead of raw `xcodebuild`, so I could build, run on a booted
simulator, **drive the UI (taps, typing), and capture screenshots** to verify each fix visually
— not just by tests. Every fix below was confirmed on-device and against the full suite.

## Round 1 — Real payload swap, and stale test fixtures

**My prompt:** *"There was some data missing and the JSON was not proper in
`form_payload.json`. Now I have updated the JSON manually. Use XcodeBuildMCP and the test cases
to test each case, each field, and if any error is thrown, fix the issues and make the app work
as expected."*

I replaced my placeholder sample with a comprehensive **9-field** payload (multi-dropdown,
NUMBER/SECURE/URI text subtypes, an empty-options billing dropdown, a `COLOR_PICKER` unknown
type, checkbox links, and a campaign-name default longer than its `max_length`).

**The AI predicted the failure before running, then proved it.** It noted that two tests had
hard-coded the *old* sample's count and would now break (the new payload has **8 renderable + 1
skipped**, not 6). It ran the suite via the CLI: exactly **2 failures**, both
`payload.fields.count → 8 == 6`. No decode errors, no crashes — the app handled the new payload
correctly; the "errors thrown" were stale fixtures, not app bugs.

I had it (a) fix the two counts, (b) *upgrade* the bundled-decode test to assert each field's
decoded shape (subtypes, options, `max_length`, metadata), and (c) add a `BundledPayloadTests`
suite that drives the **real** payload through the view model — ordering, the over-long default
truncated to 20, the toggle seeded on, and required-field validation. Then it ran the app and
took screenshots, and I tapped **Save** to watch every required field flag its own error message
(including the empty-options billing conflict). Result: **78 tests pass**, app verified working.

**A correctness call I flagged back to myself:** my new payload marks `billing_account`
`required` with empty `options`, so by the resilience rule it can *never* be satisfied — the app
correctly blocks submit. The AI surfaced this as "not a bug, but you can't submit this form as
configured." I came back to it in Round 4.

## Round 2 — Title colliding with the Dynamic Island

**My prompt (with a screenshot):** *"On scrolling to the top, the Dynamic Island and the safe
area are interrupting the content. Fix the UI break at the top — add a navigation bar or
somehow fix it."*

The large title was scroll content with no nav bar, so its top line ran under the status bar.
The AI wrapped the screen in a `NavigationStack`. **Debug #6:** the first attempt used a *large*
navigation title and it rendered **invisible** — a dark title on the dark themed bar, because
the system large-title color doesn't follow `.toolbarColorScheme`. The screenshot caught the
empty band immediately. The fix was a compact **inline** bar with the title as a `principal`
toolbar item colored explicitly from the theme (`theme.text`), over a themed `toolbarBackground`.
Re-ran, screenshotted: title sits below the Dynamic Island, legible, no overlap. 78 tests green.
Lesson reinforced: for SwiftUI nav-bar text color, control it explicitly rather than hoping a
modifier wins.

## Round 3 — Hard-capping `max_length`, and a SwiftUI binding gotcha

**My prompt:** *"For `campaign_name` (max 20): if a char is above 20, trim and keep only 20; at
20/20 don't show red; and it should not exceed 20 even if the user types — let the char not
append."*

This is the best debugging moment of the bug-fix phase. The counter color was a one-liner
(reaching the cap is valid, so I made the counter neutral, never red). But when the AI typed 16
extra characters into the full field on the simulator, the screenshot showed the bug clearly:
**the counter said `20/20` while the field visibly displayed more than 20 characters.**

The *value* was correctly capped (the counter, which reads the model, proved it) but the
**displayed text wasn't reverting.** This is a classic SwiftUI trap: when the truncated value
equals the previous value, a plain view-model binding doesn't push the capped text back to the
field, so the keystroke lingers on screen. The robust fix was to bind the field to **local
`@State`** and, on an over-limit edit, rewrite that state to the capped value — which *forces*
the field to drop the extra character — while keeping the view model in sync for
validation/submit. Re-ran on-device: typing 16 extra chars now changes nothing, counter neutral
at `20/20`. I would not have trusted this fix from the value alone — only the on-device
screenshot exposed the display/value divergence.

## Round 4 — A batch of 8 UI/UX fixes + a local billing flow

**My prompt:** *"There are some bugs to fix, fix them all: (1) remove the Next/Done keyboard
buttons; (2) if a text field has no placeholder, use the label as placeholder; (3) make the
placeholder color consistent/standard; (4) when Ad Networks is clicked the whole field disappears
with the popup; (5) when all fields are entered, turn the Save button `#BB86FC` to indicate it's
clickable; (6) make the checkbox color `#BB86FC` (it's gray, can't tell if checked); (7) if no
billing account, add a local flow — tapping the field opens a bottom sheet with full name / card
number / exp / CVV + an Add button, list added cards, and save them locally; (8) toggle color
`#BB86FC` when on. Fix all, then test with the XcodeBuild CLI."*

I had the AI work through all eight. Highlights of where judgment mattered:

- **Items 5/6/8 (the `#BB86FC` accent):** I centralized it as a `ResolvedTheme.accent` brand
  color rather than hard-coding it in three places, and wired Save/checkbox/toggle to it. Item 5
  needed a reactive `isFormValid` on the view model to drive the Save tint.
- **Item 4 (dropdown disappearing):** I could **not reproduce it** on my iPhone 16 Pro simulator
  — tapping the dropdown showed the options and selecting worked. The report was on an iPhone 17
  Pro / iOS 26, which I don't have. Rather than ship a `Menu` I couldn't verify on that device, I
  had the AI **replace the `Menu` with a sheet-based selector** — robust across iOS versions and
  with *better* multi-select UX (checkmarks, stays open, Done). That removes the entire class of
  `Menu`/Liquid-Glass popover bug. (Push-back on myself: don't "fix" by guessing — change the
  mechanism that could plausibly be at fault.)
- **Item 7 (local billing):** the biggest piece — a `BillingCard` model, a `CardStore` persisting
  to `UserDefaults`, and a bottom-sheet component. I made the AI add an explicit **security
  caveat in the code**: storing the full PAN and CVV in `UserDefaults` is *not* secure and is only
  to satisfy "save locally" — a real app would tokenize. I verified the whole flow on-device:
  filled the card form, tapped Add, the card listed as `•••• 4242` with a checkmark, and the
  field showed the masked card. The validator was updated so a selected card satisfies the
  previously-unsatisfiable billing field — which also resolves the Round-1 caveat.

**Debug #7 — a compile error from a Text vs. View type.** Coloring the placeholder failed to
build: `Text(...).foregroundStyle(...)` returns `some View`, but `TextField`'s `prompt:` wants a
`Text`. The Text-specific `.foregroundColor` returns `Text`; swapping it fixed the build.

**Debug #8 — flaky UI automation, so I switched to a unit test.** To prove item 5 visually I
needed every field filled, but coordinate-based typing on a scrolling, keyboard-occluded form
kept landing text in the wrong field (the tap's focus change is async; `type` fired before it
settled). Instead of fighting it, I had the AI verify item 5 **deterministically** with a unit
test — `isFormValid` is `false` with empty required fields and flips `true` once they're all
satisfied. That's a cleaner proof than a fragile screenshot, and it's now a regression guard.

Result: **79 tests pass** via the CLI, and I confirmed items 1–4, 6–8 on-device by screenshot
(toggle/checkbox purple, consistent placeholders, the dropdown sheet with multi-select, the
billing add/select flow). One honest gap I noted to myself: I showed the Save button's *muted*
state on screen and proved the *valid → accent* transition by test rather than a screenshot,
because of the automation flakiness above.

### What this phase reinforced about working with the AI

- **Screenshots catch what tests and values can't.** The `max_length` display/value divergence
  and the invisible nav title were both invisible to the test suite and the model state — only
  an on-device screenshot exposed them. Driving the real app via XcodeBuildMCP was worth it.
- **When you can't reproduce, change the mechanism, don't guess a patch.** The dropdown got a
  sheet, not a speculative Menu tweak.
- **Prefer a deterministic test over a fragile UI gesture** when automation is flaky (item 5).
- **The AI is a strong executor but I own the calls** — the accent-color centralization, the
  security caveat on stored cards, keeping the project name, and the resilience trade-offs were
  mine; the AI implemented and verified them.
