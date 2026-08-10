# Community JSON Migration Tracker

status: active
created: 2026-08-09
owner: this session (Validation Agent), Implementation Agent = Codex CLI via `data/call_implementation_agent.sh`

**Approval scope (clarified 2026-08-09):** authoring/updating a community's own JSON (§4's per-community
work) is standing-approved as part of this tracker and does not need a fresh sign-off per community. Only
changes to the shared *specification* — `field-types.md`, `guards.md`, `effects.md`,
`workflow-grammar.md`, or a genuinely new archetype — go back to the user for approval before landing,
same as §1/§2 already did.

## 0. What this tracker is

The generic v2 archetype pipeline (`instanceDataSchema` + `workflowDefinitions` JSON, rendered by
`GenericWorkflowInstanceCard` + the 3 real bespoke archetypes) is proven end-to-end on 3 communities
(Apartment Events, Tabletop Club, AuthZ Repro HOA — the last is a throwaway test package, not a real
product community). **The other 10 real communities are not migrated** — confirmed by direct source
inspection, not assumed:

| Tier | Communities | Current state |
|---|---|---|
| Pure legacy (no JSON at all) | Cedar Commons HOA, Member Social Space, Ad-Free Community, Data Portability Community | Hardcoded Dart, no `workflowDefinitions` |
| Hybrid (real JSON, bespoke rendering) | Garden Club, Camera Club, Neighborhood Book Club, Chess Club, Masjid Nur, Riverside Youth Soccer | Real `workflowDefinitions` embedded as Dart string literals in `part02_tab_shell.dart`, run through the real engine, but rendered by **per-community bespoke widgets** (`_GardenClubEngineTabSurface` etc.), not `renderBindings`/the generic archetype dispatcher — and only reached for the Calendar tab |
| Already engine-native | Apartment Events, Tabletop Club | Fully JSON-driven via the generic pipeline already — no migration work needed |

This tracker covers the 10 non-migrated communities. Governing rule for this whole effort, set by the user:
**author JSON → identify archetype/spec/API gaps → lock gaps in with the user → implement → verify live →
repeat per community.** Always verify against real source/widget code before proposing a new archetype;
check existing archetype capability first, every time (`docs/references/archetypes/README.md`, re-verified
2026-08-05 @ `743395e0` — 3 real bespoke archetypes: `event-rsvp`, `votePoll`, `equipment-loan`; 6 more
🟡 GENERIC via `GenericWorkflowInstanceCard`: `paymentCheckout`, `approvalQueueItem`, `formEntry`,
`discussionThread`, `statusTimeline`, `notificationInbox`; the rest are ❌ NOT REAL — do not target them).

**Process change, locked 2026-08-09 (see §1b): "author JSON" no longer means hand-authoring it directly in
this session.** It means dispatching the `loom-calendar-experience-authoring` Skill (sandboxed, spec-only)
against the community's product doc, then judging its output — both for the JSON's own quality and for
whether the Skill itself needs updating. Cedar Commons HOA's JSON was hand-authored before this change
landed; it is the first community being re-run through the new skill-based process specifically to test it.

**Standing product-doc rule (locked by the user 2026-08-09): only ever EXPAND product docs. Never remove a
documented or implemented workflow/interaction.** Where the doc and the real implementation disagree, the
doc gets expanded to cover the union, never trimmed to match the doc.

## 1. Locked spec additions (both now in `docs/references/reference/field-types.md`, doc_version 1.2.0)

Both approved by the user 2026-08-09. Both are field/display-level capabilities, deliberately **not** new
archetypes and **not** new `effects.md` ops — a link-open is a presentation action tied to one field's
value, not a state mutation, so it doesn't belong in the effects vocabulary; and because every archetype
already renders `instanceDataSchema` through the same shared fact-pill code, building this once at the
field-type level makes it available to every archetype simultaneously.

1. **`type: "url"`** — a field whose value is an openable link/document. Required `openMode`:
   `"external"` | `"embedded"` | `"choice"`. Tapping performs the platform action; never calls
   `applyTransition`, never mutates `instanceData`. New validator rules (all ⚠️ proposed):
   `missing_url_open_mode`, `invalid_url_open_mode`, `url_open_mode_on_non_url_field`.
2. **Citation lists** — `type: "list"` with an `itemSchema` whose members can themselves be `type: "url"`
   (e.g. `{ "label": {"type":"text"}, "source": {"type":"url","openMode":"external"} }`). No new field
   `type`; renders each list item as label text + a tappable link per that member's `openMode`. New
   validator rule (⚠️ proposed): `item_schema_on_non_list_field`.

**Implementation sequencing (locked):** `openMode: "external"` only needs `url_launcher` (not currently a
`loom_communities_app_shell` dependency — confirmed via `pubspec.yaml`). `embedded`/`choice` need
`webview_flutter` (also not present) — a strictly larger follow-on. Land `external` first; the field-level
JSON contract does not change based on which increment ships first.

## 1a. Findings from the single tooling smoke test (2026-08-09) — real, not hypothetical

Surfaced by actually installing Cedar Commons HOA's JSON and driving the live app on-device (§6's mandatory
gate, run once end-to-end as a dry run before the full cycle — see the mini-report for the full trace).
Recorded here because they're durable, cross-community findings, not just this one run's trivia.

