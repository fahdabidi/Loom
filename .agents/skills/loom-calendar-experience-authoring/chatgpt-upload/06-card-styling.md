---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-23
audience: llm-agent
derived_from:
  - docs/references/reference/render-bindings.md
  - docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc
---

# Card styling — which fields show compactly, and per-category color

**This doc answers two questions the Skill hits whenever a community wants its cards to look richer than
the flat default:** *"which fields should show on the compact (tile) card vs. only the expanded (detail)
view?"* and *"can different instances of the same workflow look visually distinct from each other?"*
Both are answered entirely by data already declared in a workflow's own `instanceDataSchema` — neither
needs a bespoke widget or App-Shell code change per community.

## Which fields show where: `displayContexts` (already implemented)

Every field in `instanceDataSchema` may declare `displayContexts: ["tile", "detail"]` — this is not new
grammar, it already exists and is already used throughout the frozen fixture. `"tile"` means "show this
on the compact/collapsed card"; `"detail"` means "show this on the expanded card." A field can declare
both, either, or neither (an empty array, or omitting the key entirely, means "every context" unless the
field is a hidden computed signal — see `cardStyleId` below, which deliberately declares `[]`).

```jsonc
"location": { "type": "text", "displayIcon": "location_on_outlined", "labelTemplate": "{value}",
  "displayContexts": ["tile", "detail"] },   // shows compactly AND expanded
"host": { "type": "text", "displayIcon": "person_outline", "labelTemplate": "Host: {value}",
  "displayContexts": ["detail"] }             // expanded only — too much detail for a compact card
```

**This is the entire "configurable which labels appear on the compact card" mechanism.** A community
that wants its compact cards to show more (or fewer) fields does so by editing each field's own
`displayContexts` — no new JSON key, no App-Shell change. Order on the card follows declaration order in
`instanceDataSchema` — put the fields you want to appear first, earliest in the schema.

**Guidance, not a hard rule:** compact cards are compact for a reason — declaring every field
`["tile", "detail"]` defeats the point. Reserve `"tile"` for the 2-4 fields that let someone recognize
and triage the item at a glance (what/when/where); push everything else (host, description, secondary
metadata) to `"detail"` only.

## Per-category visual style: `styleField` (PROPOSED, not yet App-Shell-implemented)

By default every card on a tab renders in one flat community/tab accent — every event on a Calendar
looks the same color regardless of what kind of event it is. `styleField` lets a workflow's own data
choose a different visual style per instance, e.g. so a game night and a tournament read as visually
distinct at a glance, matching how a real calendar app color-codes different event categories.

**The shape — one pointer field on the binding, all the real logic lives in `instanceDataSchema`:**

```jsonc
{
  "tabId": "calendar", "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary",
  "styleField": "cardStyleId"
}
```

```jsonc
"instanceDataSchema": {
  "category": { "type": "text", "writableBy": "formEntry", "storage": "inline",
    "displayContexts": [] },
  "cardStyleId": { "type": "number",
    "formula": "if(category == 'tournament', 1, if(category == 'social', 2, 0))",
    "displayContexts": [] }
}
```

`category` is a plain, community-authored field (any values the community wants — the example above
uses `"tournament"`/`"social"`, but nothing is reserved or hardcoded). `cardStyleId` is a **computed**
field mapping that value to a small integer, using nested `if()` — already-implemented, already-proven
vocabulary (see `formulas.md`; the identical pattern already ships in `tournament-ballot.dueAt`'s
`reminderOffset`-to-hours mapping). No new formula function is required to build this mapping, however
many categories a community wants — just more `if()` nesting.

**Why a pointer field, not an inline value on the binding itself:** the mapping formula is entirely the
workflow author's own business logic — which categories exist, and which slot each maps to. `styleField`
only tells the App Shell *where to look*, the same design already used for
`responseTable.eventField`/`filterableFacets[].field` (both name a workflow-owned field rather than
duplicating workflow-owned logic on the binding).

**When there's really only one category:** not every workflow type needs a `category` field of its own.
`tournament-event` has exactly one conceptual category ("tournament") — its `cardStyleId` is a bare
constant formula, still a real formula (not a stored value), still using the same mechanism:

```jsonc
"cardStyleId": { "type": "number", "formula": "1", "displayContexts": [] }
```

**Resolution (not yet App-Shell-implemented):** the archetype reads `instanceData[binding.styleField] ??
0` and looks up that integer, modulo the palette size, in a small, fixed set of style slots *derived
from the same community/tab accent this binding already resolves* — never a new, unrelated, hardcoded
color. A community that never sets `styleField` sees no change at all: today's single flat accent.

**Always hide the pointer fields from fact-pill rendering.** `category` and `cardStyleId` (or any field
whose only job is feeding `styleField`) should declare `"displayContexts": []` — they exist to drive
visual styling, not to be read as a fact by the viewer.

## Self-check before adding `styleField` to a workflow

- [ ] Does the mapping field (`cardStyleId` or your own name) declare `"displayContexts": []`? It should
      never render as a fact pill.
- [ ] Is the mapping field genuinely `formula`-typed (computed), not a stored value a form or effect
      writes directly? The mapping logic must re-evaluate from the real category value on every read.
- [ ] Did you reuse nested `if()` rather than reaching for a function that doesn't exist yet? Check
      `formulas.md`'s implemented vocabulary before assuming a gap.
- [ ] Does `styleField` name a **declared, `number`-typed** field in this same workflow's own
      `instanceDataSchema`? (Validator: `dangling_style_field`.)
- [ ] Have you left `styleField` off entirely for a workflow that has no meaningful category
      distinction? Absence is the correct default, not an oversight.

## Reference

- [`render-bindings.md`](../reference/render-bindings.md) — normative `styleField` grammar, full
  validator check list, `responseTable`/`filterableFacets` (the two existing bindings this design
  mirrors).
- [`formulas.md`](../reference/formulas.md) — the full computed-field vocabulary, including `if()` and
  every function already available for a mapping formula.
- [`07-actions-and-fabs.md`](./07-actions-and-fabs.md) — the same "one pointer field, real logic stays in
  the workflow's own schema" design principle applied to actions instead of styling.
