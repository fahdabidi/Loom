---
spec: 4
doc_version: 1.2.0
status: proposed
last_verified: 2026-08-26
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/permissions.md
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
  - docs/API/OpenAPI/community-surfaces/document-library-api.openapi.yaml
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
3. anyone in the field named by `visibility.fields.sharedWith`.

The community names that field; the archetype does not fix it (decision D9, 2026-08-14 —
[`workflow-grammar.md`](../reference/workflow-grammar.md)'s `visibility.fields`). Conventionally
`sharedWithFanIds`:

```jsonc
"visibility": {
  "default": "membersOnly",
  "fields": { "sharedWith": "sharedWithFanIds" }
}
```

An unset or empty list admits nobody — never everybody.

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

## 3a. Where a document's content lives

A library holds **stored** documents or **linked** ones. Both are real products. The workflow has to
say which, because the two differ in who holds the bytes, what a member does to add one, and what
happens when the source disappears.

**Linked.** The community declares a `url` field. A member pastes an address when creating the
document, and Loom stores nothing but the address. This is what every community shipped before
2026-08-26 and what four of the five still do — a list of khutbah notes, book guides or rules PDFs
that live in a provider's drive. A linked document's content is only as durable as somebody else's
link.

**Stored.** The workflow declares an `upload` transition. A member holding it uploads a file through
the Document Library API
([`document-library-api.openapi.yaml`](../../API/OpenAPI/community-surfaces/document-library-api.openapi.yaml)),
which stores the bytes, records the document against the instance, and writes the content reference
into the instance field the upload named.

> **`upload` is a capability, not a label.** The Document Library API derives permission to store
> files from the presence of an `upload` transition a fan can invoke. A transition that declares
> `upload` but merely sets a URL from a member's input is therefore not a naming quibble: it hands
> out file-storage authority for a paste. The validator rejects that as
> `document_upload_stores_no_content`, and reports a library with no `upload` at all as
> `document_library_is_link_only` — a warning, because a link library is a legitimate choice, not a
> mistake.

### Authoring a stored library

Three things, and only the first is new:

```jsonc
"transitions": [
  // 1. The upload capability. Guarded like any other authoring action.
  { "id": "upload-document", "action": "upload", "from": ["draft"], "to": null,
    "guard": { "allowedRoleIds": ["hoa-board"] } }
],

"instanceDataSchema": {
  // 2. The field the stored document fills. `writableBy: "effect"` because the
  //    platform writes it and a member must not be able to type into it -- that
  //    is the difference between a stored document and a linked one.
  "documentUrl": { "type": "url", "writableBy": "effect", "storage": "inline" }
}
```

3. Nothing else. There is no bucket to name, no size to configure, no storage permission to declare.
A community that grants `upload` to a role has said everything the platform needs.

The field stays `type: "url"`: the reference the platform writes *is* a URL, and it carries no token,
so it is safe to keep in instance data — which a signed URL would not be, since instance data is
readable by everyone the workflow admits.

**A stored library must not also require a member-supplied URL.** If `documentUrl` is `required` and
`writableBy: "formEntry"`, a member cannot create the document without typing an address, and the
upload has nothing left to do. Make the content field `writableBy: "effect"` and never `required`.

### Reading a stored document

`GET /v1/communities/{communityId}/instances/{instanceId}/documents` lists the documents a viewer may
read; the content endpoint streams the bytes. Neither needs anything in the package: the reader set
is the instance's, resolved exactly as §3 describes.

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
- **Archetype-owned bookkeeping** is still not enforced. The per-person fields in §2 are maintained
  by whatever the community writes, so the `actorInList` guards this contract promises to remove are
  still being written by hand.

### Closed since 1.1.0

- **`sharing.grantable` is implemented** (2026-08-26). A fan in the field named by
  `visibility.fields.sharedWith` may invoke transitions whose action is in the contract's grantable
  set — `open`, `download`, `edit` for this archetype. The grant is an alternative to a transition's
  guard rather than a clause within it, because guards combine with AND and have no combinator, so a
  grant expressed as a guard clause would narrow access instead of widening it.

  The grantable set comes from the contract and never from community JSON. A package that could name
  its own would be able to add `delete` and hand one person the power to destroy a document the
  community reserves to a role, so lifecycle actions — `publish`, `archive`, `delete`, `create` — are
  ungrantable by construction.

  Populating the shared-with field is still the community's own business: `share` and `grant_access`
  are in the vocabulary, but nothing supplies the list automatically, and a field declared
  `writableBy: "None"` can be honoured and never filled.

- **The shared-with read model is enforced** (and was before 1.1.0 was written — the note claiming
  otherwise was stale). `_isVisibleThroughArchetype` admits a shared-with fan ahead of the visibility
  default.

- **A state's `readGuard` narrows under any default** (2026-08-26). It was previously consulted only
  when `visibility.default` was `guarded`, so the pairing this document's §4 example depends on —
  `membersOnly` with board-only guards on `draft` and `archived` — silently admitted every member.
  §3's claim that the engine "prefers" the state guard is now true as written.
