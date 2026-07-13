# Loom Communities — Archetype Realization (V3)

Status: In progress — cycle kicked off 2026-07-12, Milestone 1.1 dispatched to the implementation
agent. **Depends on**: [V2's tracker](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine.md)
being fully closed — **satisfied**, V2 Phases 1-5 are all closed (Phase 6 was never started; this
tracker supersedes and absorbs it, see [Phase 3](./Loom_Communities_Workflow_Engine_Phase3_Skill.md)).
No code for this effort has been written yet.

This document is the **tracker**: context, the phase index, and the milestone-status table. Each
phase's own doc (and the two cross-phase reference docs) holds the detailed design, milestones, and
validation tests required to close them — the same split V2 used from its Phase 1 onward.

## 1. Context & motivation

V2 built a real, general, JSON-declared workflow engine (states, guards, effects, persona gating) and
proved it works by migrating 8 communities onto it. What V2 never proved is that the **UI layer**
delivers what each of the 17 catalogued archetypes' names promise. A live review of the running app —
starting from one concrete defect (Book Club's `votePoll` hardcodes 2 candidate names and ignores real
vote tallies) — triggered a full audit of every archetype across every community. The result: **15 of
17 archetypes are the same generic card (icon + title + subtitle + fact-pill row + button row),
reskinned** — not distinct, modern UI screens with real interaction models. Full findings, with
file:line evidence for every archetype:
[Loom_Communities_Workflow_Engine_Archetype_Audit.md](./Loom_Communities_Workflow_Engine_Archetype_Audit.md).

Investigating *why* archetypes kept collapsing to the same generic card surfaced a second, deeper gap:
the effect model can express `set`/`increment`/`append` but nothing that computes (a vote tally, a
capacity remainder, a ranking) or creates a new instance (a notification, a chat message) — so every
community that needed either wrote bespoke, per-community Dart (Chess Club's `_rankingsEffect`) or
faked it by regex-parsing a display string (`_isCapacityFull`). Left as-is, this directly threatens the
Skill's eventual "JSON only, no code" promise (V2 Phase 6, never started) — the Skill cannot give any
community a working ballot without writing new code if the ballot's logic is bespoke Dart. The fix,
designed collaboratively during planning against five hard constraints (Skill-authorable, well-understood
syntax, field-references-only/no parameters, no author-written loops, <50 lines): a
**spreadsheet-formula / SQL-computed-column** model for computation, plus a Redwood/JET-style
**data-bound Repeater** for dynamic-cardinality UI (variable-length button/row lists). Full design:
[Loom_Communities_Workflow_Engine_ComputationModel.md](./Loom_Communities_Workflow_Engine_ComputationModel.md).

**Goal, in three explicitly gated steps** (mapped to Phases 1-3 below):

1. **Fully implement every archetype with real, modern interaction models, and wire all of Tabletop
   Club's tabs to them** — including a new Tournament + Voting feature built specifically to exercise
   the gaps the audit found. **The user personally validates this step before anything downstream
   starts.**
2. Only after that sign-off: extend/modify archetypes further as needed to meet the *other* example
   communities' actual documented needs.
3. Build the Skill: takes a community design doc as input, mechanically produces the JSON to rebuild
   that community — JSON only, no archetype edits, no code changes, ever, once this step starts. Every
   community gets rebuilt through the Skill, one at a time, using Tabletop Club's real implementation as
   the reference the Skill is grounded in.

**Guiding principle for Phase 1 (supersedes V2's "app-shell-only, never touch `loom_workflow_engine`"
constraint that applied to V2 Phase 4/5's community migrations):** that constraint made sense when the
task was mechanically applying an *already-proven* engine to more communities. This is a different task
— discovering and closing genuine capability gaps. Where the UX genuinely needs something the engine
doesn't support yet (computed effects, scheduled notifications, cross-instance voting eligibility), the
fix is a real addition to the shared `WorkflowEngineApi`/`loom_workflow_engine` contract, not an
app-shell workaround. Where the demo app specifically can't provide real infrastructure (no backend, no
timers), the demo's implementation of that API stubs in pre-filled/canned data — but the API shape
itself must be genuine, so a real backend could implement it for real later.

## 2. Prior art considered

**A named-function registry was proposed and rejected during planning.** The first design for computed
effects (e.g. `computeVoteTally`) was a registry of pre-implemented Dart functions referenced from JSON
by `functionId` + field-name params — a direct generalization of Chess Club's `_rankingsEffect`. This
was rejected: it still keeps the actual computation logic in Dart, so a genuinely new computation still
requires a code change, which is exactly the seam that breaks the Skill's "JSON only" promise. The
formula/effect-op model in
[ComputationModel.md](./Loom_Communities_Workflow_Engine_ComputationModel.md) replaced it — the *logic
itself* lives in the JSON as a declarative formula, not as a name pointing at a Dart body. A small,
closed set of genuinely external/opaque platform services (payment processing, checksums, scheduled
notifications) remains referenced by name from JSON — kept deliberately distinct from the rejected
registry because those operations cannot be expressed as field math no matter how rich the formula
grammar gets (see ComputationModel.md §8).

**Oracle Redwood/JET's collection components** (`oj-list-view`/`oj-table`, bound to a `DataProvider`
abstraction plus a row template) are the direct model for the Data-bound Repeater primitive — checked
explicitly during planning rather than invented from scratch, since "a UI region whose row count is
data-driven, not code-fixed" is a solved problem in mature design systems. See ComputationModel.md §5.

## 3. Engine design & phase docs

**Reference docs** (not phase-sequenced — every phase reads these):
- [Loom_Communities_Workflow_Engine_Archetype_Audit.md](./Loom_Communities_Workflow_Engine_Archetype_Audit.md)
  — the audit that triggered this effort; per-archetype verdict + evidence + reuse-vs-build strategy.
- [Loom_Communities_Workflow_Engine_ComputationModel.md](./Loom_Communities_Workflow_Engine_ComputationModel.md)
  — computed-field formulas, extended effect ops, read-side aggregate API, the Repeater primitive,
  live/query-bound lists, the platform-services boundary. Built in Phase 1, reused by all later phases.
- [Loom_Communities_Workflow_Engine_Archetype_Implementation_Standard.md](./Loom_Communities_Workflow_Engine_Archetype_Implementation_Standard.md)
  — living per-archetype status table, updated as Phase 1/2 close milestones. Supersedes/extends
  [V2's Archetype Catalog](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_Archetype_Catalog.md)
  (base JSON field schemas stay there; this doc adds the implementation-status axis).

**Phase docs** (each phase only starts once the prior phase's milestone table below is fully green —
Phase 1 additionally requires its own manual human sign-off, milestone 1.20):
1. [Phase 1 — Modernize Tabletop Club (the golden reference build)](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub.md)
   — computation model + Repeater primitive built here, every archetype realized, Tournament + Voting
   feature. Ends with a manual sign-off gate.
2. [Phase 2 — Extend archetypes for the other communities' real needs](./Loom_Communities_Workflow_Engine_Phase2_CommunityExtension.md)
   — one milestone per community (Garden, Camera, Book, Chess, Youth Soccer, Mosque, HOA).
3. [Phase 3 — The Skill (JSON-only, no code, no archetype edits, ever)](./Loom_Communities_Workflow_Engine_Phase3_Skill.md)
   — doc-template audit, Skill methodology, Tabletop Club as first proof run, then community rollout.

## 4. Phase / milestone tracker

Markers: `[ ]` not started, `[~]` in progress, `[r]` implementation claims done / ready for
verification, `[!]` verification found code issues / sent back, `[x]` closed (code-verified AND
screenshot-validated — see §5). This table is the single place to check overall progress without
opening every phase doc. All milestones below start `[ ]` — nothing in this effort has begun.

| Phase | Milestone | Status |
| --- | --- | --- |
| 1 — Tabletop Club | 1.1 Computed-field formulas (engine core) | `[x]` **CLOSED 2026-07-12** — independently verified: `loom_workflow_engine` analyze clean + 98/98 tests, `loom_ux_judges` analyze clean + 39/39 tests, commit `c860045` |
| 1 | 1.2 Extended effect ops + read-side aggregate API | `[x]` **CLOSED 2026-07-12** — independently verified: analyze clean + 99/99 tests, commit `72a66e6`; 2 test-coverage gaps found and independently confirmed correct via diagnostic script, carried forward as non-blocking follow-up |
| 1 | 1.3 Data-bound Repeater primitive | `[x]` **CLOSED 2026-07-12** — independently verified: analyze clean + 9/9 tests, commit `064126d`; first attempt was interrupted by a tool-level glitch and required one resumption |
| 1 | 1.4 Scheduled notifications + cross-instance eligibility guard | `[ ]` Not started |
| 1 | 1.5 Calendar month/week grid | `[ ]` Not started |
| 1 | 1.6 Marketplace grid reformalized onto Repeater | `[ ]` Not started |
| 1 | 1.7 Discussion threads generalized | `[ ]` Not started |
| 1 | 1.8 Document library real data | `[ ]` Not started |
| 1 | 1.9 Notification inbox | `[ ]` Not started |
| 1 | 1.10 Export wizard step progression | `[ ]` Not started |
| 1 | 1.11 Volunteer roster capacity meter | `[ ]` Not started |
| 1 | 1.12 AI search real query input | `[ ]` Not started |
| 1 | 1.13 Audience/multi-select picker | `[ ]` Not started |
| 1 | 1.14 Single-item preference control | `[ ]` Not started |
| 1 | 1.15 Status timeline visual + protectedDetail masking | `[ ]` Not started |
| 1 | 1.16 Dashboard prioritization | `[ ]` Not started |
| 1 | 1.17 formEntry checkbox + relative-time-picker control | `[ ]` Not started |
| 1 | 1.18 Tournament + Voting feature (flagship) | `[ ]` Not started |
| 1 | 1.19 Archetype Implementation Standard finalized | `[ ]` Not started |
| 1 | 1.20 Human sign-off gate (manual) | `[ ]` Not started — **hard gate, blocks Phase 2** |
| 2 — Community extension | 2.1 Garden Club | `[ ]` Not started |
| 2 | 2.2 Camera Club | `[ ]` Not started |
| 2 | 2.3 Book Club | `[ ]` Not started |
| 2 | 2.4 Chess Club | `[ ]` Not started |
| 2 | 2.5 Youth Soccer | `[ ]` Not started |
| 2 | 2.6 Mosque | `[ ]` Not started |
| 2 | 2.7 HOA | `[ ]` Not started |
| 2 | 2.8 Phase close-out | `[ ]` Not started |
| 3 — The Skill | 3.1 Community-doc template audit and upgrade | `[ ]` Not started |
| 3 | 3.2 Validator as a required Skill gate | `[ ]` Not started |
| 3 | 3.3 Skill methodology implementation (steps 1-6) | `[ ]` Not started |
| 3 | 3.4 First proof run: Tabletop Club through the Skill | `[ ]` Not started |
| 3 | 3.5 Garden Club (Skill rollout) | `[ ]` Not started |
| 3 | 3.6 Camera Club (Skill rollout) | `[ ]` Not started |
| 3 | 3.7 Book Club (Skill rollout) | `[ ]` Not started |
| 3 | 3.8 Chess Club (Skill rollout) | `[ ]` Not started |
| 3 | 3.9 Youth Soccer (Skill rollout) | `[ ]` Not started |
| 3 | 3.10 Mosque (Skill rollout) | `[ ]` Not started |
| 3 | 3.11 HOA (Skill rollout) | `[ ]` Not started |

## 5. Handoff protocol (implementation agent ↔ verification agent)

**This supersedes V2's async mailbox/`file_watcher.py` protocol** (`data/verification_feedback_protocol.md`),
which this session replaced with a direct, synchronous invocation partway through V2's Phase 5: the
verification agent calls the implementation agent directly via `data/call_implementation_agent.sh`
(WSL Ubuntu, `npx @openai/codex exec --sandbox workspace-write`) and blocks on the result — no mailbox
file, no polling watcher, no delivery-confirmation races, since the call itself doesn't return until the
implementation agent's run finishes. The process rules below (production-quality bar, commit gate,
code-before-screenshots sequencing, marker semantics) carry forward unchanged from V2 §5 — only the
transport mechanism changed.

**Roles are strictly separated and never swap:**
- **Implementation agent** (invoked via `data/call_implementation_agent.sh <prompt-file>`): writes
  code, and — per the prompt it's given — sets a milestone row to `[r]` in both this table and that
  milestone's own checklist in its phase doc once it believes the milestone's validation tests are
  satisfiable, with a brief note on what changed/which files. Every kickoff prompt carries the
  production-quality bar clause below verbatim — no shortcuts, no local-state standing in for real
  engine wiring, no decorative fixtures the app doesn't actually execute.
- **Verification agent**: never writes implementation code. Reads the `[r]` claim, runs code-level
  verification first, then (only if that passes) live-emulator/screenshot validation, then either
  closes the milestone (`[x]`) or sends it back (`[!]`) with specific, actionable fix instructions
  written directly into the phase doc's milestone section, then re-invokes
  `data/call_implementation_agent.sh` with those fix instructions as the next prompt.

**Verification sequence — code first, screenshots only after code passes, never both at once:**
1. **Code verification (mandatory first step).** Read the diff/files the implementation agent's note
   points at. Check them against that specific milestone's validation-test list line by line
   (unit-test coverage, formula/effect-op correctness, guard behavior, validator behavior, etc.) — run
   the actual test suite where the milestone specifies one. **Do not proceed to screenshots/emulator
   work until this step is fully green.**
2. **If code verification finds issues:** do not touch the emulator or take any screenshots. Set the
   milestone marker to `[!]` in both this table and the phase doc, and write a concrete, specific fix
   list directly into that milestone's section in the phase doc — the same specificity V2's phase docs
   used (see e.g. V2's Phase 5 Milestone 5.4/5.5 rejection notes for the standard this is held to).
3. **Only once code verification is fully green:** proceed to live-emulator/screenshot-based validation
   exactly as each milestone's bullets specify (WSL Ubuntu, `PantryVision_Manual_API_36` AVD).
4. **Commit gate (mandatory).** Confirm every file the milestone touched — code, tests, fixtures, and
   the tracker/phase-doc edits themselves — is committed, with no modified or untracked files
   remaining in scope, before closing the milestone or sending the next kickoff.
5. **Close the milestone** (`[~]`/`[r]` → `[x]`) only after steps 1, 3, and 4 all pass, citing the
   evidence (test pass counts, screenshot references, and the commit hash covering this milestone).

**Why code verification must gate screenshots, not run alongside them:** a screenshot only proves the
UI *renders*; it doesn't prove the guard/formula/effect logic underneath is correct per that
milestone's actual validation tests. A screenshot that happens to look right can mask a code-level bug
(e.g. a formula silently falling back to a stale value) that no single screenshot would reveal.

## Production-quality bar (every kickoff prompt, verbatim)

> This is a production implementation, not a prototype or demo. Complete this task at the highest
> quality bar: no shortcuts, no placeholder/stub logic, no local-only state standing in for real
> engine wiring, no hardcoded values masquerading as computed ones, and no tests weakened or deleted
> to make something pass. If a fixture or schema models a state machine or a computed formula, the
> running application must actually parse and execute it through the real
> `WorkflowDatabase`/`WorkflowEngineApi`/`applyTransition` path — never a decorative fixture the UI
> ignores. If any part of this task cannot be completed to this bar (missing primitive, ambiguous
> requirement, schema gap), stop and say so explicitly in the resubmission note rather than shipping a
> partial or faked implementation. State plainly which files make the real engine calls and which do
> not — a passing test count is not a substitute for that statement.

Verification-side enforcement this clause depends on: a passing test count is never sufficient proof by
itself. Every milestone verification must independently read the actual implementation — grep for the
real engine calls, not just trust the resubmission note — before accepting a `[r]` as genuine, the same
discipline that caught V2's M2.3/M4.1 (decorative-fixture) and M5.4/M5.5 (hardcoded-literal-instead-of-
computed) anti-patterns.

## 6. Explicitly out of scope for now
- Any change to V2's closed Phases 1-5 communities' JSON before Phase 3 (the Skill) reaches that
  specific community's rollout milestone — Phase 1/2 touch app-shell rendering code and the shared
  engine, not per-community fixture JSON, except where a milestone explicitly says otherwise (e.g.
  milestone 1.8's Tabletop Club document-library fixture).
- A real backend / HTTP implementation of `WorkflowEngineApi` — `LocalWorkflowEngineApi` (SQLite-backed)
  remains the only implementation needed for the demo app; the platform services in
  ComputationModel.md §8 are demo-stubbed with canned data, real API shape only.
- Swiss-pairing generator and true Elo (`pow`/`exp`) for Chess Club — boundary math functions noted in
  ComputationModel.md §8, not needed for any current interaction; add only if a future community
  genuinely needs them.
