---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.3.0
status: current
last_verified: 2026-08-05
audience: llm-agent
---

# Archetypes — index and status

`cardSurfaceFamily` in a render binding names an **archetype** — the widget family that renders the
instance.

## AGENT: hard rules

1. **MUST NOT invent a `cardSurfaceFamily`.** Only the values below exist. An unknown one produces
   `missing_template` and renders as a generic fallback card.
2. **Check the Status column.** A `🟡 GENERIC` archetype below still renders correctly — live
   transitions, live queries, creation, guards all genuinely work — it is just the shared
   icon+pills+buttons template, not a bespoke widget shaped like its name.
3. **Read the honesty note below** before assuming any archetype "works" the way its name implies.
4. **STANDING RULE for whoever closes an archetype-related milestone:** updating this README's status
   table (and, once an archetype is BOTH rich AND generically reachable, writing its per-archetype doc)
   is part of that milestone's own definition of done. See
   [Loom_Communities_Workflow_Engine_3.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3.md) §5a.

## Status legend

| Status | Meaning |
|---|---|
| ✅ REAL | A genuinely distinct widget with the interactions its name implies, reached purely by declaring the `cardSurfaceFamily` in JSON — no hardcoded per-community wiring |
| 🟡 GENERIC | Reached purely by declaring the `cardSurfaceFamily` in JSON (no hardcoded wiring) — transitions/creation/live-query all genuinely work — but renders via the shared `GenericWorkflowInstanceCard` (icon + title + fact pills + buttons), not a distinct widget |
| ❌ NOT REAL | Does not render or does not work as declared |

**Re-verified 2026-08-05 against Dart source at commit `743395e0`** (tracker 3 Phases B-G, all closed
except G.4/G.5), superseding the 2026-07-17 table below. Every claim in this table was checked by
grepping `EngineNativeArchetypeCard`'s dispatch switch and the actual widget files — not carried
forward from a prior doc claim.

## The dispatch mechanism (read this before the table)

`EngineNativeArchetypeCard.build()` (`part27_engine_native_binding_dispatcher.dart:322-436`) is the
**single** place `cardSurfaceFamily` is switched on. Three branches route to a bespoke widget; every
other value falls to the generic card:

```
case 'event-rsvp'     -> _EventRsvpDetailCard                (part28_engine_native_calendar_surface.dart:1427)
case 'votePoll'       -> VotePollArchetypeCard (repeater/tournament-event)  (part35_votepoll_archetype_card.dart)
case 'equipment-loan' -> EquipmentLoanArchetypeCard           (part36_engine_native_marketplace_surface.dart:369-693)
default                -> GenericWorkflowInstanceCard         (part26_generic_instance_card.dart)
```

`_enabledTabs` (`part27_engine_native_binding_dispatcher.dart:77-84`) now covers **all six** of
Tabletop Club's real tabs — `{'admin', 'calendar', 'giving', 'home', 'marketplace', 'messages'}` —
each gated at the tab-shell level by `_hasEngineNativeBinding(experience, tabId)`
(`part12_persona_and_tabs.dart:497-506`). **For Tabletop Club, every tab now routes through
`EngineNativeListSurface`/`EngineNativeBindingDispatcher`/`EngineNativeArchetypeCard` — none of them
fall back to a legacy per-community `rendererId` widget anymore.** The old hardcoded `'ballot'` tab and
`_TournamentBallotTabSurface`/`_TournamentBallotEngineStore` were deleted outright in Phase B.8 (not
just bypassed). The other bespoke rendererId-keyed widgets the 2026-07-17 table described
(`FormEntryTabSurface`, `StatusTimelineTabSurface`, `NotificationInboxTabSurface`, the old thread-detail
code) still exist as **dead code for Tabletop Club** — the tab-level gate diverts away from them before
the rendererId switch is ever reached — but remain genuinely load-bearing for the other seven,
still-shallow-schema communities. Do not delete them.

