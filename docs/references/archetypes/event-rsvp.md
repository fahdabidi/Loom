---
spec: 4
doc_version: 1.1.0
status: proposed
last_verified: 2026-08-14
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/permissions.md
  - app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart
---

# `event-rsvp`

An event people respond to: going, maybe, not going, or waiting for a place.

**The most used archetype in the corpus** — 8 of 11 communities. Also the one carrying the most
hand-written duplication, which is why its bookkeeping clause matters more than any other.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. Actions

Eleven. Permission ids are `event_rsvp.<action>`.

| Group | Actions |
|---|---|
| Authoring | `create` · `edit` · `cancel` · `reopen` |
| Responding | `respond` · `withdraw_response` · `join_waitlist` |
| Personal | `set_reminder` |
| Suggesting | `propose_change` |
| Recording | `record_outcome` |
| Reading | `view` |

**`propose_change` exists because `suggest-new-time` is offered to members who cannot `edit`.** Mapping
it to `edit` would grant every suggester the power to actually move the event — a real privilege
escalation hidden inside a naming decision.

**`cancel` and `withdraw_response` read alike and are opposites.** `cancel-tournament` calls the event
off for everyone; `cancel-rsvp` withdraws one person's attendance. Getting these backwards grants a
member the power to cancel the event.

## 2. Responses are rows, not arrays

**The response-row shape is canonical.** An event's responses live in a separate workflow named by the
event binding's `responseTable.workflowType`, one instance per member per event, whose **state is the
answer**: `pending`, `going`, `maybe`, `declined`, `waitlisted`.

```jsonc
"responseTable": { "workflowType": "garden-event-rsvp-response",
                   "eventField": "eventId", "pendingStates": ["pending"] }
```

A `respond` transition moves that row between response states. **Exclusivity is inherent** — a row has
exactly one state, so a member cannot be counted in two sets by construction.

### Why this replaced the array shape

An earlier draft of this contract listed five per-person arrays (`goingFanIds`, `maybeFanIds`,
`notGoingFanIds`, `waitlistFanIds`, `reminderFanIds`) as archetype-owned, and justified it by claiming
nothing enforced exclusivity. **Measuring the corpus disproved that claim**, and it is corrected here
rather than quietly dropped:

| Shape | Communities | Exclusivity |
|---|---|---|
| Response rows | Camera Club, Chess Club, Garden Club, Book Club, Tabletop, Riverside | inherent |
| Arrays | Masjid Nur | correct, hand-written — 4 effects per transition |
| Arrays | Tabletop `tournament-event` | **genuinely missing** |

So the defect was one workflow in one community, not a systemic flaw.

The real problem with arrays is different and fatal to archetype ownership: **`respond` maps to three
different arrays depending on the transition** (`rsvp-going` → `goingPersonaIds`, `rsvp-maybe` →
`maybePersonaIds`, and so on). The archetype cannot tell which set to fill from the action alone, so
"the archetype owns the response sets" is not implementable in that shape. Rows remove the ambiguity
instead of encoding it, and make Tabletop's missing-exclusivity bug unrepresentable.

### What the archetype owns

| Owned | Meaning |
|---|---|
| the response row's lifecycle | one row per member per event, materialized in `pending` (§4) |
| response state transitions | `respond` and `join_waitlist` move the row; a row has one state |
| `reminderFanIds` | `set_reminder`, on the event — genuinely a set, and unambiguous |

Counts, capacity remaining and "is full" **derive** from the rows. A community never stores them: a
stored count and the rows it summarises will drift.

## 3. Visibility

Model: **`roles` + `owner`**. An event is readable by the roles its state admits, plus its creator.

Corpus split: 5 `membersOnly`, 4 `public`, 2 `guarded` — the widest spread of any archetype, which fits.
A public community calendar and a board-only facility reservation are both `event-rsvp`.

## 4. Response rows

Per-member responses live in a separate workflow named by
`renderBindings[].responseTable.workflowType`. That workflow inherits this archetype
(`permissions.md` §6 step 3b) even though it declares no bindings of its own.

**This shape is required, not optional** — see §2. Six of eight communities already use it. It also
carries what arrays never could: a row can hold a dietary note or a comment alongside the response,
because it is a row rather than a membership flag.

> Before step 3b existed, those workflows had no archetype and derived **no permission at all** —
> 26 transitions across 5 communities, including `respond-going`, the single most common member action
> in the product.

### Who creates a row

**The engine does, not the community.** A row is materialized in `pending` the first time a member
applies a response transition to an event they have no row for. Nothing in community JSON declares it.

This is the only reading consistent with the corpus: all six communities declare `from: ["pending"]` on
their respond transitions, which is dead unless a row can exist in `pending` before its member has
answered. Materializing at *view* time would satisfy that too, but it writes on read — one row per
member per event opened — so the write is deferred to the first transition that actually needs it.

Because the creation path is archetype-owned rather than community-declared, `no_creation_path_for_editable_type`
must not fire on a workflow reached through `responseTable.workflowType`. All six response tables trip
it today; that is a validator gap, not six authoring bugs.

### Where `withdraw_response` lands

**`pending`.** It is the only target that makes the action mean anything.

Riverside is the corpus's one implementation, and it routes to `declined`:

```
respond-declined   pending|going|maybe|waitlisted -> declined
cancel-rsvp              going|maybe|waitlisted   -> declined
```

