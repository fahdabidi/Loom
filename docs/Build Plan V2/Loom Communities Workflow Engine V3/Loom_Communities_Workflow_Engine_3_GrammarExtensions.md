# Grammar Extensions — Phase A′ language design (proposal, awaiting sign-off)

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). Finalizes the exact JSON shapes for
**GAP-1, GAP-2 (+ one new addition), GAP-3, GAP-4** — the four gaps registered in
[Language Gaps](./Loom_Communities_Workflow_Engine_3_LanguageGaps.md) — into an implementation-ready
spec, reviewed here **before** Phase A′ writes any code and before the implementation/validation cycle
resumes. Nothing in this doc is implemented yet. Nothing here edits the frozen Tabletop Club JSON;
where an example below matches something already sitting in that JSON, it is cited as evidence the shape
already round-trips through a real authoring exercise, not as a retroactive edit.

## Versioning

**No version bump.** Every addition below is a new optional key, a new optional effect `op`, or a new
formula function — nothing existing changes shape or becomes required. Per
[JSON Schema Versions](./Loom_Communities_Workflow_Engine_JSON_Schema_Versions.md)'s own rule ("additive
changes never bump"), `workflowGrammarVersion` stays at `1`. `spec-version.json`'s `knownGaps` entries
for GAP-1/2/3/4 move to a `resolvedInGrammar` section once this is implemented (not yet).

---

## GAP-1 — Transition `inputs`

**Problem:** a transition cannot receive a value from the member — the only workaround is a shared
scratch field written by a separate `updateInstanceFields` call, then a parameterless transition fired
second. Two calls, racy under concurrency, non-declarative.

**Shape:**

```jsonc
"transitions": [
  {
    "id": "cast-vote",
    "from": ["open"], "to": null,
    "guard": { /* unchanged */ },
    "inputs": { "choice": { "type": "text", "required": true } },
    "effects": [
      { "op": "createInstance", "workflowType": "tournament-vote",
        "fields": { "ballotId": "{id}", "voterId": "$actor", "choice": "{input.choice}" } }
    ]
  }
]
```

- `inputs`: a map of `name → { type, required }`, same `type` vocabulary as `instanceDataSchema` fields
  ([`reference/field-types.md`](../../../references/reference/field-types.md)).
- New interpolation source: `{input.<name>}`, resolvable anywhere `{field}`/`$actor` already resolve
  (effect `value`s, `fields` maps, nested `branch` arms).
- `applyTransition` gains a new parameter carrying the input values for that call; if `required` and
  missing, the engine refuses the same way a missing-required-field currently refuses `createInstance`.

**Per-item action buttons** (so a repeater can render "Vote for {candidate}" without one bespoke button
per candidate):

```jsonc
"renderBindings": [
  { "states": ["open"], "role": "any", "tabId": "home",
    "cardSurfaceFamily": "vote-poll", "bindingKind": "primary",
    "repeater": {
      "source": "candidates",
      "itemActions": [
        { "transitionId": "cast-vote", "inputs": { "choice": "{item.id}" } }
      ]
    } }
]
```

`repeater.source` may be a plain field name on the instance (a list already in `instanceDataSchema`, as
above) **or** a `query(...)` expression (see GAP-4) for a live, cross-instance-bound list. Each
`itemActions` entry names a transition and maps its `inputs` from the repeated item's own fields via
`{item.<field>}`.

**Already exercised in the frozen JSON:** `tournament-ballot.cast-vote` and its `open` binding's
`repeater`/`itemActions` use exactly this shape today (parsed as inert extra keys until this lands —
confirmed via `LoomWorkflowTransition`/`RenderBinding` fromJson, neither field exists on the Dart model
yet).

**Validator additions needed:** `inputs` type-checked against the known type vocabulary; every
`{input.x}` interpolation site checked against a declared input name (new `unknown_input_reference`
finding); `itemActions[].inputs` checked the same way against `{item.x}`.

---

## GAP-2 — `renderBindings[].creatable`, plus contextual pre-fill

