---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.0.0
status: proposed
last_verified: 2026-08-13
audience: llm-agent
derived_from:
  - docs/Build Plan V2/CJM.16 Identity Architecture Proposal.md
  - docs/API/OpenAPI/identity/fan-passport-api.openapi.yaml
  - docs/API/OpenAPI/identity/app-access-api.openapi.yaml
---

# Identity types — `roleId` and `fanId`

**Status: PROPOSED.** This defines `workflowGrammarVersion: 2`. Packages stamped `1` keep the old
rules unchanged; the two versions are not mixed within a package.

## 1. The defect this fixes

Grammar v1 has exactly one identity type, `personaId`, and uses it for two incompatible things:

- **what kind of member is this** — `hoa-board`, `garden-coordinator`, shared by many people
- **which specific person is this** — the one individual who may read this private thread

Guards that need the second meaning are given values that only ever satisfy the first. At runtime
`$viewer` binds to a signed-in account id, so a seeded `"participantAPersonaId": "platform-member-alex"`
compared against `$viewer` can never match. Member Social Space's Messages tab — the community's entire
purpose — is permanently empty as a result.

This is not one community's bug. Ten of eleven fixtures seed a person-shaped field with a role string,
and seven have live guards checking such values. It went unnoticed through eight walkthroughs because
role-gated communities never exercise the second meaning.

**The fix is a type split**, and its real payoff is not the rename. It is that comparing a person to a
role becomes a **validator error at authoring time**. Grammar v1 cannot express that mistake *as* a
mistake, because both sides are nominally the same type.

## 2. The two types

| Type | Means | Issued by | Appears in |
|---|---|---|---|
| `roleId` | a kind of member, held by many people | the community package, in `roles[]` | guards, create-action permissions, tab visibility |
| `fanId` | one specific person, globally unique | Fan Passport | instance data, and `$actor` / `$viewer` |

The dividing line, stated once: **a `roleId` says what someone is allowed to be; a `fanId` says who
someone is.** Roles never appear as instance data values. People never appear in `roles[]`.

Nullable and array forms follow the existing convention: `fanId?`, `fanId[]`, `fanId[]?`.

## 3. What changes from v1

### 3.1 Declarations

| v1 | v2 |
|---|---|
| `experience.personas[]` | `experience.roles[]` |
| `personas[].personaId` | `roles[].roleId` |
| `personas[].roleLabel` | unchanged — it already meant the role's display name |

### 3.2 Access control keys

| v1 | v2 | Occurrences in the corpus |
|---|---|---|
| `guard.allowedPersonaIds` | `guard.allowedRoleIds` | 582 |
| `actions[].byPersonaIds` | `actions[].byRoleIds` | 70 |
| `tabs[].visiblePersonaIds` | `tabs[].visibleRoleIds` | 15 |

These were always role-based. The rename makes them say so.

### 3.3 Instance data field types

| v1 | v2 |
|---|---|
| `"type": "personaId"` | `"type": "fanId"` |
| `"type": "personaId[]"` | `"type": "fanId[]"` |

Every person-shaped instance field renames with it — `createdByPersonaId` → `createdByFanId`,
`goingPersonaIds` → `goingFanIds`, `holderPersonaId` → `holderFanId`, and so on. Around 857 keys across
the corpus.

`roleId` is legal as an instance-data type but is expected to be rare: a field holding a role rather
than a person. Nothing in the current corpus needs it.

### 3.4 `renderBindings[].role` → `renderBindings[].audience`

`role` here never meant a community role. Its values are `"actor" | "receiver" | "any"` — the *viewer's
relationship to this instance*. Keeping the name would leave two unrelated meanings of "role" in one
file, one of them now a real type. Renamed to `audience`; the three values are unchanged.

### 3.5 Formulas

`$actor` and `$viewer` are **`fanId`-typed**. That is what makes the following a type error rather than
a silent no-op:

```jsonc
// v1 — parses, never matches, no diagnostic
"formula": "$viewer == payerPersonaId || $viewer == 'masjid-admin'"

// v2 — the left comparison is fanId == fanId, fine.
//      the right compares a fanId to a declared roleId: ERROR.
"formula": "$viewer == payerFanId"
"guard": { "allowedRoleIds": ["masjid-admin"] }
```

An author who wants "this person, or anyone with this role" writes the person check as a formula and
the role check as `allowedRoleIds`. They are different layers — see `permissions.md` §2.

## 4. Validator rules added in v2

| Rule | Severity |
|---|---|
| `roles[]` present and non-empty; every entry has a `roleId` | error |
| every `allowedRoleIds` / `byRoleIds` / `visibleRoleIds` entry is a declared `roleId` | error |
| `actorEqualsField.key` names a field typed `fanId` (or `fanId?`) | error |
| `actorInList.key` names a field typed `fanId[]` | error |
| `$actor` / `$viewer` compared against a string literal that is a declared `roleId` | error |
| a v1 key (`allowedPersonaIds`, `byPersonaIds`, `visiblePersonaIds`, `renderBindings[].role`) in a v2 package | error |
| field `type` outside the known set | error — v1 left this unchecked, which is how the split stayed invisible |

The fifth rule is the one that earns the migration. Three formulas in the current corpus are broken by
exactly this mechanism and produce no diagnostic today:

| Location | Formula |
|---|---|
| Masjid Nur | `$viewer == payerPersonaId \|\| $viewer == 'masjid-admin'` |
| Neighborhood Book Club | `$viewer == recipientPersonaId \|\| $viewer == 'book-organizer'` |
| Neighborhood Book Club | `if($viewer == 'book-organizer', materialUrl, …)` |

They are deliberately **not** hand-patched. They are fixed as part of this migration so that the type
split is demonstrated to catch them, rather than asserted to.

## 5. Where `fanId` values come from

A `fanId` is issued by Fan Passport and is global — the same person carries one `fanId` across every
community, which is what makes the cross-community Messages tab possible.

Community JSON still **never contains a user**: see `permissions.md` §9. Seed instance data references
`fanId`s that provisioning creates through the real Fan Passport and App Access APIs at install time.
Authoring a literal `fanId` into a package by hand is not the intended path.

## 6. Naming, and why "persona" was freed

Fan Passport already has a `Persona`: a pseudonymity facet of one human, where one person has many.
The grammar's `personaId` was the opposite — one persona, many people — which is a role. Two systems
using the same word for inverse concepts is a defect on its own. The contract's usage came first and is
load-bearing across seven API surfaces, so the grammar's is the one that changes.

`roleId` is also what App Access has always called it, so after this migration the JSON, the derivation
in `permissions.md`, and the identity services all use one word for one thing.
