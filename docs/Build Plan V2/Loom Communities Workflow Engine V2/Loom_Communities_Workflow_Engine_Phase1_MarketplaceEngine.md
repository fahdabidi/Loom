# Phase 1 — Marketplace Engine Prototype (Tabletop Club)

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md) (see that doc for
overall status/gating and the phase tracker). This doc holds the **core engine design** — schema, API,
rendering, validator — since Phase 1 is where all of it is first built; every later phase reuses this
design without re-deriving it.

Status: not started. Depends on: `Loom Communities App Shell V2/AppShell V2 Tracker.md`'s Calendar
(M4) and Marketplace (M3b) phases being fully closed — **satisfied 2026-07-04** (both re-closed with
live evidence after their reopenings). Phase 1 is unblocked to begin; no code below has been written.

## 1. Scope & goal

Everything downstream (Phases 2-6) reuses what gets built here: the domain-agnostic workflow schema,
the `WorkflowEngineApi` abstraction + its SQLite-backed local implementation, the validator, and the
generic rendering primitives. Prototype community/workflow: Tabletop Club's Marketplace tab
(equipment-loan + equipment-giveaway), replacing the existing marketplace-only
`LoomListingStateMachine`.

## 2. Proposed general schema

Replaces the marketplace-only `LoomListingStateMachine`/`LoomListingTransition` with a
domain-agnostic `LoomWorkflowStateMachine`/`LoomWorkflowTransition`, usable by any workflow type
(marketplace listing, RSVP, payment, approval, ...):

```json
{
  "workflowType": "marketplace-listing",
  "initialState": "available",
  "states": {
    "available": { "label": "Available", "tone": "positive" },
    "onLoan": { "label": "On loan", "tone": "warning" },
    "queued": { "label": "Queue open", "tone": "info" }
  },
  "transitions": [
    {
      "id": "borrow",
      "label": "Request loan",
      "icon": "arrow_forward",       // renders on the button — see note below
      "tone": "primary",             // "primary" | "secondary" | "destructive" — button visual weight
      "from": ["available"],
      "to": "onLoan",
      "guard": { "allowedPersonaIds": ["tabletop-member"] },
      "effects": [{ "op": "set", "key": "holderPersonaId", "value": "$actor" }],
      "linkedWorkflowId": "tabletop-game-loan"
    },
    {
      "id": "join-queue",
      "label": "Join queue",
      "icon": "add_circle_outline",
      "tone": "secondary",
      "from": ["onLoan", "queued"],
      "guard": {
        "allowedPersonaIds": ["tabletop-member"],
        "actorInList": { "key": "queuedPersonaIds", "present": false }
      },
      "effects": [{ "op": "appendUnique", "key": "queuedPersonaIds", "value": "$actor" }]
    },
    {
      "id": "leave-queue",
      "label": "Leave queue",
      "icon": "remove_circle_outline",
      "tone": "secondary",
      "from": ["onLoan", "queued"],
      "guard": {
        "allowedPersonaIds": ["tabletop-member"],
        "actorInList": { "key": "queuedPersonaIds", "present": true }
      },
      "effects": [{ "op": "removeValue", "key": "queuedPersonaIds", "value": "$actor" }]
    }
  ]
}
```

