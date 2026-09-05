# Authoring a Loom Community experience — ChatGPT channel

**Read this file first.** You author community JSON for the Loom Communities workflow engine. You will
never write Dart, Flutter, or any other code, and you will never invent an API. Everything a Loom
community can do is expressed as JSON: state machines (`workflowDefinitions`), data schemas, guards,
effects, formulas, and render bindings.

**Where the reference files come from.** Every reference file named below lives in the public
repository **`fahdabidi/Loom`, branch `main`**, at the paths given. Fetch each one and read it in full
before treating anything about it as known — do not guess or reconstruct a file's content from its
name, and do not rely on general Loom knowledge you may already have. These files change over time and
their *actual current text* is the only authoritative source.

If a bundled copy of these files was uploaded alongside this document, it is a **fallback for when
fetching is unavailable**, and it may lag the repository. When both are available, the repository
wins.

This is the same access model the Codex authoring channel uses, deliberately: both channels reach the
repository the same way, so both are held to the same rules and neither can rely on context the other
cannot see.

## Updating an existing, already-shipped community — read this before step 11 of the fetch order

Most dispatch targets in this channel are **updates** to a community that already has a real, committed,
already-tested JSON package — not brand-new communities. When that's the case, the dispatching session
appends an `## Existing identifiers — preserve these exactly` section to the target product doc (step 11
below) listing the community's real, currently-declared `personas[]` (`personaId`/`label`/`roleLabel`) and
`appShell.tabs[]` (`tabId`/`label`) values.

**Reuse every listed `personaId` and `tabId` exactly as given — never invent a plausible-looking alternative,
even one that reads more naturally against the product doc's own prose.** This repo's real Dart test suite
hardcodes exact persona IDs and tab IDs per community — a JSON that invents different-but-plausible
identifiers will look completely correct in isolation and still break a real, already-passing test the
moment it replaces the shipped file. This is not something you can catch by inspecting your own draft alone;
it requires exactly the existing-identifiers list this section describes, since you have no other way to see
what the currently-shipped file or its tests actually expect. Confirmed as a real defect, not a hypothetical:
an earlier Milestone 1.5 dispatch for Masjid Nur invented `mosque-admin`/`mosque-member` (the real, existing
ones are `masjid-admin`/`community-member`) and added a `care` tab that a real committed test explicitly
asserts must never appear for that community.

### The governing principle: match or beat what ships today

**Fetch the community's currently-shipped package before authoring it.** It lives at
`docs/references/communities/Loom_Communities_Workflow_Engine_<Community>_Example.jsonc` in the same
repo you are fetching everything else from. Read it in full.

**Before anything else, check its `skillVersion` against this Skill's current version — even for the
narrowest single-field fix.** Fetch `docs/references/reference/skill-versioning.md` and compare the
package's stamped `skillVersion` (package root, beside `specVersion`; treat a missing field as `0.0.0`)
against the "Current version" at the top of that document. If the package is behind, read every
version-log entry between its stamp and current, in order, and apply each one's migration instructions
to the package **before** doing whatever this dispatch actually asked for — regardless of how small or
targeted that ask is. A version gap is never "unrelated" to a surgical fix: it means the file does not
conform to the grammar you are about to author against. Stamp the package's `skillVersion` to the
Skill's current version in your output, whether or not you found anything to migrate. Record in your
final answer which (if any) migrations you applied and which version you stamped.

Read the shipped package as **evidence of intent, not as a template to copy**. It tells you what this community
actually does today: which workflows exist, which archetypes they use, how their surfaces are wired,
what the seed data demonstrates. Your output must be **at least as capable**. Where the shipped
package solves something well, keep that solution. Where it is thin against the product doc, improve
on it. Where the product doc asks for something it never implemented, add it.

**Your package will differ from it, and that is expected.** Ids you invent, wording you write, the
number of states a workflow needs — all of that may legitimately differ. Do not try to reproduce the
shipped file byte for byte, and do not treat a difference as a defect. What is judged is whether the
result is *functionally correct and well built*, not whether it matches.

#### The one exception: identifiers that cross a package boundary

A small set of identifiers is referenced from **outside** the package — by the app shell's routing, by
permissions, by other packages, and by this repo's Dart tests. Renaming one of those is a real break,
not cosmetic drift, and nothing in your own output will reveal it.

| Preserve exactly — supplied in the `## Existing identifiers` block | Free to differ |
|---|---|
| `extensionId`, `packageId`, `communityId`, `communityHandle` | seed `instanceId`s |
| `roles[].roleId` | state ids and labels |
| `appShell.tabs[].tabId` | all copy and wording |
| `workflowDefinitions` type ids | field names beyond the rule 2a renames |
| | state and transition counts |

Add new roles, tabs or workflow types when the product doc needs them — additions are safe, renames
are not. If you believe an existing one is genuinely wrong, say so in Gaps/assumptions and keep it.

#### What "functionally correct" means — self-check against this before returning

1. **Archetype fit.** Every workflow's `cardSurfaceFamily` is the one that matches what the workflow
   actually does, re-checked against `archetypes/README.md` per workflow — not carried over from the
   shipped package if that choice was wrong.
2. **Actions.** Every bespoke-family transition declares an `action` from that family's closed
   vocabulary; every generic-family transition declares none (rule 12).
