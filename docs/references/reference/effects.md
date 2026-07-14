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

# Effects (normative) — grammar v1

An effect is what **changes** when a transition fires. Effects run after guards pass, inside the same
transaction as the state change.

**Complete list: nine ops. No others exist.** An unrecognized `op` is an error
(`unknown_effect_op`) — the parser will not guess.

## Effect object — every legal key

```jsonc
{
  "op": "<one of the nine>",       // REQUIRED
  "key": "<field name>",           // for data ops; null for branch/createInstance/removeFromTileGrid
  "value": <any>,                  // for data ops
  "relatedInstance": "<field>",    // cross-instance write (see §8)
  "workflowType": "<type>",        // createInstance only
  "fields": { },                   // createInstance only
  "if": "<formula>",               // branch only
  "then": [ ],                     // branch only
  "else": [ ]                      // branch only
}
```

## Interpolation (available in every `value` and in `fields`)

| Token | Resolves to |
|---|---|
| `$actor` | The acting persona's id |
| `$timestamp` | Now (ISO-8601) |
| `{fieldName}` | That field's current value on this instance (incl. **computed** fields) |

`{fieldName}` reads computed fields too — this is how `close-vote` writes `{winner}` without anyone ever
storing a winner.

---

## The nine ops

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
| `op` must be one of the nine | `unknown_effect_op` |
| `key` must be declared in this schema (same-instance ops) | `dangling_instance_data_key` |
| MUST NOT write a computed (`formula`) field | `computed_field_written_by_effect` |
| `relatedInstance` must be a declared field on **this** instance | `dangling_related_instance_field` |
| `createInstance.workflowType` must exist | `dangling_create_instance_target` |
| `createInstance.fields` keys must be declared on the **target** | `dangling_instance_data_key` |
| `branch.if` must be a valid formula over this schema | `invalid_formula_syntax` / `unknown_formula_field` |
| Effects inside `then`/`else` are validated recursively | (all of the above) |

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