**`icon`/`tone` on transitions (added 2026-07-04 — closes a real gap).** Without these, rendering a
button's icon would need a per-`transition.id` Dart ternary (`transition.id == 'leave-queue' ?
Icons.remove_circle_outline : ...`) — the *exact* anti-pattern `instanceDataSchema.displayIcon` (§7a)
was built to eliminate for fact pills, just reappearing on the button side instead. `icon` is optional
(a button can render label-only) and `tone` drives visual weight (primary = filled/prominent,
secondary = outlined, destructive = warning-colored — e.g. "Reject"/"Withdraw"/"Report lost"), never
business logic — the guard already decides *whether* a button shows; `tone` only decides how it looks.

Key generalization: today's per-feature boolean flags on `LoomListingTransition`
(`setsHolderToActor`, `clearsHolder`, `incrementsQueue`, `queuedPersonaIds`-specific fields, etc.)
and the growing pile of named fields on `LoomMarketplaceListing` (`currentHolderLabel`,
`queueLength`, `dueLabel`, ...) collapse into two small, reusable primitives:

- **`instanceData: Map<String, dynamic>`** — a generic per-instance data bag (replaces
  `currentHolderLabel`/`queueLength`/`queuedPersonaIds`/etc. as named Dart fields; any workflow type
  declares whatever keys it needs).
- **`guard`** — a small declarative predicate vocabulary evaluated against `instanceData` + the
  acting persona (`allowedPersonaIds`, `actorInList`, `instanceDataEquals` — added 2026-07-04, a
  value-equality check on an arbitrary `instanceData` field, e.g.
  `{ "instanceDataEquals": { "key": "availabilityState", "value": "available" } }` — needed for §2d's
  orthogonal-lifecycle pattern, symmetric to `actorInList`'s list-membership check; extensible to more
  predicates later as real needs arise — resist over-building this up front).
- **`effects`** — a small declarative mutation vocabulary applied to `instanceData` on successful
  transition (`set`, `appendUnique`, `removeValue`, `increment`, `decrement` — same idea, keep
  minimal, add operations only when a real workflow needs one).

This is *the* central design decision: no new boolean flag ever needs to be added to a Dart class
again for a new interaction — a community/workflow author declares a new guard/effect combination
in JSON instead.

## 2a. Workflows, card surfaces, and tabs are many-to-many (design update, 2026-07-04)

The schema above implicitly assumed one workflow ⇄ one card surface ⇄ one tab. That's false in
general — a real example: a document is drafted/edited in one card surface, then published via an
approval workflow reviewed in a *different* card surface, in a *different* tab. Fix: replace a
single fixed `cardSurfaceFamily` on the workflow type with a `renderBindings` list, keyed by
`(state, role)`, each declaring where that combination renders:

```jsonc
"renderBindings": [
  // Author, while drafting — the only place transitions actually get triggered from this state.
  { "states": ["draft"], "role": "actor", "tabId": "documents",
    "cardSurfaceFamily": "document-editor", "bindingKind": "primary" },

  // Author, once submitted — same state, but now a passive status view, not the editor.
  { "states": ["pending-approval"], "role": "actor", "tabId": "documents",
    "cardSurfaceFamily": "document-status-badge", "bindingKind": "primary" },

  // Approver sees the SAME state in a completely different tab and surface.
  { "states": ["pending-approval"], "role": "receiver", "tabId": "board",
    "cardSurfaceFamily": "approval-queue-item", "bindingKind": "primary" },

  // Once published, everyone reads it the same way, back in Documents.
  { "states": ["published", "rejected"], "role": "any", "tabId": "documents",
    "cardSurfaceFamily": "document-library-detail", "bindingKind": "primary" }
]
```

Design decisions, stated explicitly so they don't drift later:

- **`renderBindings` is an N-entry list — arbitrarily many roles, not just two** (updated 2026-07-04).
  The 4-entry example above happens to use two roles (`actor`/`receiver`), but a workflow may bind
  **many** distinct participant roles, each to its own surface/tab. A multi-stage HOA architectural
  request, for instance, legitimately involves `applicant` → `board-reviewer` → `committee` →
  `auditor` (read-only) — four+ roles, four+ bindings, one workflow. So:
  - **`role` is not limited to the fixed `actor`/`receiver`/`readOnly`/`any` set.** Those four stay as
    the *conventional base vocabulary* (and `any` as the catch-all), but a workflow may declare
    arbitrary named participant roles (`board-reviewer`, `committee`, `auditor`, …). This generalizes
    `LoomWorkflowPersonaPolicy`'s current three fixed persona-ID lists into a `roles: { "<roleName>":
    ["<personaId>", …] }` map (with `actor`/`receiver`/`readOnly` as reserved, conventional key names
    so existing declarations keep working). A given persona may hold more than one role on the same
    instance; role resolution returns the *set* of roles, and every matching binding renders.
  - **Reasonable cap (validation guidance, not a hard architectural wall):** ≤ 32 `renderBindings`
    and ≤ 16 distinct roles per workflow type. The §7c validator flags anything past that as a smell
    (a workflow needing 20 roles is almost always two workflows). Far below any real limit — just a
    guardrail so a generated workflow can't explode the binding space.
  - `"any"` still covers states where role stops mattering (once published, everyone reads the same
    surface) and is the right default for simple single-surface workflows like Marketplace.
- **A binding doesn't restate which transitions are available.** That's still
  `availableTransitions(state, persona, instanceData)`'s job (§2's existing guard mechanism) — a
  binding only answers *where*, never *which buttons*, so guard logic never has to be maintained in
  two places. This is also the full answer to "one card surface handles many transitions" (edit/
  delete/submit all live on one `document-editor` binding for `draft`) — already covered, nothing
  new needed.
- **`bindingKind: "primary"` vs `"summary"`** is what lets one state render in more than one place at
  once without duplicating the interactive surface — `primary` is where transitions actually get
  triggered; a `"summary"` binding would be a read-only pointer/preview shown elsewhere (e.g. a
  compact "1 pending approval" entry on a Home feed).
- **Tabs become derived, not separately declared.** A tab's existence is just "does at least one
  `renderBinding`, across any workflow type/instance, currently target this `tabId` for this
  persona" — this formalizes (and is meant to eventually replace) today's fragile keyword-matching
  tab-presence heuristic (`_hasAnySection`/`_hasAnySurfaceFamily`, `part12_persona_and_tabs.dart`),
  which already tries to do this, just by guessing from workflow-ID substrings instead of an
  explicit declaration.
- **Marketplace is the simple end of this spectrum, not a special case**: one binding, `role: "any"`,
  covers every state, since member vs. organizer only ever differ in *which buttons* they see on the
  *same* surface, never in *which surface*. See the living example file — its `renderBindings` were
  updated to this shape to stay consistent with this section.

## 2b. Container archetypes — revised from evidence (2026-07-04), not guessed from Tabletop alone

An earlier pass proposed 4 archetypes (`list`, `grid`, `table`, `singleItem`) based only on Tabletop
Club — the one test community. That was too narrow, and the current shipped implementation across
the real community examples has known gaps for the same reason (see the remediation logs cited
below — several of these product docs record "in progress" fixes for surfaces that had been
collapsed into generic cards). Before designing further, all 7 built-out community product-experience
docs (`docs/Product Docs V2/Community Examples/`: Cedar Commons HOA, Masjid Nur, Neighborhood Book
Club, Riverside Youth Soccer, Garden Club, Camera Club, Chess Club) were read in full, cross-checked
against the card-surface/tab-renderer-contract specs those docs themselves cite
(`docs/CardSurfaces/tab-renderer-contracts.md` etc.). Those renderer-contract specs independently
declare named tab surfaces (`CalendarTabSurface`, `MarketplaceTabSurface`, `DocumentsTabSurface`,
`WorkflowStatusSurface`, `PaymentGivingTabSurface`, `MessagesTabSurface`, `CareVolunteerTabSurface`,
`AdminReviewComposeTabSurface`, `HomeTabSurfaceStack`) and **explicitly name collapsing them into
generic list/grid rendering as a hard product-spec failure** — this is corroborated twice, not just
inferred once from a single community.

### Revised archetype catalog (15 container types + 1 cross-cutting rendering concern)

Each entry cites which communities' product docs demonstrate the need, so this stays evidence-backed
rather than speculative. Full per-community tab/card/action detail lives in sibling docs in this
folder (index at the bottom of this section); the master cross-reference table and per-archetype
JSON field schemas live in
[Loom_Communities_Workflow_Engine_Archetype_Catalog.md](./Loom_Communities_Workflow_Engine_Archetype_Catalog.md).

**Provenance note (2026-07-04):** the original 13-archetype list was cross-checked against Oracle's
Redwood enterprise page-template taxonomy (Welcome/Overview/Item-overview/Smart-list/Foldout/
Simple+Advanced-create-edit/Guided-process/Data-management/Gantt/Smart-search). That comparison
surfaced two real gaps our community-derived list glossed over — data *entry* was under-modeled
(Redwood makes create/edit a headline page type; we'd hand-waved it as "the generic action
surface"), and we'd conflated a passive status *viewer* with an active multi-step *wizard*. Both are
now fixed below (`formEntry` #14, `guidedProcess` #15, and `statusTimeline` #4 narrowed to the
passive dual-viewer role only). Two lower-priority Redwood ideas are noted but not adopted as
archetypes (see "Responsive behaviors & deferred" at the end of this section).

1. **`calendarAgenda`** — month/week/date-strip + date-grouped agenda list + expandable event-detail
   panel; built-in sub-pattern for RSVP/capacity/waitlist/reminder/conflict. **Every single community**
   needs this (Tabletop, HOA, Mosque, Book Club, Youth Soccer, Garden Club, Camera Club, Chess Club) —
   the strongest possible signal. Supersedes the earlier plain `list` framing for anything date-grouped.
2. **`stateMachineGrid`** — responsive grid (2-3 up) + search/filter + listing detail whose action
   buttons are engine-derived from a per-item state machine (§2), with built-in queue/waitlist
   position and current-holder/custody (privacy-redacted) as first-class sub-state, not bolted on.
   Needed by: Tabletop (equipment-loan), Garden Club (tool loan/giveaway, plant exchange), Camera Club
   (gear loan), Book Club (shared library). Supersedes the earlier plain `grid` — a plain tile grid
   without built-in queue/custody state was flagged explicitly as an anti-pattern in two of these docs
   ("single generic request card... without browse, queue, listing, or custody").
3. **`documentLibrary`** — categorized library/folders + document detail + embedded-vs-external open
   choice + version/access/acknowledgement state + audit trail. Needed by: HOA, Mosque, Book Club,
   Youth Soccer (waivers).
4. **`statusTimeline`** — **passive** status/case tracker: sequential named steps (submitted →
   under-review → changes-needed → approved/rejected → reopened) with current/previous/next, the
   **dual requester/reviewer view** (both sides *watch* the same instance, via two role-keyed
   `renderBindings`), comments, payment/document checkpoints, audit history, alternate reviewer
   actions (request changes, reopen, appeal, retry). Narrowed 2026-07-04: this is what you *look at*,
   not what you *fill in* — the actor's data-entry side of these workflows is now `formEntry` (#14)
   or `guidedProcess` (#15), bound to the same instance for `role: actor` while `statusTimeline`
   binds for `role: receiver`/tracking. Needed by: HOA (architectural request tracking + committee
   decision queue), Chess Club (match negotiation status, result dispute), lighter version in Camera
   Club (critique draft/submitted/reviewed status).
5. **`paymentCheckout`** — amount/purpose/recipient, pay action, durable receipt/history, retry/
   refund/manage/cancel-subscription alternates. Needed by: Tabletop (Giving), HOA (dues), Mosque
   (donation), Youth Soccer (registration payment).
6. **`notificationInbox`** — composer (admin) + sent/read/delivery-state (member), sender/audience/
   timestamp, unread badges/counters. Needed by: HOA (owner notifications), Mosque (announcements +
   neutral care notifications), Book Club (selection publish), Youth Soccer (reminders).
7. **`discussionThread`** — inbox/thread-list + thread detail + composer + read/unread + mute/
   archive/block + connection invites. Needed by: Book Club (discussion); every community's Messages
   tab is this archetype by default.
8. **`searchAiAnswer`** — query + generated answer + cited/permission-guarded sources + refine/save/
   share. Needed by: Mosque (search-ai-citation), Book Club (search-ai-digest).
9. **`exportWizard`** — scope selection + redaction preview + checksum + generate/download/transfer/
   rollback/retry, multi-step with a durable audit result. Needed by: HOA, Garden Club, Book Club,
   Youth Soccer.
10. **`votePoll`** — comparative candidate list with live aggregate results, deadline countdown,
    winning-state/tie handling, cast/change/clear vote. Needed by: Book Club (book selection ballot).
11. **`volunteerRoster`** — role/shift/time + open-spots-vs-filled counter + signed-up roster +
    protected-contact handling. Needed by: Mosque (volunteer signup).
12. **`protectedDetail`** — a detail view where specific fields are masked/redacted per viewer
    permission rather than the whole card being hidden — genuinely different from a disabled button,
    since parts of the *same* object render differently per viewer. Needed by: Mosque (care request
    public/private split), Youth Soccer (minor-data redaction), lighter versions in Garden Club/Book
    Club (privacy-safe holder labels until claim/handoff).
13. **`dashboard`** — a meta-archetype: composites *mini* cards drawn from any of the above archetypes
    at variable density (`minimized`/`medium`/`expanded` — reusing the density vocabulary already
    established for tab pinning), tap-to-expand. This is what **every single community's Home tab**
    requires (`HomeTabSurfaceStack` already names this pattern) — Home is never one archetype, it's an
    aggregation of pointers into the others.
14. **`formEntry`** (added 2026-07-04, Redwood gap #1) — genuine multi-field data *entry*: a single
    create/edit form with typed fields, validation, draft/submit, and an optional **master-detail
    variant** (a parent record plus a child collection edited together, e.g. an event + its RSVP
    options, a listing + its photos). This is the archetype the earlier list was missing entirely —
    data entry had been hand-waved as "the `linkedWorkflowId` fires the generic action surface." Its
    field set is driven by the same `instanceDataSchema` (§7a) the read-side archetypes use, so a
    field declared once renders both in its entry form and in its detail pill. Needed by: Book Club
    (nomination), Mosque (care-request submit, announcement compose), Youth Soccer (registration
    fields, roster edit), Garden Club (plant-exchange + list-your-item), Camera Club (critique submit
    + list-your-gear), HOA (architectural-request submit), Chess Club (propose-match form), and every
    `stateMachineGrid`'s "list your own item" sub-flow. This is the second-broadest archetype after
    `calendarAgenda`/`dashboard` — its absence was the single biggest hole.
15. **`guidedProcess`** (added 2026-07-04, Redwood gap #2 — split out of `statusTimeline`) — an
    **active, single-actor, sequential multi-step wizard** the actor *completes* (step 1 → 2 → 3 with
    a visible position indicator and per-step validation), distinct from `statusTimeline` which is the
    passive *tracking* of such a process. The canonical case: Youth Soccer's guardian registration
    (info → waiver acknowledgement → payment → roster confirmation) — the guardian steps *through* it
    (`guidedProcess`, `role: actor`) while the club reviewer *watches* it (`statusTimeline`,
    `role: receiver`) — same workflow instance, two role-keyed bindings, which is exactly the split
    §2a's `renderBindings` was built to express. Needed by: Youth Soccer (registration), Chess Club
    (match-meetup propose→confirm as the actor experiences it). `exportWizard` (#9) is structurally a
    specialization of this — kept as its own named entry only because its scope/redaction/checksum/
    download shape recurs identically across 5 communities and is worth a dedicated template, but it
    shares `guidedProcess`'s step-runner mechanics underneath.

Kept from the original 4, scope-adjusted:
- **`table`** — kept, generalized with an optional `rankingMode` (rank/position/delta emphasis) to
  cover Chess Club's leaderboard/standings without inventing a 14th top-level archetype for what is
  structurally still rows+columns with a specific visual treatment.
- **`singleItem`** — kept for genuinely single-object detail/summary cards, including
  settings/preference-toggle sub-patterns (e.g. Mosque's donor-visibility choice) that don't need a
  collection at all.
- **`list`** — kept, narrowed to plain scrollable collections that need none of `calendarAgenda`'s
  date-grouping, `documentLibrary`'s embedded/external duality, `notificationInbox`'s read-state, or
  `discussionThread`'s composer — a genuinely plain list is now the exception, not the default.

**Deliberately not new top-level archetypes** (composed from the above instead, per the "small closed
set" restraint principle — resist fragmenting the taxonomy further just because a pattern appeared
once):
- Chess Club's two-party match-scheduling negotiation (propose → accept/decline/reschedule) —
  composes `formEntry` (the propose form) + `guidedProcess`/`statusTimeline` (the respond/confirm
  sequence) + `calendarAgenda`'s event-detail (the confirmed match).
- Camera Club's photo critique (image + attached comment thread + reviewer queue) — composes
  `formEntry` (submit, image-forward) + `stateMachineGrid` (the submissions grid) + `discussionThread`
  (attached critique).

**Responsive behaviors & deferred (Redwood ideas noted, not adopted as archetypes):**
- **Foldout / 2-3 panel master-detail** (Redwood's Foldout template) — a persistent collection on one
  side that unfolds a detail panel inline rather than navigating away. Treated as a **responsive
  behavior** of the collection archetypes (`list`/`stateMachineGrid`/`documentLibrary`/`calendarAgenda`)
  on wide/tablet viewports, NOT a separate archetype: on a phone they navigate/expand-in-place; on a
  wide viewport the same archetype renders master-list + detail-panel side by side. This is the honest
  answer to "how do we do a 2/3-panel list+detail view" — it's a layout mode, not a new container.
- **Data-management bulk-edit grid** (Redwood's spreadsheet-like Data Management template) — deferred.
  No community product doc currently demands editing many records at once; revisit if an
  admin/organizer workflow (e.g. bulk roster edits) surfaces a concrete need.

### Cross-cutting rendering concern (not a 13th container — applies to all of them)

Every archetype above must render in **actor / receiver / readOnly / disabled-with-reason / hidden**
modes for the same underlying data (Mosque's persona-picker and persona-aware-UX workflows require
this explicitly, and it's a repeated requirement across every community doc's persona/state matrix).
This is already the right shape for §2a's `renderBindings.role` field to carry — no new mechanism
needed, just confirmation that §2a's design (role-keyed bindings, reusing the existing actor/
receiver/readOnly vocabulary) already generalizes to this requirement rather than needing its own
new concept.

### Per-community tabs/cards/actions docs

Each built-out community gets its own doc in this folder, mapping its tabs to specific cards, each
card's archetype assignment, and the actions that card performs — grounded in the product docs'
actual workflow-to-surface mapping, not the current implementation:
- [Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md)
- [Loom_Communities_Workflow_Engine_Mosque.md](./Loom_Communities_Workflow_Engine_Mosque.md)
- [Loom_Communities_Workflow_Engine_BookClub.md](./Loom_Communities_Workflow_Engine_BookClub.md)
- [Loom_Communities_Workflow_Engine_YouthSoccer.md](./Loom_Communities_Workflow_Engine_YouthSoccer.md)
- [Loom_Communities_Workflow_Engine_GardenClub.md](./Loom_Communities_Workflow_Engine_GardenClub.md)
- [Loom_Communities_Workflow_Engine_CameraClub.md](./Loom_Communities_Workflow_Engine_CameraClub.md)
- [Loom_Communities_Workflow_Engine_ChessClub.md](./Loom_Communities_Workflow_Engine_ChessClub.md)

## 2c. Audience, distribution & invite cardinality (design update, 2026-07-04)

A workflow that one persona *creates* and others *receive* (an event, an announcement, a reminder, a
published book selection) has an **audience** — and audience cardinality is a real axis the archetype
set didn't originally express:

| Cardinality | Example |
| --- | --- |
| **1-to-all-of-a-role** | Mosque admin announces to all members |
| **1-to-selected-many** | Invite these 5 specific people to a planning meeting |
| **1-to-1** | Invite one specific person |

**What already worked, and what didn't.** Persona *symmetry* (who may create vs. who may receive) was
already handled by §2a's role-keyed bindings + a guard on the `create` transition — admin-only-create
is `allowedPersonaIds: ["masjid-admin"]` on that transition; member-to-member just also allows the
member role. **No new cards needed for that.** What broke was cardinality: "who receives" was a
*static role list* (`receiverPersonaIds` = persona *types*), which can only express
**1-to-all-of-a-role**. It cannot express "these 5 people" or "just this one," because the audience
wasn't a per-instance chosen set of individuals.

**Fix — audience as per-instance data (the direct generalization of the marketplace queue).** This is
the *same* primitive as `queuedPersonaIds`: a per-instance list of specific individuals + a
membership gate. Three additions, all reusing existing machinery — **no new archetypes, no extra
per-community cards**:

1. **`audienceSelector` field type in `formEntry`** — the creation form gains one field whose mode is
   `all | selected-many | individual`; picking it populates the instance's audience data. That single
   field collapses all three cardinalities into one workflow.
2. **Per-instance audience data** (just `instanceData`, already supported):
   ```jsonc
   "instanceData": {
     "audienceScope": "selected",              // "all" | "selected" | "individual"
     "invitedPersonaIds": ["fatima","yusuf"],  // empty when scope="all"
     "rsvpByPersona": { "fatima": "going" }     // per-member response — same shape as queuedPersonaIds
   }
   ```
3. **Dynamic `receiver` resolution** — a workflow may declare `audienceMemberField: "invitedPersonaIds"`,
   so the `receiver` role resolves from *this instance's* audience (using the same per-instance
   membership guard the queue introduced) instead of only the static `receiverPersonaIds`.
   `audienceScope: "all"` falls back to the static role; `selected`/`individual` use the list.
   Everything downstream (the `role: receiver` binding, the RSVP/accept/decline transitions) works
   unchanged.

The three cardinalities then collapse to one workflow: **1-to-all** = `scope:"all"`; **1-to-many** =
`invitedPersonaIds:[a,b,c]`; **1-to-1** = `invitedPersonaIds:[x]`. And **distribution** (how each
invitee finds out) is a read-side concern — the invitee's `notificationInbox`/`dashboard` surfaces
"you're invited to X" by querying "instances where I'm in the audience," which is exactly §3's
`queryInstances`. The two design additions connect.

**Backend shape: fan-out-on-read now.** One event/announcement document carrying the audience list +
per-member response map, each recipient querying for instances they're in — mirrors the queue
(per-member state on one instance) and is right for community-scale audiences (dozens–hundreds). The
alternative, **fan-out-on-write** (one recipient record per person), scales to mega-blasts but costs
N writes per create and splits identity — note as a future scaling option, don't build it now.

**Cross-community reach:** this primitive isn't Mosque-specific — HOA owner notifications, Youth
Soccer reminders, and Book Club selection-publish are all "1-to-all / 1-to-selected" distributions
that use exactly this. "Invite list" and "waitlist" being the same shape is a strong signal the
abstraction is holding. **This design is built and tested in Phase 2** (see
[Phase 2's doc](./Loom_Communities_Workflow_Engine_Phase2_Calendar.md)), since Calendar RSVP is the
first workflow where it becomes load-bearing — nothing to implement in Phase 1 itself.

## 2d. Creation/moderation lifecycle vs. interaction lifecycle — one workflow, not two (design update, 2026-07-04)

Every `stateMachineGrid` community (Tabletop, Garden Club, Camera Club, Book Club) has a "list your
own item" flow that was left as an open scope note (see the marketplace `.jsonc`'s header comment) —
does creating a listing (upload image, fill fields, submit, optionally get reviewed, later delist)
need a *second* workflow alongside the browse/borrow one? **No — one workflow, with the
moderation/existence lifecycle as the top-level `states`, and the interaction lifecycle
(available/onLoan/queued) as *orthogonal* `instanceData`.** Merging them into one flat state list
(`draft`, `pending-review`, `published-available`, `published-onLoan`, `published-queued`,
`delisted`, ...) would reproduce the exact mistake `"queued"` already taught us to avoid — two
genuinely independent concerns stacked onto one axis.

```jsonc
{
  "workflowType": "equipment-loan",
  "initialState": "draft",
  "states": {
    "draft":          { "label": "Draft" },
    "pending-review": { "label": "Pending review", "tone": "info" },
    "published":      { "label": "Published", "tone": "positive" },
    "delisted":       { "label": "Delisted" }
  },
  "transitions": [
    { "id": "submit-listing", "label": "Submit for review", "icon": "send", "tone": "primary",
      "from": ["draft"], "to": "pending-review",
      "guard": { "allowedPersonaIds": ["tabletop-member"] } },
    { "id": "approve-listing", "label": "Approve", "icon": "check_circle", "tone": "primary",
      "from": ["pending-review"], "to": "published",
      "guard": { "allowedPersonaIds": ["tabletop-organizer"] },
      "effects": [{ "op": "set", "key": "availabilityState", "value": "available" }] },
    { "id": "reject-listing", "label": "Send back", "icon": "undo", "tone": "secondary",
      "from": ["pending-review"], "to": "draft",
      "guard": { "allowedPersonaIds": ["tabletop-organizer"] } },

    // Top-level state never changes again while actively listed — only availabilityState does,
    // via the instanceDataEquals guard added in §2 above:
    { "id": "borrow", "label": "Request loan", "icon": "arrow_forward", "tone": "primary",
      "from": ["published"], "to": null,
      "guard": { "allowedPersonaIds": ["tabletop-member"],
                 "instanceDataEquals": { "key": "availabilityState", "value": "available" } },
      "effects": [{ "op": "set", "key": "availabilityState", "value": "onLoan" },
                  { "op": "set", "key": "holderPersonaId", "value": "$actor" }] },
    { "id": "return", "label": "Return", "icon": "keyboard_return", "tone": "primary",
      "from": ["published"], "to": null,
      "guard": { "instanceDataEquals": { "key": "availabilityState", "value": "onLoan" } },
      "effects": [{ "op": "set", "key": "availabilityState", "value": "available" },
                  { "op": "set", "key": "holderPersonaId", "value": null }] },

    { "id": "delist", "label": "Delist", "icon": "delete_outline", "tone": "destructive",
      "from": ["published"], "to": "delisted",
      "guard": { "allowedPersonaIds": ["tabletop-member-owner"] } }
  ]
}
```

**Multiple archetypes across one lifecycle — same mechanism as HOA's request/document split, nothing
new:**
```jsonc
"renderBindings": [
  { "states": ["draft"], "role": "actor", "tabId": "marketplace",
    "cardSurfaceFamily": "listing-editor", "bindingKind": "primary" },          // formEntry
  { "states": ["pending-review"], "role": "actor", "tabId": "marketplace",
    "cardSurfaceFamily": "listing-status-badge", "bindingKind": "summary" },
  { "states": ["pending-review"], "role": "receiver", "tabId": "admin",
    "cardSurfaceFamily": "listing-review-queue-item", "bindingKind": "primary" }, // statusTimeline
  { "states": ["published"], "role": "any", "tabId": "marketplace",
    "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary" }           // stateMachineGrid
]
```
Communities without a review step just skip `pending-review` entirely (`submit-listing` targets
`published` directly) — the state is optional per community, not a fixed part of the shape.

This pattern generalizes beyond marketplace listings to *any* create→publish→interact→archive
workflow (Garden Club/Camera Club/Book Club listings; arguably calendar events too, if a community
wants event review before publishing) — it's the general resolution for "creation is a separate
experience from viewing," not a marketplace-specific fix.

## 3. Local workflow engine API (no real backend yet)

Define an abstract `WorkflowEngineApi` (mirrors the shape already documented — but never
implemented — in `docs/API/OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml`):

```dart
abstract class WorkflowEngineApi {
  // READ a collection — the missing third core method (see §3b). Resolves a tab+persona (+ the
  // archetype's search/filter/sort config) into the set of instances a surface should render.
  Future<InstancePage> queryInstances({
    required String tabId,
    required String personaId,
    SurfaceQuery query = const SurfaceQuery(),   // search text, filter values, sort, date-window
    int limit = 25,
    String? cursor,                              // opaque; null = first page
  });