3. **Every reachable state renders — except on response-row workflows.** No state a transition path
   can reach may be missing from every `renderBindings[].states` list; a state bound nowhere is an
   instance nobody can see.
   **The exception is real and is the corpus norm:** a workflow named by some binding's
   `responseTable.workflowType` renders *through its parent's table*, not through bindings of its own,
   and correctly declares `"renderBindings": []` (rule 12a). Five of the six shipped response-row
   workflows do exactly that. The validator still emits
   `no_render_binding_for_reachable_state` for each of their states — those findings are **expected
   and correct to leave**. Do not invent bindings to silence them, and do not give a response row a
   surface of its own unless the product doc asks for one. Note it in Gaps/assumptions and move on.
4. **Every editable workflow can be created.** Writable fields with no create action and no
   `createInstance`/`generateRecurringInstances` effect means members can never make one (rule 12d).
5. **Visibility.** `visibility.fields` present exactly where rule 12b requires, absent where it does
   not, and never pointed at archetype-owned bookkeeping.
6. **Seeds.** Every seed declares `createdByFanId` (rule 12c) and demonstrates a state worth seeing —
   seeds are the first thing a reviewer looks at.
7. **Zero validator errors and zero warnings.** A warning you cannot eliminate must be justified
   explicitly in Gaps/assumptions, naming the finding.

If no `## Existing identifiers` section is present in the target doc, this is a brand-new community
with nothing to preserve — author roles/tabs fresh as normal, per the rest of this document.
### When the update is also a `specVersion: 4` migration — the persona→role collapse

The shipped file you are updating declares legacy `experience.personas[]`; your output must declare
`experience.roles[]` (rule 2a). **Which transformation applies depends on what that community's
personas actually denote**, and `identity-types.md` §2 gives the discriminator in one line:
*"Roles never appear as instance data values. **People never appear in `roles[]`.**"*

**Case 1 — the personas are role-like (the common case). Rename 1:1 and PRESERVE THE ID.**
`identity-types.md` §3.1 is a key rename, not a re-derivation:
`personas[].personaId` → `roles[].roleId`, **same value**; `roleLabel` unchanged.

```jsonc
{ "personaId": "chess-organizer", "roleLabel": "Organizer" }   // v1
{ "roleId":    "chess-organizer", "roleLabel": "Organizer" }   // v4 — id preserved
```

**Do not shorten, re-slug, or strip a community prefix from the id.** `chess-organizer` does not
become `organizer`. Every `allowedRoleIds`/`byRoleIds`/`visibleRoleIds` value keeps referring to the
same string it always did, and this repo's Dart test suite hardcodes these exact ids per community —
34 call sites at last count. Re-deriving them silently breaks real, already-passing tests while the
package still validates clean, which is the worst possible combination.

**Case 2 — the personas are individual people** (named humans: "Alex Rivera", "Bailey Chen", several
sharing one `roleLabel`). Then they are **not** roles at all and must not appear in `roles[]`. Each
person becomes a `fanId` in seed data and instance-data fields, and `roles[]` is derived from the
**distinct `roleLabel` values**, so four such personas sharing two labels yield **two** roles.

**How to tell the cases apart:** if the `personaId` names a kind of member and the `label` restates it
(`ad-off-owner` / "Owner"), it is Case 1. If the `label` is a human name and several personas share a
`roleLabel`, it is Case 2. If a community genuinely mixes both, say so explicitly in
Gaps/assumptions naming each persona and which case you applied — do not guess silently.

**In Case 2 only, the derivation has a hazard that is not mechanical.** A guard listing *some but not
all* of a role's personas **cannot** be translated to that role: `allowedRoleIds: ["member"]` would
grant access to every member, including the ones the original list deliberately excluded. That is a
silent privilege widening, and exactly the kind of change that looks correct in review. Do not widen
and do not guess — flag it in Gaps/assumptions, naming the exact guard and personas:

- a **strict subset of one role** — translating would widen access;
- a **partial set spanning two or more roles** — no single role expresses it.

Only a persona list covering a role's **full** roster translates cleanly. Two `roleLabel`s that would
produce the same `roleId` are an error to report, not to merge.

**The hazard that makes this non-mechanical — read carefully.** A guard listing *some but not all* of
a role's personas **cannot be translated to that role**: `allowedRoleIds: ["member"]` would grant
access to every member, including the ones the original list deliberately excluded. That is a silent
privilege widening, and it is exactly the kind of change that looks correct in review.

When you hit one, **do not widen and do not guess**. Two cases, both of which must go in
Gaps/assumptions naming the exact guard and personas:

- a **strict subset of one role** — flag it; translating would widen access;
- a **partial set spanning two or more roles** — flag it as mixed; no single role expresses it.

Only a persona list covering a role's **full** roster translates cleanly to that role. The dispatching
session verifies your derivation against this repo's own migration-derivation tool, so a flagged case
costs a follow-up question; a silently widened one is a real access-control defect.

## Fetch order

Fetch each of these from `fahdabidi/Loom` (branch `main`) in order, reading it in full before moving
to the next. Skipping ahead risks missing an invariant a later file assumes you already know.

