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

**Not started. Ready to dispatch — Milestone 1.5 now provides real, committed, judge-verified ground truth
for every field this milestone's widgets need to bind to** (see "Real fixtures to design against" under
1c, and the one real, previously-unknown design question 1c now flags explicitly). Scope: make the 4
promoted archetypes real, matching the bar already set by `event-rsvp`/`equipment-loan`/`votePoll` (a
genuinely distinct widget, not a fallback to `GenericWorkflowInstanceCard`) where the audit found a real
interaction gap, or explicitly matching the existing 🟡 GENERIC bar (functional via the shared template,
cosmetically generic) where a full bespoke widget isn't warranted — that call is made per-archetype below,
not assumed uniform.

### 1a. Registry addition

**Done, 2026-08-12 (Ticket GapClosure.1a, commit `d07f1059`).** Added `table`, `documentLibrary`,
`searchAiAnswer`, `exportWizard` to `knownWorkflowArchetypes`/`knownWorkflowArchetypeIds` in
`app/packages/core/loom_workflow_engine/lib/src/models/workflow_archetypes.dart` (the same registry
`TabId-Archetype.1` built), all `ArchetypeStatus.real`. Registry grew from 9 → 13. Independently verified:
`flutter analyze` clean on `loom_workflow_engine`, full test suite 210/210 pass, and a real validator run
against each of the 7 Milestone-1.5-touched fixtures individually confirms `unknown_card_surface_family`
dropped to 0 for all 7 (was Chess Club 7, Cedar Commons HOA 4, Neighborhood Book Club 7, Masjid Nur 3,
Garden Club 2, Riverside Youth Soccer 7, Data Portability Community 28 — all now 0 total errors). The
dispatch agent's own sandbox hit the known WSL vsock error (`call_implementation_agent.sh`'s documented
issue) mid-verification after the edit and commit had already landed cleanly — independent verification
(this note) is what actually confirms the ticket, not the agent's own blocked self-report. This alone does
**not** make community JSON using these values render correctly — it only stops the validator rejecting
them. Dispatch wiring (1b) and widgets (1c) are separate, required steps, not yet started.

### 1b. Dispatch wiring

`EngineNativeArchetypeCard.build()` (`part27_engine_native_binding_dispatcher.dart:322-436`) is the single
switch point (`archetypes/README.md`'s "The dispatch mechanism" section). Add a case for each of the 4
routing to its real widget (1c) — or, for any of the 4 where 1c's scope decision is "🟡 GENERIC is
sufficient," deliberately leave it unrouted (falls to `default → GenericWorkflowInstanceCard`, same as the
6 existing 🟡 GENERIC archetypes) and say so explicitly in the STATUS response, matching this doc's own
honesty convention — do not silently skip a case without recording the decision.

### 1c. Widgets — one real design decision per archetype, not a uniform treatment

**Real fixtures to design against (added 2026-08-12, post-Milestone 1.5).** Milestone 1c was originally
written before any real community JSON existed for these 4 archetypes. Now that all 7 Milestone 1.5
communities are committed, a direct grep across every real fixture surfaces one confirmed field-naming
divergence and two areas that turned out more consistent than the original design notes assumed —
concrete enough to change how the widgets should bind to data, not just cosmetic:

- **`searchAiAnswer` — confirmed divergence, open design decision, not yet resolved.** The two real
  communities using this archetype name their answer-body field differently: Masjid Nur's
  `mosque-search-ai-citation` uses `curatedAnswerBody` (`Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc:1575`,
  `"curatedAnswerBody": { "type": "textarea?", "writableBy": "effect", ... }`); Neighborhood Book Club's
  `book-search-ai-digest` uses `answer` instead
  (`Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc:808`,
  `"answer": { "type": "textarea", "writableBy": "effect", "maxLength": 2000, ... }`). With only 2 real
  instances and a 1-for-1 disagreement, there is no majority convention to default to. This is the exact
  CJM.5 failure class (`event-rsvp`'s detail card once hardcoded literal type strings instead of reading
  each community's own declared binding, silently breaking for every non-default name) — a widget that
  hardcodes either literal field name will render one of these two communities' answers as permanently
  empty. **Whoever picks up this ticket must resolve this explicitly, one of two ways, and say which in the
  STATUS response — do not silently pick one:** (a) bind generically, reading the answer field via the
  `citations[]`/answer role already expressed through `displayContexts` or `instanceDataSchema` metadata
  rather than any single hardcoded literal, so either name (or a future third name) works without a widget
  change; or (b) declare one canonical field name as a new Hard Rule (matching `event-rsvp`'s
  `eventDate`/`eventTime` convention, Hard Rule 8) and fix the non-compliant community via a follow-up Skill
  dispatch before or alongside this ticket. (a) is recommended — it doesn't require touching already-judged
  community JSON to unblock Dart work — but this tracker is not the place to force that call silently.
  **Refinement, 2026-08-12:** `query` and `citations` themselves are consistently named across both real
  fixtures (both use exactly `query` and `citations` — confirmed, no divergence on those two), so a widget
  can safely bind those two by literal name; only the free-text "answer" concept diverges, and it's worse
  than a simple two-name split — Masjid Nur's own schema declares *three* overlapping fields for it
  (`aiAnswerBody`, `curatedAnswerBody`, and a computed `displayAnswer` formula field,
  `"formula": "if(curatedAnswerBody == null, aiAnswerBody, curatedAnswerBody)"`, all three with overlapping
  `tile`/`detail` visibility), while Book Club has a structurally different pair (`answer`, always-empty
  platform-service field; `curatedSummary`, the real human-authored substitute, pattern-11-style) with no
  unifying computed field at all. A naive "render every visible non-query/non-citations field generically"
  fallback would double-render Masjid Nur's `curatedAnswerBody` and `displayAnswer` side by side once both
  resolve non-null — so option (a) needs a real answer-selection heuristic, not just "read whatever's
  there," and that heuristic is genuinely undecided; still explicitly left to the ticket, not resolved here.
- **`documentLibrary` — Done, 2026-08-12 (Ticket GapClosure.1b1c-documentLibrary, commit `e83b4190`).** Added
  `DocumentLibraryArchetypeCard` (dispatched from `EngineNativeArchetypeCard.build()`'s per-instance switch,
  same as `event-rsvp`/`equipment-loan`/`votePoll`) plus real `openMode: "choice"` rendering in the shared
  field renderer (embedded viewer via a new `webview_flutter` dependency + external via the existing
  `url_launcher` code path, reused not duplicated). Every one of the 7 `*PersonaIds` affordances only
  renders when both its transition is available and its backing field is declared — confirmed against
  Chess Club's/Riverside Youth Soccer's narrower real schemas. One Codex dispatch round (hit the known WSL
  vsock error before its own verification could run, real edits still landed) plus 2 real fixes caught only
  during independent verification: a nullable-`int` `flutter analyze` error, and a `WorkflowActionButtonRow`
  surface-key naming inconsistency (`documentLibrary-...` camelCase vs. the established `equipment-loan-...`
  kebab-case precedent the ticket explicitly pointed at) that the ticket's own new test correctly caught.
  Independently verified: `flutter analyze` clean, full `loom_communities_app_shell` suite back to exactly
  the same 10 pre-existing baseline failures plus all new tests passing, validator 0
  `unknown_card_surface_family` for Masjid Nur and Cedar Commons HOA. Live UX walkthrough not yet run.
  Mostly consistent, bind by role not by a fixed required list. Across the 4 real
  communities (Masjid Nur, Cedar Commons HOA, Chess Club, Riverside Youth Soccer), the *names* used for each
  access-tracking role agree wherever the role is present (`readPersonaIds`, `acknowledgedPersonaIds`,
  `accessRequestedPersonaIds`, `allowedPersonaIds`, `downloadedPersonaIds`, `openedPersonaIds`,
  `savedPersonaIds` — confirmed via `grep -oE '"[a-zA-Z]*PersonaIds"'` against each fixture). What varies is
  *which* of those roles each community's document workflow actually models: Chess Club's
  `chess-rules-documents` only has `allowedPersonaIds`/`readPersonaIds`/`downloadedPersonaIds` (a simpler
  doc with no access-request or save-for-later flow), Riverside Youth Soccer's `soccer-waiver-document` is
  missing `openedPersonaIds`/`downloadedPersonaIds`/`savedPersonaIds` for the same reason. This is legitimate
  per-community scope variation, not a naming bug — the widget must treat every one of these `*PersonaIds`
  fields as optional (present-if-relevant), never assume all 7 exist on a given instance, and should still
  degrade gracefully (e.g. no "Requested access" affordance rendered) when a role's field is simply absent
  from that workflow's schema. Real interaction gap otherwise unchanged (category grouping +
  acknowledgement/access-request state + version history is materially different from one field in a
  generic card). Two real prerequisites, not one: (i) the widget itself, and (ii) a narrower gap than this
  tracker previously stated — **correction, 2026-08-12:** direct code read found `type: "url"` is *not*
  entirely unimplemented as `field-types.md` (still marked `⚠️ PROPOSED, not yet implemented` as of this
  correction) and this tracker's own prior text both claimed. `openMode: "external"` and citation-list
  (`itemSchema`) rendering are real today — confirmed live in `part18_marketplace_rendering.dart:583-611`
  (top-level `type: "url"`, `openMode == 'external'` branch) and `:612-671` (`itemSchema` list members, same
  `external` handling per-item), fed by `InstanceDataField.fromJson`'s existing `openMode`/`itemSchema`
  parsing (`workflow_models.dart:786-790`). What's still genuinely missing is `openMode: "embedded"`/
  `"choice"` — both fall through to a disabled-looking `Icons.link_off` "unsupported: <label>" pill
  (`part18_marketplace_rendering.dart:604-610`, `:660-671`), never actually opening anything. This matters
  concretely: every real fixture's *primary* document-open field (Cedar Commons HOA's, Chess Club's, and
  Riverside Youth Soccer's `documentUrl`-equivalent, Masjid Nur's `resourceUrl`, Neighborhood Book Club's
  `materialUrl`/`meetingUrl`) declares `openMode: "choice"`, each with its own `NEEDS IMPLEMENTATION`
  comment correctly flagging it as not-yet-real — confirmed via `grep -B1 '"openMode": "choice"'` across
  all 5 fixtures. So this ticket's real scope is narrower and more concrete than "build the url renderer
  from scratch": implement `openMode: "choice"` (render both "Open embedded" and "Open externally"
  controls, per `field-types.md`'s own spec) — `external` is already done, `embedded` alone is lower
  priority since no real fixture uses it standalone. Do this as part of the same ticket, not a separate one
  — a `documentLibrary` widget that can't actually open its own documents isn't done. `choice`/`embedded`
  need an embedded-viewer capability: confirmed by direct read, `loom_communities_app_shell/pubspec.yaml`
  depends on `url_launcher` (powers the already-working `external` mode) but not `webview_flutter` —
  `field-types.md`'s existing note on this point is accurate. Adding that dependency is in scope for
  `choice` (which needs both an embedded viewer and the external fallback), a real, non-trivial addition,
  not just a rendering branch.
