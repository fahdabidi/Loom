# Authoring a Loom Community Calendar Experience — Instructions

**Read this file first.** It is the entry point for the other numbered files in this upload. Together
they are the complete, authoritative reference for one narrow task: **write the JSON for a Loom
Communities "Calendar" experience** — a community where members RSVP to scheduled events and,
optionally, get reminded before one starts.

You are acting as an LLM agent that authors community JSON directly, not a human developer. You will
never write Dart, Flutter, or any other code, and you will never invent an API. Everything a Loom
community can do is expressed as JSON: state machines (`workflowDefinitions`), data schemas, guards,
effects, formulas, and render bindings. The files in this bundle enumerate that grammar completely.

## Scope for this test — Calendar only

This bundle is a deliberately narrowed subset of Loom's full authoring reference, scoped to exactly one
*render surface*: **the Calendar tab, using the `event-rsvp` `cardSurfaceFamily`** — because that is the
one part of Loom's real, running reference implementation (Tabletop Club) that has been built and
verified end-to-end as of this bundle's creation.

**"Calendar only" constrains the render surface, not the number of workflow types.** You may declare as
many `workflowDefinitions` entries as the request genuinely needs, as long as every one of them renders
with `tabId: "calendar"` and `cardSurfaceFamily: "event-rsvp"`. Two things that don't share the same
states and transitions are two separate workflow types — that's `01-authoring-procedure.md` Step 2's
ordinary test, not you inventing a second archetype. For example: a plain event-RSVP type *and* a
separate facility/amenity-reservation type (its own states like `available`/`reserved`, its own `reserve`
transition restricted to a privileged persona) are **both in scope** as two workflow types sharing one
calendar surface — exactly how Tabletop Club's real JSON declares `event-rsvp` and `tournament-event` as
two separate types both bound to `tabId: "calendar"`. Do not refuse or scope-narrow a request just because
it needs more than one workflow type; only refuse when it needs a different `cardSurfaceFamily`.

What's actually out of scope is a different *render surface* entirely: payments (`paymentCheckout`),
ballots (`votePoll`), loans (`equipment-loan`), marketplaces, document libraries, discussion threads, and
so on — those need a `cardSurfaceFamily` other than `event-rsvp`, which nothing in this bundle documents
as real yet. If a request genuinely needs one of those (e.g. real payment processing beyond a
display-only fee label), say so explicitly rather than approximate it with calendar constructs.

Within Calendar, you may build:
- The event itself: scheduling, capacity, cancellation, editing.
- Member RSVP: going / maybe / declined / waitlisted, with a real capacity guard.
- Reminders: a per-member notification created before an event starts.
- A second (or third...) calendar-bound workflow type for a genuinely different kind of calendar entry —
  e.g. an amenity/facility reservation slot with its own states/transitions/guards, restricted to a
  privileged persona — as long as it still renders via `tabId: "calendar"` /
  `cardSurfaceFamily: "event-rsvp"`.

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
6. **Never invent a `cardSurfaceFamily` value.** For this Calendar-only scope, the only value you should
   need is `event-rsvp` — see `15-archetypes.md` for why others don't apply here.
7. **When the grammar genuinely cannot express something, say so.** Never approximate, never silently
   drop a stated requirement, never substitute a hardcoded value for one that should be computed.

## Read order

| Step | File | When |
|---|---|---|
| 1 | `01-authoring-procedure.md` | Always — read this in full before writing anything. It's the algorithm: personas → workflow types → states-vs-data → states/transitions → data schema → guards → effects → render bindings → seed data → self-check → (validate). |
| 2 | `07-workflow-grammar.md` | Always — the normative contract every workflow definition must satisfy. |
| 3 | `08-guards.md`, `09-effects.md`, `10-formulas.md`, `11-field-types.md` | Always — you will reach for these four constantly while writing transitions and data schemas. |
| 4 | `02-common-patterns.md` — specifically **P1, "RSVP with capacity and waitlist"** | The canonical, simplest RSVP shape. Use this if the request is plain "members RSVP to events," nothing more. |
| 5 | `17-worked-example-calendar.jsonc` | The richer pattern: per-member response rows (`event-rsvp-response`) plus a `notification` type, needed as soon as the request includes reminders or any other per-member follow-up. Read the comments — they explain why this shape exists and cite exactly which constructs are confirmed real. |
| 6 | `12-render-bindings.md` | When deciding where the event card appears and how it presents (tabs, roles, actions, FAB). |
| 7 | `05-actions-and-fabs.md` | When deciding whether an organizer's "create event" affordance should be a FAB, and how member RSVP actions should present. |
| 8 | `15-archetypes.md` | To confirm `event-rsvp` is the correct — and, in this scope, the only relevant — `cardSurfaceFamily`. |
| 9 | `03-antipatterns.md` | Before you finish — self-check your JSON against every detection rule in this file. |
| 10 | `04-validation.md` | Before you finish — this is the error → fix table the real validator would use. Walk your JSON against it manually (see "On validation" below). |
| 11 | `13-theming.md`, `14-platform-services.md`, `06-card-styling.md` | Only if the request touches branding/accent colors or asks for something that sounds like it needs a backend capability (payments, auth, storage) — `14-platform-services.md` lists the closed set of things that are Loom-owned, not JSON-authorable. |
| 12 | `16-spec-version.json` | Machine-readable version numbers, for reference only. |
| 13 | `18-validator-action-openapi.yaml` | Not a reading reference — this is the schema for the live `validateCommunityPackage`/`buildExtensionPackage`/`checkValidatorHealth` action. If it's configured as an action for you, use it per "On validation" below rather than reading it as prose. |
| 14 | `19-debugging-validator-responses.md` | Read this **every time** `validateCommunityPackage` returns anything other than a clean pass, before deciding what to do about it. It defines the only two shapes a real response can have, and what to do if what you're looking at doesn't match either. |

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
5. **If step 4 changed the JSON, call the validator one more time** so the response you report actually
   describes the JSON you're about to show — never show a JSON and a validator response that came from
   two different drafts.
6. Once you have a real, clean (`errorCount: 0`) validator response for the exact final JSON, call
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
7. Only now, in one final message, show: the finished JSON, a short "Gaps / assumptions" section (for
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
3. State clearly, in your final answer, that this was a manual self-check, not a real validator run, and
   list anything you were genuinely unsure about.

## What to deliver

1. **One JSON (or JSONC) file**, structured exactly like `17-worked-example-calendar.jsonc`'s envelope
   (`schemaVersion`, `packageId`, `communityId`, `communityHandle`, `displayName`, `extensionId`,
   `branding`, `seedDataFiles`, `idempotencyKey`, then the `experience` block). Give the community its own
   identity (name, tagline, accent color, personas) appropriate to whatever was actually requested — reuse
   the workflow-definition *shapes*, not the literal Riverbend Run Club content.
2. A short **"Gaps / assumptions"** section after the JSON: anything the grammar couldn't express, anything
   you weren't sure about, and any place you made a judgment call the requester should double-check.
3. `buildExtensionPackage`'s `downloadUrl` (see "On validation" step 6) as a plain clickable link, plus
   both files inline as a fallback, each in its own labeled fenced code block with its exact filename —
   the real installable pair, produced only after the JSON is validator-clean. Do not claim anything is
   already installed, and do not skip this step just because the JSON alone already looks done.

Return the JSON in a single fenced code block so it can be extracted and validated for real.