| Step | Path | When |
|---|---|---|
| 1 | `docs/references/guide/01-authoring-procedure.md` | Always — the algorithm: roles → workflow types → states-vs-data → states/transitions → data schema → guards → effects → render bindings → seed data → self-check → validate. |
| 2 | `docs/references/reference/workflow-grammar.md` | Always — the normative contract every workflow definition must satisfy. |
| 3 | `docs/references/reference/guards.md`, `effects.md`, `formulas.md`, `field-types.md` | Always — you will reach for these constantly. |
| 4 | `docs/references/guide/03-common-patterns.md` | The pattern(s) matching what the target needs: P1 RSVP, P2 ballot, P3 approval queue, P4 loan/giveaway, P5 payment, P6 discussion thread. |
| 5 | `docs/references/reference/render-bindings.md` | Where each card appears and how it presents, for every workflow type in the target. |
| 6 | `docs/references/guide/07-actions-and-fabs.md` | When deciding whether a "create" affordance should be a FAB. |
| 7 | `docs/references/archetypes/README.md` | The source of truth for which `cardSurfaceFamily` is correct for **each** workflow. Re-check per workflow, not once. |
| 8 | `docs/references/guide/04-antipatterns.md`, `guide/05-validation.md` | Self-check before emitting. `05-validation.md` also carries the **diagnostic** for working out what a finding actually means before you fix it. |
| 9 | `docs/references/reference/theming.md`, `platform-services.md` | `platform-services.md` lists what is Loom-owned and not JSON-authorable. Never fabricate one. |
| 10 | `docs/references/reference/solved-patterns.md` | Recurring requirement shapes already found and fixed, with the verified-correct JSON for each. |
| 11 | `docs/references/reference/permissions.md` | Always — defines the `action` field, which archetypes require it, and the closed vocabulary for each. |
| 11a | `docs/references/reference/identity-types.md` | Always — normative for `specVersion: 4`. The `roleId`/`fanId` split and every rename it implies. |
| 11b | `docs/references/archetypes/CONTRACTS.md` | Always — what each archetype guarantees. Then fetch the per-archetype doc (`docs/references/archetypes/<archetype>.md`) for each family you actually use — each carries a **worked JSON example** showing the shape to copy. |
| 12 | The target product doc | The actual requirements to author against. |

## Scope

Build any workflow whose required `cardSurfaceFamily` is confirmed real in
`docs/references/archetypes/README.md` (fetched at step 7 — that file is the live source of truth, always
re-check it, never assume the list is frozen or matches an earlier session's memory of it):

- 3 real bespoke archetypes: `event-rsvp`, `votePoll`, `equipment-loan`.
- 6 🟡 GENERIC archetypes (real, rendered by the shared generic card): `paymentCheckout`,
  `approvalQueueItem`, `formEntry`, `discussionThread`, `statusTimeline`, `notificationInbox`.
- 4 more real bespoke archetypes, promoted 2026-08-11 and fully implemented 2026-08-12 — see
  `archetypes/README.md`'s "Promoted archetypes — closed 2026-08-12" section, fetched at step 7, for the
  current authoritative status; do not treat the 4 named here as fixed if that section has changed):
  `table`, `documentLibrary`, `searchAiAnswer`, `exportWizard`. **Use these when the target genuinely needs
  them — do not silently substitute a generic archetype.** They validate cleanly like any other archetype
  now — no `unknown_card_surface_family` caveat to report. For `searchAiAnswer`'s answer text and
  `exportWizard`'s checksum/transfer-id/receipt-id fields specifically: declare the field, never write it
  from any effect, and mark it with a `NEEDS IMPLEMENTATION (platform service): ...` comment — these are
  real, separate, `❌ Not implemented` platform-services gaps (`platform-services.md`), unchanged by the
  archetype itself now being implemented. Never gate an `exportWizard` transition's *completion* on the
  checksum/transfer-id field either (`solved-patterns.md` pattern 14) — unlike `searchAiAnswer`'s answer
  (pattern 11: a real admin-curated field is a legitimate substitute), a checksum has no honest
  human-curated substitute.

**Explicitly out of scope — say so per Hard Rule 7 below, never force-fit**: any `cardSurfaceFamily` still
marked ❌ NOT REAL in `archetypes/README.md` as fetched. A target needing one of these gets a plain,
specific refusal (which section, why it doesn't fit any real family, what family it would actually need if
it existed) — not an approximation with a real archetype it doesn't belong to, and not a silent drop.

⚠️ **The CardSurfaces vocabulary trap.** Product docs' own "Card Surface Registry Mapping" tables name
surfaces like `payment`, `documents`, `calendar`, `workflow-status`, `notification-inbox`, `portability`,
`search`, `roster` — **none of those names are real `cardSurfaceFamily` values**. Never copy a product doc's
registry-table name directly into `cardSurfaceFamily`. Always translate through `archetypes/README.md`'s
real enum (fetched at step 7) instead.

## Hard rules — never violate these

1. Stamp a single package-root `specVersion: 4`. This replaced the legacy three-number scheme
   (`schemaVersion`/`experience.experienceSchemaVersion`/`experience.workflowGrammarVersion`) — see
   `docs/references/_meta/versioning-policy.md`, fetched as part of step 1's authoring procedure.
2. **Never emit any of the three legacy version fields.** A package declaring `specVersion` must not
   also carry `schemaVersion`, `experience.experienceSchemaVersion`, or
   `experience.workflowGrammarVersion` — doing so is its own validation error
   (`docs/references/guide/05-validation.md`'s `missing_schema_version` / `legacy_experience_schema`
   rows). This has been a real, load-bearing mistake in practice; double-check this before returning
   output, especially when updating an already-shipped community that still declares the legacy triple
   — the target output must not carry it forward.
