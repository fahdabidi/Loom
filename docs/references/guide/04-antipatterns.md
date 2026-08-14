---
spec: 4
doc_version: 1.2.0
status: current
last_verified: 2026-07-21
audience: llm-agent
---

# Anti-patterns — self-check before emitting

**Run every rule below against the JSON you are about to emit.** Each has a **detection** (mechanical)
and a **fix**.

Every one of these has actually shipped in this codebase. They are not hypothetical.

---

## AP-1 — A "state" that can coexist with other states

**The most damaging modeling error.**

**Detection:** for any two states A and B of the same workflow, ask: *can a real instance be in A and B
at the same time?* If yes → at least one is not a state.

**Symptom:** the state ends up with **no coherent transitions** — you cannot write them, because they
depend on a dimension the state machine doesn't model.

**Real failure:** Marketplace declared `queued` as a state. But an item can be **on loan AND have people
queued** simultaneously. `queued` was therefore declared with **zero transitions** — and queued listings
rendered **no buttons at all**. It reached a live device before anyone noticed.

**Fix:** the coexisting dimension is **data**, not state.

```jsonc
// ❌ WRONG
"states": { "available": {}, "onLoan": {}, "queued": {} }

// ✅ RIGHT — one state; availability + queue are orthogonal data
"states": { "published": { "label": "In library" }, "delisted": { "isTerminal": true } },
"instanceDataSchema": {
  "availabilityState": { "type": "text", "writableBy": "effect" },
  "queuedPersonaIds":  { "type": "personaId[]", "writableBy": "effect" }
},
"transitions": [
  { "id": "borrow", "from": ["published"], "to": null,          // orthogonal
    "guard": { "instanceDataEquals": { "key": "availabilityState", "value": "available" } },
    "effects": [ { "op": "set", "key": "availabilityState", "value": "onLoan" } ] }
]
```

**Rule of thumb:** *per-member* conditions (who's going, who's queued, who voted) are **always** data —
many members differ simultaneously. They are never states.

---

## AP-2 — Storing what you could compute

**Detection:** any field written by `increment`/`decrement`/`set` whose value is derivable from another
field.

**Symptom:** the stored value drifts from reality. A `goingCount` of 7 next to a `goingPersonaIds` of 6.

```jsonc
// ❌ WRONG
"goingCount": { "type": "number", "writableBy": "effect" },
"effects": [ { "op": "appendUnique", "key": "goingPersonaIds", "value": "$actor" },
             { "op": "increment", "key": "goingCount", "value": 1 } ]

// ✅ RIGHT
"goingCount": { "type": "number", "formula": "size(goingPersonaIds)" },
"effects": [ { "op": "appendUnique", "key": "goingPersonaIds", "value": "$actor" } ]
```

**Fix:** declare it as a `formula`. Delete the effect.

---

## AP-3 — Parsing a display string to recover data

**Detection:** any field whose value is a human sentence that also encodes a number
(`"12 of 20 seats filled"`).

**Real failure:** the app had `_goingCountFromLabel()` and `_isCapacityFull()` — functions that **regex-
parsed a label string** to recover numbers the system had thrown away.

```jsonc
// ❌ WRONG
"capacityLabel": { "type": "text" }        // "12 of 20 seats filled" — now parse it back out

// ✅ RIGHT — store the data, compute the display
"capacity":   { "type": "number", "required": true },
"goingCount": { "type": "number", "formula": "size(goingPersonaIds)",
                "labelTemplate": "Going: {value}" },
"isFull":     { "type": "bool",   "formula": "size(goingPersonaIds) >= capacity" }
```

**Fix:** store structured data; use `labelTemplate` for display.

---

## AP-4 — Relying on UI hiding for security

**Detection:** any requirement of the form "only X may do Y" that is **not** expressed as a `guard`.

**Symptom:** the button is hidden, but `applyTransition` would succeed if called. The rule is decorative.

```jsonc
// ✅ RIGHT — the engine refuses, not the widget
{ "id": "cast-vote",
  "guard": { "relatedInstanceField": "eventId", "relatedListField": "goingPersonaIds" } }
```