1. **`hoa-owner-01` vs. `hoa-homeowner` (fixed, JSON-side):** the fixture's seed `workflowInstances` used a
   stray instance-level identifier (`hoa-owner-01`) in several `personaId`-typed fields
   (`createdByPersonaId`, `payerPersonaId`, `reservedByPersonaId`, `requesterPersonaId`) instead of the
   community's actually-declared persona id (`hoa-homeowner`). The validator caught the `createdByPersonaId`
   instances (`unknown_instance_persona`) but NOT the plain `instanceData` fields of the same shape — those
   are never checked against the declared persona list, only `createdByPersonaId` is. **Lesson for every
   remaining community's JSON:** any `personaId`-typed `instanceData` field that a guard reads must hold a
   real declared persona id, not a distinct "flavor" instance identifier — the validator will not catch this
   class of bug, only a live sign-in-and-look pass will. (This fix alone did not make the Giving tab visible
   — see #4.)
2. **Calendar tab requires a field literally named `eventDate` (NOT fixed, documented gap):** the Calendar
   surface (`part28_engine_native_calendar_surface.dart:635`) reads `instanceData['eventDate']` as a
   hardcoded literal — it does NOT consult `instanceDataSchema` for a `type: "date"` field under any other
   name, and does NOT use the `locationOverlap` creationGuard's own configurable `dateField` (which exists
   for a completely different purpose — overlap-checking at creation time, not calendar projection).
   Cedar Commons HOA's `hoa-facility-reservation` uses `reservationDate` (a more domain-accurate name) and,
   as a result, fails to render on the Calendar tab at all (`Could not show hoa-res-room-a: event date is
   missing or invalid`). This is a real, validator-invisible archetype-fit gap, confirmed by the live judge
   walkthrough exactly as intended — **every remaining community's calendar-bound workflow needs a literal
   `eventDate` field** (rename, or add a computed `formula` field aliasing the real date field) until/unless
   the calendar surface is changed to honor a configurable field name. Left as-is in this fixture
   deliberately, to prove the live-walkthrough gate surfaces real gaps rather than being fixed silently —
   pick this up as its own follow-up ticket before Cedar Commons HOA is marked complete in §4.
3. **Marketplace tab renders its real, correct empty state** ("Marketplace is coming to Cedar Commons HOA")
   for a community with no workflow bound to `tabId: "marketplace"` — confirmed as intended behavior, not a
   bug, since Cedar Commons HOA's design never targets that tab.
4. **`role: "actor"` in a render binding means "I am `createdByPersonaId`," not "a `personaId`-typed field
   on this instance names me" (NOT fixed, open design question):** confirmed by reading
   `_engineNativeActorRolesForInstance` (`part32_engine_native_list_surface.dart:145-150`, the default
   `rolesForInstance` for the generic list-based tab surface that "giving" uses) — it grants role `"actor"`
   **only** when `instance.createdByPersonaId == viewerPersonaId`, nothing else. Fixing #1's `payerPersonaId`
   was necessary but not sufficient: `hoa-dues-priya`'s `createdByPersonaId` is correctly `hoa-board` (the
   board issues the invoice), so a signed-in Homeowner is never its "actor," and the `role: "actor"` primary
   binding never resolves — the Giving tab stays empty for the exact persona meant to pay. This is a genuine
   **board-issues / member-acts** shape (also true of `hoa-architectural-request`'s decision flow in
   reverse) that the default creator-based "actor" role does not model. **Open question for the user/next
   session, not resolved here:** should such workflows declare `role: "any"` instead (visible to every
   signed-in persona — simple, but reopens the "read visibility" question §3's `no_read_visibility_declared`
   warning already flags, since nothing currently scopes an "any" binding to just the relevant payer), or
   does the binding-resolver need a real `payer`/custom role wired via an explicit `rolesForInstance`
   override (bigger, more correct, not yet attempted anywhere in this codebase for a non-creator actor)?
   Left open deliberately — this is a real architecture decision, not a JSON typo, and belongs in §2/§3 of
   this tracker's next revision before Cedar Commons HOA (or Garden Club's near-identical loan-request shape)
   can be marked complete.

## 1b. New process: skill-based JSON authoring (locked 2026-08-09)

Every community's JSON was, up to Cedar Commons HOA, hand-authored directly in this session. That worked,
but it means the *authoring capability itself* was never actually tested — I both wrote the JSON and judged
it, with full knowledge of the app's internals, the archetype registry, and every prior fix. The whole point
of `docs/references` is that it's supposed to be sufficient **on its own**, with no other context, for an
LLM to author a real community — and `.agents/skills/loom-calendar-experience-authoring/` already exists
specifically to test that claim (its own `SKILL.md`: "is `docs/references` alone... sufficient for an LLM to
author a working experience?", confirmed once already against a live external ChatGPT session with zero
repo/tool access, 2026-08-04).

