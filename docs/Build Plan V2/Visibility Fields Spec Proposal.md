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

**Re-derived 2026-08-18 from the validator itself**, run over all 11 shipped fixtures, replacing the
earlier `audit_visibility_expressiveness.py` numbers. The audit script was wrong and the correction
matters, so it is recorded rather than quietly overwritten.

```
missing_visibility_fields, actual validator output: 29
  Change 1 removes the requirement entirely:        18
  Still required after Change 1:                    11
     of which expressible today (enough fields):     7
     of which need Change 2 (person + non-person):   4
```

**What the audit script got wrong.** It counted 39 findings, including every `recipient`-model
workflow. The validator's `requiredKey` switch maps `VisibilityModel.recipient => null`
(`community_package_validator.dart:622-631`), so **the rule never fires for `recipient` at all** —
those 10 findings do not exist. Two rows in the original Cause A table (`book-selection-publish`,
`tabletop-meetup-announcement`) and one in §4 (`platform-top-banner-no-fill`) were therefore never
blocking anything.

The lesson is the standing one: the validator is the oracle, not a script written alongside the
analysis. The *reasoning* below survived the correction — Cause B still names exactly the same four
payment workflows — but the totals did not.

The 11 cases surviving Change 1 split into two distinct causes.

### Cause A — the rule fires on workflows that are not identity-scoped at all (18 cases)

Verified against the corpus: **every** one of these 18 has no `readGuard` at the workflow level and
none at any state, and a `default` of `membersOnly`, `public`, or unset.

| Community | Workflows | `visibility.default` |
|---|---|---|
| ChessClub | `chess-match-result`, `chess-pairing-queue`, `chess-discussion-thread`, `chess-rules-documents` | `membersOnly` |
| NeighborhoodBookClub | `book-nomination`, `book-reading-material`, `book-discussion-message` | `membersOnly` |
| Phase1_TabletopClub | `tabletop-club-dues-payment`, `game-purchase-proposal`, `discussion-thread` | unset |
| MasjidNur | `mosque-document-resource`, `mosque-discussion-thread` | `membersOnly` |
| RiversideYouthSoccer | `soccer-waiver-document`, `soccer-team-discussion` | `membersOnly` |
| AdFreeCommunity | `ad-off-community-checkout` | `membersOnly` |
| CedarCommonsHOA | `hoa-member-document` | `membersOnly` |
| GardenClub | `plant-exchange-submission` | `membersOnly` |
| CameraClub | `critique-submission` | **`public`** |

None of these gate reads on *who you are*. They gate on membership, or they are public.
`critique-submission` is the clearest: it is **public**, and the validator still demands a `parties`
mapping — a mapping that could only ever narrow a read that is already open to everyone.

**The split is total, with no ambiguous middle:** all 18 removed cases have zero guards of any kind,
and all 11 surviving cases are `guarded` *and* carry a workflow-level `readGuard`. That is a strong
signal the condition in Change 1 is drawn at the right line rather than fitted to the data.

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

## 2. Change 1 — make the requirement conditional (resolves Cause A, 18 cases)

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

## 4. The third problem — resolved, not deferred

This was filed as an open question. Re-derivation closed it: **every case in it is gone**, so nothing
carries into Phase F.

The problem was real — some workflows have enough identity fields to satisfy the arity check, but none
that *mean* "party". The fields present are **per-person bookkeeping the archetype itself owns**
(`CONTRACTS.md`: read/acknowledged/saved/downloaded sets), not access-control lists. Naming
`downloadedPersonaIds` as `sharedWith` would grant read to everyone who already downloaded the
document — circular, and worse than failing, because it passes validation while granting wrongly.

| Community | Workflow | Required key | Status |
|---|---|---|---|
| ChessClub | `chess-rules-documents` | `sharedWith` | removed by Change 1 (`membersOnly`, no guard) |
| MasjidNur | `mosque-document-resource` | `sharedWith` | removed by Change 1 |
| CedarCommonsHOA | `hoa-member-document` | `sharedWith` | removed by Change 1 |
| RiversideYouthSoccer | `soccer-team-discussion` | `participants` | removed by Change 1 (0 identity fields) |
| MemberSocialSpace | `platform-top-banner-no-fill` | `recipient` | **never a finding** — the rule does not fire for `recipient` |

That the bookkeeping-vs-party confusion lands *exclusively* on workflows with no identity-scoped
visibility is not a coincidence: a workflow that never gated reads on identity had no reason to declare
an access-control field in the first place. Change 1 removes the demand at its source.

