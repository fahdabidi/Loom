---
spec: 4
doc_version: 1.0.0
status: proposed
last_verified: 2026-08-18
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/identity-types.md
  - app/packages/tooling/loom_ux_judges/lib/src/validator/community_package_validator.dart
---

# `visibility.fields` — two spec changes, and one open question

**Status: PROPOSED.** User-approved in principle 2026-08-18; this document is the concrete form for
review before implementation.

Phase F is blocked corpus-wide by `missing_visibility_fields`. Investigating it showed the findings are
not one problem but three, and that **two of them cannot be fixed by authoring** — the grammar cannot
express what the communities actually mean.

## 1. The evidence

Every workflow whose archetype uses a visibility model that reads instance-data identities was checked
against the identity fields it actually declares (script: `audit_visibility_expressiveness.py`, run
against all 11 shipped fixtures).

```
TOTAL findings needing visibility.fields: 39
  SATISFIABLE (enough identity fields exist): 28
  UNSATISFIABLE (cannot be expressed today):  11
```

The 11 unsatisfiable cases split into two distinct causes.

### Cause A — the rule fires on workflows that are not identity-scoped at all (7 cases)

| Community | Workflow | Model | `visibility.default` | `readGuard` | identity fields |
|---|---|---|---|---|---|
| ChessClub | `chess-match-result` | parties | `membersOnly` | none | 0 |
| ChessClub | `chess-pairing-queue` | parties | `membersOnly` | none | 0 |
| NeighborhoodBookClub | `book-selection-publish` | recipient | **`public`** | none | 0 |
| NeighborhoodBookClub | `book-nomination` | parties | `membersOnly` | none | 1 |
| Phase1_TabletopClub | `tabletop-club-dues-payment` | parties | unset | none | 0 |
| Phase1_TabletopClub | `tabletop-meetup-announcement` | recipient | unset | none | 0 |
| AdFreeCommunity | `ad-off-community-checkout` | parties | `membersOnly` | none | 1 |

None of these gate reads on *who you are*. They gate on membership, or they are public. `book-selection-publish`
is the clearest: it is **public**, and the validator still demands a `recipient` mapping.

`CONTRACTS.md` defines these models as **additive** — `roles` → "**plus:** the owner" → "**plus:** the two
named sides". A workflow that is already `public` or `membersOnly` has nothing for `parties`/`recipient`
to add. **The rule keys off the archetype alone and never asks whether identity-scoped visibility is in
play.**

### Cause B — one identified person plus a non-person counterparty (4 cases)

| Community | Workflow | Its one identity field | What its `readGuard` reveals |
|---|---|---|---|
| AdFreeCommunity | `ad-off-member-checkout` | `memberPersonaId` | `actorEqualsField: memberPersonaId` |
| AdFreeCommunity | `ad-off-receipt-evidence` | `memberPersonaId` | `actorEqualsField: memberPersonaId` |
| MasjidNur | `mosque-donation-payment` | `payerPersonaId` | `$viewer == payerPersonaId \|\| $viewer == 'masjid-admin'` |
| RiversideYouthSoccer | `soccer-registration-payment` | `guardianPersonaId` | `allowedPersonaIds: [soccer-guardian, soccer-coach]` |

All four are payments. The second party is **the community** — a club, a mosque, a soccer org. It is not a
person, so no instance-data field can name it, and `parties` requires exactly two.

**This is also the root of a bug already tracked separately.** `mosque-donation-payment`'s guard is
`$viewer == payerPersonaId || $viewer == 'masjid-admin'` — one of the seven documented always-false
identity-vs-role comparisons. Communities keep reaching for that broken construct because what they mean
is *"this person, plus whoever holds role X"*, and the grammar has no way to say it. **The broken
comparisons are a symptom of Cause B, not an unrelated defect.**

## 2. Change 1 — make the requirement conditional (resolves Cause A, 7 cases)

**Today:** the validator requires `visibility.fields.<key>` whenever the workflow's archetype has an
identity-reading visibility model, regardless of that workflow's own `visibility`.

**Proposed:** require it only when the workflow's own `visibility` actually engages the identity-scoped
layer — that is, when `visibility.default` is `guarded`, **or** a `readGuard` is declared.

When `visibility.default` is `public` or `membersOnly` and no `readGuard` is present, the archetype's
identity model adds nothing, and no mapping is required. Declaring one anyway stays legal.

**No grammar change.** This is a validator rule correction; the additive semantics in `CONTRACTS.md`
already imply it.

## 3. Change 2 — allow a role as a party (resolves Cause B, 4 cases)

