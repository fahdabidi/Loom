# Phase E — Game purchase proposals (Home submit + Admin decide)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). Phase A, B, C, and D are all closed.

## Process note (2026-08-05, before starting)

Investigated current reality before dispatching anything — same discipline as Phase C/D. Unlike those two,
this doc's own milestone table (E.1-E.8 below) already existed and needed no re-sequencing. But real prior
work from *other* phases already closes two of these milestones without ever being credited here:

- **E.5 (member-authored creation grammar) is already done.** Phase A′'s GAP-2 closure (2026-07-16,
  `cfb98334` and preceding commits) built a real, community-agnostic, tab-agnostic creation FAB
  (`_CreatableWorkflowAction`/`_CreatableActionFab` in `part01_local_extension_screen.dart`,
  `EngineNativeArchetypeCreationCard`/`GenericWorkflowCreationCard`) that scans *any* tab's
  `workflowDefinitions` for a creation-shaped `renderBinding` — not a Tabletop-Club special case, and not
  scoped to `_enabledTabs`. This is exactly the grammar capability E.5 asked for, already serving Calendar
  (where it was introduced) and, once Home was enabled in Phase B, already available to
  `game-purchase-proposal` too.
- **E.7 (delete old committee-decision remnants) is already effectively true.** `tabletop-committee-decision`
  has **zero production code** anywhere in `lib/src` — it survives only inside a couple of tests'
  self-contained legacy JSON fixtures (`_legacyExperience()`-style hand-written pre-V3 shapes in
  `v3_milestone_a4_engine_native_parsing_test.dart` and two `loom_communities_demo` tests), which exercise
  an unrelated legacy path, not the frozen V3 JSON. Nothing needs deleting from production code; only
  confirming this stays true.
