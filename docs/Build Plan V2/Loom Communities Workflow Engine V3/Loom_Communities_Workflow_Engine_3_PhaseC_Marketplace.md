# Phase C — Marketplace tab (the club game library)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). Phase A is closed; Phase B (Home) is also
now closed (2026-08-04) and its exact working pattern (ticketed dispatch via
`data/call_implementation_agent.sh`, independent verification, `ux-gate-judge-tools.md` principles at
App-Shell-milestone weight for the live walk) is what this phase follows.

> **Scoping note.** Firm on scope, light on snippets — detailed kickoffs are written after Phase A's
> human gate, against the revised JSON.

## Process note (2026-08-04, before starting)

Investigated current reality before dispatching anything, since CALR.4g (an earlier, differently-scoped
ticket) already did real work on Marketplace that this milestone table predates:

- The frozen JSON's `equipment-loan` type already declares the full real lifecycle this phase wants:
  `borrow` (with the real `requiresWorkflowsComplete: ["tabletop-club-dues-payment"]` cross-workflow
  guard), `join-queue`/`leave-queue` (`actorInList`-guarded), `return`, `delist`, plus a `kind:
  "transition"` FAB action for `borrow` ("Request loan").
- `_MarketplaceTabSurface`'s `_loadNextPage` (`part02_tab_shell.dart`) already queries the **real engine**
  directly (`_engine.queryInstances`) and filters to instances whose `renderBindings` declare
  `tabId == 'marketplace'` — this is genuinely real, not the shallow `experience.marketplaceListings`
  shape the original milestone text assumed. CALR.4h's live walk directly confirmed the dues guard and
  the transition-FAB work correctly on-device.
- **But this is still a bespoke, one-off widget** (`_MarketplaceTabSurface`/`_MarketplaceBrowseSurface`),
  not routed through the shared `EngineNativeBindingDispatcher`/`_enabledTabs`/`EngineNativeListSurface`/
  `EngineNativeArchetypeCard` pipeline every other tab (Calendar, Giving, Home) now uses — exactly what
  C.7 already anticipated retiring.
- **Automated test coverage for the real lifecycle is thin**: CALR.4g's own test file
  (`v3_calr4g_marketplace_transition_action_test.dart`) only covers FAB visibility (2 tests). The
  well-known `b34_marketplace_browse_test.dart` (16 tests) lives in a **different package**
  (`app/apps/loom_communities_demo/test/`, not `loom_communities_app_shell`) and tests a **separate,
  legacy Shape-B fixture** (`_writeFixture(includeListings: true)`, the old `tabletop-game-loan`
  confirmation-surface pattern) used by other communities — it does not exercise the real frozen
  Tabletop Club JSON's `equipment-loan` type at all. **The dues guard, queue join/leave, and return have
  never been proven by an automated test against the real fixture** — only by CALR.4h's manual
  screenshot walk. B.6 already showed exactly how dangerous that gap is (a real, previously-undiscovered
  engine bug that a live walk never happened to exercise, caught only once an automated test finally
  drove the exact scenario) — treat "looks correct in a screenshot" as unproven until an automated test
  says otherwise.

**Conclusion:** follow Phase B's own exact, proven sequence rather than the original C.1-C.6 breakdown's
implied order (build lifecycle from scratch) — the lifecycle already exists in the JSON and is *probably*
correct; the actual remaining work is (a) proving it with real automated tests against the real fixture,
same rigor as B.4-B.6, and (b) migrating it onto the shared generic pipeline the way B.2/B.3 built
`VotePollArchetypeCard`. Milestones below are re-sequenced accordingly; original C.1-C.8 text kept below
for reference where still accurate.

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

## Milestones (re-sequenced 2026-08-04 per the process note above)

