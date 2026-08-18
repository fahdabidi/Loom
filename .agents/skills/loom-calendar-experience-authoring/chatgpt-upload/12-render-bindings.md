---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.8.0
status: current
last_verified: 2026-08-09
audience: llm-agent
derived_from:
  - app/packages/core/loom_workflow_engine/lib/src/evaluator/binding_resolver.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart
  - app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part32_engine_native_list_surface.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart
---

# Render bindings (normative) — grammar v1

A render binding answers: **where does an instance of this workflow appear, in this state, for this
role?**

**Key idea:** a workflow lands on a tab because **its own JSON says so** — not because of any hardcoded
rule. A workflow with **no** binding for a state does not render in that state (the correct way to hide
drafts).

## Binding object — 11 keys (2 added in Phase A′ 2026-07-16, 2 added 2026-07-17, 1 added 2026-07-23)

```jsonc
{
  "states": ["open"],                  // REQUIRED
  "role": "any",                       // REQUIRED
  "tabId": "calendar",                 // REQUIRED
  "cardSurfaceFamily": "event-rsvp",   // REQUIRED
  "bindingKind": "primary",            // REQUIRED
  "audienceMemberField": "invitedPersonaIds",  // optional
  "repeater": { /* see below */ },              // optional, GAP-1
  "actions": [ /* see below */ ],               // optional, GAP-2 (replaced `creatable`, grammar v2)
  "responseTable": { /* see below */ },         // optional, PROPOSED 2026-07-17
  "filterableFacets": [ /* see below */ ],      // optional, PROPOSED 2026-07-17
  "styleField": "cardStyleId"                   // optional, PROPOSED 2026-07-23
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
| `actions` | object[] | no | Archetype-owned actions (create, transition) rendered as buttons on the card or as tab/contextual FABs (GAP-2; replaced the flat `creatable` object in grammar v2) |
| `responseTable` | object | no | Points a calendar-family archetype at a per-member response table, instead of assuming field names (PROPOSED) |
| `filterableFacets` | object[] | no | Named, labeled, computed-field-backed filters/stats a generic list surface may offer (PROPOSED) |
| `styleField` | string | no | Names a `number`-typed field in this workflow's own `instanceDataSchema` whose per-instance computed value selects this card's visual style/color slot, instead of the archetype always using one flat community/tab accent (PROPOSED) |

⚠️ **Grammar/engine status differs across these additions — read before using any of them.** `repeater`
is fully implemented and engine-executed (parsing + `{item.x}`/`{input.x}` resolution + validator
checks) — confirmed working end-to-end on `tournament-ballot`. `actions` (grammar v2, replacing the flat
`creatable` object) is **the model this file now normatively describes**, and covers two action kinds.
`kind: "create"`: `scope: "tab"` create-actions are fully built and shipping (the tab creatable-action
FAB — CALR.3g/3h/3b — every `event-rsvp`, `tournament-event`, and every other tab-level creation runs
through it end-to-end); `scope: "instance"` creates (`button` on a card, or a contextual FAB driven by
the in-focus instance — e.g. "Create ballot for this tournament") are **the newly-designed surface not
yet App-Shell-implemented** (see `spec-version.json` → `proposedNotImplemented.actionsGrammar`). `kind:
"transition"` (pulling one already-declared transition out of the automatic button row into its own FAB
or distinguished button) is **new grammar, also not yet App-Shell-implemented** — written ahead of the
code that will consume it, same convention. `responseTable`, `filterableFacets`, and `styleField` are
**PROPOSED — grammar/validator only, written ahead of the App Shell code that will consume them**, same
convention this file's earlier additions used before their own consumers existed.

## ⚠️ `role: "actor"`/`"receiver"` resolution — per-tab, creator-only, and NOT symmetric (found 2026-08-09)

**This is not part of the JSON grammar at all — it's decided per-tab by App Shell dispatch code, and its
real behavior is sharp enough to silently produce dead buttons and invisible cards if you assume
`"actor"`/`"receiver"` resolve the way their names suggest.** A binding covering a state, passing the
validator, and even satisfying `no_render_binding_for_reachable_state` does **not** mean a guard-permitted
persona can actually reach it — role resolution is a separate, undocumented-until-now failure mode
(confirmed by reading `part27_engine_native_binding_dispatcher.dart`, `part32_engine_native_list_surface.dart`,
`part28_engine_native_calendar_surface.dart`, `part36_engine_native_marketplace_surface.dart`):

| Tab | Resolution | Practical effect |
|---|---|---|
| `admin` | `instance.createdByPersonaId == viewer` → `"actor"`; everyone else → `"receiver"` | The **only** tab where `role: "receiver"` ever resolves to anything. |
| `giving`, `home`, `messages`, `marketplace` | `instance.createdByPersonaId == viewer` → `"actor"`; everyone else → **nothing** | `role: "receiver"` can **never** resolve here — a `"receiver"` binding on these tabs is permanently dead, no matter what the guard allows. |
| `calendar` | No role callback is passed at all — always resolves to nothing | **Neither** `"actor"` nor `"receiver"` ever resolves — only `role: "any"` (or `"receiver"` + `audienceMemberField` + a dynamic-audience instance, per `binding_resolver.dart`) can render anything on Calendar. |

Two consequences that have each caused real, shipped bugs:

1. **`"actor"` means literal `createdByPersonaId`, not "whoever the transition's guard is really about."** A
   workflow where persona X *creates* an instance on behalf of persona Y (e.g. the board creates a dues
   charge that a homeowner must pay, `payerPersonaId` ≠ `createdByPersonaId`) will resolve `"actor"` to the
   *creator* (board), never the business-relevant persona (the payer) — even though the payer is exactly who
   the transition's own `guard.actorEqualsField` names. A `role: "actor"` binding in this situation is a dead
   card for the very persona the transition exists for.
2. **`role: "receiver"` is a trap outside `admin`.** It reads as "the other participant" and is easy to reach
   for whenever a workflow has two personas, but on `giving`/`home`/`messages`/`marketplace`/`calendar` it
   silently never resolves — the binding parses, validates, and produces zero errors or warnings, and the
   card or button it was meant to expose simply never appears for anyone.

**What to do about it, until this becomes an engine-level fix or a validator rule:** on every tab except
`admin`, default to `role: "any"` whenever a binding needs to be visible/actionable to a persona that isn't
guaranteed to be the instance's literal creator — `"any"` is the only selector these tabs can reliably
resolve for a non-creator. The transition's own `guard` still restricts who can actually press a button;
widening the binding's `role` to `"any"` only affects who can *see the card*, never who can *act on it*. Only
reach for `"actor"`/`"receiver"` on non-`admin` tabs when you've confirmed the persona you need really is
always `createdByPersonaId` for every instance of that type.

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

## `styleField` — data-driven card style/color selection (PROPOSED, 2026-07-23)

```jsonc
"styleField": "cardStyleId"
```

`styleField` names a `number`-typed field in this workflow's own `instanceDataSchema` whose per-instance
value selects which of a small, fixed set of App Shell-owned visual style slots this card renders with —
instead of every instance on a tab rendering in the same single, flat community/tab accent. The field is
ordinarily a computed (`formula`-typed) field, not a stored one, so the mapping logic lives entirely in
the workflow's own JSON and re-evaluates on every read, e.g.:

```jsonc
"category": { "type": "text", "writableBy": "formEntry", "storage": "inline", "displayContexts": [] },
"cardStyleId": {
  "type": "number",
  "formula": "if(category == 'tournament', 1, if(category == 'social', 2, 0))",
  "displayContexts": []
}
```

**No new formula function is required for this.** Nested `if()` already maps a label value to a number
— the identical pattern already proven elsewhere in this spec (see `tournament-ballot.dueAt`'s
`reminderOffset`-to-hours mapping in the frozen fixture). `styleField` only needs the workflow author to
compose already-implemented vocabulary; the engine change is zero.

**Why a field name, not an inline value:** the mapping formula is entirely the workflow author's own
business logic (which categories exist, which slot each maps to) — `styleField` only tells the App Shell
*where to look*, mirroring how `responseTable.eventField` and `filterableFacets[].field` are pointers to
workflow-owned fields rather than inline copies of workflow-owned logic.

**Resolution (not yet App-Shell-implemented — see `spec-version.json` →
`proposedNotImplemented.styleFieldBinding`):** the archetype reads
`instanceData[binding.styleField] ?? 0` and looks up that integer (mod the palette size) in a small,
fixed palette of `LoomCardTheme` variations *derived from the same community/tab accent already resolved
for this binding* (e.g. via systematic hue/lightness variation) — never a new, unrelated, hardcoded
color. When `styleField` is absent, behavior is unchanged: today's single flat accent.

**Validation:** `styleField` must name a declared, `number`-typed field in this workflow's own
`instanceDataSchema`. → `dangling_style_field` (error)

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

## `actions` — archetype-owned actions (GAP-2, grammar v2)

An `actions` array declares the actions an archetype card offers. It **replaces the flat `creatable`
object** from grammar v1: a single member-create affordance is now one entry (`kind: "create"`) in this
array. The array shape exists so an archetype can own more than one action, and so each action can choose
independently whether it renders as a button on the card or as a FAB, and whether it operates on a
brand-new instance (tab scope) or one related to a specific existing instance (instance scope).

**Two action kinds, one shape.** `kind: "create"` makes a brand-new instance of some workflow type.
`kind: "transition"` names an **already-declared** `transitions[]` entry on this binding's own workflow
type and gives it a distinguished presentation (a FAB, or a visually separated button) instead of leaving
it in the archetype's automatic button row. Every other transition on the type keeps rendering
automatically via `availableTransitions` exactly as it always has — declaring one transition as an action
does not require declaring the rest, and **removes only that one** from the automatic row (never both,
to avoid two affordances for the same action).

```jsonc
"actions": [
  // Tab-scoped create: a brand-new instance from nothing. Renders as a tab FAB.
  { "kind": "create", "label": "New event",
    "byPersonaIds": ["tabletop-organizer"],
    "scope": "tab", "presentation": "fab" },

  // Instance-scoped create of a DIFFERENT workflow type, owned by THIS archetype's card.
  // Renders as a button on each card; {context.id} is that card's own instance id.
  { "kind": "create", "workflowType": "tournament-ballot",
    "label": "Create ballot for this tournament",
    "byPersonaIds": ["tabletop-organizer"],
    "scope": "instance", "presentation": "button",
    "prefill": { "eventId": "{context.id}" } },

  // Transition, pulled out of the automatic row into its own contextual FAB.
  // "borrow" stays a normal declared transition with its own guard/effects; this entry
  // only changes how it presents. No byPersonaIds/workflowType/prefill — the transition's
  // own guard is still the sole eligibility check, same as when it rendered in the row.
  { "kind": "transition", "transitionId": "borrow", "label": "Request loan",
    "presentation": "fab" }
]
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `kind` | string | **yes** | `create` or `transition`; the enum is the extension point for future action kinds. |
| `label` | string | `create`: **yes** · `transition`: no | The affordance's button/FAB text. For `transition`, defaults to that transition's own declared `label` if omitted. |
| `byPersonaIds` | string[] | `create`: **yes** · `transition`: n/a | Personas allowed to invoke a `create` action. **Not applicable to `transition`** — a transition's own `guard.allowedPersonaIds` is already the single source of truth for who may invoke it; setting `byPersonaIds` here would be a second, driftable copy of that same fact. |
| `workflowType` | string | no; n/a for `transition` | For `kind: "create"`, the type to create. **Defaults to the binding's own workflow type.** Set it only for the cross-archetype case — an action on the tournament-event card that creates a `tournament-ballot`. **Not applicable to `transition`** — a transition always acts on its own binding's workflow type. |
| `transitionId` | string | `transition`: **yes** · n/a for `create` | Names a `transitions[].id` already declared on this binding's own workflow type. |
| `scope` | string | no | `create` defaults to `tab` (`tab` or `instance`). `transition` **must** be `instance` (the default; a transition always acts on an existing instance — there is nothing to transition before one exists). |
| `presentation` | string | no | `fab` (default) or `button`. How the action's affordance renders. |
| `prefill` | object | no; n/a for `transition` | `create` only. Field → value map, pre-filling the creation form. Values use the effect interpolation grammar plus `{context.*}` (instance scope only). Use `inputs` (below) for a `transition` action instead. |
| `inputs` | object | no; n/a for `create` | `transition` only. Field → value map passed to `applyTransition` as that transition's own `inputs` (see [`effects.md`](./effects.md) `{input.x}`). Keys must match names the named transition itself declares under its own `inputs`. Values may use `{context.<field>}` — the host/in-focus instance's own current field, self-referenced as an input (e.g. carrying one of its own fields into the transition's effects). Use `prefill` (above) for a `create` action instead. |

**Scope is the whole model for `create`; fixed for `transition`.** Every other field's behaviour
follows from it:

| | `scope: "tab"` (create only) | `scope: "instance"` |
|---|---|---|
| Applies to | a brand-new top-level instance, unrelated to anything on screen | `create`: an instance **related to** one specific existing instance. `transition`: the existing instance being transitioned. |
| Renders as | always a tab-level FAB (a `presentation: "button"` on a tab-scoped action is a validator error — there is no card to put it on) | `button` → an affordance on each host card; `fab` → a contextual FAB whose context is the **in-focus** host card |
| Context (`{context.*}`) | none — any `{context.*}` in `prefill` is a validator error | resolved from the host instance: `button` uses that card's own instance; `fab` uses the in-focus instance (the App Shell's existing focus tracker) |
| Visible when zero instances of the host type exist? | yes — creation-from-nothing must always be reachable | no — there is no instance to own or contextualise the action |

