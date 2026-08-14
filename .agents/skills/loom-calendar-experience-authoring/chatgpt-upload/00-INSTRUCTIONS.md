# Authoring a Loom Community Calendar Experience — Instructions

**Read this file first.** It is the entry point for the other numbered files in this upload. Together
they are the complete, authoritative reference for one narrow task: **write the JSON for a Loom
Communities "Calendar" experience** — a community where members RSVP to scheduled events and,
optionally, get reminded before one starts.

You are acting as an LLM agent that authors community JSON directly, not a human developer. You will
never write Dart, Flutter, or any other code, and you will never invent an API. Everything a Loom
community can do is expressed as JSON: state machines (`workflowDefinitions`), data schemas, guards,
effects, formulas, and render bindings. The files in this bundle enumerate that grammar completely.

## Scope — every real archetype, not just Calendar

**Broadened 2026-08-09** (this bundle was Calendar/`event-rsvp`-only from 2026-08-04 through 2026-08-09).
**Broadened again 2026-08-11, those 4 fully implemented 2026-08-12.** You may author a `workflowDefinitions`
entry for **any** workflow whose correct `cardSurfaceFamily` is listed as real in `15-archetypes.md` (the
live source of truth — always check it, this list is a summary, not a substitute):

- **7 real bespoke archetypes**: `event-rsvp` (event/RSVP/reminder — see `17-worked-example-calendar.jsonc`
  for the full worked pattern), `votePoll` (ballot/tally/eligibility/runoff), `equipment-loan` (loan/
  reservation/giveaway with a queue), `table` (sortable/filterable grid — leaderboards, rosters, anything
  browsed at scale rather than one card per item), `documentLibrary` (categorized document library —
  browse/acknowledge/version/access-request), `searchAiAnswer` (query + cited answer — see the
  platform-service caveat below), `exportWizard` (stepped export/transfer flow — see the platform-service
  caveat below).
- **6 generic-but-real archetypes** (rendered by the shared generic card, not a bespoke widget):
  `paymentCheckout`, `approvalQueueItem`, `formEntry`, `discussionThread`, `statusTimeline`,
  `notificationInbox`.