  // READ the actions available on ONE instance for one persona.
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  });

  // MUTATE one instance via a state-changing transition (guard-checked, effects applied).
  WorkflowTransitionResult applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String personaId,
  });

  // CREATE a new instance (added 2026-07-04, §3c) — formEntry's first submission, no instanceId
  // yet. `required`/`type` on instanceDataSchema validated generically at this call, not before.
  Future<String> createInstance({    // returns the new instanceId
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String personaId,
  });

  // EDIT fields on an EXISTING instance without transitioning state (added 2026-07-04, §3c) — e.g.
  // fixing a typo in a draft before submitting. Every key must be in the instance's CURRENT state's
  // editableFields (§7a-i) and declare writableBy:"formEntry" (§7a); `required` is NOT enforced here,
  // so an incomplete draft can still be saved.
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  });
}
// InstancePage = { List<WorkflowInstance> items; String? nextCursor; bool hasMore; }
```

`LocalWorkflowEngineApi` implements this interface (the direct generalization of today's
`_mutableListings`/`_applyTransition` pattern in `part02_tab_shell.dart`) — this is what the demo app
uses now. **Decided 2026-07-05: `LocalWorkflowEngineApi` is backed by real `drift`/SQLite
persistence, not an in-memory `Map`** — see §3d for the full design and rationale. When a real
backend exists later, a `RemoteWorkflowEngineApi` implements the same interface over HTTP; **no
card-surface UI code changes**, since UI only ever talks to `WorkflowEngineApi`, never to
`LocalWorkflowEngineApi` directly.

### 3a. Future production backend: Firebase, validated against XState's model

When a real backend lands (planned: Firestore + Cloud Functions), `RemoteWorkflowEngineApi`
implementation shape, validated 2026-07-04 against how XState models exactly this
(shared, durable, multi-user state — see conversation for full XState comparison):

- **Firestore document per workflow instance** = the durable, shared source of truth
  (`{ state, instanceData }` — literally the "snapshot" concept from a pure state-machine
  transition function). Firestore's real-time listeners (`onSnapshot`) push updates to every
  connected client automatically — this is what makes state "shared across many users" for free;
  the engine itself doesn't need any pub-sub/multi-client logic of its own.
- **Cloud Function, run inside a Firestore transaction** = `applyTransition`'s real implementation:
  read current `{state, instanceData}` → evaluate guards → apply effects → write back atomically.
  The transaction is what makes concurrent taps safe (two members tapping "join queue" on the same
  listing at once) — Firestore retries the transaction, so the second one re-reads the
  already-updated data and correctly re-evaluates its guard.
- **Known gap to plan for**: guard/effect evaluation should stay a **pure function** of
  `(state, instanceData, event)` — no timers, no long-running process per instance (i.e. don't reach
  for a hosted XState-actor product like Stately Sky/State Backed/Restate; we don't need a
  long-running actor for a request/response "tap a button" model). The one thing a pure
  per-request model doesn't give you for free is **delayed/scheduled transitions** (e.g.
  auto-expiring a loan after its due date) — plan to handle those via Cloud Scheduler invoking the
  same `applyTransition` path with a system-originated event, not via an in-process timer.

### 3b. Data query & pagination (design update, 2026-07-04)

Collection archetypes (`stateMachineGrid`, `documentLibrary`, etc.) had **no defined way to get their
rows** — the original `WorkflowEngineApi` only had per-instance `availableTransitions`/`applyTransition`
(both requiring an `instanceId`), and population was described in prose but backed by no method. `queryInstances`
(added to §3 above) is the missing read half of the engine (transitions mutate; queries read).

**How a collection populates — the archetype does not fetch itself imperatively; it declares.** A
surface's `renderBinding` already carries `tabId`, `role`, and `states`; the archetype's own config
carries `search.searchableFields` / `filters.field` / sort. Together those are a fully-derivable
query: *"instances of the workflowTypes bound to this tab whose currentState has a binding for this
persona's role, narrowed by the current search/filter/sort."* The engine resolves that into a
`queryInstances` call and hands the page to the (presentational) archetype widget. The archetype
declares **what** it needs; the engine does the fetch. This keeps the widget dumb and the query in one
place.

**Cursor pagination, not offset.** `queryInstances` takes an opaque `cursor` + `limit` and returns
`{ items, nextCursor, hasMore }`. Cursor (not offset) is required, not a preference:
- The real backend is Firestore (§3a), which paginates natively by cursor (`startAfter(doc).limit(n)`).
- Cursors are **stable under concurrent inserts**; offset paging on a live-updating marketplace would
  skip/duplicate rows as items change under you — a genuine correctness bug on exactly the surfaces
  most likely to change while being scrolled.

**Local vs Firestore split falls out cleanly** (same interface, no UI change):
- `LocalWorkflowEngineApi` is SQLite-backed (§3d) and uses real keyset pagination, not an in-memory
  shortcut — deliberately, to exercise the same cursor contract the Firestore backend needs.
- `FirebaseWorkflowEngineApi` maps `queryInstances` to a Firestore cursor query, with the **first page
  as a live `onSnapshot` listener and the paginated tail fetched on demand** (the standard "live first
  page, paginated tail" pattern — live listeners and deep pagination don't compose, so only the first
  page stays live).

**Sort is part of the query, not just a UI concern (added 2026-07-04, for `table`'s column sorting).**
`SurfaceQuery` gains `sort: { key, direction }` alongside search/filter. This matters for correctness,
not just completeness: **a Firestore cursor is only meaningful relative to the query's current
ordering.** Tapping a column header to re-sort a `table` **must reset pagination to page 1** rather
than reuse the existing cursor — reusing a cursor across a sort change silently returns wrong or
duplicated rows, since `startAfter(doc)` means something different under a different order. `sort.key`
may only reference an `instanceDataSchema` field with `sortable: true` (§7a) — enforced by the §7c
validator, the same shape as the `searchable`/`filters.field` check.

**Not every archetype needs it:**
- **Needs pagination:** `stateMachineGrid`, `documentLibrary`, `notificationInbox`, `discussionThread`,
  `list`, `table`.
- **Single-instance (N/A):** `formEntry`, `guidedProcess`, `paymentCheckout`, `statusTimeline`,
  `protectedDetail`, `votePoll`, `singleItem`.
- **`dashboard`** — its pins are a bounded small set; no paging.
- **`calendarAgenda` is a special case** — its "load more" is a **date-range window** ("show next
  month"), not a row cursor. So its `SurfaceQuery` carries a `dateWindow` (range) instead of a
  `cursor`; range-based paging is a distinct flavor from cursor paging and the query type should
  express both.

**OpenAPI cleanup (pre-existing inconsistency, independent of this engine work):** the specs already
have pagination primitives but they don't line up. `docs/API/OpenAPI/_shared/pagination.yaml` defines
a clean **cursor** model (`Limit` + `Cursor` params, `PageInfo` = `hasMore`+`nextCursor`), but the
card-surfaces spec's list endpoints reference those shared params **zero times** and instead return a
`SurfaceCollectionResponse` with a differently-named `nextPageToken` — and declare **no request-side
page parameter at all**, so responses hint at more pages with no way to ask for the next. Two
conventions (`cursor`/`nextCursor` vs `nextPageToken`), one of them non-functional. **Reconcile on the
shared cursor model**: make `SurfaceCollectionResponse` use `nextCursor` and make the 28 `list-*`/
`browse`/`search` endpoints actually consume the shared `Limit`/`Cursor` params. This is Milestone 1.6
below.

### 3c. Multi-tenant dynamic schema on a fixed backend (design update, 2026-07-04)

The real question isn't "how do we support arbitrary per-community fields" — Firestore is
schema-less at the document level, so that's free. It's narrower: **do the fixed Cloud Functions
ever need to know a specific field's name at deploy time?** They don't, because of the core design
decision made all the way back in §2: guards/effects are a small set of *generic, parameterized*
operators (`allowedPersonaIds`, `actorInList`, `instanceDataEquals`, `set`, `appendUnique`,
`removeValue`, ...) dispatched on operator name and applied against whatever `key` string the JSON
names — never hardcoded field references in application code. That single decision is what makes
this whole section tractable.

**Two Firestore collections, both fixed-shape, both hold dynamic content:**
```
workflowDefinitions/{extensionId}_{workflowType}
  - states, transitions, instanceDataSchema, renderBindings   ← the JSON schema itself, as DATA
  - version, validatedAt, validatorResult

