---
spec: 4
doc_version: 1.9.0
status: current
last_verified: 2026-08-09
audience: llm-agent
derived_from:
  - app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
---

# Guards (normative) — specVersion 4

A guard decides **who may fire a transition, and when**.

**Enforcement:** the engine evaluates guards inside `applyTransition`. A failing guard makes the
transition **genuinely refuse** (throw). It is not a UI hint. The UI additionally uses
`availableTransitionsAsync` to hide unavailable buttons, but the *security property* lives in the engine.

**Semantics:** all present guard keys are **AND**-ed. An absent/empty guard means "anyone, always".

⚠️ **One documented exception, at one specific call site.** `states[].editGuard` (workflow-grammar.md,
IMPLEMENTED 2026-07-25 — CALR.10a) reuses this exact `WorkflowGuard` type, but the App Shell's
edit-rendering check treats an *absent* `editGuard` as "no editing exposed," not "anyone, always" — see
workflow-grammar.md's `states` section for why. Every other use of `WorkflowGuard` in this doc keeps the
normal open-by-default semantics; this is a property of that one call site, not a change to the guard
type itself.

**Complete list: ten kinds, all ten implemented and engine-executed today.** Confirmed via
`guard_evaluator.dart`/`local_workflow_engine_api.dart` and proven live throughout Tabletop Club's
capacity/waitlist guards (`event-rsvp-response`) and, as of CAL.Calendar2/CAL.Notify, its cancellation
deadlines, location-overlap protection, and recipient-gated notifications too. See each section's own
status callout, and `spec-version.json` for the individual implementation dates/commits.

⚠️ **Guards also now have a second usage site beyond transitions.** `states[].creationGuard`
(workflow-grammar.md, PROPOSED — CAL.Calendar2.0) reuses this exact `WorkflowGuard` type to gate
**instance creation itself**, not just transitions — see workflow-grammar.md's `states` section for why
this was needed (today, `createInstance`/`createInstances` run zero guard checks of any kind) and how its
default-when-absent semantics deliberately differ from `editGuard`'s.

---

## 1. `allowedRoleIds` — role allowlist

> **specVersion 4 rename.** This key is `allowedRoleIds` in v1 and `allowedRoleIds` in v2. It was always
> role-based; the rename makes it say so. See [`identity-types.md`](./identity-types.md).

```jsonc
"guard": { "allowedRoleIds": ["tabletop-organizer"] }
```

| Field | Type | Meaning |
|---|---|---|
| `allowedRoleIds` | `roleId[]` | The actor must hold one of these roles |

Every id MUST be a declared role. → else `dangling_allowed_role_id` (error in v2)

**Use for:** "only organizers can cancel", "only members can RSVP".

**This is the role layer, and it is the only identity check that can be pre-granted as a permission.**
Questions about *which specific person* — the recipient, the current holder, the queue member — belong to
`actorEqualsField` / `actorInList` below, which resolve per instance at runtime and are checked against
`fanId` fields. See [`permissions.md`](./permissions.md) §2.

