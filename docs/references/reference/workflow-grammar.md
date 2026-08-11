---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.6.0
status: current
last_verified: 2026-08-09
derived_from: app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart
---

# Workflow grammar (normative) — grammar v1

**The contract.** Every key here is one the engine's parser genuinely reads
(`LoomWorkflowStateMachine.fromJson`, `workflow_models.dart:341-371`) and the engine genuinely executes.
Nothing is aspirational.

**If this doc and the code disagree, the code wins** — and that is a bug in this doc, to be fixed via the
[publishing flow](../_meta/publishing-flow.md).

## Shape of one definition

```jsonc
"workflowDefinitions": {
  "<workflowType>": {                  // the map key IS the workflowType; not repeated inside
    "initialState": "<stateName>",     // REQUIRED. Must be a key of `states`.
    "states":       { /* ... */ },     // REQUIRED. Non-empty.
    "transitions":  [ /* ... */ ],     // REQUIRED. May be empty [] (a terminal-only type).
    "renderBindings":     [ /* ... */ ],  // optional, defaults []
    "instanceDataSchema": { /* ... */ },  // optional, defaults {}
    "visibility":         { /* ... */ }   // optional — see "visibility / readGuard" below. Defaults to public.
  }
}
```

⚠️ **`workflowType` is the map key**, passed into `fromJson` separately. Do not add a `workflowType`
field inside the object — it is ignored.

## `visibility` / `readGuard` — who may read instances of this type

✅ **IMPLEMENTED** (`WorkflowVisibility`/`WorkflowVisibilityDefault`, `workflow_models.dart:471-538`) —
genuinely enforced read-path filtering in `local_workflow_engine_api.dart` (`queryInstances`/`aggregate`
scoping, ~lines 340-392), not advisory. Found missing from this doc entirely 2026-08-09 while comparing a
Skill-authored package against `guide/05-validation.md`'s `no_read_visibility_declared` warning, which was
the only place this construct was mentioned anywhere in `docs/references`.

```jsonc
"visibility": {
  "default": "public",              // "public" | "membersOnly" | "guarded". Default if omitted: "public".
  "readGuard": { "allowedPersonaIds": ["hoa-board"] }   // REQUIRED sibling when default is "guarded".
                                                          // Same WorkflowGuard shape as editGuard/creationGuard.
}
```

| `default` value | Who may read an instance of this type |
|---|---|
| `public` (or `visibility` omitted entirely) | Anyone — today's default, unchanged behavior for every existing community that doesn't declare this key. |
| `membersOnly` | Any signed-in, active-status account for this community. |
| `guarded` | Must also pass the sibling `readGuard` (a `WorkflowGuard`, evaluated per-instance) — **and requires `readGuard` to be present, or parsing fails** (`workflow_models.dart:528-532`). |

**Per-state override:** a `states.<stateName>.readGuard` (same `WorkflowGuard` shape) takes precedence
over the workflow-level `visibility.readGuard` for instances currently in that state — evaluated as
`stateGuard ?? machine.visibility.readGuard` (`local_workflow_engine_api.dart:388-389`). This lets a type
be `guarded` overall but relax (or further restrict) which persona can read a specific state, e.g. a
`published` state opening up to `membersOnly` while `draft` stays board-only.

**Validator:** `no_read_visibility_declared` (warning only, `guide/05-validation.md`) fires whenever a
workflow type omits `visibility` entirely — it never blocks `report.passed`, since the omitted-default
(`public`) is legitimate and matches every pre-existing community's actual behavior.

---

## `states`

