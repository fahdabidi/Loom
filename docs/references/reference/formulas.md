---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.2.0
status: current
last_verified: 2026-07-31
audience: llm-agent
derived_from: app/packages/core/loom_workflow_engine/lib/src/evaluator/formula_evaluator.dart
---

# Formulas (normative) — grammar v2

A formula is a **pure expression** evaluated at read time. It never mutates anything.

**Two uses:**
1. **Computed field** — `instanceDataSchema.<field>.formula`. Derived on read; never stored, never
   seeded, never effect-written.
2. **Condition** — `guard.formula` and `branch.if`.

**Safety:** formulas are parsed by a dedicated evaluator, never handed to a language runtime. Only the
functions and operators below can execute, and field references resolve **only** against the same
workflow's declared `instanceDataSchema`.

**Rule: if a value can be derived, derive it.** Never store a count, total, ranking, or boolean condition
you could compute. A stored count and its underlying list *will* drift apart.

---

## Operators — complete list

| Category | Operators |
|---|---|
| Arithmetic | `+` `-` `*` `/` (also `×` `÷`) |
| Comparison | `==` `>` `>=` `<` `<=` |
| Boolean | `&&` `\|\|` `!` (unary not) |
| Grouping | `( )` |

⚠️ **There is no `!=`.** Invert by restructuring: `a != b` → `if(a == b, false, true)`.

**Correction, 2026-07-17:** unary `!` (not) was previously (incorrectly) documented as absent alongside
`!=`. Verified directly against the parser (`formula_evaluator.dart:458-462`, `_unary()`) and evaluator
(`:236`, `!_bool(v)`): **`!` genuinely works** — only the two-character `!=` comparison operator is
actually absent (confirmed: `_comparison()`, `:428-436`, never checks for it). `!isFull` is valid; prefer
`size(goingFanIds) < capacity` anyway where a positive formulation reads more clearly, but do not
treat `!` as unsupported — it is.

## Literals

| Kind | Example |
|---|---|
| Number | `42`, `3.14` |
| **String** | `'available'` or `"available"` — **both quote styles work** |
| Boolean | `true`, `false` |
| Null | `null` |

✅ **String literals are supported.** `"availabilityState == 'available'"` is valid.

## Field references

A bare identifier is a field on **this** workflow. It MUST be declared in this workflow's
`instanceDataSchema`. → else `unknown_formula_field` (error)

Dotted paths (`item.choice`) are used inside collection functions to select a column.

---

## Functions — complete list (23). No others exist.

✅ **Correction 2026-07-31: `subtractHours` and `mapGet` are actually IMPLEMENTED** (confirmed directly
against `formula_evaluator.dart`) — this doc's own "PROPOSED" warning was stale, left over from before
their implementation shipped. **`combineDateAndTime` is also IMPLEMENTED** (CAL.Notify2.9, 2026-08-01)
— everything else in this list is real today.

### Aggregates over a list

| Function | Signature | Returns |
|---|---|---|
| `count` | `count(list)` | Number of items |
| `size` | `size(list)` | Number of items (use for lists/maps; the common one) |
| `sum` | `sum(list, column?)` | Sum |
| `avg` | `avg(list, column?)` | Mean, or `null` if empty |
| `min` | `min(list, column?)` | Minimum, or `null` if empty |
| `max` | `max(list, column?)` | Maximum, or `null` if empty |
| `countDistinct` | `countDistinct(list, column?)` | Count of distinct values |

### Grouping and ranking

| Function | Signature | Returns |
|---|---|---|
| `groupCount` | `groupCount(list, column)` | **Map** of value → count. *The vote tally.* |
| `argMaxKey` | `argMaxKey(map)` | The key with the highest value. *The winner.* |
| `topKeys` | `topKeys(map)` | **List** of all keys tied for the highest value. *The tie set.* |
| `sortBy` | `sortBy(list, column, 'asc'\|'desc')` | Sorted list |
| `mapGet` | `mapGet(map, key)` | The value at `key`, or `0` if absent. *Pulls one count out of a `groupCount` tally without a `null`-arithmetic trap.* |