2a. **`specVersion: 4` requires the `roleId`/`fanId` identity split — see `identity-types.md` (step
   11a), fetched in full, not assumed from this summary.** `experience.personas[]` becomes `roles[]`
   with `roleId` (not `personaId`); `guard.allowedPersonaIds`→`allowedRoleIds`;
   `actions[].byPersonaIds`→`byRoleIds`; `tabs[].visiblePersonaIds`→`visibleRoleIds`;
   `renderBindings[].role`→`audience`; every person-shaped instance-data field renames to its
   `*FanId(s)` form (`createdByPersonaId`→`createdByFanId`, and so on) and its declared `type`
   becomes `fanId`/`fanId[]` instead of `personaId`/`personaId[]`. When updating an already-shipped
   community (see the "Updating an existing" section above), apply this rename to **every** occurrence
   in the existing package — do not leave any old-spelled key alongside the new version stamp, and do
   not silently skip a field because it looked like an edge case; if genuinely unsure whether a field
   is role-shaped or person-shaped, say so explicitly in your Gaps/assumptions section rather than
   guessing.
3. Never emit a JSON key that isn't enumerated in the reference files you fetched. An unknown key is
   silently ignored by the real parser — it produces a community that looks correct in the JSON but does
   nothing at runtime.
4. Never write Dart, or ask for Dart to be written.
5. Never seed or effect-write a computed (`formula`) field.
6. Never invent a `cardSurfaceFamily` value not listed in `archetypes/README.md`'s real-archetypes table.
7. When the grammar genuinely cannot express something, say so. Never approximate, never silently drop a
   stated requirement, never substitute a hardcoded value for one that should be computed.
8. Name event date/time fields literally `eventDate`/`eventTime` on any `event-rsvp`-bound workflow — never
   a synonym. Before finishing any `event-rsvp` workflow, check your own draft for this on that type's
   `instanceDataSchema` and every guard/effect/formula/renderBinding that references it.
9. Cross-reference repeat/retry language in the target product doc against your transition graph — if it
   uses "retry", "resubmit", "try again", "reopen", "undo", or "re-request", confirm the transition(s) that
   phrase implies actually cover every state a member could realistically be retrying from.
10. **In `specVersion: 4` this key is `audience`, not `role` (rule 2a) — the values below are unchanged.**
    On every tab except `admin`, `audience: "receiver"` never resolves to anyone, and `audience: "actor"` only ever
    matches the literal instance creator — never assume otherwise (see `render-bindings.md`'s normative
    table, fetched at step 5). For every `renderBinding` using `audience: "actor"` or `"receiver"` on a
    non-`admin` tab, confirm the persona it needs to reach really is always the instance creator; if not,
    use `audience: "any"` instead.
11. Build the requirement traceability table (`01-authoring-procedure.md` Step 9.5) and include it as a
    real artifact in your final answer, not a claim that you checked. One row per atomic product-doc
    requirement per workflow, citing the exact JSON construct that satisfies it, or `not_implemented` with
    reasoning grounded in a real, checked constraint — never a guessed persona/tab restriction.
12. **Declare `action` on every transition of a bespoke-archetype workflow, and never on a generic one.**
    The six bespoke families (`event-rsvp`, `votePoll`, `equipment-loan`, `documentLibrary`,
    `searchAiAnswer`, `exportWizard`) each have a **closed** action vocabulary — see
    `permissions.md` (fetched at step 11) for the exact list per family, and use only those values. The
    seven generic families (`paymentCheckout`, `approvalQueueItem`, `formEntry`, `discussionThread`,
    `statusTimeline`, `notificationInbox`, `table`) derive their permissions structurally and must carry
    **no** `action` field at all. `table` is the one to watch: it renders as a grid and reads as bespoke,
    but that is list layout only — it has no dispatcher case, so it takes no `action`. `action` is what the platform maps to the permission a transition needs.
    **A missing one does not crash — and that is exactly why it matters.** The engine reads
    `if (family == null || action == null) return sourceData;`: the transition still runs, and the
    archetype's per-person bookkeeping for it silently never happens, with no error and no runtime
    diagnostic. A crash would announce itself; this loses the archetype's guaranteed record-keeping
    quietly and permanently, which is why the validator has to catch it and why you must not omit one.
    Three further points, each of which has already caused a real defect:
    (a) A workflow with `"renderBindings": []` that is named by some binding's `responseTable.workflowType`
    **inherits that binding's archetype** (§6 step 3b) — so an RSVP response workflow is bespoke and its
    transitions do need `action`. A workflow with no bindings and no `responseTable` owner derives nothing.
    (b) The "Observed transitions" column is a **lookup aid, not authority**. When it disagrees with what
    the transition's `guard`/`from`/`to`/`effects` actually do, the transition wins — `cancel-loan` means
    `withdraw_request` in one community and `return` in another. Resolve from the column, then confirm
    against the transition, and say so when they diverge.
    (c) A workflow may mix one bespoke family with generic bindings; that is normal and the bespoke family
    is the archetype. Only two or more *bespoke* families is an error.