```jsonc
"states": {
  "open":      { "label": "Signups open", "tone": "positive",
                 "editableFields": ["title", "capacity"],
                 "editGuard": { "allowedPersonaIds": ["tabletop-organizer"] } },
  "cancelled": { "label": "Cancelled", "tone": "negative", "isTerminal": true }
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `label` | string | **yes** | Human-readable state name, shown in the UI |
| `tone` | string | no | Visual tone: `positive` · `negative` · `warning` · `info` |
| `editableFields` | string[] | no | Fields the user may edit **while in this state** |
| `editGuard` | `WorkflowGuard` | no | Gates *who* may use `editableFields` — same shape as `transitions[].guard` (see below) |
| `creationGuard` | `WorkflowGuard` | no | Gates whether a **new instance** may be created into this state at all — see below. PROPOSED, not yet implemented. |
| `isTerminal` | bool | no (default `false`) | No transitions may leave this state |

✅ **IMPLEMENTED 2026-07-25 (CALR.10a)** — see `spec-version.json`'s `resolvedInGrammar.editGuard`.
`LoomWorkflowState.editGuard` parses as a nullable `WorkflowGuard?`, and Calendar's real detail card
(`_EventRsvpDetailCard`) reads it before rendering editors, matching the deviation rule below exactly.

**`editGuard` is a call-site-specific deviation from guards.md's normal "absent guard means anyone,
always" semantics.** `editGuard`'s *type* is exactly `WorkflowGuard` (see guards.md) — no new guard
shape — but the App Shell's "should I render `GenericWorkflowInstanceCard`'s editors" check MUST require
`editGuard` to be present (non-null) before evaluating it or showing any editor, full stop. An *absent*
`editGuard` means editing is not exposed at all for that state, not "anyone may edit." This differs from
every other `WorkflowGuard` use (transitions), where an absent guard already means open, because a
transition that isn't declared simply has no button — there's no equivalent "not declared" state for
`editableFields` once it's non-empty, so defaulting open would silently widen permissions.

⚠️ **`creationGuard` — PROPOSED 2026-07-25 (CAL.Calendar2.0/2.9 design pass), not yet implemented.** Found
during the CAL.Calendar2 audit: `createInstance`/`createInstances` (`local_workflow_engine_api.dart`,
`_createInstanceValidated`) run zero guard checks today — only schema validation (`_validateSeedData`).
Guards have only ever gated *transitions*. `creationGuard` closes this for the one case that genuinely
needs it: `guards.md`'s new `locationOverlap` kind must be checked before a conflicting instance is ever
persisted, not after. Same `WorkflowGuard` type as `editGuard` — no new guard shape.

**`creationGuard`'s absent-default is the OPPOSITE of `editGuard`'s.** An absent `creationGuard` means
"anyone may create, always" — the *normal* guards.md default — not "no creation allowed." This is
deliberate: almost no workflow type will ever declare one, and every existing "New X" FAB across every
community depends on creation staying open by default. `editGuard`'s inverted default exists specifically
*because* exposing edit UI is the riskier direction to default open; creation is not analogous — it already
works everywhere today with no guard at all, so introducing the key must not silently change that.

`creationGuard` is checked by `_createInstanceValidated` — the one shared choke point behind
`createInstance`, `createInstances`, **and** every occurrence `generateRecurringInstances` spawns — so a
`locationOverlap` guard declared here automatically covers recurring-series siblings too, with no separate
plumbing.

### Rules the validator enforces

- **Every non-terminal state must have ≥1 outgoing transition.** Otherwise it is a **stuck state** — an
  instance reaches it and can never leave, and the UI shows no buttons. → `stuck_state` (error)
- **Every state must be reachable** from `initialState` via some transition path. →
  `unreachable_state` (error)
- **`editableFields` may only name fields whose `writableBy` is `"formEntry"`.** A field written by an
  effect is not user-editable, and listing it is a contradiction. → `effect_field_in_editable_fields`
  (error)
- **`editGuard.allowedPersonaIds`, if present, must name declared personas.** (proposed rule,
  `dangling_edit_guard_persona` — not yet implemented, see `spec-version.json`)
- **`creationGuard`, if present, must be a well-formed `WorkflowGuard`** — every field-name it references
  (e.g. `locationOverlap.locationField`) must be declared in this workflow's own `instanceDataSchema`.
  (proposed rule, `dangling_creation_guard_field` — not yet implemented)

> The stuck-state check exists because of a real shipped bug: a `queued` marketplace state with zero
> declared transitions, so queued listings had **no buttons at all**. It reached a live emulator walk
> before anyone noticed. The validator now catches it at author time.

---

## `transitions`

```jsonc
{
  "id": "rsvp-going",              // REQUIRED, unique within this workflow
  "label": "I'm going",            // REQUIRED, non-empty — this is the button text
  "icon": "event_available",       // optional, Material icon name
  "tone": "primary",               // optional: primary | secondary | destructive
  "from": ["open"],                // REQUIRED, non-empty. Source states.
  "to": null,                      // target state, or null (see below)
  "guard": { /* ... */ },          // optional — see reference/guards.md
  "effects": [ /* ... */ ],        // optional — see reference/effects.md
  "linkedWorkflowId": "some-type", // optional — fires a linked action surface
  "inputs": { /* ... */ }          // optional — see "transitions[].inputs" below
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `id` | string | **yes** | Unique within the workflow |
| `label` | string | **yes** | Button text. Empty → `missing_label` (error) |
| `icon` | string | no | Material icon name |
| `tone` | string | no | `primary` · `secondary` · `destructive` |
| `from` | string[] | **yes** | Source states. All must exist. |
| `to` | string\|null | no | Target state, or `null` for **orthogonal** |
| `guard` | object | no | Who/when. [guards.md](./guards.md) |
| `effects` | object[] | no | What changes. [effects.md](./effects.md) |
| `linkedWorkflowId` | string | no | Opens a linked confirmation/action surface |
| `inputs` | object | no | Organizer-entered values, collected in a dialog. See below. |

### `transitions[].inputs`

✅ **IMPLEMENTED 2026-07-26 (CAL.Calendar2.1, commit `58cba6f`)** — `GenericTransitionInputDialog`
(`part26_generic_instance_card.dart`) and every field below are real and independently verified end-to-end,
including `make-recurring`'s full migration off its old bespoke picker.

A map of input name → spec. When present and non-empty, firing the transition first shows a
generic, schema-driven dialog (App-Shell's `GenericTransitionInputDialog`) that collects one value
per entry before the transition is applied. Collected values are available to `effects` as
`{input.<name>}` (see [effects.md](./effects.md)).

```jsonc
"inputs": {
  "freq": { "type": "text", "required": true },
  "byDayOfWeekWeekly": {
    "type": "list",
    "options": ["MO", "TU", "WE", "TH", "FR", "SA", "SU"],
    "visibleWhen": "freq == 'weekly'",
    "writesTo": "byDayOfWeek"
  },
  "byDayOfWeekMonthly": {
    "type": "list",
    "options": ["MO", "TU", "WE", "TH", "FR", "SA", "SU"],
    "maxSelections": 1,
    "visibleWhen": "freq == 'monthly'",
    "modeGroup": "monthlyPattern",
    "modeValue": "lastOrNthWeekday",
    "writesTo": "byDayOfWeek"
  }
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `type` | string | **yes** | `text` · `number` · `list`. Governs both the rendered widget and the value's shape. |
| `required` | bool | no | Blocks confirmation until a non-empty value is entered. Default `false`. |
| `options` | string[] | no | Renders as chips instead of a free-text field. `type: "text"` + `options` is single-select (`ChoiceChip`); `type: "list"` + `options` is multi-select (`FilterChip`), producing a `List<String>`. |
| `visibleWhen` | formula | no | Evaluated live against persisted instance data merged with the values entered so far in this dialog (including other inputs' current picks). Hidden inputs contribute nothing to the result. Same formula grammar as guards — see [guards.md](./guards.md). |
| `modeGroup` / `modeValue` | string | no | Groups mutually-exclusive inputs behind one radio choice. All entries sharing a `modeGroup` render together as a `RadioGroup`; an input tagged with `modeGroup`/`modeValue` is only collected when that group's current selection equals its own `modeValue`. |
| `maxSelections` | number | no | Caps a `type: "list"` + `options` (multi-select) input. Selecting past the cap evicts the oldest pick — a UI-side single-select-via-chips convenience, most commonly `1`. Absent means unbounded. |
| `writesTo` | string | no | Overrides the instance-data / `{input.x}` key this entry's value is collected under (default: the entry's own map key). Lets two mode-scoped inputs with different shapes (e.g. different `maxSelections`) share one logical output field — only one is ever visible/relevant at a time, so there is no write collision. |

**Why split `byDayOfWeek` into two inputs above**: its cardinality genuinely differs by mode — weekly
recurrence allows any number of weekdays, but the monthly "last/Nth weekday" mode requires
*exactly* one (`recurrence_evaluator.dart` enforces this: `bySetPos` requires `byDayOfWeek.length
== 1`). Rather than inventing a formula-conditioned cardinality field, cardinality stays a static
per-input property (`maxSelections`) and two mode-scoped inputs share one output key via
`writesTo`.

### `to: null` — orthogonal transitions

**`"to": null` means the top-level state does not change; only `instanceData` does.**

This is not an edge case — it is how most real interactions work:

| Interaction | State change? | `to` |
|---|---|---|
| RSVP going to an open event | No — still `open` | `null` |
| Join a queue for a listing | No — still `published` | `null` |
| Cast a vote in an open ballot | No — still `open` | `null` |
| Post a message in a thread | No — still `open` | `null` |
| Cancel the event | **Yes** → `cancelled` | `"cancelled"` |
| Close the ballot | **Yes** → `closed` | `"closed"` |

**The decision rule:** *can this be true at the same time as other things in the same dimension?* If yes,
it is **data**, and the transition is orthogonal. If it genuinely replaces the previous condition, it is
a **state**.

Getting this wrong produces either a stuck state or a combinatorial state explosion. See
[anti-patterns](../guide/04-antipatterns.md).

---

## `renderBindings`

Where instances of this workflow appear. Full detail: [render-bindings.md](./render-bindings.md).

```jsonc
"renderBindings": [
  { "states": ["open"], "role": "any", "tabId": "calendar",
    "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary" }
]
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `states` | string[] | **yes** | Which states this binding applies to |
| `role` | string | **yes** | `any` · `actor` · `receiver` |
| `tabId` | string | **yes** | `home` / `messages` (always exist, system-guaranteed) or any id this community declares in `appShellConfiguration.tabs[]`/`personaTabs[]` — see [render-bindings.md](./render-bindings.md#tabid--complete-rule) |
| `cardSurfaceFamily` | string | **yes** | Which archetype renders it |
| `bindingKind` | string | **yes** | `primary` (full, interactive) · `summary` (compact) |
| `audienceMemberField` | string | no | Field holding the invited personas, for targeted visibility |

A workflow with **no** bindings for a state simply doesn't render in that state — which is a legitimate
way to hide drafts.

---

## `instanceDataSchema`

The single source of truth for a workflow's data: validation, display, editability, and computation.
Full detail: [field-types.md](./field-types.md).

```jsonc
"instanceDataSchema": {
  "title":      { "type": "text", "required": true, "writableBy": "formEntry",
                  "labelTemplate": "{value}", "displayContexts": ["tile", "detail"] },
  "goingPersonaIds": { "type": "personaId[]", "writableBy": "effect" },
  "goingCount": { "type": "number", "formula": "size(goingPersonaIds)" }   // computed
}
```

Three kinds of field, and the distinction is load-bearing:

| Kind | Declared by | Written by | Seeded in `instanceData`? |
|---|---|---|---|
| **Form-entry** | `writableBy: "formEntry"` | The user, via `editableFields` | Yes |
| **Effect** | `writableBy: "effect"` | Transition effects | Yes |
| **Computed** | `formula: "..."` | **Nobody** — derived on read | **No — error if you do** |

**A computed field must never be seeded and never be written by an effect.** The validator rejects both
(`computed_field_seeded`, `computed_field_written_by_effect`). Storing something you could compute is how
you get a value that is confidently wrong.

---

## Complete worked example

A ballot with cross-instance eligibility, a computed tally, and a real runoff on a tie — every grammar
feature in one definition.

```jsonc
"tournament-ballot": {
  "initialState": "open",

  "states": {
    "open":   { "label": "Voting open", "tone": "positive", "editableFields": ["pendingChoice"] },
    "closed": { "label": "Closed", "tone": "info", "isTerminal": true }
  },

  "transitions": [
    {
      "id": "cast-vote",
      "label": "Vote",
      "from": ["open"],
      "to": null,                                    // voting doesn't close the ballot
      "guard": {
        // Cross-instance: the actor must appear in `goingPersonaIds` on the instance named by
        // THIS instance's `eventId` field. Enforced by the engine, not by hiding a button.
        "relatedInstanceField": "eventId",
        "relatedListField": "goingPersonaIds"
      },
      "effects": [
        { "op": "append", "key": "ballots",
          "value": { "personaId": "$actor", "choice": "{pendingChoice}" } }
      ]
    },
    {
      "id": "close-vote",
      "label": "Close vote",
      "from": ["open"],
      "to": "closed",
      "guard": { "allowedPersonaIds": ["organizer"] },
      "effects": [
        {
          "op": "branch",
          "if": "isTie",
          "then": [
            // A real runoff: spawn a NEW ballot with only the tied candidates.
            { "op": "createInstance", "workflowType": "tournament-ballot",
              "fields": { "eventId": "{eventId}", "candidates": "{tiedCandidates}",
                          "round": "runoff", "ballots": [] } }
          ],
          "else": [
            // Cross-instance write: push the winner onto the EVENT instance.
            { "op": "set", "key": "selectedGame", "value": "{winner}", "relatedInstance": "eventId" }
          ]
        }
      ]
    }
  ],

  "renderBindings": [
    { "states": ["open"],   "role": "any", "tabId": "home",
      "cardSurfaceFamily": "votePoll", "bindingKind": "primary" },
    { "states": ["closed"], "role": "any", "tabId": "home",
      "cardSurfaceFamily": "votePoll", "bindingKind": "summary" }
  ],

  "instanceDataSchema": {
    "eventId":      { "type": "text", "required": true },
    "candidates":   { "type": "list", "required": true },
    "pendingChoice":{ "type": "text", "writableBy": "formEntry" },
    "ballots":      { "type": "list", "writableBy": "effect" },

    // The entire tally/winner/tie logic — five one-line formulas, zero Dart.
    "voteCounts":     { "type": "map",    "formula": "groupCount(ballots, choice)" },
    "winner":         { "type": "text",   "formula": "argMaxKey(voteCounts)" },
    "tiedCandidates": { "type": "list",   "formula": "topKeys(voteCounts)" },
    "isTie":          { "type": "bool",   "formula": "size(tiedCandidates) > 1" }
  }
}
```

Note what is **not** here: no vote-counting code, no tie-detection code, no runoff-creation code. The
`voteCounts`/`winner`/`isTie` formulas and the `branch`/`createInstance` effect *are* the logic.

---

## Validator rules (summary)

Run [the validator](../guide/05-validation.md). It enforces:

| Rule | Severity |
|---|---|
| Non-terminal state with no outgoing transition (`stuck_state`) | error |
| State unreachable from `initialState` | error |
| `from`/`to` naming an undeclared state | error |
| Transition with an empty `label` | error |
| Guard/effect referencing an undeclared `instanceData` key | error |
| Effect writing a computed (`formula`) field | error |
| Computed field seeded in `instanceData` | error |
| `editableFields` naming a non-`formEntry` field | error |
| Formula referencing an unknown field or function | error |
| Circular formula dependency | error |
| Cross-instance reference that doesn't resolve | error |
| `createInstance` targeting an unknown `workflowType` | error |
| `requiresWorkflowsComplete` cycle | error |
| `linkedWorkflowId` not in the loaded set | warning (may be external) |
| >32 `renderBindings` or >16 roles | warning (a smell — likely two workflows) |

## See also

- [guards.md](./guards.md) · [effects.md](./effects.md) · [formulas.md](./formulas.md)
- [field-types.md](./field-types.md) · [render-bindings.md](./render-bindings.md)
- [Common patterns](../guide/03-common-patterns.md) — copyable recipes
