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

# `exportWizard`

A long-running export, transfer or replay, with a preview step, a redaction review, and an outcome to
record.

Used by 6 communities. **All 14 of its workflows declare `visibility: guarded`** -- the only archetype
with a uniform guarded default, and it fits: an export contains whatever the exporter could read.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. Actions

Eleven. Permission ids are `export_wizard.<action>`.

| Group | Actions |
|---|---|
| Setup | `configure_scope` - `preview` |
| Review | `approve_redaction` |
| Execution | `run` - `retry` - `cancel` |
| Delivery | `download` - `decide_transfer` |
| Undo | `rollback` |
| Bookkeeping | `record_outcome` |
| Reading | `view` |

**`record_outcome` deliberately covers the state-machine bookkeeping** -- `record-*`, `fail-*`,
`complete-*`, `mark-*`, `retire-*`. These are usually platform- or admin-recorded rather than
member-invoked, and grouping them keeps the member-facing vocabulary honest.

Four lookalike pairs resolve by the precedence rules in `permissions.md` section 4, and are worth
stating because the rule alone is easy to misread:

| Transition | Action | Not |
|---|---|---|
| `start-preview-export` | `preview` | `run` -- the longer pattern wins |
| `start-transfer-rollback` | `rollback` | `run` -- literal beats pattern |
| `complete-transfer-rollback` | `rollback` | `record_outcome` |
| `cancel-transfer-rollback` | `cancel` | it really does cancel the rollback |

`confirm-*` has **no pattern at all**: its three occurrences land in three different actions.

## 2. Bookkeeping

**None per-person.** Export state is per-instance, not per-viewer. This is the only bespoke archetype
with no bookkeeping clause.

## 3. Visibility

Model: **`roles` + `owner`**. An export is owned by whoever ran it.

Data Portability Community is the extreme case: 9 workflows, 80 transitions, every one `guarded`. That
community exists to exercise export/transfer semantics, and its shape is why the vocabulary carries 11
actions rather than 4.

## 4. Community-defined actions

Permitted. None in the corpus -- all 80 Data Portability transitions map to the vocabulary, which is
what made it possible to widen that vocabulary from evidence rather than invention.

## 5. Open

- **`record-download` means different things in different families.** In `exportWizard` it is
  `record_outcome` (the owner recording that a download happened); in `documentLibrary` it is
  `download`. Both are correct per family, but a reader moving between them will be surprised.

## 6. Worked example

A complete, correct `exportWizard` workflow. The shape matters more than the wording — copy the
structure, not the copy.

```jsonc
"club-export-package": {
  "initialState": "ready",
  "visibility": { "default": "guarded",
                  "readGuard": { "allowedRoleIds": ["club-organizer"] } },

  "instanceDataSchema": {
    "exportLabel":   { "type": "text",   "required": true },
    "exportScope":   { "type": "list",   "required": true,
                       "labelTemplate": "Scope: {value}" },
    "statusMessage": { "type": "text",   "writableBy": "effect" },
    "exportHistory": { "type": "list",   "writableBy": "effect" },
    "createdByFanId":{ "type": "fanId",  "required": true }
  },

  "states": {
    "ready":       { "label": "Ready to export", "tone": "info",
                     "editableFields": ["exportLabel", "exportScope"],
                     "editGuard": { "allowedRoleIds": ["club-organizer"] } },
    "generated":   { "label": "Export generated", "tone": "positive" },
    "rolled-back": { "label": "Export rolled back", "tone": "warning" },
    "cancelled":   { "label": "Export cancelled", "tone": "negative",
                     "isTerminal": true }
  },

  "transitions": [
    { "id": "change-export-scope", "action": "configure_scope",
      "label": "Change scope", "from": ["ready", "rolled-back"], "to": null,
      "guard": { "allowedRoleIds": ["club-organizer"] },
      "inputs": { "exportScope": { "type": "list", "required": true } },
      "effects": [
        { "op": "set", "key": "exportScope", "value": "{input.exportScope}" },
        { "op": "append", "key": "exportHistory",
          "value": { "action": "scope-changed", "actorFanId": "$actor", "at": "$timestamp" } }
      ] },

    { "id": "generate-export", "action": "run",
      "label": "Generate export", "tone": "primary",
      "from": ["ready"], "to": "generated",
      "guard": { "allowedRoleIds": ["club-organizer"] },
      "effects": [
        { "op": "set", "key": "statusMessage", "value": "Export generated" },
        { "op": "append", "key": "exportHistory",
          "value": { "action": "generated", "actorFanId": "$actor", "at": "$timestamp" } }
      ] },

    { "id": "rollback-export", "action": "rollback",
      "label": "Roll back", "from": ["generated"], "to": "rolled-back",
      "guard": { "allowedRoleIds": ["club-organizer"] } },

    { "id": "cancel-export", "action": "cancel",
      "label": "Cancel export", "tone": "destructive",
      "from": ["ready", "rolled-back"], "to": "cancelled",
      "guard": { "allowedRoleIds": ["club-organizer"] } }
  ],

  "renderBindings": [
    { "tabId": "admin", "audience": "any",
      "cardSurfaceFamily": "exportWizard", "bindingKind": "primary",
      "states": ["ready", "generated", "rolled-back", "cancelled"],
      "actions": [ { "kind": "create", "label": "New export" } ] }
  ]
}
```

### Why each part is the way it is

- **Every transition declares an `action`.** `exportWizard` is bespoke, so the closed vocabulary in §1
  applies and a missing `action` silently skips archetype bookkeeping (`permissions.md` §4).
- **`change-export-scope` has `"to": null`.** It edits in place without leaving `ready`. A self-loop
  written as `"to": "ready"` would work, but `null` states the intent.
- **The `renderBindings[].states` list names every state.** Omitting one hides instances sitting in it
  — the validator's `no_render_binding_for_reachable_state`.
- **There is a `create` action.** Without one, and with no `createInstance` effect anywhere, nobody can
  ever start an export: `no_creation_path_for_editable_type`.
- **`labelTemplate` on `exportScope`.** The fact-pill renderer prints the template with `{value}`
  substituted, so this field renders as `Scope: match results, rankings`. Declare it when a field
  reads better with a prefix.
- **Visibility is `guarded`.** Every one of the corpus's 14 `exportWizard` workflows is (§ opening) —
  an export contains whatever the exporter could read, so it is never `public`.
- **No per-person bookkeeping fields.** §2: this archetype owns none. Do not declare
  `downloadedFanIds`-style sets here.

### What not to do

- Do not fabricate a `checksum`, `transferId`, or `receiptId` value. Those are platform-owned
  (`platform-services.md`); declare the field if the product needs it and leave it unwritten, with a
  `NEEDS IMPLEMENTATION (platform service)` comment.
- Do not map `start-preview-export` to `run`. It is `preview` — the longer pattern wins (§1).
- Do not give a generic-family workflow an `action`. Only the six bespoke families take one.
