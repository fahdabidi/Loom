---
spec: 4
doc_version: 1.0.0
status: proposed
last_verified: 2026-08-14
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/permissions.md
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
---

# `documentLibrary`

A library of documents members read, acknowledge, save and download — and that a smaller group
authors, publishes and retires.

Used by 5 communities: Cedar Commons HOA, Chess Club, Masjid Nur, Neighborhood Book Club, Riverside
Youth Soccer.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md). Permission derivation:
[`../reference/permissions.md`](../reference/permissions.md).

## 1. Actions

Nineteen. Permission ids are `document_library.<action>`.

| Group | Actions |
|---|---|
| Authoring | `upload` · `edit` · `publish` · `delete` |
| Lifecycle | `archive` · `restore` |
| Reading | `view` · `open` · `download` · `mark_read` · `mark_unread` |
| Commitment | `acknowledge` |
| Personal | `save` · `unsave` |
| Access | `request_access` · `withdraw_access_request` · `grant_access` · `share` |
| Follow-up | `request_follow_up` |

`edit`, `publish` and `delete` are **new in specVersion 4**. They were added because an ordinary
policy could not be written without them — see §4.

**`archive` and `delete` are different actions on purpose.** Archiving retires a document that still
exists and can be restored; deleting removes it. A community that grants only `archive` has made a
deliberate choice that nothing is ever destroyed, and that choice should be visible in its permission
grants rather than hidden in whether it happened to declare a transition.

A transition may declare **no** `action`. It is then a community-defined action, derives its
permission structurally, and renders in the generic button row — see `CONTRACTS.md` §1.

## 2. Bookkeeping the archetype owns

Per-person state. A community declares none of these fields and writes no idempotence guard against
them.

| Field | Maintained by |
|---|---|
| `openedFanIds` | `open` |
| `acknowledgedFanIds` | `acknowledge` |
| `savedFanIds` | `save` / `unsave` |
| `downloadedFanIds` | `download` |
| `accessRequestedFanIds` | `request_access` / `withdraw_access_request` |
| `sharedWithFanIds` | `share` / `grant_access` |

Each action is **once per person**. Today every community hand-writes that as
`actorInList: { key: "openedPersonaIds", present: false }`, once per transition — six such guards in
Cedar Commons HOA alone, plus five array declarations and two derived-state formulas. All of it is the
same logic re-expressed, and all of it becomes archetype-supplied.

Read state (`hasOpened`, `hasAcknowledged`, `isSaved`) derives from these; a community never stores it.

## 3. Visibility

Model: **`owner_and_shared`**. A document is readable by

1. the roles a state's `readGuard` admits, plus
2. its owner, plus
3. anyone in `sharedWithFanIds`.

**Per-state read guards already exist** — `LoomWorkflowState.readGuard`, which the engine prefers over
the workflow-level guard (`stateGuard ?? machine.visibility.readGuard`). State-scoped visibility needs
no new grammar.

Sharing is the archetype's mechanism, not the community's. A community enables it:

```jsonc
"sharing": { "enabled": true, "grantable": ["open", "download", "edit"] }
```

`share` then populates `sharedWithFanIds` and the read model honours it. **No formula is written.**
Alex sharing a document with Casey requires nothing in community JSON.

> Read guards fail closed. An unset identity field matches nobody, so a document owned by no one is
> visible to no one. That is why seed data carrying no identity renders nothing rather than leaking.

## 4. Worked example — Cedar Commons HOA

The policy, stated in English:

> Only the HOA Board may edit, delete or publish documents. Unpublished documents are visible only to
> the Board. Published documents are viewable by all HOA members, who may view and download them.

Written against this contract:

```jsonc
"hoa-member-document": {
  "states": {
    // Drafts are Board-only. A per-state readGuard, role-based, no formula.
    "draft":     { "label": "Draft",
                   "readGuard": { "allowedRoleIds": ["hoa-board"] } },

    // Published inherits the workflow's membersOnly default: every member reads it.
    "published": { "label": "Published" },

    // Retired documents go back to Board-only.
    "archived":  { "label": "Archived", "isTerminal": false,
                   "readGuard": { "allowedRoleIds": ["hoa-board"] } }
  },

  "visibility": { "default": "membersOnly" },

  "transitions": [
    { "id": "upload-document",  "action": "upload",  "from": ["draft"],     "to": null,
      "guard": { "allowedRoleIds": ["hoa-board"] } },
    { "id": "edit-document",    "action": "edit",    "from": ["draft", "published"], "to": null,
      "guard": { "allowedRoleIds": ["hoa-board"] } },
    { "id": "publish-document", "action": "publish", "from": ["draft"],     "to": "published",
      "guard": { "allowedRoleIds": ["hoa-board"] } },
    { "id": "delete-document",  "action": "delete",  "from": ["draft"],     "to": null,
      "tone": "destructive",
      "guard": { "allowedRoleIds": ["hoa-board"] } },
    { "id": "archive-document", "action": "archive", "from": ["published"], "to": "archived",
      "guard": { "allowedRoleIds": ["hoa-board"] } },
    { "id": "restore-document", "action": "restore", "from": ["archived"],  "to": "published",
      "guard": { "allowedRoleIds": ["hoa-board"] } },

    // Member actions. No actorInList guards: `open`, `download`, `acknowledge`
    // and `save` are once-per-person by definition of the action.
    { "id": "record-open",         "action": "open",        "from": ["published"], "to": null,
      "guard": { "allowedRoleIds": ["hoa-member"] } },
    { "id": "confirm-download",    "action": "download",    "from": ["published"], "to": null,
      "guard": { "allowedRoleIds": ["hoa-member"] } },
    { "id": "acknowledge-latest",  "action": "acknowledge", "from": ["published"], "to": null,
      "guard": { "allowedRoleIds": ["hoa-member"] } },
    { "id": "save-document",       "action": "save",        "from": ["published"], "to": null,
      "guard": { "allowedRoleIds": ["hoa-member"] } }
  ]
}
```

### Permissions this derives

| Role | Permissions |
|---|---|
| `hoa-board` | `document_library.upload`, `.edit`, `.publish`, `.delete`, `.archive`, `.restore` |
| `hoa-member` | `document_library.open`, `.download`, `.acknowledge`, `.save` |

Nothing above names a permission. Every one is derived from `action` + `allowedRoleIds`, exactly as
`permissions.md` §1 describes.

### What the community no longer writes

Against the shipped Cedar Commons HOA workflow, this removes:

- 6 `actorInList` idempotence guards
- 5 `*PersonaIds` array declarations
- 2 derived-state formulas (`memberAccessState`, `downloadState`)
- every `readGuard` formula — replaced by two role lists

and adds the draft state and the three lifecycle actions the policy actually needed.

## 5. Community-defined actions

Permitted, and rendered normally. A community that needs "Send to committee for review" declares a
transition with no `action`; it derives `advance` structurally and appears in the button row. It gets
no per-person bookkeeping, because the archetype has no idea what it means — which is the honest
outcome.

## 6. Open

- **Whether `delete` should be terminal or soft.** Written above as `to: null` on a draft, which is
  the least destructive reading. A community wanting hard deletion of published documents is a
  different policy and probably wants a terminal state.
- **`sharing.grantable`** is proposed, not implemented. The engine does not yet enforce
  archetype-owned bookkeeping or the shared-with read model.
