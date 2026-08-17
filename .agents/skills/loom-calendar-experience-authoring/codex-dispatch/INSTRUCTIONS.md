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

Only introduce a new persona or tab if the target doc's requirements genuinely need one beyond what's
listed — and if you do, say so explicitly in your Gaps/assumptions section, naming exactly which identifier
is new and why the existing set didn't already cover the need.

If no `## Existing identifiers` section is present in the target doc, this is a brand-new community with
nothing to preserve — author personas/tabs fresh as normal, per the rest of this document.

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
| 11b | `docs/references/archetypes/CONTRACTS.md` | Always — what each archetype **guarantees** as opposed to what you declare: its actions, the per-person bookkeeping it owns, and its visibility model. Then fetch the per-archetype doc (`docs/references/archetypes/<archetype>.md`) for each family you are actually using. |
| 12 | The target product doc (given to you at dispatch time, see below) | The actual requirements to author against. |

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

1. Emit `experienceSchemaVersion: 2`.
2. Stamp all three version fields with their current real values, confirmed against a real shipped
   fixture, never guessed by analogy to each other: `schemaVersion: 1`, `experienceSchemaVersion: 2`,
   `workflowGrammarVersion: 1`. **`workflowGrammarVersion` is 1, not 2** — it does not track
   `experienceSchemaVersion`; the two numbers are independent and a value of `2` fails validation
   (`unsupported_schema_version`). This has happened in practice; double-check this specific field before
   returning output.
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
10. On every tab except `admin`, `role: "receiver"` never resolves to anyone, and `role: "actor"` only ever
    matches the literal instance creator — never assume otherwise (see `render-bindings.md`'s normative
    table, fetched at step 5). For every `renderBinding` using `role: "actor"` or `"receiver"` on a
    non-`admin` tab, confirm the persona it needs to reach really is always the instance creator; if not,
    use `role: "any"` instead.
11. Build the requirement traceability table (`01-authoring-procedure.md` Step 9.5) and include it as a
    real artifact in your final answer, not a claim that you checked. One row per atomic product-doc
    requirement per workflow, citing the exact JSON construct that satisfies it, or `not_implemented` with
    reasoning grounded in a real, checked constraint — never a guessed persona/tab restriction.
12. **Declare `action` on every transition of a bespoke-archetype workflow, and never on a generic one.**
    The six bespoke families (`event-rsvp`, `votePoll`, `equipment-loan`, `documentLibrary`,
    `searchAiAnswer`, `exportWizard`) each have a **closed** action vocabulary — see
    Never declare a field an archetype owns. `CONTRACTS.md` (step 11b) lists the per-person bookkeeping
    each archetype maintains itself — response sets, read/acknowledged/saved/downloaded sets, queues.
    Declaring one of those, or writing an `actorInList` idempotence guard against it, duplicates logic
    the archetype already applies and is how the same rule ends up expressed two different ways.
    `permissions.md` (fetched at step 11) for the exact list per family, and use only those values. The
    seven generic families (`paymentCheckout`, `approvalQueueItem`, `formEntry`, `discussionThread`,
    `statusTimeline`, `notificationInbox`, `table`) derive their permissions structurally and must carry
    **no** `action` field at all. `table` is the one to watch: it renders as a grid and reads as bespoke,
    but that is list layout only — it has no dispatcher case, so it takes no `action`. `action` is what the platform maps to the permission a transition needs, so an
    unmapped or misnamed one silently leaves a permission ungranted and the action fails at runtime.
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
13. **Never author a permission, a user, or a membership.** Permissions are derived from your
    `allowedPersonaIds`/`byPersonaIds` plus `action` — writing one is always wrong. Likewise never model
    joining a community, approving a member, or assigning someone a persona as a workflow: that is an App
    Shell experience backed by the App Access service. Domain processes that *accompany* joining (signing a
    waiver, paying a registration fee, a coach reviewing a player) remain legitimate workflows — it is the
    membership grant itself that must not be one.

## Two valid RSVP shapes — pick deliberately

- The plain `goingPersonaIds[]`/`maybePersonaIds[]`/`waitlistPersonaIds[]` list pattern (P1 in
  `03-common-patterns.md`) for "members RSVP" with no per-member follow-up.
- The `event-rsvp`/`event-rsvp-response` per-member-row pattern, required as soon as anything per-member
  happens afterward — most importantly a reminder notification, since a notification's recipient must be
  read off a real row's own field, not extracted from inside a shared list.

Do not mix the two within one workflow type.

## On validation — no live validator call in this channel; a mandatory manual self-check instead

