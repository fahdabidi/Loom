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
- **Correction to an earlier draft of this note**: `_MarketplaceBrowseSurface`'s `_loadNextPage`
  (`part02_tab_shell.dart:5566`) does call `_engine.queryInstances(...)`, but `_engine` is **not** the
  real shared community engine — `initState()` (line ~5471) creates its own **private, per-widget-instance
  `WorkflowDatabase.memory()` + `LocalWorkflowEngineApi`**, and `_seedAndLoad()` (line ~5522) re-creates
  instances into it from `widget.listings` (a snapshot, via CALR.4g's projection of the real engine-native
  data into the legacy `LoomMarketplaceListing` shape). This is the **exact same bespoke-per-feature-engine
  anti-pattern** as the `_TournamentBallotEngineStore` deleted in B.8 — it only *looks* real because it's
  seeded from a real snapshot at build time. Any borrow/queue/return mutation happens against this private
  copy and **never reaches the shared engine**. This plausibly explains a gap CALR.4h's own closure notes
  flagged and left unresolved ("the equipment-loan transition-FAB did not appear even after genuinely
  paying dues live... `_completedWorkflowIds` appears not to be recomputed against the freshly-paid
  state") — a real symptom of exactly this disconnection, not a mystery.
- **Conclusion: treat nothing in `_MarketplaceBrowseSurface` as already real for the purposes of this
  phase.** The JSON-declared lifecycle (borrow/dues-guard/queue/return/giveaway) is real and correct; the
  widget that's supposed to drive it against the real shared engine does not yet exist. This phase builds
  it, the same way B.2/B.3 built `VotePollArchetypeCard` against the real shared engine from the start —
  not a migration of working code, a genuine build against the already-real JSON.
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

**Conclusion:** follow Phase B's own exact, proven sequence. The JSON already declares a correct, complete
lifecycle (borrow/dues-guard/queue/return/giveaway) — that part needs no new design. What this phase
actually builds, from scratch, against the real shared engine, is the widget: a real
`EquipmentLoanArchetypeCard` on the generic pipeline (mirroring `VotePollArchetypeCard`'s own build),
proven with real automated tests at B.4-B.6's rigor — not a migration of already-working code, since the
current bespoke widget's data layer is disconnected from the shared engine and cannot be assumed correct
just because it renders plausibly. Milestones below are re-sequenced accordingly; original C.1-C.8 text
kept below for reference where still accurate.

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
| C.1-2 | ✅ Closed (2026-08-05). Turn on `tabId: "marketplace"` in `EngineNativeBindingDispatcher._enabledTabs`; real `EquipmentLoanArchetypeCard` (browse tile + detail) on the generic pipeline | See closure evidence below — a new `part36_engine_native_marketplace_surface.dart` (`EngineNativeMarketplaceSurface` + `EquipmentLoanArchetypeCard`), mirroring `VotePollArchetypeCard`'s pattern, using `RepeaterSurface`'s grid mode (Milestone 1.6). Took 6 fix rounds after the initial dispatch — all independently found, ticketed, and verified by the verification agent, none self-implemented. |
| C.3 | ✅ Closed (2026-08-05, commit `34dbd0ce`). Borrow + dues guard, proven both directions with a real automated test | New engine-level test in `v3_milestone_phasec_marketplace_archetype_test.dart`: an unpaid `tabletop-member` calling `applyTransition('borrow')` on Catan directly genuinely throws `StateError`; after a real `applyTransition('pay', ...)` on `tabletop-club-dues-payment`, the same `borrow` call succeeds and both the transition result and a fresh query show `availabilityState: onLoan`/`holderPersonaId: tabletop-member`. Test-only change (51 lines), verified independently: `flutter analyze` clean, 170/171 green (only the known a11 flake). First-try success, no fix rounds needed. |
| C.4 | ✅ Closed (2026-08-05, commits `43f1c11f` + `bba2f4de`). Join / Leave queue + Return, proven with real automated tests | New engine-level test proving: join-queue is a real mutation (`queuedPersonaIds`/`queueLength` update), the button swaps join↔leave for real, reserve-ahead works on an available (not just on-loan) listing, and Return clears `availabilityState`/`holderPersonaId`/`dueDate` for real. One fix round: the test's first attempt used a numbered persona (`tabletop-member-03`) for `return`'s `allowedPersonaIds` guard, which does a literal-string match against generic role names only — the same guard pitfall documented in Phase B. Verified independently: `flutter analyze` clean, 172/173 green (only the known a11 flake). |
| C.5 | ✅ Closed (2026-08-05, commit `fe66da91`). Giveaway claim | New tests prove `claim` on `listing-old-catan`: engine-level (real `newState: claimed`, `claimedByPersonaId` set) and widget-level (the tile genuinely disappears from the grid after tapping claim). Root cause of the disappearance: the `available`-only `renderBindings` state filter excludes it from the next query — `removeFromTileGrid` itself is presentation-only in this codebase and only closes an open detail dialog, it does not remove grid tiles. First-try success, verified independently: `flutter analyze` clean, 174/175 green (only the known a11 flake). |
| C.6 | ✅ Closed (2026-08-05, commit `e65f46ab`). Retire the now-dead engine-native Marketplace listing projection | Not a full deletion of `_MarketplaceBrowseSurface` — it stays intact for other (non-engine-native) communities, which populate `marketplaceListings` via a *different* raw-JSON path. What was actually dead: `_marketplaceListingsFromEngineNative` (`part15_evidence_catalog.dart`), CALR.4g's projection of engine-native instances into the legacy shape — provably unreachable since `_hasEngineNativeBinding` gates ahead of the `marketplaceListings` fallback unconditionally for any engine-native community. Removed (38 lines). Verified independently: `flutter analyze` clean, 174/175 app-shell green (only the known a11 flake), **and `b34_marketplace_browse_test.dart` 16/16 green, confirmed byte-for-byte unmodified** (SHA-256 checked before/after by the implementation agent, re-run and confirmed passing by the verification agent). First-try success. |
| C.7 | ✅ Closed (2026-08-05, fix commit `ae3282e2`). Live walk + evidence matrix + random regression re-check | Real Android emulator walk (App-Shell-milestone weight, same recipe as B.9) — see closure evidence below. Found and fixed one real bug: computed helper fields leaking as raw unlabeled pills. |

### C.7 closure evidence (2026-08-05)

Real Android emulator walk (`emulator-5554`, freshly built debug APK, fresh Tabletop Club install via the
real "Add local community" flow — extension/init packages sideloaded into the app's private storage since
scoped storage/SELinux block direct file-picker access to `/sdcard`/`/data/local/tmp`, matching this
tracker's established workaround from earlier sessions).

Confirmed live, screenshot-backed, as both Organizer and Member personas:
- Marketplace grid renders the real seeded listings (Catan, Wingspan, Root, Gloomhaven, the retired-Catan
  giveaway, plus real peer-shared `tabletop-game-loan` instances like Azul/Ticket to Ride) through the
  generic pipeline, with category filter chips.
- As Member with dues unpaid: "Request loan" correctly absent on Catan, "Join queue" present instead —
  matches C.3's guard exactly.
- Paid dues for real via the Giving tab's "Pay $15" action, returned to Marketplace: "Request loan" now
  appears on Catan — this is the exact dues-guard-recompute scenario CALR.4h's original manual walk (Phase C
  process note) failed on; confirmed working live end to end.
- Tapped "Request loan" for real: Catan transitioned to `onLoan`, `Holder: tabletop-member` appeared live.
- Tapped "Claim giveaway" on the retired Catan for real: it genuinely disappeared from the grid on the next
  render — live confirmation of C.5's mechanism (state-filtered `renderBindings` exclusion, not
  `removeFromTileGrid`).
- Random regression spot-check: Home, Calendar, and Giving tabs all rendered correctly during the same
  session (dues payment flow itself doubles as a Giving regression check).

**Real bug found by visual inspection** (not caught by any automated test, since none of them asserted
"no unlabeled raw-value pills exist"): every Marketplace card showed two extra pills reading bare "0" and
"true"/"false" with no label — a real accessibility issue too (a screen reader would announce these with zero
context). Root cause: `queueLength`/`isAvailable`, two formula-backed convenience fields in the frozen JSON
meant only for internal guard/formula use, have no `labelTemplate`, and `_factSchema()`'s fallback
(`labelTemplate: field.labelTemplate ?? '{value}'`) rendered them anyway. Fixed on the Dart side (the JSON is
frozen) by excluding any field with a `formula` and no `labelTemplate` from the fact-pill set — a general
fix, not a hardcoded field-name exclusion. Verified independently (`flutter analyze` clean, 174/175 app-shell
green, only the known a11 flake) and re-confirmed live on the emulator after rebuilding: the raw pills are
gone in both tile and detail contexts, real fields (title/category/condition/description/availability)
still render correctly. The same class of issue was separately spotted in Giving (a `receiptStatus` field
shown as its literal field name) — out of scope for Phase C, flagged for Phase D.

### C.1-2 closure evidence (2026-08-05)

Dispatched as one combined ticket (`data/v3_ticket_phasec1_c2_marketplace_pipeline.md`, commit `20471138`),
then required six follow-up fix rounds before the suite was genuinely green — every one independently found
by the verification agent via a real `flutter analyze`/`flutter test` rerun (never by trusting the
implementation agent's own sandbox-blocked self-report), ticketed precisely, dispatched, and re-verified.
None of the fixes were self-implemented.

- **fix1** (`5f4a558b`): dues-guard staleness in `LocalWorkflowEngineApi.availableTransitionsAsync` — it
  didn't recompute `completedWorkflowIds` the way `applyTransition` already did, so a freshly-paid member
  never saw `borrow` (this is the exact gap CALR.4h's manual walk flagged and left unresolved). Also fixed
  the `v3_milestone_a7_binding_dispatch_test.dart` regression from widening `_enabledTabs`.
- **fix2** (`96038a5b`): the real grid-overflow root cause — `RepeaterSurface._buildItem` never wrapped grid
  items in `Expanded`, so cards got unbounded height regardless of the grid cell's real bound. fix1's own
  aspect-ratio tuning attempt hadn't fixed this; the structural fix did.
- **fix3** (`26bd76a6`): correctly fixed one stale test regression, but its "join-queue availability" fix
  was actually wrong — it patched the test's wait behavior without confirming the button ever rendered.
- **fix4** (`f6891a8b`): a real production bug — `EngineNativeMarketplaceSurface` passed an inline
  `rolesForInstance` closure that got a new identity on every rebuild, so
  `EngineNativeBindingDispatcher.didUpdateWidget`'s `identical()` check reloaded the entire grid from the
  engine on every keystroke in search. Fixed by giving the callback a stable identity.
- **fix5** (`5f99b3d1`): found and fixed fix3's actual gap — the pre-existing `v3_calr4g_marketplace_transition_action_test.dart`
  helper tapped the center of a tile, which could land on an inner action button instead of the outer
  detail-open `InkWell`. A genuine test hit-testing bug, not a production defect; confirmed by the
  verification agent independently tracing `availableTransitionsAsync`'s real output for Catan before
  accepting the diagnosis.
- **fix6** (`f55f111a`): the category-filter test wait was vacuous (it waited for a listing that would have
  been visible with or without the filter applied) and the chip tap needed `ensureVisible` first. This
  dispatch was interrupted before its own commit step (process boundary); the verification agent found the
  staged, already-correct diff, independently reran the full suite (169/170, only the known a11 flake), and
  committed it.

Final state: `loom_communities_app_shell` 169/170 green (only the pre-existing, separately-tracked
`v3_milestone_a11_event_rsvp_archetype_test.dart` date-picker flake fails), `loom_workflow_engine` 195/195
green, `flutter analyze` clean on both packages. `b34_marketplace_browse_test.dart` (the legacy-fixture
regression guard, different package) was never touched.

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

- [x] Marketplace renders from JSON `workflowDefinitions`; zero bespoke Dart for the loan/giveaway types
      (C.1-2, C.6 — the last remaining bespoke-Dart shim, the dead engine-native listing projection, is
      removed).
- [x] A queued listing **always** has actions (the original bug is now structurally impossible — C.1-2/C.4:
      `join-queue`/`leave-queue` work on both available and on-loan listings, proven by real
      `applyTransition` calls).
- [x] The dues guard is proven by a genuinely refused transition (C.3: unpaid `applyTransition('borrow')`
      genuinely throws; paid succeeds).
- [x] `b34_marketplace_browse_test.dart` passes **unmodified** (C.6: confirmed byte-for-byte unmodified via
      SHA-256, 16/16 green).

Phase C is fully closed (C.1-2 through C.7, 2026-08-05). Next: Phase D (Giving).
