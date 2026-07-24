---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.2.0
status: current
last_verified: 2026-07-24
audience: llm-agent
derived_from:
  - app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
---

# Guards (normative) — grammar v1

A guard decides **who may fire a transition, and when**.

**Enforcement:** the engine evaluates guards inside `applyTransition`. A failing guard makes the
transition **genuinely refuse** (throw). It is not a UI hint. The UI additionally uses
`availableTransitionsAsync` to hide unavailable buttons, but the *security property* lives in the engine.

**Semantics:** all present guard keys are **AND**-ed. An absent/empty guard means "anyone, always".

⚠️ **One documented exception, at one specific call site.** `states[].editGuard` (workflow-grammar.md,
PROPOSED) reuses this exact `WorkflowGuard` type, but the App Shell's edit-rendering check treats an
*absent* `editGuard` as "no editing exposed," not "anyone, always" — see workflow-grammar.md's `states`
section for why. Every other use of `WorkflowGuard` in this doc keeps the normal open-by-default
semantics; this is a property of that one call site, not a change to the guard type itself.

**Complete list: seven kinds. No others exist.**

⚠️ **`relatedAggregate` (kind 6) is PROPOSED grammar, not yet engine-implemented** — written and
validator-speced ahead of the code that executes it, same convention the frozen Tabletop Club JSON
itself uses elsewhere ("written before the code that loads it"). The other six kinds are real today.

---

## 1. `allowedPersonaIds` — persona allowlist

```jsonc
"guard": { "allowedPersonaIds": ["tabletop-organizer"] }
```

| Field | Type | Meaning |
|---|---|---|
| `allowedPersonaIds` | string[] | The actor's `personaId` must be in this list |

Every id MUST be a declared persona. → else `dangling_allowed_persona_id` (warning)

**Use for:** "only organizers can cancel", "only members can RSVP".

---

## 2. `actorInList` — is the actor in (or not in) a list field?

```jsonc
"guard": { "actorInList": { "key": "goingPersonaIds", "present": false } }
```

| Field | Type | Meaning |
|---|---|---|
| `key` | string | A list-valued field on **this** instance. MUST be declared. |
| `present` | bool | `true` = actor MUST be in the list · `false` = actor MUST NOT be |

**Use for:** the classic paired transitions — show *Join queue* only to those not queued, and *Leave
queue* only to those who are.

```jsonc
// Join: only if NOT already queued
{ "id": "join-queue",  "guard": { "actorInList": { "key": "queuedPersonaIds", "present": false } },
  "effects": [ { "op": "appendUnique", "key": "queuedPersonaIds", "value": "$actor" } ] }

// Leave: only if already queued
{ "id": "leave-queue", "guard": { "actorInList": { "key": "queuedPersonaIds", "present": true } },
  "effects": [ { "op": "removeValue", "key": "queuedPersonaIds", "value": "$actor" } ] }
```

---

## 3. `instanceDataEquals` — field equals a value

```jsonc
"guard": { "instanceDataEquals": { "key": "availabilityState", "value": "available" } }
```

| Field | Type | Meaning |
|---|---|---|
| `key` | string | A field on this instance. MUST be declared. |
| `value` | any | Must equal this exactly |

**Use for:** gating on **orthogonal data** that is not a top-level state — the correct way to express
"only if the item is available" when availability is data, not a state.

---

## 4. `formula` — any computed boolean condition

```jsonc
"guard": { "formula": "size(goingPersonaIds) < capacity" }
```

| Field | Type | Meaning |
|---|---|---|
| `formula` | string | An expression over **this** workflow's fields. Must evaluate `true`. |

Full vocabulary: [`formulas.md`](./formulas.md). Every referenced field MUST be declared in this
workflow's `instanceDataSchema`. → else `unknown_formula_field` (error)

**Use for:** capacity, quorum, thresholds, deadlines — anything arithmetic or comparative.

```jsonc
// Going: only while seats remain
{ "id": "rsvp-going",    "guard": { "formula": "size(goingPersonaIds) < capacity" } }
// Waitlist: only once genuinely full
{ "id": "join-waitlist", "guard": { "formula": "size(goingPersonaIds) >= capacity" } }
```

**This is the correct alternative to storing a stale `isFull` flag.** The condition is evaluated against
live data every time.

---

## 5. `relatedListMembership` — cross-instance membership (the eligibility guard)

**"The actor must appear in `<field>` on a *different* instance."**

```jsonc
"guard": {
  "relatedInstanceField": "eventId",        // a field on THIS instance holding a target instanceId
  "relatedListField": "goingPersonaIds"     // a list field on THAT instance
}
```

⚠️ **Note the flat shape.** Unlike the others, this guard is declared as **two sibling keys**, not a
nested object. (`WorkflowGuard.fromJson` detects it by the presence of `relatedInstanceField`.)

| Field | Type | Meaning |
|---|---|---|
| `relatedInstanceField` | string | Field on **this** instance whose value is the **target instanceId**. MUST be declared here. |
| `relatedListField` | string | List field on the **target** instance. Must be declared **there**. |

**Evaluation:** the engine reads `instanceData[relatedInstanceField]` → loads that instance → checks the
actor is in its `relatedListField`. A genuine cross-instance database read, re-evaluated live (not
snapshotted at creation).

**Use for:** "only people who RSVP'd going to the tournament may vote in its ballot."

```jsonc
// On tournament-ballot:
"guard": { "relatedInstanceField": "eventId", "relatedListField": "goingPersonaIds" }
// Reads: ballot.instanceData.eventId -> that event instance -> is $actor in its goingPersonaIds?
```

