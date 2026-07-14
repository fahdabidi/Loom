# Phase E — Game purchase proposals (Home submit + Admin decide)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). **Blocked on Phase A.**

> **Scoping note.** Firm on scope, light on snippets — detailed kickoffs are written after Phase A's
> human gate, against the revised JSON.

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
| E.1 | Turn on `tabId: "admin"` in the binding dispatcher | Home is already on from Phase B. |
| E.2 | **Live `queryInstances`-bound Repeater** | The second Repeater shape (Phase B built the in-instance-list shape). Bound to a state-filtered query. Test: creating a new pending instance makes a new row appear with no widget rebuild. |
| E.3 | Proposal decision queue on Admin | Approve / Request changes / Reject as real transitions, organizer-gated. |
| E.4 | Member's own proposal status on Home | The `role: actor` bindings; the member sees their real instance's real state. |
| E.5 | **Member-authored creation (grammar addition)** | Close the "create a brand-new instance" gap generically. Serves Phase F too. |
| E.6 | Revise-and-resubmit loop | `changes-requested` → edit → `submit` → `pending` again. |
| E.7 | Delete the old `tabletop-committee-decision` remnants | Ensure nothing still renders the scripted card. |
| E.8 | Live walk + evidence matrix + random regression re-check | Full-tab audit of **both** Home and Admin. |

## Definition of done

- [ ] A member can genuinely author, submit, revise, and resubmit a proposal.
- [ ] The organizer's queue is genuinely live-query-bound — a new submission appears on its own.
- [ ] The member sees the real decision on their **own** proposal (no hardcoded game name anywhere).
- [ ] The creation affordance is a **generic grammar capability**, not a Tabletop-Club special case.
- [ ] One workflow definition drives cards on two different tabs — the `renderBindings` payoff.
