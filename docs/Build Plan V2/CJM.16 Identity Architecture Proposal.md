# CJM.16 — Seed Identity Architecture Proposal

**Status: REVISED 2026-08-13. The diagnosis below still stands; the original recommendation does not.**

The first version of this document proposed a new package-level `seedAccounts` construct. **That design
is superseded and should not be implemented.** It invented a fourth identity concept for Loom
Communities alone, in a system that already had a designed identity model nobody had wired in.

What replaced it: **Fan Passport for identity, and a new App Access API for groups, roles, and
permissions.** The App Access service is built, running, and verified — see §7.

**Origin:** a Root Cause Agent dispatch against CJM.16 (Member Social Space's Messages tab showing zero
conversations for a freshly-signed-up account — `Community JSON Migration Tracker.md` §4 row 8),
2026-08-13. Root-caused with 0.97 confidence; blast-radius audit covered all 11 real community fixtures
by direct source read.

---

## 1. The problem in one paragraph

The community JSON grammar has exactly one identity type — `personaId` — and uses it for two genuinely
different things: **what role is this account** (e.g. `"tabletop-organizer"`, shared by many accounts)
and **which specific individual is this** (the account that should be able to read one specific private
message thread). Guards and formulas that need the second meaning (`actorEqualsField`, `actorInList`,
`$actor`/`$viewer` comparisons) are silently given values that only ever satisfy the first. Seed data is
authored before any real account exists and has no way to name one, so authors are forced to write a
persona-type string into an identity field, where it can never match.

## 2. The identity model as the grammar specifies it today

Grounded in the current reference docs:

- **`field-types.md`** — `personaId` is *"A single persona id."* No second identity type exists. Every
  identity-valued field in every fixture is typed `personaId` or `personaId[]`.
- **`formulas.md`** — `$actor` is *"the persona who performed the current transition"*, `$viewer` is
  *"the persona currently reading/querying."* No distinction between a persona *type* and an *account*.