### Membership and position

| Function | Signature | Returns |
|---|---|---|
| `contains` | `contains(list, value)` | bool |
| `indexOf` | `indexOf(list, value)` | Position, or -1. *Queue position.* |

### Conditional

| Function | Signature | Returns |
|---|---|---|
| `if` | `if(condition, whenTrue, whenFalse)` | Either branch |

### Date / time

| Function | Signature | Returns |
|---|---|---|
| `now` | `now()` | Current timestamp |
| `daysBetween` | `daysBetween(a, b)` | Days between two dates |
| `daysUntil` | `daysUntil(date)` | Days from now until date |
| `isBefore` | `isBefore(a, b)` | bool |
| `isAfter` | `isAfter(a, b)` | bool |
| `isPast` | `isPast(date)` | bool — *deadline passed* |
| `subtractHours` | `subtractHours(date, hours)` | `date` minus `hours` — a real new `DateTime`. *Deriving a reminder's `dueAt` from a `deadline`.* |
| `combineDateAndTime` | `combineDateAndTime(date, time)` | Combines an ISO date field and an optional `HH:mm` time field into one real local `DateTime` (midnight if `time` is absent/null). **IMPLEMENTED 2026-08-01 (Notifications Experience phase, CAL.Notify2.9)** — the shared value-parsing helper preserves the exact behavior used by `cancellationDeadline`/`locationOverlap` guards and is now available as a public formula function so computed fields can use it too. *Combining `event-rsvp`'s separate `eventDate`/`eventTime` fields before computing a real `reminderAt` — the same lesson `cancellationDeadline` already taught: a date field alone parses to midnight, so subtracting hours from just the date makes a reminder inaccurately early for any event with a real time-of-day.* |

