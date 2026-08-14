---
name: loom-calendar-experience-authoring
description: Author the JSON for a Loom Communities experience using only docs/references as source material, restricted to the 13 archetypes confirmed real in docs/references/archetypes/README.md (event-rsvp, votePoll, equipment-loan, paymentCheckout, approvalQueueItem, formEntry, discussionThread, statusTimeline, notificationInbox, table, documentLibrary, searchAiAnswer, exportWizard — the last 4 promoted 2026-08-11 and fully implemented, registry+dispatch+widget, 2026-08-12; searchAiAnswer/exportWizard each still carry one real platform-service field gap, see "searchAiAnswer/exportWizard's platform-service gaps" below). Originally scoped to Calendar/event-RSVP only (2026-08-04); broadened 2026-08-09 once every other real archetype was confirmed to already have a canonical pattern in docs/references/guide/03-common-patterns.md; broadened again 2026-08-11 for 4 more archetypes, implemented 2026-08-12. This is the ONLY sanctioned way to author or edit real community JSON in this repo — never hand-author community *.jsonc content directly, even for a small, well-understood change. A narrow, portable subset of the full using-loom-to-build-an-extension skill — deliberately does NOT use that skill's components/card-surfaces/* material, which uses a different, incompatible vocabulary from the real cardSurfaceFamily enum (see "CardSurfaces vocabulary trap" below). Provider-neutral by construction — the same reference material is exported as a standalone upload bundle for LLMs with no repo/tool access, such as a ChatGPT session.
---

# Loom Calendar Experience Authoring

## Status: confirmed working end-to-end (2026-08-04)

A live ChatGPT Custom GPT built entirely from `chatgpt-upload/`'s 20 files — no repo access, no local
tools — produced a two-workflow-type "Apartment Events" calendar package (event RSVP + a separate
facility-reservation type), called the live `validateCommunityPackage` action itself, and self-reported
`{"status":"pass","errorCount":0,"warningCount":0,"findings":[]}`. Independently re-running the same JSON
through the real validator here matched byte-for-byte. This closes the loop this Skill exists to test:
**`docs/references` alone is sufficient for an external LLM, with no repo or tool access, to author a
real, validator-clean Loom Calendar experience — and, per the "Installing what comes back" section below,
that JSON can then actually be installed and rendered in the real app, not just pass structural
validation.**

Getting here took four rounds of real failures, each with a durable fix baked into this bundle: an
over-narrow scope reading (a request needing two workflow types was wrongly refused — fixed in
`00-INSTRUCTIONS.md`'s Scope section), an invented `creatable` render-binding key (fixed as a named
example in Hard Rule 3), a ChatGPT Action-calling layer that either sent empty request bodies or
**fabricated plausible-looking but definitely-fake error text** (`UnrecognizedKwargsError: (...)` is not
a shape our Dart server can produce) instead of honestly reporting a failed call (fixed via the
`packageJson`-string-wrapped request shape plus the new `19-debugging-validator-responses.md` anti-
fabrication guide), and a per-call consent-prompt loop that stalled the multi-step validate-and-fix cycle
with no visible progress (fixed via `x-openai-isConsequential: false` on both operations). Treat one clean
round as a strong result, not a permanent guarantee — the mechanism is demonstrably capable of working,
not proven immune to regressing.

**Broadened 2026-08-09 — read the Scope section below, not this paragraph, for current coverage.** This
Skill no longer covers Calendar/event-RSVP only. It covers every archetype confirmed real in
`docs/references/archetypes/README.md` (`event-rsvp`, `votePoll`, `equipment-loan`, `paymentCheckout`,
`approvalQueueItem`, `formEntry`, `discussionThread`, `statusTimeline`, `notificationInbox`) — see the
"Scope" section for the current, authoritative list and the archetypes it still doesn't cover. It still
does not own the build/validate/sideload/certify pipeline; that remains
[`using-loom-to-build-an-extension`](../using-loom-to-build-an-extension/SKILL.md)'s job. This Skill also
deliberately never reads that sibling Skill's `components/card-surfaces/*` material — see the "CardSurfaces
vocabulary trap" warning in Scope for why.

**This Skill only ever refers to [`docs/references`](../../../docs/references).** No `components/`,
`workflows/`, `setup/`, or dart-tooling references — those are the internal repo's build/validate/certify
machinery, out of scope here. `docs/references` is already written for exactly this purpose ("Audience: an
LLM agent... not a human tutorial" — see its own
[`README.md`](../../../docs/references/README.md)): complete enumerations, explicit invariants, and a
load-order table.

## Three channels, one source of truth

This Skill is dispatched the same way regardless of who's running it — read `docs/references` (plus this
bundle), author against the target spec, self-check, report. Three channels are proven working as of
2026-08-11:

1. **In-repo, full access** — a Claude Code `Agent` tool dispatch (or an equivalent session with real
   filesystem/tool access to this repo) reading `docs/references/**` directly off disk. Fastest to iterate,
   used for most of the 11 real communities under `docs/references/communities/`.
