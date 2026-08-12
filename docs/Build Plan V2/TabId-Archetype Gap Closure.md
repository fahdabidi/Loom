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
| Cedar Commons HOA | `cedar-commons-hoa-product-experience.md` | **Done, 2026-08-12.** `hoa-member-document`→`documentLibrary`, `hoa-export-evidence`→`exportWizard`. Took 2 rounds: round 1 hit the same hidden-document defect as Masjid Nur (required singular `recipientPersonaId`, `solved-patterns.md` pattern 10); round 2 fixed (`membersOnly` + list-based `openedPersonaIds`/`acknowledgedPersonaIds`/`accessRequestedPersonaIds`/`savedPersonaIds`/`downloadedPersonaIds`). Independently re-validated: 4 expected `unknown_card_surface_family` errors, 1 `destructive_transition_ignores_availability_field` warning on `cancel-export` — independently judged a legitimate validator false-positive (the product doc only gates *transfer*, not cancellation, on checksum status; gating cancel too would trap a stuck/failed export with no exit) and accepted as-is. Judged **PASS**, 2 non-blocking fast-follow items noted: the access-request flow has no board-side grant/deny resolution (dead end, not a hard product-doc requirement), and the traceability table overclaims "board sees document access audit" as implemented when the 5 audit list fields have no `displayIcon`/`labelTemplate`/`displayContexts` and render nowhere. **Round 3, 2026-08-12:** found and fixed a real, separate defect — `hoa-export-evidence`'s `start-export-transfer`/`record-transfer-complete` gated on the never-writable `checksum`/`transferId` fields, making the entire transfer-completion path permanently unreachable (`solved-patterns.md` pattern 14, discovered via a different community's judge review and cross-checked against every already-committed `exportWizard` fixture). Fixed to a narrow, targeted diff (only those 2 guards + 1 comment changed, confirmed byte-identical elsewhere), independently judged **PASS**. Live UX walkthrough not yet run. |
| Neighborhood Book Club | `neighborhood-book-club-product-experience.md` | **Done, 2026-08-12.** `book-reading-material`→`documentLibrary`, `book-search-ai-digest`→`searchAiAnswer`, `book-export-metadata`→`exportWizard`. Took 3 rounds: round 1 hit two real content defects — `book-vote` could get permanently stuck at zero votes (no cancel path, dropped relative to shipped), and `book-discussion-message` reintroduced an unrequested invite/connect subsystem sourced from cross-community boilerplate (`solved-patterns.md` pattern 13 — the same root cause as pattern 12, manifesting as an unwanted feature instead of an unwanted persona); round 2 fixed both but introduced the checksum dead-end (pattern 14) on `book-export-metadata`'s entire completion path; round 3 fixed that too, judged **PASS** after an exhaustive check of all 9 transitions in that workflow (not just the one obviously-broken one). Independently re-validated: 7 expected `unknown_card_surface_family` errors, 10 warnings all matching established accepted baselines (RSVP-response coverage gaps, a legitimate `cancel-export`-not-gated false positive, and a new `no_destructive_exit_for_managed_type` on `book-vote-response` judged acceptable — it's a durable participation record, not something individually deletable; the parent `book-vote.cancel-vote` is the real cancellation point). Live UX walkthrough not yet run. |
| Riverside Youth Soccer | `riverside-youth-soccer-product-experience.md` | **Done, 2026-08-12.** `soccer-waiver-document`→`documentLibrary`, `soccer-export-metadata`→`exportWizard`, `soccer-team-roster`→`table` (a genuinely new workflow, not a rename — restores the legacy team-wide sortable roster grid the earlier archetype migration dropped). Took 2 rounds: round 1 built `soccer-team-roster` as a fully independent workflow with zero linking to `soccer-guardian-join-approval`/`soccer-minor-redaction` — approving a registration never populated the roster (coach had to hand-retype every player), and a guardian's consent actions never propagated to the roster's own redaction state; round 2 added a real `registrationCaseId` link (`createInstance` on approval, `transitionRelated` effects on every consent transition) and was independently verified end-to-end in both directions, including tracing the real engine source (`local_workflow_engine_api.dart`) to confirm `transitionRelated` preserves the real acting persona rather than bypassing guards. Independently re-validated: 7 expected `unknown_card_surface_family` errors, 6 warnings (5 baseline RSVP-response pattern, 1 `cancel-rsvp`-not-gated-on-reminderStatus judged a validator false positive after reading the actual heuristic source). No checksum-class dead end found in `soccer-export-metadata` (all 10 transitions checked by hand). FYI, out of scope for this JSON: a pre-existing bespoke native Dart renderer (`part19_youth_soccer_engine.dart`) exists for this community; which renderer actually serves users depends on the broader migration cutover. Live UX walkthrough not yet run. |
| Masjid Nur | `masjid-nur-product-experience.md` | **Done, 2026-08-12.** `mosque-document-resource`→`documentLibrary`, `mosque-search-ai-citation`→`searchAiAnswer`. The hardest of the 7 — took 4 rounds: round 1 invented wrong persona ids (`mosque-admin`/`mosque-member` vs real `masjid-admin`/`community-member`) and a forbidden `care` tab; round 2 fixed identifiers but hit the hidden-document defect (pattern 10) and a dead-end search-answer state (pattern 11); round 3 fixed both (verified end-to-end by an independent judge) but left `communityId`/`extensionId` as an inconsistent pair and over-tightened search-answer visibility; round 4 fixed both, judged **PASS**. Independently re-validated: 3 expected `unknown_card_surface_family` errors, 0 warnings. Round 4 also restructured `mosque-event-rsvp` to fold per-member RSVP into list fields directly (dropping the separate, always-unreachable `mosque-event-rsvp-response` workfow that caused warnings in round 3) — a disclosed, judge-confirmed legitimate simplification, not a hidden regression. Note for reviewers: the diff against this commit's predecessor is large (identity pair, RSVP architecture, search-answer field names) because each round is a fresh full regeneration, not an incremental patch — expected, not scope creep. Live UX walkthrough not yet run. |
| Garden Club | `garden-club-product-experience.md` | **Done, 2026-08-12.** `garden-export-custom-schemas` now uses `exportWizard`. Skill-authored via the Codex CLI channel (3rd dispatch — 2 real bugs found and fixed in the channel's own instructions along the way: a missing `appShell.tabs[]` declaration requirement, and a wrong `workflowGrammarVersion` value; both landed as `solved-patterns.md` pattern 8 and an INSTRUCTIONS.md fix, benefiting every remaining community). Independently re-validated: 2 errors, both the expected/tracked `unknown_card_surface_family` for `exportWizard`, nothing else; 8 warnings matching the pre-existing baseline. Independently judged **PASS** by a fresh Skill Output Judge dispatch — no fabricated platform-service values (checksum/transferId/receiptId genuinely never effect-written), `exportWizard` confirmed non-force-fit and doc-endorsed, and several real improvements over the previously-shipped fixture (richer tool-loan state machine, contact-privacy masking, `appShell.tabs[]` now matching product doc §3.1's per-persona tabs instead of one flattened `admin` tab). **Round 4, 2026-08-12: superseded the original note below.** Independent investigation (triggered by a different community's judge finding) determined that gating export completion on `checksumVerified` was itself a real defect, not an honest limitation — a checksum has no legitimate human-curated substitute the way a search answer does, so completion must simply never depend on it (`solved-patterns.md` pattern 14). Fixed to a narrow diff (4 guard formulas across `start-export`/`start-transfer`/`start-import`/`retry-export`, 44 lines total, confirmed byte-identical elsewhere by direct diff). Export now completes normally; `checksum`/`checksumVerified` stay honestly unset forever. Independently re-judged **PASS**. ~~One accepted, expected behavior change: export completion is now honestly unreachable via any action until Milestone 1's platform-service work lands.~~ Live UX walkthrough not yet run (deferred with the rest of Milestone 1.5's communities, per this effort's own scope). |
| Data Portability Community | `data-portability-community-product-experience.md` | **Done, 2026-08-12.** Its entire domain now uses `exportWizard` — 9 workflows (`export-import-preview`, `export-import-replay`, `export-protected-redaction`, `export-schema-listing`, `export-full-bundle`, `export-redacted-bundle`, `export-checksum-evidence`, `export-transfer-verification`, `export-transfer-rollback`), a more granular 1:1 mapping to the product doc's own §6 table than the previously-shipped 5-workflow merge — independently judged justified, not scope creep. Took 2 rounds: round 1 invented wrong envelope identifiers (`packageId`/`communityId`/`communityHandle`/`extensionId` all different from the real, externally-referenced values — a new envelope-level manifestation of pattern 9) and hit the checksum dead-end (pattern 14) on 2 transitions; round 2 fixed both, judged **PASS** — envelope IDs now match exactly, every one of 19 formula guards + 3 instanceDataEquals guards across all 9 workflows checked exhaustively for the same dead-end class, none found. `portability-receiving-provider` (the one real case where a receiving-provider persona exists) confirmed meaningfully wired: real accept/reject-transfer actions, correctly scoped out of the 6 workflows it shouldn't see. Independently re-validated: 28 expected `unknown_card_surface_family` errors (1:1 with 28 real `exportWizard` bindings), 0 warnings. Live UX walkthrough not yet run. |

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
| ⬜ Open | `needs-skill-dispatch` | Milestone 1.5 (Skill-dispatched JSON authoring for the 7 affected communities) — 3 of 7 done (Garden Club, Chess Club, Cedar Commons HOA). Dispatching one community at a time, Codex CLI channel, judging each before commit. Remaining: Neighborhood Book Club, Riverside Youth Soccer, Masjid Nur, Data Portability Community. | this tracker | 2026-08-12 |
| ⬜ Open | `new-ticket` | Cedar Commons HOA: `hoa-member-document` access-request flow has no board-side grant/deny resolution (dead end once requested); traceability overclaims "board sees document access audit" — 5 audit list fields have no display config and render nowhere. Non-blocking fast-follow, judge-identified. | m15-cedarhoa-r2 judge | 2026-08-12 |
| ⬜ Open | `blocked` | Milestone 2 (retire `NEEDS IMPLEMENTATION` archetype-pending comments) — blocked on Milestones 1+1.5 AND on the user's fresh, explicit, per-instance approval at the time it actually runs | this tracker | 2026-08-11 |
