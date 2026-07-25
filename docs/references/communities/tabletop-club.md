---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.8.0
status: current
last_verified: 2026-07-25
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
1. **List a game** — any member (`renderBindings[].actions[]`, `kind: "create"`, `scope: "tab"`),
   pre-filled with `ownerPersonaId = $actor`. Not organizer-only — this is the entire point of
   "peer-to-peer."
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
| Event/RSVP (Calendar) — **REDESIGNED 2026-07-17, spec written, PROPOSED/not yet built** | title, date, time, location, host, capacity, going/seats-remaining, per-member response state (as `event-rsvp-response` rows, not a list field) | open/full/cancelled/RSVPed | Going, Maybe, Can't go, Join waitlist (only when genuinely full), **organizer: create a new event** | parsing capacity from a label string instead of a real computed field; a stored response count instead of a live `groupCount` over response rows |
| **Calendar Day/Week/Month/Pending views (PROPOSED — not yet built)** | four view modes on the same calendar surface: 1×1 day, 7×1 week (one card per day), 7×6 month (existing grid), and an unbounded **Pending** view (events the viewer has not yet responded to, regardless of date) | day/week/month/pending, each showing minimized event cards that expand to the full RSVP card on tap | switch view mode; tap a date cell in month view to jump to that day; tap a minimized card to expand it (accordion — one expanded at a time); organizer: create a new event for this day | showing every event regardless of the selected scope; auto-expanding a card by default instead of starting minimized; conflating "Pending" with the bounded day/week/month views |
| Tournament ballot | candidates (name/description), per-candidate vote button, live tally, deadline/reminder, tie→runoff | open/closed/runoff | cast vote, view candidate detail | hardcoding the winner instead of computing it |
| Equipment loan/giveaway (Marketplace — club library) | item, availability, current holder, queue, loan vs. giveaway mode | available/queued/loaned/given | browse, borrow, return, give away | borrow allowed while dues are unpaid |
| **Peer game sharing (Marketplace — PROPOSED, 2026-07-15 review)** | item, **owner** (which member), availability, current holder, pending-approval state, queue, due date | available/pending-approval/loaned/queued/delisted | list your own game, edit/delist, request to borrow, approve/decline (owner), join/leave queue, return, renew, report an issue | showing a peer listing with no owner identity; auto-approving a borrow request without the owner's say |
| Dues payment (Giving) | amount, purpose, cadence, receipt | unpaid/paid | pay | abstract payment chip with no receipt |
| Game purchase proposal | game name, reason, decision state | draft/pending/changes-requested/approved/rejected | propose (member), approve/reject/request changes (organizer) | a pre-seeded fake draft instead of a real member-authored proposal |
| Discussion thread (Messages) | subject, participants, messages, unread state | open/archived | post, reply, mark read, **start a new thread** | no way to start a new thread at all |

