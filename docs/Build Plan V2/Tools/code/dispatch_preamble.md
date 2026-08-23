# Standing rules for every Loom dispatch

These rules are identical in every dispatch and never vary by ticket. They lead the
prompt deliberately: DeepSeek caches on the PREFIX of a request, so an unchanging
opening block is billed at a fraction of the normal input rate on every dispatch after
the first. Do not restate or summarise this block back to me.

## Files you may never modify

- `docs/references/**/*.md` -- locked product and reference documentation. Read them
  freely; never edit them. If a doc is wrong, report it and stop; do not "fix" a
  failure by editing the document that defines the requirement.
- Any community `*.jsonc`, anywhere in the repo. Community JSON is authored solely by
  the community-authoring Skill. Byte-identical copies (`cp`) are permitted where a
  ticket asks for them; authoring, reformatting, reserialising and prettifying are not
  -- not one byte, not whitespace.

## How to handle a failure you did not expect

- A failing test is a FINDING to report, never a licence to weaken the test. Do not
  delete, skip, loosen or `expect`-invert an existing assertion to get to green.
- Never add a silent fallback. Loud failure beats a quiet default everywhere: a run
  that reports success while exercising the wrong input manufactures false evidence,
  which is worse than an honest failure.
- If the UI genuinely lacks an affordance a product doc requires, that is a real
  product finding. Report it precisely -- community, workflow, interaction, what
  happened, what was expected -- and do not paper over it.

## What your report must contain

- Exact test TOTALS for every suite you ran, not just pass/fail. Explain any total that
  moves DOWN. Totals moving up is normal when you add tests.
- The specific numbers the ticket asks for, as fractions, per community where relevant.
- Anything you could not do, and why.

A truthful partial result is worth far more than an overstated one. Every number you
report is verified independently against the repository afterwards, so an inflated
claim is found immediately and costs more than the honest number would have.

## Verification commands

    cd app/packages/core/loom_communities_app_shell && flutter test
    cd app/packages/core/loom_workflow_engine && flutter test
    cd app/packages/tooling/loom_ux_judges && flutter test
    cd app/apps/loom_communities_demo && flutter test

---

# Ticket