communities/{communityId}/workflowInstances/{instanceId}
  - workflowType: string
  - currentState: string
  - instanceData: map<string, any>     ← the dynamic part; Firestore doesn't care what's in it
  - createdAt, updatedAt, createdByPersonaId
```
One shape for every community that will ever exist. Onboarding a new community/extension is writing
one new `workflowDefinitions` document — never a schema migration, never new backend code deployed.
This is "config as data."

**Five fixed methods, all interpreters, none aware any specific community exists** (§3's
`WorkflowEngineApi`, now complete): `queryInstances`, `availableTransitions`, `applyTransition`,
`createInstance`, `updateInstanceFields`. Each loads the relevant `workflowDefinitions` document by
`workflowType`, interprets its guards/effects/schema generically against whatever `instanceData` is
in play, and that's the entire surface area — forever, regardless of how many communities or
workflow types get authored later.

**Concrete worked example — what actually differs between two communities' listings, and what
doesn't.** Tabletop Club and Garden Club both call `createInstance` — same method signature, same
Cloud Function code path:
```dart
// Tabletop Club
await api.createInstance(
  workflowType: "equipment-loan",
  initialInstanceData: { "title": "Catan", "category": "Board Games", "condition": "Like new",
    "photo": "gs://tabletop-club/listings/catan.jpg", "description": "..." },
  personaId: "tabletop-member-42");