**`{context.*}` resolution (instance scope only, both kinds):**
- `{context.id}` — the host instance's own id. (A `tournament-ballot`'s `eventId` = the tournament
  instance's id, so `"eventId": "{context.id}"` on a tournament-event-owned action is exactly right.)
- `{context.<fieldName>}` — the host instance's `instanceData[<fieldName>]` value.

For `create`, `context` refers to the *host* instance the action was invoked from — never the created
type, and never readable outside `prefill`. For `transition`, `context` **is** the instance being
transitioned (there is only one instance in play), so `{context.<fieldName>}` inside `inputs` is a
self-reference to that same instance's own current data.

**Creation semantics (load-bearing, unchanged from v1):** a `create` action renders a form for the target
state's `editableFields`, collects values, merges in the resolved `prefill`, **then** calls
`createInstance` — never a blank instance first. Every `required`, non-computed field of the created type
must appear in that state's `editableFields` **or** be supplied by `prefill`, or the created instance
would be invalid on arrival. A `prefill`-supplied field need not be in `editableFields` (that is exactly
how a hidden, context-derived field like `eventId` is populated without showing the user an editor).

**Transition-presentation semantics:** a `transition` action does not create a second way to invoke the
transition — it **replaces** the transition's row-button presentation with the declared one. The named
transition's own `guard`/`effects`/`inputs` declaration is completely unchanged; only *where and how* it
renders differs. This is why `byPersonaIds`, `workflowType`, and `prefill` are inapplicable here: nothing
about eligibility or target type changes, only presentation.