`cancel-rsvp`'s sources are a strict subset of `respond-declined`'s and its target is identical — it is a
relabelled duplicate that adds no reachable state. Routing withdrawal to `pending` restores the
distinction the action names: `declined` is an answer ("not coming"), `pending` is the absence of one
("never mind"). It also keeps the two separable downstream, since reminder sweeps target `pending` and
should not re-nudge someone who affirmatively declined.

This makes `pending` the sole state that is both initial and a transition target.

## 5. Worked example — Garden Club

It takes **two** workflow definitions. The event holds authoring and lifecycle; the response table holds
per-member answers. Showing only the first is what produced the array shape §2 replaced.

**The event:**

```jsonc
"garden-event-rsvp": {
  "states": {
    "open":      { "label": "Open" },
    "cancelled": { "label": "Cancelled", "isTerminal": true }
  },
  "visibility": { "default": "membersOnly" },

  "renderBindings": [
    { "responseTable": { "workflowType": "garden-event-rsvp-response",
                         "eventField": "eventId", "pendingStates": ["pending"] } }
  ],

  "transitions": [
    { "id": "publish-event",  "action": "create", "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-coordinator"] } },
    { "id": "make-recurring", "action": "edit",   "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-coordinator"] } },
    { "id": "add-reminder",   "action": "set_reminder", "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-member"] } },

    // Cancelling must sweep the rows, or they stay live and keep accepting
    // responses -- a row cannot see its parent's state. One effect per source
    // state, because a filter matches one state at a time.
    { "id": "cancel-event", "action": "cancel", "from": ["open"], "to": "cancelled",
      "tone": "destructive",
      "guard": { "allowedRoleIds": ["garden-coordinator"] },
      "effects": [
        { "op": "transitionRelated", "transitionId": "event-cancelled",
          "relatedQuery": { "workflowType": "garden-event-rsvp-response",
                            "filter": { "eventId": "{id}", "$state": "going" } } },
        { "op": "transitionRelated", "transitionId": "event-cancelled",
          "relatedQuery": { "workflowType": "garden-event-rsvp-response",
                            "filter": { "eventId": "{id}", "$state": "maybe" } } },
        { "op": "transitionRelated", "transitionId": "event-cancelled",
          "relatedQuery": { "workflowType": "garden-event-rsvp-response",
                            "filter": { "eventId": "{id}", "$state": "waitlisted" } } }
      ] }
  ]
}
```

**The response table** — declares no bindings, and inherits `event_rsvp` via `permissions.md` §6 step 3b:

```jsonc
"garden-event-rsvp-response": {
  "states": {
    "pending":    { "label": "No response" },   // initial; engine-materialized (§4)
    "going":      { "label": "Going" },
    "maybe":      { "label": "Maybe" },
    "declined":   { "label": "Not going" },
    "waitlisted": { "label": "Waitlisted" },
    "cancelled":  { "label": "Event cancelled", "isTerminal": true }
  },
  "visibility": { "default": "membersOnly" },

  "transitions": [
    { "id": "respond-going",    "action": "respond",
      "from": ["pending", "maybe", "declined", "waitlisted"], "to": "going",
      "guard": { "allowedRoleIds": ["garden-member"] } },
    { "id": "respond-maybe",    "action": "respond",
      "from": ["pending", "going", "declined", "waitlisted"], "to": "maybe",
      "guard": { "allowedRoleIds": ["garden-member"] } },
    { "id": "respond-declined", "action": "respond",
      "from": ["pending", "going", "maybe", "waitlisted"], "to": "declined",
      "guard": { "allowedRoleIds": ["garden-member"] } },
    { "id": "respond-waitlist", "action": "join_waitlist",
      "from": ["pending", "maybe", "declined"], "to": "waitlisted",
      "guard": { "allowedRoleIds": ["garden-member"] } },

    // Withdrawal returns the row to "no answer" -- not to `declined`, which
    // would make it a duplicate of respond-declined. See §4.
    { "id": "withdraw-rsvp", "action": "withdraw_response",
      "from": ["going", "maybe", "waitlisted"], "to": "pending",
      "guard": { "allowedRoleIds": ["garden-member"] } },

    // Target of the parent's cascade. Not member-invokable.
    { "id": "event-cancelled", "action": "cancel",
      "from": ["pending", "going", "maybe", "waitlisted"], "to": "cancelled",
      "guard": { "allowedRoleIds": ["garden-coordinator"] } }
  ]
}
```

| Role | Permissions |
|---|---|
| `garden-coordinator` | `event_rsvp.create`, `.edit`, `.cancel` |
| `garden-member` | `event_rsvp.respond`, `.join_waitlist`, `.withdraw_response`, `.set_reminder` |

Both workflows derive `event_rsvp.*` — that is the point of step 3b, and why `respond-going` carries a
permission at all.

`respond-waitlist` is `join_waitlist`, **not** `respond` — it is the overflow path, offered only when the
event is full, and it is a distinct capability a community may withhold.

Counts come from the rows, never from a stored field: `groupCount(responses, '$state')` tallies by real
workflow state ([`formulas.md`](../reference/formulas.md)).

## 6. Community-defined actions

Permitted. Nothing in the corpus currently needs one — all 8 communities' `event-rsvp` transitions map to
the vocabulary — which is unusual and reflects how well-explored this archetype is.

## 7. Open

- **Capacity enforcement.** Communities express it as a `relatedAggregate` guard today. Whether the
  archetype should own "cannot go over capacity" is undecided; it is arguably as much a correctness
  property as response exclusivity.
- **The calendar surface.** `event-rsvp` is what renders on a calendar-shaped tab, and that surface
  carries behaviour keyed on the literal tab name `calendar`. That coupling is residue from before
  generic tabIds and is not part of this contract.
