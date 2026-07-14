---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
---

# Authoring procedure

**The algorithm.** Follow these steps in order. Do not skip steps 6-8.

## Mental model (one paragraph)

A community is a set of **state machines** declared in JSON and executed by a real engine. You declare
*what states a thing can be in*, *what transitions move between them*, *who may fire each* (guards),
*what changes when they fire* (effects), *what is derived rather than stored* (formulas), and *where it
appears* (render bindings). You never author UI and never author code. The app renders the declaration.

---

## Step 1 — Extract personas

From the requirements, list every distinct actor. Each becomes a persona.

```jsonc
"personas": [
  { "personaId": "<kebab-id>", "label": "<short>", "roleLabel": "<short>",
    "description": "<what they do>" }
]
```

**Rule:** every `allowedPersonaIds` entry you write later MUST be a `personaId` declared here. The
validator warns on dangling persona ids.

---

## Step 2 — Enumerate the "things" (→ workflow types)

List every distinct kind of object the community manipulates. Each becomes **one entry** in
`workflowDefinitions`.

**Type vs instance — critical:**
- A community with 40 hikes has **one** `hike-rsvp` *type* and **40** *instances*.
- A community with hikes AND book-swaps has **two** types.

**Test:** *do these two things have the same states and the same transitions?* If yes → one type, two
instances. If no → two types.

---

## Step 3 — For each type, decide states vs data

**This is the highest-risk step. Most modeling bugs originate here.**

Apply this decision rule to every candidate condition:

> **Can this be true at the same time as another condition in the same dimension?**
> - **Yes** → it is **data** (`instanceData` + an orthogonal transition, `"to": null`).
> - **No — it genuinely replaces the previous condition** → it is a **state**.

### Decision table

| Condition | Simultaneous with others? | Verdict |
|---|---|---|
| Event is `open` / `cancelled` | No — mutually exclusive | **state** |
| Member has RSVP'd going | Yes — many members, many at once | **data** (`goingPersonaIds`) |
| Listing is on loan | Yes — can be on loan **and** have a queue | **data** (`availabilityState`) |
| Members are queued for a listing | Yes — simultaneous with on-loan | **data** (`queuedPersonaIds`) |
| Ballot is `open` / `closed` | No | **state** |
| A vote has been cast | Yes — many voters | **data** (`ballots`) |
| Proposal is `draft`/`pending`/`approved`/`rejected` | No — mutually exclusive | **state** |

**Failure mode if you get this wrong:** a shipped bug made `queued` a marketplace *state*. Because an
item can be on loan *and* queued simultaneously, `queued` had no coherent transitions — it was declared
with **zero**, and queued listings rendered **no buttons at all**. The validator now catches this
(`stuck_state`), but the correct fix is to model it as data in the first place.

---

## Step 4 — Write states and transitions

```jsonc
"<workflowType>": {
  "initialState": "<must be a key of states>",
  "states": {
    "<name>": { "label": "<human>", "tone": "positive|negative|warning|info",
                "editableFields": ["<formEntry fields editable in this state>"],
                "isTerminal": false }
  },
  "transitions": [
    { "id": "<unique>", "label": "<button text>", "icon": "<material-icon>",
      "tone": "primary|secondary|destructive",
      "from": ["<state>"], "to": "<state>" | null,
      "guard": { /* who/when */ }, "effects": [ /* what changes */ ] }
  ]
}
```

**Invariants (validator-enforced):**
- Every **non-terminal** state MUST have ≥1 outgoing transition. → else `stuck_state`
- Every state MUST be reachable from `initialState`. → else `unreachable_state`
- `label` MUST be non-empty. → else `missing_label`
- `"to": null` for orthogonal transitions (state unchanged, data changed).

---

## Step 5 — Write `instanceDataSchema`

Every field a workflow uses MUST be declared. Three kinds — pick deliberately:

| Kind | Declare | Written by | Seed in `instanceData`? |
|---|---|---|---|
| Form-entry | `"writableBy": "formEntry"` | User (via `editableFields`) | Yes |
| Effect | `"writableBy": "effect"` | Transition effects | Yes |
| **Computed** | `"formula": "<expr>"` | **Nobody** | **NO — hard error** |

**Rule: if a value can be derived, derive it.** Never store a count, total, ranking, or boolean condition
you could compute.

