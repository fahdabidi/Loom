# Authoring a Loom Community experience — Codex/GitHub-fetch channel

**Read this file first.** You are running as a **zero-repo-access** authoring agent for the Loom
Communities workflow engine. This is the third channel this Skill is proven on, alongside a full-repo-
access in-repo run and the zero-tool-access `chatgpt-upload/` bundle uploaded to an external provider — see
`SKILL.md`'s "Two channels" section (soon three) for how this fits together. **Your working directory has
no Loom repository content in it at all — this is deliberate, not a mistake.** You must fetch every
reference file you need from GitHub, using whatever fetch/web tool is available to you, exactly the way a
zero-tool-access provider would need everything supplied externally, except here the supply mechanism is a
live fetch instead of a pre-attached file.

**Repository**: `fahdabidi/Loom`, branch `main`. Every path below is relative to the repo root. Fetch each
file's full content before treating anything about it as known — do not guess or reconstruct a file's
content from its name or from general Loom knowledge you might already have; the file's *actual current
text* is the only authoritative source, and it changes over time.

You are acting as an LLM agent that authors community JSON directly, not a human developer. You will never
write Dart, Flutter, or any other code, and you will never invent an API. Everything a Loom community can
do is expressed as JSON: state machines (`workflowDefinitions`), data schemas, guards, effects, formulas,
and render bindings. The files you fetch below enumerate that grammar completely.

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

Read it as **evidence of intent, not as a template to copy**. It tells you what this community
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
   **Every action must be driven by something the product doc asks for.** An action being *legal* for
   the family is not a reason to declare it. Adding one the shipped package lacks and the doc never
   requests produces a control that renders and does nothing, because nothing in the package gives it
   an effect and no requirement gives it a purpose. If an action looks missing, write it in
   Gaps/assumptions; do not add it speculatively.
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
5b. **A reminder is declared, never computed.** If the product doc says members are reminded before
   something, use the workflow-level `reminder` block -- `anchorDateField`, optional
   `anchorTimeField`, `leadHours` and/or `leadHoursField`, optional `enabledField`. Do **not** write a
   `dueAt` field with a formula: that idiom predates the block, the sweep no longer honours it, and it
   could never carry a timezone, so the same event resolved to different instants on different hosts.
   A member who chooses their own offset is `leadHoursField` with `leadHours` as its default, which is
   what `if(offset == null, 24, offset)` used to say. A *materialised* notification is different and
   still stores its `dueAt` outright -- that is data an effect writes, not a calculation.

5a. **Document libraries hold stored files or links — decide which, from the product doc.** A
   `documentLibrary` workflow is one or the other and the package must say so, because the two differ
   in who holds the bytes. If the doc says members or admins *upload* or *add a file*, declare an
   `upload` transition and make the content field `writableBy: "effect"` and never `required`. If the
   doc talks about a *source*, a *provider*, an *external link* or *opening* something hosted
   elsewhere, it is a link library: a member-writable `url` field and no `upload` action.
   [`document-library.md` §3a](../../../docs/references/archetypes/document-library.md) is the
   authority and gives the JSON for both. Getting this wrong is caught by
   `document_upload_stores_no_content`, and it is worth getting right first because `upload` grants a
   real platform capability.
6. **Seeds.** Every seed declares `createdByFanId` (rule 12c) and demonstrates a state worth seeing —
   seeds are the first thing a reviewer looks at.
7. **Zero validator errors and zero warnings.** A warning you cannot eliminate must be justified
   explicitly in Gaps/assumptions, naming the finding.

#### When you revise the product doc, revise it — do not replace it

A product doc in this repo is read by more than a person. Its section structure and its two
six-column tables are parsed: the workflow-to-surface mapping, the persona/state matrix, and the B25
addendum table that defines the production bar. Dropping a section because your rewrite covers the
same ground in fewer words removes rows that evidence tooling counts.

So when you return a revised product doc:

- **Keep every `##` section the source doc had**, in its order. Add sections if the product needs
  them; do not merge or drop.
- **Keep both six-column table headers verbatim.** They are matched literally. A reworded header
  silently unparses every row beneath it.
- **Never write the `## Existing identifiers` block into the product doc.** It is dispatch
  scaffolding that tells you what to preserve — it is not something the community's product doc
  should carry, and a later run that reads it back would treat it as product content.
- Prefer a targeted correction to a rewrite. If the doc contradicts itself, fix the contradiction and
  say which rows you changed; a doc that is 40% shorter has usually lost a requirement rather than
  found a better way to say it.

