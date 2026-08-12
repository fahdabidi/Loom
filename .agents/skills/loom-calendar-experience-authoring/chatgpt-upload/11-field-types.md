---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.3.0
status: current
last_verified: 2026-08-12
audience: llm-agent
derived_from:
  - app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
  - app/packages/core/loom_workflow_engine/lib/src/evaluator/source_query.dart
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
---

# `instanceDataSchema` field types (normative) — grammar v1

`instanceDataSchema` is the **single source of truth** for a workflow's data: validation, display,
editability, and computation. Every field a workflow touches MUST be declared here.

## Field object — all 15 attributes

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
  "source": "query(<type> where <foreignField> == <localField>)",  // makes the field QUERY-BACKED (read-only)
  "openMode": "external"|"embedded"|"choice"  // type: "url" only — see below. "external" is REAL; "embedded"/"choice" still not implemented.
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
| `url` | An openable external or embedded link/document | `openMode: "external"` is ✅ REAL; `"embedded"`/`"choice"` are not yet implemented — see below. Use `url?` for nullable. |

**Nullable convention:** append `?` (e.g. `date?`, `personaId?`) for fields that are legitimately empty.

## `type: "url"` — external/embedded document and link fields (`external`: ✅ REAL; `embedded`/`choice`: still proposed)

Proposed 2026-08-09; found while scoping Cedar Commons HOA's `hoa-member-document` and Riverside Youth
Soccer's `soccer-waiver-document` on the v2 generic-archetype migration: both need a field whose value is a
link the user can actually open (an embedded viewer, an external browser/app, or a choice of either), not
just display as text.

**Correction, 2026-08-12:** `openMode: "external"` is implemented, not proposed — confirmed live at
`part18_marketplace_rendering.dart:583-611` (top-level `type: "url"` field, tappable, launches via
`url_launcher`) and `:612-671` (the citation-list `itemSchema` case below, same `external` handling
per-item), fed by `InstanceDataField.fromJson`'s existing `openMode` parsing (`workflow_models.dart:786`).
This doc previously stated the whole `type: "url"` mechanism did nothing — that was stale/wrong for
`external` by the time of this correction; only `openMode: "embedded"` and `"choice"` remain genuinely
unimplemented (both currently render a disabled-looking `Icons.link_off` "unsupported: <label>" pill,
`part18_marketplace_rendering.dart:604-610`/`:660-671`, never opening anything). This matters concretely
for real content: every real community fixture's *primary* document-open field (as opposed to a secondary
`attachmentUrl`-style field, which several already declare as `external` and which already works)
currently declares `openMode: "choice"`, not `external` — grep `docs/references/communities/*.jsonc` for
`"openMode": "choice"` to confirm current instances. `GenericWorkflowInstanceCard` and every bespoke
archetype (`EquipmentLoanArchetypeCard` included) render `instanceDataSchema` fields through the same
shared fact-pill code described above.

**This is deliberately a field-type/display capability, not a new archetype and not a new `effects.md`
op.** Opening a link is a presentation action tied to one field's *value* — it has no bearing on workflow
state, so it does not belong in the effects vocabulary (every effect op exists to mutate `instanceData`
inside the same transaction as a state change; a platform navigation is neither). And because every
archetype already consumes the same schema-driven field renderer, building this once at the field-type
level makes it available to `event-rsvp`, `equipment-loan`, `votePoll`, and every 🟡 GENERIC archetype
simultaneously — not something a community has to opt into per-archetype.

```jsonc
"externalUrl": {
  "type": "url", "required": true, "writableBy": "formEntry",
  "openMode": "choice",
  "displayIcon": "description", "labelTemplate": "Open {value}"
}
```

| Field | Type | Required | Meaning |
|---|---|---|---|
| `openMode` | string | **yes**, for `type: "url"` fields | `external` — always opens via the platform's normal external-link handling (a new browser tab/app). `embedded` — always opens in an in-app viewer. `choice` — renders both an "Open embedded" and "Open externally" control and lets the user pick. |

**Rendering contract:** the shared field renderer shows a `type: "url"` field as a tappable control (not
plain text), labeled per `labelTemplate` if present, using the icon/style already established for
actionable fields. Tapping it performs the platform action named by `openMode` — it does **not** call
`applyTransition` and never mutates `instanceData`. A workflow that also needs to *record* that the link
was opened (an audit trail, an acknowledgement) declares that as an ordinary transition with its own
`appendUnique`/`set` effect on a separate field, exactly as any other user action — the two concerns are
independent and composed by declaring both, not by overloading one field.

**Why `openMode` is required, not defaulted:** an absent value could plausibly mean either "external is
always safe, default to it" or "the author forgot to decide" — for a capability that reaches outside the
app (launching another app, or rendering arbitrary content in an embedded viewer), defaulting silently is
the wrong failure mode. Requiring an explicit choice makes the validator catch the omission
(`missing_url_open_mode`) rather than guessing.

