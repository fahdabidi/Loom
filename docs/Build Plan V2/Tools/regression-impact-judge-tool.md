# Regression Impact Judge — dispatch tool for verifying a shared-code fix didn't break its other consumers

## Why this exists

Found 2026-08-10, mid Community JSON Migration effort: CJM.1 (`equipment-loan` giveaway generalization)
and CJM.3 (citation-list rendering) both landed against **shared** code — a widget/renderer reused by every
community that declares the same `cardSurfaceFamily`, not code scoped to one community. Verification for
both tickets checked "does this ticket's own new behavior work" (a fixture re-check, a full `flutter test`
run) but never systematically asked "**which other communities/workflows already use this same shared code
path, and does the change alter their behavior too**" — a full green test suite proves nothing broke
*that has a test*, not that nothing broke. This gap became acute once CJM.5 was found (a bug in the
`event-rsvp` detail card, the shared widget every `cardSurfaceFamily: "event-rsvp"` community renders
through — already-merged Camera Club, Garden Club, and Riverside Youth Soccer all depend on the exact code
CJM.5 will touch, with Neighborhood Book Club and Masjid Nur about to add two more). A fix here has a wide,
easy-to-underestimate blast radius, and "the ticket's own tests pass" is not sufficient evidence that
radius was actually covered.

**Distinct from every other judge role in this pipeline:** the Community JSON Migration Tracker's Skill
Output Judge (`§1c`) reviews one community's JSON against its own product doc; the Root Cause Agent
(`root-cause-agent-tool.md`) diagnoses an unexplained bug's mechanism; the LLM Vision UX Judge
(`ux-gate-judge-tools.md`) reviews rendered screenshots against a rubric. None of them ask "what else does
this shared code change touch, and did I verify each of those."

## What it is

A **Claude Agent-tool dispatch** (not Codex CLI — this is in-session verification work, matching the
pattern already used for every Skill Output Judge this migration effort dispatches), given a shared-code
change (a diff, a commit, or a ticket description) and tasked with:

1. **Enumerate every consumer** of the changed code path — every community JSON (or legacy Dart-embedded
   fixture) that declares the same `cardSurfaceFamily`, calls the same shared function, or exercises the
   same validator rule the change touches. Find this by grep across `docs/references/communities/*.jsonc`,
   `app/packages/core/loom_communities_app_shell/lib/src/part02_tab_shell.dart` (legacy embedded fixtures),
   and any test fixtures — not by asking the implementer to self-report which consumers exist.
2. **For each consumer, determine whether the change could plausibly alter its behavior** — read the actual
   code path with that consumer's specific data shape in mind (field names, states, guards), not just "the
   test suite is green so it's fine." A consumer with no existing test is not evidence of safety; it's an
   unverified gap the judge must close by tracing the code directly.
3. **Where a consumer already has automated test coverage**, independently re-run it (never trust a prior
   self-report of "tests pass" — the same standing rule this whole session's ticket-verification discipline
   already applies to Codex dispatches, extended here to shared-code blast radius specifically).
4. **Where no test exists for a consumer**, reason through the exact code path with that consumer's real
   JSON/fixture to determine whether behavior is preserved or altered. If that reasoning can't reach
   confidence without a live/manual check (e.g. an actual emulator run), say so explicitly — flag it as a
   required follow-up, don't silently skip it or mark it "probably fine."
5. **Report per-consumer**, not just one verdict for the whole change — a table of
   community/consumer → verified impact (none / regressed / needs live verification), each with the exact
   evidence (file:line reasoning, test name and result, or an explicit "needs live check" flag).

## Contract

Two things this role must never do, mirroring the discipline already established for every other judge in
this pipeline:
- **Never accept "the ticket's own tests pass" as proof of no regression elsewhere.** That's exactly the
  blind spot this role exists to close.
- **Never mark a consumer "safe" without either running its real test or tracing its real code path with
  its own data shape.** A generic "this change looks backward-compatible" statement without consumer-
  specific evidence is not acceptable — same standard already enforced on every Skill Output Judge dispatch
  this session (no unverified self-report treated as fact).

## Writing the dispatch prompt

Include, so the judge doesn't waste its budget re-deriving what's already known:
- The exact diff/commit(s), or a precise description of the shared-code change (which file, which
  function/class, what changed and why).
- The **specific mechanism** that changed (e.g. "a hardcoded literal workflow-type string was replaced with
  a value read from `responseTable.workflowType`") — not just "this file changed," so the judge knows
  exactly what to trace per consumer.
- Known or suspected consumers if any are already identified (a starting list is fine and saves budget,
  same as the Root Cause Agent's "leading hypothesis" convention — but the judge must still independently
  confirm the list is complete via its own grep, not just trust it).
- The verification bar expected: for this migration effort, that means checking every community currently
  merged into `docs/references/communities/*.jsonc` plus every legacy Dart-embedded fixture in
  `part02_tab_shell.dart` that shares the touched `cardSurfaceFamily`/mechanism.

## Dispatch mechanics

Dispatched via the `Agent` tool (`subagent_type: general-purpose` or `Explore` depending on whether the
task is pure investigation or needs to run commands/tests — general-purpose if it needs to run
`flutter test`/`dart run` commands, which it almost always will), run in the background alongside other
work, exactly like every Skill Output Judge dispatch this session. Never self-dispatched by the same agent
that authored the shared-code fix — always a separate, independent dispatch, same rule as every other judge
role here.

## What happens to the report

If every consumer comes back verified-safe (with real evidence per consumer, not a blanket statement), the
shared-code ticket can be marked done in the tracker. If any consumer is found regressed, that becomes a
new, real bug — either folded into the original ticket if it hasn't landed yet, or a fresh follow-up ticket
if it already merged, dispatched through the same Implementation Agent pipeline and re-verified independently
before closing. If a consumer needs a live/manual check the judge couldn't complete itself (e.g. an
emulator walkthrough), that becomes an explicit action item for the orchestrating session, not something to
quietly drop.

## Status

**Not yet used for CJM.1 or CJM.3** — both shipped before this role was defined, verified only by their own
ticket-scoped tests plus one or two fixture spot-checks, not a systematic per-consumer sweep. Retroactive
risk is judged low for both (CJM.1 changed one boolean-derivation getter with confirmed-identical output
against the one other real consumer at the time, Tabletop Club; CJM.3 added a new, additive `itemSchema`
branch behind a precedence check that only activates when a workflow explicitly declares `itemSchema`, which
no pre-existing community did before CJM.3 landed) — but this is exactly the kind of “probably fine”
non-per-consumer reasoning this doc says not to accept, so it's named here honestly rather than silently
retrofitted. **First real use: CJM.5** (`Community JSON Migration Tracker.md` §2) — once its fix is
diagnosed and dispatched, the Regression Impact Judge must independently verify it against every
`event-rsvp`/`responseTable` consumer (Camera Club, Garden Club, Riverside Youth Soccer already merged;
Neighborhood Book Club, Masjid Nur pending) before that ticket is marked done, not just its own new test.