- **`guards.md`** — `allowedPersonaIds` is explicitly role-based. `actorEqualsField` and `actorInList`
  are documented for genuinely individual cases (*"only the recipient may mark their own notification
  read"*) — but the doc never says these need a **different kind of value** in the field they check.

At runtime `$actor`/`$viewer` bind to the signed-in account's id, which `LocalAuthApi.signUp` mints as
`<personaTypeId>-<counter>`. So `$viewer == "platform-member-alex"` can never equal
`platform-member-alex-20`. `allowedPersonaIds` works because it is checked against the account's
separately-tracked `personaTypeId` — which is why role-gated communities never hit this, and why the gap
survived eight successful walkthroughs before Member Social Space exposed it.

## 3. Where it breaks

### 3.1 The triggering case

Member Social Space's personas are named **individuals** ("Alex Rivera", "Bailey Chen") rather than role
types, because it is a messaging community. A seeded thread declares:

```jsonc
"participantAPersonaId": "platform-member-alex",
"visibility": { "default": "guarded",
  "readGuard": { "formula": "$viewer == participantAPersonaId || $viewer == participantBPersonaId" } }
```

This is the only way today's grammar can express "this thread belongs to whoever signs up as Alex." It
becomes unsatisfiable the moment a real account exists. The Messages tab — the community's entire stated
purpose — is permanently empty.

### 3.2 The pervasive case

Ten of eleven fixtures seed at least one `createdByPersonaId` with a bare persona-type string, and seven
already have live `actorEqualsField`/`actorInList`/direct-formula guards checked against such values
(Ad-Free Community, Cedar Commons HOA, Chess Club, Garden Club, Masjid Nur, Neighborhood Book Club,
Riverside Youth Soccer). Data Portability Community is the sole clean case — it uses only role-wide
`allowedPersonaIds`.

## 4. What does not fix this

**Loosening `$actor`/`$viewer` to fall back to persona-type matching** is unsound. `LocalAuthApi` already
seeds twelve accounts sharing the type `tabletop-member`. A type-matching fallback would let *every*
account of a type satisfy a guard meant to gate one specific private thread or payment — converting a
per-individual privacy boundary into a role-wide one across nearly every community.

## 5. The actual architecture — Fan Passport plus App Access

The identity tier already existed and predates Loom Communities by six weeks. `LoomAccount` was built a
month and a half *later*, in parallel, because passports had no role or community concept — so a second,
disconnected identity system grew alongside the first.

### 5.1 Fan Passport owns identity

`FanPassport` (`docs/API/OpenAPI/identity/fan-passport-api.openapi.yaml`) answers *who is this user and
are they authenticated*: `fanId`, `displayName`, `privacyMode`, `publicKey`, `createdAt`. `fanId` is
already the universal identity key across every API surface in the repo — campaign, ai_gateway,
community_registry, community_ops, community_foundation, community_engine, community_experience.

**`fanId` is global and cross-community, and community code may see it.** An earlier draft of this
document argued the opposite — that a community should only ever see a per-community pseudonym. That was
wrong: the Messages tab is part of the default AppShell for *every* community and is explicitly a
cross-community surface, where one user sees messages spanning all their communities. That is
impossible without a stable identity visible across communities.

Fan Passport's own `PairwiseCreatorIdentity` remains the mechanism for fan↔creator pseudonymity. It is a
separate concern from community membership and is unaffected by anything here.

### 5.2 App Access owns groups, roles, and permissions

Rather than extend the fan/creator privacy surface with multi-tenant authorization, this is a new owned
surface: `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`. It depends on Fan Passport for
identity and never redefines it.

| Concept | Meaning | Loom Communities usage |
|---|---|---|
| **App** | tenancy root, owns a permission catalog | `loom_communities` |
| **Permission** | one declared capability | `event_rsvp.create` |
| **Group** | tenancy unit within an app | one per community |
| **Role** | named set of permissions | `cedar_commons_hoa_admin` |
| **AppAccess** | fan ↔ app, with app-level roles | "this fan may use Loom Communities" |
| **GroupMembership** | fan ↔ group, with group-scoped roles | "this fan is an admin of Cedar Commons HOA" |

A role with a `groupId` belongs to that group; a role without one is an app-level template assignable in
any group. `GroupMembership` is deliberately one record answering both *is this fan in the group* and
*as what* — it is exactly the join that community membership plus role assignment needed.

It is app-agnostic by design: no Loom Communities concept appears in the contract. `loom_communities` is
simply its first consumer.

## 6. What this changes in the community JSON grammar

The single structural change: **split the overloaded `personaId` into two distinct types.**

- **`roleId`** — a community-declared type shared by many people (what `personas[]` actually declares)
- **`fanId`** — one specific person, global, issued by Fan Passport

| Current JSON | What it means | Becomes |
|---|---|---|
| `personas[]` → `personaId` | role type | `roles[]` → `roleId` |
| field type `personaId` / `personaId[]` | **a person**, nearly always | `fanId` / `fanId[]` |
| `guard.allowedPersonaIds` | roles | `allowedRoleIds` |
| `actions[].byPersonaIds` | roles | `byRoleIds` |
| `tabs[].visiblePersonaIds` | roles | `visibleRoleIds` |
| `$actor` / `$viewer` | account id | **`fanId`** |
| `actorEqualsField.key` | a person field | must point at a `fanId` field |
| `actorInList.key` | a person list | must point at `fanId[]` |
| seed `createdByPersonaId` | person | `createdByFanId` |

The load-bearing row is the second. `goingPersonaIds`, `holderPersonaId`, `recipientPersonaId`,
`participantAPersonaId`, `createdByPersonaId` all mean a *person* and are currently typed as a *role*.
Roles legitimately appear only in guards, action permissions, and tab visibility — never as instance
data values.

**Seed data references a real `fanId`**, provisioned through Fan Passport, with membership and roles
provisioned through App Access. There is no new `seedAccounts` construct; a community package declares
which seed passports and memberships it expects, and provisioning creates them through the real APIs.

**Why this is worth the migration:** the type split makes this entire bug class *statically detectable*.
Today `$viewer == participantAPersonaId` is untypeable because both sides are nominally `personaId`.
With two types, comparing a person to a role becomes a validator error at authoring time — the current
grammar cannot even express the mistake as a mistake.

### 6.1 A naming collision to resolve

"Persona" means opposite things in the two systems:

| | Cardinality | Meaning |
|---|---|---|
| Fan Passport `Persona` | one person → **many** personas | a pseudonymity facet of one human |
| Grammar `personaId` | one persona → **many** people | a role type |

The contract's usage came first and is load-bearing across seven API surfaces. The grammar's is the
misnamed one and should become **`role`**, which is what it always was. Note `renderBindings[].role`
(`"actor" | "receiver" | "any"`) is a *third* meaning — the viewer's relationship to an instance — and
may want renaming to `audience` to avoid compounding the confusion.

## 7. What is already built

Since the first draft, the backend half is done and verified:

- **App Access OpenAPI contract** — 15 paths, 23 operations, 26 schemas, in the public repo.
- **`loom_communities` permission catalog** — 69 permissions, one per archetype action, categorized by
  `cardSurfaceFamily` so the catalog stays aligned with the grammar's own vocabulary
  (`docs/API/Examples/loom-communities-permission-catalog.json`).
- **Dart client contracts** — `loom_api_contracts` now carries `AppAccessApi` and its models.
- **A working service** — Spring Boot 3.3.5 on Java 21 over PostgreSQL 16, running on k3s, implemented
  against the contract with API interfaces generated from the spec at build time. All 23 operations,
  verified by 7 integration tests against real PostgreSQL. It lives in a separate private repository;
  this public repo publishes contracts only.

What remains is the **client half**: adopting `fanId` in the app shell, retiring `LoomAccount`'s
parallel identity model, and migrating the grammar and fixtures per §6.

## 8. Open questions

1. **Migration sequencing.** §6 touches ten communities' seed data. One pass, or staged — Member Social
   Space first, since it is the only community where this is a visible, blocking failure today, with the
   other nine currently latent?
2. **Grammar rename scope.** `personaId` → `roleId` touches every fixture, the Skill's instructions, and
   the validator. Do it as one atomic grammar version bump (`workflowGrammarVersion: 1 → 2`), or
   introduce `fanId` fields first and rename later?
3. **`renderBindings[].role`** — rename to `audience`, or accept the overload?
4. **Two suspicious literals.** `$viewer == 'masjid-admin'` and `$viewer == 'book-organizer'` are broken
   by this same mechanism but read like they were *meant* to be role checks (`allowedRoleIds`). Likely
   plain authoring mistakes needing a one-line guard-type fix rather than migration — worth checking
   each product doc before assuming otherwise.
5. **Provisioning flow.** When a community package is installed, what creates its App Access group,
   roles, and memberships? A registration step at install time is the obvious answer, but it is not
   designed yet.

## 9. Out of scope here

- **CJM.18** (Data Portability cross-community sign-up failure) — its Root Cause Agent report stands: a
  statically-confirmed stale-closure defect in `_authApiForCommunity`, independent of this identity
  question, with a concrete fix and two regression tests specified.
- **Fan↔creator pseudonymity** — `PairwiseCreatorIdentity` is a separate concern, unaffected.
- **Any implementation on the client side.** The backend is built; the app-shell migration in §6 is a
  proposal awaiting the decisions in §8.