**This also dissolves the concern recorded in the Document ACL proposal §5** about pointing
`sharedWith` at a bookkeeping array — all four `documentLibrary` cases above are Change-1 removals.

## 5. What changes, concretely

| File | Change |
|---|---|
| `docs/references/archetypes/CONTRACTS.md` | Visibility-model table: note the requirement is conditional; document role-as-party |
| `docs/references/reference/workflow-grammar.md` | `visibility.fields` shape: string-or-role-object entries |
| `docs/references/reference/identity-types.md` | §3.5 cross-reference: role-as-party is the correct home for person-plus-role |
| `docs/references/archetypes/approval-queue-item.md`, `payment-checkout.md` | §Visibility: role-as-party worked example |
| `community_package_validator.dart` | `_validateVisibilityFields`: conditional requirement; accept role objects; validate roleId against `roles[]`; keep arity at 2 |
| `.agents/skills/.../chatgpt-upload/` mirror + zip | Same guidance, regenerated |

## 5a. Engine impact — verified against the engine, 2026-08-18

The proposal previously flagged this as *"to be confirmed, not assumed."* It has now been read out of
the engine. **The required role-membership lookup exists and is reachable.**

**Change 1: zero engine impact — confirmed, not inferred.** `_isVisibleThroughArchetype`
(`local_workflow_engine_api.dart:541`) already tolerates absent fields: the `parties` and
`participants` cases call `.any(...)` over a list that defaults to `const []`, and the `sharedWith`
and `recipient` cases short-circuit on `!= null`. Dropping the validator requirement changes no engine
behaviour on any path.

**Change 2: the lookup `allowedRoleIds` uses is `_personaTypeById`, and it is already in scope.**

| Evidence | Location |
|---|---|
| `final Map<String, String> _personaTypeById = {};`, populated by explicit registration | `local_workflow_engine_api.dart:148,152` |
| `allowedRoleIds` resolves through it: `typeForAllowedCheck = personaTypeId ?? personaId` | `guard_evaluator.dart:26-31` |
| The engine feeds it in at 8 call sites, including the `guarded` read path | `local_workflow_engine_api.dart:535` |
| `_isVisibleThroughArchetype` is an instance method on that same class | `local_workflow_engine_api.dart:541` |

Because the archetype visibility resolver is a method on the class that owns the map, a role-as-party
branch can read `_personaTypeById[personaId]` directly. **No signature change, nothing becomes async,
and the semantics are identical to `allowedRoleIds` by construction** — which is exactly the
consistency the change requires.

**Two findings that qualify the estimate, both real:**

1. **`parties` is `List<String>` today**, parsed by a `stringList()` helper that rejects non-string
   entries (`workflow_models.dart:487,511`). Change 2 therefore needs a genuine model change —
   `parties` becomes a list of a two-case union (field name vs role reference) with `fromJson`
   accepting `{"role": "<roleId>"}` — not a one-line branch in the resolver. Sizeable but contained.
2. **`_personaTypeById` is populated by registration, so an unregistered viewer resolves to `null`**
   and a role-as-party entry denies. That is fail-closed and consistent with the "all models fail
   closed" clause, but it means role-as-party admits only registered viewers. Worth stating in
   `CONTRACTS.md` alongside the change rather than leaving it to be discovered.

## 6. Expected effect on Phase F

| | Findings | Running total |
|---|---|---|
| Actual validator output today | 29 | **29** |
| After Change 1 (18 no longer required) | −18 | **11** |
| After Change 2 (4 become expressible) | −4 | **7** |
| Mechanical: declare a mapping from fields that already exist | −6 | **1** |
| Residue: `platform-blocked-target` | — | **1** |

The 4 Change-2 cases are exactly the payment workflows in §3. The 6 mechanical ones —
`hoa-dues-payment`, `hoa-committee-decision`, `mosque-care-request`, `platform-message-thread`,
`platform-connection`, `soccer-guardian-join-approval` — each already declare two or more genuine
identity fields and need only the mapping written down.

`platform-blocked-target` (the one-legitimate-reader block record) is **not** resolved by either change —
it is `guarded` with a real `readGuard`, so Change 1 does not apply, and its counterparty is a person who
must *not* read it, so Change 2 does not either. Its recommended resolution remains re-homing to
`formEntry` (`roles`+`owner` visibility), decided during Phase F.
