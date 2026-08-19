---
spec: 4
doc_version: 1.0.0
status: proposed
last_verified: 2026-08-14
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/permissions.md
---

# `statusTimeline`

A read-mostly view of where something stands.

Used by 2 communities directly, with only 4 community-defined transitions -- but it is the most common
**secondary** binding in the corpus: 8 of Data Portability's 9 workflows pair a `statusTimeline`
summary with an `exportWizard` primary.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. Actions

**None named.** Derives structurally.

Most `statusTimeline` bindings carry no transitions at all -- they render state, and the actions live
on the workflow's primary binding.

## 2. Bookkeeping

**None.**

## 3. Visibility

Model: **`roles`**, and in practice it inherits its workflow's model, because it is usually a second
binding on a workflow whose primary surface is something else.

## 4. Why it matters more than its usage count suggests

`statusTimeline` is the archetype that makes **mixed-family workflows normal**. A workflow rendering
`exportWizard` on an admin tab and `statusTimeline` on a home tab names two families and is completely
unambiguous -- only one is bespoke.

An earlier draft of `permissions.md` section 8 made *any* disagreement among a workflow's bindings an
error. Measured against the corpus, that rule rejected **27 workflows**, 26 of them wrongly -- and most
of those 26 were a bespoke primary paired with a `statusTimeline` summary.

## 5. Community-defined actions

**The norm.** `acknowledge`, `deactivate`, `mark-audited`, `review-completion`.

## 6. Open

- **Whether a summary binding should declare its own visibility**, separate from the workflow's primary
  surface. Today it cannot, which is why a `guarded` export shows a `guarded` timeline even where a
  community might want the timeline visible more widely.

## 7. Worked example — as a secondary binding

`statusTimeline` is most often a **second binding on a workflow whose primary surface is something
else** (§4). This is that shape: one workflow, two families, and only one of them bespoke.

```jsonc
"club-export-package": {
  "initialState": "ready",
  "visibility": { "default": "guarded",
                  "readGuard": { "allowedRoleIds": ["club-organizer"] } },

  "instanceDataSchema": {
    "exportLabel":   { "type": "text", "required": true },
    "statusMessage": { "type": "text", "writableBy": "effect" }
  },

  "states": {
    "ready":     { "label": "Ready to export", "tone": "info" },
    "generated": { "label": "Export generated", "tone": "positive" }
  },

  "transitions": [
    { "id": "generate-export", "action": "run", "label": "Generate export",
      "from": ["ready"], "to": "generated",
      "guard": { "allowedRoleIds": ["club-organizer"] },
      "effects": [ { "op": "set", "key": "statusMessage",
                     "value": "Export generated" } ] }
  ],

  "renderBindings": [
    // PRIMARY: the bespoke surface, where the actions live.
    { "tabId": "admin", "audience": "any",
      "cardSurfaceFamily": "exportWizard", "bindingKind": "primary",
      "states": ["ready", "generated"],
      "actions": [ { "kind": "create", "label": "New export" } ] },

    // SECONDARY: read-only progress on a member-facing tab. No actions.
    { "tabId": "home", "audience": "any",
      "cardSurfaceFamily": "statusTimeline", "bindingKind": "summary",
      "states": ["ready", "generated"] }
  ]
}
```

### Why each part is the way it is

- **Two families on one workflow is normal, not an error.** Only `exportWizard` is bespoke, so the
  workflow's archetype is unambiguous. §4 records that an earlier `permissions.md` draft made any
  disagreement between bindings an error and thereby rejected 27 workflows, 26 of them wrongly —
  mostly this exact pairing.
- **The summary binding declares no `actions`.** Actions belong on the primary. A `statusTimeline`
  that sprouts its own buttons is usually a sign the workflow wanted two workflows.
- **`action` is on the transition, not the binding.** The transition is `run` because the *workflow*
  is bespoke `exportWizard`. The presence of a generic `statusTimeline` binding does not change that,
  and does not mean the transition should drop its `action`.
- **Both bindings list every state.** A state missing from *both* renders nowhere; the validator's
  `no_render_binding_for_reachable_state` counts the union, not each binding separately.
- **Visibility is declared once, on the workflow.** §6 leaves open whether a summary should carry its
  own; today it does not — it inherits.

### What not to do

- Do not give a `statusTimeline`-only workflow an `action` on its transitions. Alone, it is generic
  and derives structurally (§1).
- Do not add a second bespoke family. Two bespoke families on one workflow *is* the error the
  ambiguity rule is for; one bespoke plus any number of generic is fine.
