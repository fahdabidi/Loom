# CJM.16 — Seed Identity Architecture Proposal

**Status: PROPOSAL, awaiting review. Nothing in this doc is implemented or locked.** No code, JSON
fixture, or spec doc has been changed as part of this proposal. CJM.16 and CJM.18 implementation work is
paused pending a decision on this doc — see `Community JSON Migration Tracker.md` §8.

**Origin:** a Root Cause Agent dispatch against CJM.16 (Member Social Space's Messages tab showing zero
conversations for a freshly-signed-up account — `Community JSON Migration Tracker.md` §4 row 8),
2026-08-13. Full raw report: `data/v3_rootcause_cjm16_STATUS.md` (gitignored, host/VM-local — ask if you
need the verbatim file; this doc is the distilled, organized version of its findings plus my own
review). Root-caused with 0.97 confidence; blast-radius audit covered all 11 real community fixtures by
direct source read, not sampling.

---

## 1. The problem in one paragraph

The JSON grammar has exactly one identity type — `personaId` — and uses it for two genuinely different
things: **"what role/type is this account"** (e.g. `"tabletop-organizer"`, shared by many accounts) and
**"which specific individual account is this"** (e.g. the actual signed-up account that should be able
to read a specific private message thread). Guards and formulas that need the second meaning
(`actorEqualsField`, `actorInList`, `$actor`/`$viewer` formula comparisons) are silently given values
that only ever satisfy the first meaning, because seed data is authored before any real account exists
and has no way to name one. The result: every private, per-individual guard checked against seeded data
is unsatisfiable by design, not by bug — it was never possible for a freshly signed-up account's real ID
to equal the bare persona-type string seed data was forced to use as a placeholder.

## 2. The current identity model, as actually specified today

Grounded directly in the current reference docs (re-read for this proposal, not from memory):

- **`field-types.md`**: `personaId` is documented as *"A single persona id"* — no second identity type
  exists in the grammar. Every identity-valued field in every community fixture — participant, owner,
  creator, recipient, holder, blocker, moderator — is typed `personaId` or `personaId[]`.
- **`formulas.md`**: `$actor` is documented as *"The persona who performed the current transition"* and
  `$viewer` as *"The persona currently reading/querying"* — both described in terms of "persona," with
  no documented distinction between a persona *type* and a specific signed-in *account*.
