# HARNESS — arrange at the row's provable source state, and fix two defects that would bank false evidence

**Status:** written 2026-10-02, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Scoped by:** Root Cause Agent, session key `harness-remote-data-strategy`. **I verified every
load-bearing claim below myself by reading the cited lines — do not re-derive them, but do not trust
my summary either: the citations are exact.**
**Follows:** `HARNESS-arrange-rows-through-the-product.md` (landed `a8845f57`), whose seam this repairs.

## Why this ticket exists, and why it is NOT "add field type support"

The seam's first device run produced six clean `blocked_by_arrangement` diagnoses for Garden. I was
about to ticket the cheapest-looking one — `garden-tool-loan` needs a `fanId` creation field — and that
would have **made the evidence worse**. Verified by reading the package:

- `"label": "List a tool to loan"` is creatable by `garden-member`, and its create action prefills
  **`ownerFanId: "$actor"`** (Garden package `:1444-1450`).
- `request-loan`'s guard is **`"formula": "if(ownerFanId == $actor, false, true)"`** (`:1043`) — it
  exists precisely to deny the listing's own creator.

So filling the field lets the plan proceed, creates the listing with the acting member as owner, and
then waits for a button the product **correctly refuses to render**. The row would record an
"unavailable"-shaped outcome meaning *"the primary was not offered"* when the truth is *"the harness
made the actor the one identity the guard excludes."* That is this repo's recorded
**"we found nothing" is not "the system offers nothing"** failure, and it would have cost a device run
to bank a false claim about the product.

## Change 1 — target the row's provable source state, not the seed's recorded state (the big one)

`planB25RemoteArrangement` throws `later-state` whenever `currentState != machine.initialState`
(`test/b25_remote_arrangement.dart:80-88`, verified verbatim), and the caller hands it
**`currentState: selector.instance.currentState`** — the state of whichever *seed* the selector picked
(`integration_test/workflow_ui_evidence_test.dart:4984`, verified).

**A seed's state is an artifact of what the package author chose to illustrate. It is the row's DATA
authority, not its STATE authority.** The scoping measured **32 rows with no initial-state seed**
against **53 rows whose primary action fires from the initial state** — so most "later-state" walls are
an accident of seed choice, not a real sequencing need. `mosque-announcement` is the clean case: its
only seed sits at `sent`, yet B17 proves the full draft→publish flow from a fresh creation today.

**Do:** when every primary-matching candidate fires from `initialState`, arrange at `initialState` and
keep the seed only as the data authority. **Only** throw `later-state` when a primary match genuinely
requires a non-initial state. Expect roughly 27 of those 32 walls to dissolve with **no new interaction
capability**.

## Change 2 — the formula gate tests the wrong candidate set

`arrangeRemoteInstanceFor` passes **every actionable transition** as `candidateTransitions`
(`workflow_ui_evidence_test.dart:4988-4991`, verified: `selector.transitions.map(...)`). The
all-denied gate at `b25_remote_arrangement.dart:123-141` therefore sees formula-less candidates such as
`leave-queue`, whose verdict is `unknown` (`b25_formula_guard_reachability.dart:44`), and `unknown !=
denied`, so `.every(denied)` never fires.

**That is exactly why tool-loan threw the field wall (#6) while giveaway threw the self-creator wall
(#5)** — same underlying defect, different wall reported, purely because of which candidates happened to
carry formulas.

**Do:** scope the gate to **primary-matching** candidates, or at minimum throw when all primary matches
are denied. **Keep `unknown` as a third state** — do not collapse it to denied, and do not filter
candidates away: `primary_action_unavailable` is a designed outcome and must stay reachable.

## Change 3 — the returned selector carries stale data

`arrangeRemoteInstanceFor` returns a synthetic selector with `currentState:
selector.instance.currentState` and `instanceData: selector.instance.instanceData`
(`workflow_ui_evidence_test.dart:5061-5068`, verified), while correctly setting
`createdByFanId: actorFanId`. But the **real created row** carries the resolved prefill — e.g.
`ownerFanId = actorFanId` — not the seed's values. Everything downstream that reasons from
`instance.instanceData` (actor-field checks, input completion, postconditions) is reasoning from data
the created instance does not have.

**Do:** return the planner's `syntheticInstanceData` (seed + resolved prefill) and the state the
instance was actually arranged at.

## Do not

- **Do not add `fanId`, `date` or `time` field support in this ticket.** Those are real prerequisites
  (~34 rows have a non-text required creation field; date+time dominate at ~14, then `list` ~10,
  `fanId` ~8) but they **co-occur with two-identity on the same creation forms**, so shipping them
  alone converts crisp blocks into false "unavailable" rows. They belong with the two-identity work.
- **Do not implement two-identity arrangement here.** It is the largest real gap (~21 rows) and reuses
  `authenticateEvidenceFanForRemote`, which is already re-entrant — but it is a separate increment.
- **Do not fill a `fanId` field by picking "any member"** when that work does arrive. The constraint is
  **directional**: `hoa-dues-payment` is board-created and every member transition guards
  `actorEqualsField: payerFanId`, so that field must be **the acting fan**; tool-loan's owner,
  `chess-match-meetup.opponentFanId` and `platform-connection.inviteeFanId` must be **a different** fan.
  Derive each value from the row's own candidate guards.
- **Do not touch `docs/references/**`** — hard-locked.

## Verification

- A test that **fails before and passes after** for Change 1: a row whose seed sits in a later state
  while its primary action fires from `initialState` must arrange rather than throw. Run it against the
  un-fixed planner first — a test that cannot fail for the reason it claims proves nothing.
- For Change 2, assert the gate still **does** throw when every primary match is denied (the
  self-creator case), and still **does not** throw when a primary match is merely `unknown`.
- All five suites, skip counts before pass counts: demo **274** (0 failed, 0 skipped), app shell
  **448** (+2), engine **345** (+1, with both Postgres credential sets), service **168** (+1, the one
  skip being the App Access one and **not** a PostgreSQL test), judges **525**. All five measured green
  by me on 2026-10-02, so any movement is yours. **If you lack Postgres credentials, say so** — more
  skips means your run proved less.
- `flutter analyze` on the demo app: **3** pre-existing issues; take the count from flutter's own
  `N issues found` line. A fourth is yours.
- **Do not run a capture to verify this.** `--mode targeted-precheck` currently overwrites canonical
  manifests for phases it did not run (19 tracked files, `B14` 3097→70 lines); that is a separate open
  defect. If you believe a device run is needed, say so and stop.