#### The block lists identifiers. It is not evidence that anything else exists.

The `## Existing identifiers` block exists to tell you the values in the table above — the ones you
cannot discover any other way because they are referenced from outside the package. **Anything else it
asserts is a claim you can and must check**, because you fetched the shipped package and it is right
there.

If the block says an action, transition, field or workflow exists and the fetched package does not
declare it, **the package wins.** Say so in Gaps/assumptions and carry on from what the package
actually contains. Do not add the thing to make the brief true.

This is a real defect, not a hypothetical. A dispatch brief once listed `grant_access` among a
community's existing document actions; the package declared no such thing. The agent noticed the
discrepancy, reported it, and added the transition anyway out of deference to the brief. Because the
archetype owns that action's bookkeeping and the platform had not implemented it yet, the result was a
transition with no effects — a button that rendered and did nothing.

The general rule the incident illustrates: **a dispatching session can be wrong about the package, and
you are the one holding the package.** Deference is correct for identifiers you cannot verify. It is
wrong for existence claims you can.

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

Fetch each of these in order, reading it in full before moving to the next. Skipping ahead risks missing an
invariant a later file assumes you already know.

| Step | Path | When |
|---|---|---|
| 1 | `docs/references/guide/01-authoring-procedure.md` | Always — the algorithm: personas → workflow types → states-vs-data → states/transitions → data schema → guards → effects → render bindings → seed data → self-check → (validate). |
| 2 | `docs/references/reference/workflow-grammar.md` | Always — the normative contract every workflow definition must satisfy. |
| 3 | `docs/references/reference/guards.md`, `docs/references/reference/effects.md`, `docs/references/reference/formulas.md`, `docs/references/reference/field-types.md` | Always — you will reach for these four constantly, including `field-types.md`'s `type:"url"` section for any document/external-link field. |
| 4 | `docs/references/guide/03-common-patterns.md` | Read the pattern(s) matching what the target needs: P1 RSVP, P2 ballot, P3 approval queue, P4 loan/giveaway, P5 payment, P6 discussion thread. |
| 5 | `docs/references/reference/render-bindings.md` | Where each card appears and how it presents (tabs, roles, actions, FAB), for every workflow type in the target, not just calendar-bound ones. |
| 6 | `docs/references/guide/07-actions-and-fabs.md` | When deciding whether a "create" affordance should be a FAB, and how response/decision actions should present. |
| 7 | `docs/references/archetypes/README.md` | The source of truth for which `cardSurfaceFamily` is correct for **each** workflow, and which values are real vs. not real — re-check for every workflow type, not once. This file is the live status; do not trust any archetype list embedded in this instructions file as more current than it. |
| 8 | `docs/references/guide/04-antipatterns.md`, `docs/references/guide/05-validation.md` | Self-check before emitting. |
| 9 | `docs/references/reference/theming.md`, `docs/references/reference/platform-services.md` | `platform-services.md` lists the closed set of things that are Loom-owned, not JSON-authorable — always check it before writing any effect that looks like it produces a receipt id, checksum, payment confirmation, or search/AI answer. Never fabricate one (AP-6). |
| 10 | `docs/references/reference/solved-patterns.md` | Recurring requirement shapes already found and fixed in real community packages, with the verified-correct JSON shape for each. Check every workflow's requirements against this list before treating a shape as novel. |
| 11 | `docs/references/reference/permissions.md` | Always — defines the `action` field, which archetypes require it, and the closed action vocabulary for each. Permissions are **derived** from what you author; you never write one. |
| 11a | `docs/references/reference/identity-types.md` | Always — normative for `specVersion: 4`, the only version this bundle describes. Defines the `roleId`/`fanId` type split: `experience.personas[]`→`roles[]`, `personaId`→`roleId` for role declarations, `guard.allowedPersonaIds`→`allowedRoleIds`, `actions[].byPersonaIds`→`byRoleIds`, `tabs[].visiblePersonaIds`→`visibleRoleIds`, `renderBindings[].role`→`audience`, and every person-shaped instance-data field (`createdByPersonaId`, `goingPersonaIds`, etc.) renames to its `*FanId(s)` equivalent. A legacy key in a `specVersion: 4` package is a validator error — never emit `personaId`-shaped keys alongside `specVersion`. |
| 11b | `docs/references/archetypes/CONTRACTS.md` | Always — what each archetype **guarantees** as opposed to what you declare: its actions, the per-person bookkeeping it owns, and its visibility model. Then fetch the per-archetype doc (`docs/references/archetypes/<archetype>.md`) for each family you are actually using. |
| 12 | The target product doc (given to you at dispatch time, see below) | Your STARTING POINT, not a frozen specification. You design the experience: perfect this doc first, then derive the package from it, and return both (hard rule 14). |

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