## The archetypes (Tabletop Club's 9, re-verified 2026-08-05)

| `cardSurfaceFamily` | Purpose | Status | Evidence |
|---|---|---|---|
| `event-rsvp` | Event with RSVP + capacity + waitlist, a container of cards scoped to a view (Day/Week/Month/Pending), organizer-creatable | ✅ REAL | Per-row `event-rsvp-response` table (one row/member/event) queried live (`part28...:806-844,809`); scoped Day/Week/Month/Pending views (`part28...:983-1002`); real "+ New event" creation via the `creatable` binding (`...jsonc:271-297`). The CAL.1-CAL.4 redesign — spec-only as of 2026-07-17 — is fully implemented, not just proposed. |
| `equipment-loan` | Browse/borrow/queue/return items | ✅ REAL | `EquipmentLoanArchetypeCard` (`part36...:369-693`): real borrow/join-queue/leave-queue/return/return-game/claim buttons driven by live `availableTransitionsAsync`, giveaway-vs-loan branching. Zero fallback to the generic template anywhere in the file (grepped). Flipped from 🟡 PARTIAL — Phase C built the missing per-item interaction. |
| `votePoll` | Ballot: candidates, tally, tie/runoff; also tournament-attendance summary | ✅ REAL | `VotePollArchetypeCard` (`part35_votepoll_archetype_card.dart`), dispatched purely by `cardSurfaceFamily`. The old hardcoded `'ballot'`-tab path this archetype used to require is **deleted** (Phase B.8) — confirmed zero references to `TournamentBallotTabSurface`/`'ballot'` remain in `part02_tab_shell.dart`/`part11_shell_models.dart`. |
| `paymentCheckout` | Dues/donations + receipt | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. Reached purely by `cardSurfaceFamily` (Phase D wired the Giving tab into the pipeline) — genuinely live, but the pay action itself is the shared template, not a bespoke widget. Phase D deliberately declined to build a fake receipt-ID platform service rather than fake the missing capability (`PhaseD_Giving.md`); a real ID-generation service remains a named, honest gap. |
| `approvalQueueItem` | A live queue of items awaiting decision | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. The queue mechanics are genuinely real: a live `queryInstances`-bound Repeater (a new proposal really appears with no polling/hacks), real Approve/Reject/Request-changes transitions (`PhaseE_Proposals.md`) — but no bespoke widget exists. |
| `formEntry` | Author/edit a record (typed controls) | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. The old bespoke checkbox/reminder-offset widget still exists but is dead code for Tabletop Club (diverted before the rendererId switch). |
| `discussionThread` | Threads + messages + compose | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard` + a new **generic** (not Messages-specific) structured-list renderer for the `messages` list-of-maps field. Phase F built real thread list, open/reply, mute/archive, unread tracking, and a "start new thread" creation action — all live-query/engine-backed — deliberately as generic infrastructure, not a bespoke `discussionThread` widget (`PhaseF_Messages.md:63`: "zero bespoke `discussionThread` widget"). |
| `statusTimeline` | Timestamped progression of an item | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. Old bespoke timeline widget is dead code for Tabletop Club (still live for other communities). |
| `notificationInbox` | List of notices, unread state | 🟡 GENERIC | No dispatcher case → `GenericWorkflowInstanceCard`. A bespoke `notificationInbox` widget was explicitly deferred as separate, larger, out-of-scope work (`PhaseB_Home.md:75`); only a small tweak so it shows full body in detail context. |

**All nine are now reached purely by declaring the `cardSurfaceFamily` in JSON — the "is it reachable
at all" axis that used to gate every one of these is fully resolved for Tabletop Club.** Only three
(`event-rsvp`, `equipment-loan`, `votePoll`) currently render a genuinely distinct bespoke widget; the
other six are 🟡 GENERIC — functionally real, visually/interactionally generic.

## Other archetypes (not used by Tabletop Club — unverified this pass, prior claims carried forward)

| `cardSurfaceFamily` | Purpose | Status |
|---|---|---|
| `documentLibrary` | Categorised documents | ❌ NOT REAL (widget exists; no data ever populated it) |
| `stateMachineGrid` / `table` | Browse many items, search/filter/sort | ❌ NOT REAL (except Marketplace's browse shell, now tracked above as `equipment-loan`) |
| `volunteerRoster` | Shifts + capacity meter | ❌ NOT REAL |
| `exportWizard` | Stepped export flow | ❌ NOT REAL |
| `searchAiAnswer` | Query + cited answer | ❌ NOT REAL |
| `audienceSelector` | Multi-select member picker | ❌ NOT REAL |
| `protectedDetail` | Field-level masking by viewer | ⚠️ Permission logic REAL; visual treatment now also real for the masked branch (Phase G.2 fixed the hardcoded-black masking colors) |
| `singleItem` | Exclusive choice (radio/segmented) | ❌ NOT REAL |
| `guidedProcess` | Multi-step wizard with step indicator | ✅ REAL |
| `dashboard` | The Home feed | ⚠️ Real, but section order is hardcoded, not data-driven |

## ⚠️ Honesty note — read this

An earlier audit of all 17 archetypes found that 15 of 17 were the same generic card, reskinned. Tracker
3 has since closed every phase (A through G.3): 9 of 9 Tabletop Club archetypes are now genuinely
reachable purely by JSON declaration, and 3 of 9 (`event-rsvp`, `equipment-loan`, `votePoll`) render a
truly distinct, bespoke interaction. The other 6 are honestly labeled 🟡 GENERIC above — this is a
**deliberate scope decision made and documented in each phase's own closing doc** (Phases D/E/F each
explicitly chose to build the generic queue/list/creation infrastructure rather than a one-off bespoke
widget per workflow type, since that infrastructure is what Phase 3's Skill actually needs). It is not
an oversight and not silently dropped.

**Consequence for the agent:** declaring `cardSurfaceFamily: "volunteerRoster"` (❌ NOT REAL, unused by
Tabletop Club) does not get you a working interaction. Declaring `cardSurfaceFamily: "paymentCheckout"`
(🟡 GENERIC) **does** get you a real, live, transition-capable card — just not a bespoke payment-shaped
one. Do not tell the user an interaction doesn't work when it does (🟡 GENERIC is still fully
functional), and do not tell the user a card is bespoke when it renders through the shared template.

**Tabletop Club is now a finished reference community for the purposes of this rebuild** — every
archetype it declares is genuinely reachable from JSON with no hardcoded per-community wiring, which is
the bar Phase 3 (the Skill) actually needs. See
[Loom_Communities_Workflow_Engine_3.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3.md)'s
Phase G for the closing evidence (G.1-G.3 closed; G.4 is this documentation pass; G.5 is the pending
human sign-off).

`docs/CardSurfaces/` (all 26 files) remains superseded — every file invents a nonexistent
`CommunityXxxApi`. Nothing from it is promoted here.

Per-archetype JSON reference docs, now that generic reachability is confirmed live for all 9:
[`vote-poll.md`](./vote-poll.md), [`equipment-loan.md`](./equipment-loan.md),
[`payment-checkout.md`](./payment-checkout.md), [`approval-queue.md`](./approval-queue.md),
[`discussion-thread.md`](./discussion-thread.md). `calendar-agenda.md` remains **not yet written** —
Phase A's own responsibility, still pending its A.10 human review gate.

Until then, also use:
- [`guide/03-common-patterns.md`](../guide/03-common-patterns.md) — canonical templates (grammar-correct
  JSON; silent on which archetypes actually render richly today)
- [`communities/tabletop-club.md`](../communities/tabletop-club.md) — a full worked community
- **This README's status table above** — the current, honest source for what renders richly right now
