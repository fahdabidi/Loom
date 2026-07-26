---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.5.0
status: current
last_verified: 2026-07-25
audience: llm-agent
derived_from:
  - app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
  - app/packages/core/loom_workflow_engine/lib/src/evaluator/effect_evaluator.dart
  - app/packages/core/loom_workflow_engine/lib/src/evaluator/recurrence_evaluator.dart
---

# Effects (normative) — grammar v1

An effect is what **changes** when a transition fires. Effects run after guards pass, inside the same
transaction as the state change.

**Complete list: eleven ops** (op 10, `removeFromTileGrid`, is presentation-only; op 11,
`transitionRelated`, is implemented as of 2026-07-25 — see §11; op 12, `generateRecurringInstances`, is
implemented as of 2026-07-25 — see §12). An unrecognized `op` is an error (`unknown_effect_op`) — the
parser will not guess.

## Effect object — every legal key

```jsonc
{
  "op": "<one of the eleven>",     // REQUIRED
  "key": "<field name>",           // for data ops; null for branch/createInstance/removeFromTileGrid/generateRecurringInstances
  "value": <any>,                  // for data ops
  "relatedInstance": "<field>",    // cross-instance write (see §8)
  "workflowType": "<type>",        // createInstance, generateRecurringInstances
  "fields": { },                   // createInstance, generateRecurringInstances (per-occurrence template)
  "if": "<formula>",               // branch only
  "then": [ ],                     // branch only
  "else": [ ],                     // branch only
  "relatedQuery": { },             // transitionRelated only
  "transitionId": "<id>",          // transitionRelated only
  "anchorField": "<field>",        // generateRecurringInstances only (§12)
  "recurrenceRule": { }            // generateRecurringInstances only (§12)
}
```

## Interpolation (available in every `value` and in `fields`)

| Token | Resolves to |
|---|---|
| `$actor` | The acting persona's id |
| `$timestamp` | Now (ISO-8601) |
| `{fieldName}` | That field's current value on this instance (incl. **computed** fields) |
| `{id}` | **This instance's own `instanceId`** — added in Phase A′, 2026-07-16 |
| `{input.<name>}` | The value supplied for transition input `<name>` on this call — added in Phase A′ (GAP-1) |

`{fieldName}` reads computed fields too — this is how `close-vote` writes `{winner}` without anyone ever
storing a winner.

`{id}` is how an effect refers to the instance firing the transition — most commonly inside a
`createInstance` effect's `fields`, to stamp a foreign-key-style back-reference on the new row (see the
worked example below). It is **not** a key in `instanceDataSchema` — the instance's own id is never a
declared field — so it needed its own interpolation source; `{fieldName}` alone cannot express it.

