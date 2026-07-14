---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
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

**Complete list: six kinds. No others exist.**

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

## 6. `requiresWorkflowsComplete` — cross-workflow prerequisite

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
| Only if actor finished **another workflow** | `requiresWorkflowsComplete` |

## Anti-patterns

| ❌ Wrong | ✅ Right |
|---|---|
| Relying on the UI to hide a button for security | Declare the guard; the engine refuses |
| Storing `isFull: true` as effect-written data and guarding on it | `formula` guard over live data |
| A `pending`/`eligible` **state** to represent per-member eligibility | `actorInList` / `relatedListMembership` on **data** — many members can differ simultaneously |
| Duplicating a workflow to express two permission levels | One workflow; guard-filter the transitions |