## 7. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| `event-rsvp` (REDESIGNED, PROPOSED) | member | Calendar, scoped multi-card container | capacity, live going count, seats remaining, Going/Maybe/Can't-go, waitlist gated by a live per-row count, organizer event creation | `applyTransition` on the member's own `event-rsvp-response` row; `relatedAggregate` guard (PROPOSED, `guards.md` kind 7); `groupCount`/`mapGet` formulas over query-backed `responses`; `renderBindings[].actions[]` (`kind: "create"`, `scope: "tab"` — real consumer, CALR.3g/3h/3b) | none yet — CAL.1-CAL.4 tickets not dispatched; supersedes A.8/A.10's evidence, which describes the pre-redesign list-based shape |
| `event-rsvp-response` (NEW TYPE, PROPOSED) | member | not directly rendered — aggregated by `event-rsvp` | one row per (event, member), states pending/going/maybe/declined/waitlisted | bulk-created via a proposed `createInstances` primitive at event-creation time | none yet |
| `tournament-event` | member | Calendar event detail | accepted count, actor-in-list-guarded "I'm going"/"Can't make it", **organizer: create a new tournament**, **organizer: create a ballot for this tournament** | `actorInList` guard, `accepted` formula, `renderBindings[].actions[]` (`kind: "create"`, `scope: "tab"` — real consumer, for the tournament itself; `kind: "create"`, `scope: "instance"`, cross-archetype, `{context.id}` → `tournament-ballot.eventId` — designed, not yet App-Shell-implemented, for the ballot). RSVP tracking deliberately NOT converted to the response-table pattern — no capacity ceiling exists to guard, only an unenforced quorum; converting it is an explicit open gap, not silently done. | A.8 widget tests for RSVP; creation not yet tested — CAL.1/CAL.3 not dispatched |
| **Calendar Day/Week/Month/Pending views (PROPOSED)** | member | four view modes on the same Calendar surface, reached by a toggle or by tapping a date cell (→ Day) | each view's own scoped, minimized-card list; Pending is unbounded by date | new App Shell view-mode state (no grammar needed) + `render-bindings.md`'s `responseTable`/`filterableFacets` (PROPOSED) to keep the view generic across archetypes, not hardcoded to `event-rsvp`'s own field names | none yet — CAL.2 ticket not dispatched; blocked on CAL.1 (event creation) per the acceptance-test methodology agreed 2026-07-17 |
| `tournament-ballot` / `tournament-vote` | member | Home ballot card | per-candidate vote button, live `groupCount` tally, deadline | cross-instance eligibility guard, `createInstance` (vote-as-row), `branch`+`createInstance` (runoff) | Blocked on Phase A′ (GAP-1 transition inputs, GAP-4 query-backed `source`) then Phase B |
| `equipment-loan` / `equipment-giveaway` | member | Marketplace listing (club library) | availability, current holder, queue, dues-paid gate, **member: request a loan (contextual FAB)** | cross-workflow guard (`requiresWorkflowsComplete: ["tabletop-club-dues-payment"]`); `renderBindings[].actions[]` (`kind: "create"`, `scope: "tab"` — listing itself, real consumer); `kind: "transition"`, `transitionId: "borrow"` — the `borrow` transition pulled out of the automatic button row into its own contextual FAB, its own `guard` unchanged (designed, not yet App-Shell-implemented — see §10 and [`07-actions-and-fabs.md`](../guide/07-actions-and-fabs.md)) | Phase C |
| `tabletop-game-loan` (PROPOSED redesign) | member (owner + borrower) | Marketplace listing (peer-shared) | owner identity, availability, pending-approval, current holder, queue, due date, renew/report-issue | `renderBindings[].actions[]` (`kind: "create"`, `scope: "tab"`, GAP-2) for listing your own game; owner-approval is plain guarded transitions — no new grammar beyond GAP-2 | Blocked on Phase A′ (GAP-2), then Phase C; no ticket written yet |
| `tabletop-club-dues-payment` | member | Giving | amount, receipt | `paymentCheckout` archetype | Phase D |
| `game-purchase-proposal` | member (author) / organizer (decision) | Home (submit) / Admin (queue) | proposal state, live pending queue | `renderBindings[].actions[]` (`kind: "create"`, `scope: "tab"`, GAP-2) | Blocked on Phase A′, then Phase E |
| `discussion-thread` | member | Messages | thread list, unread, post/reply, **start new thread** | `renderBindings[].actions[]` (`kind: "create"`, `scope: "tab"`, GAP-2) for thread creation | Blocked on Phase A′, then Phase F |

## 8. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| `event-rsvp` (REDESIGNED, PROPOSED) | member's own `event-rsvp-response` row transitions between pending/going/maybe/declined/waitlisted | organizer sees live `goingCount`/`waitlistedCount` (query-backed, real-time), plus creates new events | past events remain visible read-only; a member's own row for a cancelled event stays whatever it last was | Going hidden/replaced by Join waitlist when the live `relatedAggregate` count reaches capacity; creation affordance hidden for non-organizers | non-member cannot respond; non-organizer cannot create |
| **Calendar Day/Week/Month/Pending views (PROPOSED)** | member switches view mode, taps cards to expand/collapse, taps a date cell to jump to Day | organizer sees the identical views (no persona-specific view logic) | a day/week/month with no events shows an empty state, not an error; Pending with nothing outstanding shows an empty state too | create-event action hidden for non-organizers, same as above | back navigation from Day (reached via date-cell tap) returns to Month, not Home |
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
- **Calendar date-cell tap must open a day-scoped view (PROPOSED, 2026-07-17 review — supersedes the
  2026-07-15 entry, extended with Week/Pending):** tapping a date box in the month grid switches to Day
  view for that date — showing only that day's events (filtered, not the whole month's agenda). Back
  from Day view returns to Month, not Home. Tapping an event's inline title inside a month-grid cell does
  both in one tap: switches to Day view AND expands that specific card.