- `02-common-patterns.md` (the full copy of Loom's canonical patterns file) has a ready-made pattern for
  six of the first nine: P1 RSVP, P2 ballot, P3 approval queue, P4 loan, P5 payment, P6 discussion thread.
  `formEntry`/`notificationInbox`/`statusTimeline` are simple enough to build directly from
  `07-workflow-grammar.md` + `11-field-types.md` without a dedicated worked pattern. `table`/
  `documentLibrary`/`searchAiAnswer`/`exportWizard` need no new grammar either — `table`/`documentLibrary`
  consume ordinary `instanceDataSchema` flags (`sortable`/`searchable`/`labelTemplate`, and `type: "url"`
  fields with `openMode: "choice"` for documents — this is the fully-implemented mode real communities use
  for their primary document field); `searchAiAnswer` needs a `citations[]` list field shaped
  `{label, source: {type:"url", openMode:"external"}}` (`11-field-types.md`'s "Citation lists"); `
  exportWizard` is an ordinary state machine (scope → generate → verify → download, retry/rollback as
  needed) — its widget derives progress from the state machine itself, no particular field name required.

**Two workflow types sharing one render surface is normal, not scope-narrowing.** You may declare as many
`workflowDefinitions` entries as a request genuinely needs. Two things that don't share the same states and
transitions are two separate workflow types — that's `01-authoring-procedure.md` Step 2's ordinary test,
not you inventing a second archetype.

**searchAiAnswer/exportWizard's real platform-service gaps — still real, unchanged by the archetype now
being implemented.** `searchAiAnswer`'s answer text and `exportWizard`'s checksum/transfer-id/receipt-id
fields are real platform-service gaps (`14-platform-services.md`: "External search / AI answer" and
"Checksum / integrity hash" are both `❌ Not implemented`), independent of the archetype itself. Declare
the field, never write it from any effect, and mark it with a `NEEDS IMPLEMENTATION (platform service):
...` comment exactly as `14-platform-services.md`'s own AP-6 guidance already requires for every other
not-implemented service. Do not fabricate a value — a hardcoded-looking checksum/export-id/AI-answer is a
hard antipattern, not a shortcut. Never gate an `exportWizard` transition's *completion* on the
checksum/transfer-id field either (`20-solved-patterns.md` pattern 14) — a checksum has no honest
human-curated substitute, unlike `searchAiAnswer`'s answer (pattern 11: a real admin-curated field is a
legitimate substitute for the platform-owned answer field, as long as that platform field itself stays
honestly unwritten).

**What's actually out of scope**: a `cardSurfaceFamily` NOT listed as real in `15-archetypes.md` —
currently `audienceSelector`, `volunteerRoster`, `singleItem`, `protectedDetail`, `guidedProcess`,
`dashboard`. If a request genuinely needs one of those, say so explicitly (which part of the request, why,
what family it would need) rather than approximating it with a real archetype it doesn't belong to. Most of
these needs are already expressible with an in-scope archetype — `formEntry` + a per-field `formula` for
masking, `formEntry` + a `capacity`/count-formula for a roster's numbers, ordinary transitions for an
exclusive choice — check `15-archetypes.md`'s "Considered and explicitly NOT promoted" table before
declaring the whole request out of scope.

**If a request is only partially in scope** (the common case for a real, multi-workflow community): author
the in-scope part completely and validator-clean, and report everything else by name/section/needed-family
in the same response, rather than refusing the whole request or silently dropping part of it.

⚠️ **A trap to watch for, found 2026-08-09 authoring against a real product doc**: some product docs have
their own "Card Surface Registry Mapping" table naming surfaces like `payment`, `documents`, `calendar`,
`workflow-status`, `notification-inbox`, `portability`, `search`, `roster` — **these are not real
`cardSurfaceFamily` values**. Always translate through `15-archetypes.md`'s real names instead of copying a
product doc's own table literally: `payment`→`paymentCheckout`, `documents`/`external-document-link`→
`documentLibrary`, `calendar`→`event-rsvp`, `workflow-status`→`approvalQueueItem`/`statusTimeline`,
`notification-inbox`→`notificationInbox`, `portability`→`exportWizard`, `search`→`searchAiAnswer`,
`roster`/leaderboard-shaped browsing→`table` — see the platform-service caveat above for
`portability`/`exportWizard` and `search`/`searchAiAnswer` specifically.

## Hard rules — never violate these

1. **Emit `experienceSchemaVersion: 2`** (engine-native). This is the only schema version described in
   this bundle.
2. **Stamp all three version fields**: `schemaVersion`, `experienceSchemaVersion`,
   `workflowGrammarVersion`. Never omit them.
3. **Never emit a JSON key that isn't enumerated in these reference files.** An unknown key is silently
   ignored by the real parser — it produces a community that looks correct in the JSON but does nothing
   at runtime. If you're not sure a key exists, say so instead of guessing. **Named example this has
   actually happened with**: a renderBinding-level `"creatable": {"byPersonaIds": [...], "label": "..."}`
   field is NOT real grammar and is silently dropped. The only real way to give a persona a "+ New" FAB is
   `"actions": [{"kind": "create", "label": "...", "byPersonaIds": [...], "scope": "tab",
   "presentation": "fab"}]` on the renderBinding — copy this shape from
   `17-worked-example-calendar.jsonc`, don't improvise a shorter-looking key even if it seems plausible.
4. **Never write Dart, or ask for Dart to be written.** If a requirement seems to need code, it is either
   (a) expressible in the grammar and you haven't found the right construct yet — re-read
   `10-formulas.md` and `09-effects.md`; or (b) a genuine gap in what this narrowed bundle covers — stop
   and report it plainly instead of inventing a workaround.
5. **Never seed or effect-write a computed (`formula`) field.** Computed fields are derived at read time
   only.
6. **Never invent a `cardSurfaceFamily` value not listed as real in `15-archetypes.md`.** Do not copy a
   product doc's own "Card Surface Registry Mapping" table names either — see the CardSurfaces vocabulary
   trap in the Scope section above; those names are a different, incompatible vocabulary.
7. **When the grammar genuinely cannot express something, say so.** Never approximate, never silently
   drop a stated requirement, never substitute a hardcoded value for one that should be computed.
8. **Name event date/time fields literally `eventDate`/`eventTime` on any `event-rsvp`-bound workflow —
   never a synonym.** Found 2026-08-09: the real Calendar surface reads `instanceData['eventDate']`/
   `instanceData['eventTime']` by hardcoded string key (for tile day-position and time-label display), not
   by declared type. A field named e.g. `startDate`/`startTime` validates cleanly — the JSON-grammar
   validator cannot see this rule — but silently renders no time and sorts to midnight. Before finishing
   any `event-rsvp` workflow, grep your own draft for `eventDate`/`eventTime` on that type's
   `instanceDataSchema` and every guard/effect/formula/renderBinding that references it.
9. **Cross-reference repeat/retry language in the source material against your transition graph.** Found
   2026-08-09: a "record payment failure" transition only fired from one state when the product doc
   described retrying after failure. If the request or product doc uses words like "retry", "resubmit",
   "try again", "reopen", "undo", or "re-request", confirm the transition(s) that phrase implies actually
   cover every state a member could realistically be retrying from — not just the first state you wrote it
   against. The validator has no access to your source prose, so it cannot catch this; treat it as your
   own responsibility, same as rule 7.
10. **On every tab except `admin`, `role: "receiver"` never resolves to anyone, and `role: "actor"` only
    ever matches the literal instance creator — never assume otherwise.** Found 2026-08-09: a dues charge
    the board creates for a homeowner to pay had a `role: "actor"` binding on the `giving` tab, but "actor"
    there means `createdByPersonaId` (always the board), never the actual payer named in the transition's
    own guard — the payer could never see the card. See `12-render-bindings.md`'s normative table for the
    full per-tab mechanism. Before finishing, for every `renderBinding` using `role: "actor"` or `"receiver"`
    on a tab other than `admin`: confirm the persona the binding needs to reach really is always
    `createdByPersonaId` for that instance type. If it isn't (the guard names a different field — a payer,
    a recipient, a reservation owner, anyone who isn't guaranteed to be the creator), use `role: "any"`
    instead — the transition's own guard still restricts who can act, widening the binding's role only
    affects who can see the card. This never shows up as a validator finding — the JSON is grammar-valid
    either way.
11. **Build the requirement traceability table (`01-authoring-procedure.md` Step 9.5) and include it in
    your final answer as a real artifact, not a claim that you checked.** For every workflow, every atomic
    requirement from the product doc's tables gets a row: cite the exact JSON construct that satisfies it,
    or mark `not_implemented` with `reasoning` that cites a real, checked constraint (a validator rule, a
    closed enum, a missing `10-formulas.md` function, a `14-platform-services.md` ❌ Not-implemented row) —
    never a guessed persona/tab restriction. Found 2026-08-10: a package silently dropped an explicit
    "waiting players see queue position" requirement and justified the drop with a claim ("Player has no
    admin-tab access") that contradicted both the grammar (per-persona tab sets aren't real in grammar v1)
    and the package's own `role: "any"` binding on that exact tab. This rule exists because that kind of
    self-contradiction survives every other check in this file — a clean validator response, and hard
    rules 8-10, all check the JSON's internal consistency or specific known traps, never full doc-to-JSON
    coverage.

## Read order

| Step | File | When |
|---|---|---|
| 1 | `01-authoring-procedure.md` | Always — read this in full before writing anything. It's the algorithm: personas → workflow types → states-vs-data → states/transitions → data schema → guards → effects → render bindings → seed data → self-check → (validate). |
| 2 | `07-workflow-grammar.md` | Always — the normative contract every workflow definition must satisfy. |
| 3 | `08-guards.md`, `09-effects.md`, `10-formulas.md`, `11-field-types.md` | Always — you will reach for these four constantly while writing transitions and data schemas. |
| 4 | `02-common-patterns.md` | Read the pattern(s) matching what the request needs — **P1** RSVP with capacity/waitlist, **P2** ballot with tally/eligibility/runoff, **P3** approval queue (propose→decide), **P4** loan lifecycle with queue, **P5** payment, **P6** discussion thread. A community needing several archetypes means reading several patterns. |
| 5 | `17-worked-example-calendar.jsonc` | The richer per-member-row pattern for `event-rsvp`: response rows (`event-rsvp-response`) plus a `notification` type, needed as soon as an event-shaped request includes reminders or other per-member follow-up. Read the comments — they explain why this shape exists and cite exactly which constructs are confirmed real. |
| 6 | `12-render-bindings.md` | When deciding where each card appears and how it presents (tabs, roles, actions, FAB) — for every workflow type in the request, not just calendar-bound ones. |
| 7 | `05-actions-and-fabs.md` | When deciding whether a "create" affordance should be a FAB, and how response/decision actions should present. |
| 8 | `15-archetypes.md` | The source of truth for which `cardSurfaceFamily` is correct for **each** workflow in the request, and which values are real vs. not real — re-check this for every workflow type, not once. |
| 9 | `03-antipatterns.md` | Before you finish — self-check your JSON against every detection rule in this file. |
| 10 | `04-validation.md` | Before you finish — this is the error → fix table the real validator would use. Walk your JSON against it manually (see "On validation" below). |
| 11 | `13-theming.md`, `14-platform-services.md`, `06-card-styling.md` | Only if the request touches branding/accent colors or asks for something that sounds like it needs a backend capability (payments, auth, storage) — `14-platform-services.md` lists the closed set of things that are Loom-owned, not JSON-authorable. |
| 12 | `16-spec-version.json` | Machine-readable version numbers, for reference only. |
| 13 | `18-validator-action-openapi.yaml` | Not a reading reference — this is the schema for the live `validateCommunityPackage`/`buildExtensionPackage`/`checkValidatorHealth` action. If it's configured as an action for you, use it per "On validation" below rather than reading it as prose. |
| 14 | `19-debugging-validator-responses.md` | Read this **every time** `validateCommunityPackage` returns anything other than a clean pass, before deciding what to do about it. It defines the only two shapes a real response can have, and what to do if what you're looking at doesn't match either. |
| 15 | `20-solved-patterns.md` | Always, before Step 9.5's traceability table — recurring requirement shapes already found and fixed in real community packages, with the verified-correct JSON shape for each. Check every workflow's requirements against this list; several of these shapes were independently reinvented as bugs more than once before being named here. |
| 16 | `21-permissions.md` | Always — the `action` field and the closed action vocabulary per bespoke archetype. |

## The `action` field, and what you must never author

**Declare `action` on every transition of a bespoke-archetype workflow** — the six families with a
dispatcher case: `event-rsvp`, `votePoll`, `equipment-loan`, `documentLibrary`, `searchAiAnswer`,
`exportWizard` — using only the values listed for that family in `21-permissions.md`. **Never declare
`action` on a generic-archetype transition** (`paymentCheckout`, `approvalQueueItem`, `formEntry`,
`discussionThread`, `statusTimeline`, `notificationInbox`, `table`); those derive their permissions
structurally. `table` is the trap: it renders as a grid and reads as bespoke, but that is list layout
only — it has no dispatcher case and takes no `action`.

Three further points, each of which has already caused a real defect:

- A workflow with `"renderBindings": []` that is named by some binding's `responseTable.workflowType`
  **inherits that binding's archetype**, so an RSVP response workflow is bespoke and its transitions do
  need `action`. A workflow with no bindings and no `responseTable` owner derives nothing.
- The "Observed transitions" column is a **lookup aid, not authority**. Where it disagrees with what the
  transition's `guard`/`from`/`to`/`effects` actually do, the transition wins: `cancel-loan` means
  `withdraw_request` in one community and `return` in another.
- A workflow may mix one bespoke family with generic bindings — normal, and the bespoke family is the
  archetype. Only two or more *bespoke* families is an error.

Guards are keyed `allowedPersonaIds` / `byPersonaIds`, never `allowedRoleIds` / `byRoleIds`. Personas
become roles at install time; the JSON only ever says persona.

`action` is what the platform maps to the permission a transition needs. A missing or misnamed one
silently leaves a permission ungranted, and the action then fails at runtime for a reason no author can
see from the JSON.

**Never author a permission, a user, or a membership.** Permissions are derived from your
`allowedPersonaIds`/`byPersonaIds` combined with `action`. Joining a community, approving a member, and
assigning someone a persona are App Shell experiences, not workflows. Domain processes that accompany
joining — signing a waiver, paying a registration fee, a reviewer approving a player — remain
legitimate workflows; only the membership grant itself is out of scope.

## Two valid RSVP shapes — pick deliberately

- **`02-common-patterns.md`'s P1** (a `goingPersonaIds[]` / `maybePersonaIds[]` / `waitlistPersonaIds[]`
  list on the event itself) is simpler and is the right choice for plain "members RSVP" with no per-member
  follow-up.
- **The `event-rsvp` / `event-rsvp-response` pair** in `17-worked-example-calendar.jsonc` (one row per
  event per member) is required as soon as you need to do anything *per member* afterward — most
  importantly, **sending a reminder notification**, since a notification's recipient must be read off a
  real field on a real row (`{personaId}`), not extracted from inside a shared list. If the request
  mentions reminders, notifications, or "let each member manage their own RSVP," use this shape.

Do not mix the two within one workflow type — pick one per community.

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

1. **One JSON (or JSONC) file**, structured exactly like `17-worked-example-calendar.jsonc`'s envelope
   (`schemaVersion`, `packageId`, `communityId`, `communityHandle`, `displayName`, `extensionId`,
   `branding`, `seedDataFiles`, `idempotencyKey`, then the `experience` block). Give the community its own
   identity (name, tagline, accent color, personas) appropriate to whatever was actually requested — reuse
   the workflow-definition *shapes*, not the literal Riverbend Run Club content.
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
