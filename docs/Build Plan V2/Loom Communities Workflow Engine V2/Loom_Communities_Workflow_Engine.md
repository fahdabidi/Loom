# Loom Communities — General Workflow Engine

Status: Draft, not started. **Depends on**: `Loom Communities App Shell V2/AppShell V2 Tracker.md`'s
Calendar (M4 reopened) and Marketplace (M3b reopened) phases being fully completed and closed first.
Nothing in this document should be implemented before that.

## 1. Context & motivation

The AppShell V2 work exposed a recurring problem: every time a workflow needs a new interaction
(queued listings needing "Join queue"/"Leave queue", for example), the fix is a bespoke, one-off
addition to `LoomMarketplaceListing`/`LoomListingTransition` — a new boolean flag, a new field, a
new bit of wiring in `_actionsFor`/`_applyTransition`. That model is *already* a real, declarative
state machine (`LoomListingStateMachine`, `part11_shell_models.dart:69-141`), but it's scoped only
to marketplace listings, and its vocabulary is ad-hoc booleans
(`setsHolderToActor`/`clearsHolder`/`incrementsQueue`/`decrementsQueue`/`removesFromList`) rather
than a general mechanism. Meanwhile every *other* workflow type (RSVP, payment, approval,
announcement) has **no state machine at all** — just a fixed actor/receiver/completed lifecycle
(`personaWorkflowStateFor`, `part12_persona_and_tabs.dart:54-75`) and a workflow "family" that's
*guessed* from the workflow ID string (`part13_workflow_copy_catalog.dart`'s `id.contains('payment')`
etc.), not declared.

Goal: replace the ad-hoc-flags-per-feature pattern with one general, JSON-declared workflow engine
that any workflow type can use — states, transitions, guards, and effects — and a thin local API
layer that simulates what a real backend would eventually do, so card-surface UI code never needs to
change when the engine gets a real backend later.

## 2. Prior art considered (see conversation for full comparison)

- **Amazon States Language** / **CNCF Serverless Workflow** — both are JSON DSLs, but built for
  orchestrating serverless *compute* steps (retries, parallel branches, error handling), not
  persona-driven UI state. Wrong domain fit, needlessly heavy.
- **SCXML** — mature W3C statechart standard, but XML-based, and a full implementation
  (hierarchical/parallel states, `<datamodel>`, `<invoke>`) is far more than this app needs.
- **XState** — a JS/TS state machine library. Its vocabulary (states, events/transitions, guards,
  actions, context) is the closest conceptual match to what we want, and it's the direct inspiration
  for the schema below — but it's a JS library, not something we can depend on from Dart.

**Decision: don't adopt any of these wholesale.** Evolve our own existing, already-proven,
Dart-native shape (`LoomListingStateMachine`) into a domain-agnostic engine, borrowing XState's
vocabulary (guards, actions/effects, context) rather than its runtime.

## 3. Proposed general schema

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
      "from": ["available"],
      "to": "onLoan",
      "guard": { "allowedPersonaIds": ["tabletop-member"] },
      "effects": [{ "op": "set", "key": "holderPersonaId", "value": "$actor" }],
      "linkedWorkflowId": "tabletop-game-loan"
    },
    {
      "id": "join-queue",
      "label": "Join queue",
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

Key generalization: today's per-feature boolean flags on `LoomListingTransition`
(`setsHolderToActor`, `clearsHolder`, `incrementsQueue`, `queuedPersonaIds`-specific fields, etc.)
and the growing pile of named fields on `LoomMarketplaceListing` (`currentHolderLabel`,
`queueLength`, `dueLabel`, ...) collapse into two small, reusable primitives:

- **`instanceData: Map<String, dynamic>`** — a generic per-instance data bag (replaces
  `currentHolderLabel`/`queueLength`/`queuedPersonaIds`/etc. as named Dart fields; any workflow type
  declares whatever keys it needs).
- **`guard`** — a small declarative predicate vocabulary evaluated against `instanceData` + the
  acting persona (`allowedPersonaIds`, `actorInList`, extensible to more predicates later as real
  needs arise — resist over-building this up front).
- **`effects`** — a small declarative mutation vocabulary applied to `instanceData` on successful
  transition (`set`, `appendUnique`, `removeValue`, `increment`, `decrement` — same idea, keep
  minimal, add operations only when a real workflow needs one).

This is *the* central design decision: no new boolean flag ever needs to be added to a Dart class
again for a new interaction — a community/workflow author declares a new guard/effect combination
in JSON instead.

## 3a. Workflows, card surfaces, and tabs are many-to-many (design update, 2026-07-04)

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

- **`role`** reuses the existing actor/receiver/readOnly vocabulary (`LoomWorkflowPersonaPolicy`'s
  existing fixed per-workflow-instance assignment) rather than inventing new per-state role concepts
  — the author is always `actor`, the approver always `receiver`, even during states where the actor
  has zero available transitions. `"any"` covers states where the role distinction stops mattering
  (once published, everyone reads the same surface).
- **A binding doesn't restate which transitions are available.** That's still
  `availableTransitions(state, persona, instanceData)`'s job (§3's existing guard mechanism) — a
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