12a. **Never declare a field an archetype owns.** `CONTRACTS.md` (step 11b) lists the per-person
    bookkeeping each archetype maintains itself — response sets, read/acknowledged/saved/downloaded
    sets, queues. Declaring one of those in `instanceDataSchema`, or writing an `actorInList`
    idempotence guard against it, duplicates logic the archetype already applies and is how the same
    rule ends up expressed two different ways. (This rule was previously spliced into the middle of
    rule 12's sentence about action vocabularies, leaving both unreadable; they are separate rules.)

12b. **`visibility.fields` — declare it only when identity-scoped reads actually engage, use the key
    the archetype's model requires, and get the `parties` shape right.** See
    `workflow-grammar.md` § `visibility.fields` (step 2) and `CONTRACTS.md` §3 (step 11b), both
    fetched in full — this summary is a pointer, not a substitute.
    - **There are exactly four keys, and which one you need is decided by the archetype, not by you:**

      | archetype visibility model | the key | archetypes |
      |---|---|---|
      | `owner_and_shared` | `sharedWith` | `documentLibrary` |
      | `participants` | `participants` | `discussionThread` |
      | `parties` | `parties` | `approvalQueueItem`, `paymentCheckout` |
      | `recipient` | `recipient` | `notificationInbox` |

      `roles` and `owner` are visibility **models**, not keys — they read no instance data and take no
      mapping. Writing `"fields": { "owner": "someFanId" }` is not a way to say "the owner reads it";
      the owner already reads it, on every model. **An unrecognised key here is silently ignored**, so
      the mapping the archetype actually needs goes missing while the package looks configured. This
      is a confirmed defect, not a hypothetical: a `documentLibrary` was authored with
      `fields.owner` and shipped a `missing_visibility_fields` error for the `sharedWith` it never
      declared.
    - A mapping is **required** only when the workflow's own `visibility.default` is `guarded`, **or**
      it declares a `readGuard` at the workflow level or on any state. When the workflow is `public` or
      `membersOnly` with no guard anywhere, **do not invent one** — the archetype's identity model can
      only widen a read that is already open, so a mapping there adds nothing and risks naming the
      wrong field.
    - **Never point a mapping at archetype bookkeeping.** `sharedWith: "downloadedFanIds"` would grant
      read access to everyone who already downloaded the document — circular, and wrong. It passes the
      arity check while granting incorrectly, which is worse than failing. If the workflow has no field
      that genuinely means "party", say so in Gaps/assumptions rather than picking the nearest
      identity-shaped one.
    - `parties` takes **exactly two** entries, each either an instance-data field name **or**
      `{"role": "<roleId>"}` for a counterparty that is the community itself rather than a person — the
      collecting side of a payment, the reviewing body of a request. A role entry's `<roleId>` must be
      declared in `experience.roles[]`. A role object carries **only** the `role` key.
    - Use a role party instead of reaching for a formula like `$viewer == 'some-role-id'`. That
      comparison is always false — `$viewer` is a `fanId`, not a `roleId` — and the two conditions
      inside one guard are ANDed, so a `readGuard` cannot express "this person **or** whoever holds
      role X" at all. The role party is what expresses it, because archetype models widen rather than
      replace. See `identity-types.md` §3.5 (step 11a).

12c. **Every seed instance MUST declare `createdByFanId`.** This is the single most damaging thing to
    drop, because **nothing catches it**: the validator reports zero errors and zero warnings for a
    seed with no creator, and the app then throws
    `Bad state: Engine-native seed <id> is missing createdByPersonaId` at install time, so the whole
    community fails to load. Confirmed on a real regeneration: all 10 Chess Club seeds lost their
    creator, the package validated perfectly clean, and every engine-native test for that community
    broke.
    The trap is specific and easy to fall into: `createdByPersonaId` is a legacy key that rule 2a
    forbids, and the correct response is to **rename it to `createdByFanId`**, never to delete it.
    Its value is a **person** (a `fanId`), not a role — so it is one of the seed identity values that
    keeps the community's existing persona-id strings, exactly as rule 2a describes for person-shaped
    fields. Before returning any package, count your seeds and count your `createdByFanId` fields;
    they must be equal.

12d. **Every workflow with writable fields needs a creation path**, unless it is genuinely seed-only.
    A `formEntry`- or effect-authored field with no `renderBindings[].actions[].kind: "create"`
    targeting it, and no `createInstance`/`generateRecurringInstances` effect producing it, means no
    member can ever make one — the workflow exists but is unreachable. The validator reports this as
    `no_creation_path_for_editable_type`. A regeneration dropped two such paths (an export wizard and
    a document library) that the shipped package had, silently removing two real member capabilities.
    **Treat a validator warning as something to fix or to justify explicitly in Gaps/assumptions —
    never as acceptable noise.** Your target is zero errors *and* zero warnings.

13. **Never author a permission, a user, or a membership.** Permissions are derived from your
    `allowedRoleIds`/`byRoleIds` (the `specVersion: 4` spellings — see rule 2a) plus `action` —
    writing one is always wrong. Likewise never model
    joining a community, approving a member, or assigning someone a persona as a workflow: that is an App
    Shell experience backed by the App Access service. Domain processes that *accompany* joining (signing a
    waiver, paying a registration fee, a coach reviewing a player) remain legitimate workflows — it is the
    membership grant itself that must not be one.

14. **Converge the product doc and the JSON. Doc first, then JSON, then compare, then loop.**

    You may be dispatched two ways: with a target product doc, or with nothing but a prompt
    ("create me a community for X"). Either way BOTH artifacts are your output, and neither is
    finished until they describe the same experience.

    Work in this order, and do not skip ahead:

    **(a) Research the community and perfect the PRODUCT DOC first — before touching any JSON.**
    Starting from a prompt, you write the doc. Starting from a doc, you extend and correct it.
    Where it is thin, deepen it; where it is silent about something the experience needs, add
    it; where it is wrong about what the experience should be, correct it and say so. Do this
    from research into what this kind of community actually does, not from what happens to be
    easy to express in the grammar.

    **(b) Write the JSON from the perfected doc.**

    **(c) Compare them, in both directions.** For every workflow, transition, role, tab and
    B25 row: is everything the doc promises implemented, and is everything the package
    implements described?

    **(d) Loop.**
      - Something in the doc that the JSON does not implement -> take another pass at the JSON
        and implement it.
      - Something in the JSON that the doc does not describe -> update the doc, then REBUILD
        the JSON from the updated doc so the derivation stays honest.
      - Repeat until they match.

    The loop terminates ONLY when the two agree, or when the sole remaining difference is a
    gap you have typed and declared under rule 14a. Report how many passes you took and what
    changed in each -- a single pass through a non-trivial community almost always means you
    did not really compare.

    **CONVERGENCE IS NEVER ACHIEVED BY REMOVAL.** You may change either artifact to IMPROVE the
    product. You may not delete a doc requirement, drop a workflow, prune a transition, or
    narrow a role in order to make the two line up or to make a check pass. Deleting the
    requirement and implementing the requirement both produce "matching" artifacts; only one of
    them is the job. If you genuinely believe something should be removed because it is wrong
    for the community -- not because it is inconvenient -- say so explicitly, name exactly what
    you removed and why the experience is better without it, and expect that to be reviewed.

    A concrete case this rule exists for: Garden Club's B25 table named
    `garden-tool-loan-giveaway` while the package shipped `garden-tool-loan` and
    `garden-tool-giveaway` as separate workflows. Nothing matched the combined id, so the
    walkthrough routed to the missing-package path and crashed. Both artifacts were internally
    reasonable; nobody had ever compared them. The fix is to split the doc row to match the
    two real lifecycles (return vs. permanent transfer) -- NOT to merge two lifecycles into one
    state machine, and NOT to delete a row.

    Every transition you author must appear in the doc's workflow-to-surface mapping, its
    persona/state matrix, and -- most important -- the **B25 addendum table's required primary
    and required alternate/change/reject cells**, because that table is what the UX judge scores
    against. An interaction missing from it is invisible to the production bar no matter how
    well it works.

    **Never leave an alternate cell saying `(none ...)` for a workflow that implements a
    change, reject, withdraw, cancel, close, revise, retire or archive path.** The shipped Chess
    package implemented `withdraw-club-night-rsvp`, `cancel-club-night`, `close-pairing-queue`,
    `revise-ranking`, `retire-ranking` and `archive-document` while its doc declared
    `(none - one-way notification)` for those very rows. Four rows could never pass the
    production bar, and the near-miss fix was to loosen the judge -- which would have hidden six
    real affordances instead of proving them. A row that genuinely has no alternate is a design
    smell worth a second look: most real interactions have a way back.

14a. **Some of the experience may not be implementable. Say which, and never quietly shrink
    the doc to fit.** The JSON grammar and the archetype set are finite. You will meet
    requirements the doc can legitimately state and the package cannot express — a missing
    `cardSurfaceFamily`, an effect/guard/formula the grammar has no form for, a surface no
    archetype renders.

    When that happens the requirement STAYS IN THE DOC. It describes the experience this
    community should have, and deleting it destroys the only record that the gap exists.
    Instead report it explicitly, and say which kind it is:

    - **grammar gap** — name the exact construct the grammar lacks, and what you would need
      it to express.
    - **missing archetype** — name the surface the experience needs and the closest existing
      archetype, saying why the closest one is not adequate.

    Give each a `not_implemented` (or `partial`) row in the requirement traceability table and
    a line in Gaps/assumptions. This is how platform gaps become visible and get built; a
    requirement silently dropped, approximated, or quietly deleted from the doc is a gap
    nobody will ever fix. See also hard rule 7 — never approximate, never silently drop.

    Do NOT invent grammar to close such a gap, and do NOT weaken the doc's requirement so
    your package looks complete. An honest "the doc asks for X, the grammar cannot express
    it, here is what would be needed" is a far better result than a package that quietly
    delivers less than the doc promises.


14b. **The B25 table is a machine-parsed contract. Change its rows, never its shape.**

    A product doc's `### B25 Semantic Interaction Models` table is not prose. The UX judge
    parses it to decide what each workflow must prove, and it requires this exact six-column
    header, matched literally:

        | Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |

    Rename a column, drop one, add one, or reword the heading, and the parser matches nothing:
    every row for that community silently disappears and the workflow can no longer be judged
    at all. This has happened -- a convergence pass rewrote the header to five columns and the
    catalog reported "No B25 semantic interaction-model rows found" for the whole community.

    So:

    - You MAY rewrite the content of any cell, and you SHOULD when convergence shows the row
      is vague or wrong. Enriching a row is the point.
    - You MUST NOT change the header, the column order, or the column count.
    - Every row must have all six cells, none empty.

    **The two action columns are user-visible vocabulary, not identifiers.** A comma-separated
    cell is a *synonym set*: the judge looks for any one of those terms in the affordances a
    person can actually see on screen. `pay, donate, give, checkout` works because a button
    somewhere says one of them. A transition id like `record-payment-confirmed` does not work,
    because no button says that -- it names the mechanism, not the affordance. Write what the
    interface shows a person, and put the transition ids in the traceability table instead,
    which is where mechanism belongs.

## Two valid RSVP shapes — pick deliberately

- The plain `goingPersonaIds[]`/`maybePersonaIds[]`/`waitlistPersonaIds[]` list pattern (P1 in
  `03-common-patterns.md`) for "members RSVP" with no per-member follow-up.
- The `event-rsvp`/`event-rsvp-response` per-member-row pattern, required as soon as anything per-member
  happens afterward — most importantly a reminder notification, since a notification's recipient must be
  read off a real row's own field, not extracted from inside a shared list.

Do not mix the two within one workflow type.

## On validation — a mandatory validate-and-fix loop, done BEFORE you show anything

The full authoring procedure (`01-authoring-procedure.md`, Step 11) requires running a real validator
against the JSON before it is considered a deliverable. **If you have a `validateCommunityPackage`
action available (see `18-validator-action-openapi.yaml` — it's a live HTTP endpoint, not a document to
read), you have that tool, and this loop is mandatory, not optional:**

1. Draft the complete package internally. Do not show it to the user yet.
2. Call `validateCommunityPackage`. **The request body has exactly one field:**
   `{"packageJson": "<the entire package, JSON-encoded as a string>"}` — read
   `18-validator-action-openapi.yaml`'s description on that field carefully. Do NOT send the package's own
   top-level fields (`schemaVersion`, `packageId`, `experience`, etc.) directly as this request's fields;
   wrap the whole thing as one string value first. A call with an empty body, a body missing
   `packageJson`, or a body that puts the package's fields directly at the top level instead of inside
   `packageJson` is not a valid validator run — it is a failed tool call that happens to return a
   response. If you catch yourself about to call this tool any other way, stop and construct the argument
   correctly first.
3. If `errorCount > 0`: read every finding's `message` and `location`, fix the JSON, and call the
   validator again. Repeat until `errorCount` is 0. **Do not show the user a draft that still has
   errors, even as a "here's a work-in-progress version" — keep iterating internally.**
4. Once `errorCount` is 0, read every warning too — several (e.g. `editable_fields_without_edit_guard`,
   `no_creation_path_for_editable_type`) point at real, easy-to-miss gaps (an editor that silently never
   renders, a type nothing can ever create an instance of). Fix what's clearly wrong.
5. **Run hard rules 8, 9, 10, and 11 explicitly — a clean validator response does NOT cover any of these,
   by design.** The validator only checks JSON grammar; it cannot see the literal Dart string keys the
   Calendar UI reads, it has no access to your source product-doc prose, and it has no model of which
   `role` values actually resolve to a real viewer per tab — so none of the checks below will ever appear
   as a `validateCommunityPackage` finding:
   - **Hard rule 8**: for every `event-rsvp`-bound workflow, grep your own draft for `eventDate`/
     `eventTime` on that type's `instanceDataSchema` (and every guard/effect/formula/renderBinding
     referencing it). If the date/time field exists under any other name, rename it now.
   - **Hard rule 9**: list every repeat/retry/multi-attempt phrase in the request or product doc
     ("retry", "resubmit", "try again", "reopen", "undo", "re-request"), and for each one, name the
     transition(s) that satisfy it and confirm their `from` list covers every state a member could
     realistically be retrying from.
   - **Hard rule 10**: for every `renderBinding` using `role: "actor"` or `"receiver"` on a tab other than
     `admin`, confirm the persona it needs to reach is always the literal instance creator. If not, switch
     it to `role: "any"`.
   - **Hard rule 11**: build the requirement traceability table — every atomic requirement from the
     product doc, every workflow, cited against real JSON or marked `not_implemented` with grounded
     reasoning. This is the one check that catches a *silently dropped* requirement, not a *wrongly
     rendered* one — the other three checks above all assume the requirement was attempted; this one
     verifies it was attempted at all.
   Fix anything any of these four checks surfaces before moving on.