**New standing process for every remaining community:** JSON authoring is dispatched to a sandboxed
subagent instructed to act as this Skill — reading only `docs/references/**` (plus the Skill's own bundle)
and the target community's product doc as "the request" — rather than authored directly by this session.
This session's role shifts from author to **reviewer/judge** of the Skill's output, matching the same
separation-of-concerns principle the whole B25 pipeline is built on ("Worker agents may implement UI and
tests, but they do not grade their own work").

**Known scope mismatch, deliberate, not an oversight:** the Skill is currently scoped *narrowly* to the
Calendar tab / `event-rsvp` `cardSurfaceFamily` only (see its own `SKILL.md` Scope section) — a much
narrower slice than most communities need (Cedar Commons HOA alone needs `paymentCheckout`,
`approvalQueueItem`, `formEntry`, and a reused `equipment-loan`, none of which are `event-rsvp`). Running
this narrow Skill against a broad community on purpose is the point: it's the fastest way to find out
exactly where the Skill's instructions need broadening before trusting it for the other 9 communities. The
Skill's own Hard Rule 7 requires it to say so explicitly rather than force-fit — its response to Cedar
Commons HOA is itself the first real data point for §1c's new judge.

**First real run, dispatched 2026-08-09:** a sandboxed `general-purpose` subagent, given only `SKILL.md`,
`00-INSTRUCTIONS.md`, and `cedar-commons-hoa-product-experience.md`, told explicitly not to read the
existing hand-authored fixture or any other session artifact, and required to run the real validator CLI
itself before calling anything final (per the Skill's own mandatory validate-and-fix loop). Its prior
hand-authored version was backed up to
`Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.HAND-AUTHORED-BACKUP.jsonc` first, so nothing is
lost regardless of outcome. Result and follow-up to be recorded here once the dispatch returns.

## 1c. New judge role: Skill Output / Skill-Update Judge

A genuinely new role, alongside the existing `LLM Vision UX Judge Agent` and
`LLM Product Docs To Evidence Reconciliation Agent` in `docs/Build Plan V2/Tools/ux-gate-judge-tools.md` —
add it there once proven, following the same Agent Split table format. Purpose: **judge the Skill's output,
and separately, judge the Skill itself** — the first without the second risks silently reworking every bad
JSON by hand instead of fixing the root cause that will just recur on the next community.

| | |
|---|---|
| Responsibility | Compare a Skill-authored community JSON against (a) the community's product doc, (b) `docs/references/archetypes/README.md`'s real-vs-not-real archetype status, (c) the shared spec docs (`field-types.md`, `guards.md`, `effects.md`, `workflow-grammar.md`), and (d) the Skill's own stated scope and Hard Rules — then decide whether the JSON is correct/high-quality **and** whether the Skill's instructions, read order, worked examples, or stated scope need to change to reliably produce this quality on the next run. |
| Context allowed | The Skill-authored JSON + its self-reported "Gaps / assumptions" section, the community's product doc, the archetype registry, the shared spec docs, the Skill's own files (`SKILL.md`, `00-INSTRUCTIONS.md`, and whichever numbered reference files are relevant to what it got wrong). Explicitly allowed — unlike the authoring dispatch itself — to read the existing hand-authored comparison fixture where one exists, since this judge's job is exactly the comparison the authoring dispatch was sandboxed away from. |
| Output | A verdict on the JSON (validator-clean is necessary but not sufficient — must also be archetype-correct, not force-fitting, not missing real product-doc requirements), plus a **separate, itemized list of concrete Skill-file edits** (e.g. "broaden Scope section to cover X", "add a worked example for `paymentCheckout`", "Hard Rule N is ambiguous about Y") when the JSON's problems trace back to the Skill's own instructions rather than one-off author error. |
| Not this judge's job | Re-running the live UX walkthrough (§6 — separate, already proven, still required) or the product-doc reconciliation gate (separate LLM role, already documented in `ux-gate-judge-tools.md`, not yet run for any community this tracker covers — see the smoke-test report's coverage audit). This judge is scoped to authoring-time JSON quality and Skill fidelity only. |

Dispatch mechanics: same as the LLM Vision UX Judge — a Claude Code subagent via the `Agent` tool, not
Codex, not the headless `claude` CLI. First real dispatch happens once §1b's authoring run returns a result
to judge.

### First real verdict (2026-08-09, judged directly by this session against the returned output)

The sandboxed authoring run (§1b) returned a genuinely strong result: a validator-clean (`0 errors, 0
warnings`) package covering the two workflows that actually fit the Skill's stated Calendar/`event-rsvp`
scope (`hoa-meeting`, `hoa-facility-reservation`, both with a proper per-member-response + reminder shape),
plus an exceptionally specific, itemized report of the other 5 product-doc workflows it correctly refused to
force-fit, why each doesn't fit `event-rsvp`, and what `cardSurfaceFamily` each would really need. Every one
of those 5 refusals is correct — none of `paymentCheckout`, `documentLibrary`, `approvalQueueItem`,
`notificationInbox`-as-broadcast, or `exportWizard` is `event-rsvp`.

**Independently spot-checked, not taken on faith** — this session re-read the actual current source of every
load-bearing claim in the agent's own 10-point self-assessment before trusting any of it. Every claim
checked came back exactly correct, several with real, previously-unknown consequences:

1. **`visibility`/`readGuard` has no normative shape documented anywhere in `docs/references`** — confirmed:
   `workflow-grammar.md` mentions `visibility` exactly once, for an unrelated `audienceMemberField` concept;
   the only place `visibility`/`readGuard`/`membersOnly`/`guarded` appear together is one table row in
   `guide/05-validation.md`'s validator-rules summary, with zero shape/enforcement definition. This is a
   canonical `docs/references` gap, not a Skill-bundle-only problem — the same warning
   (`no_read_visibility_declared`) already fires on the fixture in `docs/references/communities/`.
2. **A real, previously-unknown bug in this session's OWN hand-authored Cedar Commons HOA fixture,
   confirmed by this comparison**: `guards.md` §9 (`locationOverlap`) says, verbatim, "**Use as a
   `creationGuard`**" as its recommended placement — but `workflow-grammar.md` marks `creationGuard`
   "PROPOSED, not yet implemented," and the "not yet implemented" caveat is never repeated inline in
   `guards.md` §9 itself, right where a reader would act on it. This session's hand-authored
   `hoa-facility-reservation` followed guards.md's literal recommendation and put `locationOverlap` inside a
   `creationGuard` — which **never actually runs**, meaning the hand-authored fixture's double-booking
   protection is inert despite the JSON structurally implying it works. The Skill-authored version instead
   placed `locationOverlap` on the `reserve` **transition's** guard — the real, implemented placement — and
   is therefore *more correct on a genuine functional dimension* than this session's own hand-authored JSON.
   **This needs its own follow-up fix to the hand-authored/backup fixture, independent of anything else in
   this tracker.**
3. **`guide/05-validation.md` is stale relative to the files it summarizes, confirmed**: says "one of the
   20" formula functions (`formulas.md` itself says 23 in its heading and 22 in its own rules table — a
   second, separate internal inconsistency); says "one of the nine" effect ops (effects.md documents twelve
   per the agent's report); and says "no `!`" twice, which `formulas.md` explicitly corrects with a dated
   "Correction, 2026-07-17: unary `!` ... genuinely works" note that `05-validation.md` was never updated to
   match. Confirmed by direct read of both files.
4. **Cedar Commons HOA's own product doc actively misleads on `cardSurfaceFamily` naming, confirmed**: its
   "B25 Card Surface Registry Mapping" table names surfaces `payment`, `documents`/`external-document-link`,
   `calendar`, `workflow-status`, `notification-inbox`, `portability` — none of which are real
   `cardSurfaceFamily` enum values (`paymentCheckout`, `documentLibrary`, `event-rsvp`,
   `approvalQueueItem`/`statusTimeline`, `notificationInbox`, `exportWizard`) — and links each to
   `../../CardSurfaces/*.md`, the exact 26-file set `archetypes/README.md` already declares **superseded**
   ("every file invents a nonexistent `CommunityXxxApi`. Nothing from it is promoted here"). This is very
   likely the same trap that led this session to originally over-propose 3 new archetypes for this same
   community before being corrected earlier in this project. If the other 9 communities' product docs share
   this template (not yet checked), every one of them carries the same trap for both the Skill and any
   hand-authoring pass that trusts the product doc's own registry table literally.

**Verdict: the Skill's output is high-quality and its scope discipline is working correctly** — it did
exactly what Hard Rule 7 asks (report, don't approximate) and, per finding #2, its narrow focus on only the
in-scope grammar made it *more* correct than this session's own broader, faster hand-authoring pass. **The
Skill does not yet cover enough of a typical community to be the sole authoring path** — Cedar Commons HOA
needs 5 more workflow types this Skill is deliberately out of scope for. Recommendation, not yet applied:

**(a)/(b)/(c) applied 2026-08-09, user-approved:**
- `workflow-grammar.md` (now doc_version 1.6.0): added a full normative `visibility`/`readGuard` section —
  confirmed by direct source read (`workflow_models.dart:471-538`, `local_workflow_engine_api.dart:340-392`)
  to be genuinely, currently enforced (not advisory, not proposed) — previously undocumented anywhere
  except one bare table row in `guide/05-validation.md`.
- `guards.md` §9 (now doc_version 1.9.0): added the "do not place in `creationGuard`, it silently never
  runs" caveat directly inline next to the recommendation that caused it.
- `guide/05-validation.md` (now doc_version 1.1.0): fixed `unknown_effect_op` (nine → twelve),
  `unknown_formula_function` (20 → 23), and the stale "no `!`" claim (now correctly states unary `!` is
  supported, only `!=` is not) — all three resynced against the current `formulas.md`/`effects.md`.

**(d) a second real bug found in the hand-authored fixture, same review pass:** `hoa-export-evidence`'s
`generate-export` effect sets `"checksum": "SHA-{id}"` — a fabricated, fake-looking hash. Confirmed via
`platform-services.md`: both "Checksum / integrity hash" and "ID generation" are `❌ Not implemented`
platform services. This is a real AP-6 violation (never substitute a hardcoded value for one that should be
computed by a real service) introduced by this session's own hand-authoring, caught only by the skill-vs-
hand-authored comparison this judge pass did. Needs its own fix alongside the `locationOverlap` merge below.

**Process decision, superseding this section's original "do not broaden" recommendation (user direction,
2026-08-09):** broaden `loom-calendar-experience-authoring` itself to cover every real/working
`cardSurfaceFamily`, not just `event-rsvp` — do **not** switch to `using-loom-to-build-an-extension`
instead. Investigated directly: that sibling Skill is a much heavier, ~700-line, full B25-pipeline
apparatus (build/certify/UX-review, not just JSON authoring) whose own Operating Rule 15 points at exactly
the same superseded `components/card-surfaces/*` vocabulary that misled this session's original Cedar
Commons HOA archetype proposal and that this Skill's finding #4 flagged as a trap — adopting it would
reintroduce the exact problem this whole exercise is trying to close. `loom-calendar-experience-authoring`'s
own narrow, `docs/references`-only discipline is the asset worth keeping; only its stated *scope* needs to
widen. This is de-risked by a real discovery: `guide/03-common-patterns.md` **already has canonical
patterns P1-P6** covering RSVP, ballot (`votePoll`), approval queue (`approvalQueueItem`), loan
(`equipment-loan`), payment (`paymentCheckout`), and discussion thread (`discussionThread`) — i.e. every
real archetype except `formEntry`/`notificationInbox` (simple enough not to need a dedicated pattern) — and
`SKILL.md`'s own `chatgpt-upload/` regeneration step already copies the **entire** `03-common-patterns.md`
file into the bundle as `02-common-patterns.md`, P2-P6 included, even though nothing in the read order or
scope text currently tells the Skill to use them. Broadening is therefore mostly a scope/read-order/
Hard-Rule edit, not authoring new teaching material from scratch. See §1d for the concrete plan and
execution.

**Deferred, not dropped:** whether the CardSurfaces-registry-vocabulary trap (finding #4) exists in the
other 9 communities' product docs too — explicitly deferred by the user until Cedar Commons HOA's full,
broadened-Skill-authored package passes this judge for real. Minor Skill-bundle polish items (the
`chatgpt-upload/` self-contradiction about reading its own worked example, the missing "ship the in-scope
slice" instruction, the reminder-scheduling gap) get folded into §1d's broadening edit rather than done
separately.

## 1d. Broadening `loom-calendar-experience-authoring` — plan and execution (2026-08-09)

Goal: the Skill authors a **complete** Cedar Commons HOA package (all 7 workflows, not just the 2
calendar-shaped ones), sandboxed exactly as before, then §1c's judge decides whether the result correctly
uses the real archetypes and matches the product doc — iterate (edit Skill → re-dispatch → re-judge) until
it does, before touching any other community.

Concrete edits (this session, direct — Skill-bundle files are not spec files, no separate approval gate
per the tracker's own approval-scope rule):

1. **`SKILL.md` Scope section**: replace the "Calendar only... `event-rsvp` is the only `cardSurfaceFamily`
   this Skill's scope needs" framing with the full real set — `event-rsvp`, `votePoll`, `equipment-loan`
   (the 3 bespoke real archetypes) plus `paymentCheckout`, `approvalQueueItem`, `formEntry`,
   `discussionThread`, `statusTimeline`, `notificationInbox` (the 6 🟡 GENERIC ones) — sourced from
   `docs/references/archetypes/README.md`, cited as the live source of truth rather than copied as a frozen
   list. Explicitly out of scope, by the same source: `documentLibrary`, `exportWizard`, `audienceSelector`,
   `stateMachineGrid`/`table`, `volunteerRoster`, `searchAiAnswer`, `singleItem` (all ❌ NOT REAL) — say so
   per Hard Rule 7, never force-fit.
2. **Hard Rule 6**: update from "the only value you should need is `event-rsvp`" to "never invent a
   `cardSurfaceFamily` not listed as real in `archetypes/README.md`" — same rule, corrected scope.
3. **Read order**: add `guide/03-common-patterns.md` P2-P6 (already physically present in the
   `chatgpt-upload/` bundle as `02-common-patterns.md`, just never pointed at), keyed to which pattern
   applies to which product-doc request shape (ballot → P2, propose/decide → P3, loan/giveaway → P4,
   payment → P5, discussion → P6). Change the `archetypes/README.md` read-order entry from "confirm
   `event-rsvp` is correct" to "the source of truth for picking the right `cardSurfaceFamily` for
   **any** workflow in scope, and for which families are real vs. not."
4. **New: CardSurfaces-vocabulary warning**, sourced directly from this Skill's own first-run finding #4 —
   product docs' "B25 Card Surface Registry Mapping" tables use names (`payment`, `documents`, `calendar`,
   `workflow-status`, `notification-inbox`, `portability`) that do **not** match real `cardSurfaceFamily`
   values and link to the superseded `docs/CardSurfaces/` folder. Never copy those names directly into
   `cardSurfaceFamily` — always cross-reference `archetypes/README.md`'s real enum.
5. **New: partial-scope instruction** — "if any part of the request is in scope, author that part
   completely; report everything else by product-doc section, workflow id, and the `cardSurfaceFamily` it
   would actually need, rather than refusing the whole request or force-fitting."
6. **`00-INSTRUCTIONS.md`**: mirror edits 1-5 (it's the frozen portable copy consumed by a no-tool-access
   provider, per `SKILL.md`'s own regeneration convention) plus fix its own stale "eleven"/"one of the
   nine" phrasing to match §1c fix (c) above.
7. Regenerate `chatgpt-upload/`'s straight-copied files (`07-workflow-grammar.md`, `08-guards.md`,
   `11-field-types.md`, `04-validation.md`) from the now-updated `docs/references` sources, per `SKILL.md`'s
   own documented `cp` recipe.
8. Re-dispatch the sandboxed authoring run against Cedar Commons HOA's product doc — same sandboxing rules
   as §1b's first run (read-only, `docs/references/**` + the product doc + this Skill's own files; no
   reading the hand-authored fixture or its backup; real validator CLI required before treating anything as
   final) — this time expecting a complete 7-workflow package, not a 2-workflow slice.
9. §1c's judge (this session, directly, same verification discipline as the first pass — spot-check the
   agent's own claims against real source before trusting them) reviews the result for: validator
   cleanliness, correct archetype selection per `archetypes/README.md` (not the CardSurfaces vocabulary),
   real product-doc coverage, absence of AP-6-style fabricated values (the `checksum` bug is the concrete
   negative example to check for), and correct use of the `type:"url"` field (CJM.2 external-mode support)
   for `hoa-member-document` — declaring `openMode` freely is fine even though `embedded`/`choice` aren't
   implemented yet; that's expected, to be closed in a later implementation cycle, not an authoring defect.
10. Iterate (fix Skill → re-dispatch → re-judge) until the judge finds no blocking issues. Only then merge
    the result into the canonical `Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`, re-run
    the §6 live UX Judge walkthrough fresh, and move to the next community.

## 2. Approved shared code gaps — 3 tickets, dispatch first (they unblock every community's JSON)

All three approved by the user 2026-08-09 ("Approving all the others (1,2,4)"). Each becomes its own
`data/v3_ticket_<name>.md` at dispatch time, following the proven structure (`## Context`, `## Scope`,
`## Do not do`, `## Required verification`, `## Git safety reminder`, `## Commit`, `## Required response
format`) — see §5 for the exact dispatch mechanics.

### Ticket CJM.1 — `equipment-loan` giveaway generalization

**File:** `app/packages/core/loom_communities_app_shell/lib/src/part36_engine_native_marketplace_surface.dart:369-696`.
**Gap:** `EquipmentLoanArchetypeCard` is otherwise fully generic (fact-pills + button row driven by
`instanceDataSchema`/`availableTransitionsAsync`; queue/return already generic via action-ID lookup) —
the **only** hardcoded literal is `_isGiveaway => _instance.workflowType == 'equipment-giveaway'`, gating
"borrow" vs. "claim" button copy. **Fix:** derive `_isGiveaway` from a declared JSON property instead of a
hardcoded workflow-type string (e.g. a `cardSurfaceFamily`-adjacent flag or a convention on the
`instanceDataSchema`/workflow definition itself — Implementation Agent picks the mechanism, must not be a
second hardcoded string list). **Do not touch:** queue/return logic (already generic, do not regress).
**Unblocks:** Garden Club's `garden-tool-loan` (borrow) reuse of the same archetype without inventing a
new one.

### Ticket CJM.2 — `type: "url"` field rendering (external only)

**Files:** the shared fact-pill/field renderer (used by `GenericWorkflowInstanceCard` and every archetype —
locate via the `displayIcon`/`labelTemplate` rendering path already read this session), plus
`loom_communities_app_shell/pubspec.yaml` (add `url_launcher`). **Scope:** render `type: "url"` fields per
the locked contract in §1.1 — tappable control, `openMode: "external"` launches via `url_launcher`,
`embedded`/`choice` explicitly out of scope for this ticket (render as disabled/"not yet supported" rather
than crash, OR reject at validator level if `openMode` isn't `"external"` — Implementation Agent's choice,
state which one in STATUS). **Unblocks:** Cedar Commons HOA (`hoa-member-document`), Riverside Youth Soccer
(`soccer-waiver-document`).

### Ticket CJM.3 — citation-list rendering (`itemSchema` on `type: "list"`)

**Files:** same shared field renderer as CJM.2 (dispatch together or immediately sequential — CJM.3 extends
the exact code CJM.2 adds). **Scope:** render per the locked contract in §1.2 — each list item renders its
non-`url` members as text and its `url`-typed member as a tappable link per that member's own `openMode`.
**Depends on:** CJM.2 landing first (reuses its tap-to-open primitive). **Unblocks:** Neighborhood Book
Club (`book-search-ai-digest`), Masjid Nur (`mosque-search-ai-citation`).

## 3. Product-doc expansion tasks (locked: expand only, never remove)

Each is a real doc edit, not just a decision — the doc file itself must gain the sections below before that
community's JSON is treated as locked, since the JSON should implement the doc's full (expanded) scope.

| Community | Doc file | Expansion needed |
|---|---|---|
| Chess Club | `docs/references/communities/chess-club-product-experience.md` | Doc covers only 4 B9-era workflows (`chess-local-install-open`, `chess-route-home`, `chess-match-meetup`, `chess-match-result`). Real implementation has 8 (+ `chess-club-night`, `chess-discussion-thread`, `chess-export-package`, `chess-pairing-queue`, `chess-rankings-table`, `chess-rules-documents`). Expand doc to cover all 8. **Open question, resolve before locking JSON:** verify whether `chess-local-install-open`/`chess-route-home` are real per-community workflow instances or just the generic cross-community install/routing mechanic (if the latter, they don't need a per-community workflow entry at all — confirm by reading how they're actually exercised before deciding, do not assume). |
| Masjid Nur | `docs/references/communities/masjid-nur-product-experience.md` | Doc wants `mosque-document-resource`; implementation built `mosque-discussion-thread` instead. Build **both** — add `mosque-document-resource` (per doc) and add `mosque-discussion-thread` to the doc (per implementation). 10 total workflows, not 9. `mosque-search-ai-citation` needs the citation-list extension (§1.2 / CJM.3). |
| Neighborhood Book Club | `docs/references/communities/neighborhood-book-club-product-experience.md` | Doc wants `book-shared-library` (searchable, loan/giveaway, queue); implementation has generic `book-library-item`. Reconcile as **one** workflow, expanded to deliver the doc's full richness, under a name that preserves both (decide exact id when authoring JSON). `book-search-ai-digest` needs the citation-list extension (§1.2 / CJM.3). |
| Riverside Youth Soccer | `docs/references/communities/riverside-youth-soccer-product-experience.md` | `soccer-team-discussion` is implemented but not in the doc — add it, keep it. `soccer-waiver-document` needs `type: "url"` (§1.1 / CJM.2). |
| Garden Club | `docs/references/communities/garden-club-product-experience.md` | Doc wants a combined `garden-tool-loan-giveaway`; implementation has separate `garden-tool-loan` + undocumented `garden-volunteer-shift`. Keep both tool-loan and volunteer-shift (nothing removed); expand doc to document volunteer-shift. `garden-tool-loan`'s borrow flow depends on CJM.1's generalization fix to reuse `equipment-loan` cleanly. |
| Camera Club | `docs/references/communities/camera-club-product-experience.md` | `camera-validation-report` is implemented but not in the doc, and was independently confirmed by an earlier B25 judge finding to be pure scaffolding with zero real content. **Decision (made under the never-remove rule, not before it):** this is dropping an undocumented, contentless placeholder, not removing a real interaction — the never-remove rule protects real workflows/interactions, not empty scaffolding. Proceeding to drop it; flagged here for visibility rather than silently carried forward. |

No doc-mismatch found (so far) for Member Social Space, Ad-Free Community, Data Portability Community, or
Cedar Commons HOA — Cedar Commons HOA's JSON is already authored 1:1 against its doc. **Caveat:** Member
Social Space / Ad-Free Community / Data Portability Community have not yet had the same close doc-vs-
implementation reconciliation pass the other 6 got — do not treat "no mismatch found" as "confirmed no
mismatch" until that pass actually runs (§4 row status reflects this honestly as "needs reconciliation
pass", not "clean").

## 4. Per-community status

JSON files land at `docs/references/communities/Loom_Communities_Workflow_Engine_<Name>_Example.jsonc`,
following the Cedar Commons HOA pattern (grammar-verified inline comments explaining archetype-reuse
reasoning, kept as durable doc, not just chat explanation).

| # | Community | Doc reconciliation | JSON authoring | Known code gaps | UX Judge walkthrough |
|---|---|---|---|---|---|
| 1 | Cedar Commons HOA | Locked (7 workflows, 1:1 with doc) | **Mid-merge, see §1c** — canonical `.jsonc` is still the pre-skill hand-authored version (validator-clean, 1 bug found+fixed via live walkthrough per §1a #1, but confirmed via §1c to have a 2nd, real latent bug: `locationOverlap` on `creationGuard`, which never runs). Skill-authored calendar slice (2 of 7 workflows, `hoa-meeting`+`hoa-facility-reservation`, correctly avoids that bug) saved separately as `...SKILL-AUTHORED-CALENDAR-SLICE.jsonc`, not yet merged in. | CJM.2 (done, see §1a); §1a #2 `eventDate` gap and §1a #4 `role:"actor"`-vs-payer design question still open; §1c's creationGuard bug needs its own fix | **Smoke-tested 2026-08-09** (pre-§1c merge) — real install, real sign-in, Home/Calendar/Marketplace/Giving all exercised; not a full pass. Must re-run after the §1c merge lands. |
| 2 | Garden Club | Locked per §3 (keep tool-loan + volunteer-shift) | Not started | CJM.1 (tool-loan reuse of `equipment-loan`); volunteer-shift archetype fit not yet deep-dived | Not run |
| 3 | Neighborhood Book Club | Locked per §3 (reconcile `book-library-item`/`book-shared-library`) | Not started | CJM.3 (citation list on `book-search-ai-digest`) | Not run |
| 4 | Riverside Youth Soccer | Locked per §3 (add `soccer-team-discussion` to doc) | Not started | CJM.2 (`soccer-waiver-document`) | Not run |
| 5 | Chess Club | **Blocked** — open question on `chess-local-install-open`/`chess-route-home` must resolve before doc expansion is final | Not started | None identified yet (pending doc-expansion resolution) | Not run |
| 6 | Camera Club | Locked per §3 (drop `camera-validation-report`, no doc addition needed for it) | Not started | None identified | Not run |
| 7 | Masjid Nur | Locked per §3 (build both document-resource and discussion-thread, 10 workflows) | Not started | CJM.3 (citation list on `mosque-search-ai-citation`) | Not run |
| 8 | Member Social Space | **Needs reconciliation pass** (not yet done — see §3 caveat). Ad-slot workflows (`platform-in-stream-ad`, `platform-top-banner-no-fill`, `platform-sensitive-no-fill`) confirmed to need no special gap — no live ad-decisioning backend exists anywhere in this local app, so filled/no-fill is ordinary seeded instance data, fits `formEntry`/generic pattern | Not started | None identified | Not run |
| 9 | Ad-Free Community | **Needs reconciliation pass** (not yet done) | Not started | Not yet assessed | Not run |
| 10 | Data Portability Community | **Needs reconciliation pass** (not yet done) | Not started | Not yet assessed | Not run |

## 5. Dispatch mechanics — emulate exactly, do not improvise a shortcut

This is the same canonical recipe proven this session for the AuthZ.P1-P7 ticket series (8+ tickets shipped,
independently verified). Full detail lives in `data/call_implementation_agent.sh`'s own header comment —
read it before the first dispatch of this tracker if any step below is unclear. Summarized here for the
per-community loop:

```bash
# 1. Author the ticket file (one per community-JSON-authoring pass, or per shared code gap CJM.1-3)
#    at data/v3_ticket_cjm_<slug>.md, following the proven structure:
#    ## Context / ## Scope / ## Do not do / ## Required verification / ## Git safety reminder /
#    ## Commit / ## Required response format (the _STATUS.md template).

# 2. Baseline
bash data/wsl_dispatch_tracker.sh baseline <label>

# 3. Dispatch, backgrounded (never run call_implementation_agent.sh in the foreground — it blocks
#    the session for the full dispatch duration)
setsid nohup bash data/call_implementation_agent.sh data/v3_ticket_cjm_<slug>.md --fresh \
  < /dev/null > .codex-logs/<label>_dispatch.out.log 2>&1 & disown
sleep 3   # let the dispatch's own WSL session establish before capturing

# 4. Capture the process set this dispatch spawned
bash data/wsl_dispatch_tracker.sh capture <label>

# 5. Watch via Monitor (NOT a raw tail|grep loop — see the script header for why that leaks sessions)
wsl.exe -e bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom" && bash data/watch_dispatch_log.sh <label>'

# 6. Once genuinely complete (Monitor fired on "codex exec exited with status", not just a vsock
#    alert mid-run) -- BOTH of the following together, as one paired step, BEFORE flutter
#    analyze/tests:
bash data/wsl_dispatch_tracker.sh cleanup <label>
# ...and confirm+commit the round's real edits (git status/git diff first) right alongside cleanup.

# 7. Gate check -- must print "READY FOR VALIDATION" before independent verification starts
bash data/handoff_gate.sh <label>

# 8. Independent verification (mine, never trust STATUS.md alone):
#    - flutter analyze clean on every touched package
#    - full test suite, no unexplained pass-count drop
#    - for JSON tickets: re-run the real validator (loom_ux_judges CommunityPackageValidator /
#      workflow_validator.dart) against the new fixture AND every existing shipped community,
#      confirm zero new errors
#    - for code-gap tickets touching UI: live re-verification on the emulator, not just analyze/test
```

**Session-wide WSL concurrency budget (standing user instruction): cap total concurrent `wsl.exe`
subprocesses at 4.** One dispatch + one Monitor watch = 2 already-reserved slots; route any additional
ad-hoc `wsl.exe` calls (status checks, log reads) through `data/wsl_slot.sh` rather than firing them
unbounded. For anything needing >4 parallel checks (e.g. dispatching JSON-authoring tickets for several
communities' *reconciliation passes* at once, which don't touch code and don't need the full Codex dispatch
loop), batch up to 4 parallel calls inside a single `wsl -e bash -lc "... & ... & wait"` invocation instead
of spawning multiple top-level `wsl.exe` processes — proven pattern from the Phase A judge-dispatch batches
earlier this session.

**Model:** dispatches default to GPT-5.3-Codex-Spark @ xhigh (`data/call_implementation_agent.sh`'s current
default, set 2026-08-07) unless a ticket has reason to override via `CODEX_IMPLEMENTATION_PROFILE`.

## 6. Mandatory completion gate — live LLM Vision UX Judge walkthrough

**No community is marked complete in §4 without a real walkthrough. This is not optional and not
satisfied by `flutter analyze`/unit tests alone** — those verify code correctness, not that the actual
rendered UI matches the community's product doc and is legible/actionable to a real user.

Mechanism (proven end-to-end this session on Apartment Events — 6 real findings surfaced, one bridged to a
ticket, fixed, and re-verified as passing on recapture; full detail and Agent Split table in
`docs/Build Plan V2/Tools/ux-gate-judge-tools.md`):

1. **Launch the emulator** via the hardened launcher (not ad hoc):
   ```powershell
   wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom" && bash app/packages/tooling/launch_loom_demo_emulators.sh --restart --mode both --run-app --app-target manual'
   ```
2. **Capture real screenshots** for the community's workflows/personas — either the existing automated
   catalog path (`b25_capture_workflow_screenshots.dart --mode targeted-precheck --phases <phase>` for
   communities already in `loomEvidenceTargets`) or the manual adb/uiautomator capture + hand-assigned
   `rowId`/`screenshotHash` approach (proven for Apartment Events, which isn't in the catalog).
3. **Produce `screenRows[]`** via `b25_evidence_collector.dart`, with real `rowId`/`screenshotHash`, and
   compute `appCommitSha` = `git rev-parse --short HEAD` at that exact moment.
4. **Dispatch the judge** — a Claude Code subagent via the `Agent` tool (never Codex; never the headless
   `claude` CLI for this tracker's Phase A work — that's the separate, not-yet-built Phase B automation),
   briefed with the canonical prompt contract at `ux-gate-judge-tools.md`'s Agent Split table + the exact
   numeric/boilerplate thresholds (≥16-char `visibleEvidence` on direct-question answers, ≥24-char on
   holistic, ≥80-char non-boilerplate `critique`/`why`, **100% `screenRows` coverage in `screenReviews[]`**
   — not a sample), Read-only access to the screenshots, and the fixed facts to echo back verbatim. The
   agent must classify any doc/implementation mismatch it notices as `product-spec-gap` /
   `implementation-gap` / `evidence-gap` per the contract, and must never include
   `sourceReviewRunId`/`carriedForward`/`reusedPriorReview`/`usesPriorReview`/`carriedFromPriorReview` in
   its output (the freshness gate rejects any of these being present/truthy).
5. **Run the real chain**, from `app/` under WSL:
   ```bash
   dart run packages/tooling/loom_ux_judges/bin/b25_llm_review_freshness_gate.dart --llm-review <output.json>
   dart run packages/tooling/loom_ux_judges/bin/b25_llm_ux_review_importer.dart --llm-review <output.json> --output independent-production-ux-review.json
   dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input independent-production-ux-review.json
   ```
6. **Any real finding becomes a ticket** via the Phase C bridge (`ux-gate-judge-tools.md`'s "Findings-to-
   tickets bridge" section) — hand-authored `data/v3_ticket_<name>.md`, dispatched per §5, independently
   verified, then **recaptured and re-judged** to confirm the fix actually landed in the pixels (not just
   that the code changed) before the community is marked complete.
7. **Run the LLM Product Docs To Evidence Workflow Reconciliation gate** (added to this checklist
   2026-08-09, closing a real gap the tooling-coverage audit found — this role exists and is dispatchable,
   it was simply never run in the first smoke-test pass). Full contract:
   `docs/Build Plan V2/Tools/b25-product-doc-workflow-reconciliation-llm-gate.md`. Same dispatch mechanism
   as step 4 (Agent tool, fresh context) — compares the community's product doc §6/7/8/9 and B25 semantic/
   card-surface sections against the same screenshots/evidence from steps 2-3, plus the relevant
   `components/card-surfaces/*.md` docs. Any blocker/major finding becomes a ticket exactly like step 6.

A community only moves to "complete" in §4 once: JSON authored (via §1b's skill dispatch, not hand-authored)
and validator-clean, judged by §1c's Skill Output/Update Judge, all its code gaps (if any)
dispatched/verified/committed, and both this walkthrough (steps 1-6) and the product-doc reconciliation gate
(step 7) run with either zero findings or all findings resolved and re-verified.

## 7. Execution order

1. **Prove the skill-based authoring process (§1b) on Cedar Commons HOA first**, since its JSON already
   exists as a known-good comparison point: dispatch the sandboxed Skill-authoring run → dispatch §1c's
   Skill Output/Update Judge against the result, comparing to the hand-authored backup → apply whatever
   Skill-file edits the judge recommends → only then treat the skill-based process as ready for the other 9
   communities. Do not skip straight to using the Skill on communities with no existing comparison point
   until this loop has run at least once.
2. Dispatch CJM.1, CJM.2, CJM.3 (§2) — sequentially or CJM.1 parallel with CJM.2, then CJM.3 after CJM.2
   (CJM.3 reuses CJM.2's rendering primitive). These unblock JSON authoring for HOA, Garden Club, Book
   Club, Soccer, Masjid Nur.
3. Resolve Chess Club's open question (§3) — read how `chess-local-install-open`/`chess-route-home` are
   actually exercised, confirm real-per-community vs. generic-mechanic, before expanding its doc.
4. Run the reconciliation pass (§3 caveat) for Member Social Space, Ad-Free Community, Data Portability
   Community — currently the only 3 of the 10 without a completed doc-vs-implementation check.
5. Expand the 6 mismatched product docs (§3) with real edits, not just decisions recorded here.
6. Author JSON for all 9 remaining communities via §1b's skill dispatch (not hand-authored), one at a time,
   each followed by §1c's Skill Output/Update Judge before treating that community's JSON as locked. If the
   Skill's own stated scope (Calendar/`event-rsvp` only) can't cover what a community needs, that's a real,
   expected finding, not a blocker — fall back to hand-authoring for the out-of-scope parts, exactly as
   surfaced for Cedar Commons HOA, and feed that gap back into whether/how the Skill should be broadened.
7. Per community, once JSON is locked: validate → live-install → run the §6 UX Judge gate (now including
   step 7, the product-doc reconciliation gate) → close out row in §4.
8. Only after all 10 rows in §4 read complete: remove the legacy Dart catalog paths
   (`part04_rich_spec_catalog.dart`, `part05_domain_preview.dart`, `part08_garden_and_helpers.dart`,
   `part09_action_surfaces.dart`'s legacy paths, `part14_copy_helpers.dart`'s legacy paths) and the 6
   hybrid communities' bespoke per-community widgets (`_GardenClubEngineTabSurface` etc.) — explicit
   "scrap all the legacy code" directive, deferred until nothing still depends on them.