**Also drives `audience: "receiver"` resolution.** A `renderBindings` entry with `audience: "receiver"`
(v1: `audience: "receiver"`) resolves to whichever roles pass at least one available transition's guard — an
`allowedRoleIds` guard here is usually what makes that resolution meaningful/narrow, rather than "every
role." See
[`render-bindings.md`'s role resolution section](./render-bindings.md#role-actorreceiver-resolution--general-guard-derived-tab-agnostic).

---

## 2. `actorInList` — is the actor in (or not in) a list field?

```jsonc
"guard": { "actorInList": { "key": "goingFanIds", "present": false } }
```

| Field | Type | Meaning |
|---|---|---|
| `key` | string | A list-valued field on **this** instance, **typed `fanId[]`** in specVersion 4. MUST be declared. |
| `present` | bool | `true` = actor MUST be in the list · `false` = actor MUST NOT be |

**Use for:** the classic paired transitions — show *Join queue* only to those not queued, and *Leave
queue* only to those who are.

```jsonc
// Join: only if NOT already queued
{ "id": "join-queue",  "guard": { "actorInList": { "key": "queuedFanIds", "present": false } },
  "effects": [ { "op": "appendUnique", "key": "queuedFanIds", "value": "$actor" } ] }

// Leave: only if already queued
{ "id": "leave-queue", "guard": { "actorInList": { "key": "queuedFanIds", "present": true } },
  "effects": [ { "op": "removeValue", "key": "queuedFanIds", "value": "$actor" } ] }
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
"guard": { "formula": "size(goingFanIds) < capacity" }
```

| Field | Type | Meaning |
|---|---|---|
| `formula` | string | An expression over **this** workflow's fields. Must evaluate `true`. |

Full vocabulary: [`formulas.md`](./formulas.md). Every referenced field MUST be declared in this
workflow's `instanceDataSchema`. → else `unknown_formula_field` (error)

**Use for:** capacity, quorum, thresholds, deadlines — anything arithmetic or comparative.

```jsonc
// Going: only while seats remain
{ "id": "rsvp-going",    "guard": { "formula": "size(goingFanIds) < capacity" } }
// Waitlist: only once genuinely full
{ "id": "join-waitlist", "guard": { "formula": "size(goingFanIds) >= capacity" } }
```

**This is the correct alternative to storing a stale `isFull` flag.** The condition is evaluated against
live data every time.

---

## 5. `relatedListMembership` — cross-instance membership (the eligibility guard)

**"The actor must appear in `<field>` on a *different* instance."**

```jsonc
"guard": {
  "relatedInstanceField": "eventId",        // a field on THIS instance holding a target instanceId
  "relatedListField": "goingFanIds"     // a list field on THAT instance
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
"guard": { "relatedInstanceField": "eventId", "relatedListField": "goingFanIds" }
// Reads: ballot.instanceData.eventId -> that event instance -> is $actor in its goingFanIds?
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
| `field` | string | **Required whenever `op` is anything other than `count`.** Names the field on each matched row to aggregate over. PROPOSED 2026-07-25 (CAL.Calendar2.8) — see the correction note immediately below. |
| `comparator` | string | `<` `<=` `>` `>=` `==` `!=` |
| `compareTo` | number \| object | Either a literal threshold, or `{ "relatedInstanceField": "<field on this instance>", "field": "<field on that related instance>" }` — read a threshold off a *different* related instance, same cross-instance-lookup shape as `relatedListMembership` below. |

⚠️ **Correction, found 2026-07-25 (CAL.Calendar2 design pass): `sum`/`avg`/`min`/`max`/`countDistinct` do
NOT actually work today, despite being documented above as available.** `RelatedAggregateGuard`
(`workflow_models.dart`) has no field/column parameter at all, and its caller
(`_passesRelatedAggregateGuard`, `local_workflow_engine_api.dart`) hardcodes `column: ''` when calling the
real `aggregate()` method — which requires a genuine column for every op except `count`. Any community
JSON written today with `"op": "sum"` silently aggregates over an empty-string column and produces a
meaningless result; it does not error. **Only `op: "count"` is safe to use in a real fixture until the
`field` parameter above is engine-implemented** (PROPOSED, CAL.Calendar2.8 — not yet built).

**NEW 2026-07-26 (CAL.Calendar2.8, PROPOSED, engine not yet built): the frozen fixture's `respond-going`
transition now declares `"op": "sum", "field": "partySize"`** (party-size/plus-ones) — this is deliberately
INERT today, landing atomically alongside the `field`-parameter engine fix in the same implementation pass,
never shipped ahead of it. Do not treat its presence in the fixture as evidence the engine change has
landed; check `spec-version.json` → `relatedAggregateFieldParam` for the real implementation status.

**Evaluation:** the engine computes this aggregate **fresh**, via the same real `aggregate()` method a
direct API caller would use — not a cached or stale value. Because `evaluateGuard` itself stays
synchronous (by design — see [`formulas.md`](./formulas.md) on why formulas never touch the database),
the caller (`applyTransition`/`availableTransitionsAsync`, both already `async`) computes this value
**before** the synchronous guard check runs, the same pattern already used for
`requiresWorkflowsComplete`'s `completedWorkflowIds`.

**Use for:** a capacity/quorum/threshold check where the thing being counted lives in a separate
per-row table, not a list field on this instance — e.g. "no more than `capacity` rows may reach
`going`" when going/maybe/declined/waitlisted are real per-member rows, not a `fanId[]` list.

```jsonc
// On event-rsvp-response's respond-going transition:
"guard": {
  "allowedRoleIds": ["tabletop-member", "tabletop-organizer"],
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

⚠️ **This `filter` shape (field → literal / `{fieldName}` / reserved `$state`) is reused, not
reinvented, by `effects.md`'s `transitionRelated` op's `relatedQuery.filter`** (implemented 2026-07-25) —
the difference is that a guard only ever *counts* the matching rows, while `transitionRelated` *resolves
and transitions one of them*. See [`effects.md`](./effects.md) §11.

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

## 8. `cancellationDeadline` — a time-before-the-event cutoff

✅ **IMPLEMENTED 2026-07-26 (CAL.Calendar2.2, commit `062d0d5`)** — `CancellationDeadlineGuard`,
`guard_evaluator.dart`'s evaluation branch, and the injectable-clock support it needed all shipped and are
independently verified end-to-end.

**"The actor may only fire this transition while at least `hoursBefore` hours remain before a real
date+time on this instance."**

```jsonc
"guard": {
  "cancellationDeadline": { "dateField": "eventDate", "timeField": "eventTime", "hoursBefore": 24 }
}
```

| Field | Type | Meaning |
|---|---|---|
| `dateField` | string | A `date`-typed field on **this** instance. MUST be declared. |
| `timeField` | string \| null | A `time`-typed field on **this** instance, combined with `dateField` into one real timestamp. Optional — omit for an all-day event, in which case the deadline is computed from midnight of `dateField`. |
| `hoursBefore` | number | Must be positive. The guard passes while `now() <= combine(dateField, timeField) - hoursBefore hours`. |

**Why not a `formula` guard instead** (e.g. `isBefore(now(), subtractHours(eventDate, 24))`): `eventDate`
alone is a bare date string — `formula_evaluator.dart`'s `_date()` helper parses it as midnight, so a plain
formula guard referencing only `eventDate` would compute a cutoff up to 24 hours too generous for an
event that starts later in the day. This dedicated guard kind combines both fields correctly and is
validator-checkable (wrong field name/type is a static error, not a runtime `FormulaEvaluationException`).

**Use for:** "members can't back out within 24 hours of the event"; "can't join the waitlist same-day."

**Validation (once implemented):** `dateField` must be declared with `type: "date"`; `timeField`, if
present, must be declared with `type: "time"`; `hoursBefore` must be a positive number.

---

## 9. `locationOverlap` — prevent double-booking a shared resource

✅ **IMPLEMENTED 2026-07-26 (CAL.Calendar2.9, commit `6589a88`)** — a genuinely new capability, not a cheap
formula composition: `source_query.dart`'s `query(...)` grammar supports only a single equality condition
(no compound filters, no self-exclusion), so this needed a real async database scan
(`_passesLocationOverlapGuard`) with proper interval-overlap math, closer in shape to `effects.md`'s bespoke
`recurrence_evaluator.dart` arithmetic than a one-line addition.

**"No other instance of this same workflow type may share this instance's own `locationField` value with
an overlapping time range."** Unlike `relatedAggregate`, this does not name a separate related
`workflowType` — it always scans sibling instances of **this instance's own type**.

```jsonc
"guard": {
  "locationOverlap": {
    "locationField": "location",
    "dateField": "eventDate",
    "timeField": "eventTime",
    "durationMinutes": 120
  }
}
```

| Field | Type | Meaning |
|---|---|---|
| `locationField` | string | A field on **this** instance (and every sibling instance of the same type) whose value identifies the shared resource. MUST be declared. |
| `dateField` | string | A `date`-typed field, combined with `timeField` into this instance's own start timestamp. MUST be declared. |
| `timeField` | string \| null | A `time`-typed field. Optional, same all-day fallback as `cancellationDeadline`. |
| `durationMinutes` | number | This instance's assumed duration, used to compute its own `[start, start + durationMinutes)` range for the overlap check. Must be positive. |

**Evaluation:** fails if any other instance of the same workflow type has an equal `locationField` value
and a `[start, start + durationMinutes)` range that overlaps this instance's own. **This is a hard guard —
it blocks the mutation outright**, not a display-only warning.

**Use as a plain transition `guard`** (the shape shown above) — this is the real, working placement,
confirmed enforced by `_passesLocationOverlapGuard`. ⚠️ **Do not place this inside a `creationGuard`.**
`workflow-grammar.md` marks `creationGuard` **PROPOSED, not yet implemented** — `_createInstanceValidated`
runs zero guard checks today, so a `locationOverlap` guard placed there silently never runs, producing a
package that structurally implies double-booking protection while actually enforcing none. (Found
2026-08-09: exactly this mistake shipped in a real community fixture, because this section's own
`creationGuard` recommendation below doesn't repeat that caveat inline.) Once `creationGuard` ships for
real, placing `locationOverlap` there becomes the stronger option — it would also cover every sibling a
recurring series generates via the one shared choke point (`_createInstanceValidated`,
`generateRecurringInstances`'s per-occurrence creation included) — but until then, the transition-guard
placement above is the only one that actually blocks anything.

**Use for:** "Main Hall can't be double-booked for two overlapping game nights."

**Validation (once implemented):** `locationField`/`dateField` must be declared with the right types;
`timeField`, if present, must be `type: "time"`; `durationMinutes` must be a positive number.

---

## 10. `actorEqualsField` — the actor must be the persona named on this instance

✅ **IMPLEMENTED 2026-07-31 (CAL.Notify.1, commit `06f53ed`; validator rules CAL.Notify.2, commit
`572b8f6`)** — found while designing a `notification` workflow type: `instanceDataEquals` only compares a
field to a fixed literal, and `actorInList` only checks membership in a **list**-valued field — neither can
express "the actor must equal this single scalar field's own value," a genuinely common shape ("only the
recipient can dismiss their own notification," "only the assigned reviewer may approve"). Now live in the
frozen fixture, gating `notification`'s own `mark-read` transition (CAL.Notify.3).

```jsonc
"guard": { "actorEqualsField": { "key": "recipientFanId" } }
```

| Field | Type | Meaning |
|---|---|---|
| `key` | string | A scalar (non-list) field on **this** instance, **typed `fanId`** in specVersion 4. MUST be declared. The guard passes only if `$actor == instanceData[key]`. |

> **specVersion 4:** the field named here must be typed `fanId` (or `fanId?`), because `$actor` is a
> `fanId`. Pointing it at a `roleId` field is an error — that comparison is the pre-v3 defect that made
> per-individual guards silently unsatisfiable. See [`identity-types.md`](./identity-types.md).

**Use for:** "only the recipient may mark their own notification read" — the alternative (relying on the
UI to only ever *show* a viewer their own notifications) is a UI convention, not engine enforcement; a
direct API call would bypass it, the same category of gap `editGuard`'s original App-Shell-only
enforcement had (see `spec-version.json` → `editGuardEngineEnforcement`).

**Also drives `audience: "actor"` resolution.** If any transition on a workflow declares `actorEqualsField`,
that field's value is who `audience: "actor"` on a `renderBindings` entry resolves to for that instance — not
just who this specific transition's guard gates. See
[`render-bindings.md`'s role resolution section](./render-bindings.md#role-actorreceiver-resolution--general-guard-derived-tab-agnostic).

```jsonc
// On notification's mark-read transition:
"guard": { "actorEqualsField": { "key": "recipientFanId" } }
```

**Validation (once implemented):** `key` must be declared on this workflow's own `instanceDataSchema`,
and must not be a list-typed field (use `actorInList` for that shape instead). → else
`dangling_actor_equals_field` / `actor_equals_field_on_list_type`.

---

## Combining guards (AND)

```jsonc
"guard": {
  "allowedRoleIds": ["tabletop-member"],
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
| Only role X | `allowedRoleIds` |
| Only if actor is/isn't already in a list | `actorInList` |
| Only if a data field equals a value | `instanceDataEquals` |
| Only if a computed/arithmetic condition holds | `formula` |
| Only if actor is on a list belonging to **another** instance | `relatedListMembership` |
| Only if a live count/sum over a **related table** clears a threshold | `relatedAggregate` |
| Only if actor finished **another workflow** | `requiresWorkflowsComplete` |
| Only while a real deadline hasn't passed | `cancellationDeadline` |
| Only if no sibling instance double-books a shared resource | `locationOverlap` |
| Only if the actor is the specific persona named on this instance | `actorEqualsField` |

## Anti-patterns

| ❌ Wrong | ✅ Right |
|---|---|
| Relying on the UI to hide a button for security | Declare the guard; the engine refuses |
| Storing `isFull: true` as effect-written data and guarding on it | `formula` guard over live data |
| A `pending`/`eligible` **state** to represent per-member eligibility | `actorInList` / `relatedListMembership` on **data** — many members can differ simultaneously |
| Duplicating a workflow to express two permission levels | One workflow; guard-filter the transitions |