## 3b. Container archetypes — revised from evidence (2026-07-04), not guessed from Tabletop alone

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

### Revised archetype catalog (12 container types + 1 cross-cutting rendering concern)

Each entry cites which communities' product docs demonstrate the need, so this stays evidence-backed
rather than speculative. Full per-community tab/card/action detail lives in sibling docs in this
folder (§ index at the bottom of this section).

1. **`calendarAgenda`** — month/week/date-strip + date-grouped agenda list + expandable event-detail
   panel; built-in sub-pattern for RSVP/capacity/waitlist/reminder/conflict. **Every single community**
   needs this (Tabletop, HOA, Mosque, Book Club, Youth Soccer, Garden Club, Camera Club, Chess Club) —
   the strongest possible signal. Supersedes the earlier plain `list` framing for anything date-grouped.
2. **`stateMachineGrid`** — responsive grid (2-3 up) + search/filter + listing detail whose action
   buttons are engine-derived from a per-item state machine (§3), with built-in queue/waitlist
   position and current-holder/custody (privacy-redacted) as first-class sub-state, not bolted on.
   Needed by: Tabletop (equipment-loan), Garden Club (tool loan/giveaway, plant exchange), Camera Club
   (gear loan), Book Club (shared library). Supersedes the earlier plain `grid` — a plain tile grid
   without built-in queue/custody state was flagged explicitly as an anti-pattern in two of these docs
   ("single generic request card... without browse, queue, listing, or custody").
3. **`documentLibrary`** — categorized library/folders + document detail + embedded-vs-external open
   choice + version/access/acknowledgement state + audit trail. Needed by: HOA, Mosque, Book Club,
   Youth Soccer (waivers).
4. **`statusTimeline`** — sequential named steps (submitted → under-review → changes-needed →
   approved/rejected → reopened) with current/previous/next, dual requester/reviewer view, comments,
   payment/document checkpoints, audit history, alternate actions (request changes, reopen, appeal,
   retry). Needed by: HOA (architectural request + committee decision), Youth Soccer (guardian join
   approval), lighter versions in Camera Club (critique draft/submitted/reviewed) and Chess Club
   (result dispute).
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
  composes `calendarAgenda`'s event-detail with `statusTimeline`'s propose/respond/confirm shape.
- Camera Club's photo critique (image + attached comment thread + reviewer queue) — composes
  `stateMachineGrid` (image-forward item template) with `discussionThread` attached.

### Cross-cutting rendering concern (not a 13th container — applies to all of them)

Every archetype above must render in **actor / receiver / readOnly / disabled-with-reason / hidden**
modes for the same underlying data (Mosque's persona-picker and persona-aware-UX workflows require
this explicitly, and it's a repeated requirement across every community doc's persona/state matrix).
This is already the right shape for §3a's `renderBindings.role` field to carry — no new mechanism
needed, just confirmation that §3a's design (role-keyed bindings, reusing the existing actor/
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

## 4. Local workflow engine API (no real backend yet)

Define an abstract `WorkflowEngineApi` (mirrors the shape already documented — but never
implemented — in `docs/API/OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml`):

```dart
abstract class WorkflowEngineApi {
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  });

  WorkflowTransitionResult applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String personaId,
  });
}
```