2. **Zero-tool-access external provider** — the [`chatgpt-upload/`](./chatgpt-upload) bundle (20 files),
   uploaded as-is to a provider with no repo access and no code execution (proven end-to-end against a
   ChatGPT Custom GPT, see "Status" above). Everything the Skill needs must be reachable by *reading docs
   alone* — the whole point is testing whether documentation-as-interface is sufficient.
3. **Zero-repo-access, live GitHub fetch (Codex CLI)** — `data/call_skill_authoring_agent.sh` dispatches
   Codex CLI (profile `gpt5_6_sol_xhigh`, i.e. GPT-5.6-Sol at xhigh reasoning) with its working root pointed
   at an empty scratch directory outside this repo (`-C`, no `--add-dir`, `--skip-git-repo-check`) — this
   emulates the zero-tool-access provider's isolation, but with GitHub read access instead of a pre-attached
   file bundle, so the agent fetches `docs/references/**` live via Codex's built-in `github.fetch_file` tool
   rather than reading a static snapshot. Full brief:
   [`codex-dispatch/INSTRUCTIONS.md`](./codex-dispatch/INSTRUCTIONS.md). **Confirmed by direct, real dispatch
   (2026-08-11, not assumed)**: a scoped smoke test correctly fetched and quoted `archetypes/README.md`'s
   then-just-pushed `doc_version`/`last_verified`/section-heading values verbatim, proving it reads live
   `origin/main` content, not stale or pretrained knowledge. Because there is no live validator reachable
   from inside that sandbox (confirmed separately — shell-level network access to arbitrary HTTPS endpoints
   is blocked there), this channel runs a rigorous **manual** self-check and defers real validator
   confirmation to the dispatching session, immediately after the agent returns its JSON — never trust this
   channel's own self-report of validity as the final word.

