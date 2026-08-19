---
spec: 4
doc_version: 1.1.0
status: current
last_verified: 2026-08-17
audience: llm-agent
derived_from:
  - docs/Build Plan V2/CJM.16 Identity Architecture Proposal.md
  - docs/API/OpenAPI/identity/fan-passport-api.openapi.yaml
  - docs/API/OpenAPI/identity/app-access-api.openapi.yaml
---

# Identity types — `roleId` and `fanId`

**Status: CURRENT.** This defines `specVersion: 4`. Packages stamped `1` or `2` keep the old
rules unchanged; the two versions are not mixed within a package. Ratified 2026-08-17: reviewed
against the corpus and found sound, with one correction to the motivating example below.

## 1. The defect this fixes

Grammar v1 and v2 have exactly one identity type, `personaId`, and use it for two incompatible things:

- **what kind of member is this** — `hoa-board`, `garden-coordinator`, shared by many people
- **which specific person is this** — the one individual who may read this private thread

Guards that need the second meaning are given values that only ever satisfy the first. At runtime
`$viewer` binds to a signed-in account id, so a seeded `"participantAPersonaId": "platform-member-alex"`
compared against `$viewer` can never match — a real, present defect in guard/formula correctness,
independent of any particular tab.

**Correction (2026-08-17):** an earlier version of this section additionally claimed this defect was
why "Member Social Space's Messages tab — the community's entire purpose — is permanently empty." That
part is no longer accurate on its own: `messages` was separately locked 2026-08-16 as a fixed,
system-provided App Shell tab that renders unconditionally and ignores community-declared
`renderBindings` targeting it entirely (`antipatterns.md` AP-14) — a real fixture like Member Social
Space that still targets `tabId: "messages"` (see `guide/03-common-patterns.md` P6) needs that separate,
deliberately deferred fix regardless of this identity-type split. Fixing the `personaId`/`fanId`
confusion below remains correct and necessary on its own merits — it just does not, by itself, make that
particular tab render.

This is not one community's bug. Ten of eleven fixtures seed a person-shaped field with a role string,
and seven have live guards checking such values. It went unnoticed through eight walkthroughs because
role-gated communities never exercise the second meaning.

**The fix is a type split**, and its real payoff is not the rename. It is that comparing a person to a
role becomes a **validator error at authoring time**. Grammar v1 and v2 cannot express that mistake *as* a
mistake, because both sides are nominally the same type.

## 2. The two types

| Type | Means | Issued by | Appears in |
|---|---|---|---|
| `roleId` | a kind of member, held by many people | the community package, in `roles[]` | guards, create-action permissions, tab visibility |
| `fanId` | one specific person, globally unique | Fan Passport | instance data, and `$actor` / `$viewer` |

The dividing line, stated once: **a `roleId` says what someone is allowed to be; a `fanId` says who
someone is.** Roles never appear as instance data values. People never appear in `roles[]`.

Nullable and array forms follow the existing convention: `fanId?`, `fanId[]`, `fanId[]?`.

## 3. What changes from v2

### 3.1 Declarations

| v1 and v2 | v3 |
|---|---|
| `experience.personas[]` | `experience.roles[]` |
| `personas[].personaId` | `roles[].roleId` |
| `personas[].roleLabel` | unchanged — it already meant the role's display name |

### 3.2 Access control keys

| v1 and v2 | v3 | Occurrences in the corpus |
|---|---|---|
| `guard.allowedPersonaIds` | `guard.allowedRoleIds` | 582 |
| `actions[].byPersonaIds` | `actions[].byRoleIds` | 70 |
| `tabs[].visiblePersonaIds` | `tabs[].visibleRoleIds` | 15 |

These were always role-based. The rename makes them say so.

### 3.3 Instance data field types

| v1 and v2 | v3 |
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
// before v3 — parses, never matches, no diagnostic
"formula": "$viewer == payerPersonaId || $viewer == 'masjid-admin'"

// v3 — the left comparison is fanId == fanId, fine.
//      the right compares a fanId to a declared roleId: ERROR.
"formula": "$viewer == payerFanId"
"guard": { "allowedRoleIds": ["masjid-admin"] }
```

An author who wants "this person, or anyone with this role" writes the person check as a formula and
the role check as `allowedRoleIds`. They are different layers — see `permissions.md` §2.

**For read visibility specifically, there is a direct construct — use it.** The two conditions inside a
single guard are ANDed, so a `readGuard` cannot express *"the payer **or** the treasurer"* by combining
a formula with `allowedRoleIds`; that yields "the payer **and** a treasurer", which is not what any of
these workflows mean. This is the actual reason the broken `$viewer == 'role-id'` formulas keep getting
written — authors reach for the only shape that looks like an OR.

The correct home is a role reference in `visibility.fields.parties`
([`workflow-grammar.md`](workflow-grammar.md) § *A party may be a role*):

```jsonc
"visibility": {
  "default": "guarded",
  "readGuard": { "actorEqualsField": { "key": "payerFanId" } },
  "fields": { "parties": ["payerFanId", { "role": "masjid-admin" }] }
}
```

The archetype visibility models **widen** — they are evaluated in addition to the `readGuard`, never
instead of it — so this reads as the OR the author intended, while each layer stays type-correct: the
guard compares `fanId` to `fanId`, and the role reference resolves through the same role lookup
`allowedRoleIds` uses.

## 4. Validator rules added in specVersion 4

| Rule | Severity |
|---|---|
| `roles[]` present and non-empty; every entry has a `roleId` | error |
| every `allowedRoleIds` / `byRoleIds` / `visibleRoleIds` entry is a declared `roleId` | error |
| `actorEqualsField.key` names a field typed `fanId` (or `fanId?`) | error |
| `actorInList.key` names a field typed `fanId[]` | error |
| `$actor` / `$viewer` compared against a string literal that is a declared `roleId` | error |
| a legacy key (`allowedPersonaIds`, `byPersonaIds`, `visiblePersonaIds`, `renderBindings[].role`) in a specVersion 4 package | error |
| field `type` outside the known set | error — v1 and v2 left this unchecked, which is how the split stayed invisible |

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