| # | Milestone | Notes |
|---|---|---|
| C.1 | Turn on `tabId: "marketplace"` in `EngineNativeBindingDispatcher._enabledTabs`, gated by `_hasEngineNativeBinding` | Same additive pattern as B.1/GP.2 — checked ahead of `_MarketplaceTabSurface`'s existing dispatch, which stays fully intact and unmodified for every other (non-engine-native) community. No behavior change yet for Tabletop Club — this just opens the pipe. |
| C.2 | Real `EquipmentLoanArchetypeCard` (browse tile + detail) on the generic pipeline | Mirrors `VotePollArchetypeCard`'s pattern exactly: a new bespoke widget dispatched from `case 'equipment-loan':` in `EngineNativeArchetypeCard`, using `RepeaterSurface`'s grid mode (Milestone 1.6) for the tile layout. Renders title/category/condition/availability/holder/queue fields from real `instanceDataSchema`, not hand-picked. |
| C.3 | Borrow + dues guard, proven both directions with a real automated test | The actual headline requirement CALR.4h only proved manually: an unpaid member's `applyTransition('borrow')` genuinely throws (`requiresWorkflowsComplete` guard); a paid-up member succeeds and `availabilityState`/`holderPersonaId` update for real. Mirrors B.4's negative-proof discipline exactly — do not accept "the button is hidden" as proof. |
| C.4 | Join / Leave queue + Return, proven with real automated tests | `actorInList`-guarded button swap (Join vs Leave), `queueLength` computed field, Return clearing `availabilityState`/`holderPersonaId`/`dueDate` — all against the real frozen fixture, not assumed correct because CALR.4h's screenshots looked right. |
| C.5 | Giveaway claim | `equipment-giveaway`'s `claim` transition + `removeFromTileGrid` effect, real test. |
| C.6 | Retire `_MarketplaceTabSurface`/`_MarketplaceBrowseSurface` for Tabletop Club | Only once C.2-C.5 prove the generic pipeline fully replaces it. **`b34_marketplace_browse_test.dart` must stay green unmodified** — it tests a *different*, legacy Shape-B fixture other communities still use; confirm this explicitly rather than assuming, since it lives in a different package (`app/apps/loom_communities_demo/test/`) than every other test this tracker has touched so far. |
| C.7 | Live walk + evidence matrix + random regression re-check | Full-tab audit, same recipe as B.9. |

**Original C.1-C.8 text (2026-07, pre-CALR.4g), kept for reference — largely superseded by the
re-sequenced table above, which reflects what CALR.4g already proved real:**

| # | Milestone | Notes |
|---|---|---|
| ~~C.1~~ | ~~Turn on `tabId: "marketplace"` in the binding dispatcher~~ | Same flip as B.1. |
| ~~C.2~~ | ~~Grid/tile rendering through the generic card~~ | Reuse `RepeaterSurface`'s existing grid mode (built in Milestone 1.6) + Phase A's generic card for tile vs detail, honoring `displayContexts: ["tile"]` / `["detail"]` from the schema. |
| ~~C.3~~ | ~~Borrow / Return lifecycle on real instance data~~ | Effects mutate `availabilityState` / `holderPersonaId` / `dueDate` — no local widget state. |
| ~~C.4~~ | ~~Join / Leave queue, with per-member identity~~ | The `actorInList` guard drives which button shows. Queue position from the computed `queueLength`. |
| ~~C.5~~ | ~~**Cross-workflow dues guard, proven negatively**~~ | Unpaid member: `applyTransition('borrow')` genuinely throws. Pay dues (Phase D — or seed `paid`) → borrow now succeeds. This is the test that matters. |
| ~~C.6~~ | ~~Giveaway claim~~ | Incl. `removeFromTileGrid`. |
| ~~C.7~~ | ~~Retire the bespoke marketplace listing path~~ | Only once the generic pipeline renders it. Keep `b34_marketplace_browse_test.dart` green **unmodified** — it is the strongest regression guard in the repo for this tab. |
| ~~C.8~~ | ~~Live walk + evidence matrix + random regression re-check~~ | Full-tab audit. |

## Definition of done

- [ ] Marketplace renders from JSON `workflowDefinitions`; zero bespoke Dart for the loan/giveaway types.
- [ ] A queued listing **always** has actions (the original bug is now structurally impossible).
- [ ] The dues guard is proven by a genuinely refused transition.
- [ ] `b34_marketplace_browse_test.dart` passes **unmodified**.