- **Week view (PROPOSED, 2026-07-17):** a 7-card row, one per day of the selected week (Sunday-start,
  matching the month grid's own column order), each showing that day's own scoped, minimized event-card
  list.
- **Pending view (PROPOSED, 2026-07-17):** a fourth view mode, unbounded by date — every event the
  current viewer has not yet responded to, regardless of how far out it is. Reuses the same generalized
  holding-container widget as Day/Week/Month, parametrized by `responseTable`/`filterableFacets`
  (`render-bindings.md`) rather than a bespoke widget.
- **Minimized-card, tap-to-expand list (PROPOSED, 2026-07-17):** every view (Day/Week/Month/Pending)
  shows its scoped events as minimized cards by default — no card auto-expands. Tapping a card expands it
  into the full RSVP card (reusing `EngineNativeArchetypeCard` from the generic pipeline); tapping a
  second card collapses the first (accordion — one expanded at a time).
- **Organizer creates a new Calendar event (PROPOSED, 2026-07-17; FAB infrastructure redesigned
  2026-07-20; `actions[]` grammar v2, 2026-07-21):** a generic, tab-wide floating-action-button mechanism
  (not Calendar-specific) surfaces any `renderBindings[].actions[]` entry with `kind: "create"`, `scope:
  "tab"` matching the current tab and viewer persona (GAP-2). Calendar has two: `event-rsvp`'s "New
  event" (real, CALR.3g/3h/3b) and `tournament-event`'s "New tournament" (real, CALR.3b) — resolved via
  `creatableAction`/`tabCreatableActionStyles` (`render-bindings.md`): `multiActionStyle` (speedDial/
  stacked/singleFirst) for how multiple actions lay out, `presentationStyle` (popup/slideOutBottom/
  slideOutLeft/slideOutRight) for how the tapped action's own archetype card surface presents, in creation
  mode. Not bundled with tournament-ballot creation, which is a separate, **instance-scoped**
  (`scope: "instance"`, `presentation: "button"`) action declared on `tournament-event`'s own binding —
  not `tournament-ballot`'s — and invoked from a specific tournament's own card via `{context.id}` prefill
  (`{context.id}` is the tournament instance's own id, which is exactly `tournament-ballot.eventId`).
  Designed, not yet App-Shell-implemented — see [`07-actions-and-fabs.md`](../guide/07-actions-and-fabs.md).
- **Member requests a game loan via a contextual FAB, not a row button (PROPOSED — `actions[]` grammar
  v2, 2026-07-21):** the second, complementary `actions[]` pattern — a **transition** (not a create) pulled
  out of its archetype's automatic button row. `equipment-loan`'s `borrow` transition already exists as a
  plain guarded transition (dues-paid gate, availability check — see §3/§7); a `kind: "transition"` action
  (`transitionId: "borrow"`) gives it its own contextual FAB, bound to the in-focus marketplace listing,
  since "request a loan" is that card's single primary action — while `join-queue`/`leave-queue`/`return`/
  `delist` stay as ordinary row buttons, unchanged. This is the model to reach for whenever one existing
  transition (not a new instance) deserves a distinguished, floating affordance instead of one button among
  several. Designed, not yet App-Shell-implemented — see
  [`07-actions-and-fabs.md`](../guide/07-actions-and-fabs.md).
- **Calendar cards get data-driven, per-category color (`styleField`, 2026-07-23, IMPLEMENTED
  2026-07-24 — CALR.9b, commit `f4bf58f`):** each event's own `category` field (a plain
  community-authored value, e.g. `"social"`/`"tournament"`) drives a computed `cardStyleId` via nested
  `if()` — the same mapping pattern already proven by `tournament-ballot.dueAt`'s `reminderOffset`
  formula, no new engine function. `event-rsvp`'s calendar binding declares `styleField: "cardStyleId"`;
  `tournament-event`'s calendar binding does the same with a constant `cardStyleId` (every tournament is
  one category). The resolved integer selects one of a small, fixed set of App Shell-owned visual style
  slots, all still derived from the community/tab accent already in use — never a new, unrelated,
  hardcoded color. Confirmed live: Friday game night and Summer tournament render in genuinely distinct,
  accent-derived colors. See `render-bindings.md` `styleField` section and `spec-version.json` →
  `resolvedInGrammar.styleFieldBinding`.
- **Organizer-only event editing (`editGuard`, 2026-07-24, IMPLEMENTED 2026-07-25 — CALR.10a, commits
  `494f4cb`..`5ce77bd`, 5 rounds):** `event-rsvp`/`tournament-event` already declare real `editableFields`
  (title/eventDate/eventTime/location/host/capacity), and Calendar's real detail card
  (`_EventRsvpDetailCard`) now renders real, type-aware editors for them, gated by `editGuard`.
  **Deliberately deviates from guards.md's normal "absent guard means anyone" default** at this one call
  site — an absent `editGuard` means no editing exposed, not open editing. Independent verification caught
  and closed a real Save-persistence bug across the 5 rounds (final root cause: the Calendar dispatcher's
  post-mutation requery racing the write, fixed with a local, card-scoped stale-guard). Confirmed live on
  a real Android emulator: organizer sees and can save real edits; member sees none. See
  `workflow-grammar.md` `states` section and `spec-version.json` → `resolvedInGrammar.editGuard`.