**Confirmed by direct testing (2026-08-11), not assumed:** this sandbox's shell-level network access is
broken for arbitrary HTTPS endpoints — a plain `curl` to the validator's own health-check URL fails at DNS
resolution before it ever reaches the tunnel. The only network path confirmed to work reliably from inside
this sandbox is the built-in `github.fetch_file` tool (a first-party Codex "app," not a general-purpose HTTP
client). There is no configured MCP server and no other fetch tool available (`codex mcp list` returns
none). **Do not attempt to call the validator HTTP endpoint from inside this session** — a shell `curl`/
`wget`/`fetch` to it will fail, and burning turns retrying it (proxies, DNS-over-HTTPS workarounds, browser-
emulation tricks) wastes the dispatch budget for no benefit. This is a known, structural limitation of this
channel, not something a cleverer request will route around.

Real validator confirmation happens **outside this session, after you return your answer**: the dispatching
session runs your JSON through the real validator (or the equivalent local `dart run
community_package_validator.dart`) itself and reports the result back. Your job is to make that first real
run come back clean, via a rigorous **manual** self-check performed before you show anything:

1. Draft the complete package internally. Do not show it yet.
2. Walk every detection rule in `04-antipatterns.md` by hand against your own draft, one rule at a time.
3. Walk the error → fix table in `05-validation.md` by hand — for each row, check whether your draft could
   trigger it, not just whether it obviously does.
4. Run hard rules 8, 9, 10, and 11 explicitly — these never ran through the validator even in the channels
   where a live validator is reachable (it only checks JSON grammar, not the Dart Calendar surface's
   hardcoded field-name reads, not your source product-doc prose, not which `role` values actually resolve
   to a real viewer per tab), so they need the same manual rigor regardless of channel.
5. Re-read your own draft once more end to end, specifically hunting for: an unknown key (Hard Rule 3), a
   fabricated platform-service value (`platform-services.md`), and a `cardSurfaceFamily` not in
   `archetypes/README.md`'s real-archetypes table (Hard Rule 6). Any `unknown_card_surface_family` finding
   at this point is a real defect to fix, not an expected result — all 13 archetypes, including
   `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard`, validate cleanly as of 2026-08-12.
6. **Do this as its own separate pass, not folded into step 5** (a whole-package omission is easy to miss
   while reviewing each `renderBindings` entry in isolation — this has happened in practice, see
   `solved-patterns.md` pattern 8): first confirm no `renderBindings[].tabId` in your draft equals
   `"messages"` — it is a fixed, system-provided App Shell tab with no community-authorable content
   (`antipatterns.md` AP-14) — then list every remaining distinct non-`home` `tabId` value used anywhere
   across the whole package and confirm each one has a matching `appShell.tabs[]`/`personaTabs[]` entry.
   Missing this produces `unknown_tab_id` findings, one per undeclared tab.
7. State clearly and plainly in your final answer that this was a **manual self-check, no live validator
   ran in this channel** — never imply or fabricate a validator response you did not actually obtain. If you
   are not fully confident a check passes, say so explicitly rather than asserting it does.

## What to deliver

1. **One JSON (or JSONC) file** — the complete package: `schemaVersion`, `packageId`, `communityId`,
   `communityHandle`, `displayName`, `extensionId`, `branding`, `seedDataFiles`, `idempotencyKey`, the
   `experience` block, **and a top-level `appShell` block** (see below — required whenever any workflow uses
   a `tabId` other than `home`, which is nearly always). Return it in a single fenced code block so it can
   be extracted and validated for real; if the package is too large for one reply to be practical, write it
   to a file in your own scratch working directory and say so explicitly, naming the exact path — never
   truncate or summarize the package itself in place of the real content. **Never declare `messages` in
   `appShell.tabs[]`/`personaTabs[]` or target it in any `renderBindings` entry** — it is a fixed,
   system-provided App Shell tab, not a community-authorable one (`antipatterns.md` AP-14).

   **`appShell.tabs[]` is easy to drop entirely — check for it as an explicit, separate step, not as part of
   reviewing each `renderBindings` entry.** After drafting every workflow, collect the full set of distinct
   non-`home` `tabId` values used anywhere across the package (there should be none using `messages`), then
   confirm every one of them has a matching entry in `appShell.tabs[]` (or `personaTabs[]` for a
   persona-scoped tab) — see
   `render-bindings.md`'s `appShell.tabs[]` / `personaTabs[]` — tab declaration shape` section (fetched at
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
4. Your manual self-check results — plainly stated, per the "On validation" section above: which rules you
   checked, and an explicit statement that no live validator ran in this channel (the dispatching session
   runs the real validator against your JSON after you return it, and will follow up separately if it finds
   something your self-check missed).

Do not attempt to build an installable `.loom-init.zip`/`.loom-extension.zip` pair — that is the dispatching
session's job, not yours, for this channel.