## On validation — call the real validator and iterate until it is clean

**You have a live validator. Use it. Do not return a package you have not validated.**

A Loom validator HTTP server runs on this machine, and your sandbox has network access to it. The
dispatching session starts it and refuses to dispatch you if it is not answering, so it is up:

```bash
curl -s -m 10 http://127.0.0.1:8787/health
# {"status":"ok"}
```

Verified working from inside this sandbox on 2026-08-19 — both `GET /health` and `POST /validate`.
This replaces the previous manual-only self-check, which was written when the sandbox had no network
at all.

### The loop

1. Draft the complete package to a file in your working directory. Do not show it yet.
2. `POST` it to `/validate`, **always sending the `X-Loom-Dispatch` header** with the label you were
   given at dispatch time (it appears in your prompt's target-doc path, e.g. `cedar_r2`):

   ```bash
   curl -s -m 30 -X POST -H 'Content-Type: application/json' \
     -H 'X-Loom-Dispatch: <your-label>' \
     -H 'X-Loom-Round: <round number, starting at 1>' \
     --data-binary @your-package.jsonc \
     http://127.0.0.1:8787/validate
   ```

   The two headers cost you nothing and are not optional. The server records which findings each round
   produced, which is how this Skill gets improved — a rule that keeps producing the same finding
   across dispatches is a documentation gap, and that is only visible if the rounds are attributable.
   Sending them wrong is better than omitting them.

   The body may be JSON or JSONC — comments are stripped server-side. The response is a
   `ValidationReport`: `{"status", "errorCount", "warningCount", "findings":[{"type","message","location","isWarning"}]}`.
3. **Fix every error.** Each finding carries the exact `location` path and a `type` naming the rule.
   Fix the cause, not the symptom — a finding is telling you something real about the package.
4. Re-validate. Repeat until `errorCount` is **0**.
5. Then address warnings the same way, except where a warning is expected and correct to leave — see
   the response-row exception in the functional-correctness checklist. Justify every warning you
   leave in Gaps/assumptions, naming the finding type.
6. Only then return your answer.

**Returning a package with `errorCount > 0` is a failed dispatch.** You had the tool that would have
caught it. If you cannot make a finding go away, say so explicitly in Gaps/assumptions, quote the
finding, and explain what you tried — do not quietly return it.

### Bound the loop — 6 rounds, then stop and report

**Stop after 6 validate-and-fix rounds even if findings remain**, and return what you have with an
explicit `## UNRESOLVED FINDINGS` section listing each remaining finding verbatim (`type`, `location`,
`message`) and what you tried for it. A bounded run that reports honestly is useful; an unbounded one
that burns the dispatch and returns nothing is not.

Three things that do **not** count as a round, because they are not the normal fix cycle:

- a `curl` that fails to connect or times out — that is a transport failure, retry it;
- a response that is not a `ValidationReport` — malformed request, fix the call;
- a validate you ran purely to confirm an edit you already knew was right.

**Aim to need one round, not six.** Every finding you fix on round three is one the reference docs
should have prevented on round one, so treat a multi-round run as a signal worth reporting: if the
same finding type keeps reappearing, say so plainly in Gaps/assumptions and name the doc that should
have told you. That note is more valuable than the fix.

### Reading findings

- `location` is a path into your own package, e.g.
  `experience/workflowDefinitions/hoa-member-document/visibility/fields/owner`. Go to exactly that
  spot.
- `type` names the rule. When a message names legal values or the key a construct requires, that is
  the answer, not a hint — `unknown_key` will tell you which keys are legal for that position.
- An `unknown_key` finding means the parser **ignores** that key: whatever you meant by it is not
  happening. Do not "fix" it by deleting the key alone; work out which real key you needed.

### How to fix a finding — declare the intent, never delete it

**The governing rule: a finding almost always means something is referenced but not declared, or
declared but ignored. The fix is to make the intent real. Deleting the reference also clears the
finding, and is almost always wrong.**

This matters because the validator cannot tell the two apart. A formula that referenced an undeclared
field and a formula you deleted both produce a clean run — but one of them removed a capability the
product doc asked for, silently, and nothing downstream will ever flag it. **When you clear a finding
by removing something, say so explicitly in Gaps/assumptions and name what you removed.** If you
cannot justify the removal there, it was the wrong fix.

Two quick sanity checks on your own work, both cheap:

- After a fix round, your schema, formula and transition **counts should generally go up, not down**.
  A round that clears ten findings while shrinking the package is a warning sign about your own fix.
- If a fix makes a workflow do *less* than the shipped package did, you have almost certainly removed
  capability rather than declared intent.

| Finding | What it means | The right fix | The wrong fix |
|---|---|---|---|
| `unknown_key` | The parser **ignores** this key. Whatever you meant by it never happens. | Work out which real key expresses the intent — the message lists the legal keys for that position — and use it. | Deleting the key. The intent goes with it. |
| `unknown_instance_data_key` | A guard, effect, binding or seed names a field that `instanceDataSchema` never declares. | **Declare the field**, with the right type and `writableBy`. | Deleting the guard/effect/seed value that referenced it. |
| `unknown_formula_field` | A formula reads a field that does not exist. | Declare the field the formula needs. | Deleting the formula, or the field it computes. |
| `dangling_actor_equals_field` | A guard compares the actor to a field that is not declared, or is not identity-typed. | Declare it as `fanId`. If the guard meant a role, use `allowedRoleIds` instead — see rule 12b. | Dropping the guard. That silently opens up a read or a transition. |
| `unknown_input_type` | A transition input names a type outside the closed set. | Use a real type. The message lists every legal one; `fanId`, `fanId[]`, `roleId` and their nullable forms are all valid. | Removing the input, or retyping it as `text` to make the error go away. |
| `missing_transition_action` | A bespoke-family transition has no `action`. | Add the action from that family's closed vocabulary (rule 12). | Re-homing the workflow to a generic family to dodge the requirement. |
| `no_creation_path_for_editable_type` | Nothing can ever create an instance of a workflow that has writable fields. | Add a `create` action, or a `createInstance` effect that produces it. | Making the fields non-writable, or deleting them. |
| `no_render_binding_for_reachable_state` | A state renders nowhere. | Add the state to a binding's `states` list. | Deleting the state, or the transition that reaches it. **Exception:** response-row workflows correctly have no bindings — see the functional-correctness checklist. Leave those. |
| `missing_visibility_fields` | An identity-scoped read needs a field mapping. | Declare the key the archetype's model requires (rule 12b's table). | Changing `visibility.default` to `membersOnly` to dodge the requirement — that changes who can read the workflow. |
| `invalid_workflow_definition` | The workflow failed to parse. | Read the message for the exact type error and fix the shape. | Deleting the workflow. |
| `unknown_instance_workflow_type` | A seed names a workflow type that does not exist. | Fix the type name, or declare the workflow. | Deleting the seed. |
| `seed_instance_missing_creator` | A seed has no `createdByFanId`. | Add it — rule 12c. The value is a person. | Deleting the seed. |
| `document_upload_stores_no_content` | A transition declares the `upload` action but sets the library's `url` content field from a member input — a link publish named as an upload, which also hands out file-storage permission. | Decide which library this is. Stored: drop the input, let the API write the field. Linked: this is not an upload, so use `edit` or a community-defined transition. | Deleting the transition. The community still needs whatever it did. |
| `document_library_is_link_only` *(warning)* | This library keeps its content in a member-typed `url` field and declares no `upload`, so nothing can be stored through the Document Library API. | Usually nothing — most shipped document libraries are deliberately link libraries. Justify it in Gaps/assumptions by name. | Adding an `upload` transition to silence it. That grants file-storage authority the product doc never asked for. |
| `redundant_transition` | Two transitions share a guard and target from the same states. | If they really are one capability, remove one. If they are distinct operations, give them different targets or effects — and if they legitimately differ only in effects, say so in Gaps/assumptions and leave them. | Blindly deleting one. Approve and decline commonly share a target state and are not duplicates. |