`{input.<name>}` resolves a value supplied when the transition was fired (see
[`workflow-grammar.md`](./workflow-grammar.md)'s `transitions[].inputs`). This is what lets a single
"Vote" transition know *which* candidate a specific tap voted for, without a shared, racy scratch field:

```jsonc
// tournament-ballot's cast-vote transition
"inputs": { "choice": { "type": "text", "required": true } },
"effects": [
  { "op": "createInstance",
    "workflowType": "tournament-vote",
    "fields": {
      "ballotId": "{id}",              // this ballot's own instance id
      "voterId": "$actor",
      "choice": "{input.choice}"       // whatever choice THIS call supplied
    } }
]
```

Two members voting at the same moment each get their own `applyTransition` call with their own `inputs`
map — `{input.choice}` resolves per-call, so there is no shared field for a race to corrupt. This is the
grammar-native replacement for the old workaround (write a shared `pendingChoice` field, then fire a
parameterless transition second) — see [`guide/04-antipatterns.md`](../guide/04-antipatterns.md).

---

## The eleven ops

### 1. `set` — assign a value

```jsonc
{ "op": "set", "key": "availabilityState", "value": "onLoan" }
{ "op": "set", "key": "holderPersonaId",   "value": "$actor" }
{ "op": "set", "key": "paidAt",            "value": "$timestamp" }
{ "op": "set", "key": "dueDate",           "value": null }        // null clears
```

### 2. `append` — add to a list (duplicates allowed)

```jsonc
{ "op": "append", "key": "ballots",
  "value": { "personaId": "$actor", "choice": "{pendingChoice}" } }
```
`value` may be an **object** — interpolation applies inside it. This is how a vote record is built.

### 3. `appendUnique` — add to a list, no duplicates

```jsonc
{ "op": "appendUnique", "key": "goingPersonaIds", "value": "$actor" }
```
**Use this, not `append`, for persona lists.** Prevents an actor double-registering.

### 4. `removeValue` — remove from a list

```jsonc
{ "op": "removeValue", "key": "goingPersonaIds", "value": "$actor" }
```

### 5. `increment` / 6. `decrement` — bump a number

```jsonc
{ "op": "increment", "key": "viewCount", "value": 1 }
```

⚠️ **Prefer a computed field.** If the number is derivable (`size(goingPersonaIds)`), use a `formula` —
never an incrementing counter. A counter and its list **will** drift apart. Use `increment` only for a
quantity with no underlying list.

### 7. `branch` — conditional effects

```jsonc
{
  "op": "branch",
  "if": "isTie",                    // a formula over this workflow's fields; must be boolean
  "then": [ /* effects */ ],
  "else": [ /* effects */ ]
}
```

| Field | Type | Meaning |
|---|---|---|
| `if` | string | Formula. Validated like any formula. |
| `then` | effect[] | Run when true |
| `else` | effect[] | Run when false |

Nesting is permitted. `then`/`else` effects are validated recursively.

### 8. cross-instance `set` — write a field on **another** instance

```jsonc
{ "op": "set", "key": "selectedGame", "value": "{winner}", "relatedInstance": "eventId" }
```

| Field | Meaning |
|---|---|
| `relatedInstance` | A field on **this** instance holding the **target instanceId** |
| `key` | A field on the **target** instance (NOT this one) |
| `value` | Interpolated against **this** instance |

**Reads as:** *take my `eventId` → find that instance → set its `selectedGame` to my computed `winner`.*

⚠️ **`key` belongs to the target's schema, not yours.** Do not declare it locally. (The definition-level
validator skips it; the instance-level validator resolves the reference and checks it there.)

**Use for:** propagating a result across workflows — the ballot writing its winner onto the event.

### 9. `createInstance` — spawn a new instance

```jsonc
{ "op": "createInstance",
  "workflowType": "tournament-ballot",
  "fields": {
    "eventId": "{eventId}",
    "candidates": "{tiedCandidates}",     // a computed list — passed by value
    "round": "runoff",
    "ballots": []
  } }
```

| Field | Meaning |
|---|---|
| `workflowType` | The type to create. MUST be declared. → else `dangling_create_instance_target` |
| `fields` | Initial `instanceData`. Every key MUST be declared on the **target** type. |

The new instance starts at the target's `initialState`. Interpolation applies to `fields` values.

**Use for:** a runoff ballot, a scheduled notification, a spawned chat message — anything where firing a
transition should bring a *new object* into existence.

**MUST NOT** write a computed field of the target. → `computed_field_written_by_effect`

### 10 (presentation-only). `removeFromTileGrid`

```jsonc
{ "op": "removeFromTileGrid" }
```
No `key`. Removes the instance's tile from a grid surface. Touches no `instanceData`.

### 11. `transitionRelated` — apply a transition to a *queried* instance

```jsonc
{
  "op": "transitionRelated",
  "relatedQuery": {
    "workflowType": "event-rsvp-response",
    "filter": { "eventId": "{eventId}", "$state": "waitlisted" },
    "sortKey": "rsvpedAt",
    "limit": 1
  },
  "transitionId": "respond-going"
}
```

| Field | Type | Meaning |
|---|---|---|
| `relatedQuery` | object | Same shape as `guards.md`'s `relatedAggregate.filter` (field → literal, `{fieldName}` interpolated against **this** instance, or the reserved `$state` key), plus `sortKey` (a field on the **target** type, ascending) and `limit` (currently only `1` is defined). |
| `transitionId` | string | A transition declared on `relatedQuery.workflowType`. Applied to the **first** matching row after sorting. |

