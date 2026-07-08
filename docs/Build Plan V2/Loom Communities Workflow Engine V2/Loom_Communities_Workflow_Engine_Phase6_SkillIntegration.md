# Phase 6 â€” Update the Skill

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 5](./Loom_Communities_Workflow_Engine_Phase5_Migration.md) being fully closed.

Status: not started. **Not designed in detail yet, deliberately** â€” revisit once Phases 1-5's actual
shape (not just this plan's guess at it) is known, same caveat as Phase 5.

**Handoff:** once a milestone below is implemented, set its marker to `[r]` here and in the main
tracker, then run this in-session watcher call and wait for delivery:

```python
from data.file_watcher import check_file_update
import asyncio

async def main():
  await check_file_update("data/verification_feedback.md")  # baseline call, returns immediately
  print(await check_file_update(
    "data/verification_feedback.md",
    timeout_seconds=1200,
    reset_template_path="data/verification_feedback_template.md",
    activity_process_names=["wsl", "dart"],
  ))

asyncio.run(main())
```

Then follow the embedded delivery instructions directly.
[Â§5 Handoff protocol](./Loom_Communities_Workflow_Engine.md#5-handoff-protocol-implementation-agent--verification-agent-added-2026-07-05)
for the full sequencing (code verification always runs before any screenshot validation).

## 1. Scope & goal

The point of this whole engine, from the Skill's perspective
(`.agents/skills/using-loom-to-build-an-extension/SKILL.md`): a workflow becomes something the Skill
**declares** (JSON, mechanically validated) rather than something an LLM hand-writes UI/button code
for per extension.

Concretely: add the Phase 1 Â§7c validator (`workflow_state_machine_validator.dart`) as a required
gate alongside the existing judge tools (`workflow_completeness_judge.dart`, `ux_contract_judge.dart`,
etc.) under SKILL.md's "Required Workflow Validation Gate"; update the card-surface component docs
(`components/card-surfaces/*.md`) to reference `instanceDataSchema`-driven rendering instead of
prose-only anatomy descriptions; update the relevant SKILL.md operating rules (15, 16, etc.) to point
at schema declaration instead of bespoke per-workflow UI authoring.

## 2. What this changes about B25

B25's visual/domain judgment (does the copy sound right, does the layout feel modern) still matters
and isn't replaced. But a whole class of bugs B25 currently only catches via a full emulator
screenshot pass (stuck states, missing icons, wrong-persona-sees-wrong-button) becomes structurally
impossible before a screenshot is ever taken, once buttons/fact-pills are mechanically generated from
a schema that already passed the Phase 1 Â§7c validator.

## 3. Living example

A fully worked example â€” the tabletop marketplace's loan/giveaway workflows expressed in this schema,
covering both the workflow *type* definition and multiple listing *instances* (the tile-grid data) â€”
is kept as a standalone, iterating file:
[`Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc`](./Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc),
already load-bearing as Phase 1's own evidence-bar fixture. Treat it as a living design artifact, not a
final spec â€” comment on it directly, it's expected to change as the schema is refined. This is the
reference example a Skill author (human or LLM) would be pointed at once this phase makes the schema
the primary authoring mechanism.

## 4. Placeholder milestones (to be filled in after Phases 1-5)

### Milestone 6.1 â€” Validator as a required Skill gate
Add `workflow_state_machine_validator.dart` to SKILL.md's "Required Workflow Validation Gate" section,
alongside the existing judge tools.

**Validation tests required to close this milestone:**
- [ ] SKILL.md's gate section lists the validator and its invocation command.
- [ ] A test extension authored with an intentionally broken workflow (stuck state, dangling
  reference, etc. â€” reusing the Phase 1 Â§7c regression-guard fixtures) is rejected by the gate before
  UI generation runs.
- [ ] A test extension authored with a valid workflow passes the gate and proceeds to generation
  unmodified.

### Milestone 6.2 â€” Card-surface component docs updated to schema-driven rendering
Update `components/card-surfaces/*.md` to describe `instanceDataSchema`-driven rendering (icons,
labels, editability) instead of prose-only per-field anatomy descriptions.

**Validation tests required to close this milestone:**
- [ ] Each updated component doc's "anatomy" section is replaced or supplemented with a reference to
  the relevant `instanceDataSchema` keys it renders, cross-checked against the actual
  `cardSurfaceFamily` templates built in Phases 1-5 (no doc describing a field the templates don't
  actually render, and vice versa).
- [ ] Spot-check: pick one component doc pre- and post-update, confirm an LLM given only the updated
  doc + a schema can correctly predict what a card renders, without needing the old prose anatomy
  section.

### Milestone 6.3 â€” SKILL.md operating rules point at schema declaration
Update SKILL.md rules (15, 16, etc.) to require schema declaration as the primary authoring path
instead of bespoke per-workflow UI authoring.

**Validation tests required to close this milestone:**
- [ ] A full Skill run authoring a new, previously-unmigrated workflow (chosen once Phase 5's targets
  are known) produces a schema-declared workflow (passes Milestone 6.1's gate) with zero hand-written
  per-workflow button/icon/wiring code â€” confirm via code review that no new Dart file introduces a
  bespoke `_actionsFor`-style branch.
- [ ] Existing B25 judge tools still run and pass on the schema-generated output, confirming the
  visual/domain judgment layer (Â§2 above) composes with the new mechanical gate rather than
  conflicting with it.