Deliberately hour-granularity, not day-granularity — some reminder offsets are sub-day (e.g. "one hour
before"). Deliberately generic (a raw duration subtraction), not a labeled-offset-aware function — the
label-to-hours mapping (`'one-week'` → 168, etc.) is composed in the JSON via `if`, keeping business
vocabulary out of the interpreter, the same principle every other formula in this file already follows.

## Reserved row references — not `instanceDataSchema` fields

| Reference | Resolves to |
|---|---|
| `$actor` | The **person** who performed the current transition, as a `fanId` (or `null` outside a transition) |
| `$viewer` | The **person** currently reading/querying, as a `fanId` (set on every `queryInstances`/`availableTransitionsAsync` call) |
| `$state` | **(PROPOSED)** A row's own current FSM state, usable as the `column` argument to `groupCount`/`sum`/etc. — e.g. `groupCount(responses, '$state')` tallies rows by their real workflow state, not a duplicated status field. Only meaningful inside a `source: query(...)`-backed list's aggregate functions; not a bare field reference. |

> **Grammar v2: `$actor` and `$viewer` are `fanId`-typed.** Comparing either against a declared `roleId`
> is a validator error, not a silent false. This is the single most common v1 authoring mistake —
> `$viewer == 'masjid-admin'` parses, never matches, and produces no diagnostic. "This person, or anyone
> with this role" is written as a `fanId` comparison in the formula **plus** an `allowedRoleIds` guard;
> they are different layers. See [`identity-types.md`](./identity-types.md) and
> [`permissions.md`](./permissions.md) §2.

**Why `$state` matters:** without it, counting "how many rows are in the `going` state" would force
authoring a redundant `instanceData` field manually kept in sync with the state machine on every
transition — exactly the kind of duplicated-source-of-truth pattern `goingCount`'s own history in this
file already warns against (a stored count *will* drift from what it claims to summarize; the same is
true of a stored status code drifting from the real state).

---

## Canonical formulas

### Capacity / attendance
```jsonc
"goingCount":     { "type": "number", "formula": "size(goingFanIds)" },
"spotsRemaining": { "type": "number", "formula": "capacity - size(goingFanIds)" },
"isFull":         { "type": "bool",   "formula": "size(goingFanIds) >= capacity" },
"quorumMet":      { "type": "bool",   "formula": "size(goingFanIds) >= minimumAttendance" }
```

### Vote tally, winner, tie — the entire ballot, in four lines
```jsonc
"voteCounts":     { "type": "map",  "formula": "groupCount(ballots, choice)" },
"winner":         { "type": "text", "formula": "argMaxKey(voteCounts)" },
"tiedCandidates": { "type": "list", "formula": "topKeys(voteCounts)" },
"isTie":          { "type": "bool", "formula": "size(tiedCandidates) > 1" }
```
A formula MAY reference another computed field (`isTie` → `tiedCandidates` → `voteCounts`). Dependencies
must be **acyclic**. → else `circular_formula_dependency` (error)

### Queue position
```jsonc
"queueLength":   { "type": "number", "formula": "size(queuedFanIds)" },
"myQueuePlace":  { "type": "number", "formula": "indexOf(queuedFanIds, $viewer)" }
```

### Availability (string literal)
```jsonc
"isAvailable": { "type": "bool", "formula": "availabilityState == 'available'" }
```

### Deadlines
```jsonc
"isExpired":     { "type": "bool",   "formula": "isPast(deadline)" },
"daysRemaining": { "type": "number", "formula": "daysUntil(deadline)" }
```

### Money
```jsonc
"totalRaised":   { "type": "number", "formula": "sum(donations, amount)" },
"donorCount":    { "type": "number", "formula": "countDistinct(donations, donorId)" },
"fundedPercent": { "type": "number", "formula": "totalRaised / goal * 100" }
```

### Standings
```jsonc
"rankings": { "type": "list", "formula": "sortBy(players, score, 'desc')" }
```

### Row-per-user response tally (event-rsvp-response pattern)
```jsonc
"responses":       { "type": "list", "source": "query(event-rsvp-response where eventId == id)" },
"responseCounts":  { "type": "map",    "formula": "groupCount(responses, '$state')" },
"goingCount":      { "type": "number", "formula": "mapGet(responseCounts, 'going')" },
"waitlistedCount": { "type": "number", "formula": "mapGet(responseCounts, 'waitlisted')" },
"isFull":          { "type": "bool",   "formula": "goingCount >= capacity" }
```
The row's own FSM state (`$state`), not a duplicated status field, is what gets tallied — see the
Reserved row references section above.

### Deriving a reminder time from a deadline
```jsonc
"dueAt": { "type": "date",
  "formula": "subtractHours(deadline, if(reminderOffset == 'one-week', 168, if(reminderOffset == 'one-day', 24, if(reminderOffset == 'one-hour', 1, 0))))" }
```

---

## Rules (validator-enforced)

| Rule | Error |
|---|---|
| Must parse | `invalid_formula_syntax` |
| Every referenced field must be declared in **this** schema | `unknown_formula_field` |
| Every function must be one of the 22 | `unknown_formula_function` |
| Computed-field dependencies must be acyclic | `circular_formula_dependency` |
| A computed field MUST NOT be written by an effect | `computed_field_written_by_effect` |
| A computed field MUST NOT be seeded in `instanceData` | `computed_field_seeded` |

## Anti-patterns

| ❌ Wrong | ✅ Right |
|---|---|
| `{"op":"increment","key":"goingCount"}` alongside a `goingFanIds` list | `"goingCount": {"formula": "size(goingFanIds)"}` |
| Seeding `"isFull": false` in `instanceData` | Declare it as a `formula`; never seed |
| Parsing a display string (`"12 of 20 seats"`) to get a number | Store `capacity`; compute the rest |
| `status != 'closed'` | `if(status == 'closed', false, true)` (no `!=` operator — `!` itself is fine) |

## Not in the vocabulary

If you need one of these, **stop and report the gap** — do not approximate:

| Missing | Note |
|---|---|
| `!=` | Restructure: `if(a == b, false, true)`. (Unary `!` is NOT missing — see the Operators section above.) |
| `rank`, `topN` | Proposed but unimplemented. `sortBy` covers most cases. |
| `pow`, `exp` | Not implemented (would be needed for true Elo). |
| String concatenation | Use `labelTemplate` (`"{value} seats"`) for display instead. |