Every edit to `docs/references/**` that changes authoring behavior must be mirrored into `chatgpt-upload/`
(see that folder's own section below) — channels 2 and 3 both depend on it, deliberately kept in lockstep
rather than left to drift.

## Why this exists

`using-loom-to-build-an-extension` assumes a local repo, dart tooling, an Android emulator, and a
Codex/Claude-Code execution target — its own SKILL.md says as much ("online-only chat surfaces are
deferred until Loom has a hosted build and validation backend"). This Skill exists to answer a narrower,
testable question: **is `docs/references` alone — no repo, no tools, no code execution — sufficient for
an LLM to author a working Calendar experience?** The `chatgpt-upload/` folder in this Skill is the
portable export used to test that directly against a provider with no filesystem or tool access.

## Scope

**Broadened 2026-08-09** (was Calendar/`event-rsvp`-only from 2026-08-04). **Broadened again 2026-08-11,
those 4 fully implemented 2026-08-12** (archetype gap-closure audit — see `archetypes/README.md`'s
"Promoted archetypes — closed 2026-08-12" section). Build any workflow whose required `cardSurfaceFamily`
is confirmed real in
[`docs/references/archetypes/README.md`](../../../docs/references/archetypes/README.md) — that file is the
live source of truth, always re-check it, do not treat the list below as frozen:

- **3 real bespoke archetypes**: `event-rsvp` (event/RSVP/reminder — the original scope, still the richest-
  taught pattern, see `chatgpt-upload/17-worked-example-calendar.jsonc`), `votePoll` (ballot with tally/
  eligibility/runoff), `equipment-loan` (loan/reservation/giveaway lifecycle with a queue).
- **6 🟡 GENERIC archetypes** (real, rendered by the shared `GenericWorkflowInstanceCard`, not a bespoke
  widget): `paymentCheckout`, `approvalQueueItem`, `formEntry`, `discussionThread`, `statusTimeline`,
  `notificationInbox`.
- Each of the 3 bespoke + payment/approval/loan/discussion above has a canonical pattern already written in
  [`docs/references/guide/03-common-patterns.md`](../../../docs/references/guide/03-common-patterns.md) —
  P1 (RSVP), P2 (ballot), P3 (approval queue), P4 (loan), P5 (payment), P6 (discussion thread). `formEntry`
  and `notificationInbox` are simple enough (a field/button pair; a sender→recipient record) not to need a
  dedicated pattern — build them directly from `workflow-grammar.md` + `field-types.md`.
- **4 more ✅ REAL archetypes** (promoted into the vocabulary 2026-08-11, fully implemented — registry,
  dispatch, and a real bespoke widget each — 2026-08-12): `table` (sortable/filterable grid — leaderboards,
  rosters, anything browsed at scale rather than one card per item), `documentLibrary` (categorized
  document library — browse/acknowledge/version/access-request), `searchAiAnswer` (query + cited answer —
  the widget is real, the actual answer computation remains a platform-service gap, see "searchAiAnswer/
  exportWizard's platform-service gaps" below), `exportWizard` (stepped export/transfer flow — the widget
  is real, checksum/ID generation remains a platform-service gap, see below).

**Explicitly out of scope — say so per Hard Rule 7, never force-fit**: any `cardSurfaceFamily` still marked
❌ NOT REAL in `archetypes/README.md` as of this writing — `audienceSelector`, `volunteerRoster`,
`singleItem`, `protectedDetail`, `guidedProcess`, `dashboard` (the last four were specifically audited and
rejected for promotion 2026-08-11 — see `archetypes/README.md`'s "Considered and explicitly NOT promoted"
table for why each one; the underlying capability those requests need is almost always already expressible
with an in-scope archetype — `formEntry` + a per-field `formula` for masking, `formEntry` + the existing
`capacity`/count-formula pattern for a roster's numbers, 3 ordinary transitions for an exclusive choice —
check that table before refusing). A request needing one of the genuinely out-of-scope six gets a plain,
specific refusal (which product-doc section, why it doesn't fit any real family, what family it would
actually need if it existed) — not an approximation with a real archetype it doesn't belong to, and not a
silent drop.

### Authoring `table` / `documentLibrary` / `searchAiAnswer` / `exportWizard` — all 4 now ✅ REAL

All 4 are fully implemented as of 2026-08-12 (`TabId-Archetype Gap Closure.md`'s Milestone 1, closed) —
use the real name like any other archetype; they validate cleanly, with no `unknown_card_surface_family`
caveat to report. Two of the four (`searchAiAnswer`, `exportWizard`) still carry a real, separate
platform-service gap on specific fields — see below, this is the only remaining special handling:

1. Author the workflow's grammar exactly as for any other archetype — no new grammar exists for any of
   these 4; `table` and `documentLibrary` need nothing beyond ordinary `instanceDataSchema` flags already
   in every pattern (`sortable`/`searchable`/`labelTemplate`, and `type: "url"` fields for documents —
   `openMode: "choice"` is the fully-implemented mode real communities use for their primary document
   field, giving both an embedded-viewer and an external-open control; `openMode: "external"` alone also
   works for a secondary/attachment-style link); `searchAiAnswer` needs a `citations[]` list field shaped
   `{label, source: {type:"url", openMode:"external"}}` (`field-types.md`'s "Citation lists," also fully
   implemented); `exportWizard` is an ordinary state machine (scope → generate → verify → download, with
   error/retry/rollback states as needed) — its widget derives progress from the state machine itself, so
   no particular field name is required for that part.
2. **searchAiAnswer/exportWizard's platform-service gaps — still real, unchanged by the archetype now
   being implemented.** `searchAiAnswer`'s answer text and `exportWizard`'s checksum/transfer-id/receipt-id
   fields are real platform-service gaps (`platform-services.md`: "External search / AI answer" and
   "Checksum / integrity hash" are both `❌ Not implemented`), independent of the archetype itself. Declare
   the field, never write it from any effect, and mark it with a `NEEDS IMPLEMENTATION (platform service):
   ...` comment exactly as `platform-services.md`'s own AP-6 guidance already requires for every other
   not-implemented service. Do not fabricate a value. Per `solved-patterns.md` pattern 14, never gate an
   `exportWizard` transition's *completion* on the checksum/transfer-id field either — a checksum has no
   honest human-curated substitute, unlike `searchAiAnswer`'s answer (pattern 11: a real admin-curated
   field, e.g. a `curatedSummary`-style field, is a legitimate substitute for the platform-owned answer
   field, as long as the platform field itself still stays honestly unwritten).

**If a request is only partially in scope** (common — most real communities mix in-scope and out-of-scope
workflows): author the in-scope part completely and validator-clean, and report the rest by product-doc
section/workflow id/needed-family, in the same response. Do not refuse the whole request because part of it
is out of scope, and do not silently ship an incomplete package with no explanation of what's missing.

⚠️ **The CardSurfaces vocabulary trap** — found 2026-08-09 while authoring against a real product doc.
Product docs' own "### B25 Card Surface Registry Mapping" tables name surfaces like `payment`, `documents`,
`calendar`, `workflow-status`, `notification-inbox`, `portability`, `search`, `roster`, and link to
`docs/CardSurfaces/*.md` (**deleted 2026-08-14**; the surviving copy is under `docs/Build Plan V2/`)
— **none of those names are real `cardSurfaceFamily` values**, and that whole
`docs/CardSurfaces/` folder is explicitly superseded (`archetypes/README.md`: "every file invents a
nonexistent `CommunityXxxApi`. Nothing from it is promoted here"). Never copy a product doc's registry-table
name directly into `cardSurfaceFamily`. Always translate through `archetypes/README.md`'s real enum:
`payment`→`paymentCheckout`, `calendar`→`event-rsvp`, `workflow-status`→`approvalQueueItem` or
`statusTimeline`, `notification-inbox`→`notificationInbox`.

**Updated 2026-08-11, archetypes fully implemented 2026-08-12 — three of these translations changed
direction.** `documents`/`external-document-link`→`documentLibrary`, `portability`→`exportWizard`, and
(new) `search`→`searchAiAnswer`, `roster`/leaderboard-shaped browsing→`table` are the **correct**
translations — see "Authoring `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard`" above; all 4
validate cleanly now, never silently substitute `formEntry` for one of these four instead of following
that section. The platform-service caveat for `portability`/`exportWizard` and (new)
`search`/`searchAiAnswer` is unchanged: never fabricate a `checksum`/export-id/AI-answer value — see
`platform-services.md`'s ❌ Not implemented list, a hardcoded-looking value there is AP-6 regardless of
which archetype it's attached to.

This Skill deliberately never reads `using-loom-to-build-an-extension`'s
`components/card-surfaces/*` material — that sibling Skill's own Operating Rule 15 points at the same
superseded vocabulary this warning exists to avoid. This Skill only ever refers to `docs/references`.

⚠️ **The `eventDate`/`eventTime` hardcoded-field-name trap** — found 2026-08-09 in a judged
Cedar Commons HOA output. Any `event-rsvp`-bound workflow's date/time fields **must** be named literally
`eventDate` and `eventTime`, not a synonym like `startDate`/`startTime`/`date`/`time`. This is not a style
preference: `EngineNativeCalendarSurface` (`part28_engine_native_calendar_surface.dart:343,635,642`) reads
`instanceData['eventDate']`/`instanceData['eventTime']` by literal Dart string key — for the tile's day
position and its time label — not by declared `instanceDataSchema` type. A correctly-typed field named
anything else validates cleanly (the JSON-grammar validator has no way to know these two keys are special)
but silently renders no time label and sorts to midnight. **Self-check before emitting any `event-rsvp`
workflow**: grep your own draft JSON for `eventDate`/`eventTime` on that workflow type's
`instanceDataSchema` — if a date/time field exists under any other name, rename it (and every guard/effect/
formula/renderBinding reference to it) before finishing. A validator-clean pass does **not** confirm this;
it is a rendering-layer requirement the grammar checker cannot see.

⚠️ **Reconcile every product-doc capability phrase against your transition graph before finishing** —
found 2026-08-09 in the same review (a "record payment failure" transition only fired from one state, when
the product doc described retrying after a failed attempt). If the source material (a product doc, or the
request itself) uses repeat/retry/multi-attempt language — "retry", "resubmit", "try again", "reopen",
"undo", "re-request" — walk every transition that phrase implies and confirm its `from` list actually
covers every state a member could realistically be retrying from, not just the state you first wrote it
against. This is a semantic completeness check the validator cannot perform (it has no access to your
source prose, only your JSON) — treat it as your own responsibility, the same way Hard Rule 7 already
requires you to never silently drop a stated requirement. Do this check explicitly, in writing if useful
(a short list of capability phrases found → transition(s) that satisfy each), before presenting any package
as finished.

⚠️ **The `role: "actor"`/`"receiver"` per-tab resolution trap** — found 2026-08-09 auditing the merged Cedar
Commons HOA package. `role` resolution is not part of the JSON grammar; it's decided by App Shell dispatch
code, per tab, and it is sharply asymmetric — see
[`render-bindings.md`](../../../docs/references/reference/render-bindings.md)'s normative table for the full
mechanism. The two traps that actually shipped bugs: **`admin` is the only tab where `role: "receiver"` ever
resolves to anyone** — on `giving`/`home`/`messages`/`marketplace` it never resolves, and on `calendar`
neither `"actor"` nor `"receiver"` ever resolves (only `"any"` renders there); and **`"actor"` always means
the literal instance creator**, never "whoever the transition's guard is really about" — a dues charge the
board creates for a homeowner to pay resolves `"actor"` to the board, not the payer, even though the payer
is who the transition's own guard names. **Self-check before finishing**: for every `renderBinding` using
`role: "actor"` or `"receiver"` on a tab other than `admin`, confirm the persona it needs to reach really is
always the instance's creator — if not, use `role: "any"` instead (the transition's own guard still
restricts who can act; widening the binding only affects who can see the card). A validator-clean pass does
**not** confirm this either — the JSON is grammar-valid regardless of which role you pick.

## Read order

Same load order as `docs/references/README.md`, plus the pattern for whatever archetype the request needs:

1. [`docs/references/guide/01-authoring-procedure.md`](../../../docs/references/guide/01-authoring-procedure.md) — the algorithm.
2. [`docs/references/reference/workflow-grammar.md`](../../../docs/references/reference/workflow-grammar.md) — the contract, including the `visibility`/`readGuard` section.
3. [`docs/references/reference/guards.md`](../../../docs/references/reference/guards.md), [`effects.md`](../../../docs/references/reference/effects.md), [`formulas.md`](../../../docs/references/reference/formulas.md), [`field-types.md`](../../../docs/references/reference/field-types.md) — including `field-types.md`'s `type:"url"` section for any document/external-link field.
4. [`docs/references/guide/03-common-patterns.md`](../../../docs/references/guide/03-common-patterns.md) — read the pattern matching the request: P1 RSVP, P2 ballot, P3 approval queue, P4 loan/giveaway, P5 payment, P6 discussion thread. Read more than one when a community needs more than one archetype.
5. [`chatgpt-upload/17-worked-example-calendar.jsonc`](./chatgpt-upload/17-worked-example-calendar.jsonc) — the richer per-member-row + reminder pattern, needed as soon as an `event-rsvp`-shaped request includes notifications.
6. [`docs/references/reference/render-bindings.md`](../../../docs/references/reference/render-bindings.md) and [`guide/07-actions-and-fabs.md`](../../../docs/references/guide/07-actions-and-fabs.md) — where each card appears and how "create" affordances present, per tab.
7. [`docs/references/archetypes/README.md`](../../../docs/references/archetypes/README.md) — the source of truth for which `cardSurfaceFamily` fits a given workflow, and which values are real vs. not, for **every** workflow in scope, not just to confirm one.
8. [`docs/references/guide/04-antipatterns.md`](../../../docs/references/guide/04-antipatterns.md) and [`guide/05-validation.md`](../../../docs/references/guide/05-validation.md) — self-check before emitting.
9. [`docs/references/reference/theming.md`](../../../docs/references/reference/theming.md), [`platform-services.md`](../../../docs/references/reference/platform-services.md) — always check `platform-services.md`'s ❌ Not implemented table before writing any effect that looks like it produces a receipt id, checksum, payment confirmation, or search/AI answer — those must never be fabricated (AP-6).
10. [`docs/references/reference/solved-patterns.md`](../../../docs/references/reference/solved-patterns.md) — recurring requirement shapes already found and fixed in real community packages, with the verified-correct JSON shape for each. Check every workflow's requirements against this list during Step 9.5 (below) before treating a shape as novel — several of these were independently reinvented as bugs more than once before being named here.
11b. [`docs/references/archetypes/CONTRACTS.md`](../../../docs/references/archetypes/CONTRACTS.md) — what each archetype **guarantees** rather than what you declare: its actions, the per-person bookkeeping it owns (response sets, read/saved/downloaded sets, queues), and its visibility model. Then read the per-archetype doc for each family you use. **Never declare a field the archetype owns**, and never write an `actorInList` idempotence guard against one — that duplicates logic the archetype already applies.

11. [`docs/references/reference/permissions.md`](../../../docs/references/reference/permissions.md) — the `action` field and the closed action vocabulary per bespoke archetype. **Declare `action` on every transition of a bespoke-archetype workflow — the six families with a dispatcher case (`event-rsvp`, `votePoll`, `equipment-loan`, `documentLibrary`, `searchAiAnswer`, `exportWizard`) — using only that family's listed values, and never on a generic-archetype transition** — the seven generic families, `table` among them, derive their permissions structurally. `table` looks bespoke because it renders as a grid, but that is list layout only; it has no dispatcher case and takes no `action`. A workflow with `"renderBindings": []` that is named by some binding's `responseTable.workflowType` inherits that binding's archetype, so RSVP response workflows *are* bespoke; one with no bindings and no `responseTable` owner derives nothing. The doc's "Observed transitions" column is a lookup aid, not authority — where it disagrees with the transition's own `guard`/`from`/`to`/`effects`, the transition wins (`cancel-loan` is `withdraw_request` in one community and `return` in another). Mixing one bespoke family with generic bindings is normal; only two or more bespoke families is an error. Permissions themselves are always derived from what you author; never write a permission, a user, or a membership/join-approval workflow. Domain processes that accompany joining (a waiver, a registration fee, a reviewer decision) remain legitimate workflows; the membership grant itself does not.

When run inside this repo (Claude Code, Codex), read these files live from `docs/references` — they are
kept current there. Do not read the copies under `chatgpt-upload/` for anything **except**
`17-worked-example-calendar.jsonc` itself, which is authored directly in this Skill bundle (not a mirror of
a `docs/references` file) and has no live-repo equivalent to read instead.

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

**Before treating a clean (`errorCount: 0`) validator pass as "done," also run the four self-checks below —
none of these is JSON-grammar-shaped, so none will ever appear as a validator finding no matter how clean
the pass is. A validator pass alone is necessary, not sufficient:**

1. `eventDate`/`eventTime` literal field naming (Scope section warning callout).
2. Product-doc repeat/retry phrase reconciliation against transition `from` lists (Scope section warning
   callout).
3. `role: "actor"`/`"receiver"` per-tab resolution (Scope section warning callout).
4. **The Step 9.5 requirement traceability table** (`guide/01-authoring-procedure.md`) — a mandatory output
   artifact, not an internal check: every atomic requirement from the product doc's §3/§3.1/§5/§6/§7/§9
   tables, for every workflow, cited against the exact JSON construct that satisfies it, or marked
   `not_implemented` with `reasoning` grounded in a real, citable grammar/validator/platform-services
   constraint — never a guessed persona/tab restriction. This is the check that would have caught a real
   defect (Chess Club's `chess-pairing-queue` silently dropping "queue position" with a false justification)
   that neither the validator nor checks 1-3 above ever would have.

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
suite use, exposed publicly and callable as a ChatGPT Custom GPT Action.

**Running it:**

```bash
# from app/, inside WSL (dart lives there, not on the Windows side)
dart run packages/tooling/loom_ux_judges/bin/validator_server.dart --port 8787
# in a separate terminal, also inside WSL:
~/tools/cloudflared tunnel run loom-validator
```

**As of 2026-08-05 this is a named Cloudflare tunnel with a stable hostname**
(`https://loom-validator.ccselectronics.ai`), not the earlier quick-tunnel setup. It was switched after
the quick tunnel's random-URL-per-restart behavior caused a real, hard-to-diagnose outage: the tunnel (and
server) were restarted mid-session, minting a new `*.trycloudflare.com` URL, but the Custom GPT's Action
schema was never re-saved with it — every call to the old URL just went nowhere, with **no error at all**
(not a timeout message, not an explicit failure — ChatGPT reported "no visible response payload"). Ground
truth came from two places: adding unconditional request logging to `handleValidatorRequest` (so the
server's own stdout is authoritative on whether a request ever arrived, independent of what the calling
LLM self-reports) showed zero incoming requests during the failure; and directly asking ChatGPT what
`servers.url` it had configured surfaced the stale old URL. Setup for the named tunnel (one-time, needs a
Cloudflare account with a zone — `ccselectronics.ai` here):

```bash
cloudflared tunnel login                              # opens a browser auth URL, select the zone
cloudflared tunnel create loom-validator               # writes ~/.cloudflared/<tunnel-id>.json
# ~/.cloudflared/config.yml:
#   tunnel: <tunnel-id>
#   credentials-file: /home/<user>/.cloudflared/<tunnel-id>.json
#   ingress:
#     - hostname: loom-validator.ccselectronics.ai
#       service: http://localhost:8787
#     - service: http_status:404
cloudflared tunnel route dns loom-validator loom-validator.ccselectronics.ai
cloudflared tunnel run loom-validator
```

The hostname now survives server/tunnel restarts — `18-validator-action-openapi.yaml`'s `servers[0].url`
only needs updating again if the named tunnel itself is deleted/recreated or DNS is repointed. It still
depends on the local machine being on and both processes running, so a `GET /health` liveness check before
relying on it is still worth doing. Direct exposure via the router's DMZ was tried first and hit an
`ECONNREFUSED` from a genuinely external test (likely CGNAT or a DMZ target-IP mismatch — not
conclusively diagnosed) before falling back to a tunnel at all.

**Server code**: `app/packages/tooling/loom_ux_judges/lib/src/validator/validator_http_server.dart`
(library, tested by `test/validator_http_server_test.dart`) — `bin/validator_server.dart` is a thin CLI
wrapper. Routes: `GET /health`, `POST /validate` (response: the same `{status, errorCount, warningCount,
findings}` shape the CLI prints), `POST /package` (see below). Both POST routes accept two request-body
shapes: the raw package object directly, **or** `{"packageJson": "<the package, JSON-encoded as a
string>"}` — see below for why the second shape exists and is what the Action schema documents as
primary.

**Operational notes:**
- `handleValidatorRequest` logs every incoming request (method, path, host, user-agent, remote IP) to
  stdout unconditionally, before any parsing — this is the ground-truth check for "did a call actually
  arrive" when a caller's self-report can't be trusted (see the stale-URL incident above).
- `00-INSTRUCTIONS.md`'s validation section now tells the authoring agent to call
  `validateCommunityPackage` before presenting any package as finished, and to fall back to the old
  manual self-check only if the action is unavailable.

### `POST /package` / `POST /package.json` — bundles a validated JSON into the real installable artifact

Added 2026-08-05, closing the gap between "the JSON validates" and "the JSON is actually installable" (see
"Installing what comes back" below, which documents what the real app requires: two files, an extension
manifest plus the init package, both ending in `.loom-extension.zip`/`.loom-init.zip`). Both routes:

1. Run the same validator internally; refuse (`422`, `error: "package_has_errors"`, full validation
   report attached) if `errorCount > 0` — you cannot package something the validator would reject.
2. Require `extensionId`, `communityId`, and `displayName` as non-empty strings at the package's *top
   level* (not nested in `experience`) — this is a **separate** requirement from validator-cleanliness,
   since `CommunityPackageValidator` never checks these; only the real app installer
   (`LocalInAppBackend.parseLocalPackagePair`) does. Refuse with `422`/`package_build_failed` if missing.
3. On success, generate a minimal extension manifest (`{schemaVersion: 1, extensionId, displayName,
   version: "1.0.0", mode: "local-demo"}`) alongside the init package (the input, re-serialized) — both
   named `<handle>.loom-extension.zip` / `<handle>.loom-init.zip`, both **plain JSON text despite the
   `.zip` suffix**, matching the app installer's own accepted convention (see "Installing what comes
   back" — its `installLocalPackagePairFromFiles` tries a real zip first, falls back to plain JSON).

**Two response shapes, for two different callers**: `/package` returns a real zip archive
(`application/zip`, built with `package:archive`, confirmed to unzip cleanly with a standard tool) — for
direct HTTP/CLI use. `/package.json` returns the identical manifest + init-package pair **inline as JSON
objects**, no zip at all — this is the one `18-validator-action-openapi.yaml`'s `buildExtensionPackage`
operation actually points at, for a real, confirmed reason (next section).

**Added 2026-08-05: `/package.json` also returns `downloadUrl`.** The first working version left the user
manually copy-pasting two JSON code blocks into correctly-named files — functional, but real friction
compared to a download link, and the user flagged it as such the moment they saw it in practice.
`/package.json` now builds the real zip server-side (same `buildExtensionPackageZip` `/package` uses),
holds it in an in-memory, size-bounded cache (`_downloadStore`, oldest evicted past 50 entries, does not
survive a server restart — this is a local dev convenience, not durable storage), and returns
`downloadUrl` pointing at a new `GET /download/:id` route that serves those exact bytes. The scheme is
read from `X-Forwarded-Proto` (which Cloudflare Tunnel sets to `https` for the public hop) rather than
assumed, and the host from the request's own `Host` header — so the link is correct whether hit through
the tunnel or directly against `localhost:8787` in testing. This works specifically *because* it sidesteps
the Action-calling layer for the actual file transfer: the model just hands back a URL string (which it's
reliably good at), and the user's own browser does a plain `GET` — never touching the Action transport
that failed on binary responses in the first place. `00-INSTRUCTIONS.md` now has the model present
`downloadUrl` as the primary deliverable, with the two inline JSON blocks kept as a fallback.

**Implementation**: `lib/src/validator/package_builder.dart` (`buildExtensionPackagePlan` builds the
manifest + validates required fields, shared by both routes; `buildExtensionPackageZip` wraps that plan
into zip bytes for `/package`) + all three routes (`/package`, `/package.json`, `/download/:id`) in
`validator_http_server.dart`. Tests:
`validator_http_server_test.dart`'s six `/package` + `/package.json` cases (clean package → correct
content; validator errors → 422; validator-clean but missing top-level fields → 422, for each route).
Live-tested end-to-end through the tunnel against a real validated Apartment Events package for both
routes.

### Real finding: ChatGPT's Action layer failed on the binary zip response — pivoted to JSON

The first live test of `buildExtensionPackage` (pointed at `/package`, `application/zip`) came back
honest but empty: `validateCommunityPackage` succeeded normally, but two consecutive
`buildExtensionPackage` calls both failed with a **"client transport exception"** — a real, specific,
non-fabricated-sounding error (unlike the earlier `UnrecognizedKwargsError` saga below, this one didn't
cite field names that contradicted the current schema), and the model correctly reported the failure
honestly instead of inventing a fake zip — direct evidence the anti-fabrication fix
(`19-debugging-validator-responses.md`) is working. But the underlying capability gap was real: ChatGPT's
Action-calling transport appears not to handle binary/file responses reliably, even though
`/validate`'s plain-JSON responses have been consistently reliable across many calls by this point.
Rather than keep tuning binary-response headers against an untestable hypothesis, the fix was
categorical: added `/package.json`, returning the exact same manifest + init-package content as plain
JSON (`extensionManifest`/`initializationPackage` as nested objects, not a zip), and repointed the Action
schema at it. `00-INSTRUCTIONS.md` now tells the agent to present both files as two separate labeled
fenced code blocks (their exact filenames from `extensionManifestFilename`/
`initializationPackageFilename`) for the user to save locally, rather than expecting a clickable
download link. **Unconfirmed**: whether this is reliably better in practice — the theory is strong
(JSON-only has a long track record here, binary has none) but not yet proven by a live round.

### Real finding: the ChatGPT Action reliably failed to call the validator correctly — and the model fabricated plausible-looking error text instead of reporting that honestly

Across four live test rounds (2026-08-03/04) with an increasingly-hardened OpenAPI schema — a full
envelope-property breakdown, then a minimal single-property schema, then a `packageJson`-string-wrapped
schema — every attempt to have ChatGPT call `validateCommunityPackage` on a real, multi-KB Apartment
Events package either sent an empty/near-empty body (validator correctly reported
`missing_schema_version`/`missing_experience`, proving the server and network path both worked) or
produced a self-reported error, `UnrecognizedKwargsError: (<field names>)`, that is **not a shape our
Dart server can produce under any circumstance** — it has no Python-style exception vocabulary anywhere
in it, only the two documented JSON response shapes. The conclusive tell: that exact error string,
including which field names it listed, tracked the *previous* schema's field names even after the schema
was rewritten to no longer declare those fields at all — meaning the reported "error" could not have come
from the actual (changed) request. The most defensible reading is that the model fabricated a
technical-sounding failure rather than admitting it hadn't obtained (or hadn't made) a real tool call.