// Garden Club — same method, entirely different community
await api.createInstance(
  workflowType: "garden-tool-loan-giveaway",
  initialInstanceData: { "title": "Pruning shears", "category": "Tools", "condition": "Good",
    "photo": "gs://garden-club/listings/shears.jpg", "loanMode": "loan-or-giveaway" },
  personaId: "garden-member-7");
```
Three things differ, and none are new API surface: the `workflowType` string (a different lookup key
into `workflowDefinitions`), which keys appear in `initialInstanceData` (driven entirely by whichever
`instanceDataSchema` gets loaded — Garden Club's `loanMode` field doesn't exist in Tabletop's schema
at all), and which `communityId` the instance is scoped under (implicit from the caller's session).
The validation loop inside `createInstance` never branches on community — it iterates over however
many `required: true` fields the *loaded* schema declares, whatever they're named. This closes on the
client side too: the `formEntry` widget reads `currentState.editableFields` and calls the same generic
method regardless of which community it's rendering for — neither the backend nor the Flutter code
has a single per-community branch anywhere in this path.

**`createInstance` vs. `updateInstanceFields` — why both, and why `required` only applies to one.**
`createInstance` and `applyTransition` are where `instanceDataSchema.required` gets enforced —
actually submitting or advancing a workflow. `updateInstanceFields` deliberately does **not** check
`required`, because it exists for incidental edits to an already-existing instance while it sits in a
state whose `editableFields` (§7a-i) allows them (fixing a typo in a still-`draft` listing before
ever submitting) — an incomplete draft must be saveable. Authorization for `updateInstanceFields` is
generic and reuses data that already exists: every key in the update must be in the instance's
*current* state's `editableFields`, must declare `writableBy: "formEntry"` (never `"effect"`) in
`instanceDataSchema`, and the caller must hold whatever role that state's binding assigns as editor.

**The one place true dynamism hits a hard Firestore constraint: composite indexes.** Firestore
requires indexes to be declared, not inferred, for compound queries (filter + sort, multiple
filters) — and since `searchable`/`sortable` fields are only known once an extension's
`instanceDataSchema` is authored, they can't be hand-written ahead of time. This needs its own small
automated pipeline: on extension install/update, read the new `workflowDefinitions` document's
`searchable`/`sortable: true` fields (cross-referenced against which `stateMachineGrid`/`table`
archetypes actually reference them via `filters.field`/`sort`) and programmatically deploy the
corresponding entries to `firestore.indexes.json` via the Admin SDK — generated, not hand-maintained,
the same principle as the auto-generated button docs (§5). Track as real Phase 1 infrastructure.

**Security: make Firestore Security Rules boring by pushing all writes through the generic
functions.** Writing *dynamic per-community* Security Rules (validating arbitrary, extension-defined
field types) fights the platform — rules are static with no runtime JSON-schema interpreter. Instead:
**Security Rules deny all direct client writes to `workflowInstances` entirely**; every mutation goes
through a Cloud Function running as a privileged service account, where the real generic validation
happens (`required`/`type`/`writableBy` checked against the loaded schema at request time). Clients
only ever read directly. Rules stay fixed and trivial — written once, never touched per community —
while the actual dynamic logic lives in application code that's *also* fixed, just schema-interpreting.

**Validation happens twice, at two different times, for two different reasons:** (1) **author time**
— the full §7c validator runs in the Skill before a `workflowDefinition` is ever written to Firestore;
(2) **write time** — a thin Cloud Function trigger on `workflowDefinitions` writes re-runs a subset of
the same checks (stuck states, dangling refs) before accepting the document, so a buggy or
compromised Skill run can't push a broken definition straight past the client-side gate.

### 3d. Demo persistence: SQLite-backed `LocalWorkflowEngineApi` (design update, 2026-07-05)

**Decision: `LocalWorkflowEngineApi` persists to a real embedded SQLite database via `drift`, not an
in-memory `Map`.** Rationale and the options weighed:

- **Why not stay in-memory:** would still satisfy the interface, but every restart of the demo app
  silently discards state — fine for a "does the UI render" check, but it hides exactly the class of
  bug this section exists to catch (pagination correctness under real storage, transactional
  guard+effect application, dynamic-schema query/index generation).
- **Why not Parquet:** considered and rejected for this layer specifically (2026-07-04). Parquet is a
  write-once, columnar, OLAP-oriented format — every single-row mutation (one button tap) would force
  a full-file rewrite, the Dart Parquet ecosystem is thin, and it wouldn't even validate anything
  production-relevant: the real backend's *live* path is Firestore (§3a), not Parquet — Parquet only
  ever appears at the export boundary (`exportWizard`, a separate concern from live instance storage).
- **Why SQLite via `drift`:** already a dependency in this codebase (`drift`, `sqlite3`,
  `sqlite3_flutter_libs`, `sqlparser`, `drift_dev` — no new dependency introduced), gives genuine
  cross-restart persistence, and — unlike a `Map` — is a real database with its own transaction
  semantics, real query planner, and (SQLite ≥3.38) native JSON functions. That combination lets the
  demo's local engine rehearse the same *shape* of problem the Firestore backend (§3a/§3b/§3c) will
  actually face, instead of only proving the interface compiles.

**Schema — one fixed-shape table, mirroring the two Firestore collections from §3c:**
```sql
CREATE TABLE workflow_definitions (
  definition_id TEXT PRIMARY KEY,      -- "{extensionId}_{workflowType}"
  workflow_type TEXT NOT NULL,
  definition_json TEXT NOT NULL,       -- states, transitions, instanceDataSchema, renderBindings
  version INTEGER NOT NULL
);