**When a finding recurs across rounds**, stop and re-read the reference doc for that construct rather
than trying another edit. Fixing the same finding three times means you have the wrong model of the
grammar, and the next edit will be wrong too.

### What the validator does not check

It reads JSON grammar only. It cannot see the Dart Calendar surface's hardcoded field-name reads,
your source product doc's prose, or which `audience` values resolve to a real viewer per tab. So
**still** walk these by hand before returning, exactly as before:

1. Every detection rule in `04-antipatterns.md`, one at a time, against your own draft.
2. The error → fix table in `05-validation.md` — for each row, ask whether your draft *could* trigger
   it, not just whether it obviously does.
3. Hard rules 8, 9, 10 and 11 explicitly.
4. A separate whole-package pass listing every distinct non-`home`/`messages` `tabId` used anywhere,
   confirming each has a matching `appShell.tabs[]` entry. Do this as its own step, not folded into
   reviewing bindings one at a time — a whole-package omission is easy to miss that way
   (`solved-patterns.md` pattern 8).

### What to report

State the **final** `/validate` response — `status`, `errorCount`, `warningCount` — and how many
validate-and-fix rounds you took. If you left any warning standing, list each with its type and your
justification. Never describe a validator result you did not actually obtain.

## What to deliver

1. **One JSON (or JSONC) file** — the complete package: `specVersion` (the value `4`, and **not**
   `schemaVersion` — see Hard Rules 1 and 2; this list previously named `schemaVersion` here, which
   directly contradicted them), `packageId`, `communityId`,
   `communityHandle`, `displayName`, `extensionId`, `branding`, `seedDataFiles`, `idempotencyKey`, the
   `experience` block, **and a top-level `appShell` block** (see below — required whenever any workflow uses
   a `tabId` other than `home`/`messages`, which is nearly always). Return it in a single fenced code block
   so it can be extracted and validated for real; if the package is too large for one reply to be practical,
   write it to a file in your own scratch working directory and say so explicitly, naming the exact path —
   never truncate or summarize the package itself in place of the real content.

   **`appShell.tabs[]` is easy to drop entirely — check for it as an explicit, separate step, not as part of
   reviewing each `renderBindings` entry.** After drafting every workflow, collect the full set of distinct
   non-`home`/`messages` `tabId` values used anywhere across the package, then
   confirm every one of them has a matching entry in `appShell.tabs[]` (or `roleTabs[]` for a
   persona-scoped tab) — see
   `render-bindings.md`'s `appShell.tabs[]` / `roleTabs[]` — tab declaration shape` section (fetched at
   step 5) for the exact field shape, and `solved-patterns.md` pattern 8 (fetched at step 10) for a full
   worked example of this exact omission and its fix. A package whose workflows are otherwise perfect but
   has no `appShell` block will fail validation with an `unknown_tab_id` finding per undeclared tab — this
   has happened in practice and is not a hypothetical risk.
