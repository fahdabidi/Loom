---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.3.0
status: current
last_verified: 2026-07-15
audience: llm-agent
derived_from:
  - docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc
  - docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_3.md
  - docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_3_PhaseA_Calendar.md
  - docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_3_GrammarExtensions.md
  - docs/Build Plan V2/Skill/references/community-product-experience-template.md
---

# Tabletop Club Product Experience

Uses the [Community Product Experience Template](../../Build%20Plan%20V2/Skill/references/community-product-experience-template.md).
This is the **reference community** for the engine-native (`experienceSchemaVersion: 2`) grammar — see
[communities/README.md](./README.md) for why. Content below reflects what is **verified real** as of
this doc's `last_verified` date; anything not yet implemented is marked `PROPOSED` or `NOT YET BUILT`
explicitly rather than blended in as if it already works. See §11 for the review that produced this
version.

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Tabletop Club |
| Community type | Board game / hobby club |
| Product promise | Coordinate game nights, tournaments, a shared game library, and dues for a local tabletop gaming club — the reference build proving the engine-native grammar can express a real club, not a synthetic demo. |
| Brand cues | Terracotta accent (`#C4703F`, deeper `#8A5A34` on Giving), warm neutral card fills, dice/game-night imagery, casual-but-organized club tone. |
| What this must not feel like | A generic workflow list, a validator test harness, or a JSON-schema demo. Every card must be the community's own domain language ("Friday game night," "Summer tournament") — never "Workflow: event-rsvp." |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| `tabletop-organizer` | Plans game nights and tournaments, manages the game library, decides purchase proposals, collects dues. | Schedule events, resolve the tournament ballot, approve/reject game purchases, keep the library moving. | Can cancel events and approve/reject proposals — actions with real consequences for other members. | Every event has a real RSVP count; the pending-proposal queue is empty or actively being worked; overdue loans are visible. |
| `tabletop-member` | RSVPs to game nights and tournaments, borrows games from the club library **and from other members' personal collections**, proposes purchases, votes on the tournament ballot, pays dues. | Know what's happening and when, vote for what to play, borrow/return games fairly (club-owned or peer-owned), share their own games with the club, propose a game the club should buy. | Cannot borrow until dues are current (cross-workflow guard); cannot vote unless RSVP'd "going" to the tournament (cross-instance guard); as an owner, approves who borrows their own game. | RSVP status is unambiguous; vote is cast and counted; loan/return state is always current for both club and peer items; proposal outcome is visible on their own submission. |

## 3. Workflow Types: Lifecycle And Data

Ground truth extracted directly from the frozen JSON (11 types) — not reconstructed from memory. Two
real, instructive contrasts worth reading before writing a new community: (1) `equipment-loan`'s states
are `published`/`delisted` (is the listing shown at all) — "on loan" vs. "available" is **data**
(`availabilityState`), coexisting with an independent `queuedPersonaIds` list, exactly the case the
authoring guide's own decision table warns about. (2) `equipment-giveaway`'s states genuinely **are**
`available`/`claimed` — same-sounding word, opposite verdict, because a giveaway item cannot be "claimed
and still available" at once, so no independent data axis is needed.