**Fix:** every permission rule is a guard. **Test it by attempting the transition and expecting a throw**
— not by asserting a button is absent. Those are different claims.

---

## AP-5 — A scripted card with no workflow behind it

**Detection:** any `entryText`-style narrative that asserts something happened
(*"A member proposed buying Wingspan"*) with **no transition anywhere that could produce it**.

**Real failure:** a `committee-decision` card said a member had proposed a game — but **no workflow let a
member propose anything**. It modeled only the back half of a two-sided interaction. The organizer
"decided" on a hardcoded string.

**Fix:** model **both halves**. If someone can decide it, someone must be able to propose it.

```jsonc
// ✅ RIGHT — the full loop
"states": { "draft": {}, "pending": {}, "approved": {}, "changes-requested": {}, "rejected": {} },
"transitions": [
  { "id": "submit",          "from": ["draft","changes-requested"], "to": "pending",
    "guard": { "allowedPersonaIds": ["member"] } },
  { "id": "approve",         "from": ["pending"], "to": "approved",
    "guard": { "allowedPersonaIds": ["organizer"] } },
  { "id": "request-changes", "from": ["pending"], "to": "changes-requested",
    "guard": { "allowedPersonaIds": ["organizer"] } },
  { "id": "reject",          "from": ["pending"], "to": "rejected",
    "guard": { "allowedPersonaIds": ["organizer"] } }
]
```

---

## AP-6 — Hardcoding a value that should be computed

**Detection:** a literal in `instanceData` or an effect where a formula reference belongs — a fixed
winner, a fixed receipt id, a fixed count.

**Real failure:** a vote poll's "declare winner" wrote a **hardcoded candidate name**, ignoring the
actual tally. It looked like it worked.

```jsonc
// ❌ WRONG
{ "op": "set", "key": "selectedGame", "value": "Wingspan" }

// ✅ RIGHT — the computed winner
{ "op": "set", "key": "selectedGame", "value": "{winner}", "relatedInstance": "eventId" }
```

**Fix:** interpolate the computed field. If it genuinely cannot be computed (a receipt id, a payment
authorization), it is a [platform service](../reference/platform-services.md) — **report the gap; do not
fake it.**

---

## AP-7 — Duplicating a workflow per persona

**Detection:** two workflow types with the same states and near-identical transitions, differing only in
who acts.

```jsonc
// ❌ WRONG: "member-proposal" + "organizer-proposal-review"

// ✅ RIGHT: one type; guard-filter the transitions and role-key the bindings
"transitions": [
  { "id": "submit",  "guard": { "allowedPersonaIds": ["member"] } },
  { "id": "approve", "guard": { "allowedPersonaIds": ["organizer"] } }
],
"renderBindings": [
  { "states": ["draft"],   "role": "actor",    "tabId": "home",  "...": "..." },
  { "states": ["pending"], "role": "receiver", "tabId": "admin", "...": "..." }
]
```

---

## AP-8 — The same icon on every field

**Detection:** more than ~2 fields in a workflow sharing a `displayIcon`.

**Real failure:** every calendar fact pill used `check_circle_outline` — it read as a "field parsed OK"
debug affordance rather than information.

**Fix:** date → `calendar_today`/`schedule` · person → `person_outline` · place →
`location_on_outlined` · capacity → `groups_outlined` · money → `payments_outlined`.

---

## AP-9 — A stuck state

**Detection:** a state with `isTerminal` absent/false and **zero** outgoing transitions.
(The validator catches this: `stuck_state`.)

**Fix:** either add a transition out, or mark it `"isTerminal": true` — deliberately.

---

## AP-10 — Everything bound to `home`

**Detection:** most workflows declaring a `home` binding.

**Symptom:** Home becomes a wall of duplicate cards — the same instance appearing there *and* on its real
tab.

**Fix:** bind each workflow to the tab it belongs on. Home is a **curated feed**, not a catch-all.

---

## AP-11 — Silently dropping a requirement

**Detection:** a requirement in the brief with no corresponding construct in the JSON.

