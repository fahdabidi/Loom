---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
derived_from: app/packages/core/loom_workflow_engine/lib/src/evaluator/formula_evaluator.dart
---

# Formulas (normative) — grammar v1

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
| Boolean | `&&` `\|\|` |
| Grouping | `( )` |

⚠️ **There is no `!=` and no `!` (not).** Invert by restructuring:
- instead of `a != b` → `if(a == b, false, true)`
- instead of `!isFull` → `size(goingPersonaIds) < capacity`

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

## Functions — complete list (20). No others exist.

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

---

## Canonical formulas

### Capacity / attendance
```jsonc
"goingCount":     { "type": "number", "formula": "size(goingPersonaIds)" },
"spotsRemaining": { "type": "number", "formula": "capacity - size(goingPersonaIds)" },
"isFull":         { "type": "bool",   "formula": "size(goingPersonaIds) >= capacity" },
"quorumMet":      { "type": "bool",   "formula": "size(goingPersonaIds) >= minimumAttendance" }
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
"queueLength":   { "type": "number", "formula": "size(queuedPersonaIds)" },
"myQueuePlace":  { "type": "number", "formula": "indexOf(queuedPersonaIds, $viewer)" }
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

---

## Rules (validator-enforced)

| Rule | Error |
|---|---|
| Must parse | `invalid_formula_syntax` |
| Every referenced field must be declared in **this** schema | `unknown_formula_field` |
| Every function must be one of the 20 | `unknown_formula_function` |
| Computed-field dependencies must be acyclic | `circular_formula_dependency` |
| A computed field MUST NOT be written by an effect | `computed_field_written_by_effect` |
| A computed field MUST NOT be seeded in `instanceData` | `computed_field_seeded` |

## Anti-patterns

| ❌ Wrong | ✅ Right |
|---|---|
| `{"op":"increment","key":"goingCount"}` alongside a `goingPersonaIds` list | `"goingCount": {"formula": "size(goingPersonaIds)"}` |
| Seeding `"isFull": false` in `instanceData` | Declare it as a `formula`; never seed |
| Parsing a display string (`"12 of 20 seats"`) to get a number | Store `capacity`; compute the rest |
| `!isFull` | `size(goingPersonaIds) < capacity` (no `!` operator) |
| `status != 'closed'` | `if(status == 'closed', false, true)` (no `!=` operator) |

## Not in the vocabulary

If you need one of these, **stop and report the gap** — do not approximate:

| Missing | Note |
|---|---|
| `!` (not), `!=` | Restructure as shown above |
| `rank`, `topN` | Proposed but unimplemented. `sortBy` covers most cases. |
| `pow`, `exp` | Not implemented (would be needed for true Elo). |
| String concatenation | Use `labelTemplate` (`"{value} seats"`) for display instead. |