**Problem:** no declarative way to say "a member can create a new instance of this type." The only
existing path is `createInstance` as an *effect* of a transition on an *existing* instance — a user
cannot transition into existence.

**Base shape (already used in the frozen JSON, `game-purchase-proposal` and `discussion-thread`):**

```jsonc
"renderBindings": [
  { "states": ["draft"], "role": "actor", "tabId": "home",
    "cardSurfaceFamily": "form-entry", "bindingKind": "primary",
    "creatable": { "byPersonaIds": ["tabletop-member"], "label": "Propose a game" } }
]
```

**Creation semantics (load-bearing, restated from Language Gaps):** the affordance renders a form for
the `initialState`'s `editableFields`, collects values, **then** calls `createInstance` — never creates a
blank instance first. Validator rule `creatable_missing_required_field`: every `required`, non-derived
field of the type MUST appear in `initialState.editableFields`, or a created instance is invalid on
arrival.

**New addition — `prefill`, for the Calendar day-detail "add event" case:**

```jsonc
"creatable": {
  "byPersonaIds": ["tabletop-member", "tabletop-organizer"],
  "label": "Add event",
  "prefill": { "eventDate": "{context.date}" }
}
```

- `prefill`: a map of `field → value`, using the **same interpolation grammar** as effects (`$actor`,
  literals) plus a **new source, `{context.<key>}`** — supplied by the *caller* of the creation flow, not
  read from any instance. The App Shell's day-detail route, when rendering "Add event" for July 20th,
  invokes creation with `context: { "date": "2026-07-20" }`; `{context.date}` resolves against that.
- If the pre-filled field is in `editableFields`, the form shows it already populated (the member can
  still change it). If it is **not** in `editableFields`, it is set silently, with no form control — the
  same way `createdByPersonaId` is normally set via `$actor` without a form field for it.
- `context` is scoped entirely to a single creation invocation; it is not persisted, not an instance
  field, and not readable from anywhere else. It exists only to answer "where in the app did the member
  tap 'create'?"

**Why this is the right fix, not a Calendar-specific hack:** any future "create X, scoped to Y" pattern
(a proposal created from a specific meeting's agenda, a loan request pre-scoped to a specific listing)
needs the identical mechanism — this is one general addition, not a day-detail-specific one.

**Validator additions needed:** `prefill` keys checked against the target's declared
`instanceDataSchema` (same check as `createInstance.fields`); `{context.x}` interpolation is only valid
inside `creatable.prefill`, nowhere else (a new `context_reference_outside_creatable` finding if misused).

---

## GAP-3 — "All participants except the actor"

**Problem:** no set-difference effect; thread `unread` is a single bool instead of per-persona.

**Shape:**

```jsonc
{ "op": "setFromFormula", "key": "unreadPersonaIds", "formula": "removeAll(participantPersonaIds, $actor)" }
```

- New effect op `setFromFormula`: evaluates `formula` (same evaluator as `instanceDataSchema[].formula`,
  same restricted function set) against the instance's current data plus `$actor`/`$viewer`, and writes
  the result to `key` — a formula-effect hybrid, but still an *effect* (runs once, at transition time),
  not a live-recomputed *formula* field.
- New formula function `removeAll(list, value)`: returns `list` with every occurrence of the scalar
  `value` removed. (Deliberately narrow — not a general set-difference over two lists; every known use
  case is "remove one actor from a list.")

**Still degraded, not fully fixed:** this makes `unreadPersonaIds` an honest per-persona list, but
computing "is unread **for the current viewer**" still requires a formula like
`contains(unreadPersonaIds, $viewer)` — fine, already expressible — so this closes the gap completely
once applied; no further grammar change needed here.

**Validator additions needed:** `setFromFormula`'s `formula` validated exactly like a schema-field
formula (same `_checkFormulaString` reuse Ticket A already built); `removeAll` added to
`formulaFunctionNames`.

---

## GAP-4 — Query-backed `source` fields: execute the query, not just preserve it

**Current state (A.5, already landed):** `InstanceDataField.source` is parsed and preserved through
reload; a formula depending on an unpopulated `source` field is deferred rather than crashing or
false-positiving. **The query itself is never executed.** This is the remaining half.

**Shape (unchanged from the original proposal — this section specifies execution semantics for syntax
that already exists in the model):**

```jsonc
"ballots": { "type": "list", "source": "query(tournament-vote where ballotId == id)" }
```

**Bounded query grammar — deliberately minimal, matching this codebase's "small fixed vocabulary, no
arbitrary execution" philosophy** (the same reason the formula evaluator has a fixed function set with
no dynamic code):