- **`table` — Done, 2026-08-12 (Ticket GapClosure.1b1c-table, commit `b451c388`).** Added
  `WorkflowTableArchetypeCard` + `(tabId, workflowType)` grouping in `EngineNativeListSurface`, per the
  architectural finding below. Took 2 Codex dispatch rounds (both hit the known WSL vsock error before
  their own verification could run, real edits still landed each time) plus independent-verification-caught
  fixes for 2 real bugs the dispatch itself didn't catch: (1) a Column-children `if`/`else` construct where
  `else` bound to the wrong (inner) `if`, silently dropping every non-table binding on any tab using this
  surface — caught by a 12-test regression spanning unrelated features (event-rsvp, votePoll, messages,
  giving, home announcements), confirmed via a stashed-diff baseline comparison, not by `flutter analyze`;
  (2) `DataRow.key` doesn't propagate to any discoverable `Widget` (confirmed by reading Flutter SDK's own
  `data_table.dart` — it becomes a `TableRow.key`, consumed only by `Table`'s internal row-diffing), so the
  ticket's own row-key convention was unfindable via `find.byKey` regardless of naming — fixed by giving
  row identity to a `KeyedSubtree` wrapping the first cell instead. Independently verified: `flutter
  analyze` clean, full `loom_communities_app_shell` suite back to exactly the same 10 pre-existing baseline
  failures (unrelated to this ticket) plus both new table tests passing, validator 0
  `unknown_card_surface_family` for Chess Club and Riverside Youth Soccer. Live UX walkthrough not yet run.
  Real interaction gap (browsing 20+ rows at scale is not what a card-per-item list is for).
  Build a genuine sortable/filterable grid widget consuming the existing `sortable`/`searchable`/
  `labelTemplate`/`displayIcon` `instanceDataSchema` flags every other archetype already reads — no new
  JSON grammar needed, this is pure Dart. Confirmed against both real fixtures (Chess Club's
  `chess-rankings-table`, Riverside Youth Soccer's `soccer-team-roster`): both bind purely through those
  generic schema flags with no archetype-specific field names, so this archetype carries none of
  `searchAiAnswer`/`documentLibrary`'s naming-divergence risk by construction. ✅ REAL is the right bar
  here, not 🟡 GENERIC. **Real architectural finding, 2026-08-12 (changes 1b's scope for this archetype
  specifically):** a `table`-family row is *one workflow instance per row* (confirmed: each
  `chess-rankings-table`/`soccer-team-roster` instance is a single player's/row's own fields, not a single
  instance holding an array) — so the grid must aggregate across *all* instances sharing a binding, not
  render one instance as a table. That means `EngineNativeArchetypeCard.build()`'s per-instance switch
  (`part27_engine_native_binding_dispatcher.dart:309-424`, the dispatch point 1b otherwise describes for
  the other 3 archetypes) is the wrong insertion point for `table` — it only ever sees one resolved binding
  at a time. The real insertion point is one level up, where a tab's full binding list is turned into
  per-item cards: `EngineNativeListSurface.build()`'s `builder` callback
  (`part32_engine_native_list_surface.dart:105-144`), which currently does `for (final resolved in
  bindings) ... EngineNativeArchetypeCard(...)` unconditionally. Confirmed both real `table` usages route
  through this exact surface (Chess Club's `chess-rankings-table` on `tabId: "home"`/`"admin"`, Youth
  Soccer's `soccer-team-roster` on `tabId: "team"`/`"home"` — none use the calendar or marketplace surfaces,
  `part28_engine_native_calendar_surface.dart`/`part36_engine_native_marketplace_surface.dart`, so those
  need no change unless a future community binds `table` there). The fix: partition `bindings` by
  `cardSurfaceFamily == 'table'` (further grouped by `binding.tabId` + `machine.workflowType`, since two
  different table-bound workflow types on the same tab are still two separate grids) and hand each group to
  one new grid widget instead of N separate `EngineNativeArchetypeCard`s; non-`table` bindings keep today's
  per-item path unchanged. Both real fixtures also use `bindingKind: "summary"` alongside `"primary"` for
  the same `table` workflow on a second tab (Chess Club's admin-tab summary row, Youth Soccer's home-tab
  summary row) — **checked, resolved:** `bindingKind` is grep-confirmed never read anywhere in the render
  pipeline (`part27`/`part32`/`part28`/`part36`), only ever written in JSON/test fixtures — so no special
  summary-vs-primary handling is needed; each grouped binding (regardless of `bindingKind`) simply renders
  its own grid on its own tab, same as every other archetype already treats it.
- **`searchAiAnswer`** (continued) — the widget (query display + `citations[]` list rendering, consuming
  the already-`⚠️ PROPOSED` "Citation lists" shape) is buildable and should be ✅ REAL for that part. The
  **answer computation itself is out of scope for this milestone** — `platform-services.md` lists "External
  search / AI answer" as `❌ Not implemented`, and that does not change here. The widget must render
  correctly against an empty/unset answer field (real community JSON will have the answer field marked
  `NEEDS IMPLEMENTATION` and never written) — do not build a fake/stub answer generator to make the widget
  look more finished than the platform actually is.
- **`exportWizard`** — same platform-service split as `searchAiAnswer`. **Correction, 2026-08-12:** this
  tracker previously claimed the field-naming picture was "reassuringly consistent" based on a whole-file
  grep across each fixture — that grep was **not scoped to the exportWizard workflow block itself** and
  picked up matching substrings from unrelated workflows in the same file (e.g. Chess Club's `downloadUrl`
  hit came from `chess-rules-documents`, a `documentLibrary` workflow, not the export one). Direct,
  properly-scoped reads of the actual `instanceDataSchema` blocks tell a different story: Chess Club's
  `chess-export-package` uses `exportScope`/`statusMessage`/`exportHistory`; Cedar Commons HOA's
  `hoa-export-evidence` uses `scope`/`exportStatus`/`statusHistory` for the same three concepts — genuinely
  different names, not a false alarm. Only `exportLabel` and `checksum` are confirmed literally consistent
  across these two. **This does not need a field-naming decision the way `searchAiAnswer` does, though —
  there's a cleaner path:** every workflow instance already carries a fully generic, always-present
  `currentState` plus the machine's own declared `states[].label`/`.tone` (the same data every archetype's
  fact-pill renderer already reads for tone/coloring). The widget's *core* progress UI should derive from
  `currentState`/`states`, not from any named business field at all — sidesteps the naming-divergence
  question entirely, since state-machine shape is universal while field names for supplementary detail
  (status text, checksum, transfer id) are not. Real fixtures confirm this state machine is **not strictly
  linear** — Cedar Commons HOA's real path is `draft → preview → generating → ready → transferring →
  transferred`, with `failed`/`rolled-back`/`cancelled` as real side-exits, not just terminal cleanup states
  — so a naive single-track linear stepper may misrepresent a failed/rolled-back instance. Whoever picks up
  this ticket must decide and document how to represent this (a linear stepper that also shows a
  visually-distinct "off-path" state for failed/rolled-back, vs. a status-badge-plus-history-list approach
  closer to how the existing 🟡 GENERIC `statusTimeline` archetype already renders progression generically)
  — flagged as an open design call, not resolved here. Supplementary fields (checksum, transfer/receipt ids,
  status text) render via the ordinary generic schema-driven fact-pill approach, present-if-declared, same
  reasoning as `documentLibrary`'s roles above — no hardcoded literal field names needed anywhere in this
  widget. Checksum/integrity-hash and opaque-ID generation remain `❌ Not implemented` platform services and
  are explicitly **not** part of this milestone — per `solved-patterns.md` pattern 14, every real fixture
  now correctly never gates *completion* on these fields either, so the widget must render correctly with
  them perpetually unset and must never fabricate a value to fill them in.

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

0. STATUS response explicitly states how `searchAiAnswer`'s answer-field binding was resolved (generic
   role-based binding vs. a new canonical-name Hard Rule + community fix — see 1c above) and confirms the
   `documentLibrary` widget treats every `*PersonaIds` role as optional-if-present, not a fixed required set.
   Do not leave this undocumented — it is the one real open design question this milestone inherited from
   Milestone 1.5's real fixtures.
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

**All 7 communities done, 2026-08-12.** A final full validator sweep across all 11 real fixtures under
`docs/references/communities/` confirms: the 7 communities touched here each show exactly their expected
`unknown_card_surface_family` error count and nothing else (Chess Club 7, Cedar Commons HOA 4, Neighborhood
Book Club 7, Masjid Nur 3, Garden Club 2, Riverside Youth Soccer 7, Data Portability Community 28 — matching
28 real `exportWizard` bindings 1:1) — and all 4 untouched real communities (Ad-Free Community, Camera Club,
Member Social Space, Tabletop Club) remain unaffected at 0 errors. No collateral damage anywhere. This work
surfaced 6 durable Skill fixes along the way (`solved-patterns.md` patterns 9-14, all shared across every
future dispatch of every channel), two of which (10, the hidden-document defect; 14, the checksum-completion
dead end) were found to independently affect already-committed communities and were fixed there too, not
just in the dispatch that first surfaced them. See each row below for the full round-by-round history.

**Was unblocked ahead of Milestone 1 by explicit user decision (2026-08-12).** The default sequencing (wait for
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
| ⬜ Open | `new-ticket` | Milestone 1 tickets in progress: 1a (registry) ✅ done; `table` ✅ done; `documentLibrary` ✅ done (each caught 1-2 real bugs in independent verification the dispatch's own checks missed — see their own tracker entries above). Remaining: `searchAiAnswer` (carry forward the answer-field-naming open decision explicitly, do not silently pick), `exportWizard` — both authored, ready to dispatch. | user-identified | 2026-08-11 (refreshed 2026-08-12) |
| ✅ Closed | `needs-skill-dispatch` | Milestone 1.5 (Skill-dispatched JSON authoring for the 7 affected communities) — all 7 done, each independently validated + judged PASS. See per-community rows above for full round-by-round history. | this tracker | 2026-08-12 |
| ⬜ Open | `new-ticket` | Cedar Commons HOA: `hoa-member-document` access-request flow has no board-side grant/deny resolution (dead end once requested); traceability overclaims "board sees document access audit" — 5 audit list fields have no display config and render nowhere. Non-blocking fast-follow, judge-identified. | m15-cedarhoa-r2 judge | 2026-08-12 |
| ⬜ Open | `blocked` | Milestone 2 (retire `NEEDS IMPLEMENTATION` archetype-pending comments) — blocked on Milestones 1+1.5 AND on the user's fresh, explicit, per-instance approval at the time it actually runs | this tracker | 2026-08-11 |
