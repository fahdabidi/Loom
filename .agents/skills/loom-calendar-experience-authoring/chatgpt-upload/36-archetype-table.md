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

# `table`

Rows in a grid.

Used directly by 1 community (Riverside Youth Soccer's roster) with 9 community-defined transitions.
Chess Club's rankings pair it with `formEntry`.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. `table` is generic, despite the grid

This is the archetype most often mistaken for a bespoke one, and the mistake has already been made once
in this repo's own specification.

`table` has **no dispatcher case**. It falls through to `GenericWorkflowInstanceCard` like every other
generic family. Its only special treatment is **list layout**: `part32` groups sibling `table` bindings
into one `WorkflowTableArchetypeCard` per `(tabId, workflowType)`.

**A tabular layout is not a semantic contract.** An earlier draft of `permissions.md` listed `table` as
a seventh bespoke family with a two-action vocabulary, `view` and `publish`. The corpus disproved it:
13 `table` transitions exist -- applying consent, redacting fields, archiving roster rows, requesting
guardian updates, revising and discarding ranking drafts -- and only `publish-ranking` fits either
action.

## 2. Actions

**None named.** Derives structurally.

## 3. Bookkeeping

**None.**

## 4. Visibility

Model: **`roles` + `owner`**.

Riverside's roster rows are guardian-scoped, expressed today with `actorEqualsField` guards -- a
per-instance check the workflow engine resolves, not a role permission.

## 5. Community-defined actions

**The norm**, and they are substantial: `apply-private-consent`, `apply-shared-consent`,
`redact-fields`, `undo-last-redaction-change`, `archive-roster-row`, `request-guardian-update`,
`apply-correction-request`, `save-roster-update`, `mark-waiver-acknowledged`.

Consent and redaction are real privacy operations on minors' data. They derive `advance` and
`terminate` structurally, which expresses *may edit the roster* but not *may redact specifically*.

## 6. Open

- **Redaction may deserve promotion.** If Riverside needs "may correct a row" separated from "may
  redact a minor's fields", that is precisely the signal `permissions.md` section 5 describes for
  promoting a family to bespoke -- not a reason to complicate the generic path.

## 7. Worked example

Roster rows in a grid, with the guardian-scoped read Riverside actually uses. Note what is **absent**:
no `action` on any transition, and no archetype-owned bookkeeping fields.

```jsonc
"club-roster-row": {
  "initialState": "active",
  "visibility": {
    "default": "guarded",
    // Per-instance, not a role permission: each guardian sees their own row.
    "readGuard": { "actorEqualsField": { "key": "guardianFanId" } }
  },

  "instanceDataSchema": {
    "playerName":     { "type": "text",  "required": true },
    "guardianFanId":  { "type": "fanId", "required": true },
    "consentLevel":   { "type": "text",  "labelTemplate": "Consent: {value}" },
    "archivedReason": { "type": "text",  "writableBy": "effect" }
  },

  "states": {
    "active":   { "label": "Active", "tone": "positive",
                  "editableFields": ["playerName", "consentLevel"],
                  "editGuard": { "allowedRoleIds": ["club-coach"] } },
    "archived": { "label": "Archived", "tone": "neutral", "isTerminal": true }
  },

  "transitions": [
    // No "action" key anywhere in this workflow -- see section 1.
    { "id": "apply-shared-consent", "label": "Share with team",
      "from": ["active"], "to": null,
      "guard": { "actorEqualsField": { "key": "guardianFanId" } },
      "effects": [ { "op": "set", "key": "consentLevel", "value": "shared" } ] },

    { "id": "archive-roster-row", "label": "Archive row", "tone": "destructive",
      "from": ["active"], "to": "archived",
      "guard": { "allowedRoleIds": ["club-coach"] },
      "inputs": { "archivedReason": { "type": "text", "required": true } },
      "effects": [ { "op": "set", "key": "archivedReason",
                     "value": "{input.archivedReason}" } ] }
  ],

  "renderBindings": [
    { "tabId": "roster", "audience": "any",
      "cardSurfaceFamily": "table", "bindingKind": "primary",
      "states": ["active", "archived"],
      "actions": [ { "kind": "create", "label": "Add player" } ] }
  ]
}
```

### Why each part is the way it is

- **No `action` on any transition.** `table` is generic (§1). Adding one is a validator error, not a
  harmless extra — only the six bespoke families take `action`.
- **The permission still exists.** `archive-roster-row` derives `terminate` from `tone: "destructive"`
  and a terminal `to`; `apply-shared-consent` derives `advance`; the create affordance derives
  `create`. Structure supplies what the vocabulary would have.
- **`actorEqualsField` rather than a role.** Riverside's rows are guardian-scoped: the reader must be
  *this row's* guardian, which no `allowedRoleIds` list can express (§4).
- **Sibling rows group automatically.** `part32` collapses sibling `table` bindings sharing a
  `(tabId, workflowType)` into one grid card. Declare one binding, not one per row.
- **No bookkeeping fields.** §3: the archetype owns none. Any per-person array here would be
  community-declared and community-maintained.

### What not to do

- Do not give it `view`/`publish` actions. An earlier `permissions.md` draft did exactly that; the
  corpus disproved it — 13 `table` transitions exist and only `publish-ranking` fits either (§1).
- Do not reach for `table` because the data looks tabular. The grid is list layout, not a semantic
  contract. If the workflow is a form that happens to list, `formEntry` is the archetype.