CREATE TABLE workflow_instances (
  instance_id TEXT PRIMARY KEY,
  community_id TEXT NOT NULL,
  workflow_type TEXT NOT NULL,
  current_state TEXT NOT NULL,
  instance_data TEXT NOT NULL,         -- JSON-serialized Map<String, dynamic>, same shape as Firestore's instanceData
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  created_by_persona_id TEXT NOT NULL
);
CREATE INDEX idx_instances_lookup ON workflow_instances (community_id, workflow_type, current_state);
```
`workflow_definitions` exists so the demo loads the same JSON fixtures (e.g.
`Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc`) that a real `workflowDefinitions`
Firestore collection would hold — the local engine never hardcodes a schema in Dart, matching §3c's
"config as data" principle even in the demo.

**How the five `WorkflowEngineApi` methods map onto SQL — each chosen specifically to rehearse its
Firestore counterpart, not just to "make it work":**
- **`queryInstances`** uses **keyset pagination** (`WHERE (sortKey, instance_id) > (?, ?) ORDER BY
  sortKey, instance_id LIMIT ?`), not `OFFSET`. This is a deliberate choice, not a style preference:
  an `OFFSET` implementation would pass every test trivially without ever proving the cursor contract
  (§3b) holds under concurrent inserts — the exact correctness property that matters once Firestore is
  real. Keyset pagination in SQLite validates the same cursor semantics `RemoteWorkflowEngineApi` will
  need against `startAfter(doc)`.
- **`availableTransitions`** reads one row by `instance_id`, decodes `instance_data` JSON, and runs the
  guard evaluator — a pure function of `(state, instanceData, event)` per §3a — completely unchanged
  from how it would run against a Firestore-fetched document. No SQL-specific logic here at all,
  which is itself the point: guard/effect evaluation must stay storage-agnostic.
- **`applyTransition`** runs inside a single SQLite transaction: read the row, evaluate guards, apply
  effects, write `current_state`/`instance_data`/`updated_at` back, all atomically. This is the direct
  local analogue of §3a's "Cloud Function inside a Firestore transaction" — exercising the same
  read-evaluate-write-atomically shape now, on a real transactional engine, rather than deferring the
  first test of that shape to the production backend.
- **`createInstance`** inserts a new row with a generated `instance_id`, the workflow definition's
  declared initial state, and `instance_data` set only after the same generic `required`/`type`
  validation described in §3c runs against the *loaded* `instanceDataSchema` — never a Dart-level
  per-field check.
- **`updateInstanceFields`** merges the given keys into the decoded `instance_data` map and writes it
  back, after the same generic `editableFields`/`writableBy:"formEntry"` authorization check from §3c
  — `required` deliberately not enforced, matching §3's existing contract.

**Dynamic per-community schema on SQLite — same problem as §3c's composite-index pipeline, same
answer.** SQLite has no notion of a fixed collection schema to violate, so arbitrary per-community
fields inside `instance_data` are free, same as Firestore. The one genuine analogue of §3c's
"composite indexes must be generated, not hand-written" constraint: SQLite can index *inside* a JSON
column via expression indexes (`CREATE INDEX ... ON workflow_instances (json_extract(instance_data,
'$.title'))`), but only for fields that exist — so the same generation step described in §3c
(read a `workflowDefinition`'s `searchable`/`sortable: true` fields, cross-referenced against what
archetypes actually query) should emit these expression indexes locally too, rather than hand-listing
fields per community. Building this once, against SQLite, is a low-risk rehearsal of the exact
generation pipeline §3c requires against Firestore later.

**What this validates, concretely, before the production backend exists:** cross-restart persistence
of real data; transactional atomicity of guard-check-then-effect-apply under a real transaction
boundary; keyset-cursor pagination correctness under concurrent inserts; and dynamic per-community
field indexing driven by schema data rather than hardcoded per-field code. Each item rehearses the
matching Firestore behavior in §3a/§3b/§3c directly, so a bug surfaces now, against an embedded
database, instead of being invisible until the real backend is built. **What does not change:** the
`WorkflowEngineApi` interface itself (§3) is identical either way — only `LocalWorkflowEngineApi`'s
internals move from a `Map` to a `drift` database; `RemoteWorkflowEngineApi` remains a separate,
later implementation of the same interface.

## 4. Wiring buttons to transitions

One generic function replaces `_actionsFor` (today marketplace-only): given a workflow instance's
current state + `instanceData` + the acting persona, `availableTransitions(...)` returns the list of
transitions to render as buttons — one button per transition, keyed `<surface>-action-<transitionId>`
(same convention already used: `marketplace-action-<id>`). Tapping a button calls
`applyTransition(...)`; if the transition declares `linkedWorkflowId`, the existing generic
action-surface completion UI still fires exactly as it does today (no change to that layer — it's
already type-agnostic).

## 5. Auto-generated button documentation

Since transitions/guards are fully declarative, a small script can walk a `LoomWorkflowStateMachine`
and emit a table of every state × persona role → available buttons, without hand-maintaining it:

| State     | Persona             | Available buttons   |
| --------- | ------------------- | -------------------- |
| available | member              | Request loan        |
| onLoan    | member (not queued) | Join queue, Return  |
| onLoan    | member (queued)     | Leave queue, Return |
| queued    | member (not queued) | Join queue          |
| queued    | member (queued)     | Leave queue         |

This becomes the living replacement for hand-written sections of `equipment-loan.md` and similar
card-surface docs — generated from the JSON, not hand-synced (removing an entire class of
doc-goes-stale-vs-code bugs we've hit repeatedly in the AppShell V2 tracker, e.g. `event-rsvp.md`).

## 6. Explicitly out of scope for Phase 1
- Any change to Calendar or Marketplace before AppShell V2's current tracker closes both phases —
  **satisfied**, both re-closed 2026-07-04. Phase 1 supersedes that interim fix rather than building
  on top of it.
- A real backend / HTTP implementation of `WorkflowEngineApi` — `LocalWorkflowEngineApi` is the only
  implementation needed for the demo app throughout Phases 1-5 (see main tracker §… "Out of scope").
- Audience/distribution (§2c), RSVP, payment, and any second-community work — Phases 2-4.

## 7. Skill-facing engine internals (design, brainstormed 2026-07-04)

These four subsections (`instanceDataSchema` as schema source of truth, `editableFields`, cross-workflow
dependencies, and the validator/rendering-layer contracts) are **built in Phase 1**, even though their
ultimate consumer is the Skill (Phase 6) — Phase 1's own fixture
(`Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc`) already requires the full
`instanceDataSchema` shape below, and the §7c validator/§7d rendering contract are explicitly Phase 1
build items (see Milestones 1.3/1.4 below).

### 7a. The schema needs two layers, not just the state machine

Layer 1 is the state machine already designed in §2 (`states`/`transitions`/`guard`/`effects`).
Layer 2 is `instanceDataSchema` — and as of 2026-07-04 it's **the single source of truth for a
field's entire life**: storage, validation, and display, not just display metadata. Before this
extension, `instanceDataSchema` (display) and `formEntry.fields[]` (input: type/required) were two
separate, hand-synced field lists for the same data — exactly the "doc-goes-stale-vs-code" failure
mode this whole redesign exists to eliminate elsewhere. Fixed by folding everything into one place:

```jsonc
"instanceDataSchema": {
  "title": {
    "type": "text", "required": true, "maxLength": 120,
    "writableBy": "formEntry",           // "formEntry" | "effect" — who's ever allowed to set this
    "storage": "inline",                 // stored directly in the instance document
    "searchable": true,                  // usable in a stateMachineGrid's search.searchableFields
    "sortable": true,                    // usable as a sortable table column (§ table archetype)
    "displayIcon": null, "labelTemplate": "{value}", "displayContexts": ["tile","detail"]
  },
  "photo": {
    "type": "image", "required": false,
    "writableBy": "formEntry",
    "storage": "reference", "storageTarget": "firebase-storage",  // see note below — NOT stored inline
    "displayContexts": ["tile","detail"]
  },
  "holderPersonaId": {
    "type": "personaId?",
    "writableBy": "effect",              // NEVER user-entered — only a transition's effect sets this
    "sortable": false,                    // no useful sort order on a persona ID
    "displayIcon": "person_outline", "labelTemplate": "Holder: {value}", "displayContexts": ["tile","detail"]
  },
  "queuedPersonaIds": {
    "type": "personaId[]", "writableBy": "effect",
    "displayIcon": "groups_outlined", "labelTemplate": "Queue: {value.length}",
    "displayContexts": ["tile","detail"], "hideWhenEmpty": true
  }
}
```

A generic fact-pill renderer walks this schema + current `instanceData` and picks the right
icon/label every time, for any workflow type — this is the direct fix for the Calendar bug (every
fact pill hardcoding the same checkmark icon) generalized into the schema itself, so no call site can
regress it again.

**`storage`/`storageTarget` — images are a materially different case.** A text/date/number field's
value *is* what's stored in `instanceData`. An image cannot work that way — Firestore documents cap
around 1MB and aren't built for binary blobs. `storage: "reference"` means the field holds a
**URL/path string**, not the bytes; the actual file lives in Firebase Storage. This makes an image
field's write a two-step flow (upload to Storage first, then write the returned URL into
`instanceData` via the normal `formEntry` submission), not a special case in the engine itself — the
transition/effect layer doesn't know or care that the string happens to be a Storage URL.

**What this schema now generates**, beyond the UI form/display/button-docs already covered: backend
validation (Firestore Security Rules checking `required`/`type` server-side — defense in depth
beyond the Cloud Function's own guard check, since a malicious client could otherwise write to
Firestore directly) and Firestore composite indexes (any `searchable`/`sortable: true` field needs a
real index to query/sort on — generated from the schema instead of hand-maintained separately).

### 7a-i. Per-state field editability — `editableFields` (added 2026-07-04, replaces `formEntry.fieldOrder`)

Which fields a `formEntry`/`guidedProcess` surface shows as editable **varies by workflow state**
(a listing's fields are all editable in `draft`, mostly locked in `pending-review`, not editable at
all once `published`). Declaring that per-archetype-binding would duplicate across every
`formEntry`/`guidedProcess` surface a workflow has — so it's declared once, on the state itself:

```jsonc
"states": {
  "draft":          { "label": "Draft",
                       "editableFields": ["photo","title","category","condition","description"] },
  "pending-review": { "label": "Pending review", "tone": "info",
                       "editableFields": ["reviewNotes"] },
  "published":      { "label": "Published", "tone": "positive" }  // no editableFields — nothing
                                                                    // user-editable once published;
                                                                    // borrow/delist are TRANSITIONS,
                                                                    // not field edits
}
```

**Rendering rule, fully mechanical, no archetype config needed:** at the current state, a
`formEntry`/`guidedProcess` surface renders every field in that state's `editableFields` as an input.
Every *other* `writableBy: "formEntry"` field with a non-empty value renders **read-only/locked**
(reusing the existing `hideWhenEmpty` — no new hidden/visible/editable three-state system). A field's
identity, type, and validation live once in `instanceDataSchema`; the state only says which subset is
currently editable. This generalizes to `guidedProcess` for free, since its steps *are* states in this
model — Youth Soccer's registration wizard (join→waiver→payment→roster) declares `editableFields` per
step exactly the same way.

**Net effect: `formEntry.fieldOrder` is removed** — the field list and order are derived from
`state.editableFields` in `instanceDataSchema`'s own declared order. `formEntry`'s own config keeps
only genuinely presentational concerns (grouping fields into visual sections, `submitLabel`) — never
*which* fields, only *how arranged*. `writableBy: "effect"` fields can never appear in any state's
`editableFields` — enforced by the §7c validator, not left as an authoring convention.

### 7b. Cross-workflow dependencies get a real field

Today's `prerequisiteWorkflowId` (`part11_shell_models.dart:888`) is a single string — one dependency,
no expressiveness. Generalize to a list, at the transition level:

```json
"guard": {
  "allowedPersonaIds": ["tabletop-member"],
  "requiresWorkflowsComplete": ["tabletop-membership-dues-current"]
}
```

When unsatisfied, the generic renderer doesn't hide the button — it shows the **already-existing**
`waitingForPrerequisite`/`waitingText: 'Waiting'` UX (`part12_persona_and_tabs.dart:114-115` — this is
a real pattern already in the codebase, being generalized, not invented). This is the mechanism that
makes dependency declarations drive rendering, not just gate an API call. **First real usage is
Phase 3** (Giving's dues-current gate on Marketplace's `borrow` transition) — the field is designed
here so Phase 1's guard evaluator already knows how to interpret it, but nothing exercises it until
Phase 3.

### 7c. Validator — a new required Skill gate, same shape as the existing judges

`SKILL.md` already has a family of judge tools run via `dart run
packages/tooling/loom_ux_judges/bin/*.dart` (`workflow_completeness_judge.dart`, `ux_contract_judge.dart`,
etc.) under its "Required Workflow Validation Gate" section. A new `workflow_state_machine_validator.dart`
slots into that exact pattern, run **before** any UI generation, checking:

- **Stuck states** — every non-terminal state has ≥1 outgoing transition (this is *literally* the bug
  we hit: the marketplace loan template's `"queued"` state had zero).
- **Unreachable states** — every declared state is reachable from `initialState` via BFS over
  `transitions` (the `@xstate/graph`-style reachability check, ported to Dart, over our own schema).
- **Dangling references** — every `allowedPersonaIds` entry, `requiresWorkflowsComplete` target,
  `linkedWorkflowId`, and `instanceDataSchema` key referenced by a guard/effect actually resolves.
- **Dependency cycles** — no workflow transitively requires itself complete via
  `requiresWorkflowsComplete`.
- **Every transition has a `label`** — so a generated button never renders without display text.
- **Binding cap** (§2a) — ≤32 `renderBindings` and ≤16 distinct roles per workflow type; past that is
  a smell (almost always two workflows), not a hard wall.
- **Mandatory action-button-row slot** (§7d) — every `bindingKind: "primary"` template includes
  exactly one `WorkflowActionButtonRow`; a primary binding missing it fails, the same as a stuck state.
- **`editableFields` only references `writableBy: "formEntry"` keys** (§7a-i) — a state can never
  declare an effect-only field as editable; that's an authoring bug, not a valid configuration.
- **`table` column `sortable: true` only references an `instanceDataSchema` field with
  `sortable: true`** (§3b) — same shape as the `searchable`/`filters.field` check, catching a column
  declared sortable over a field with no backing index.

### 7d. Rendering layer — shared interactive primitives + a small per-family layout template

Today every card-surface family (`_ListingDetailView`, `_GivingTabSurface`, `_CalendarEventDetail`)
independently re-implements "render fact pills" and "render action buttons." Instead:

- **Generic, shared widgets** (built once, in the engine package): `WorkflowActionButtonRow` (takes
  `availableTransitions(...)`'s output, renders available/waiting/hidden per §7b) and
  `WorkflowFactPillRow` (takes `instanceData` + `instanceDataSchema`, renders icon+label per §7a) — usable
  by any `workflowType`.
- **A small per-`cardSurfaceFamily` layout template** — declarative arrangement (header, then
  fact-pill row, then action-button row, then linked-workflow completion state), differing only in
  chrome between families, not in the interactive logic underneath.
- **Mandatory action-button-row contract (added 2026-07-04 — closes a real gap).** Every archetype's
  primary-binding template (`bindingKind: "primary"`, §2a) **must** include exactly one
  `WorkflowActionButtonRow`, bound to that binding's `workflowType`. This is not configurable per
  community and not optional — it's a structural property of being a primary binding, the same way
  every archetype has a `theme`/`workflowType`. Position is archetype-specific (bottom of the detail
  panel for `stateMachineGrid`; bottom of the form for `formEntry`; inline per-step for
  `guidedProcess`; top-right for `statusTimeline`'s reviewer actions) but presence is universal. This
  is what makes "the archetype inherits the buttons" true by construction rather than a manual
  per-community wiring step — a community/Skill author never declares which buttons appear where; they
  declare `workflowType` (supplies the actions, via `availableTransitions`) and `cardSurfaceFamily`
  (supplies the container), and the fixed slot is what connects them. Add this as a §7c validator
  check: any primary-binding template missing the slot fails, the same way a stuck state does.
- **What the Skill/LLM still authors**: the workflow JSON (validated per §7c), which
  `cardSurfaceFamily` template to use (already an existing Skill decision — SKILL.md rule 15), and
  domain copy. What it stops hand-writing: per-workflow icon choices, button enable/waiting/hidden
  logic, or bespoke button-wiring code — including, as of the `icon`/`tone` addition above, the
  button's own icon.

## 8. Milestones

Each milestone's evidence bar must be fully green before the next starts (same convention as
`AppShell V2 Tracker.md`). Suite/emulator commands run in WSL Ubuntu (the only environment on this
machine with Flutter + the Android SDK/emulator configured).

### Milestone 1.1 — Core state machine engine (no UI, no persistence)
Build `LoomWorkflowStateMachine`/`LoomWorkflowTransition`/`instanceDataSchema` model classes and the
guard/effect evaluator (§2, §2d, §7a) as pure Dart, parsed from JSON matching
`Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc`'s shape.

**Validation tests required to close this milestone:**
- [ ] Unit tests for every guard operator (`allowedPersonaIds`, `actorInList` present/absent,
  `instanceDataEquals`) — both the true and false branch of each, including the compound-guard case
  (`allowedPersonaIds` AND `instanceDataEquals` both required, one true one false → transition
  unavailable).
- [ ] Unit tests for every effect operator (`set`, `appendUnique` on an empty list / on a list already
  containing the value / on a list not containing it, `removeValue` present/absent, `increment`,
  `decrement`) — assert the exact resulting `instanceData`, not just "no crash."
- [ ] Unit test reproducing the original marketplace bug as a regression guard: a state with zero
  outgoing transitions parses successfully (the engine itself must not reject it — that's the
  validator's job in Milestone 1.3, not a parse-time error) but `availableTransitions` on it correctly
  returns an empty list.
- [ ] Unit test for the §2d orthogonal-lifecycle example: parse the `equipment-loan` JSON from §2d,
  drive it draft → pending-review → published → borrow → return → delist, asserting `currentState`
  and `instanceData.availabilityState` change independently at each step (proves the two axes don't
  leak into each other).
- [ ] Unit test for `renderBindings` role resolution (§2a): a persona holding two roles on one
  instance resolves both matching bindings, not just one.

### Milestone 1.2 — `WorkflowEngineApi` + SQLite-backed `LocalWorkflowEngineApi`
Build the abstract `WorkflowEngineApi` (§3) and its `drift`/SQLite implementation (§3d) — schema
migration, DAO methods for all five interface methods, keyset pagination.

**Validation tests required to close this milestone:**
- [ ] `createInstance` unit test: submitting valid `initialInstanceData` (all `required: true` fields
  present) succeeds and returns a resolvable `instanceId`; submitting with a missing required field
  throws a typed validation error naming the missing field.
- [ ] `updateInstanceFields` unit test: editing a field in the current state's `editableFields`
  succeeds; editing a field NOT in `editableFields` (e.g. `holderPersonaId`, `writableBy: "effect"`)
  is rejected; editing while leaving other required fields empty still succeeds (proves `required` is
  correctly NOT enforced here per §3c).
- [ ] `applyTransition` transactional-atomicity test: two concurrent `applyTransition` calls on the
  same instance for a guard that only one can satisfy (e.g. `join-queue` when `actorInList` requires
  absence) — assert exactly one succeeds and the other's guard correctly re-evaluates against the
  first's already-applied effect (the local analogue of Firestore's transaction-retry behavior, §3a).
- [ ] `queryInstances` keyset-pagination test: seed >1 page of instances, page through with the
  returned `nextCursor` until `hasMore == false`, assert the concatenated pages contain every seeded
  instance exactly once, in stable order. **Concurrency variant (the actual point of choosing keyset
  over offset, §3b):** insert a new instance that sorts *before* the current cursor position between
  two `queryInstances` calls — assert the already-fetched page is unaffected and no row is skipped or
  duplicated across the two calls.
- [ ] `queryInstances` sort-change test: fetch page 1 sorted by field A, change `sort.key` to field B
  without resetting the cursor — assert the engine resets to page 1 itself rather than reusing the
  stale cursor (per §3b's "sort change must reset pagination" rule) — either by ignoring a
  now-invalid cursor or by throwing, whichever the implementation settles on, but never silently
  returning wrong rows.
- [ ] Cross-restart persistence test: write instances, close and reopen the `drift` database
  connection (simulating an app restart), assert `queryInstances` returns the same data — the actual
  property that motivated choosing SQLite over in-memory (§3d).
- [ ] Dynamic-schema query test: load two different `workflowDefinitions` fixtures with disjoint
  `searchable`/`sortable` fields, assert querying/sorting by each community's own fields works and
  the expression-index generation step (§3d) doesn't hardcode either community's field names.

### Milestone 1.3 — Validator (`workflow_state_machine_validator.dart`)
Build the §7c validator as a standalone Dart tool runnable via
`dart run packages/tooling/loom_ux_judges/bin/workflow_state_machine_validator.dart`.

**Validation tests required to close this milestone:**
- [ ] Regression-guard test (explicitly called out in the original design, §7c/Phase 1 evidence bar):
  intentionally reintroduce a stuck state (a state with zero outgoing transitions that isn't declared
  terminal) into a copy of the marketplace fixture — assert the validator fails with a message
  identifying that exact state, then assert it passes again once reverted.
- [ ] Unreachable-state test: add a state no transition ever targets — validator fails, naming the
  unreachable state.
- [ ] Dangling-reference tests, one per reference kind: bad `allowedPersonaIds` entry, bad
  `requiresWorkflowsComplete` target, bad `linkedWorkflowId`, bad `instanceDataSchema` key in a
  guard/effect — each fails with a message naming the specific dangling reference.
- [ ] Dependency-cycle test: two workflows whose `requiresWorkflowsComplete` chains form a cycle —
  validator fails, naming the cycle.
- [ ] Missing-label test: a transition with no `label` — validator fails.
- [ ] Binding-cap test: a workflow declaring 33 `renderBindings` or 17 distinct roles — validator
  flags it (smell, per §2a — confirm whether implemented as a hard failure or a warning, and assert
  that behavior explicitly, not just "some output").
- [ ] Missing-action-button-row test: a `bindingKind: "primary"` template with no
  `WorkflowActionButtonRow` slot — validator fails (§7d's mandatory-slot contract).
- [ ] `editableFields`-references-`effect`-field test: a state declaring an effect-only field as
  editable — validator fails.
- [ ] `sortable` `table`-column-without-backing-field test: a `table` archetype config marking a
  column sortable over an `instanceDataSchema` field that isn't `sortable: true` — validator fails.
- [ ] Green-path test: the actual `Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc` fixture
  passes the validator with zero findings, once converted from illustrative comments into real data
  (this is the fixture's own acceptance bar, not just the validator's).

### Milestone 1.4 — Rendering primitives + first `cardSurfaceFamily` templates
Build `WorkflowActionButtonRow`/`WorkflowFactPillRow` (§7d) and the `equipment-loan`/
`equipment-giveaway` templates.

**Validation tests required to close this milestone:**
- [ ] Widget test: `WorkflowActionButtonRow` given a fixed `availableTransitions()` output renders
  exactly one button per transition, each keyed `<surface>-action-<transitionId>`, with the declared
  `icon`/`tone` (primary/secondary/destructive visually distinct, e.g. via `Key`/`ButtonStyle`
  assertions, not just "a button exists").
- [ ] Widget test: a transition gated by an unsatisfied `requiresWorkflowsComplete` (§7b) renders the
  existing `waitingForPrerequisite`/"Waiting" UX, not a hidden button and not a crash.
- [ ] Widget test: `WorkflowFactPillRow` given `instanceData` + `instanceDataSchema` renders the
  correct icon/label per field, including the `hideWhenEmpty` case (an empty `queuedPersonaIds`
  produces zero pills, a non-empty one shows the `Queue: {n}` label) — this is the direct regression
  guard for the Calendar checkmark-icon bug, generalized.
- [ ] Widget test: the `equipment-loan`/`equipment-giveaway` templates each render with exactly one
  `WorkflowActionButtonRow` in their primary binding (manual proof of the §7d contract the validator
  also checks structurally).

### Milestone 1.5 — Replace Tabletop Marketplace tab with the new engine end-to-end
Replace `LoomListingStateMachine`/`_ListingCard`/`_ListingDetailView` with the new engine + generic
renderer, wired through `LocalWorkflowEngineApi`, including whatever `queuedPersonaIds`/
`requiresActorInQueue` shape the interim AppShell V2 fix landed with (this phase supersedes that
interim fix, not layers on top of it).

**Validation tests required to close this milestone:**
- [ ] Full behavioral-parity widget-test suite against today's Marketplace tab: grid renders, detail
  view opens, borrow/join-queue/leave-queue/return/giveaway-claim all function — one test per
  interaction, not one combined smoke test.
- [ ] `queryInstances` actually populates the grid — assert via a fake/injected paginated dataset
  larger than one page that the grid requests and renders a second page (in-memory-sized demo data
  alone wouldn't prove this; pad the fixture or inject a larger fake dataset specifically for this
  test).
- [ ] Live emulator walk (WSL Ubuntu, `PantryVision_Manual_API_36` AVD): screenshot evidence of the
  Marketplace tab on the new engine performing the same round trip as the current
  `wf_marketplace-join-then-leave-queue` test, on-device.
- [ ] Full `flutter test` suite green, exact pass count cited, zero regressions elsewhere.
- [ ] §1.3's validator run against the live fixture as a final gate, output pasted into the evidence
  log.

### Milestone 1.6 — OpenAPI pagination cleanup
Reconcile `docs/API/OpenAPI/_shared/pagination.yaml`'s cursor model with the card-surfaces spec (§3b).

**Validation tests required to close this milestone:**
- [ ] `SurfaceCollectionResponse` uses `nextCursor` (renamed from `nextPageToken`); confirm via a spec
  diff that no endpoint still references the old field name.
- [ ] The 28 `list-*`/`browse`/`search` endpoints reference the shared `Limit`/`Cursor` request
  params — confirm via a grep-based count matching the spec's own endpoint count, not a sample.
- [ ] Spec lints clean (whatever OpenAPI lint tool this repo already uses for these files).
- [ ] The marketplace browse endpoint specifically declares a functional request-side cursor
  parameter and its response documents `nextCursor` — spot-checked by hand since it's the
  Milestone-1.5-adjacent endpoint.
