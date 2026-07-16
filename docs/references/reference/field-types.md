---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.1.0
status: current
last_verified: 2026-07-16
audience: llm-agent
derived_from:
  - app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
  - app/packages/core/loom_workflow_engine/lib/src/evaluator/source_query.dart
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
---

# `instanceDataSchema` field types (normative) — grammar v1

`instanceDataSchema` is the **single source of truth** for a workflow's data: validation, display,
editability, and computation. Every field a workflow touches MUST be declared here.

## Field object — all 14 attributes

```jsonc
"<fieldName>": {
  "type": "<see table>",           // REQUIRED
  "required": false,               // default false
  "writableBy": "formEntry"|"effect",
  "storage": "inline"|"reference",
  "storageTarget": "<backend>",    // when storage=reference
  "searchable": false,             // default false
  "sortable": false,               // default false
  "displayIcon": "<material-icon>",
  "labelTemplate": "{value}",
  "displayContexts": ["tile","detail"],
  "hideWhenEmpty": false,          // default false
  "maxLength": 500,
  "formula": "<expression>",       // makes the field COMPUTED (read-only)
  "source": "query(<type> where <foreignField> == <localField>)"  // makes the field QUERY-BACKED (read-only)
}
```

⚠️ **`type` is a free-form string in the parser** — it is not validated against an enum. Use only the
values below; an unrecognized type will parse but render unpredictably.

## Types

| `type` | Meaning | Notes |
|---|---|---|
| `text` | Single-line string | The default for names/titles |
| `textarea` | Multi-line string | Use with `maxLength` |
| `number` | Numeric | |
| `bool` | Boolean | |
| `date` | ISO-8601 date/datetime | Use `date?` for nullable |
| `time` | Time of day | |
| `list` | Array of anything (incl. objects) | e.g. `ballots`, `candidates`, `messages` |
| `map` | Key→value | Typically a `groupCount` result |
| `personaId` | A single persona id | `personaId?` for nullable |
| `personaId[]` | Array of persona ids | **The standard for member lists** |
| `image` | Image reference | Use `storage: "reference"` |

**Nullable convention:** append `?` (e.g. `date?`, `personaId?`) for fields that are legitimately empty.

## The four kinds of field — pick deliberately

| Kind | How to declare | Written by | Seed in `instanceData`? |
|---|---|---|---|
| **Form-entry** | `"writableBy": "formEntry"` | The user, when the field is in the current state's `editableFields` | Yes |
| **Effect** | `"writableBy": "effect"` | Transition effects | Yes |
| **Computed** | `"formula": "<expr>"` | **Nobody** — derived on read | **NO — hard error** |
| **Query-backed** | `"source": "query(...)"` | **Nobody** — populated on read from another type's rows | **NO — hard error** |

**Rules:**
- Only `writableBy: "formEntry"` fields may appear in a state's `editableFields`. → else
  `effect_field_in_editable_fields`
- A computed OR query-backed field MUST NOT be effect-written (`computed_field_written_by_effect`) or
  seeded (`computed_field_seeded`) — both checks now cover `source` fields the same way they've always
  covered `formula` fields (widened in Phase A′, 2026-07-16).
- **If a value can be derived, derive it.** See [formulas.md](./formulas.md).

## `source` — query-backed fields (GAP-4, executed as of Phase A′, 2026-07-16)

For a field whose value is really "every row of another type that references me" — a ballot's cast
votes, a thread's messages-from-another-table, any parent/child relationship modeled as separate
instances rather than a nested list — declare `source` instead of `formula`:

```jsonc
"ballots": { "type": "list", "source": "query(tournament-vote where ballotId == id)" }
```

**Bounded query grammar — deliberately minimal, matching this codebase's "small fixed vocabulary, no
arbitrary execution" philosophy** (the same reason the formula evaluator has a fixed function set):

```
source := "query(" workflowType " where " foreignField " == " localField ")"
```

- `workflowType` MUST be a declared type.
- `foreignField` MUST be a declared field on that type.
- `localField` MUST be `id` (this instance's own id — see [`effects.md`](./effects.md)'s `{id}`
  interpolation for the equivalent on the write side) or a declared field on **this** type.
- Only `==` is supported. No compound conditions, no other operators, no nesting.