**This was not fixed by further schema engineering** — three different schema shapes produced this same
class of failure. What changed instead: `19-debugging-validator-responses.md` (new) tells the authoring
agent, as a hard rule, exactly what the two real response shapes are and that anything else — especially
anything resembling a stack trace or exception class name — must never be reported as a genuine result.
`00-INSTRUCTIONS.md` now points there explicitly on any non-clean-pass response. **Update: the very next
round after this fix (combined with the consent-prompt fix below) came back clean and honest** — a real
Shape A response, self-reported accurately, matching an independent re-run byte-for-byte (see Status
section at the top). One clean round doesn't prove the fabrication behavior can never recur under
different conditions, since I still can't inspect what request ChatGPT actually sent — but it's real
evidence the fix works, not just a hopeful instruction.

### Separate finding: per-call consent prompts stall the multi-call validate-and-fix loop

Once the mandatory validate-and-fix loop (above) started calling the validator repeatedly in one turn,
the user hit a different problem: ChatGPT shows an Allow/Deny confirmation before *every individual*
Action call by default (any `POST` operation is treated as "consequential" unless told otherwise), with
no visible progress between prompts. A multi-step internal loop is exactly the shape that makes this
worst — repeated silent stalls waiting on manual approval. Fix: both operations in
`18-validator-action-openapi.yaml` now declare `x-openai-isConsequential: false` (an OpenAI Actions
schema extension), since `/validate` is genuinely read-only — it never mutates anything, only returns a
report. **Confirmed live**: the round immediately after this fix had zero mention of repeated Allow
prompts, where every prior round had gotten stuck in that cycle.

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
6. **Never trust a self-reported `validateCommunityPackage` response at face value — always re-run the
   package through the real validator independently before believing its status.** Per the fabrication
   finding above, a ChatGPT session has reported specific, technical-sounding "errors" for a validator
   call that never actually happened correctly. A self-reported response is a claim to verify, not a
   result to relay.