6. **If step 4 or step 5 changed the JSON, call the validator one more time** so the response you report
   actually describes the JSON you're about to show — never show a JSON and a validator response that came
   from two different drafts.
7. Once you have a real, clean (`errorCount: 0`) validator response for the exact final JSON, call
   `buildExtensionPackage` (route `/package.json`) with that **same, exact** package (same request shape:
   `{"packageJson": "<string>"}`). This validates again internally and, if still clean, returns a **JSON
   object** with `downloadUrl` — a direct link to a real zip of the installable pair, generated
   server-side — plus the same content again inline (`extensionManifestFilename`/`extensionManifest` and
   `initializationPackageFilename`/`initializationPackage`) as a fallback for if the link doesn't work for
   the user. If it returns `422` with `error: "package_build_failed"`, the package is missing
   `extensionId`, `communityId`, or `displayName` as a non-empty string at the *top level* (not nested
   inside `experience`) — fix that and retry both calls. This is a separate requirement from
   validator-cleanliness; `validateCommunityPackage` does not check these fields, only
   `buildExtensionPackage` does, because only the real app installer needs them.
8. Only now, in one final message, show: the finished JSON, a short "Gaps / assumptions" section (for
   anything you deliberately left as a warning rather than fixing), the **exact, final** validator
   response (status/errorCount/warningCount/findings) — not a paraphrase — and `downloadUrl` presented as
   a **plain clickable link**, described as "download this to get both installable files as a zip." Below
   the link, also show the two inline files (`extensionManifest`, `initializationPackage`), each in its
   own fenced code block labeled with its exact filename (`extensionManifestFilename`,
   `initializationPackageFilename`), as a fallback in case the link doesn't work for the user — tell them
   they can save each block's content into a file with that exact name instead. Do not claim anything is
   already installed; the link and the blocks both produce file contents, not an installation.

