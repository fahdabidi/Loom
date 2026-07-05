# Loom Communities — General Workflow Engine

Status: Draft. **Depends on**: `Loom Communities App Shell V2/AppShell V2 Tracker.md`'s Calendar (M4)
and Marketplace (M3b) phases being fully completed and closed first — **this gate is now satisfied**
(both re-closed 2026-07-04 with live evidence after their reopenings). Phase 1 below is unblocked to
begin; no code from this engine has been written yet.

**2026-07-05: this document was split by phase.** The full design (schema, API, rendering, validator)
and Phase 1's detailed milestones/validation tests now live in
[Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md),
since Phase 1 is where all of it is first built. This doc is now the **tracker**: context, prior art,
the phase index, and the milestone-status table. Each phase's own doc holds that phase's detailed
milestones and the validation tests required to close them.

## 1. Context & motivation

The AppShell V2 work exposed a recurring problem: every time a workflow needs a new interaction
(queued listings needing "Join queue"/"Leave queue", for example), the fix is a bespoke, one-off
addition to `LoomMarketplaceListing`/`LoomListingTransition` — a new boolean flag, a new field, a
new bit of wiring in `_actionsFor`/`_applyTransition`. That model is *already* a real, declarative
state machine (`LoomListingStateMachine`, `part11_shell_models.dart:69-141`), but it's scoped only
to marketplace listings, and its vocabulary is ad-hoc booleans
(`setsHolderToActor`/`clearsHolder`/`incrementsQueue`/`decrementsQueue`/`removesFromList`) rather
than a general mechanism. Meanwhile every *other* workflow type (RSVP, payment, approval,
announcement) has **no state machine at all** — just a fixed actor/receiver/completed lifecycle
(`personaWorkflowStateFor`, `part12_persona_and_tabs.dart:54-75`) and a workflow "family" that's
*guessed* from the workflow ID string (`part13_workflow_copy_catalog.dart`'s `id.contains('payment')`
etc.), not declared.

Goal: replace the ad-hoc-flags-per-feature pattern with one general, JSON-declared workflow engine
that any workflow type can use — states, transitions, guards, and effects — and a thin local API
layer that simulates what a real backend would eventually do, so card-surface UI code never needs to
change when the engine gets a real backend later.

## 2. Prior art considered (see conversation for full comparison)

- **Amazon States Language** / **CNCF Serverless Workflow** — both are JSON DSLs, but built for
  orchestrating serverless *compute* steps (retries, parallel branches, error handling), not
  persona-driven UI state. Wrong domain fit, needlessly heavy.
- **SCXML** — mature W3C statechart standard, but XML-based, and a full implementation
  (hierarchical/parallel states, `<datamodel>`, `<invoke>`) is far more than this app needs.
- **XState** — a JS/TS state machine library. Its vocabulary (states, events/transitions, guards,
  actions, context) is the closest conceptual match to what we want, and it's the direct inspiration
  for the schema in Phase 1's doc — but it's a JS library, not something we can depend on from Dart.

**Decision: don't adopt any of these wholesale.** Evolve our own existing, already-proven,
Dart-native shape (`LoomListingStateMachine`) into a domain-agnostic engine, borrowing XState's
vocabulary (guards, actions/effects, context) rather than its runtime.

## 3. Engine design & phase docs