**Why this exists:** every other cross-instance mechanism either writes one field on one directly-named
instance (`relatedInstance`, §8) or spawns a brand-new one (`createInstance`, §9). Nothing today can
*find* a set of sibling instances and drive one of them through its own state machine — the gap this
closes is waitlist promotion: a seat opens on `event-rsvp`, and the **oldest** waitlisted
`event-rsvp-response` row (not a specific, already-known instanceId) needs to be pushed to `going`.

**Semantics — this is a real `applyTransition` call, not a bypass.** The resolved target instance is
transitioned exactly as if `WorkflowEngineApi.applyTransition` were called on it directly: the target
transition's own `guard` (including its own `relatedAggregate`, if any) is evaluated fresh, against the
target's current data, at the moment this effect runs. **If the target's guard fails, the effect is a
silent no-op** — it does not error, and it does not retry against the next-best match. This is a
deliberate design choice: it lets `transitionRelated` be attached unconditionally to every transition
that *might* free a seat (e.g. `event-rsvp-response`'s `respond-maybe`/`respond-declined`, regardless of
which state the row is leaving), without a separate "did this actually free a seat?" formula check —
correctness falls out of the target's own capacity guard re-evaluating live, the same guard that already
gates a member's own manual "Going" tap.

**Ordering caveat:** `sortKey` sorts ascending by the named field's value on `instanceData` — it does
**not** fall back to insertion order. A workflow relying on `sortKey` for a real "first come, first
served" guarantee must stamp its own explicit ordering field via a `set` effect (e.g. `"rsvpedAt":
"$timestamp"` on the transition that enters the queued/waitlisted state) — instance ids are randomly
generated and carry no temporal meaning.

**Validation:** `relatedQuery.workflowType` must be declared → else
`dangling_transition_related_workflow_type`; `transitionId` must be a transition declared on that type →
else `dangling_transition_related_transition_id`; `sortKey`, if present, must name a field declared on
that type → else `dangling_transition_related_sort_key`.

### 12. `generateRecurringInstances` — spawn a bounded recurring series

**Implemented 2026-07-25 (CAL.Recurrence, commits `2974310`/`e653074` engine, `91ef180` validator,
`f5d30b9`/`b4ee5c2` frozen fixture, `7128d9a` App-Shell creation UI, `4eb10d8` App-Shell delete-series).**
Landed in the frozen Tabletop Club fixture: `event-rsvp`'s `make-recurring` transition.

```jsonc
{
  "op": "generateRecurringInstances",
  "workflowType": "event-rsvp",
  "anchorField": "eventDate",
  "fields": {
    "title": "{title}", "eventDate": "{eventDate}", "location": "{location}",
    "seriesId": "$newSeriesId"
  },
  "recurrenceRule": {
    "freq": "weekly",
    "interval": 1,
    "count": 12,
    "byDayOfWeek": ["FR"]
  }
}
```

| Field | Type | Meaning |
|---|---|---|
| `workflowType` | string | The type to spawn occurrences of. MUST be declared. |
| `anchorField` | string | Which key in `fields` holds the base date; the computed occurrence date overwrites this field per-occurrence. MUST be a key present in `fields`, and MUST name a `"date"`-typed field on `workflowType`. |
| `fields` | object | Per-occurrence `instanceData` template — same interpolation as `createInstance.fields` (§9), plus one reserved token below. Every key MUST be declared on `workflowType`. |
| `recurrenceRule` | object | The pattern — see below. |

**Reserved token `$newSeriesId`** (available only inside this op's own `fields`): resolves to one fresh id,
minted once per effect application (not once per occurrence) — every generated occurrence, and the
anchor instance itself, share the same value. This is deliberately separate from `$actor`/`$timestamp`:
those resolve from ambient call context on every use, but `$newSeriesId` is a value the effect handler
mints itself.

**`recurrenceRule` shape:**

| Field | Type | Meaning |
|---|---|---|
| `freq` | `"daily"` \| `"weekly"` \| `"monthly"` | Required. |
| `interval` | integer, default `1` | Every N days/weeks/months. |
| `count` | integer, 1–366 | **Required.** Total occurrences in the series, including the anchor itself — bounds this to eager, fixed-size generation; there is no infinite/open-ended recurrence. |
| `byDayOfWeek` | list of `"MO"`/`"TU"`/`"WE"`/`"TH"`/`"FR"`/`"SA"`/`"SU"` | `weekly`: which weekdays each interval-week (omit → defaults to the anchor's own weekday). `monthly`: exactly one code, only meaningful paired with `bySetPos`. Invalid for `daily`. |
| `byMonthDay` | integer, 1–31 | `monthly` only. A fixed day-of-month, **clamped to the target month's real last day** (e.g. `31` lands on Apr 30, Feb 28, or Feb 29 in a leap year — recomputed fresh per occurrence). Mutually exclusive with `bySetPos`. |
| `bySetPos` | `"first"`/`"second"`/`"third"`/`"fourth"`/`"last"` | `monthly` only, requires exactly one `byDayOfWeek` entry (e.g. `byDayOfWeek: ["FR"]` + `bySetPos: "last"` → "last Friday of the month"). If an ordinal position doesn't exist in a given month, falls back to that month's last occurrence of the weekday for that occurrence only — `count` is never short-counted. Mutually exclusive with `byMonthDay`. |

**Omitting an optional `recurrenceRule` field**: when a value is authored as a bare `{input.x}` token and
the transition is fired without supplying that input at all, it resolves to `null` (not a stringified
literal) — omitted `interval`/`byDayOfWeek`/`byMonthDay`/`bySetPos` correctly fall back to their defaults
(`interval` → `1`; the others → not applied) rather than causing a spurious parse error. A JSON author
composing a `recurrenceRule` template should feel free to declare every field as a token even when the
caller usually only supplies a handful of them for a given `freq`.

**Weekly `byDayOfWeek` and the anchor**: when `byDayOfWeek` doesn't include the anchor's own weekday (e.g.
a Wednesday anchor recurring only on Mondays), occurrence 0 is still always the anchor's real date —
the walk finds the remaining `count - 1` occurrences strictly after it, never before, and never
double-counts the anchor's date even if its own weekday does happen to be requested.

**Occurrence 0 is the anchor instance itself** — the instance the transition fired on gets `seriesId`
stamped onto it in place; it is never duplicated. Occurrences `1..count-1` are brand-new, independent
sibling instances, each one exactly as normal and independent as any other instance of that
`workflowType` — the same RSVP/edit/cancel mechanics that already work for a single event work
per-occurrence for free, with zero new per-occurrence interaction model.

**Deleting one occurrence vs. the whole series:** deleting a single occurrence needs no new capability —
it's that occurrence's own existing cancel/decline transition, unchanged. Deleting an entire series is
**not** a new engine bulk-effect op — it's client-orchestrated: query every instance of the same
`workflowType` sharing that `seriesId`, and call each one's existing single-instance cancel transition in
a loop.

**Why bespoke Dart, not the formula evaluator:** `monthly`'s `byMonthDay`-with-clamping and
`bySetPos`-with-fallback logic is real month/weekday-boundary arithmetic. Expressing this as composed
generic formula primitives would mean building something close to an RRULE engine inside a
general-purpose expression language — over-generalizing it for one narrow feature. The date computation
is real `DateTime` arithmetic in a dedicated evaluator, not a formula.

**Validation:** `workflowType` must be declared → else
`dangling_generate_recurring_target`; `fields` keys must be declared on the target →
`dangling_instance_data_key`; MUST NOT write a computed field of the target →
`computed_field_written_by_effect`; `anchorField` must be a key present in `fields` and must name a
`"date"`-typed target field → else `dangling_recurrence_anchor_field` /
`invalid_recurrence_anchor_field_type`; `recurrenceRule.freq`/`count` are required and range-checked →
else `missing_recurrence_freq` / `invalid_recurrence_freq` / `missing_recurrence_count` /
`invalid_recurrence_count`; `byMonthDay`/`bySetPos` are mutually exclusive →
`recurrence_month_day_set_pos_conflict`; each field is only valid for its applicable `freq` →
`recurrence_field_invalid_for_freq`; monthly `byDayOfWeek` requires `bySetPos` →
`recurrence_weekday_without_set_pos`. A value supplied as a runtime `{input.x}` token (organizer-entered,
not statically known) is skipped by the static validator and backstopped by a runtime error instead —
same deliberate validator/runtime split already documented for `transitionRelated`'s silent guard-failure
behavior.

---

## Worked example — tie → real runoff, else propagate the winner

```jsonc
{
  "id": "close-vote",
  "label": "Close vote",
  "from": ["open"], "to": "closed",
  "guard": { "allowedPersonaIds": ["organizer"] },
  "effects": [
    {
      "op": "branch",
      "if": "isTie",                                  // computed: size(topKeys(voteCounts)) > 1
      "then": [
        { "op": "createInstance", "workflowType": "tournament-ballot",
          "fields": { "eventId": "{eventId}", "candidates": "{tiedCandidates}",
                      "round": "runoff", "ballots": [] } },
        { "op": "set", "key": "outcome", "value": "runoff" }
      ],
      "else": [
        { "op": "set", "key": "outcome", "value": "decided" },
        { "op": "set", "key": "selectedGame", "value": "{winner}", "relatedInstance": "eventId" }
      ]
    }
  ]
}
```

Zero lines of Dart. The tally (`voteCounts`), the winner (`argMaxKey`), and the tie test (`isTie`) are
formulas; the runoff and the propagation are effects.

---

## Rules (validator-enforced)

| Rule | Error |
|---|---|
| `op` must be a known op | `unknown_effect_op` |
| `key` must be declared in this schema (same-instance ops) | `dangling_instance_data_key` |
| MUST NOT write a computed (`formula`) field | `computed_field_written_by_effect` |
| `relatedInstance` must be a declared field on **this** instance | `dangling_related_instance_field` |
| `createInstance.workflowType` must exist | `dangling_create_instance_target` |
| `createInstance.fields` keys must be declared on the **target** | `dangling_instance_data_key` |
| `branch.if` must be a valid formula over this schema | `invalid_formula_syntax` / `unknown_formula_field` |
| Effects inside `then`/`else` are validated recursively | (all of the above) |
| `transitionRelated.relatedQuery.workflowType` must be declared | `dangling_transition_related_workflow_type` |
| `transitionRelated.transitionId` must exist on that type | `dangling_transition_related_transition_id` |
| `transitionRelated.relatedQuery.sortKey`, if present, must be declared on that type | `dangling_transition_related_sort_key` |
| `generateRecurringInstances.workflowType` must be declared | `dangling_generate_recurring_target` |
| `generateRecurringInstances.anchorField` must be a `fields` key naming a `"date"` field | `dangling_recurrence_anchor_field` / `invalid_recurrence_anchor_field_type` |
| `recurrenceRule.freq`/`count` required and range-checked; `byMonthDay`/`bySetPos` mutually exclusive; monthly `byDayOfWeek` requires `bySetPos`; fields must match their applicable `freq` | `missing_recurrence_freq` / `invalid_recurrence_freq` / `missing_recurrence_count` / `invalid_recurrence_count` / `recurrence_month_day_set_pos_conflict` / `recurrence_weekday_without_set_pos` / `recurrence_field_invalid_for_freq` |

## Selection table

| Requirement | Op |
|---|---|
| Assign / clear a value | `set` (`value: null` clears) |
| Record an event that can repeat (a vote) | `append` |
| Add a persona to a list | `appendUnique` |
| Remove a persona from a list | `removeValue` |
| Count something with no underlying list | `increment` / `decrement` |
| Count something **with** an underlying list | ❌ none — use a `formula` |
| Do A or B depending on a condition | `branch` |
| Bring a new object into existence | `createInstance` |
| Write onto a different instance | `set` + `relatedInstance` |
| Find a queried sibling and drive its own state machine | `transitionRelated` |
| Spawn a bounded recurring series (fixed count, no infinite recurrence) | `generateRecurringInstances` |