**A validator response reporting `missing_schema_version` / `missing_experience` on a package you just
wrote is a strong signal your own tool call was malformed — empty, truncated, or sent the package's
fields directly instead of wrapped inside `packageJson` — not that your JSON is actually broken.** Do
not report that as "the package failed validation" and do not count it as one of your fix-loop
iterations — it means the validation attempt itself failed, not step 3's normal error-fixing case. Retry
the call, double-checking the request body is exactly `{"packageJson": "<string>"}`. If constructing that
reliably is a genuine problem for you in a single turn, say so explicitly in your answer and ask the user
to send a follow-up message asking you to validate the JSON you just produced, rather than fabricating or
guessing at what a validator run would have said.

**Read `19-debugging-validator-responses.md` in full the moment `validateCommunityPackage` returns
anything other than a clean pass, before writing anything about it.** It defines the only two response
shapes that are real (a validation report, or a `{"error", "message"}` 400) — anything else, including
anything that looks like a programming-language exception name or stack trace, is not a real response
from this API under any circumstance, and reporting it as one is a hard violation of hard rule 7 (never
approximate, never fabricate). If you cannot show the literal JSON that came back, the correct thing to
write is "I could not obtain a real validator response this turn" — never a specific-sounding invented
error in its place.

**If the action is missing, fails, or the endpoint is unreachable** (this is a local dev-machine tunnel
with no uptime guarantee — it may simply be offline), fall back to a manual self-check and say plainly
that no real validator ran:

1. Walk every detection rule in `03-antipatterns.md` against your JSON explicitly.
2. Walk the error → fix table in `04-validation.md` and check each condition by hand (every persona
   referenced exists, every state is reachable, every non-terminal state has an outgoing transition,
   every `instanceData` key is declared in that type's schema, no computed field is seeded or
   effect-written, etc.).
3. Run hard rules 8, 9, 10, and 11 by hand exactly as described above (step 5 of the mandatory loop) —
   these never run through the validator even when it IS available, so a missing/unreachable action
   changes nothing about whether you need to do them.
4. State clearly, in your final answer, that this was a manual self-check, not a real validator run, and
   list anything you were genuinely unsure about.

## What to deliver

1. **One JSON (or JSONC) file** carrying the package envelope: `specVersion` (the value `4`, and
   **not** `schemaVersion` — see hard rules 1 and 2; this list previously named `schemaVersion` here,
   which directly contradicted them), `packageId`, `communityId`, `communityHandle`, `displayName`,
   `extensionId`, `branding`, `seedDataFiles`, `idempotencyKey`, then the `experience` block. Give the
   community its own identity (name, tagline, accent color, and `roles[]` — not `personas[]`, see rule
   2a) appropriate to whatever was actually requested. Reuse the workflow-definition *shapes* from the
   worked examples, never their literal content.
2. The **requirement traceability table** (hard rule 11 / `01-authoring-procedure.md` Step 9.5) — the real
   JSON artifact, one object per workflow, not a prose claim that you checked coverage.
3. A short **"Gaps / assumptions"** section after the JSON: anything the grammar couldn't express, anything
   you weren't sure about, and any place you made a judgment call the requester should double-check — this
   should list every `not_implemented`/`partial` row from the traceability table again, cross-referenced.
4. `buildExtensionPackage`'s `downloadUrl` (see "On validation" step 6) as a plain clickable link, plus
   both files inline as a fallback, each in its own labeled fenced code block with its exact filename —
   the real installable pair, produced only after the JSON is validator-clean. Do not claim anything is
   already installed, and do not skip this step just because the JSON alone already looks done.

Return the JSON in a single fenced code block so it can be extracted and validated for real.

**Running in-repo (Claude Code, Codex) instead of a no-tool-access provider**: item 3 above (the
`buildExtensionPackage`/`downloadUrl` flow) is specific to the hosted validator Action and does not apply.
Deliver just the JSON (item 1) and the Gaps/assumptions section (item 2); the caller is responsible for
turning it into an installable `.loom-init.zip`/`.loom-extension.zip` pair (see `SKILL.md`'s "Installing
what comes back" section for the exact in-repo mechanism — a small generator script following
`generate_tabletop_club_package.dart`'s pattern) if installation is needed.

5. **The product doc, and the convergence record** (hard rules 14 and 14a) -- the experience you
   are implementing, written down, plus proof you actually compared it to the package.

   If you were dispatched with only a prompt, this is the whole doc and you authored it. If you
   were given a doc, this is the exact replacement text for every row you changed or added,
   across the workflow-to-surface mapping, the persona/state matrix, and the B25 addendum's
   required-primary and required-alternate cells. Give full replacement rows, not descriptions
   of changes, so they apply verbatim -- you cannot write to the repo.

   Then the convergence record, which is the part that proves rule 14 was followed:

   - how many doc <-> JSON passes you took, and what changed in each;
   - anything the DOC promised that the JSON did not implement, and how you closed it;
   - anything the JSON implemented that the DOC did not describe, and how you closed it;
   - anything you REMOVED from either artifact, named explicitly, with why the community is
     better without it. Removals are reviewed. "It made them match" is not a reason;
   - any residual mismatch, which is only acceptable as a typed gap under rule 14a.

   A convergence record claiming one pass and zero differences on a non-trivial community reads
   as "I did not compare", and will be checked against the package.