## Installing what comes back — the generated JSON is not just structurally valid, it installs and renders

A validator pass proves grammar correctness, not that the real app will load and render the package —
`docs/references/README.md`'s own "PROVISIONAL — never loaded by a running app" warning would suggest
caution here. **That warning is stale** (confirmed 2026-08-04 via direct code research, not just re-reading
docs): commits through 2026-08-04 finished a generic, community-agnostic install → render pipeline, and
Tabletop Club's own `extensionId` is deliberately absent from the App Shell's hardcoded demo catalog
specifically to prove this — see
`.agents/skills/using-loom-to-build-an-extension/examples/verify-tabletop-club/README.md`. Concretely:

- `experienceForExtensionId` (`part15_evidence_catalog.dart`) parses ANY package's `experience` block
  generically when `experienceSchemaVersion == 2` — `workflowDefinitions`, `workflowInstances`, and
  `personas` all go through the shared engine-grammar model (`LoomWorkflowStateMachine.fromJson` et al.),
  not anything Tabletop-specific.
- The Demo App's "Add Community" flow (`LocalPackageLoaderDialog` → `LocalInAppBackend.
  installLocalPackagePairFromFiles`) installs any package with a matching `extensionId` across an
  extension manifest and an init package — no allow-list.
- A Calendar tab appears automatically whenever any `workflowDefinitions` entry declares a
  `renderBindings` entry with `tabId: "calendar"` (`_hasEngineNativeCalendarBinding`,
  `part12_persona_and_tabs.dart`), and renders through the same generic
  `EngineNativeCalendarSurface` → `EngineNativeBindingDispatcher` → `EngineNativeArchetypeCard` pipeline
  Tabletop Club uses — `calendar`, `giving`, and `home` are all wired generically as of this date.

**To actually install a package produced by this Skill**: the JSON this Skill produces is the
*initialization* package. You also need a small extension-manifest JSON (`{schemaVersion, extensionId,
displayName, version}`, matching `extensionId`) — see
`.agents/skills/using-loom-to-build-an-extension/examples/verify-tabletop-club/loom.extension.json` for
the shape. Save both files ending in `.loom-init.zip` / `.loom-extension.zip` (plain JSON text is fine,
they don't need to be real zip archives — `installLocalPackagePairFromFiles` falls back to parsing plain
JSON when the bytes aren't a real zip), get them onto the running app's filesystem, then use the Demo
App's "Add Community" FAB and paste both paths in. One real gap: no individual named accounts get seeded
for a new community (that's hardcoded only for Tabletop Club's `ext_verify_tabletop_club`), so testing
personas means using the generic role-switcher, not "sign in as a specific person."

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