**Fix:** **never** silently approximate. Either express it, or mark it:

```jsonc
// NEEDS IMPLEMENTATION: <what is missing and why the grammar cannot express it>
```
…and list every such gap in your final response. A community that quietly does 80% of what was asked,
with no indication of which 80%, is worse than one that clearly states its limits.

---

## AP-12 — A shared scratch field for a per-item action (superseded 2026-07-16 — GAP-1 closed)

**This used to be the only way to express "which item did the user act on."** It no longer is — do not
write it, even though it will still validate.

**Detection:** a field like `pendingChoice` written by one transition, then read by a second,
parameterless transition fired immediately after.

**Symptom:** a real race. Two members firing the two-call sequence at the same moment can interleave: A
writes `pendingChoice = 'catan'`, B writes `pendingChoice = 'azul'`, A's second call fires and reads B's
value. A's vote silently becomes Azul.

```jsonc
// ❌ WRONG — shared scratch field, two calls, racy
{ "id": "set-choice",  "effects": [ { "op": "set", "key": "pendingChoice", "value": "$actor-supplied" } ] },
{ "id": "cast-vote",   "effects": [ { "op": "createInstance", "fields": { "choice": "{pendingChoice}" } } ] }

// ✅ RIGHT — the choice travels WITH the transition (GAP-1)
{ "id": "cast-vote",
  "inputs": { "choice": { "type": "text", "required": true } },
  "effects": [ { "op": "createInstance", "fields": {
    "ballotId": "{id}", "voterId": "$actor", "choice": "{input.choice}" } } ] }
```

**Fix:** declare `inputs` on the transition and reference `{input.x}` in its effects — see
[`effects.md`](../reference/effects.md) and [`render-bindings.md`](../reference/render-bindings.md)'s
`repeater.itemActions` (for a per-item button that supplies a different input per row).

---

## AP-13 — A seeded blank draft, standing in for a real create affordance

**Detection:** a pre-seeded `workflowInstances` row in a `draft`-like state with mostly-empty fields,
existing only so the member has *something* to edit — rather than a real "+ New" action.

**Real failure:** `game-purchase-proposal` used to ship with one seeded blank draft per community, so a
member could edit *that one row* to "submit a proposal." A member could never actually propose a
*second* game — the JSON had no way to say "let a member create a new instance of this type."

**Fix:** declare a `renderBindings[].actions[]` entry (`kind: "create"`) on the type instead of seeding a
placeholder row (GAP-2 — see [`render-bindings.md`](../reference/render-bindings.md) and
[`07-actions-and-fabs.md`](./07-actions-and-fabs.md)). **Caveat, honestly stated:** as of 2026-07-21,
`scope: "tab"` creates are real grammar, parse, validate, **and render end-to-end** (the tab
creatable-action FAB, CALR.3g/3h/3b). `scope: "instance"` creates and `kind: "transition"` actions are
real grammar and validate, but no running UI consumes them yet. Declaring the right shape now is still
correct even for the not-yet-rendered cases (it's what the Skill should emit; the App Shell will catch up
to it) — but do not claim an *interaction* works until a later phase's own doc/review confirms it does.
What's already wrong regardless is the OLD workaround: never seed a blank placeholder instance to fake
creatability — that teaches the wrong shape even where nothing yet renders the right one.

---

## Final self-check

- [ ] No state can coexist with another state (AP-1)
- [ ] No stored value is derivable (AP-2, AP-3)
- [ ] Every permission rule is a `guard`, not UI hiding (AP-4)
- [ ] Every "someone did X" has a transition that produces it (AP-5)
- [ ] No hardcoded value where a computed one belongs (AP-6)
- [ ] No workflow duplicated per persona (AP-7)
- [ ] Icons are distinct and meaningful (AP-8)
- [ ] No stuck states (AP-9)
- [ ] `home` is curated, not a dumping ground (AP-10)
- [ ] Every unmet requirement is explicitly marked and reported (AP-11)
- [ ] No shared scratch field for a per-item action — use transition `inputs` (AP-12)
- [ ] No seeded blank draft standing in for `creatable` (AP-13)