**Validation (once implemented):** `type: "url"` fields MUST declare `openMode` as one of the three listed
values → else `missing_url_open_mode` / `invalid_url_open_mode`. `openMode: "embedded"` or `"choice"`
requires the embedded-viewer platform capability to actually be present in the build — declaring it
without that capability wired is a build-time gap, not a JSON error (same category of honesty issue as
`archetypes/README.md`'s `❌ NOT REAL` entries, not a new validator rule).

**Known follow-on:** `openMode: "embedded"`/`"choice"` need an embedded viewer capability
(`webview_flutter` is not currently a dependency of `loom_communities_app_shell` — confirmed by reading its
`pubspec.yaml`, re-confirmed 2026-08-12). `openMode: "external"` needed `url_launcher`, which the same
`pubspec.yaml` now lists as a real dependency (`^6.3.2`, confirmed 2026-08-12) — this increment has already
landed (see the correction note above). `embedded`/`choice` remain a following increment — an
implementation-sequencing decision, not a grammar change; the field-level contract above does not change
based on which increments are built first.

## Citation lists — `type: "url"` items inside a `type: "list"` field (✅ REAL for `openMode: "external"`)

Proposed 2026-08-09; found scoping Neighborhood Book Club's `book-search-ai-digest` and Masjid Nur's
`mosque-search-ai-citation` workflows: both need a field that is a *list of citations* — each one a short
label plus an openable source link — not a single link. The single-field `type: "url"` shape above covers
"this one field is a link" but not "this field is a list, and each item in it is (label + link)."
**Correction, 2026-08-12:** implemented for `external`-mode citation members — see the correction note in
the `type: "url"` section above; both real `searchAiAnswer`-relevant fixtures (Masjid Nur, Neighborhood
Book Club) already declare their citation source as `openMode: "external"` and render correctly today.

**This does not need a new field `type`.** A citation list is simply `type: "list"` whose items happen to be
objects containing a `url`-shaped member, declared via an `itemSchema`:

```jsonc
"citations": {
  "type": "list",
  "writableBy": "effect",
  "itemSchema": {
    "label": { "type": "text" },
    "source": { "type": "url", "openMode": "external" }
  },
  "displayIcon": "auto_stories",
  "labelTemplate": "{value.length} sources"
}
```

| Field | Type | Required | Meaning |
|---|---|---|---|
| `itemSchema` | object | only meaningful on `type: "list"` fields whose items are objects with an openable member | Same field-object grammar as `instanceDataSchema` itself, one level down — each key is a member name, each value a field object. Only `type`/`openMode` are meaningful inside an `itemSchema` member today (no nested `formula`/`source`/`writableBy` — a citation item's members are plain data, written whole by whatever effect appends the citation). |

**Rendering contract:** the shared field renderer, on encountering a `type: "list"` field with `itemSchema`
containing a `type: "url"` member, renders each list item as a row with the non-`url` members (e.g. `label`)
as text and the `url` member as a tappable control per that member's own `openMode` — exactly the same
tap-triggers-platform-action, never-`applyTransition` contract as a top-level `type: "url"` field, just
applied per-row instead of once. A list field with no `itemSchema`, or an `itemSchema` with no `url`-typed
member, renders exactly as `type: "list"` does today (unchanged) — this is additive, not a new required
attribute on every list.

**Why not a new field type (e.g. `citationList`):** the list is still fundamentally "an array of things" —
sorting, `size()` formulas, `hideWhenEmpty`, and `source`-query hydration should all keep working on it
unchanged. The only new idea is "an item's member can itself be a `url`," which composes with the existing
`type: "list"` + nested-object convention rather than requiring a parallel type.

**Validation (once implemented):** `itemSchema` members follow the same `missing_url_open_mode`/
`invalid_url_open_mode` rules as top-level fields, scoped to that item member (⚠️ proposed —
`missing_url_open_mode`/`invalid_url_open_mode` fire identically whether the `type: "url"` declaration is
top-level or inside an `itemSchema`, no new rule ids needed). `itemSchema` on a non-`"list"`-typed field is
`item_schema_on_non_list_field` (⚠️ proposed, new).

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
| `type: "url"` requires `openMode` | `missing_url_open_mode` (⚠️ proposed) |
| `openMode` must be `external`, `embedded`, or `choice` | `invalid_url_open_mode` (⚠️ proposed) |
| `openMode` on a non-`"url"`-typed field | `url_open_mode_on_non_url_field` (⚠️ proposed) |
| `itemSchema` on a non-`"list"`-typed field | `item_schema_on_non_list_field` (⚠️ proposed) |