**Execution:** at read time — `queryInstances`, `availableTransitionsAsync`, `applyTransition`'s result,
and `dueNotifications` all hydrate `source` fields before returning — the engine runs the equality query
against its own store and populates the field with the **full `instanceData` of every matching instance**
(not just ids; `groupCount(ballots, choice)` needs to read each matched row's `choice`). Once hydrated, an
ordinary `formula` field can aggregate over it with the normal function vocabulary — this is how
`tournament-ballot`'s `voteCounts`/`winner`/`tiedCandidates`/`isTie` work: four one-line formulas over a
`source`-backed list, zero bespoke tally code.

**Validator checks:** `invalid_source_query_syntax` if the string doesn't parse;
`dangling_source_query_workflow_type` if `workflowType` isn't declared; `dangling_instance_data_key` if
`foreignField`/`localField` don't resolve on their respective types.

## Display attributes

| Attribute | Effect |
|---|---|
| `displayIcon` | Material icon on the fact pill. **Give each field a distinct, meaningful icon.** |
| `labelTemplate` | How the value renders. `{value}` → the value; `{value.length}` → list length |
| `displayContexts` | `["tile"]` = compact card only · `["detail"]` = expanded only · both = everywhere |
| `hideWhenEmpty` | Omit the pill entirely when null/empty (e.g. don't show "Queue: 0") |
| `searchable` | Included in search |
| `sortable` | May be sorted on. **Required** if a table column sorts by it |

⚠️ **Do not give every field the same `displayIcon`.** A real shipped bug had every calendar fact pill
using `check_circle_outline`, which read as a debug affordance rather than information. Date → `schedule`,
person → `person_outline`, place → `location_on_outlined`, capacity → `groups_outlined`.

### `labelTemplate` examples
```jsonc
"title":            { "labelTemplate": "{value}" },                 // -> "Eagle Ridge loop"
"capacity":         { "labelTemplate": "{value} seats" },           // -> "12 seats"
"goingCount":       { "labelTemplate": "Going: {value}" },          // -> "Going: 7"
"queuedPersonaIds": { "labelTemplate": "Queue: {value.length}" },   // -> "Queue: 2"
"dueDate":          { "labelTemplate": "Due back {value}" }         // -> "Due back 2026-07-17"
```
`labelTemplate` is the **only** string-composition mechanism — formulas cannot concatenate strings.

## Storage

| `storage` | Meaning |
|---|---|
| `inline` | Stored in `instanceData` (the default for everything) |
| `reference` | A pointer; the blob lives elsewhere. Set `storageTarget` (e.g. `firebase-storage`). Use for images. |

---

## Canonical schema

```jsonc
"instanceDataSchema": {
  // form-entry: user-editable while the state allows it
  "title":     { "type": "text", "required": true, "maxLength": 80,
                 "writableBy": "formEntry", "storage": "inline",
                 "searchable": true, "sortable": true,
                 "labelTemplate": "{value}", "displayContexts": ["tile", "detail"] },
  "eventDate": { "type": "date", "required": true,
                 "writableBy": "formEntry", "storage": "inline", "sortable": true,
                 "displayIcon": "calendar_today", "labelTemplate": "{value}",
                 "displayContexts": ["tile", "detail"] },
  "capacity":  { "type": "number", "required": true,
                 "writableBy": "formEntry", "storage": "inline",
                 "displayIcon": "groups_outlined", "labelTemplate": "{value} seats" },

  // effect-written: mutated by transitions
  "goingPersonaIds": { "type": "personaId[]", "writableBy": "effect", "storage": "inline" },
  "holderPersonaId": { "type": "personaId?",  "writableBy": "effect", "storage": "inline",
                       "displayIcon": "person_outline", "labelTemplate": "Holder: {value}",
                       "hideWhenEmpty": true, "displayContexts": ["tile", "detail"] },

  // computed: derived on read. NEVER seeded, NEVER effect-written.
  "goingCount":     { "type": "number", "formula": "size(goingPersonaIds)",
                      "displayIcon": "groups_outlined", "labelTemplate": "Going: {value}",
                      "displayContexts": ["tile", "detail"] },
  "spotsRemaining": { "type": "number", "formula": "capacity - size(goingPersonaIds)" },
  "isFull":         { "type": "bool",   "formula": "size(goingPersonaIds) >= capacity" }
}
```

## Rules (validator-enforced)

| Rule | Error |
|---|---|
| Every guard/effect key must be declared here | `dangling_instance_data_key` |
| Every formula-referenced field must be declared here | `unknown_formula_field` |
| `editableFields` may only name `writableBy: "formEntry"` fields | `effect_field_in_editable_fields` |
| A computed OR query-backed field may not be effect-written | `computed_field_written_by_effect` |
| A computed OR query-backed field may not be seeded | `computed_field_seeded` |
| Every `instanceData` key must be declared here | `unknown_instance_data_key` |
| Every `required: true` non-computed, non-query-backed field must be present in seeds | `missing_required_field` |
| A `sortable` table column requires `sortable: true` on the field | `sortable_column_without_backing_field` |
| `source` must parse as `query(type where foreignField == localField)` | `invalid_source_query_syntax` |
| `source`'s `workflowType` must be a declared type | `dangling_source_query_workflow_type` |
| `source`'s `foreignField`/`localField` must resolve on their respective types | `dangling_instance_data_key` |
