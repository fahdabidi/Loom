---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.1.0
status: current
last_verified: 2026-07-15
audience: llm-agent
---

# Archetypes — index and status

`cardSurfaceFamily` in a render binding names an **archetype** — the widget family that renders the
instance.

## AGENT: hard rules

1. **MUST NOT invent a `cardSurfaceFamily`.** Only the values below exist. An unknown one produces
   `missing_template` and renders as a generic fallback card.
2. **Check the Status column.** Most archetypes are **being rebuilt right now** (tracker 3). A `NOT REAL`
   archetype currently renders as a generic card regardless of what you declare — you may still declare
   it (the JSON is forward-looking), but do not expect the interaction to work yet.
3. **Read the honesty note below** before assuming any archetype "works".
4. **STANDING RULE for whoever closes an archetype-related milestone (this applies to every future phase,
   not just the ones open today):** updating this README's status table (and, once an archetype is BOTH
   rich AND generically reachable from `cardSurfaceFamily`, writing its per-archetype doc) is part of that
   milestone's own definition of done — not a follow-up task, not something the next session remembers to
   do separately. A milestone that makes `event-rsvp`'s RSVP interaction real, or wires generic
   `renderBindings` dispatch onto a new tab, is **not closed** until this file reflects it, re-verified
   against the actual Dart source (never carried forward from a prior claim). See the Archetype UI Design
   gate in
   [Loom_Communities_Workflow_Engine_3.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3.md),
   which bakes this into each remaining milestone's acceptance criteria explicitly.

## Status legend

| Status | Meaning |
|---|---|
| ✅ REAL | A genuinely distinct widget with the interactions its name implies |
| 🟡 PARTIAL | The browse/list/shell chrome is real, but the per-item action/detail interaction still falls back to the generic template |
| 🔨 REBUILDING | Being made real now; the phase is named |
| ❌ NOT REAL | Currently renders as the generic card (icon + title + fact pills + buttons) |

**Re-verified 2026-07-15 against Dart source (not against prior doc claims)** — several statuses below
changed from the 2026-07-14 table after direct code citation. See
[Loom_Communities_Workflow_Engine_3.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3.md)'s
Archetype UI Design gate for what closes each remaining PARTIAL/❌ before Tabletop Club can exit its build.

## The archetypes (Tabletop Club's 9, re-verified 2026-07-15)

