# Phase 3 — The Skill (JSON-only, no code, no archetype edits, ever, once this starts)

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 2](./Loom_Communities_Workflow_Engine_Phase2_CommunityExtension.md) being fully closed.

Status: not started. Supersedes/extends
[V2 Phase 6](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_Phase6_SkillIntegration.md),
which was placeholder-only and never started.

**Handoff:** implementation is invoked directly via `data/call_implementation_agent.sh` (see the main
tracker's [§5 Handoff protocol](./Loom_Communities_Workflow_Engine.md#5-handoff-protocol)).

## 1. Scope & goal, and the constraint that governs everything below

**Constraint, stated precisely because it's load-bearing**: once this phase begins, every community
(including re-doing Tabletop Club's own JSON through the Skill as its first proof run) gets rebuilt by
having the Skill write JSON against the archetype library Phases 1-2 finished — the Skill itself never
edits a `.dart` file and never adds a new archetype. If this phase discovers a real archetype gap, that
is a sign Phase 2 wasn't actually done, not a reason to let the Skill start improvising code.

The point, from the Skill's perspective (`.agents/skills/using-loom-to-build-an-extension/SKILL.md`): a
community becomes something the Skill **declares** (JSON, mechanically validated) rather than something
an LLM hand-writes UI/button code for per extension. This extends V2 Phase 6's original goal (the
validator as a required gate) with the actual generation step V2 never attempted.

## 2. Input format — audit before generating anything

**Input**: a community design doc in the same shape as
[Loom_Communities_Workflow_Engine_Mosque.md](../Loom%20Communities%20Workflow%20Engine%20V2/Loom_Communities_Workflow_Engine_Mosque.md)
(personas, tabs → cards → archetype → actions, community-specific customizations, cross-cutting notes).

Before writing the Skill, audit whether the *existing* docs actually carry enough structured detail to
mechanically derive a full JSON definition (state graph, transitions, guards, effects, computed-field
formulas, `instanceDataSchema`, `renderBindings` including Repeater config). Working assumption: they
don't yet, since they were written for a human engineer to interpret and fill gaps, not for mechanical
derivation. Treat "does the input doc format need a stricter template" as an open question this phase
answers first, before generating any JSON — this may mean upgrading the doc template (and re-running it
across all 7 community docs) as this phase's own first milestone, not an assumption baked in now.

## 3. Method — the Skill's internal steps

Each step gets its own explicit context/guidance rather than one big undifferentiated prompt:

1. Parse the input doc → persona list + role constraints.
2. Parse tabs → cards → archetype mapping table → one workflow type per card, tagged with its archetype
   family from the [Archetype Implementation Standard](./Loom_Communities_Workflow_Engine_Archetype_Implementation_Standard.md).
3. Per workflow: derive the state graph + transitions + guards from the doc's described actions/
   interactions; derive `instanceDataSchema` (including computed-field `formula`s, per
   [ComputationModel.md](./Loom_Communities_Workflow_Engine_ComputationModel.md)) from whatever fields
   the doc's cards/actions/stats reference.
4. Assemble `renderBindings` mapping each workflow to its tab + archetype + persona role + (where the
   archetype needs one) its Repeater `source`/item-template/actions config.
5. Run the validator (`workflow_state_machine_validator.dart`, extended in Phase 1 milestone 1.1 to
   check formula/effect-op correctness) as a hard gate before considering the output done — dangling
   references, missing guards, editable-field/`writableBy` mismatches, unknown formula functions,
   circular formula dependencies all get caught here.
6. Rebuild the community's actual JSON files from this output — no hand-editing after generation.

## 4. Milestones

### Milestone 3.1 — Community-doc template audit and upgrade
**Status:** `[ ]` Not started.
- [ ] Read all 7 existing community docs against the §2/§3 requirements above; produce a concrete
  gap list (what structured detail is missing for mechanical derivation).
- [ ] If gaps are found: upgrade the doc template, re-run it across all 7 docs, confirm each still
  reads correctly as a human-authored design doc (this phase does not sacrifice human readability for
  machine-parseability).
- [ ] If no gaps are found: state explicitly why the existing format is already sufficient, with
  evidence (a worked mechanical-derivation trace on one section of one doc).

### Milestone 3.2 — Validator as a required Skill gate
**Status:** `[ ]` Not started. Carries forward V2 Phase 6 milestone 6.1's original scope.
- [ ] `workflow_state_machine_validator.dart` (Phase-1-extended) added to SKILL.md's "Required Workflow
  Validation Gate" section, alongside the existing judge tools.
- [ ] A test extension with an intentionally broken workflow (stuck state, dangling reference, unknown
  formula function, circular formula dependency) is rejected before UI generation runs.
- [ ] A test extension with a valid workflow passes the gate and proceeds unmodified.

### Milestone 3.3 — Skill methodology implementation (steps 1-6)
**Status:** `[ ]` Not started.
- [ ] The 6-step method in §3 implemented as the Skill's operating procedure
  (`.agents/skills/using-loom-to-build-an-extension/SKILL.md`), each step's guidance documented
  separately (not one undifferentiated prompt).
- [ ] Card-surface component docs (`components/card-surfaces/*.md`) updated to describe
  `instanceDataSchema`-driven rendering (including formula/Repeater config) instead of prose-only
  per-field anatomy — carries forward V2 Phase 6 milestone 6.2.

### Milestone 3.4 — First proof run: Tabletop Club through the Skill
**Status:** `[ ]` Not started. Depends on 3.1-3.3.
- [ ] Run the Skill against Tabletop Club's own (now-upgraded, per 3.1) design doc, producing JSON from
  scratch.
- [ ] Validator passes on the generated output.
- [ ] Generated JSON drives the running app to the *same* real interactions Phase 1 hand-built (ballot,
  calendar grid, repeaters, etc.) — proven by re-running Phase 1's own widget/unit test suite against
  the Skill-generated fixture instead of the hand-authored one, zero regressions.
- [ ] Code review confirms zero hand-written per-workflow button/icon/wiring code was needed — no new
  Dart file introduces a bespoke `_actionsFor`-style branch.
- [ ] Existing B25 judge tools (`workflow_completeness_judge.dart`, `ux_contract_judge.dart`, etc.)
  still run and pass on the Skill-generated output.

### Milestones 3.5-3.11 — Community rollout (one per community, in Phase-2 order)
**Status:** all `[ ]` Not started. Same verification discipline as every Phase 1/2 milestone (fresh
tests, live emulator walk) — except now the "implementation" step is invoking the Skill, not writing
Dart.
- 3.5 Garden Club
- 3.6 Camera Club
- 3.7 Book Club
- 3.8 Chess Club
- 3.9 Youth Soccer
- 3.10 Mosque
- 3.11 HOA

Each milestone: [ ] Skill run against that community's (possibly-upgraded) design doc → [ ] validator
pass → [ ] generated JSON replaces the community's hand-authored fixture → [ ] full existing test suite
for that community passes unmodified against the Skill-generated fixture → [ ] live emulator walk
confirms no behavioral regression → [ ] full combined suite green, exact count cited.