**Today:** `visibility.fields.parties` must name exactly two **instance-data field names**, both
`fanId`-typed.

**Proposed:** an entry may be either an instance-data field name (as now) **or** a role reference:

```jsonc
"visibility": {
  "default": "guarded",
  "fields": {
    "parties": ["payerFanId", { "role": "masjid-admin" }]
  }
}
```

- A **string** entry means "the person named in this instance-data field" — unchanged.
- An **object** entry `{"role": "<roleId>"}` means "anyone holding this declared role".
- `<roleId>` must be declared in `experience.roles[]` — same rule as `allowedRoleIds`, and a dangling
  role is an error.
- The exactly-two arity is **retained**. Its purpose — forcing the author to name both sides explicitly
  rather than letting the engine guess — is preserved, and D9's rationale ("a read model that guesses
  would grant access it was never told to grant") still holds.

**Why a role reference rather than a `$community` sentinel.** Every Cause-B case has a real declared role
standing in for the community: AdFree's `ad-off-owner`, Masjid's `masjid-admin`, Riverside's
`soccer-coach`. A role reference expresses this precisely, needs no new sentinel vocabulary, and — unlike
a sentinel — also gives the seven broken `$viewer == 'role'` comparisons a correct home, matching the
two-layer split `identity-types.md` §3.5 already describes. If a genuine no-role counterparty appears
later, a sentinel can be added then; it is not needed now.

## 4. Open question — a third problem this surfaced

**Some "satisfiable" cases have enough identity fields, but none that mean "party".** The fields present
are **per-person bookkeeping the archetype itself owns** (`CONTRACTS.md`: read/acknowledged/saved/
downloaded sets), not access-control lists:

| Community | Workflow | Required key | Only candidate fields |
|---|---|---|---|
| ChessClub | `chess-rules-documents` | `sharedWith` | `downloadedPersonaIds` |
| MasjidNur | `mosque-document-resource` | `sharedWith` | 7 fields, all bookkeeping |
| CedarCommonsHOA | `hoa-member-document` | `sharedWith` | 5 fields, all bookkeeping |
| MemberSocialSpace | `platform-top-banner-no-fill` | `recipient` | `reasonInspectedByPersonaIds` |

Naming `downloadedPersonaIds` as `sharedWith` would grant read access to everyone who has already
downloaded it — **circular, and wrong**. These pass the arity check while producing an incorrect grant,
which is worse than failing.

Also miscounted as satisfiable by the audit: `soccer-team-discussion` has the `participants` model, **zero**
identity fields, and no arity rule — so it satisfies the check while being unable to name anyone.

**Most of these are `membersOnly` with no `readGuard`, so Change 1 resolves them** by removing the
requirement entirely. The residue should be reviewed case by case during Phase F rather than pre-decided
here. **Recommendation: adopt Changes 1 and 2 now; treat this as a Phase F review item.**

## 5. What changes, concretely

| File | Change |
|---|---|
| `docs/references/archetypes/CONTRACTS.md` | Visibility-model table: note the requirement is conditional; document role-as-party |
| `docs/references/reference/workflow-grammar.md` | `visibility.fields` shape: string-or-role-object entries |
| `docs/references/reference/identity-types.md` | §3.5 cross-reference: role-as-party is the correct home for person-plus-role |
| `docs/references/archetypes/approval-queue-item.md`, `payment-checkout.md` | §Visibility: role-as-party worked example |
| `community_package_validator.dart` | `_validateVisibilityFields`: conditional requirement; accept role objects; validate roleId against `roles[]`; keep arity at 2 |
| `.agents/skills/.../chatgpt-upload/` mirror + zip | Same guidance, regenerated |

**Engine impact:** none for Change 1. For Change 2, whichever component resolves `parties` at read time
must resolve a role reference through the same role-membership lookup `allowedRoleIds` already uses —
to be confirmed against the engine before implementation, not assumed.

## 6. Expected effect on Phase F

| | Findings |
|---|---|
| Before | 39 required, 11 unexpressible |
| After Change 1 | ~7 no longer required at all |
| After Change 2 | 4 become expressible |
| Remaining | 28 mechanical, minus those Change 1 removes; plus the §4 review items |

`platform-blocked-target` (the one-legitimate-reader block record) is **not** resolved by either change —
it is `guarded` with a real `readGuard`, so Change 1 does not apply, and its counterparty is a person who
must *not* read it, so Change 2 does not either. Its recommended resolution remains re-homing to
`formEntry` (`roles`+`owner` visibility), decided during Phase F.
