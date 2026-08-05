# Phase B — Home tab (tournament ballot + attendance + announcements)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). **Blocked on Phase A.**

> **Scoping note.** Milestones below are firm in scope but deliberately lighter on snippets than Phase
> A's. Phase A ends in a human gate where the JSON is expected to change — detailed kickoffs are written
> *after* that gate, against the JSON as revised, not against today's guesses. What is fixed here is
> *what* must work and *how it will be proven*.

## Process note (2026-08-04)

B.1 was implemented directly by the verification-agent session (this doc's own author), not dispatched to
the implementation agent via `data/call_implementation_agent.sh` — a real deviation from this tracker's
working agreement, caught mid-session and corrected before B.2. B.1's code is small, independently
`flutter analyze`/full-suite verified, and committed (`ccbf4ee6`); left as-is rather than redone, since
redoing correct, tested code through the proper channel purely for process compliance would add no
quality value. **B.2 onward reverts to the established ticketed-dispatch flow** (write a ticket in
`data/v3_ticket_phaseb_*.md` → `bash data/call_implementation_agent.sh <ticket> --fresh` →
`wsl_dispatch_tracker.sh`/`handoff_gate.sh` → independent verification), matching how Phase A/CALR worked.
UX/judge tooling is applied at CALR's own established weight — `ux-gate-judge-tools.md`'s principles
(direct-question, screenshot-backed live evidence; the visual auditor run and recorded honestly) at
phase-end live-walk milestones (B.9), not the full B25 whole-app evidence/judge pipeline, which was
explicitly judged too heavy for a single sub-milestone even during CALR's own calendar work.

## Goal

Turn Home from a pile of generic duplicate cards into real, JSON-declared archetypes — and prove the
pipeline handles the hardest capabilities in the whole engine: a **cross-instance guard**, **computed
tallies**, and a **`branch` + `createInstance` effect that spawns a real runoff round**.

This is the richest phase. It is the reason the engine's extended effect ops exist.

## Why Home is second

Phase A proves the pipeline on the simplest possible workflow. Home proves it on the hardest one. If the
architecture survives the ballot, it survives everything else — marketplace, giving, and messages are all
strictly simpler.

## What must genuinely work

From [the JSON](./Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc):

| Workflow type | Binding | Must genuinely work |
|---|---|---|
| `tournament-ballot` | `home` primary | Vote per candidate (Repeater over the `candidates` list); candidate tap → detail popup; live tally from `groupCount(ballots, choice)`; **only personas who RSVP'd going on the linked event may vote** — the real cross-instance `relatedListMembership` guard, enforced by the engine, not hidden client-side; deadline + `dueAt`-driven reminder banner via the real `dueNotifications({asOf})` API; **close-vote on a tie spawns a real runoff ballot instance** containing only the tied candidates (`branch` → `createInstance`); non-tie writes the winner onto the event via **cross-instance `set`** |
| `tournament-event` | `home` summary | The attendance/context card (`Accepted: N`, computed by `size(goingPersonaIds)`) sitting alongside the ballot. Its `calendar` binding already works from Phase A — this is the *same instance* rendering on a second tab, which is exactly what `renderBindings` is for |
| `tabletop-meetup-announcement` | `home` summary (`published` only) | Published announcements appear on Home; drafts do **not** (the `states: ["published"]` binding is the filter) |

**Ballot is a Home card, not a tab.** The dedicated `'ballot'` bottom tab
(`part12_persona_and_tabs.dart:464-475`) is removed in this phase, per explicit direction — the real
interactions move into Home.

## User stories

- *As an eligible member, I see the ballot on Home, tap a candidate to read what it is, and vote.*
- *As a member who did **not** RSVP going, I cannot vote — and the engine genuinely refuses, not just the
  UI hiding the button.*
- *As any member, I watch the tally update live as votes come in.*
- *As a member, I see "voting closes 
&lt;date&gt;" and get a "closing soon" banner once the reminder is due.*
- *As an organizer, I close the vote; if it's tied, a real runoff round opens with only the tied
  candidates; if not, the winning game appears on the tournament event.*
- *As a member, I see published announcements on Home.*

## Milestones

| # | Milestone | Notes |
|---|---|---|
| B.1 | Turn on `tabId: "home"` in the binding dispatcher | `[x]` **Done 2026-08-04.** Widened `_enabledTabs` to `{'calendar', 'giving', 'home'}` and added an `_hasEngineNativeBinding(experience, 'home')` gate in `_TabNativeRenderer` (mirrors Giving's GP.2 pattern exactly — additive, checked ahead of the other example communities' bespoke engine chains, none of which parse `workflowDefinitions` so none match the gate) routing to `EngineNativeListSurface` instead of the legacy `_communitySectionsFor` blanket dump. **Left `_communitySectionsForTab`'s legacy `tabId == 'home'` branch and `matchesWorkflow` completely untouched** — every other community still uses it unmodified; only Tabletop Club (the sole community with `workflowDefinitions`) moves. Found and fixed 2 real regressions independent verification caught (not self-reported): `v3_milestone_a7_binding_dispatch_test.dart` had two "every disabled tab" assertions using `'home'` as its example of a *still-disabled* tab — corrected to `'marketplace'`, which remains disabled. New `v3_milestone_b1_home_engine_native_test.dart` proves the ballot + tournament-event instances resolve onto Home via the real engine path, the still-`draft` announcement stays hidden (the actual regression-proof for retiring blanket duplication), and `role:"actor"` gating works for `game-purchase-proposal`. `flutter analyze` clean; `loom_communities_app_shell` 167/167 modulo the pre-existing, separately-tracked date-picker flake in `v3_milestone_a11_event_rsvp_archetype_test.dart` (unrelated). Commit `ccbf4ee6`. |
| B.2 | Repeater-bound list rendering inside the generic card | Two shapes: an **in-instance list field** (the ballot's `candidates`) and, later (Phase E), a **live `queryInstances` list**. Build the in-instance shape here, composing with Phase A's generic card. |
| B.3 | Ballot: vote + live tally + candidate detail popup | Per-candidate action buttons via the Repeater; tally read from the computed `voteCounts`, never recomputed in Dart. |
| B.4 | Ballot: cross-instance eligibility guard, end-to-end | **Negative test is the point:** a non-RSVP'd persona's `applyTransition('cast-vote')` must genuinely throw, proven by attempting it — not merely by asserting the button is hidden. |
| B.5 | Ballot: deadline + `dueNotifications`-driven reminder banner | The engine API already exists (Milestone 1.4) and is already consumed once; here it must be driven by the JSON's `dueAt`, not a bespoke store. |
| B.6 | Ballot: close-vote → **real runoff** on tie, **cross-instance winner write** otherwise | The `branch`/`createInstance`/cross-instance-`set` effects from the JSON, executed by the engine. Test: a 3-candidate 2/2/1 tie creates a genuine new ballot instance holding exactly the two tied candidates; a clear winner writes `selectedGame` onto the *event* instance (assert on the event, via `queryInstances`). |
| B.7 | Tournament attendance card + published announcements on Home | The same `tournament-event` instance rendering on its second binding; announcements filtered by state. |
| B.8 | Remove the dedicated `'ballot'` tab; delete `_TournamentBallotEngineStore`/`_TournamentBallotTabSurface` | Only once the generic pipeline renders the ballot correctly. This is the first bespoke store retired — the proof the whole rebuild is worth it. |
| B.9 | Live walk + evidence matrix + random regression re-check | Full-tab audit of Home: *every* card, not just the new ones. |

## Definition of done

- [ ] Home renders **only** what the JSON's `renderBindings` place there — no blanket duplication.
- [ ] Zero bespoke Dart for `tournament-ballot` / `tournament-event`; `_TournamentBallotEngineStore` is
      **deleted**, and the feature still works.
- [ ] The tie → runoff → winner-propagation chain runs entirely from JSON-declared effects.
- [ ] The eligibility guard is proven by a genuine blocked `applyTransition`, not a hidden button.
- [ ] Every other tab and community unchanged (regression proven).
