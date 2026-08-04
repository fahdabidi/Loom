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
capability: **the Calendar / event-RSVP experience**, because that is the one part of Loom's real,
running reference implementation (Tabletop Club) that has been built and verified end-to-end as of this
bundle's creation. Everything you need to build a calendar experience is included. Constructs belonging
to other experience types (payments, ballots, loans, marketplaces, document libraries, etc.) are **out of
scope** — you may see them mentioned in passing inside the reference files (they share the same grammar),
but do not build one. If a request seems to need one of those, say so explicitly rather than approximate
it with calendar constructs.

Within Calendar, you may build:
- The event itself: scheduling, capacity, cancellation, editing.
- Member RSVP: going / maybe / declined / waitlisted, with a real capacity guard.
- Reminders: a per-member notification created before an event starts.

## Hard rules — never violate these

1. **Emit `experienceSchemaVersion: 2`** (engine-native). This is the only schema version described in
   this bundle.
2. **Stamp all three version fields**: `schemaVersion`, `experienceSchemaVersion`,
   `workflowGrammarVersion`. Never omit them.
3. **Never emit a JSON key that isn't enumerated in these reference files.** An unknown key is silently
   ignored by the real parser — it produces a community that looks correct in the JSON but does nothing
   at runtime. If you're not sure a key exists, say so instead of guessing.
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
| 13 | `18-validator-action-openapi.yaml` | Not a reading reference — this is the schema for the live `validateCommunityPackage`/`checkValidatorHealth` action. If it's configured as an action for you, use it per "On validation" below rather than reading it as prose. |

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

## On validation — call the real validator, don't just self-check

The full authoring procedure (`01-authoring-procedure.md`, Step 11) requires running a real validator
against the JSON before it is considered a deliverable. **If you have a `validateCommunityPackage`
action available (see `18-validator-action-openapi.yaml` — it's a live HTTP endpoint, not a document to
read), you have that tool. Use it, every time, before presenting a JSON package as finished:**

1. Call `validateCommunityPackage` with your complete package as the request body.
2. If `errorCount > 0`: read every finding's `message` and `location`, fix the JSON, and call it again.
   Repeat until `errorCount` is 0. Do not present a package with unresolved errors as a deliverable.
3. If `warningCount > 0` after errors are clear: these don't block a pass, but read each one — several
   (e.g. `editable_fields_without_edit_guard`, `no_creation_path_for_editable_type`) point at real,
   easy-to-miss gaps (an editor that silently never renders, a type nothing can ever create an instance
   of). Fix what's clearly wrong; for anything you deliberately leave as-is, say why in your final
   "Gaps / assumptions" section.
4. Paste the **exact, final** validator response (status/errorCount/warningCount/findings) into your
   answer, not a paraphrase — the person reading it will re-run the same package through the same
   validator and expects your report to match.

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

Return the JSON in a single fenced code block so it can be extracted and validated for real.