`LocalWorkflowEngineApi` implements this entirely in-memory (the direct generalization of today's
`_mutableListings`/`_applyTransition` pattern in `part02_tab_shell.dart`) — this is what the demo app
uses now. When a real backend exists later, a `RemoteWorkflowEngineApi` implements the same
interface over HTTP; **no card-surface UI code changes**, since UI only ever talks to
`WorkflowEngineApi`, never to `LocalWorkflowEngineApi` directly.

### 4a. Future production backend: Firebase, validated against XState's model

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

## 5. Wiring buttons to transitions

One generic function replaces `_actionsFor` (today marketplace-only): given a workflow instance's
current state + `instanceData` + the acting persona, `availableTransitions(...)` returns the list of
transitions to render as buttons — one button per transition, keyed `<surface>-action-<transitionId>`
(same convention already used: `marketplace-action-<id>`). Tapping a button calls
`applyTransition(...)`; if the transition declares `linkedWorkflowId`, the existing generic
action-surface completion UI still fires exactly as it does today (no change to that layer — it's
already type-agnostic).

## 6. Auto-generated button documentation

Since transitions/guards are fully declarative, a small script can walk a `LoomWorkflowStateMachine`
and emit a table of every state × persona role → available buttons, without hand-maintaining it:

| State | Persona | Available buttons |
| --- | --- | --- |
| available | member | Request loan |
| onLoan | member (not queued) | Join queue, Return |
| onLoan | member (queued) | Leave queue, Return |
| queued | member (not queued) | Join queue |
| queued | member (queued) | Leave queue |

This becomes the living replacement for hand-written sections of `equipment-loan.md` and similar
card-surface docs — generated from the JSON, not hand-synced (removing an entire class of
doc-goes-stale-vs-code bugs we've hit repeatedly in the AppShell V2 tracker, e.g. `event-rsvp.md`).

## 7. Rollout plan (sequenced, brainstormed 2026-07-04)

Each phase below only starts once the prior phase's evidence bar is fully green. Phases 1-3 stay
inside Tabletop Club (the community we already understand in depth). Phase 4 deliberately switches
to a *different* community to prove the schema generalizes, before any automation or Skill changes
are attempted.

### Phase 1 — Marketplace engine prototype (Tabletop Club)
The big one: everything downstream reuses what gets built here.
- Build `LoomWorkflowStateMachine`/`LoomWorkflowTransition`/`instanceDataSchema`/guard+effect
  evaluation (§3), fully generic, with its own unit tests — no UI yet.
- Build `WorkflowEngineApi`/`LocalWorkflowEngineApi` (§4).
- Build the §9c validator (`workflow_state_machine_validator.dart`) — stuck/unreachable states,
  dangling references, dependency cycles, missing labels.
- Build the generic rendering primitives (`WorkflowActionButtonRow`, `WorkflowFactPillRow`, §9d) and
  the first `cardSurfaceFamily` templates: `equipment-loan` (Catan/Wingspan) and `equipment-giveaway`
  (retired Catan) — using `Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc` as the actual
  fixture, converted from illustrative comments into real, validator-passing data.
- **Replace** `LoomListingStateMachine`/`_ListingCard`/`_ListingDetailView` in Tabletop's Marketplace
  tab with the new engine + generic renderer end to end (including whatever
  `queuedPersonaIds`/`requiresActorInQueue` shape the interim AppShell V2 fix lands with first — this
  phase supersedes that interim fix, not layers on top of it).
- **Evidence bar**: full behavioral parity with today's Marketplace tab (grid + detail + borrow/
  join-queue/leave-queue/return + giveaway claim) proven live on-device; validator green on the
  fixture; full test suite green with no regressions elsewhere; §9c validator demonstrably catches an
  intentionally-reintroduced stuck state (regression-guard the tooling itself, not just the schema).

### Phase 2 — Calendar (Tabletop Club)
Reuses all Phase 1 infrastructure — should be materially smaller than Phase 1.
- New `cardSurfaceFamily` template (`event-rsvp` or similar) using the same
  `WorkflowActionButtonRow`/`WorkflowFactPillRow` primitives.
- **Open design question to resolve during this phase, not before**: today's calendar RSVP workflows
  aren't really a rich state machine (mostly a fixed actor/receiver lifecycle +
  `responseChoices`) — this phase needs to determine whether RSVP maps cleanly onto
  `states`/`transitions`, or whether the schema needs a lighter-weight "simple response" mode
  alongside the full FSM mode. Don't force-fit; report back what's actually discovered.
