---
spec: 4
doc_version: 1.0.0
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

## 2. Bookkeeping the archetype owns

| Field | Maintained by |
|---|---|
| `goingFanIds` | `respond` |
| `maybeFanIds` | `respond` |
| `notGoingFanIds` | `respond` |
| `waitlistFanIds` | `join_waitlist` |
| `reminderFanIds` | `set_reminder` |

**`respond` moves a person between the three response sets atomically.** That is a correctness
property, not a convenience: today each community writes three separate transitions, each with its own
`actorInList` guard, and nothing enforces that a person appears in exactly one set. A member who
responds "going" then "maybe" can end up counted twice, inflating capacity and starving the waitlist.

Counts, capacity remaining, and "is full" derive from these. A community never stores them — a stored
count and its underlying list *will* drift.

## 3. Visibility

Model: **`roles` + `owner`**. An event is readable by the roles its state admits, plus its creator.

Corpus split: 5 `membersOnly`, 4 `public`, 2 `guarded` — the widest spread of any archetype, which fits.
A public community calendar and a board-only facility reservation are both `event-rsvp`.

## 4. Response rows

A community may hold per-member responses in a separate workflow named by
`renderBindings[].responseTable.workflowType`. That workflow inherits this archetype
(`permissions.md` §6 step 3b) even though it declares no bindings of its own.

Five communities use this shape. **Under this contract it becomes optional**, because the archetype now
owns the bookkeeping the response table existed to hold. It remains supported: a community that wants
one row per member per event — to carry a dietary note or a comment alongside the response — still
declares one.

> Before step 3b existed, those workflows had no archetype and derived **no permission at all** —
> 26 transitions across 5 communities, including `respond-going`, the single most common member action
> in the product.

## 5. Worked example — Garden Club

```jsonc
"garden-event-rsvp": {
  "states": {
    "open":      { "label": "Open" },
    "cancelled": { "label": "Cancelled", "isTerminal": true }
  },
  "visibility": { "default": "membersOnly" },

  "transitions": [
    { "id": "publish-event",  "action": "create", "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-coordinator"] } },
    { "id": "make-recurring", "action": "edit",   "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-coordinator"] } },
    { "id": "cancel-event",   "action": "cancel", "from": ["open"], "to": "cancelled",
      "tone": "destructive",
      "guard": { "allowedRoleIds": ["garden-coordinator"] } },

    // Members respond. No actorInList guards, no response arrays declared:
    // `respond` is once-per-person and mutually exclusive by definition.
    { "id": "respond-going",    "action": "respond",       "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-member"] } },
    { "id": "respond-declined", "action": "respond",       "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-member"] } },
    { "id": "respond-waitlist", "action": "join_waitlist", "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-member"] } },
    { "id": "add-reminder",     "action": "set_reminder",  "from": ["open"], "to": null,
      "guard": { "allowedRoleIds": ["garden-member"] } }
  ]
}
```

| Role | Permissions |
|---|---|
| `garden-coordinator` | `event_rsvp.create`, `.edit`, `.cancel` |
| `garden-member` | `event_rsvp.respond`, `.join_waitlist`, `.set_reminder` |

`respond-waitlist` is `join_waitlist`, **not** `respond` — it is the overflow path, offered only when the
event is full, and it is a distinct capability a community may withhold.

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
