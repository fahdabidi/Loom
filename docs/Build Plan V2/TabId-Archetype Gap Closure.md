# TabId-Archetype Gap Closure

status: active
created: 2026-08-11
owner: this session (Validation Agent), Implementation Agent = Codex CLI via `data/call_implementation_agent.sh`

## 0. What this tracker is

A direct continuation of the tabId-open/archetype-closed migration (`TabId-Archetype.0` through `.4`, all
shipped — Part 0 `0eaee648`, Ticket 1 `512a2bd5`, Ticket 2 `fc82ecf4`, Ticket 3+5 `9d474848`, Ticket 4
`c3679af4`). While auditing the 7 non-Tabletop real communities for functionality dropped or collapsed
during their earlier migration to the closed 9-value archetype registry, 4 more archetypes were found to be
real, needed, and missing: `table`, `documentLibrary`, `searchAiAnswer`, `exportWizard`. Locked into the
canonical vocabulary 2026-08-11 — see `docs/references/archetypes/README.md`'s "Promoted archetypes —
pending implementation" section for the full evidence and status table. This tracker covers the two
remaining milestones that section points at.

**Governing rule, restated because it was violated once already this session and corrected by the user:**
community JSON (`docs/references/communities/*.jsonc`) is authored **only** by dispatching the
`loom-calendar-experience-authoring` Skill (`.agents/skills/loom-calendar-experience-authoring/SKILL.md`)
against the community's product doc — never hand-authored directly by the Validation Agent, regardless of
how small or mechanical the change looks. That Skill was updated 2026-08-11 (same pass as this tracker) so
it can now correctly author content using the 4 pending archetypes, with the right `NEEDS IMPLEMENTATION`
comment conventions for their platform-service gaps. Milestone 1 below is Dart-only and has no such
restriction — the Validation Agent (or a dispatched Implementation Agent) authors that directly, matching
every other ticket this session (`TabId-Archetype.0`-`.4`).

---

## Milestone 1 — implementation (registry + dispatch + widgets)

**Not started.** Scope: make the 4 promoted archetypes real, matching the bar already set by `event-rsvp`/
`equipment-loan`/`votePoll` (a genuinely distinct widget, not a fallback to `GenericWorkflowInstanceCard`)
where the audit found a real interaction gap, or explicitly matching the existing 🟡 GENERIC bar (functional
via the shared template, cosmetically generic) where a full bespoke widget isn't warranted — that call is
made per-archetype below, not assumed uniform.

### 1a. Registry addition

Add `table`, `documentLibrary`, `searchAiAnswer`, `exportWizard` to `knownWorkflowArchetypes`/
`knownWorkflowArchetypeIds` in
`app/packages/core/loom_workflow_engine/lib/src/models/workflow_archetypes.dart` (the same registry
`TabId-Archetype.1` built). Registry grows from 9 → 13. This alone does **not** make community JSON using
these values render correctly — it only stops the validator rejecting them (`unknown_card_surface_family`).
Dispatch wiring (1b) and widgets (1c) are separate, required steps.

### 1b. Dispatch wiring

`EngineNativeArchetypeCard.build()` (`part27_engine_native_binding_dispatcher.dart:322-436`) is the single
switch point (`archetypes/README.md`'s "The dispatch mechanism" section). Add a case for each of the 4
routing to its real widget (1c) — or, for any of the 4 where 1c's scope decision is "🟡 GENERIC is
sufficient," deliberately leave it unrouted (falls to `default → GenericWorkflowInstanceCard`, same as the
6 existing 🟡 GENERIC archetypes) and say so explicitly in the STATUS response, matching this doc's own
honesty convention — do not silently skip a case without recording the decision.

### 1c. Widgets — one real design decision per archetype, not a uniform treatment

- **`table`** — real interaction gap (browsing 20+ rows at scale is not what a card-per-item list is for).
  Build a genuine sortable/filterable grid widget consuming the existing `sortable`/`searchable`/
  `labelTemplate`/`displayIcon` `instanceDataSchema` flags every other archetype already reads — no new
  JSON grammar needed, this is pure Dart. ✅ REAL is the right bar here, not 🟡 GENERIC.