2. The **requirement traceability table** (hard rule 11) — the real artifact, one object per workflow.
3. A short **"Gaps / assumptions"** section: anything the grammar couldn't express, anything you weren't
   sure about, any judgment call worth double-checking, every `not_implemented`/`partial` traceability row
   cross-referenced again, and every `NEEDS IMPLEMENTATION (platform service)` comment you left in the JSON
   listed explicitly so the reviewer doesn't have to grep for them — there should be no other kind of
   `NEEDS IMPLEMENTATION` comment left; all 13 archetypes are real as of 2026-08-12.
5. **The product doc, and the convergence record** (hard rules 14 and 14a) -- the experience you
   are implementing, written down, plus proof you actually compared it to the package.

   If you were dispatched with only a prompt, this is the whole doc and you authored it. If you
   were given a doc, this is the exact replacement text for every row you changed or added,
   across the workflow-to-surface mapping, the persona/state matrix, and the B25 addendum's
   required-primary and required-alternate cells. Give full replacement rows, not descriptions
   of changes, so they apply verbatim -- you have no repo write access here.

   Then the convergence record, which is the part that proves rule 14 was followed:

   - how many doc <-> JSON passes you took, and what changed in each;
   - anything the DOC promised that the JSON did not implement, and how you closed it;
   - anything the JSON implemented that the DOC did not describe, and how you closed it;
   - anything you REMOVED from either artifact, named explicitly, with why the community is
     better without it. Removals are reviewed. "It made them match" is not a reason;
   - any residual mismatch, which is only acceptable as a typed gap under rule 14a.

   A convergence record claiming one pass and zero differences on a non-trivial community reads
   as "I did not compare", and will be checked against the package.
4. Your validation results, per the "On validation" section above: the **final** `/validate` response
   (`status`, `errorCount`, `warningCount`), how many validate-and-fix rounds you took, and every
   warning you left standing with its type and your justification. Plus the manual checks that the
   validator cannot make — the `04-antipatterns.md` walk, the `05-validation.md` table walk, hard
   rules 8/9/10/11, and the whole-package tab audit — stated as what you actually checked. Never
   describe a validator result you did not obtain.

Do not attempt to build an installable `.loom-init.zip`/`.loom-extension.zip` pair — that is the dispatching
session's job, not yours, for this channel.