| `cardSurfaceFamily` | Purpose | Status | Evidence |
|---|---|---|---|
| `event-rsvp` | Event with RSVP + capacity + waitlist | ✅ REAL | Bespoke `_EventRsvpDetailCard` with real capacity bar, distinct tone-styled RSVP chips (Going/Maybe/Can't go/Join waitlist) with selected-state highlighting, and a distinct waitlist indicator — dispatched via `cardSurfaceFamily` check at `part28_engine_native_calendar_surface.dart:442` (covers both `event-rsvp` and `tournament-event`). Verified by `v3_milestone_a11_event_rsvp_archetype_test.dart`. |
| `equipment-loan` | Browse/borrow/queue/return items | 🟡 PARTIAL | Real search/filter/grid/pagination (`part02_tab_shell.dart:5814-6263`) — but per-item borrow/queue/return actions still render via the generic template (`part02_tab_shell.dart:6601,6693`) |
| `votePoll` | Ballot: candidates, tally, tie/runoff | ✅ REAL | Per-candidate vote buttons + live tally, candidate detail dialog, deadline/reminder banner (`part02_tab_shell.dart:3387-3600+`, specifically `:3474-3585`) |
| `paymentCheckout` | Dues/donations + receipt | 🟡 PARTIAL | Real amount/purpose header + payment history (`part02_tab_shell.dart:13316+`) — but the pay action itself is the generic template (`:13641-13659`) |
| `approvalQueueItem` | A live queue of items awaiting decision | ❌ NOT REAL | Zero implementation exists — no binding or widget named `approvalQueueItem` anywhere in `lib/src`. Approval-shaped states render through the fully generic `_WorkflowTile` path (`part02_tab_shell.dart:13281-13298` → `part01_local_extension_screen.dart:598-661` → `part05_domain_preview.dart:406+`) |
| `formEntry` | Author/edit a record (typed controls) | ✅ REAL (thin) | Bespoke checkbox + reminder-offset dropdown, engine-backed, not the generic pattern (`part02_tab_shell.dart:3206-3385`) — but only 2 field types deep; needs real type-dispatch for the full `field-types.md` vocabulary before it can carry `creatable` forms generally |
| `discussionThread` | Threads + messages + compose | ✅ REAL | Real inbox list, thread detail, composer, mute/archive, unread tracking (`part02_tab_shell.dart:165-430+`) |
| `statusTimeline` | Timestamped progression of an item | ✅ REAL (display-only) | Bespoke connected-dot vertical timeline (`part02_tab_shell.dart:2890-3037`, `part23_timeline_and_protected_detail.dart:3-58`) — genuinely distinct, but pure display, no interaction to further verify |
| `notificationInbox` | List of notices, unread state | ✅ REAL | Swipe-to-dismiss, mark-read on tap, live-refreshing repeater, unread count (`part02_tab_shell.dart:1022-1250+`) |

## Other archetypes (not used by Tabletop Club — unverified this pass, prior claims carried forward)

| `cardSurfaceFamily` | Purpose | Status |
|---|---|---|
| `documentLibrary` | Categorised documents | ❌ NOT REAL (widget exists; no data ever populated it) |
| `stateMachineGrid` / `table` | Browse many items, search/filter/sort | ❌ NOT REAL (except Marketplace's browse shell, now tracked above as `equipment-loan`) |
| `volunteerRoster` | Shifts + capacity meter | ❌ NOT REAL |
| `exportWizard` | Stepped export flow | ❌ NOT REAL |
| `searchAiAnswer` | Query + cited answer | ❌ NOT REAL |
| `audienceSelector` | Multi-select member picker | ❌ NOT REAL |
| `protectedDetail` | Field-level masking by viewer | ⚠️ Permission logic REAL; visual treatment NOT |
| `singleItem` | Exclusive choice (radio/segmented) | ❌ NOT REAL |
| `guidedProcess` | Multi-step wizard with step indicator | ✅ REAL |
| `dashboard` | The Home feed | ⚠️ Real, but section order is hardcoded, not data-driven |

## ⚠️ Honesty note — read this

An earlier audit of all 17 archetypes found that 15 of 17 were the same generic card, reskinned — an
icon, a title, a subtitle, a row of fact pills, and a row of buttons. The names promised distinct
interaction models; the code delivered one. Tracker 3 has since made real progress: as of 2026-07-15,
re-verification against the actual Dart source (not against prior doc claims) found `votePoll`,
`discussionThread`, `notificationInbox`, `statusTimeline`, and `formEntry` genuinely real for Tabletop
Club. But **`event-rsvp` and `equipment-loan` are only PARTIAL** — their browse/list shell is real, but
the actual per-item interaction (RSVP buttons, borrow/queue/return) still silently falls back to the
generic template — and **`approvalQueueItem` has zero implementation at all.**

**Consequence for the agent:** declaring `cardSurfaceFamily: "volunteerRoster"` (❌ NOT REAL) or even
`cardSurfaceFamily: "event-rsvp"` (🟡 PARTIAL) does **not** get you the full interaction its name implies.
The JSON you write is correct and forward-looking — but do not tell the user an interaction works when
it does not, and do not treat 🟡 PARTIAL as ✅ REAL just because *something* real renders.

**Tabletop Club specifically cannot be considered a finished reference community while any of its 9
archetypes are 🟡 PARTIAL or ❌ NOT REAL** — see the Archetype UI Design gate in
[Loom_Communities_Workflow_Engine_3.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3.md).

## ⚠️ A second, more consequential axis: is the widget reachable from JSON at all?

"REAL" above answers *does a rich widget exist*. It does NOT answer *does declaring
`cardSurfaceFamily: "votePoll"` in a new community's JSON actually produce that widget* — and for the
Skill (which can only ever write JSON), that second question is the one that matters.

**Finding, 2026-07-15:** `votePoll`/`discussionThread`/`notificationInbox`/`statusTimeline`/`formEntry` are
each a real, hand-written, one-off Dart engine-store + widget class, dispatched through a **hardcoded
`rendererId` switch** keyed to a fixed tab (`part02_tab_shell.dart:4063` `case
'TournamentBallotTabSurface':`, fed by a static contract table in `part11_shell_models.dart:1106-1119`
naming a fixed `tabIds: ['ballot']`) — **not** by resolving the instance's own `renderBindings`/
`cardSurfaceFamily` from JSON. A brand-new community declaring `cardSurfaceFamily: "votePoll"` today does
**not** get `_TournamentBallotTabSurface` — there is no generic path from that string to this widget.

**There is real, separate progress on the generic path**: `EngineNativeBindingDispatcher` +
`resolveBindings()` (`part27_engine_native_binding_dispatcher.dart`) genuinely reads a workflow's own
`renderBindings` from a parsed `workflowDefinitions` map (itself genuinely parsed from raw JSON at
`part15_evidence_catalog.dart:237-302`) and resolves them live. **But it is enabled for exactly one tab —
`_enabledTabs = <String>{'calendar'}` (`part27_engine_native_binding_dispatcher.dart:70`).** No other tab
routes through it yet. Whether Tabletop Club's actual running install currently exercises this path for
Calendar, or still falls back to the legacy hardcoded dispatch, was **not verified live this pass** — it
needs an emulator check, not a code read, and is called out as an open item on the gate below.

**Consequence:** none of Tabletop Club's 9 archetypes can currently be documented as "declare this
`cardSurfaceFamily`, get this widget" — the generic wiring the Skill depends on does not yet exist for 8
of the 9 tabs, and is unconfirmed live for the 9th (Calendar). **No per-archetype JSON reference doc is
written yet** — writing one now, before generic reachability is confirmed, would repeat the exact mistake
`docs/CardSurfaces/` made (describing a contract nothing actually honors). They will be written **once
generic `cardSurfaceFamily` dispatch is confirmed live** for each — tracked as part of the Archetype UI
Design gate in
[Loom_Communities_Workflow_Engine_3.md](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3.md).

`docs/CardSurfaces/` (all 26 files) was independently re-audited 2026-07-15 and confirmed **still
superseded** — every file invents a nonexistent `CommunityXxxApi`. Nothing from it was promoted here.

Until a per-archetype doc exists, use:
- [`guide/03-common-patterns.md`](../guide/03-common-patterns.md) — canonical templates (grammar-correct
  JSON; silent on which archetypes actually render richly today)
- [`communities/tabletop-club.md`](../communities/tabletop-club.md) — a full worked community
- **This README's status table above** — the current, honest source for what renders richly right now
