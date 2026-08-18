---
spec: 4
doc_version: 1.0.0
status: proposed
last_verified: 2026-08-18
audience: llm-agent
derived_from:
  - docs/references/archetypes/document-library.md
  - docs/references/archetypes/CONTRACTS.md
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
  - docs/Build Plan V2/Visibility Fields Spec Proposal.md
---

# Document sharing — from a flat list to a per-permission ACL

**Status: PROPOSED.** Raised by the user 2026-08-18 while reviewing the `visibility.fields` proposal.
Deliberately **decoupled** from that proposal: Changes 1 and 2 there unblock Phase F, this does not need
to, and coupling them would stall Phase F behind a feature no shipped community currently uses (§5).

## 1. What exists today, verified

A `documentLibrary` document is readable by:

1. the roles the state's `readGuard` admits, **plus**
2. its owner, **plus**
3. everyone named in the single field given by `visibility.fields.sharedWith`.

Confirmed in the engine — `local_workflow_engine_api.dart:551` (`VisibilityModel.ownerAndShared`) reads
`fields.sharedWith` and list-matches the viewer against it.

**Two limits follow:**

- **One permission level.** "Shared" means "can read". There is no read / comment / edit distinction,
  so a community cannot express *"Casey may view this, Bailey may edit it."*
- **Individuals only.** The list holds `fanId`s. There is no way to share with a **group** — the ordinary
  case of "share this with the Board".

The richer construct the archetype doc sketches —
`"sharing": { "enabled": true, "grantable": ["open", "download", "edit"] }` — is **entirely
unimplemented**: zero occurrences across the engine and the app shell. `document-library.md` §6 says so.
(Its adjacent claim that the shared-with *read model* is unimplemented is **stale** — that part works.)

## 2. The proposed model

Split cleanly along the line the archetype contract already draws — *"Sharing is the archetype's
mechanism, not the community's"*:

### 2.1 Authoring time — community JSON declares policy only

```jsonc
"sharing": {
  "enabled": true,
  "levels": ["read", "comment", "edit"]
}
```

`levels` is the **closed set this community permits granting**, ordered weakest to strongest. A community
that only wants view-sharing declares `["read"]`. Omitting `sharing` entirely means no sharing, which is
today's behaviour for every shipped community.

**Community JSON gets simpler, not more complex.** No `visibility.fields.sharedWith` mapping, no guard,
no bookkeeping declarations — the archetype owns all of it.

### 2.2 Runtime — the archetype owns the state

```jsonc
"sharedWith": {
  "read": [ "fan_abc", { "role": "hoa-board" } ],
  "edit": [ "fan_xyz" ]
}
```

Replaces the flat `sharedWithFanIds`. Archetype-owned bookkeeping: populated by the existing `share` and
`grant_access` actions (which gain a level argument), never hand-authored, never seeded.

### 2.3 The principal abstraction — shared with the `parties` proposal

Each entry is a **principal**, which is either:

| Form | Means |
|---|---|
| `"someFanIdField"` *(string)* | the person named in that instance-data field |
| `{ "role": "<roleId>" }` | anyone holding that declared role |

**This is the same primitive Change 2 of the `visibility.fields` proposal introduces for `parties`.**
Both need "a person **or** a role"; defining it once and reusing it across `parties`, `sharedWith`,
`participants` and `recipient` keeps the grammar coherent instead of growing four dialects. **If both
proposals proceed, the principal type should be specified once, in `identity-types.md`, and referenced
from each model.**

`<roleId>` must be declared in `experience.roles[]`; a dangling role is an error, exactly as for
`allowedRoleIds`.

### 2.4 Read and write semantics

- **Read visibility:** a viewer is admitted if they are a principal at **any** level. Stronger levels
  imply read — an `edit` grant does not also need a `read` grant.
- **Action gating:** an action requiring level *L* is permitted if the actor is a principal at *L* or
  stronger, per the `levels` ordering. `edit` therefore admits an editor but not a reader.
- **Fail closed:** an absent or empty ACL admits nobody. This preserves today's rule — *"An unset or
  empty list admits nobody — never everybody"* — and is why stripped seed identities render nothing
  rather than leaking.
- **Owner and role paths are unchanged and additive:** owner always reads; the state's `readGuard` roles
  always read. The ACL only ever **adds** readers.

## 3. Why not extend the flat list

Two alternatives were considered and rejected:

- **Parallel fields per level** (`sharedWithReadFanIds`, `sharedWithEditFanIds`, …) — multiplies
  bookkeeping fields per level, cannot express groups, and pushes the level vocabulary into field names
  where the validator cannot check it.
- **A `grants[]` array of `{principal, level}` objects** — equivalent in power, but makes the common
  query ("may this viewer read?") a scan with a level comparison, where the map form makes it a direct
  lookup. The map also matches how the question is actually asked at render time.

## 4. Implementation scope — this is a feature, not a rule fix

| Layer | Work |
|---|---|
| **Engine** | New `sharedWith` map shape; `ownerAndShared` read model resolves principals incl. role membership; `share`/`grant_access` populate at a level; action gating by level |
| **Validator** | `sharing.levels` is a non-empty ordered list; role principals resolve to declared roles; reject hand-authored/seeded `sharedWith` (archetype-owned) |
| **App shell** | A real share affordance — pick a person or role, pick a level, show current grants, revoke |
| **Docs** | `document-library.md` §3/§6, `CONTRACTS.md` documentLibrary row and the visibility table |

**Engine dependency to confirm before building:** role-principal resolution must go through the same
role-membership lookup `allowedRoleIds` already uses. This is stated as a requirement to verify, **not**
an assumption — the same open item as Change 2.

## 5. Migration impact — none

All five `documentLibrary` workflows in the corpus are `visibility.default: membersOnly` with **no**
`readGuard`:

| Community | Workflow |
|---|---|
| CedarCommonsHOA | `hoa-member-document` |
| ChessClub | `chess-rules-documents` |
| MasjidNur | `mosque-document-resource` |
| NeighborhoodBookClub | `book-reading-material` |
| RiversideYouthSoccer | `soccer-waiver-document` |

**No shipped community uses per-document sharing today.** Their `sharedWith` findings are resolved by
Change 1 of the other proposal (the requirement stops firing on non-identity-scoped workflows), so this
work is **greenfield** — no fixture migration, no back-compat burden, and nothing here blocks Phase F.

That is also why the "point `sharedWith` at a bookkeeping array" problem (Visibility proposal §4)
dissolves for `documentLibrary`: the archetype owns the ACL, so no community ever names a field for it.

## 6. Open questions

- **Level vocabulary.** `["read", "comment", "edit"]` is proposed. The existing `grantable` sketch used
  action names (`["open", "download", "edit"]`). Levels that name *capabilities* compose better with the
  19-action vocabulary than levels that name individual actions — but the mapping from level to permitted
  actions needs stating explicitly.
- **Revocation.** `share`/`grant_access` add; nothing removes. A `revoke_access` action is implied and
  is not in the current 19.
- **Link sharing / "anyone with the link"** is deliberately out of scope — it implies unauthenticated
  access, which the read model has no concept of.
- **Inheritance** (folder- or collection-level grants) is out of scope; there is no collection object.

## 7. Sequencing

1. **Visibility proposal Changes 1 + 2** — unblocks Phase F.
2. **Phase F** — fixture regeneration, all 11 communities.
3. **This proposal** — after Phase F, generalising the principal type introduced in step 1.

Deliberately last: it is the only one of the three that no shipped community needs today, and doing it
after Phase F means it builds on a corpus already migrated to `specVersion: 4`.
