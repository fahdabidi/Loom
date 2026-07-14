# Phase C — Marketplace tab (the club game library)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). **Blocked on Phase A.**

> **Scoping note.** Firm on scope, light on snippets — detailed kickoffs are written after Phase A's
> human gate, against the revised JSON.

## Goal

Render the game library from JSON-declared `equipment-loan` / `equipment-giveaway` definitions, with the
full borrow/queue/return lifecycle — and prove two capabilities the other phases don't touch:
**orthogonal state** (availability is instance data, *not* a top-level state) and a **cross-workflow
guard** (you cannot borrow until dues are paid).

## The modeling lesson this phase encodes

The original Marketplace had a `queued` *state* with **zero declared transitions** — so a queued listing
showed no actions at all. That bug existed because "queued" was never really a state: an item can be on
loan **and** have people queued simultaneously, and it can be available **and** reserved-ahead.

The JSON therefore models availability as **orthogonal `instanceData`** (`availabilityState`,
`queuedPersonaIds`), with a single `published` top-level state. The queue is derived
(`queueLength = size(queuedPersonaIds)`). Under this model the old bug is **unrepresentable** — and the
validator (Phase A) catches stuck states at author time, before a live walk ever has to.

## What must genuinely work

| Workflow type | Instances | Must genuinely work |
|---|---|---|
| `equipment-loan` | Catan (available), Wingspan (on loan, 1 queued), Root (available **and** queued — the case the old model couldn't express) | Borrow (only when `availabilityState == 'available'` **and dues are paid**); Join/Leave queue (guarded by `actorInList`, so a queued member sees *Leave*, not *Join* again); Return (only when on loan) — each a real effect on real instance data |
| `equipment-giveaway` | Retired Catan | Claim → `claimed`, sets `claimedByPersonaId`, removes from the grid |

**The dues guard is the headline:** `borrow`'s `requiresWorkflowsComplete: ["tabletop-club-dues-payment"]`
is a real cross-workflow guard evaluated by the engine. A member who hasn't paid **cannot borrow** — and
that must be proven by a genuinely refused `applyTransition`, not a hidden button.

## User stories

- *As a paid-up member, I browse the library, open a game, and borrow it.*
- *As a member who hasn't paid dues, borrowing is genuinely refused.*
- *As a member, I join the queue for a game that's out — and see my queue position.*
- *As a member already in the queue, I see "Leave queue", not "Join queue" again.*
- *As a member, I can reserve-ahead on an available-but-in-demand game.*
- *As a borrower, I return the game and it becomes available.*
- *As a member, I claim the giveaway and it leaves the grid.*

## Milestones

| # | Milestone | Notes |
|---|---|---|
| C.1 | Turn on `tabId: "marketplace"` in the binding dispatcher | Same flip as B.1. |
| C.2 | Grid/tile rendering through the generic card | Reuse `RepeaterSurface`'s existing grid mode (built in Milestone 1.6) + Phase A's generic card for tile vs detail, honoring `displayContexts: ["tile"]` / `["detail"]` from the schema. |
| C.3 | Borrow / Return lifecycle on real instance data | Effects mutate `availabilityState` / `holderPersonaId` / `dueDate` — no local widget state. |
| C.4 | Join / Leave queue, with per-member identity | The `actorInList` guard drives which button shows. Queue position from the computed `queueLength`. |
| C.5 | **Cross-workflow dues guard, proven negatively** | Unpaid member: `applyTransition('borrow')` genuinely throws. Pay dues (Phase D — or seed `paid`) → borrow now succeeds. This is the test that matters. |
| C.6 | Giveaway claim | Incl. `removeFromTileGrid`. |
| C.7 | Retire the bespoke marketplace listing path | Only once the generic pipeline renders it. Keep `b34_marketplace_browse_test.dart` green **unmodified** — it is the strongest regression guard in the repo for this tab. |
| C.8 | Live walk + evidence matrix + random regression re-check | Full-tab audit. |

## Definition of done

- [ ] Marketplace renders from JSON `workflowDefinitions`; zero bespoke Dart for the loan/giveaway types.
- [ ] A queued listing **always** has actions (the original bug is now structurally impossible).
- [ ] The dues guard is proven by a genuinely refused transition.
- [ ] `b34_marketplace_browse_test.dart` passes **unmodified**.
