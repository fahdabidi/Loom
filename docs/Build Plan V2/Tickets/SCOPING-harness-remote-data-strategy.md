# SCOPING NEEDED — how does the capture harness get rows to drive against a live backend? (ticket C)

**Status:** written 2026-10-01. **This is a scoping request, NOT an implementation ticket.** Do not
dispatch it to the implementation agent; it has no agreed design yet.
**Depends on** [HARNESS-production-wiring-and-direct-grant-auth.md](HARNESS-production-wiring-and-direct-grant-auth.md) (ticket B) — creation requires an authenticated session, so B must prove one authenticated remote frame first.

## The problem, stated plainly

The capture harness selects which seeded instance each B25 row is proven against, and it does so by
walking the package's `workflowInstances`. **Those seeds populate the local engine only.** Remote
communities start empty — that is the deliberate 2026-09-07 decision, not a gap: installing or
publishing a package is not a request to copy demo instances into Postgres.

So once the harness runs against live services (ticket B), the rows it wants to drive **do not
exist**. Authentication and the engine toggle do not touch this at all. The root cause agent that
scoped A and B called this out unprompted as the open-ended item and declined to minimise it, which is
worth taking at face value: A and B are days-scale, this is not.

## Why this needs scoping rather than a ticket

Three candidate shapes, none obviously right, and the choice changes what "proven" means:

1. **Creation-driven rows** — the harness creates each row's instance through the real create path
   before driving it. Most faithful to the product, and it means every captured row also proves
   creation. But it multiplies the work per row, and some rows' preconditions are multi-party or
   depend on another workflow's state.
2. **Target live rows** — drive whatever the live backend already holds, seeded by earlier
   walkthroughs. Cheaper, but the corpus becomes whatever happens to be there, so coverage is not
   controllable and runs are not reproducible.
3. **A seeding path into the live backend** — a deliberate, non-product fixture loader. Fast and
   reproducible, and in direct tension with the standing rule against building fixtures that bypass
   real paths. Would need an explicit decision that test data may enter Postgres by a non-product
   route.

## What a scoping dispatch should answer

- Which of the three (or what fourth) the codebase actually supports today, with file:line evidence.
- For the creation-driven option: how many of the 72 bar rows have a reachable create path for the
  persona that drives them, and how many have preconditions that another row must satisfy first. That
  count decides whether this is tractable.
- Whether the live-verification agent's existing walkthroughs already solve this — they drive real
  devices against the real backend and create rows, so **they may already be the template**, in which
  case this is less novel than it looks. **Check this first**; it is the cheapest possible answer.
- What becomes of `b25Proven` and the selector's `primary_action_unavailable` outcome, which are built
  around the assumption that a row's instance already exists.

## What NOT to let this turn into

- **Do not let it become a fixture-loader by default** because that is the easiest option. If option 3
  is chosen it must be an explicit, recorded decision with its trade-off stated, not a drift.
- **Do not weaken the bar to fit the harness.** If some rows cannot be driven live, the honest outcome
  is fewer CONFIRMED rows with the reason recorded — not a redefinition of what counts.
- **Do not start this before B proves one authenticated remote frame.** Every design here assumes a
  working authenticated remote path; scoping it earlier means scoping against an assumption.