```jsonc
"goingPersonaIds": { "type": "personaId[]", "writableBy": "effect" },
"goingCount":  { "type": "number", "formula": "size(goingPersonaIds)" },
"isFull":      { "type": "bool",   "formula": "size(goingPersonaIds) >= capacity" }
```

Full type list: [`reference/field-types.md`](../reference/field-types.md).
Full function list: [`reference/formulas.md`](../reference/formulas.md).

---

## Step 6 — Attach guards

For each transition, ask: *who may fire this, and under what conditions?*

| Requirement | Guard kind |
|---|---|
| "only organizers" | `allowedPersonaIds` |
| "only if not already in the list" | `actorInList: { key, present: false }` |
| "only if the item is available" | `instanceDataEquals: { key, value }` |
| "only if there's room" / any computed condition | `formula` |
| "only if they RSVP'd to the linked event" | `relatedListMembership` (cross-instance) |
| "only if they've paid dues" | `requiresWorkflowsComplete` (cross-workflow) |

All guards on a transition are **AND**-ed. Full detail: [`reference/guards.md`](../reference/guards.md).

**Rule:** a guard is enforced by the **engine** — it makes `applyTransition` refuse, not merely hide a
button. Never rely on UI hiding for correctness.

---

## Step 7 — Attach effects

For each transition, ask: *what changes when this fires?*

| Requirement | Effect op |
|---|---|
| Set a value | `set` |
| Add to a list (allowing dupes) | `append` |
| Add to a list (no dupes) | `appendUnique` |
| Remove from a list | `removeValue` |
| Bump a counter | `increment` / `decrement` |
| Do one thing or another, conditionally | `branch` (`if`/`then`/`else`) |
| Spawn a new instance (runoff, notification) | `createInstance` |
| Write a field on **another** instance | `set` + `relatedInstance` |

Interpolation: `$actor` → acting persona id · `$timestamp` → now · `{fieldName}` → that field's value.

Full detail: [`reference/effects.md`](../reference/effects.md).

---

## Step 8 — Attach render bindings

For each type, decide where its instances appear, per state and per role.

```jsonc
"renderBindings": [
  { "states": ["open"], "role": "any", "tabId": "calendar",
    "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary" }
]
```

- `tabId` ∈ `home` · `calendar` · `marketplace` · `giving` · `admin` · `messages`
- `role` ∈ `any` · `actor` · `receiver`
- `bindingKind` ∈ `primary` (full/interactive) · `summary` (compact)
- `cardSurfaceFamily` — **only** values from [`archetypes/README.md`](../archetypes/README.md)

**One type may bind to several tabs.** A proposal binds to `home` (role `actor` — its author tracks it)
*and* `admin` (role `receiver` — the organizer decides it). That is one workflow, two surfaces — not two
workflows.

A state with no binding does not render. This is the correct way to hide drafts.

Full detail: [`reference/render-bindings.md`](../reference/render-bindings.md).

---

## Step 9 — Write `workflowInstances` (seed data)

```jsonc
{ "instanceId": "<unique>", "workflowType": "<a declared type>",
  "currentState": "<a declared state of that type>",
  "createdByPersonaId": "<a declared persona>",
  "instanceData": { /* declared fields only; NO computed fields */ } }
```

**Invariants:**
- `instanceId` unique across the package.
- `workflowType` MUST exist in `workflowDefinitions`.
- `currentState` MUST be a declared state of that type.
- Every `instanceData` key MUST be declared in that type's `instanceDataSchema`.
- Every `required: true` non-computed field MUST be present.
- **NO computed field may appear.**
- Any cross-instance reference field (e.g. `eventId`) MUST name an existing `instanceId`.

---

## Step 10 — Self-check against anti-patterns

Load [`guide/04-antipatterns.md`](./04-antipatterns.md) and check the emitted JSON against every
detection rule. Fix before proceeding.

---

## Step 11 — Validate (MANDATORY GATE)

```bash
dart run loom_ux_judges:community_package_validator --package <your-file>.jsonc
```

**A community that does not pass is not a deliverable.** On failure, use the error→fix table in
[`guide/05-validation.md`](./05-validation.md), repair, re-run. Repeat until clean.

**Never** "fix" a failure by weakening the validator or by deleting the requirement. If the grammar
genuinely cannot express the requirement, **stop and report the gap** (see hard rule 8 in the
[README](../README.md)).

---

## Step 12 — Report gaps honestly

If any requirement could not be expressed:

- Mark the location in the JSON with a `// NEEDS IMPLEMENTATION: <what and why>` comment.
- List every such gap in your final response.
- **Do not** substitute a hardcoded value for a computed one, a scripted card for a real interaction, or
  a UI-only check for an engine guard. Those are the exact failures the archetype audit was created to
  eliminate.

---

## Canonical minimal package

Adapt this. It is complete and valid — nothing elided.

```jsonc
{
  "schemaVersion": 1,
  "packageId": "init_hiking_club_1",
  "communityId": "community_hiking_club",
  "communityHandle": "hiking-club",
  "displayName": "Hiking Club",
  "extensionId": "ext_hiking_club",
  "branding": { "accentColor": "#2D6A4F" },
  "seedDataFiles": [],

  "experience": {
    "experienceSchemaVersion": 2,
    "workflowGrammarVersion": 1,

    "displayName": "Hiking Club",
    "tagline": "Weekend trails for the neighbourhood.",
    "accentColor": "#2D6A4F",

    "personas": [
      { "personaId": "hiking-organizer", "label": "Organizer", "roleLabel": "Organizer",
        "description": "Plans hikes." },
      { "personaId": "hiking-member", "label": "Member", "roleLabel": "Member",
        "description": "Joins hikes." }
    ],

    "workflowDefinitions": {
      "hike-rsvp": {
        "initialState": "open",
        "states": {
          "open":      { "label": "Signups open", "tone": "positive",
                         "editableFields": ["title", "eventDate", "capacity"] },
          "cancelled": { "label": "Cancelled", "tone": "negative", "isTerminal": true }
        },
        "transitions": [
          {
            "id": "rsvp-going", "label": "I'm going", "icon": "hiking", "tone": "primary",
            "from": ["open"], "to": null,
            "guard": {
              "allowedPersonaIds": ["hiking-member"],
              "actorInList": { "key": "goingPersonaIds", "present": false },
              "formula": "size(goingPersonaIds) < capacity"
            },
            "effects": [
              { "op": "appendUnique", "key": "goingPersonaIds", "value": "$actor" }
            ]
          },
          {
            "id": "rsvp-withdraw", "label": "Can't make it", "tone": "secondary",
            "from": ["open"], "to": null,
            "guard": {
              "allowedPersonaIds": ["hiking-member"],
              "actorInList": { "key": "goingPersonaIds", "present": true }
            },
            "effects": [
              { "op": "removeValue", "key": "goingPersonaIds", "value": "$actor" }
            ]
          },
          {
            "id": "cancel-hike", "label": "Cancel hike", "tone": "destructive",
            "from": ["open"], "to": "cancelled",
            "guard": { "allowedPersonaIds": ["hiking-organizer"] }
          }
        ],
        "renderBindings": [
          { "states": ["open"], "role": "any", "tabId": "calendar",
            "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary" },
          { "states": ["cancelled"], "role": "any", "tabId": "calendar",
            "cardSurfaceFamily": "event-rsvp", "bindingKind": "summary" }
        ],
        "instanceDataSchema": {
          "title":     { "type": "text", "required": true, "writableBy": "formEntry",
                         "labelTemplate": "{value}", "displayContexts": ["tile", "detail"] },
          "eventDate": { "type": "date", "required": true, "writableBy": "formEntry",
                         "sortable": true, "displayIcon": "calendar_today" },
          "capacity":  { "type": "number", "required": true, "writableBy": "formEntry",
                         "displayIcon": "groups_outlined" },
          "goingPersonaIds": { "type": "personaId[]", "writableBy": "effect" },

          "goingCount":     { "type": "number", "formula": "size(goingPersonaIds)",
                              "labelTemplate": "Going: {value}",
                              "displayContexts": ["tile", "detail"] },
          "spotsRemaining": { "type": "number", "formula": "capacity - size(goingPersonaIds)" },
          "isFull":         { "type": "bool",   "formula": "size(goingPersonaIds) >= capacity" }
        }
      }
    },

    "workflowInstances": [
      {
        "instanceId": "hike-eagle-ridge",
        "workflowType": "hike-rsvp",
        "currentState": "open",
        "createdByPersonaId": "hiking-organizer",
        "instanceData": {
          "title": "Eagle Ridge loop",
          "eventDate": "2026-08-02",
          "capacity": 12,
          "goingPersonaIds": ["hiking-member"]
        }
      }
    ]
  }
}
```