```
source := "query(" workflowType " where " foreignField " == " localField ")"
```

- `workflowType` MUST be a declared type.
- `foreignField` MUST be a declared field on that type.
- `localField` MUST be `id` (this instance's own id) or a declared field on **this** type.
- Only `==` is supported. No compound conditions, no other operators, no nesting. If a real need for
  more ever appears, that is a new, separate gap to propose — not silently widened here.

**Execution:** at read time (`queryInstances`, `availableTransitions(Async)`, and anywhere else instance
data is materialized for the caller), for every field with a `source`, the engine runs the equality
query against its own store and populates the field with the **full `instanceData` of every matching
instance** (not just ids — `groupCount(ballots, choice)` needs to read each matched row's `choice`).
Same engine machinery `aggregate`/`queryInstances` already use; this is not new query infrastructure, it
is wiring an existing capability into the read path for one more field kind.

**Validator additions needed:** `source` query syntax parsed and checked at validation time
(`workflowType`/`foreignField`/`localField` existence — the same checks `CommunityPackageValidator`
already does for cross-instance `relatedInstance` references); a `source`-backed field remains treated
as derived everywhere `formula` fields already are (cannot be seeded, cannot be form-edited, cannot be
effect-written) — `computed_field_seeded`/`computed_field_written_by_effect` should fire for `source`
fields too, not just `formula` fields (check whether the existing checks already key off "has formula OR
source" — if not, this is a one-line validator fix alongside the rest).

---

## Summary of new grammar surface

| Addition | Where | Closes |
|---|---|---|
| `transitions[].inputs` | transition | GAP-1 |
| `{input.<name>}` interpolation | effect values/fields | GAP-1 |
| `renderBindings[].repeater.itemActions` | render binding | GAP-1 |
| `renderBindings[].creatable` | render binding | GAP-2 |
| `renderBindings[].creatable.prefill` + `{context.<key>}` | render binding | GAP-2 (new) |
| Effect op `setFromFormula` | effect | GAP-3 |
| Formula function `removeAll(list, value)` | formula | GAP-3 |
| Execution of `instanceDataSchema[].source` `query(...)` | engine read path | GAP-4 |

All additive. `workflowGrammarVersion` stays `1`.

## Sign-off

- [x] **Approved as specified — 2026-07-15.** User directive: "go ahead and start the
      validation/implementation cycle... attempt to autonomously complete all the implementation for the
      next tabletop community implementation phase" — Phase A′ is next in the tracker's phase index
      (§4) and is fully designed here with no outstanding open question, so this is treated as approval
      to proceed to implementation, bundled as one ticket covering GAP-1 + GAP-2 (+ the `prefill`
      addition) + GAP-4 together (all three touch the same `loom_workflow_engine`/`loom_ux_judges`
      surface and are small enough individually that splitting them would just add handoff overhead).
- [ ] Approved with changes — see inline comments/follow-up discussion.
- [ ] Not approved — needs further design.

Once implemented and independently verified, `spec-version.json`'s `knownGaps` entries update to reflect
closure, and `docs/references/reference/{effects.md, guards.md, render-bindings.md, field-types.md}` get
amended to document the new surface — per the publishing flow. That publishing-flow pass happens **after**
the implementation ticket below is verified, not before — see the ticket itself
(`data/v3_ticket_aprime_grammar_extensions.md`) for the exact dispatch.
