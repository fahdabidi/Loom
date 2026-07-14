---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
derived_from: app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
---

# `instanceDataSchema` field types (normative) — grammar v1

`instanceDataSchema` is the **single source of truth** for a workflow's data: validation, display,
editability, and computation. Every field a workflow touches MUST be declared here.

## Field object — all 13 attributes

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
  "formula": "<expression>"        // makes the field COMPUTED (read-only)
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

## The three kinds of field — pick deliberately

| Kind | How to declare | Written by | Seed in `instanceData`? |
|---|---|---|---|
| **Form-entry** | `"writableBy": "formEntry"` | The user, when the field is in the current state's `editableFields` | Yes |
| **Effect** | `"writableBy": "effect"` | Transition effects | Yes |
| **Computed** | `"formula": "<expr>"` | **Nobody** — derived on read | **NO — hard error** |

**Rules:**
- Only `writableBy: "formEntry"` fields may appear in a state's `editableFields`. → else
  `effect_field_in_editable_fields`
- A computed field MUST NOT be effect-written (`computed_field_written_by_effect`) or seeded
  (`computed_field_seeded`).
- **If a value can be derived, derive it.** See [formulas.md](./formulas.md).

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
| A computed field may not be effect-written | `computed_field_written_by_effect` |
| A computed field may not be seeded | `computed_field_seeded` |
| Every `instanceData` key must be declared here | `unknown_instance_data_key` |
| Every `required: true` non-computed field must be present in seeds | `missing_required_field` |
| A `sortable` table column requires `sortable: true` on the field | `sortable_column_without_backing_field` |