- Migrating this also fixes the two Calendar UI bugs from the current AppShell V2 tracker as a
  side effect of using the schema's `instanceDataSchema` icons/labels *if* those fixes haven't
  already landed independently first (they should have, per the current tracker's sequencing) — the
  date-strip dedup bug is a separate, date-grouping-specific concern this phase should not assume is
  automatically solved.
- **Evidence bar**: same shape as Phase 1 — live parity walk, validator green, full suite green.

### Phase 3 — Giving (Tabletop Club)
Also reuses Phase 1 infrastructure.
- New `cardSurfaceFamily` template (`payment`).
- Migrate the dues-payment workflow: `unpaid`/`paid` states, a `pay` transition with
  `linkedWorkflowId` firing the existing generic action-surface.
- **Natural follow-on, only after both sides exist on the new engine**: wire
  `requiresWorkflowsComplete` for real on Marketplace's `borrow` transition, requiring the dues
  workflow complete — the illustrative, commented-out example already in the `.jsonc` file. This is
  the first real cross-workflow-type dependency, so treat it as its own small sub-milestone with its
  own evidence (both directions: member with current dues can borrow, member without cannot and sees
  the waiting UX), not a rider on Phase 3's main evidence bar.
- **Evidence bar**: same shape as Phases 1-2.

### Phase 4 — Second community, full tab reimplementation: **HOA (Cedar Commons)**
Goal: prove the schema generalizes beyond Tabletop's three patterns (loan/giveaway marketplace, RSVP
calendar, dues payment) before building any automation or touching the Skill.