**Validation:** `relatedInstanceField` must be declared here (checked at definition level);
`relatedListField` must exist on the target (checked at **instance** level, because the target's type is
only knowable from instance data).

---

## 6. `relatedAggregate` — a live count/sum/etc. over a related table, compared to a threshold

**"Count (or sum) the rows of another workflow type matching a filter, and compare the result."**
This is the row-per-user-table analog of `formula`'s capacity check — for data that lives in a
separate, per-row table (GAP-4 pattern: `tournament-vote`, `event-rsvp-response`) rather than a list
field on this instance.

```jsonc
"guard": {
  "relatedAggregate": {
    "workflowType": "event-rsvp-response",
    "filter": { "eventId": "{eventId}", "$state": "going" },
    "op": "count",
    "comparator": "<",
    "compareTo": { "relatedInstanceField": "eventId", "field": "capacity" }
  }
}
```

| Field | Type | Meaning |
|---|---|---|
| `workflowType` | string | The related table's workflow type. MUST be declared. |
| `filter` | object | Field → value map, matched against each candidate row. Values may be `{fieldName}` (interpolated against **this** instance), a literal, or the reserved key `$state` naming the row's own current FSM state (not an `instanceData` field — see [`formulas.md`](./formulas.md)'s `$state` note). |
| `op` | string | `count` \| `sum` \| `avg` \| `min` \| `max` \| `countDistinct` — same vocabulary as `aggregate()`. |
| `comparator` | string | `<` `<=` `>` `>=` `==` `!=` |
| `compareTo` | number \| object | Either a literal threshold, or `{ "relatedInstanceField": "<field on this instance>", "field": "<field on that related instance>" }` — read a threshold off a *different* related instance, same cross-instance-lookup shape as `relatedListMembership` below. |

**Evaluation:** the engine computes this aggregate **fresh**, via the same real `aggregate()` method a
direct API caller would use — not a cached or stale value. Because `evaluateGuard` itself stays
synchronous (by design — see [`formulas.md`](./formulas.md) on why formulas never touch the database),
the caller (`applyTransition`/`availableTransitionsAsync`, both already `async`) computes this value
**before** the synchronous guard check runs, the same pattern already used for
`requiresWorkflowsComplete`'s `completedWorkflowIds`.

**Use for:** a capacity/quorum/threshold check where the thing being counted lives in a separate
per-row table, not a list field on this instance — e.g. "no more than `capacity` rows may reach
`going`" when going/maybe/declined/waitlisted are real per-member rows, not a `personaId[]` list.

```jsonc
// On event-rsvp-response's respond-going transition:
"guard": {
  "allowedPersonaIds": ["tabletop-member", "tabletop-organizer"],
  "relatedAggregate": {
    "workflowType": "event-rsvp-response",
    "filter": { "eventId": "{eventId}", "$state": "going" },
    "op": "count", "comparator": "<",
    "compareTo": { "relatedInstanceField": "eventId", "field": "capacity" }
  }
}
// Reads: count event-rsvp-response rows sharing my own eventId with $state=='going'; that count must
// be less than the `capacity` field on the event-rsvp instance named by my own eventId.
```

**Validation:** `workflowType` must be declared; every `filter` key (other than the reserved `$state`)
must be declared on that target type; `compareTo.relatedInstanceField` must be declared **here**;
`compareTo.field` must be declared on the type named by `compareTo.relatedInstanceField`'s value
(checked at instance level, like `relatedListMembership`).

---

## 7. `requiresWorkflowsComplete` — cross-workflow prerequisite

**"The actor must have completed a different workflow."**

```jsonc
"guard": { "requiresWorkflowsComplete": ["tabletop-club-dues-payment"] }
```

| Field | Type | Meaning |
|---|---|---|
| `requiresWorkflowsComplete` | string[] | workflowTypes the actor must have brought to a **terminal** state |

Each MUST be a declared workflowType. → else `dangling_requires_workflows_complete` (error)
A cycle across workflows is an error. → `dependency_cycle`

**Use for:** "you cannot borrow from the library until your dues are paid."

---

## Combining guards (AND)

```jsonc
"guard": {
  "allowedPersonaIds": ["tabletop-member"],
  "instanceDataEquals": { "key": "availabilityState", "value": "available" },
  "requiresWorkflowsComplete": ["tabletop-club-dues-payment"]
}
```
Reads: *a member* AND *the item is available* AND *their dues are paid*.

**There is no OR.** To express alternatives, write **two transitions** with different guards. This is
usually clearer anyway — they typically want different labels ("Borrow" vs "Join queue").

---

## Selection table

| Requirement | Guard |
|---|---|
| Only role X | `allowedPersonaIds` |
| Only if actor is/isn't already in a list | `actorInList` |
| Only if a data field equals a value | `instanceDataEquals` |
| Only if a computed/arithmetic condition holds | `formula` |
| Only if actor is on a list belonging to **another** instance | `relatedListMembership` |
| Only if a live count/sum over a **related table** clears a threshold | `relatedAggregate` |
| Only if actor finished **another workflow** | `requiresWorkflowsComplete` |

## Anti-patterns

| ❌ Wrong | ✅ Right |
|---|---|
| Relying on the UI to hide a button for security | Declare the guard; the engine refuses |
| Storing `isFull: true` as effect-written data and guarding on it | `formula` guard over live data |
| A `pending`/`eligible` **state** to represent per-member eligibility | `actorInList` / `relatedListMembership` on **data** — many members can differ simultaneously |
| Duplicating a workflow to express two permission levels | One workflow; guard-filter the transitions |
