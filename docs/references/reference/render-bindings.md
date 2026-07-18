---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.2.0
status: current
last_verified: 2026-07-17
audience: llm-agent
derived_from:
  - app/packages/core/loom_workflow_engine/lib/src/evaluator/binding_resolver.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart
  - app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
---

# Render bindings (normative) — grammar v1

A render binding answers: **where does an instance of this workflow appear, in this state, for this
role?**

**Key idea:** a workflow lands on a tab because **its own JSON says so** — not because of any hardcoded
rule. A workflow with **no** binding for a state does not render in that state (the correct way to hide
drafts).

## Binding object — 10 keys (2 added in Phase A′ 2026-07-16, 2 added 2026-07-17)

```jsonc
{
  "states": ["open"],                  // REQUIRED
  "role": "any",                       // REQUIRED
  "tabId": "calendar",                 // REQUIRED
  "cardSurfaceFamily": "event-rsvp",   // REQUIRED
  "bindingKind": "primary",            // REQUIRED
  "audienceMemberField": "invitedPersonaIds",  // optional
  "repeater": { /* see below */ },              // optional, GAP-1
  "creatable": { /* see below */ },             // optional, GAP-2
  "responseTable": { /* see below */ },         // optional, PROPOSED 2026-07-17
  "filterableFacets": [ /* see below */ ]       // optional, PROPOSED 2026-07-17
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `states` | string[] | **yes** | Which states this binding applies to. Each MUST be declared. |
| `role` | string | **yes** | `any` · `actor` · `receiver` |
| `tabId` | string | **yes** | Which tab (enumerated below) |
| `cardSurfaceFamily` | string | **yes** | Which archetype renders it |
| `bindingKind` | string | **yes** | `primary` · `summary` |
| `audienceMemberField` | string | no | Field holding invited personas, for targeted visibility |
| `repeater` | object | no | Renders a per-item action row over a list (GAP-1) |
| `creatable` | object | no | Declares this type member-creatable (GAP-2) |
| `responseTable` | object | no | Points a calendar-family archetype at a per-member response table, instead of assuming field names (PROPOSED) |
| `filterableFacets` | object[] | no | Named, labeled, computed-field-backed filters/stats a generic list surface may offer (PROPOSED) |

⚠️ **Grammar/engine status differs across these additions — read before using any of them.** `repeater`
is fully implemented and engine-executed (parsing + `{item.x}`/`{input.x}` resolution + validator
checks) — confirmed working end-to-end on `tournament-ballot`. `creatable` **parses and validates
correctly, and now has one real consumer**: `event-rsvp`'s "+ New event" affordance (see
`spec-version.json` → `knownGaps.instanceCreation`) — other types declaring `creatable` still render no
UI for it yet. `responseTable` and `filterableFacets` are **PROPOSED — grammar/validator only, written
ahead of the App Shell code that will consume them**, same convention this file's earlier additions
used before their own consumers existed.

## `responseTable` — point a calendar-family archetype at its per-member response table (PROPOSED)

```jsonc
"responseTable": {
  "workflowType": "event-rsvp-response",
  "eventField": "eventId",
  "pendingStates": ["pending"]
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `workflowType` | string | **yes** | The row-per-member response type (a GAP-4-style table, one row per persona per event). |
| `eventField` | string | **yes** | The field, on rows of `workflowType`, holding the parent event's `instanceId`. |
| `pendingStates` | string[] | **yes** | Which of `workflowType`'s own states count as "not yet responded" — drives the Pending view. |

**Why this exists instead of a hardcoded field-name assumption:** without it, "does the viewer still
need to respond to this event?" would require the App Shell to know `event-rsvp-response`'s specific
shape by name. A second calendar-bound archetype with a differently-named response table declares its
own `responseTable` and the same generic Pending-view logic works unmodified.

**Evaluation:** for the current viewer, find the row of `workflowType` where `eventField` equals this
event's `instanceId` and `personaId` equals the viewer — read its current state; if that state is in
`pendingStates`, this event belongs in the viewer's Pending view.

**Validation:** `workflowType` must be declared; `eventField` must be a declared field on that type;
every `pendingStates` entry must be a declared state of that type.

## `filterableFacets` — named, computed-field-backed filters for a generic list surface (PROPOSED)

```jsonc
"filterableFacets": [
  { "field": "isFull", "label": "Full events" },
  { "field": "hasWaitlist", "label": "Has waitlist" },
  { "field": "goingCount", "label": "Number accepted" }
]
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `field` | string | **yes** | A `formula`-typed field declared in this workflow's own `instanceDataSchema`. |
| `label` | string | **yes** | Display label for the facet. |

A boolean-typed `field` renders as a togglable filter chip; a `number`-typed `field` renders as a
displayed/sortable stat, not a threshold-input filter (no "at least N" UI in this pass — see
`spec-version.json` for why that was deliberately deferred).

**Validation:** each `field` must be declared, `formula`-typed, in this workflow's own
`instanceDataSchema`. → `dangling_filterable_facet_field` (error)

## `repeater` — per-item action buttons over a list (GAP-1)

Renders one row per item in a list, each with its own transition button whose inputs are drawn from that
item's own fields — this is what makes "Vote for THIS candidate" declarative instead of one bespoke
button per candidate.

```jsonc
"repeater": {
  "source": "candidates",              // a list field on this instance, OR a query(...) expression (GAP-4)
  "itemActions": [
    { "transitionId": "cast-vote", "inputs": { "choice": "{item.id}" } }
  ]
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `source` | string | **yes** | A `list`-typed field declared in this workflow's `instanceDataSchema`, **or** a bounded `query(type where foreignField == localField)` expression (see [`field-types.md`](./field-types.md)) |
| `itemActions` | object[] | no | Each names a `transitionId` and an `inputs` map whose values may reference `{item.<field>}` — that repeated item's own field |

`{item.<field>}` is resolved by the caller when it renders each row (it names a field on the repeated
item, not on the instance itself) and passed through as the transition's `inputs` when that row's button
fires — see [`effects.md`](./effects.md) for how `{input.x}` then resolves inside the transition's own
effects.

**Validator checks:** every `{item.x}` reference must correspond to a real field on whatever `source`
names — a declared list field's own item shape, or (if `source` is a `query(...)`) the queried type's
`instanceDataSchema` → `unknown_item_reference`.

## `creatable` — declaring a type member-creatable (GAP-2)

```jsonc
"creatable": {
  "byPersonaIds": ["tabletop-member", "tabletop-organizer"],
  "label": "Add event",
  "prefill": { "eventDate": "{context.date}" }   // optional
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `byPersonaIds` | string[] | **yes** | Personas allowed to create a new instance of this type here |
| `label` | string | **yes** | The affordance's button text (e.g. "Propose a game") |
| `prefill` | object | no | Field → value map, pre-filling the creation form |

**Creation semantics (load-bearing):** the affordance is meant to render a form for the target state's
`editableFields`, collect values, **then** call `createInstance` — never create a blank instance first.
Every `required`, non-computed field of the type must appear in that state's `editableFields`, or a
created instance would be invalid on arrival (`creatable_missing_required_field`, not yet implemented as
a distinct validator check — currently caught only as `missing_required_field` at seed-time, not at
creation-time, since nothing creates instances via this path yet).

`prefill`'s values use the same interpolation grammar as effects (`$actor`, literals, `{fieldName}`) plus
one new source specific to `creatable`: **`{context.<key>}`** — supplied by whatever UI invokes the
creation flow, not read from any instance. A Calendar day-detail view rendering "Add event" for July 20th
would invoke creation with `context: { "date": "2026-07-20" }`; `{context.date}` resolves against that.
`context` exists only to answer "where in the app did the member tap 'create'?" — it is never persisted,
never an instance field, and never readable anywhere else.

**Validator checks:** `byPersonaIds` against the known persona registry (`dangling_allowed_persona_id`,
warning); `prefill` keys must be declared in this workflow's own `instanceDataSchema`
(`dangling_instance_data_key`) and must not target a computed field (`computed_field_written_by_effect`);
`{context.x}` appearing anywhere OTHER than inside a `creatable.prefill` value is an error
(`context_reference_outside_creatable`).

## `tabId` — complete list

| `tabId` | Purpose | Always present? |
|---|---|---|
| `home` | The curated feed — what needs attention | **Yes** (structural) |
| `messages` | Discussion threads | **Yes** (structural, renameable but not removable) |
| `calendar` | Events, schedules, RSVPs | Only if the community declares calendar content |
| `marketplace` | Browse/borrow/claim items | Only if declared |
| `giving` | Payments, dues, donations | Only if declared |
| `admin` | Organizer-only queues and publishing | Only if declared |

`home` and `messages` are added **unconditionally** by the App Shell. The rest appear only when a
workflow binds to them.

## `role` — complete list

| `role` | Renders for |
|---|---|
| `any` | Everyone who can see the community |
| `actor` | The persona who acts on / owns this instance |
| `receiver` | The persona on the receiving end (approver, organizer) |

**Role is how one workflow serves two audiences differently.** A proposal binds `actor` → the author's
Home card, and `receiver` → the organizer's Admin queue. **One workflow, two surfaces.**

## `bindingKind` — complete list

| `bindingKind` | Renders as |
|---|---|
| `primary` | Full, interactive card — includes the action buttons |
| `summary` | Compact/read-only card |

Use `primary` for the state where the user acts; `summary` for states where they only observe (a closed
ballot, a cancelled event).

---

## Canonical patterns

### One workflow, two tabs, two roles

```jsonc
"renderBindings": [
  // The author composes it on Home
  { "states": ["draft", "changes-requested"], "role": "actor", "tabId": "home",
    "cardSurfaceFamily": "formEntry", "bindingKind": "primary" },

  // The author watches its status on Home
  { "states": ["pending", "approved", "rejected"], "role": "actor", "tabId": "home",
    "cardSurfaceFamily": "statusTimeline", "bindingKind": "summary" },

  // The organizer decides it in the Admin queue
  { "states": ["pending"], "role": "receiver", "tabId": "admin",
    "cardSurfaceFamily": "approvalQueueItem", "bindingKind": "primary" }
]
```

Note: `draft` has **no** `receiver` binding — an unsubmitted draft is invisible to the organizer. That
is expressed by *omission*, not by a permission flag.

### One instance, two tabs (same role)

```jsonc
// A tournament shows on Calendar as an event AND on Home next to its ballot.
"renderBindings": [
  { "states": ["open"], "role": "any", "tabId": "calendar",
    "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary" },
  { "states": ["open"], "role": "any", "tabId": "home",
    "cardSurfaceFamily": "votePoll", "bindingKind": "summary" }
]
```

### Hiding a state

```jsonc
"states": { "draft": {...}, "published": {...} },
"renderBindings": [
  { "states": ["published"], "role": "any", "tabId": "home",
    "cardSurfaceFamily": "notificationInbox", "bindingKind": "summary" }
  // No binding for "draft" -> drafts do not appear on Home. Correct.
]
```

---

## Rules (validator-enforced)

| Rule | Severity |
|---|---|
| Every `states` entry must be a declared state | error |
| `cardSurfaceFamily` must be a registered archetype | warning (`missing_template`) |
| A `primary` binding's surface must include an action-button row | error (`missing_action_button_row`) |
| >32 bindings on one workflow | warning — a smell; likely two workflows |
| >16 distinct roles | warning — same |
| `repeater.itemActions[].inputs`' `{item.x}` must match the source's item shape | error (`unknown_item_reference`) |
| `creatable.byPersonaIds` must be a known persona | warning (`dangling_allowed_persona_id`) |
| `creatable.prefill` keys must be declared in this workflow's `instanceDataSchema` | error (`dangling_instance_data_key`) |
| `creatable.prefill` must not target a computed field | error (`computed_field_written_by_effect`) |
| `{context.x}` outside a `creatable.prefill` value | error (`context_reference_outside_creatable`) |
| `responseTable.workflowType` must be declared | error (`dangling_response_table_workflow_type`) |
| `responseTable.eventField` must be declared on that type | error (`unknown_response_table_field`) |
| `responseTable.pendingStates` entries must be declared states of that type | error (`unknown_response_table_state`) |
| `filterableFacets[].field` must be a declared, `formula`-typed field in this schema | error (`dangling_filterable_facet_field`) |

## Anti-patterns

| ❌ Wrong | ✅ Right |
|---|---|
| Every workflow bound to `home` "so the user sees it" | Bind to the tab it belongs on. Home is a curated feed, not a dumping ground. |
| Two near-identical workflows for two personas | **One** workflow, two `role`-keyed bindings |
| A `hidden`/`archived` state with a binding, then filtering it out in the UI | Simply declare **no binding** for that state |
| Inventing a `cardSurfaceFamily` | Only values in [`archetypes/README.md`](../archetypes/README.md) exist |