- **Configurable agenda date rail (`theme.calendar.dateRail`, 2026-07-24, IMPLEMENTED 2026-07-25 —
  CALR.10b, commits `f3dbc15`/`2e0c12b`, 2 rounds):** the agenda row's date rail (weekday abbreviation
  over a circle-highlighted day number) now genuinely renders from `theme.calendar.dateRail.entries` —
  closed-primitives/open-composition split (fixed calendar-arithmetic tokens and fixed render primitives,
  but free formula composition, ordering, and accent-derived coloring via the same style-slot palette
  `styleField` uses), with `circleHighlight` carefully preserving the exact today-only-filled-circle rule
  so every non-opted-in community renders pixel-identical to before. Rail width also halved (96→48px, a
  separate, unconditional change). Confirmed live: the real fixture's 3-entry example (including a
  `count(dayInstances)` badge) renders correctly. See `theming.md` section 6 and `spec-version.json` →
  `resolvedInGrammar.calendarDateRailBinding`.
- **View attendee list (zero new grammar needed, 2026-07-24, IMPLEMENTED 2026-07-25 — CAL.AttendeeList,
  commit `94f23e4`, 1 round, zero rework):** investigation found the data plumbing already fully declared
  before this pass even started — `event-rsvp`'s `responseTable` binding plus its query-backed
  `responses`/`responseCounts` fields already enumerate every per-member response row for an event.
  `LoomAuthApi.listAccounts()` resolves each row's `personaId` to a real display name. **No JSON change
  was needed or written for this item.** Covers both attendee shapes Calendar's detail card renders:
  `event-rsvp`'s per-row responses (grouped by state) and `tournament-event`'s flat
  `goingPersonaIds`/`waitlistPersonaIds`; an id with no matching account falls back to the raw id (proven
  live against the real fixture's own legacy, unseeded `tabletop-member` entry) rather than disappearing.
- **Waitlist promotion (`transitionRelated`, 2026-07-24, IMPLEMENTED 2026-07-25 — CAL.WaitlistPromotion,
  commit `e188463`, 2 rounds):** a new effect op (`effects.md` §11) — a `relatedQuery` (reuses
  `relatedAggregate`'s existing `filter` shape, plus `sortKey`/`limit: 1`) resolves the oldest waitlisted
  row, then `transitionId` applies to it as a real `applyTransition` call — a guard failure on the target
  is a silent no-op, not an error, which is what lets it attach unconditionally to every leave-transition
  with no separate "did a seat open" check. Required a real architectural fix along the way: `applyTransition`
  now resolves guards/GAP-1 inputs in a read-only phase *before* opening its database transaction (restoring
  its original design after a fix-round caught a real `SqliteException: cannot start a transaction within a
  transaction` regression), so `transitionRelated` can apply a real, guard-respecting transition to another
  instance from inside the same outer transaction with no nesting. Landed in the frozen fixture:
  `event-rsvp-response` gained a real `rsvpedAt` field (stamped by `respond-waitlist`'s own `set` effect)
  and `respond-maybe`/`respond-declined` both gained real `transitionRelated` effects promoting the oldest
  waitlisted row. Both real validators re-run clean (0 errors/0 warnings). See `spec-version.json` →
  `resolvedInGrammar.transitionRelatedEffect`.

**Recently closed:**
- **Filter Calendar by category (2026-07-25, IMPLEMENTED — CAL.CategoryFilter, commit `468b64b`, 1
  round):** the original "trivial, pure-JSON, matches `isFull`/`hasWaitlist`/`goingCount` exactly" scoping
  was wrong — verified the facet bar only had two rendering modes (boolean toggle, numeric-sum stat), and
  `category` being `"type": "text"` would have hit the numeric branch and rendered a non-functional
  `"Category: 0"`. Added a third, genuinely generic facet kind (`_CalendarFacetKind.textValue`) derived
  purely from `instanceDataSchema[field].type`, so any future text-typed facet gets working chip-based
  filtering for free with zero JSON schema change — then added `category` to the fixture. See
  `Loom_Communities_Workflow_Engine_3.md`'s CAL.CategoryFilter row for the full round history (including
  a pre-existing, unrelated test regression this same verification pass found and fixed —
  `CAL.FullnessGuardTestFix`).

**Design closed, awaiting implementation:**
- **Recurring events (design closed 2026-07-25 — CAL.Recurrence).** No recurrence concept exists anywhere
  in the model — every event is a standalone instance. Confirmed (twice, independently) there is no
  JSON-only shortcut: `resolveInstanceScopedPrefill` (`instance_scoped_action_context.dart`, whole file
  25 lines) only supports literal passthrough, `{context.id}`, and `{context.<field>}` direct field copy;
  `createInstance.fields` (`effect_evaluator.dart`'s `resolveEffectValue`) is equally interpolation-only;
  the formula evaluator (`formula_evaluator.dart`) has no forward-direction date function at all (only
  `daysBetween`/`daysUntil`/`subtractHours`). **Design chosen: eager instance generation** — a new
  `make-recurring` transition on `event-rsvp` (self-removing after firing once, via `formula: "seriesId
  == null"`) carries a new effect, `generateRecurringInstances` (`effects.md` §12, PROPOSED), which mints
  one `seriesId`, stamps it on the anchor instance (occurrence 0), and creates `count - 1` real,
  independent sibling instances via bespoke Dart date arithmetic — not the formula evaluator, since the
  full pattern set requested (daily/weekly-by-weekday/monthly-by-date-with-clamping/monthly-by-last-or-
  Nth-weekday) is real month-boundary arithmetic that would over-generalize the formula language if forced
  through it. Every generated occurrence is immediately a normal, independent instance — RSVP,
  per-occurrence edit, per-occurrence cancel all already work unchanged. Deleting one occurrence needs no
  new capability; deleting the whole series is App-Shell client-orchestration (query every sibling
  sharing `seriesId`, loop the existing cancel transition) — not a new engine bulk-op. See
  `spec-version.json` → `proposedNotImplemented.generateRecurringInstancesEffect` and `effects.md` §12 for
  the full grammar. **Not yet implemented** — the frozen fixture is deliberately not touched in this pass
  (the engine's `op` allowlist is hard-coded; adding the transition/effect before the engine recognizes it
  would fail validation, same trap `transitionRelated` hit earlier). Implementation tickets not yet
  dispatched.

## 11. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| CAL.CategoryFilter implementation + regression fix + CAL.Recurrence design pass, 2026-07-25 | **partially** — `category` filtering's original "trivial JSON" scoping was itself wrong (would have shipped a non-functional stat display, not a filter); recurring events' design is now closed (eager instance generation, full daily/weekly/monthly-incl.-last-weekday pattern set), but is JSON/docs only this pass, deliberately not yet in the frozen fixture | `category` filtering needed a real, small, generic App-Shell addition (a third facet rendering kind), not zero code as originally scoped; independently verifying it surfaced an unrelated **pre-existing regression** (a Calendar test asserting the old, pre-waitlist-promotion manual-refill flow, silently broken since CAL.WaitlistPromotion's fixture JSON landed because the app-shell suite was never re-run against it) — fixed in the same pass; recurring events needs a genuinely new engine effect op (bespoke Dart date arithmetic, not the formula evaluator) plus App-Shell UI, none of it built yet | `spec-version.json` gained `proposedNotImplemented.generateRecurringInstancesEffect`; `effects.md` gained §12 (`generateRecurringInstances`, PROPOSED) plus op-count/rules/selection-table updates; this doc's §10 updated (CategoryFilter moved to "Recently closed," recurring events moved to "Design closed, awaiting implementation") | CAL.CategoryFilter: `_CalendarFacetKind.textValue` + selection state + chip rendering (`part28_engine_native_calendar_surface.dart`) — **IMPLEMENTED**, commit `468b64b`. Regression fix: `v3_milestone_a8_calendar_end_to_end_test.dart` test rewrite — **IMPLEMENTED**, commits `ac100e2`/`2df0462`. Recurring events: engine effect op + evaluator + validator rules + App-Shell picker dialog + delete-series action — **none dispatched yet**, tracked as CAL.Recurrence.1-7 | CAL.CategoryFilter closed (independently verified, 125/125 app-shell); recurring events open — spec updated and written this pass, implementation tickets not yet dispatched |
| CALR.10 + pinned-item implementation pass, 2026-07-25 | no — all JSON for this pass was already written and signed off on 2026-07-24 (see the row below); this pass is implementation + one small, previously-deferred piece of JSON (the `transitionRelated` effect calls themselves, held back by a real validator constraint) | no remaining gap — `editGuard` (CALR.10a, 5 rounds, closed a real Save-persistence bug independent verification caught), `theme.calendar.dateRail` (CALR.10b, 2 rounds, closed a real missing-field-threading compile error), attendee-list names (CAL.AttendeeList, 1 round, zero rework), and `transitionRelated` (CAL.WaitlistPromotion, 2 rounds, closed a real nested-transaction regression independent verification caught) are all now implemented and independently verified | `spec-version.json`: `editGuard`/`calendarDateRailBinding`/`transitionRelatedEffect` all moved from `proposedNotImplemented` to `resolvedInGrammar`; `effects.md`/`guards.md`/`workflow-grammar.md`/`theming.md` status language updated from PROPOSED to IMPLEMENTED (also caught and fixed two unrelated stale PROPOSED markers in `guards.md` for `relatedAggregate`, which has actually been implemented since 2026-07-17); this doc's §10 updated; frozen JSON: `event-rsvp-response.respond-maybe`/`respond-declined` gained real `transitionRelated` effects (the `rsvpedAt` field/stamp were already live). Both real validators re-run clean (0/0) | none remaining for this batch — attendee list, editGuard, dateRail, and waitlist promotion are all done. Recurring events (`CAL.Recurrence`) and Marketplace's tile-style system (`MKT.1`) remain pinned, each needing its own full design pass before any JSON | closed — all four items independently verified (120/122/124/147 test counts across rounds, final: App Shell 124/124, engine 147/147, validator 114/114, 0 analyzer issues everywhere) |
| Pinned-item investigation + spec pass, 2026-07-24 | **partially** — attendee list turned out to need zero new grammar at all (existing `responseTable`/`responses` already enumerate the data); waitlist promotion needed one genuinely new effect op (`transitionRelated`); recurring events confirmed to have no cheaper shortcut and still needs its own full design pass | no new engine gap for attendee list (pure App-Shell rendering); waitlist promotion is a genuine new cross-instance effect op, not yet engine-implemented; recurring events out of scope for this revision entirely | `effects.md` gained op 11 (`transitionRelated`, PROPOSED) + a cross-reference note in `guards.md` on reusing `relatedAggregate`'s `filter` shape, `spec-version.json` gained `proposedNotImplemented.transitionRelatedEffect`, this doc's §10/§11 updated, frozen JSON: `event-rsvp-response` gained a real `rsvpedAt` field + a real `set` effect on `respond-waitlist` stamping it (live today, uses only already-implemented grammar) — **the `transitionRelated` effect calls themselves were NOT added to the frozen fixture**: `effects[].op` has a hard-coded allowlist in the real engine (unlike `editGuard`/`dateRail`'s silently-ignored additive keys), and a draft that included them failed `community_package_validator.dart` with 2 genuine `unknown_effect_op` errors. No JSON at all was needed or written for attendee list; no JSON was written for recurring events (no design exists yet). Both real validators re-run clean (0 errors/0 warnings) against what was actually landed | App Shell: none of this is implemented yet (attendee-list rendering, `transitionRelated` execution) — tracked in the tracker's CAL.AttendeeList/CAL.WaitlistPromotion rows | open — spec updated and approved this revision; implementation tickets not yet dispatched; recurring events still pinned pending a full design pass |
| A.10 live emulator walk (human gate), 2026-07-24 | **yes, two** — (1) the organizer had no way to edit an already-created event's own details (wrong time, typo in location, etc.) even though the generic editing mechanism already existed elsewhere in the app; (2) the agenda date rail was hardcoded to exactly two pieces with no way to show anything else, and was requested to be visually much slimmer. Also surfaced three bigger candidate gaps (attendee list, waitlist promotion, recurring events), deliberately pinned rather than designed this revision — see §10's pinned list | no new engine gap for either spec'd item — `editGuard` reuses the existing guard evaluator (`WorkflowGuard`, already used by `transitions[].guard`) at a new call site; `dateRail` composes entirely from the existing computation model (formulas) plus the existing style-slot palette (`styleField`, CALR.9b) — neither needs a new engine primitive. The three pinned items are each a genuine new engine/rendering capability (persona-identity resolution, cross-instance transition-triggering effects, a recurrence concept) and are explicitly out of scope for this revision | `workflow-grammar.md` `states` gained `editGuard` (+ cross-reference note in `guards.md` on its deliberate absent-means-closed deviation from the guard type's normal default), `theming.md` gained section 6 (`theme.calendar.dateRail`), `spec-version.json` gained `proposedNotImplemented.editGuard`/`calendarDateRailBinding` (and `styleFieldBinding` moved to `resolvedInGrammar` — was stale, CALR.9b already shipped it 2026-07-24), this doc's §10/§11 updated, frozen JSON: `event-rsvp`/`tournament-event` both gained `editGuard: { allowedPersonaIds: ["tabletop-organizer"] }` on their `open` states, community `theme` gained a concrete `calendar.dateRail.entries` example (reproduces today's exact default plus one `formula`-kind entry). Both real validators re-run clean (0 errors/0 warnings) against the updated fixture | App Shell: `LoomWorkflowState.editGuard` parsing + the App Shell reading it (with the null-means-closed rule) before rendering `GenericWorkflowInstanceCard`'s editors on Calendar's card, currently gated only by a static `showEditors` bool; `theme.calendar.dateRail` parsing into the theme cascade + the agenda-row date rail rendering it, including halving the rail's width (`SizedBox(width: 96)` → ~48, `part28_engine_native_calendar_surface.dart:749`) — neither dispatched yet, tracked in the tracker's CALR.10 row. Pinned items (attendee list, waitlist promotion, recurring events) have no implementation scope yet — each needs its own design pass first | open — spec updated and approved this revision (JSON/docs only, per explicit instruction — no code yet); implementation tickets not yet dispatched; pinned items awaiting their own design sessions |
| `styleField` — data-driven per-category card color, 2026-07-23 | **yes** — a live design review against the real Google Calendar Schedule-view reference found that every Calendar card renders in one flat community/tab accent, with no way to visually distinguish event categories (e.g. a game night vs. a tournament) the way the reference does with distinct colors per calendar/category | no new engine gap — the mapping logic (label value → style number) composes entirely from grammar the engine already executes (nested `if()`, proven by the already-existing `tournament-ballot.dueAt`/`reminderOffset` formula); this is a new, optional render-binding pointer field plus an App-Shell palette-resolution step, not a new engine capability | `render-bindings.md` new `styleField` section + binding-object table row + validator-rule row (`dangling_style_field`), `spec-version.json` `styleFieldBinding` added, this doc's §10 updated, frozen JSON: `event-rsvp` gained `category`/`cardStyleId` fields + `styleField` on its calendar binding (Friday game night seeded `category: "social"`), `tournament-event` gained a constant `cardStyleId` + `styleField` on its calendar binding | App Shell: **IMPLEMENTED 2026-07-24 (CALR.9b, commit `f4bf58f`)** — `stylePaletteFrom(accent)` (accent-derived style-slot palette) and `_calendarEntryStyleColor` (the archetype reading `instanceData[binding.styleField]`) are both live; confirmed on a real Android emulator that Friday game night and Summer tournament render in genuinely distinct colors | closed — implemented, independently verified (118/118 App Shell + 141/141 engine tests, 0 analyzer issues), confirmed live |
| `actions[]` grammar v2 — create vs. transition FABs, 2026-07-21 | **yes** — the flat `creatable` object could only express one shape ("brand-new instance, tab FAB"); it had no way to express an action related to a specific existing instance (a button/contextual FAB on one card, e.g. "Create ballot for this tournament"), and no way to give one specific *transition* (as opposed to a create) a distinguished FAB/button presentation instead of leaving it in the automatic row (e.g. `equipment-loan`'s "Request loan") | no new engine gap — both patterns compose entirely from grammar the engine already executes (`createInstance`/`applyTransition`, existing guards/effects/inputs); this is a rendering/presentation-layer grammar addition, not a new engine capability | `render-bindings.md` `actions` section rewritten for two kinds (`kind: "create"` / `kind: "transition"`), new [`guide/07-actions-and-fabs.md`](../guide/07-actions-and-fabs.md) authored (decision procedure + worked examples for the Skill), `spec-version.json` `actionsGrammar` extended, this doc's §3/§7/§10 updated to describe both patterns and reference the new guide, frozen JSON: `tournament-event` gained the cross-archetype ballot-create action (moved off `tournament-ballot`'s own binding per the locked design rule — a host-owned action, never owned by the created type), `equipment-loan` gained a `kind: "transition"` action pulling `borrow` into its own contextual FAB | App Shell: `scope: "instance"` creates and the entire `kind: "transition"` surface are designed and validated but **not yet implemented** — tracked in the tracker's CALR.4a-f rows, same status as the rest of grammar v2's instance-scoped surface | open — spec updated and approved this revision; implementation tickets not yet dispatched |
| CALR.3 FAB redesign, 2026-07-20 | **yes** — CALR.3's own "+ New event" button was hardcoded to Calendar/`event-rsvp` specifically, with no way for a second tab or a second creatable workflow on the same tab to get one without duplicating bespoke code | yes — three implementation attempts (CALR.3e nested-Scaffold FAB, CALR.3f/3f2 bounded-layout restructuring) were all reverted after real regressions (up to 18 test failures), because `SingleChildScrollView` always gives unbounded height to its child regardless of what bounds the scrollview itself — a nested `Scaffold` inside a tab's own scrollable content can never receive bounded layout constraints, no matter how the outer layers are restructured. Corrected design: attach the FAB to `LocalExtensionScreen`'s own existing top-level Scaffold (already bounded, already computes `selectedTab`/`activePersona`/`experience`) — no nested Scaffold needed at all | `render-bindings.md` `creatableAction`/`tabCreatableActionStyles` (two design iterations same day: flat fields → three-field nested object → final two-field shape after clarifying `presentationStyle` folds in the slide edge); this doc's Calendar-creation user story updated to describe the generic mechanism instead of a Calendar-specific button | App Shell: generic FAB detection + `multiActionStyle` rendering on the real top-level Scaffold (CALR.3g), then `presentationStyle` (popup via the official `animations` package's `OpenContainer`, slide-out via `showModalBottomSheet`/`SlideTransition`) + generalizing the creation form into the archetype's own `cardSurfaceFamily` dispatch in creation mode (CALR.3h) — split into two stages given how expensive the reverted single-shot attempts were | open — spec updated and approved this revision; CALR.3g/3h tickets being scoped |
| A.10 live emulator walk, 2026-07-14/15 | no | minor — `tournament-event.minimumAttendance` has no `labelTemplate`, renders its raw field name with no value | none (JSON-authoring gap, not a product-spec gap) | fix in either the JSON (add `labelTemplate`) or A.6's generic-card fallback; deferred to A.10's own triage | open |
| Product request, 2026-07-17 — Calendar Day/Week/Pending views + real event creation | **yes** — no day/week/pending view existed (only the 7×6 month grid), no member-facing minimized-card list, and no way for the organizer to create a new event at all (`creatable` had zero real consumers anywhere in the app) | yes — `event-rsvp`'s RSVP tracking was list-based (`goingPersonaIds` etc.), not row-per-member, so its capacity guard couldn't be evaluated against a live per-row count; the engine had no bulk-create primitive, no way for a guard to reference a live cross-instance aggregate, and no way to expose a row's own FSM state to aggregation | §6/§7/§8/§10/§11 updated (this revision); `render-bindings.md` (`responseTable`, `filterableFacets`), `guards.md` (`relatedAggregate`, kind 7), `formulas.md` (`subtractHours`, `mapGet`, `$state`), `archetypes/README.md` (`event-rsvp` reopened to 🔨 REBUILDING) all updated; frozen JSON redesigned (new `event-rsvp-response` type, `event-rsvp`/`tournament-event`/`tournament-ballot` `creatable` additions, `tournament-ballot.dueAt` converted to computed, seed data converted to per-row) | JSON/docs done this revision (spec only, per explicit instruction — no code yet); engine: `createInstances` (abstract API), `relatedAggregate` guard evaluation, `$state` exposed to aggregation, `subtractHours`/`mapGet` formula functions; App Shell: creation forms (event-rsvp + tournament-event + tournament-ballot), Day/Week/Month/Pending view surface, minimized/expand card list — none dispatched yet, tracked in the CAL/AS ticket gap list pending user review | open — spec complete, implementation tickets not yet written |
| Product request, 2026-07-15 — peer-to-peer game sharing | **yes** — no member-to-member game-sharing model existed; `tabletop-game-loan` was a one-state, zero-data stub with no owner concept, no queue, no approval flow | partly closed — `tabletop-game-loan` is now authored in the frozen JSON as a real `published→delisted` type with owner-gated approve/decline/delist, request/queue/return/renew/report-issue, and three seeded peer listings (validator-invariant clean); remaining gaps are app-shell runtime loading (milestones 1.27–1.31) plus four inline `NEEDS IMPLEMENTATION` items | §2/§3/§4/§6/§7/§8/§9 updated; JSON `tabletop-game-loan` redesigned (owner-gated via `formula: "ownerPersonaId == $actor"`, no new grammar beyond forward-looking GAP-2 `creatable`); the two `equipment-loan`/`equipment-giveaway` `linkedWorkflowId` refs to the old stub removed | inline `NEEDS IMPLEMENTATION` in the JSON: auto-set owner on create (GAP-2 creator binding), auto-promote queue head on return (no list-head fn), compute/extend due date (no date-returning fn). No app-shell ticket written | open |
| Multi-user login, 2026-07-15 | **no** — the per-individual identity gap was correctly identified as a platform-service limitation in the prior review | closed — `LoomAuthApi`/`LocalAuthApi` (see `docs/references/reference/platform-services.md` §Identity) provides a real identity contract with seeded demo accounts; the app now passes individual account ids to engine calls via `resolveEnginePersonaId()`, making `ownerPersonaId == $actor` correctly distinguish individuals | Added Identity section to `platform-services.md`; removed the "per-individual identity (platform service)" caveat from the `tabletop-game-loan` review entry | `app/packages/core/loom_communities_app_shell/lib/src/part29_auth_api.dart`, `part30_local_auth_api.dart`, `part31_auth_screens.dart`, `part01_local_extension_screen.dart`, `part25_engine_native_community_store.dart`, `part28_engine_native_calendar_surface.dart`, `app/packages/core/loom_workflow_engine/lib/src/evaluator/guard_evaluator.dart`, `transition_evaluator.dart`, `local_workflow_engine_api.dart` | closed |
| Human review, 2026-07-15 | **yes** — this doc had no navigation/breadcrumb model, no calendar day-detail interaction, and no explicit states-vs-data split documented at all | yes — back navigation doesn't follow a real stack; tapping a date cell doesn't open a day view or allow event creation | Added §3 (Lifecycle/Data per type), §4.1 navigation resolution (App Shell scope, no grammar), §6/§7/§8 Calendar day-detail rows, §10 interaction standard entries (this revision) | Build a real navigation back-stack for the App Shell; build a day-detail route for Calendar (filtered events + create-event, pre-filled date) | open — product doc updated first, per this template's own rule; grammar proposed in [Grammar Extensions](../../Build%20Plan%20V2/Loom%20Communities%20Workflow%20Engine%20V3/Loom_Communities_Workflow_Engine_3_GrammarExtensions.md) (awaiting sign-off); UI ticket not yet written |
