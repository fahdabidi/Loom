---
name: loom-calendar-experience-authoring
description: Author the JSON for a Loom Communities Calendar (event-RSVP) experience, using only docs/references as source material. A narrow, portable subset of the full using-loom-to-build-an-extension skill, scoped to the one experience type that is currently built and verified end-to-end (Tabletop Club's Calendar). Provider-neutral by construction — the same reference material is exported as a standalone upload bundle for LLMs with no repo/tool access, such as a ChatGPT session.
---

# Loom Calendar Experience Authoring

Use this Skill to write the JSON for a Loom Communities **Calendar (event-RSVP)** experience — the
event/RSVP/reminder pattern verified live in Tabletop Club this build cycle. It deliberately does not
cover any other experience type (payments, ballots, loans, marketplaces, document libraries, etc.); those
belong to the full [`using-loom-to-build-an-extension`](../using-loom-to-build-an-extension/SKILL.md)
skill, which also owns the build/validate/sideload/certify pipeline this Skill does not attempt.

**This Skill only ever refers to [`docs/references`](../../../docs/references).** No `components/`,
`workflows/`, `setup/`, or dart-tooling references — those are the internal repo's build/validate/certify
machinery, out of scope here. `docs/references` is already written for exactly this purpose ("Audience: an
LLM agent... not a human tutorial" — see its own
[`README.md`](../../../docs/references/README.md)): complete enumerations, explicit invariants, and a
load-order table.

## Why this exists

`using-loom-to-build-an-extension` assumes a local repo, dart tooling, an Android emulator, and a
Codex/Claude-Code execution target — its own SKILL.md says as much ("online-only chat surfaces are
deferred until Loom has a hosted build and validation backend"). This Skill exists to answer a narrower,
testable question: **is `docs/references` alone — no repo, no tools, no code execution — sufficient for
an LLM to author a working Calendar experience?** The `chatgpt-upload/` folder in this Skill is the
portable export used to test that directly against a provider with no filesystem or tool access.

## Scope

Build only:
- The event itself (`event-rsvp`): scheduling, capacity, cancellation, editing.
- Member RSVP (`event-rsvp-response`, one row per event per member): going / maybe / declined /
  waitlisted, with a real capacity guard.
- Reminders (`notification`): a per-member notice created before an event starts.

See [`docs/references/archetypes/README.md`](../../../docs/references/archetypes/README.md) — `event-rsvp`
is the only `cardSurfaceFamily` this Skill's scope needs, and the status table there tells you what is and
isn't real in the live app today. Anything outside this scope is a signal to use
`using-loom-to-build-an-extension` instead, not to force-fit it into this Skill's constructs.

## Read order

Same load order as `docs/references/README.md`, narrowed to what a Calendar experience needs:

1. [`docs/references/guide/01-authoring-procedure.md`](../../../docs/references/guide/01-authoring-procedure.md) — the algorithm.
2. [`docs/references/reference/workflow-grammar.md`](../../../docs/references/reference/workflow-grammar.md) — the contract.
3. [`docs/references/reference/guards.md`](../../../docs/references/reference/guards.md), [`effects.md`](../../../docs/references/reference/effects.md), [`formulas.md`](../../../docs/references/reference/formulas.md), [`field-types.md`](../../../docs/references/reference/field-types.md).
4. [`docs/references/guide/03-common-patterns.md`](../../../docs/references/guide/03-common-patterns.md) — P1 (RSVP with capacity and waitlist) for the simple case.
5. [`chatgpt-upload/17-worked-example-calendar.jsonc`](./chatgpt-upload/17-worked-example-calendar.jsonc) — the richer per-member-row + reminder pattern, needed as soon as the request includes notifications.
6. [`docs/references/reference/render-bindings.md`](../../../docs/references/reference/render-bindings.md) and [`guide/07-actions-and-fabs.md`](../../../docs/references/guide/07-actions-and-fabs.md) — where the event card appears and how the "New event" affordance presents.
7. [`docs/references/archetypes/README.md`](../../../docs/references/archetypes/README.md) — confirm `event-rsvp` is correct.
8. [`docs/references/guide/04-antipatterns.md`](../../../docs/references/guide/04-antipatterns.md) and [`guide/05-validation.md`](../../../docs/references/guide/05-validation.md) — self-check before emitting.
9. [`docs/references/reference/theming.md`](../../../docs/references/reference/theming.md), [`platform-services.md`](../../../docs/references/reference/platform-services.md) — only if relevant.

When run inside this repo (Claude Code, Codex), read these files live from `docs/references` — they are
kept current there. Do not read the copies under `chatgpt-upload/`; those are frozen at export time for a
provider that cannot reach this repo.

## The two RSVP shapes

- `guide/03-common-patterns.md`'s **P1** (`goingPersonaIds[]` list on the event) — the plain case, no
  per-member follow-up.
- `event-rsvp` / `event-rsvp-response` (one row per event per member) — required as soon as the community
  needs anything per-member afterward, most importantly a reminder notification, since a notification's
  recipient is read off a real row's own `personaId` field, not extracted from inside a shared list. See
  `chatgpt-upload/17-worked-example-calendar.jsonc` for the full pattern, curated from constructs
  individually confirmed real in `guards.md`/`effects.md`/`formulas.md` — this is the same architecture
  Tabletop Club's Calendar tab actually runs, simplified to a single-workflow community for teaching.

## Validation

In-repo (Claude Code/Codex), run the real validator per
[`guide/01-authoring-procedure.md`](../../../docs/references/guide/01-authoring-procedure.md) Step 11
before treating any output as a deliverable:

```bash
dart run loom_ux_judges:community_package_validator --package <your-file>.jsonc
```

A provider with no tool access (the `chatgpt-upload/` test case) cannot run this. Its output is a
self-checked draft only — walk it through the real validator, and the app-shell/emulator gates in
`using-loom-to-build-an-extension`, before treating it as anything more.

## `chatgpt-upload/` — the portable export

[`chatgpt-upload/`](./chatgpt-upload) is a flat, self-contained bundle of the exact reference material
above, renumbered to match the read order (`00-INSTRUCTIONS.md` through `17-worked-example-calendar.jsonc`),
for uploading to a provider with no repo access. Regenerate it from `docs/references` (do not hand-edit
individual copies out of sync with the source) whenever the source files it mirrors change:

```bash
SRC="docs/references"
DST=".agents/skills/loom-calendar-experience-authoring/chatgpt-upload"
cp "$SRC/guide/01-authoring-procedure.md"   "$DST/01-authoring-procedure.md"
cp "$SRC/guide/03-common-patterns.md"       "$DST/02-common-patterns.md"
cp "$SRC/guide/04-antipatterns.md"          "$DST/03-antipatterns.md"
cp "$SRC/guide/05-validation.md"            "$DST/04-validation.md"
cp "$SRC/guide/07-actions-and-fabs.md"      "$DST/05-actions-and-fabs.md"
cp "$SRC/guide/08-card-styling.md"          "$DST/06-card-styling.md"
cp "$SRC/reference/workflow-grammar.md"     "$DST/07-workflow-grammar.md"
cp "$SRC/reference/guards.md"               "$DST/08-guards.md"
cp "$SRC/reference/effects.md"              "$DST/09-effects.md"
cp "$SRC/reference/formulas.md"             "$DST/10-formulas.md"
cp "$SRC/reference/field-types.md"          "$DST/11-field-types.md"
cp "$SRC/reference/render-bindings.md"      "$DST/12-render-bindings.md"
cp "$SRC/reference/theming.md"              "$DST/13-theming.md"
cp "$SRC/reference/platform-services.md"    "$DST/14-platform-services.md"
cp "$SRC/archetypes/README.md"              "$DST/15-archetypes.md"
cp "$SRC/spec-version.json"                 "$DST/16-spec-version.json"
```

`00-INSTRUCTIONS.md`, `17-worked-example-calendar.jsonc`, and `18-validator-action-openapi.yaml` are
authored directly in this Skill (not copied from `docs/references`) — update them by hand when the read
order, the worked pattern, or the validator endpoint changes. A zip of the same folder
(`chatgpt-upload.zip`) is provided alongside it for one-shot upload.

## Live validator: a real validator reachable over HTTP, not just self-check prose

`docs/references`' own procedure requires running the real validator CLI before treating a package as
done — something an external ChatGPT session has no way to do on its own. As of 2026-08-04 there's a
second option: a local REST wrapper around the exact same `CommunityPackageValidator` the CLI and test
suite use, exposed publicly through a Cloudflare quick tunnel, callable as a ChatGPT Custom GPT Action.

**Running it:**

```bash
# from app/, inside WSL (dart lives there, not on the Windows side)
dart run packages/tooling/loom_ux_judges/bin/validator_server.dart --port 8787
# in a separate terminal, also inside WSL:
~/tools/cloudflared tunnel --url http://localhost:8787
```

`cloudflared` prints a fresh `https://<random-words>.trycloudflare.com` URL every time it starts — there
is no persistent address. Whoever sets up the Custom GPT Action needs the current URL, pasted into
`18-validator-action-openapi.yaml`'s `servers[0].url` before uploading that schema into the GPT builder's
**Actions** tab (not Knowledge, where the other numbered files go). Direct exposure via the router's DMZ
was tried first and hit an `ECONNREFUSED` from a genuinely external test (likely CGNAT or a DMZ
target-IP mismatch — not conclusively diagnosed) before falling back to the tunnel.

**Server code**: `app/packages/tooling/loom_ux_judges/lib/src/validator/validator_http_server.dart`
(library, tested by `test/validator_http_server_test.dart`) — `bin/validator_server.dart` is a thin CLI
wrapper. Routes: `GET /health`, `POST /validate` (body: the full package, JSON or JSONC; response: the
same `{status, errorCount, warningCount, findings}` shape the CLI prints).

**Operational notes:**
- The quick tunnel has no uptime guarantee (Cloudflare's own disclaimer) and the WSL2-internal IP
  `netsh interface portproxy` would depend on (if direct exposure is revisited later) changes across WSL
  restarts — neither is durable infrastructure, both are fine for an interactive test session.
- `00-INSTRUCTIONS.md`'s validation section now tells the authoring agent to call
  `validateCommunityPackage` before presenting any package as finished, and to fall back to the old
  manual self-check only if the action is unavailable.

## Reviewing what comes back

When a JSON package built from this bundle (by ChatGPT or anything else) comes back for inspection:

1. Confirm the envelope and version fields (`schemaVersion: 1`, `experienceSchemaVersion: 2`,
   `workflowGrammarVersion: 1`) are present and correct — an LLM authoring from this bundle with no
   validator access has gotten `workflowGrammarVersion` wrong before (stamped `2` instead of `1`); the
   real validator rejects it outright (`unsupported_schema_version`).
2. Run it through the real validator CLI (`community_package_validator.dart`) as soon as the package is
   in-repo — do not rely on a manual re-read of `04-antipatterns.md`/`05-validation.md` as a substitute,
   the CLI is authoritative and catches more than either of us will by eye.
3. Check every `personaId`, `workflowType`, and cross-instance reference (`eventId`, etc.) actually
   resolves to something declared elsewhere in the same package.
4. Confirm no computed (`formula`) field was seeded or effect-written, and no key appears that isn't
   enumerated in `docs/references/reference/`.
5. If it used the per-member response-row shape, confirm reminders are wired the way
   `17-worked-example-calendar.jsonc` shows: `actorEqualsField` on `send-reminder`, `{personaId}`
   interpolated into `recipientPersonaId` — this is the exact mechanism a real identity-scoping bug in the
   live app was just fixed against, so it's worth extra scrutiny.

### The validator now catches three "expected affordance" gaps automatically

A first real test of this bundle (ChatGPT, Apartment Events community, 2026-08-03) came back
structurally valid but with three real functional gaps the validator's structural checks didn't catch —
the organizer could never create a new event, `editableFields` was declared but silently inert with no
`editGuard`, and a facility-reservation type had no exclusion from ordinary RSVP transitions. The first
two are common enough (they turned out to already be present in several of the repo's own legacy example
fixtures — Garden Club, Camera Club, Book Club, Chess Club, Youth Soccer, Mosque) that they're now
**automated validator warnings**, added directly to
`app/packages/tooling/loom_ux_judges/lib/src/validator/workflow_validator.dart`:

- `editable_fields_without_edit_guard` — a state declares `editableFields` with no `editGuard`. Per
  `workflow-grammar.md`, `editGuard`'s absent-default is the *opposite* of every other guard: no editor
  is ever rendered, for any persona. "Implemented edit, but nothing can save it."
- `no_creation_path_for_editable_type` — a workflow type has `formEntry` fields but no `kind: "create"`
  action and no `createInstance`/`generateRecurringInstances` effect anywhere in the package ever targets
  it. Every instance that will ever exist is whatever was seeded (AP-13). "Implemented edit, but no
  create." Package-level (an action or effect on a *different* type can satisfy this for a cross-archetype
  create).
- `no_destructive_exit_for_managed_type` — a primary-bound, actively-managed type (declares an
  `editGuard` somewhere) has zero `tone: "destructive"` transition anywhere. "Implemented create, but no
  cancel/withdraw/delete." Lower-confidence heuristic than the other two; plenty of types legitimately
  never need one.

All three are warnings (never block `report.passed`), since each has legitimate exceptions — they're
signal to double-check, not hard failures. The single-type-serving-two-transition-sets issue (facility
reservation vs. ordinary RSVP sharing one workflow type) was judged too bespoke to generalize safely and
was **not** added as an automated check; that one still needs a human/LLM re-read of `guide/01`'s Step 2
type-vs-instance test ("do these two things have the same transitions? If no → two types").
Tests: `workflow_validator_expected_affordance_test.dart`.