**Why HOA, not another option**: surveyed the other built-out community examples first (Mosque,
Book Club, Youth Soccer, Garden Club, Chess Club, Camera Club — via `docs/Build Plan V2/Phases/`,
`docs/Product Docs V2/Community Examples/`, and B14 evidence folders). Garden Club and Camera Club
are dominated by direct re-skins of the same loan/giveaway + RSVP patterns Tabletop already covers —
weak contrast. HOA's tab IA (Home, **Board**, **Documents**, Payments, **Requests**, Messages) is the
best genuine contrast: **Documents** is a wholly new card-surface family (library/permissioned
reading, nothing like it in Tabletop), and **Board** (architectural-request → committee-decision) is
a multi-step approval/case-task workflow — the "approval/review" family the schema hasn't been
proven against yet. Only HOA's Payments tab overlaps with what Marketplace/Giving already proved.
Mosque is a strong runner-up (Care/protected-vault and Admin/announcements+volunteer-signup are
equally novel) if HOA surfaces a blocking issue.
- Reimplement HOA's Board, Documents, and Requests tabs (the genuinely new surface families) plus
  Payments (reusing Phase 3's `payment` family) on the new engine, matching HOA's existing
  customizations/UI as the acceptance bar — this is a **reimplementation with parity**, not a
  redesign.
- **Evidence bar**: live parity walk across all reimplemented HOA tabs; validator green on HOA's new
  fixtures; full suite green; and explicitly — a written note on what, if anything, the schema had to
  be *changed* to support (new guard/effect ops, a new `cardSurfaceFamily` concept, anything
  `instanceDataSchema` couldn't express cleanly). If nothing needed to change, that's the strongest
  possible signal the schema is genuinely general, and worth stating plainly.

### Phase 5 — Automated/semi-automated migration of remaining communities
Only starts once Phase 4 proves generality (with real HOA output as the second data point, not just
Tabletop as a single example). Targets: Mosque, Book Club, Youth Soccer, Garden Club, Chess Club,
Camera Club, and any others with real fixture data. **Not designed in detail here** — do a fresh
planning pass once Phase 4's actual findings (what needed to change, if anything) are in hand, since
those findings directly determine how much of this can be mechanical (fixture JSON transformation)
versus needing per-community judgment calls.

### Phase 6 — Update the Skill
Only after Phase 5. Make `.agents/skills/using-loom-to-build-an-extension/SKILL.md` require this
schema as the primary workflow-authoring mechanism: add the §9c validator as a required gate
(alongside the existing judge tools), update the card-surface component docs
(`components/card-surfaces/*.md`) to reference `instanceDataSchema`-driven rendering instead of
prose-only anatomy descriptions, and update the relevant SKILL.md operating rules (15, 16, etc.) to
point at schema declaration instead of bespoke per-workflow UI authoring. Not designed in detail
here — revisit once Phases 1-5's actual shape (not just this plan's guess at it) is known.

## 8. Explicitly out of scope for now
- Any change to Calendar or Marketplace before AppShell V2's current tracker closes both phases —
  Phase 1 above supersedes that interim fix rather than building on top of it, but only starts after.
- Phase 5 (other communities) and Phase 6 (Skill changes) — deliberately not designed in detail yet;
  each needs its own fresh planning pass once the phase before it is actually done, not guessed at
  now.
- A real backend / HTTP implementation of `WorkflowEngineApi` — `LocalWorkflowEngineApi` is the only
  implementation needed for the demo app throughout Phases 1-5.

## 9. Skill integration (design, brainstormed 2026-07-04)

The point of this whole engine, from the Skill's perspective
(`.agents/skills/using-loom-to-build-an-extension/SKILL.md`): a workflow becomes something the Skill
**declares** (JSON, mechanically validated) rather than something an LLM hand-writes UI/button code
for per extension. This section is the design for that; not started, same gating as the rest of this
doc.

### 9a. The schema needs two layers, not just the state machine

Layer 1 is the state machine already designed in §3 (`states`/`transitions`/`guard`/`effects`).
Layer 2 is new — **display metadata** — because it's what lets UI actually be generated rather than
hand-written:

```json
"instanceDataSchema": {
  "holderPersonaId": { "type": "personaId?", "displayIcon": "person_outline", "labelTemplate": "Holder: {value}" },
  "queuedPersonaIds": { "type": "personaId[]", "displayIcon": "groups_outlined", "labelTemplate": "Queue: {value.length}" }
}
```

A generic fact-pill renderer walks this schema + current `instanceData` and picks the right
icon/label every time, for any workflow type — this is the direct fix for the Calendar bug (every
fact pill hardcoding the same checkmark icon) generalized into the schema itself, so no call site can
regress it again.

### 9b. Cross-workflow dependencies get a real field

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
makes dependency declarations drive rendering, not just gate an API call.

### 9c. Validator — a new required Skill gate, same shape as the existing judges

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

### 9d. Rendering layer — shared interactive primitives + a small per-family layout template

Today every card-surface family (`_ListingDetailView`, `_GivingTabSurface`, `_CalendarEventDetail`)
independently re-implements "render fact pills" and "render action buttons." Instead:

- **Generic, shared widgets** (built once, in the engine package): `WorkflowActionButtonRow` (takes
  `availableTransitions(...)`'s output, renders available/waiting/hidden per §9b) and
  `WorkflowFactPillRow` (takes `instanceData` + `instanceDataSchema`, renders icon+label per §9a) — usable
  by any `workflowType`.
- **A small per-`cardSurfaceFamily` layout template** — declarative arrangement (header, then
  fact-pill row, then action-button row, then linked-workflow completion state), differing only in
  chrome between families, not in the interactive logic underneath.
- **What the Skill/LLM still authors**: the workflow JSON (validated per §9c), which
  `cardSurfaceFamily` template to use (already an existing Skill decision — SKILL.md rule 15), and
  domain copy. What it stops hand-writing: per-workflow icon choices, button enable/waiting/hidden
  logic, or bespoke button-wiring code.

### 9e. What this changes about B25

B25's visual/domain judgment (does the copy sound right, does the layout feel modern) still matters
and isn't replaced. But a whole class of bugs B25 currently only catches via a full emulator
screenshot pass (stuck states, missing icons, wrong-persona-sees-wrong-button) becomes structurally
impossible before a screenshot is ever taken, once buttons/fact-pills are mechanically generated from
a schema that already passed §9c's validator.

### 9f. Living example

A fully worked example — the tabletop marketplace's loan/giveaway workflows expressed in this schema,
covering both the workflow *type* definition and multiple listing *instances* (the tile-grid data) —
is kept as a standalone, iterating file:
[`Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc`](./Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc).
Treat it as a living design artifact, not a final spec — comment on it directly, it's expected to
change as the schema is refined.