**Validator checks:** `byPersonaIds` against the known persona registry (`dangling_allowed_persona_id`,
warning); `workflowType` (when present) must name a declared workflow (`dangling_action_workflow_type`);
`kind` must be a known action kind (`unknown_action_kind`); `scope`/`presentation` must be known enum
values (`unknown_action_scope`/`unknown_action_presentation`); `presentation: "button"` with `scope:
"tab"` is an error (`tab_action_cannot_be_button`); `prefill` keys must be declared in the *created*
type's `instanceDataSchema` (`dangling_instance_data_key`) and must not target a computed field
(`computed_field_written_by_effect`); a `{context.*}` value on a `scope: "tab"` action, or anywhere other
than inside an instance-scoped action's `prefill`/`inputs`, is an error
(`context_reference_outside_instance_action`). For `kind: "transition"`: `transitionId` must name a
transition declared on this binding's own workflow type (`dangling_action_transition_id`); `scope:
"tab"` is an error (`transition_action_cannot_be_tab_scoped`); a present `workflowType`, `prefill`, or
`byPersonaIds` is an error (`transition_action_cannot_set_workflow_type` /
`transition_action_cannot_set_prefill` / `transition_action_cannot_set_by_persona_ids`); an `inputs` key
not declared under the named transition's own `inputs` is an error (`unknown_action_input_reference`);
two `transition` actions on the same binding naming the same `transitionId` is an error
(`duplicate_action_transition_id`). Symmetrically, `inputs` on a `kind: "create"` action is an error
(`create_action_cannot_set_inputs` — use `prefill`).

## `creatableAction` / `tabCreatableActionStyles` — resolving multiple tab-scoped `create` actions on one tab, and how the launched form presents (IMPLEMENTED, CALR.3g/3h/3b)

**Not a binding-object key** — these live on the top-level `experience` object, one level up, following the
same community → tab cascade already used by `theme`/`tabThemes` (one community-level object, one
per-tab override map of the same shape, each of the object's fields resolving independently). They govern
only **tab-scoped** actions (`actions[]` entries with `scope: "tab"`, which render as the tab FAB):
nothing else in the grammar says what happens when **two or more** workflow types contribute a
`scope: "tab"` create-action to the **same** `tabId` (e.g. Calendar carrying both `event-rsvp`'s "New
event" and `tournament-event`'s "New tournament"), nor how the tapped action's own form should be
presented. Instance-scoped actions (`scope: "instance"`) are unaffected by these fields — a `button`
renders inline on its card and a contextual `fab` presents its form the same `presentationStyle` way, but
their button-vs-FAB layout is decided per-action by `presentation`, not by `multiActionStyle`.

```jsonc
"experience": {
  ...
  "creatableAction": {
    "multiActionStyle": "speedDial",     // optional, default "speedDial". One of: "speedDial" | "stacked" | "singleFirst"
    "presentationStyle": "popup"          // optional, default "popup". One of: "popup" | "slideOutBottom" | "slideOutLeft" | "slideOutRight"
  },
  "tabCreatableActionStyles": {           // optional, per-tab override — same two fields, each independently optional
    "calendar": {
      "presentationStyle": "slideOutBottom"
      // multiActionStyle omitted -> falls back to creatableAction.multiActionStyle above
    }
  },
  ...
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `creatableAction` | object | no | Community-wide defaults for both fields below. |
| `creatableAction.multiActionStyle` | string | no | How multiple tab-scoped `create` actions on one tab lay out relative to each other. One of `speedDial` \| `stacked` \| `singleFirst`. |
| `creatableAction.presentationStyle` | string | no | How the tapped action's own archetype card surface (in creation mode) is presented. One of `popup` \| `slideOutBottom` \| `slideOutLeft` \| `slideOutRight`. |
| `tabCreatableActionStyles` | object | no | `{ "<tabId>": { ...same two fields, each optional... } }` — overrides one or both of `creatableAction`'s fields for one specific tab. |

**Resolution rule — each field resolves independently**, identical cascade shape to how `theme`/`tabThemes`
resolve a card's visual theme:
```
tabCreatableActionStyles[tabId]?.multiActionStyle  ?? creatableAction.multiActionStyle  ?? "speedDial"
tabCreatableActionStyles[tabId]?.presentationStyle ?? creatableAction.presentationStyle ?? "popup"
```
A tab overriding only `presentationStyle` still inherits `multiActionStyle` from the community default —
the two fields are independent, not an all-or-nothing override.

## `notificationPresentation` — which generic style renders per-persona `notification` instances (PROPOSED, Notifications Experience phase, CAL.Notify2.2)

**Not a binding-object key** — lives on the top-level `experience` object, same convention as
`creatableAction` above (a community-wide default; a future per-tab override map would follow the exact
same `tabNotificationPresentation`-shaped cascade if a community ever needs one, but isn't part of this
initial grammar since no real use case has needed it yet). Governs how instances of the `notification`
workflow type (guards.md's `actorEqualsField`, effects.md's `transitionRelated.onSuccessEffects` — see
those for how a notification instance gets created in the first place) are actually surfaced to their
recipient. Deliberately NOT another `renderBindings[].tabId` entry: a `notification` instance has no
`eventDate`/list-position/etc. of its own, so routing it through any date-grid or position-ordered surface
(Calendar's own `_CalendarEntry` projection, confirmed directly, unconditionally requires a valid
`eventDate` on every instance it renders) breaks. `notificationPresentation` instead selects one of four
purpose-built, generic, archetype-agnostic rendering styles — usable by any community regardless of which
workflow types actually create notifications.

```jsonc
"experience": {
  ...
  "notificationPresentation": {
    "style": "bell"   // one of: "bell" | "dedicatedTab" | "fixedCard" | "fab"
  },
  ...
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `notificationPresentation` | object | no | Community-wide notification rendering choice. Absent means `"bell"` (the default). |
| `notificationPresentation.style` | string | no | One of `bell` \| `dedicatedTab` \| `fixedCard` \| `fab`. |

| Style | Where it renders | Shape |
|---|---|---|
| `bell` (default) | Shared AppBar, every tab | Icon + unread-count badge, opens a bottom-sheet panel listing notifications (mark-read on tap). Community-wide chrome, not tied to any one tab. |
| `dedicatedTab` | Its own app-shell tab (`appShellConfiguration['tabs']`, not a `renderBindings[].tabId`) | A bespoke, always-scrollable list — the whole tab IS the notification inbox. |
| `fixedCard` | Pinned to the top of one specific tab's own content column | A persistent card above that tab's normal (e.g. date-grid) content — the one style that's genuinely tab-scoped rather than global. |
| `fab` | A FloatingActionButton (own or shared with a tab's existing creatable-action FAB) | Same bottom-sheet panel as `bell`, triggered from a FAB instead of an AppBar icon — for a tab whose AppBar is already crowded. |

All four are real, independently implemented and tested (CAL.Notify2.3-.6) — a community isn't limited to
whichever one Tabletop Club happens to activate (`bell`, chosen because it needs zero Calendar-specific UI
and is the most universally-expected pattern). PROPOSED overall until CAL.Notify2.2 ships the parsing side;
each individual style's own PROPOSED/IMPLEMENTED status is tracked in `spec-version.json`.

**The three `multiActionStyle` values:**
- `speedDial` — the FAB, when tapped, expands into a small radial/stacked burst of labeled mini-actions,
  one per matching tab-scoped `create` action (reference: Twitter's compose-FAB burst). The standard
  pattern for "one primary action, several related sub-actions"; scales cleanly past two.
- `stacked` — every matching tab-scoped `create` action gets its own always-visible FAB, stacked
  vertically (reference: Google Photos' share-sheet FAB column). Only reasonable for exactly two; gets
  cluttered beyond that — not a substitute for `speedDial` at scale, a deliberately simpler option for the
  two-action case.
- `singleFirst` — only the first matching tab-scoped `create` action (definition order) gets a FAB; the
  rest are not reachable via the FAB at all. A real tradeoff (it hides actions), not merely a simpler
  visual — use deliberately, not as a default.

**The four `presentationStyle` values** — this governs how the archetype card surface for the *tapped*
action's workflow type renders once launched, in creation mode (no backing instance yet — see
`archetypes/README.md` for how an archetype's own `cardSurfaceFamily` dispatch extends to a creation
variant):
- `popup` — a distinct "expand and hover" motion: the form grows outward from the FAB's own screen
  position, hovers over the current screen, then shrinks back down to the FAB on close. This is **not**
  a plain `showDialog` (whose default transition fades/scales from screen-center, not anchored to the
  FAB) — it is Material Design's own named "container transform" pattern. Build it with the official
  Flutter-team `animations` pub package's `OpenContainer` widget (purpose-built for exactly this motion),
  not a hand-rolled `Hero` transition — `OpenContainer` is the correct, low-risk tool for this specific
  effect.
- `slideOutBottom` — a sheet sliding up from the bottom edge (Flutter's `showModalBottomSheet`, fully
  native, no extra dependency).
- `slideOutLeft` / `slideOutRight` — a side panel sliding in from that edge. No single named Flutter
  widget; build with `showGeneralDialog` + a `SlideTransition` from `Offset(-1, 0)`/`Offset(1, 0)` to
  `Offset.zero` — a standard, well-understood pattern using only stock Flutter animation primitives.

**This resolves independently of how many tab-scoped `create` actions exist** — with exactly one match on
a tab, all three `multiActionStyle` values render identically (a single FAB); the distinction only matters
once a second tab-scoped `create` action lands on the same tab. `presentationStyle` applies regardless of
how many actions there are — it governs the launched form, not the FAB itself.

**Implemented** — the tab creatable-action FAB (this whole community→tab cascade, plus all four
`presentationStyle` values and all three `multiActionStyle` values) ships end-to-end as of CALR.3g/3h/3b.
`presentationStyle` also governs instance-scoped contextual FABs' launched forms.

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
| `cardSurfaceFamily` must be a registered archetype | ⚠️ **NOT ENFORCED** as of 2026-08-09 — documented as `missing_template` (warning) but confirmed by direct test that the real validator emits nothing for an invalid value. Cross-check `archetypes/README.md`'s table by hand until this lands in `workflow_validator.dart`. |
| A `primary` binding's surface must include an action-button row | error (`missing_action_button_row`) |
| >32 bindings on one workflow | warning — a smell; likely two workflows |
| >16 distinct roles | warning — same |
| `repeater.itemActions[].inputs`' `{item.x}` must match the source's item shape | error (`unknown_item_reference`) |
| `actions[].byPersonaIds` must be a known persona | warning (`dangling_allowed_persona_id`) |
| `actions[].kind` must be a known action kind | error (`unknown_action_kind`) |
| `actions[].scope`/`presentation` must be known enum values | error (`unknown_action_scope` / `unknown_action_presentation`) |
| `actions[].presentation: "button"` with `scope: "tab"` | error (`tab_action_cannot_be_button`) |
| `actions[].workflowType` (when present) must name a declared workflow | error (`dangling_action_workflow_type`) |
| `actions[].prefill` keys must be declared in the created type's `instanceDataSchema` | error (`dangling_instance_data_key`) |
| `actions[].prefill` must not target a computed field | error (`computed_field_written_by_effect`) |
| `{context.x}` on a `scope: "tab"` action, or outside any instance-scoped action's `prefill`/`inputs` | error (`context_reference_outside_instance_action`) |
| `actions[].transitionId` (kind: transition) must name a transition declared on this binding's own workflow type | error (`dangling_action_transition_id`) |
| `actions[]` with `kind: "transition"` and `scope: "tab"` | error (`transition_action_cannot_be_tab_scoped`) |
| `actions[]` with `kind: "transition"` and a present `workflowType` / `prefill` / `byPersonaIds` | error (`transition_action_cannot_set_workflow_type` / `transition_action_cannot_set_prefill` / `transition_action_cannot_set_by_persona_ids`) |
| `actions[].inputs` key (kind: transition) not declared under the named transition's own `inputs` | error (`unknown_action_input_reference`) |
| Two `kind: "transition"` actions on one binding naming the same `transitionId` | error (`duplicate_action_transition_id`) |
| `actions[]` with `kind: "create"` and a present `inputs` | error (`create_action_cannot_set_inputs`) |
| `responseTable.workflowType` must be declared | error (`dangling_response_table_workflow_type`) |
| `responseTable.eventField` must be declared on that type | error (`unknown_response_table_field`) |
| `responseTable.pendingStates` entries must be declared states of that type | error (`unknown_response_table_state`) |
| `filterableFacets[].field` must be a declared, `formula`-typed field in this schema | error (`dangling_filterable_facet_field`) |
| `styleField` must be a declared, `number`-typed field in this schema | error (`dangling_style_field`) |

## Anti-patterns

| ❌ Wrong | ✅ Right |
|---|---|
| Every workflow bound to `home` "so the user sees it" | Bind to the tab it belongs on. Home is a curated feed, not a dumping ground. |
| Two near-identical workflows for two personas | **One** workflow, two `role`-keyed bindings |
| A `hidden`/`archived` state with a binding, then filtering it out in the UI | Simply declare **no binding** for that state |
| Inventing a `cardSurfaceFamily` | Only values in [`archetypes/README.md`](../archetypes/README.md) exist |