- **`guards.md`**: `allowedPersonaIds` is explicitly documented as role-based (*"the actor's `personaId`
  must be in this list"* — used for "only organizers can cancel," a role check). `actorEqualsField` and
  `actorInList`, by contrast, are documented for genuinely individual scenarios (*"only the recipient can
  dismiss their own notification," "only the assigned reviewer may approve"*) — but the doc never states
  that these two guard kinds require a **different kind of value** in the field they check than
  `allowedPersonaIds` does. All three are illustrated with plain `personaId`/`personaId[]` fields.

**What the runtime actually does** (confirmed directly against the current source, not assumed):
`LocalAuthApi.signUp` mints a real account as `accountId: '<personaTypeId>-<counter>'` — e.g. a member
signing up as persona type `platform-member-alex` gets an account id like
`platform-member-alex-20`. `$actor`/`$viewer` are bound to that real, counter-suffixed `accountId`
everywhere in the engine (formula evaluation, guard evaluation, effects, role/audience resolution — the
Root Cause Agent traced every one of these call sites; none of them perform any type-vs-account
conversion). So `$viewer == "platform-member-alex"` (a bare persona-type literal, which is what seed
data is forced to write, since no real account exists at authoring time) can **never** equal
`$viewer == "platform-member-alex-20"` (what a real signed-up account's `$viewer` actually resolves to).

`allowedPersonaIds`, by contrast, is checked against the account's separately-tracked `personaTypeId` —
a genuinely different, correctly-role-based comparison, which is why role-gated communities never hit
this bug and why the gap went unnoticed through 8 of 10 successful community walkthroughs before Member
Social Space's Messages tab exposed it.

## 3. Where this actually breaks — concrete workflow/interaction models

### 3.1 The triggering case: Member Social Space (bilateral private threads)

Member Social Space's whole product model is unusual among the 11 communities: its personas are named
**individuals** ("Alex Rivera," "Bailey Chen," "Casey Nguyen"), not role types — by design, since it's a
messaging community where the point is reaching a specific person, not a role. A seeded
`platform-message-thread` instance declares:

```jsonc
"participantAPersonaId": "platform-member-alex",
"participantBPersonaId": "platform-member-bailey",
"visibility": { "default": "guarded",
  "readGuard": { "formula": "$viewer == participantAPersonaId || $viewer == participantBPersonaId" } }
```

This is the correct, only-available way to author "this thread belongs to whoever signs up as Alex and
whoever signs up as Bailey" in today's grammar — there is no other field type or guard shape that could
express it. It is unsatisfiable the moment a real account exists, because `$viewer` will be
`platform-member-alex-20`, never `platform-member-alex`. The Messages tab — the community's core
purpose — is empty for every real account, permanently.

### 3.2 The pervasive case: per-instance ownership/creation on role-typed communities

This is not unique to Member Social Space's named-individual model. Every one of the other 9
content-bearing communities seeds at least one `createdByPersonaId` (or equivalent owner/requester
field) with a bare persona-type string — e.g. Cedar Commons HOA's seeded `hoa-export-evidence` instance
names its creator as the bare type `"hoa-board"`, not any real board member's account. Today this is
mostly latent (these fields aren't yet gated by an exact-identity guard in most of these communities —
`allowedPersonaIds`-style role gating is what's actually enforced), but the audit found **7 more
communities already have live `actorEqualsField`/`actorInList`/direct-formula guards** checked against
the same bare-type seed values (Ad-Free Community's checkout `actorEqualsField` guards, Cedar Commons
HOA's document/reservation/committee guards, Chess Club's RSVP list, Garden Club's marketplace/export
guards, Masjid Nur's donor-visibility and — independently — a literal `$viewer == 'masjid-admin'` check
that can never match any generated admin account, Neighborhood Book Club's vote/RSVP guards including a
literal `$viewer == 'book-organizer'`, Riverside Youth Soccer's guardian/coach guards). Data Portability
Community is the one true negative — it uses only role-wide `allowedPersonaIds`, so it's unaffected.

**The shape of the gap, generalized:** any time a community's product design needs "this pre-seeded
instance belongs to (or was created by, or is only visible to) one specific future individual" — a
message thread between two named people, a document a specific board member is on record having
uploaded, a payment only its specific payer can see the receipt for — today's grammar has no way to
express that distinctly from "any account of this role type." Authors are forced to write the
persona-type string into an identity field, and it silently never resolves once a real account exists.

## 4. What does NOT fix this

**Loosening `$actor`/`$viewer` resolution to fall back to persona-type matching** (the first idea
anyone reaches for) is unsound, not just imperfect. `LocalAuthApi` already seeds 12 different accounts
(`tabletop-member-03` through `-14`) sharing the single persona type `tabletop-member`. If an
owner/participant/recipient comparison fell back to type-matching, *every* account of that type would
satisfy a guard meant to gate one specific private thread, payment, or document — turning a
per-individual privacy boundary into a role-wide one. This would be a real, silent privacy regression
across every community that has more than one account per persona type (nearly all of them), not a
narrower version of the current bug. `allowedPersonaIds` already exists as the correct, honest way to
express "any account of this role" — the grammar should not grow a second, accidental way to say the
same thing with weaker guarantees.

## 5. Proposed grammar change: declared seed accounts

**Core idea:** let a community package declare a small, explicit set of **named individual accounts**
at the package level — separately from persona *types* — and let seed data reference those declared
accounts directly wherever it means one specific individual, not a role. A real sign-up then either
*claims* one of those declared slots (if the persona/scenario calls for one) or gets an ordinary
freshly-generated account (the existing, unchanged behavior), and never the two conflated.

### 5.1 Sketch of the new package-level field

```jsonc
"seedAccounts": [
  {
    "accountId": "seed-alex-rivera",
    "personaTypeId": "platform-member-alex",
    "displayName": "Alex Rivera",
    "claimPolicy": "singleClaim"
  },
  {
    "accountId": "seed-bailey-chen",
    "personaTypeId": "platform-member-bailey",
    "displayName": "Bailey Chen",
    "claimPolicy": "singleClaim"
  }
]
```

- `accountId` — a stable, package-scoped id (namespaced by the package so two different communities'
  seed accounts can never collide in `LocalAuthApi`'s single flat account lookup).
- `personaTypeId` — must name a real, declared persona; this is the type a real sign-up must select to
  become eligible to claim this slot.
- `claimPolicy` — `"singleClaim"` (exactly one real sign-up may ever claim this slot; once claimed, later
  sign-ups for that same persona type get an ordinary generated account, same as today) is the only
  policy this proposal defines. Whether a second policy is needed (e.g. for a persona type with several
  interchangeable seeded accounts, like `tabletop-member`) is an open question — see §7.

### 5.2 What changes in seed data

Every identity-valued field that means **one specific individual** (not a role) references the declared
`accountId` instead of a bare persona-type string:

```jsonc
// Before (unsatisfiable once a real account exists):
"participantAPersonaId": "platform-member-alex"

// After:
"participantAPersonaId": "seed-alex-rivera"
```

Role-wide fields (`allowedPersonaIds`, and any guard that's genuinely meant to admit "anyone of this
type") are **completely unaffected** — they keep using bare persona-type strings exactly as today. This
proposal only touches the individual-identity case.

### 5.3 What changes at sign-up

When a real account signs up for a persona type that has a `singleClaim` seed account still unclaimed,
`LocalAuthApi.signUp` binds that real account to the seeded `accountId` (so it inherits the seeded
thread/document/payment) instead of minting a fresh counter-suffixed id. Once claimed, later sign-ups for
the same type fall back to today's ordinary behavior, unchanged.

### 5.4 What does NOT change

- The engine's `$actor`/`$viewer` resolution itself — no change. They still resolve to a real
  `accountId`; the fix is that seed data now names a real, claimable `accountId` instead of a type
  string that could never become one.
- `allowedPersonaIds` and every role-based guard — untouched.
- Communities/workflows that don't need per-individual seed identity (the large majority of already-shipped
  content) — untouched; `seedAccounts` is opt-in per package, empty/absent by default.

## 6. What this would actually require, if approved

Sequenced roughly by dependency, not yet a ticket breakdown:

1. **Spec docs first** (`workflow-grammar.md`, `field-types.md`, `guards.md`, possibly a new section or a
   dedicated `identity.md`) — define `seedAccounts`, the claim mechanism, and validator rules
   (`dangling_seed_account_persona_type`, `unclaimed-slot-references`, etc.) as the new normative
   grammar. Spec docs are hand-authored by me directly, same as always — not Skill-dispatched.
2. **Engine changes** — `LoomExperienceDefinition`/package parser to carry `seedAccounts`
   (`part11_shell_models.dart`, `part15_evidence_catalog.dart`), `LocalAuthApi.signUp`/`seedAccounts`
   claim logic, prefill-resolver fixes for live-created data (`part01_local_extension_screen.dart`'s
   `activePersona.accountId ?? activePersona.personaId` fix the Root Cause Agent also flagged as a
   related, smaller asymmetry). Dispatched as normal Implementation Agent ticket(s).
3. **Migration of existing fixtures** — every identity-valued field the audit found (§3.2's list) needs
   its bare persona-type literal replaced with a declared `accountId` reference, across the ~10 affected
   communities. This is community JSON content, so it goes through the `loom-calendar-experience-authoring`
   Skill dispatch, never hand-edited — meaning the Skill itself needs to learn this new pattern first
   (a Skill-definition update, same sequencing this project has followed for every other grammar
   promotion), then each affected community gets its own narrow, targeted-edit dispatch (matching the
   Milestone 2 precedent: full current file + exact field-by-field edit list, not a blind re-authoring
   run) rather than a full regeneration.
4. **Re-verification** — every migrated community needs its validator pass re-confirmed and, for
   Member Social Space specifically, a live re-walkthrough proving the Messages tab now shows real
   conversations for a freshly-signed-up account.

## 7. Open questions — need your decision, not mine to assume

1. **Multi-account persona types.** `tabletop-member` has 12 seeded accounts sharing one type. Does any
   real scenario need "this specific pre-seeded row belongs to one of *several* interchangeable seeded
   individuals, member's choice"? If so, `claimPolicy` needs a second mode (e.g. `"anyOfSet"` naming
   several candidate `accountId`s) — not designed in this proposal, since no concrete case that needs it
   was found in the audit. Confirm whether to add it now or leave it out until a real case appears.
2. **Naming.** `seedAccounts` / `accountId` / `claimPolicy` are working names, not final. Would you rather
   this concept read as "principals," "named participants," something else?
3. **Scope of the migration.** §6 step 3 touches ~10 communities' worth of seed data. Do you want this
   done as one large migration pass, or staged (e.g. Member Social Space first, since it's the one
   community where this is a visible, blocking product failure today; the other 9 are currently latent,
   not yet user-visible)?
4. **`masjid-admin`/`book-organizer` literal-viewer bugs.** The audit found two guards
   (`$viewer == 'masjid-admin'`, `$viewer == 'book-organizer'`) that are broken by this same mechanism but
   read like they were *meant* to be role checks (`allowedPersonaIds: ["masjid-admin"]`), not individual
   ones — possibly simple authoring mistakes rather than cases needing the new `seedAccounts` mechanism.
   Worth a quick look at each product doc before assuming they need migration rather than a one-line
   guard-type fix.

## 8. Explicitly out of scope for this doc

- CJM.18 (Data Portability cross-community sign-up bug) — paused, sequenced after this proposal is
  resolved, per your instruction. Its own Root Cause Agent report (a real, statically-confirmed
  stale-closure defect in `main.dart`'s `_authApiForCommunity`, independent of this identity question) is
  preserved and ready to act on whenever we return to it.
- Any implementation, JSON edit, or spec-doc lock — this entire document is a proposal for review.