- **What's genuinely open**: `'admin'` is **not** in `_enabledTabs`
  (`part27_engine_native_binding_dispatcher.dart`) — the organizer's decision queue is unreachable (E.1).
  Home's actor-facing bindings (compose/status) likely already render live today given the generic
  infrastructure above, but **no test anywhere asserts this** — not even a "Propose a game" text check (E.2,
  E.4). No test exercises approve/reject/request-changes (E.3) or the revise-resubmit loop (E.6). All of
  this needs real, first-time proof — not a migration of working code, matching this tracker's own repeated
  precedent (Phase B.6, Phase C's process note) that "looks like it should work" is not the same as proven.

**Conclusion**: close E.5/E.7 now with the evidence above; build and prove E.1-E.4/E.6 for real; E.8 live
walk last, same recipe as B.9/C.7/D.7.

## Goal

Build the feature that **replaces the old scripted "committee decision" card** — and, in doing so, prove
the two capabilities no other phase covers: a **live `queryInstances`-bound list** (new items appear
without a UI rebuild) and **member-authored instance creation**.

## Why this replaced the old card

The previous `tabletop-committee-decision` workflow asserted *"A member proposed buying a copy of
Wingspan"* as a scripted fact — with **no workflow anywhere that let a member propose anything**. It
modeled only the back half of a two-sided interaction. A fake proposal feeding a real decision is
incoherent, so both halves are now real.

**This is one feature spanning two tabs** — which is exactly what `renderBindings` are for. Building the
workflow once lights up *both* surfaces:

| Binding | Who | Surface |
|---|---|---|
| `draft` / `changes-requested` → `home`, role `actor` | Member | Compose / revise the proposal (`formEntry`) |
| `pending` / `approved` / `rejected` → `home`, role `actor` | Member | Watch **their own** proposal's real status |
| `pending` → `admin`, role `receiver` | Organizer | The **live pending queue** — decide |

## The two hard capabilities

**1. Live query-bound list.** The organizer's queue is a Repeater bound to
`queryInstances(workflowType: game-purchase-proposal, state: pending)`. A newly submitted proposal
**simply appears** on the next read — no bespoke "new item arrived" code. This is the pattern the whole
archetype audit said the codebase was missing everywhere (notifications, messages, events).

**2. Member-authored creation — a known grammar gap.** The engine can `createInstance` (as an *effect*),
and an instance can start in `draft` and be edited via `editableFields`. But there is **no declarative way
to say "this workflowType is member-creatable, show a + New affordance"**
(see [JSON_Schema_Versions.md](./Loom_Communities_Workflow_Engine_JSON_Schema_Versions.md), "Known
not-yet-in-grammar").

**This phase must close that gap** — it is the same gap that blocks Messages' "start a new thread"
(Phase F), so solving it once serves both. Design it as a real, community-agnostic grammar addition
(e.g. a `creatableBy` / creation `renderBinding`), not a Tabletop-Club special case.

## User stories

- *As a member, I propose a game for the club to buy — writing a real title and reason.*
- *As a member, I submit it, and it really enters the organizer's queue.*
- *As an organizer, I see every pending proposal in a live list — new ones appear without me doing
  anything.*
- *As an organizer, I approve / request changes / reject a specific proposal.*
- *As the proposing member, I see the real outcome on **my** proposal — not a hardcoded "Wingspan"
  string.*
- *As a member whose proposal needs changes, I revise and resubmit it.*

## Milestones

| # | Milestone | Notes |
|---|---|---|
| E.1 | ✅ Closed (2026-08-05, commit `55990a87` + fix1 `fea3e095`). Turn on `tabId: "admin"` in the binding dispatcher | Home is already on from Phase B. Took one fix round: the tab-visibility gate initially checked *any* transition's guard in the whole definition (a member-only `submit` transition made the tab wrongly visible to members too); fixed to scope to only transitions reachable from the admin-bound states. |
| E.2 | ✅ Closed (same commits). **Live `queryInstances`-bound Repeater** | Proven with distinctively-titled proposals submitted mid-test, confirmed to appear in the organizer's live Admin queue — not a coincidence of seed data. |
| E.3 | ✅ Closed (same commits). Proposal decision queue on Admin | Approve/reject/request-changes proven as real, organizer-gated transitions; confirmed a member has neither the actions nor Admin-tab access. |
| E.4 | ✅ Closed (same commits). Member's own proposal status on Home | Proven for approved/rejected/changes-requested outcomes via the real widget tree and a fresh engine query, using the proposer's actual submitted title, not a hardcoded string. |
| E.5 | ✅ Closed (Phase A′ GAP-2, 2026-07-16, commit `cfb98334`; confirmed still real and tab-agnostic this session). **Member-authored creation (grammar addition)** | Close the "create a brand-new instance" gap generically. Serves Phase F too. |
| E.6 | ✅ Closed (2026-08-05, same commits + fix2 `a46e675c`/fix3 `6a351964`). Revise-and-resubmit loop | `changes-requested` → edit → `submit` → `pending` again, proven with a real distinctive revised title reappearing in the Admin queue. Took two follow-up fix rounds — both the same class of finder ambiguity: a `changes-requested`/`draft`-state card is *itself* the live editable form, so its title renders as both a static fact pill and the `EditableText` field's value simultaneously; bare `find.text(...)` assertions against such a card need scoping to the specific fact-pill key. |
| E.7 | ✅ Closed (confirmed 2026-08-05 — nothing to delete). Delete the old `tabletop-committee-decision` remnants | Confirmed zero production code references `tabletop-committee-decision` anywhere in `lib/src`; it survives only in two tests' self-contained legacy JSON fixtures, an unrelated pre-V3 path. Nothing to delete. |
| E.8 | ✅ Closed (2026-08-05). Live walk + evidence matrix + random regression re-check | See closure evidence below. |

### E.8 closure evidence (2026-08-05)

Live walk on the same real Android emulator used throughout this session (rebuilt APK with all E.1-E.7
fixes, fresh Tabletop Club install):

- As Member: the real "Propose a game" FAB opens the real, generic (not Tabletop-special-cased) creation
  form (`Game Name`/`Reason` fields) — live confirmation of E.5's grammar-based creation infrastructure
  actually reaching this workflow.
- Switching to Organizer: the tab bar now shows 5 tabs (Home/Calendar/Marketplace/Giving/Admin, plus a
  pre-existing Messages tab) — confirmed the Admin tab is visible to the organizer.
- Admin tab renders the real live pending queue: the seeded "Brass: Birmingham" proposal
  ("Proposed by tabletop-member") with real Approve / Request changes / Reject buttons, exactly matching
  E.3's design.
- Tapped **Approve** for real: the card genuinely disappeared from the pending queue on the next render —
  live confirmation of E.2's live-query-bound behavior, the actual headline requirement of this phase.
- Random regression: the Admin tab's *other* workflow (`tabletop-meetup-announcement`'s draft/publish form)
  rendered correctly alongside the proposal queue in the same scroll view — no interference between the two
  workflows sharing the tab.
- Full automated suite green throughout: `loom_communities_app_shell` 175/176 (only the known a11 flake).

## Definition of done

- [x] A member can genuinely author, submit, revise, and resubmit a proposal (E.1-E.4/E.6).
- [x] The organizer's queue is genuinely live-query-bound — a new submission appears on its own (E.2).
- [x] The member sees the real decision on their **own** proposal (no hardcoded game name anywhere) (E.4).
- [x] The creation affordance is a **generic grammar capability**, not a Tabletop-Club special case (E.5).
- [x] One workflow definition drives cards on two different tabs — the `renderBindings` payoff (confirmed
      live: `game-purchase-proposal` renders on Home for the member and Admin for the organizer).