The full schema/API/rendering/validator design lives in
[Phase 1's doc](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md) (§2-§7), since that's
where it's first built; later phases reuse it without re-deriving it.

**Phase docs** (each phase only starts once the prior phase's milestone table below is fully green):
1. [Phase 1 — Marketplace engine prototype (Tabletop Club)](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md)
   — engine, `WorkflowEngineApi`/SQLite persistence, validator, rendering primitives, Marketplace tab.
2. [Phase 2 — Calendar (Tabletop Club) + audience/distribution primitive](./Loom_Communities_Workflow_Engine_Phase2_Calendar.md)
3. [Phase 3 — Giving (Tabletop Club) + cross-workflow dependency](./Loom_Communities_Workflow_Engine_Phase3_Giving.md)
4. [Phase 4 — Second community, full tab reimplementation: HOA (Cedar Commons)](./Loom_Communities_Workflow_Engine_Phase4_HOA.md)
5. [Phase 5 — Automated/semi-automated migration of remaining communities](./Loom_Communities_Workflow_Engine_Phase5_Migration.md)
   — not designed in detail yet; awaits Phase 4's findings.
6. [Phase 6 — Update the Skill](./Loom_Communities_Workflow_Engine_Phase6_SkillIntegration.md) — not
   designed in detail yet; awaits Phase 5.

**Reference docs** (not phase-sequenced — design/data artifacts every phase reads):
- [Loom_Communities_Workflow_Engine_Archetype_Catalog.md](./Loom_Communities_Workflow_Engine_Archetype_Catalog.md)
  — master archetype cross-reference table + per-archetype JSON field schemas.
- [Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc](./Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc)
  — the living worked example, Phase 1's own evidence-bar fixture.
- Per-community tabs/cards/actions docs:
  [HOA](./Loom_Communities_Workflow_Engine_HOA.md),
  [Mosque](./Loom_Communities_Workflow_Engine_Mosque.md),
  [BookClub](./Loom_Communities_Workflow_Engine_BookClub.md),
  [YouthSoccer](./Loom_Communities_Workflow_Engine_YouthSoccer.md),
  [GardenClub](./Loom_Communities_Workflow_Engine_GardenClub.md),
  [CameraClub](./Loom_Communities_Workflow_Engine_CameraClub.md),
  [ChessClub](./Loom_Communities_Workflow_Engine_ChessClub.md).

## 4. Phase / milestone tracker

Nothing below has been started. Markers: `[ ]` not started, `[~]` in progress, `[r]` implementation
claims done / ready for verification, `[!]` verification found code issues / sent back, `[x]` closed
(code-verified AND screenshot-validated — see §5's Handoff protocol for the full sequencing). This
table is the single place to check overall progress without opening every phase doc.

| Phase | Milestone | Status |
| --- | --- | --- |
| 1 — Marketplace engine prototype | 1.1 Core state machine engine | `[ ]` Not started |
| 1 | 1.2 `WorkflowEngineApi` + SQLite-backed `LocalWorkflowEngineApi` | `[ ]` Not started |
| 1 | 1.3 Validator (`workflow_state_machine_validator.dart`) | `[ ]` Not started |
| 1 | 1.4 Rendering primitives + first `cardSurfaceFamily` templates | `[ ]` Not started |
| 1 | 1.5 Replace Tabletop Marketplace tab end-to-end | `[ ]` Not started |
| 1 | 1.6 OpenAPI pagination cleanup | `[ ]` Not started |
| 2 — Calendar + audience/distribution | 2.1 Audience/distribution primitive | `[ ]` Not started |
| 2 | 2.2 RSVP schema design spike | `[ ]` Not started |
| 2 | 2.3 `event-rsvp` template + Calendar tab replacement | `[ ]` Not started |
| 3 — Giving | 3.1 `payment` template + dues workflow migration | `[ ]` Not started |
| 3 | 3.2 Cross-workflow dependency (dues-current gate on `borrow`) | `[ ]` Not started |
| 4 — HOA (second community) | 4.1 Documents tab (`documentLibrary`) | `[ ]` Not started |
| 4 | 4.2 Requests + Board (`formEntry`/`statusTimeline`/`dashboard`) | `[ ]` Not started |
| 4 | 4.3 Payments tab (reuse Phase 3's `payment` family) | `[ ]` Not started |
| 4 | 4.4 Generality finding | `[ ]` Not started |
| 5 — Migration of remaining communities | (per-community milestones — defined after Phase 4's finding) | `[ ]` Not started |
| 6 — Update the Skill | 6.1 Validator as a required Skill gate | `[ ]` Not started |
| 6 | 6.2 Card-surface component docs updated | `[ ]` Not started |
| 6 | 6.3 SKILL.md operating rules updated | `[ ]` Not started |

## 5. Handoff protocol (implementation agent ↔ verification agent, added 2026-07-05)

Implementation happens in a separate agent session/tool/worktree with no awareness of this
conversation — so the handoff between "code written" and "verified" has to be a durable signal in the
repo itself, not a message passed between sessions that may not exist yet when the other side acts.

**Roles are strictly separated and never swap:**
- **Implementation agent**: writes code, sets a milestone row to `[r]` in both this table and that
  milestone's own checklist in its phase doc once it believes the milestone's validation tests (listed
  in that phase doc) are satisfiable — with a brief note on what changed/which files.
- **Verification agent (this session)**: never writes implementation code. Reads the `[r]` claim, runs
  code-level verification first, then (only if that passes) live-emulator/screenshot validation, then
  either closes the milestone (`[x]`) or sends it back (`[!]`) with specific, actionable fix
  instructions written directly into the phase doc's milestone section.

**Detecting a handoff.** At the start of a verification session (or when resuming after a break), start
a persistent background watch on the tracker + all phase docs (file-content polling, not git — the
implementation side may not commit before checking in), e.g. the recipe below; treat any line it emits
as the trigger to re-read that file and begin the sequence below.
```bash
files=(
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase2_Calendar.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase3_Giving.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase4_HOA.md"
)
declare -A last
for f in "${files[@]}"; do last["$f"]=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1); done
while true; do
  sleep 20
  for f in "${files[@]}"; do
    cur=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
    if [ "$cur" != "${last[$f]}" ] && grep -q '\[r\]' "$f"; then
      echo "READY FOR VERIFICATION: $f"
    fi
    last["$f"]=$cur
  done
done
```

**Verification sequence — code first, screenshots only after code passes, never both at once:**
1. **Code verification (mandatory first step).** Read the diff/files the implementation agent's note
   points at. Check them against that specific milestone's validation-test list in the phase doc line
   by line (unit-test coverage, guard/effect correctness, schema/validator behavior, etc.) — run the
   actual test suite where the milestone specifies one (`flutter test`, the §7c validator, etc.).
   **Do not proceed to screenshots/emulator work until this step is fully green.**
2. **If code verification finds issues:** do **not** touch the emulator or take any screenshots. Set
   the milestone marker to `[!]` in both this table and the phase doc, and write a concrete, specific
   fix list directly into that milestone's section in the phase doc (what's wrong, where, and what
   the passing state looks like — the same specificity as this doc's own validation-test bullets, not
   a vague "needs work"). That note is the instruction set the implementation agent closes against;
   leave it there until the next `[r]` claim.
3. **Only once code verification is fully green:** proceed to live-emulator/screenshot-based
   validation exactly as each milestone's bullets specify (WSL Ubuntu, `PantryVision_Manual_API_36`
   AVD). Capture the evidence the milestone asks for.
4. **Close the milestone** (`[~]`/`[r]` → `[x]`) only after **both** steps 1 and 3 pass, citing the
   evidence (test pass counts, screenshot references) the same way `AppShell V2 Tracker.md` does.

**Why code verification must gate screenshots, not run alongside them:** a screenshot only proves the
UI *renders*; it doesn't prove the guard/effect logic, pagination, or transaction behavior underneath
is correct per that milestone's actual validation tests. Spending emulator time on code that's about
to be sent back for a rewrite is wasted effort — worse, a screenshot that happens to look right can
mask a code-level bug (e.g. a race condition in `applyTransition`) that no single screenshot would ever
reveal. Sequencing code-verification strictly before screenshot-verification is what keeps "looks done"
from being mistaken for "is done."

## 6. Explicitly out of scope for now
- Any change to Calendar or Marketplace before AppShell V2's current tracker closes both phases —
  **satisfied 2026-07-04**; Phase 1 supersedes that interim fix rather than building on top of it.
- Phase 5 (other communities) and Phase 6 (Skill changes) — deliberately not designed in detail yet;
  each needs its own fresh planning pass once the phase before it is actually done, not guessed at
  now.
- A real backend / HTTP implementation of `WorkflowEngineApi` — `LocalWorkflowEngineApi` (SQLite-
  backed, per Phase 1) is the only implementation needed for the demo app throughout Phases 1-5.