- **`documentLibrary`** — real interaction gap (category grouping + acknowledgement/access-request state +
  version history is materially different from one field in a generic card). Two real prerequisites, not
  one: (i) the widget itself, and (ii) `field-types.md`'s `type: "url"` field is still `⚠️ PROPOSED, not yet
  implemented` at the field-renderer level (`openMode: "external"/"embedded"/"choice"` currently does
  nothing) — this needs building regardless of `documentLibrary`'s own widget, since every real
  document-shaped fixture already declares `type: "url"` fields expecting it to work. Do this as part of
  the same ticket, not a separate one — a `documentLibrary` widget that can't actually open its own
  documents isn't done.
- **`searchAiAnswer`** — the widget (query display + `citations[]` list rendering, consuming the already-
  `⚠️ PROPOSED` "Citation lists" shape) is buildable and should be ✅ REAL for that part. The **answer
  computation itself is out of scope for this milestone** — `platform-services.md` lists "External search /
  AI answer" as `❌ Not implemented`, and that does not change here. The widget must render correctly
  against an empty/unset answer field (real community JSON will have `answerBody`-equivalent fields marked
  `NEEDS IMPLEMENTATION` and never written) — do not build a fake/stub answer generator to make the widget
  look more finished than the platform actually is.
- **`exportWizard`** — same split as `searchAiAnswer`. The stepped-flow widget (progress indicator across
  the state machine's real states) is buildable now — every real fixture already models this correctly as
  an ordinary state machine, confirmed during the audit. Checksum/integrity-hash and opaque-ID generation
  remain `❌ Not implemented` platform services and are explicitly **not** part of this milestone — the
  widget must render correctly with those fields perpetually unset, never fabricate a value to fill them in.

### Explicitly out of scope for Milestone 1

- Building the real AI/search backend behind `searchAiAnswer`, or the real checksum/ID-generation service
  behind `exportWizard`/`paymentCheckout`/anything else on `platform-services.md`'s closed list. Separate,
  larger platform-service work, tracked on that doc, not here.
- `volunteerRoster`, `singleItem`, `protectedDetail`, `guidedProcess`, `dashboard` — audited and explicitly
  not promoted (`archetypes/README.md`'s "Considered and explicitly NOT promoted" table). Do not build
  widgets for these as part of this milestone; if that verdict changes later it needs its own JSON-spec
  decision first, the same way the 4 in scope here got one.
- Any community JSON content change. That is Milestone 1.5 below, and happens through the Skill only.

### Required verification (same discipline as every prior TabId-Archetype ticket)

1. `flutter analyze` clean on `loom_workflow_engine` and `loom_communities_app_shell`.
2. Full test suites, both packages — report baseline pass count and after-count.
3. New tests: one per newly-real archetype proving the dispatch case is actually reached and renders real
   data (not the generic fallback) — matching the pattern `TabId-Archetype.3+5`'s
   "custom arbitrary tabId uses generic list dispatch" test already set for this kind of proof.
4. Validator smoke test against all 11 real fixtures under `docs/references/communities/` — **before** this
   milestone lands, several will show `unknown_card_surface_family` for `table`/`documentLibrary`/
   `searchAiAnswer`/`exportWizard` once Milestone 1.5's JSON is authored (expected). After this milestone,
   confirm those specific errors clear.
5. Live re-verification on at least one real community per newly-real archetype (once 1.5's JSON exists to
   test against) — confirm the actual widget renders, not just that analyze/tests pass.

---

## Milestone 1.5 — community JSON authoring (Skill-only)

**Unblocked ahead of Milestone 1 by explicit user decision (2026-08-12).** The default sequencing (wait for
Milestone 1's registry/dispatch/widgets, then author JSON) is deliberately not followed here: the user chose
to front-load this JSON/content work in parallel with Milestone 1's Dart work, with the known, accepted
consequence spelled out and confirmed before dispatch — every workflow declaring `table`/`documentLibrary`/
`searchAiAnswer`/`exportWizard` will show a real `unknown_card_surface_family` validator **error** (not a
warning) until Milestone 1 lands, which means the "all 11 real fixtures validate with 0 errors" state is
temporarily false for the communities touched here, and their affected workflows will not render in the app
until Milestone 1 closes the registry/dispatch/widget gap. This is expected and tracked, not a defect in any
dispatch's output — do not "fix" it by reverting a community back to a generic archetype. Dispatch the
`loom-calendar-experience-authoring` Skill (Codex CLI channel, `data/call_skill_authoring_agent.sh`) against
each affected community's product doc to author or update the real `.jsonc` fixtures using the `table`/
`documentLibrary`/`searchAiAnswer`/`exportWizard` values where the 2026-08-11 audit found them needed:

| Community | Product doc | What the audit found |
|---|---|---|
| Chess Club | `chess-club-product-experience.md` | **Done, 2026-08-12.** `chess-rankings-table`→`table`, `chess-rules-documents`→`documentLibrary`, `chess-export-package`→`exportWizard`. Took 3 dispatch rounds: round 1 invented wrong persona ids; round 2 fixed identifiers but added an unjustified `chess-export-reviewer` persona (misread of templated §7 boilerplate shared across multiple communities' product docs, not a real requirement — `solved-patterns.md` pattern 12); round 3 fixed. Independently re-validated: 7 errors, all expected `unknown_card_surface_family` across the 3 pending archetypes, 0 warnings. Independently judged **PASS** — evidence-gated ranking publish (no real change, no publish), correctly-placed `locationOverlap` guard, no fabricated platform-service values. Two informational, non-blocking notes: `chess-rules-documents` still models embedded/external/downloaded as mutually-exclusive states rather than the shipped fixture's orthogonal-timestamp approach (no functional break, full history via `openHistory`); `chess-match-meetup` now uses `event-rsvp` instead of `statusTimeline` (a working, deliberate choice, not a force-fit). Live UX walkthrough not yet run. |
| Cedar Commons HOA | `cedar-commons-hoa-product-experience.md` | Member document (→`documentLibrary`), export evidence (→`exportWizard`) |
| Neighborhood Book Club | (product doc for Book Club) | Reading material (→`documentLibrary`), AI search digest (→`searchAiAnswer`), export metadata (→`exportWizard`) |
| Riverside Youth Soccer | `riverside-youth-soccer-product-experience.md` | Waiver document (→`documentLibrary`), export metadata (→`exportWizard`), **and the dropped team-roster grid** (→`table`, a genuinely new workflow the Skill needs to author, not a rename — the legacy roster's team-wide sortable player view has no equivalent in the current `soccer-registration`/`soccer-minor-redaction` pair) |
| Masjid Nur | (product doc for Masjid Nur) | Document resource (→`documentLibrary`), search AI citation (→`searchAiAnswer`) |
| Garden Club | `garden-club-product-experience.md` | **Done, 2026-08-12.** `garden-export-custom-schemas` now uses `exportWizard`. Skill-authored via the Codex CLI channel (3rd dispatch — 2 real bugs found and fixed in the channel's own instructions along the way: a missing `appShell.tabs[]` declaration requirement, and a wrong `workflowGrammarVersion` value; both landed as `solved-patterns.md` pattern 8 and an INSTRUCTIONS.md fix, benefiting every remaining community). Independently re-validated: 2 errors, both the expected/tracked `unknown_card_surface_family` for `exportWizard`, nothing else; 8 warnings matching the pre-existing baseline. Independently judged **PASS** by a fresh Skill Output Judge dispatch — no fabricated platform-service values (checksum/transferId/receiptId genuinely never effect-written), `exportWizard` confirmed non-force-fit and doc-endorsed, and several real improvements over the previously-shipped fixture (richer tool-loan state machine, contact-privacy masking, `appShell.tabs[]` now matching product doc §3.1's per-persona tabs instead of one flattened `admin` tab). One accepted, expected behavior change: export completion is now honestly unreachable via any action until Milestone 1's platform-service work lands (correct per `platform-services.md`, not a regression — every `exportWizard` community will share this). Live UX walkthrough not yet run (deferred with the rest of Milestone 1.5's communities, per this effort's own scope). |
| Data Portability Community | `data-portability-community-product-experience.md` | Its entire domain (5 workflows: export-package, export-schema-listing, export-transfer, export-transfer-rollback, export-import-replay) — currently 100% generic `formEntry`/`statusTimeline` despite being the community whose whole purpose is export/portability |

**Do not skip the judge step.** Same process as every other Skill-authored community this session
(`Community JSON Migration Tracker.md` §1b): author → independently judge the output → fix real findings →
re-validate → only then treat it as done. The Validation Agent's job here is dispatching the Skill and
judging its output, same as always — never hand-writing the JSON to save a round trip.

**Required verification**: real validator run (`community_package_validator.dart`) against every touched
fixture, 0 errors expected once Milestone 1's registry has landed. Live re-verification of at least the
Youth Soccer roster restoration, since it's genuinely new content, not a rename.

---

## Milestone 2 — cleanup: retire the `NEEDS IMPLEMENTATION` comments

**BLOCKED — do not start without the user's explicit approval, checked at the time this milestone actually
runs, not inferred from Milestone 1/1.5 being complete.** This is a hard gate, not a formality: the user's
own words authoring this tracker were "once all implementation is completed, write a cleanup milestone to
go back and update the JSON comment as completed which requires explicit approval from me." Milestone 1 and
1.5 being verified complete is a **precondition** for asking, not a substitute for asking.

Once Milestone 1 (Dart) and Milestone 1.5 (JSON, via the Skill) are both independently verified complete,
and the user has explicitly signed off on running this cleanup:

1. For every `NEEDS IMPLEMENTATION (archetype pending)` comment added by Milestone 1.5's Skill dispatches —
   these are now resolved (the archetype is real) — remove or update them via a **new Skill dispatch**
   against the same product docs, same as any other JSON content change. Do not hand-edit these comments
   out directly, for the same reason JSON is never hand-authored anywhere else in this process.
2. For every `NEEDS IMPLEMENTATION (platform service)` comment on `searchAiAnswer`'s answer field or
   `exportWizard`'s checksum/id fields — these are **not** resolved by Milestone 1 (which explicitly
   excluded the platform-service work). Leave these exactly as they are. Confirm this distinction explicitly
   in the STATUS response for this milestone — accidentally clearing a platform-service marker because it
   looked similar to an archetype-pending one would silently reintroduce the AP-6 fabrication risk this
   comment convention exists to prevent.
3. Re-run the full validator smoke test across all touched fixtures, confirm 0 errors, 0 unexpected new
   warnings.
4. Update `archetypes/README.md`'s status table: move `table`/`documentLibrary`/`searchAiAnswer`/
   `exportWizard` from 🔲 PENDING to their real final status (✅ REAL or 🟡 GENERIC, per what Milestone 1
   actually built) with real evidence citations, matching the existing table's format for the other 9.

---

## 8. Live TODO / Next Steps Queue

| Status | Tag | Item | Source | Date |
|---|---|---|---|---|
| ⬜ Open | `new-ticket` | Author and dispatch Milestone 1's tickets (1a registry, 1b dispatch wiring, 1c the 4 widgets — likely 2-4 separate tickets given the per-archetype design-decision split) | user-identified | 2026-08-11 |
| ⬜ Open | `needs-skill-dispatch` | Milestone 1.5 (Skill-dispatched JSON authoring for the 7 affected communities) — 1 of 7 done (Garden Club). Dispatching one community at a time, Codex CLI channel, judging each before commit. Remaining: Chess Club, Cedar Commons HOA, Neighborhood Book Club, Riverside Youth Soccer, Masjid Nur, Data Portability Community. | this tracker | 2026-08-12 |
| ⬜ Open | `blocked` | Milestone 2 (retire `NEEDS IMPLEMENTATION` archetype-pending comments) — blocked on Milestones 1+1.5 AND on the user's fresh, explicit, per-instance approval at the time it actually runs | this tracker | 2026-08-11 |