| Workflow type | Lifecycle (→ states) | Independent facts (→ data) |
| --- | --- | --- |
| `event-rsvp` | `open → cancelled` | who's going/maybe/not-going/waitlisted (per member, simultaneous); title/date/time/location/host/capacity; computed `goingCount`/`seatsRemaining`/`isFull` |
| `tournament-event` | `open → cancelled` | who's going; `minimumAttendance`; `selectedGame` (starts "TBD," set by the ballot via cross-instance effect); computed `accepted`/`quorumMet` |
| `tournament-ballot` | `open → closed` | `outcome`; **query-backed** `ballots` (§ below); computed `isExpiringSoon`/`voteCounts`/`totalVotes`/`winner`/`tiedCandidates`/`isTie` |
| `tournament-vote` | `cast` (single state — no real lifecycle; this type exists purely as rows for `tournament-ballot` to query) | `ballotId`, `voterId`, `choice` |
| `equipment-loan` | `published → delisted` (listing visibility, not loan status) | `availabilityState` (available/loaned) + `holderPersonaId` + `queuedPersonaIds` — all coexist; computed `queueLength`/`isAvailable` |
| `equipment-giveaway` | `available → claimed` | `claimedByPersonaId` |
| `tabletop-game-loan` **(PROPOSED redesign, 2026-07-15 — currently just `open`, one state, zero data)** | `published → delisted` (listing visibility — same axis as `equipment-loan`, for consistency) | `ownerPersonaId` (**new** — which *member*, not the club, owns this game — the field that makes this peer-to-peer); `title`/`category`/`condition`/`description`; `availabilityState` (available/loaned) + `holderPersonaId` + `pendingRequestPersonaId` (awaiting the owner's approval) + `queuedPersonaIds` + `dueDate` — all coexist; computed `queueLength`/`isAvailable` |
| `tabletop-club-dues-payment` | `unpaid → paid` | `receiptStatus`, `paidAt` |
| `game-purchase-proposal` | `draft → pending → changes-requested → approved` / `rejected` | `gameName`, `reason`, `proposedByPersonaId`, `submittedAt`, `decidedByPersonaId`, `decidedAt` |
| `tabletop-meetup-announcement` | `draft → published` | `title`, `body`, `publishedAt` |
| `discussion-thread` | `open → archived` | `subject`, `participantPersonaIds`, `messages`, `unread`; computed `messageCount` |

### `tabletop-game-loan` — peer-to-peer game sharing (PROPOSED, 2026-07-15 review)

**What it's for, and how it differs from `equipment-loan`:** `equipment-loan`/`equipment-giveaway` are
the club's own collectively-owned library (organizer-managed). `tabletop-game-loan` is **any member
sharing a game they personally own with the whole community** — modeled on the
[Book Club shared library](./neighborhood-book-club-product-experience.md)'s `book-shared-library`
(list/edit/delist your own item, request/approve/queue, current-holder + due date, renew, report an
issue), adapted for one item type instead of books/DVDs/games generically.

**Interactions:**
1. **List a game** — any member (`creatable`), pre-filled with `ownerPersonaId = $actor`. Not
   organizer-only — this is the entire point of "peer-to-peer."
2. **Edit / delist** — owner only.
3. **Request to borrow** — any *other* member. If available, becomes `pendingRequestPersonaId` (awaiting
   the owner's approval); if unavailable, joins `queuedPersonaIds`.
4. **Approve / decline a request** — owner only. Approve moves `pendingRequestPersonaId` →
   `holderPersonaId` and sets `dueDate`. This owner-approval gate is the key difference from
   `equipment-loan`: it's *your* game, so *you* decide who borrows it next, not an open-access club rule.
5. **Join / leave queue** — while unavailable.
6. **Return** — holder marks returned; if the queue is non-empty, the next queued member becomes
   `pendingRequestPersonaId` (owner approves again — every hand-off goes through the owner).
7. **Renew** — holder requests more time; only when `size(queuedPersonaIds) == 0` (already expressible
   via a `formula` guard — no grammar change needed for this one).
8. **Report an issue** (lost/damaged) — holder or owner; marks the item unavailable and flags it for the
   owner's attention.

**Still just data, not new states** — every one of the above changes `availabilityState`/
`holderPersonaId`/`pendingRequestPersonaId`/`queuedPersonaIds`/`dueDate` on the *same* `published`
instance; none of it is a lifecycle change. This keeps `tabletop-game-loan` consistent with
`equipment-loan`'s own established shape rather than inventing a parallel modeling style.

**Not yet resolved — flagging honestly rather than guessing:** whether **custody history** (Book Club's
doc separately calls out "current-holder/custody history," beyond just the current holder) needs its own
row-type (mirroring the `tournament-ballot`/`tournament-vote` split) or can stay as a single mutable
field like `equipment-loan` today. Deferred to JSON-authoring time — this doc specifies the product
requirement (history should be inspectable), not the JSON shape for it.

## 4. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Home | Curated feed of what needs the member's attention | Both | Tournament ballot card, next game night, pending proposals (organizer), dues status | Vote / RSVP / decide |
| Calendar | Real month grid of scheduled events | Both | `event-rsvp` and `tournament-event` instances, capacity, RSVP state | RSVP Going/Maybe/Can't go |
| Marketplace | Club-owned library **and member-to-member peer sharing** — browse, borrow, return, give away, or list/lend your own game | Both | Listings (club and peer), availability, current holder, queue, owner (for peer listings) | Borrow / return / give away / **list your own game** |
| Giving | Dues payment | Both | Amount, purpose, cadence, receipt | Pay dues |
| Admin | Organizer decision queue | Organizer | Pending game-purchase proposals, meetup announcements | Approve / reject / request changes |
| Messages | Club discussion threads | Both | Threads, unread state, post/reply | Read / reply / start a thread |

## 4.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| `tabletop-member` | Home, Calendar, Marketplace, Giving, Messages | Tournament ballot, next game night RSVP | Terracotta theme cascades community → tab (Giving is deeper) → workflow; no member-facing Admin tab. |
| `tabletop-organizer` | Home, Calendar, Marketplace, Giving, Admin, Messages | Pending proposal queue, cancel-event controls | Same cascade; Admin tab exists only for this persona. |

**Current build status (Phase A, `experienceSchemaVersion: 2` path):** only **Home** and **Calendar** are
wired to the real engine-native pipeline today; Messages renders (shallow-path carryover). Marketplace,
Giving, and Admin are declared in the frozen JSON (`renderBindings`) but **not yet dispatched** —
Phases C/D/E build that wiring. Do not treat their absence from a live build as a defect; it is the
documented, in-progress state of tracker 3.

**Navigation/breadcrumb requirement — resolved as App Shell scope, not a JSON concern (2026-07-15
review):** back navigation must follow the actual navigation stack the member built by tapping forward,
one level at a time — community list → community home → tab → detail/day view → item detail — never
jump multiple levels at once. **This needs no new grammar.** `renderBindings` already declares *where* a
card appears; whether drilling into it pushes a real route is a rendering-strategy decision the App
Shell must apply uniformly (every "more detail" affordance = a real pushed route, never a local-state
swap on the same screen). Tracked as an App Shell engineering convention, not a product-doc or
grammar item — see `reference/render-bindings.md`.

## 5. Home Screen Requirements

The first screen after opening Tabletop Club must show:

- the club's own identity (name, terracotta branding, organizer/member role blurb) — verified real
- a curated feed of pinned/urgent surfaces (tournament ballot, next game night, pending proposals) — **not
  yet wired**; Phase A's `renderBindings` dispatch currently only honors `tabId: "calendar"`, so Home
  shows "Nothing is pinned yet" until Phase B lands
- no global workflow list or metadata-only screen — verified: the Home card renders the community's own
  description and persona blurb, not a workflow inventory

## 6. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Event/RSVP (Calendar) | title, date, time, location, host, capacity, going/seats-remaining, attendee state | open/full/cancelled/RSVPed | Going, Maybe, Can't go, Join waitlist (only when genuinely full) | parsing capacity from a label string instead of a real computed field |
| **Calendar day detail (PROPOSED — not yet built)** | the tapped date, every event scoped to that day only, a way to create a new event for that day | day-with-events / empty-day | open day, create event for this day (pre-filled with the tapped date via GAP-2's `creatable.prefill`), return to month view | showing every event regardless of the tapped day; no path back to the month grid |
| Tournament ballot | candidates (name/description), per-candidate vote button, live tally, deadline/reminder, tie→runoff | open/closed/runoff | cast vote, view candidate detail | hardcoding the winner instead of computing it |
| Equipment loan/giveaway (Marketplace — club library) | item, availability, current holder, queue, loan vs. giveaway mode | available/queued/loaned/given | browse, borrow, return, give away | borrow allowed while dues are unpaid |
| **Peer game sharing (Marketplace — PROPOSED, 2026-07-15 review)** | item, **owner** (which member), availability, current holder, pending-approval state, queue, due date | available/pending-approval/loaned/queued/delisted | list your own game, edit/delist, request to borrow, approve/decline (owner), join/leave queue, return, renew, report an issue | showing a peer listing with no owner identity; auto-approving a borrow request without the owner's say |
| Dues payment (Giving) | amount, purpose, cadence, receipt | unpaid/paid | pay | abstract payment chip with no receipt |
| Game purchase proposal | game name, reason, decision state | draft/pending/changes-requested/approved/rejected | propose (member), approve/reject/request changes (organizer) | a pre-seeded fake draft instead of a real member-authored proposal |
| Discussion thread (Messages) | subject, participants, messages, unread state | open/archived | post, reply, mark read, **start a new thread** | no way to start a new thread at all |

## 7. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| `event-rsvp` | member | Calendar event detail | capacity, going count, seats remaining, Going/Maybe/Can't-go, waitlist gated by `size(goingPersonaIds) >= capacity` | `applyTransition`, formula-computed `goingCount`/`seatsRemaining`/`isFull` | A.8 widget tests; A.10 live walk (Going 12→13, seats 8→7, confirmed on-device) |
| `tournament-event` | member | Calendar event detail | accepted count, actor-in-list-guarded "I'm going"/"Can't make it" | `actorInList` guard, `accepted` formula | A.8 widget tests |
| **Calendar day detail (PROPOSED)** | member | new day-scoped screen, reached by tapping a date cell | only that day's events, a create-event affordance | new App Shell navigation route (no grammar needed, §4.1) + `renderBindings[].creatable` with `prefill: { "eventDate": "{context.date}" }` (see [Grammar Extensions](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3_GrammarExtensions.md), GAP-2 addition) | none yet — ticket not written; blocked on Phase A′ |
| `tournament-ballot` / `tournament-vote` | member | Home ballot card | per-candidate vote button, live `groupCount` tally, deadline | cross-instance eligibility guard, `createInstance` (vote-as-row), `branch`+`createInstance` (runoff) | Blocked on Phase A′ (GAP-1 transition inputs, GAP-4 query-backed `source`) then Phase B |
| `equipment-loan` / `equipment-giveaway` | member | Marketplace listing (club library) | availability, current holder, queue, dues-paid gate | cross-workflow guard (`requiresWorkflowsComplete: ["tabletop-club-dues-payment"]`) | Phase C |
| `tabletop-game-loan` (PROPOSED redesign) | member (owner + borrower) | Marketplace listing (peer-shared) | owner identity, availability, pending-approval, current holder, queue, due date, renew/report-issue | `renderBindings[].creatable` (GAP-2) for listing your own game; owner-approval is plain guarded transitions — no new grammar beyond GAP-2 | Blocked on Phase A′ (GAP-2), then Phase C; no ticket written yet |
| `tabletop-club-dues-payment` | member | Giving | amount, receipt | `paymentCheckout` archetype | Phase D |
| `game-purchase-proposal` | member (author) / organizer (decision) | Home (submit) / Admin (queue) | proposal state, live pending queue | `renderBindings[].creatable` (GAP-2) | Blocked on Phase A′, then Phase E |
| `discussion-thread` | member | Messages | thread list, unread, post/reply, **start new thread** | `renderBindings[].creatable` (GAP-2) for thread creation | Blocked on Phase A′, then Phase F |

## 8. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| `event-rsvp` | member picks Going/Maybe/Can't go | organizer sees live `goingCount` | past events remain visible read-only | Going hidden/replaced by Join waitlist when full | non-member cannot RSVP |
| **Calendar day detail (PROPOSED)** | member taps a date, sees that day's events, may create a new one | organizer sees the same day view for events they host | a day with no events shows an empty state, not an error | create-event action hidden for personas without a creation-eligible role, if any such restriction is added | back navigation must return to month view, not the community home |
| `tournament-ballot` | member casts one vote per ballot | organizer/all members see live tally | closed ballots show final tally read-only | vote button hidden once ineligible or ballot closed | non-attendee cannot vote (cross-instance guard) |
| `equipment-loan` | member requests/returns | owner/organizer sees queue and custody | past loans remain visible | borrow disabled while dues unpaid | — |
| `tabletop-game-loan` (PROPOSED) | member requests to borrow, joins/leaves queue, renews, reports an issue | **owner** (a specific member, not the organizer) approves/declines requests and sees queue/custody for *their own* listing | past listings and completed loans remain visible | request-to-borrow disabled for the owner on their own item; approve/decline hidden from everyone except the owner (`formula: "ownerPersonaId == $actor"`); renew disabled while queue is non-empty | non-owner cannot approve/decline; borrow disabled while dues unpaid (same cross-workflow guard as `equipment-loan`) |
| `game-purchase-proposal` | member submits/edits while in draft or changes-requested | organizer sees live pending queue | approved/rejected proposals are read-only to the author | approve/reject hidden from non-organizer | non-organizer cannot decide |

## 9. Content And Seed Data Requirements

The frozen JSON (11 workflow types, 17 instances) already provides realistic seed data: two same-date
events (Friday game night, capacity 20/12 going; Summer tournament, min. attendance 8/accepted 8), four
real vote rows (catan×2, wingspan×1, azul×1 — winner computed, not seeded), club game listings (Catan,
Wingspan, Root, plus a giveaway), a dues-payment instance, two proposals (one approved, one pending), one
announcement, and two discussion threads. Use this data for evidence screenshots — do not invent parallel
fixtures.

**`tabletop-game-loan` redesign (PROPOSED) will need its own seed data once authored** — the existing
`equipment-loan`/`equipment-giveaway` listings are club-owned (`ownerPersonaId` = the organizer or no
owner field at all) and don't exercise the new peer-to-peer shape. At minimum: one member-owned listing
with `ownerPersonaId` distinct from the organizer and `availabilityState: available`; one with an active
`holderPersonaId` + `dueDate` and a non-empty `queuedPersonaIds` (so the queue/approval UI has something
real to show); one `pendingRequestPersonaId` awaiting the owner's approval. Do not reuse the club-library
fixtures for this — the whole point being verified is that *members*, not just the organizer, can own
and approve loans of their own games.

## 10. Visual And Interaction Standard

- Terracotta accent cascades community → tab (Giving deepens to `#8A5A34`) → workflow; every surface must
  read its color from the resolved `LoomCardTheme`, never a raw accent or ambient Material default
  (A.9 closed the two real bugs of this kind; see [reference/theming.md](../reference/theming.md)).
- Cards use the generic schema-driven instance card (A.6) — fields from `instanceDataSchema`, actions
  from `availableTransitionsAsync` — never a bespoke per-workflow widget.
- **Navigation must follow a real breadcrumb/back-stack model (App Shell scope, 2026-07-15 review; see
  §4.1 — needs no grammar change):** today's back arrow (see the app-bar `←` next to "Tabletop Club")
  must take the member back exactly one level in the navigation they actually traversed, not out to an
  arbitrary ancestor. This applies uniformly: community list → community home → tab → detail (e.g.
  calendar day view) → item detail.
- **Calendar date-cell tap must open a day-scoped view (PROPOSED, 2026-07-15 review; needs the GAP-2
  `prefill` addition — see [Grammar Extensions](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3_GrammarExtensions.md)):**
  tapping a date box in the month grid opens that day — showing only that day's events (filtered, not
  the whole month's agenda) and an affordance to create a new event on that day, pre-filled with the
  tapped date. Back from the day view returns to the month grid, not to Home.

## 11. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| A.10 live emulator walk, 2026-07-14/15 | no | minor — `tournament-event.minimumAttendance` has no `labelTemplate`, renders its raw field name with no value | none (JSON-authoring gap, not a product-spec gap) | fix in either the JSON (add `labelTemplate`) or A.6's generic-card fallback; deferred to A.10's own triage | open |
| Product request, 2026-07-15 — peer-to-peer game sharing | **yes** — no member-to-member game-sharing model existed; `tabletop-game-loan` was a one-state, zero-data stub with no owner concept, no queue, no approval flow | partly closed — `tabletop-game-loan` is now authored in the frozen JSON as a real `published→delisted` type with owner-gated approve/decline/delist, request/queue/return/renew/report-issue, and three seeded peer listings (validator-invariant clean); remaining gaps are app-shell runtime loading (milestones 1.27–1.31) plus four inline `NEEDS IMPLEMENTATION` items | §2/§3/§4/§6/§7/§8/§9 updated; JSON `tabletop-game-loan` redesigned (owner-gated via `formula: "ownerPersonaId == $actor"`, no new grammar beyond forward-looking GAP-2 `creatable`); the two `equipment-loan`/`equipment-giveaway` `linkedWorkflowId` refs to the old stub removed | inline `NEEDS IMPLEMENTATION` in the JSON: auto-set owner on create (GAP-2 creator binding), auto-promote queue head on return (no list-head fn), compute/extend due date (no date-returning fn). No app-shell ticket written | open |
| Multi-user login, 2026-07-15 | **no** — the per-individual identity gap was correctly identified as a platform-service limitation in the prior review | closed — `LoomAuthApi`/`LocalAuthApi` (see `docs/references/reference/platform-services.md` §Identity) provides a real identity contract with seeded demo accounts; the app now passes individual account ids to engine calls via `resolveEnginePersonaId()`, making `ownerPersonaId == $actor` correctly distinguish individuals | Added Identity section to `platform-services.md`; removed the "per-individual identity (platform service)" caveat from the `tabletop-game-loan` review entry | `app/packages/core/loom_communities_app_shell/lib/src/part29_auth_api.dart`, `part30_local_auth_api.dart`, `part31_auth_screens.dart`, `part01_local_extension_screen.dart`, `part25_engine_native_community_store.dart`, `part28_engine_native_calendar_surface.dart`, `app/packages/core/loom_workflow_engine/lib/src/evaluator/guard_evaluator.dart`, `transition_evaluator.dart`, `local_workflow_engine_api.dart` | closed |
| Human review, 2026-07-15 | **yes** — this doc had no navigation/breadcrumb model, no calendar day-detail interaction, and no explicit states-vs-data split documented at all | yes — back navigation doesn't follow a real stack; tapping a date cell doesn't open a day view or allow event creation | Added §3 (Lifecycle/Data per type), §4.1 navigation resolution (App Shell scope, no grammar), §6/§7/§8 Calendar day-detail rows, §10 interaction standard entries (this revision) | Build a real navigation back-stack for the App Shell; build a day-detail route for Calendar (filtered events + create-event, pre-filled date) | open — product doc updated first, per this template's own rule; grammar proposed in [Grammar Extensions](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3_GrammarExtensions.md) (awaiting sign-off); UI ticket not yet written |
