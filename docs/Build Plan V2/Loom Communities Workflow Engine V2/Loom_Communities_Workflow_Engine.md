# Loom Communities — General Workflow Engine

Status: Draft. **Depends on**: `Loom Communities App Shell V2/AppShell V2 Tracker.md`'s Calendar (M4)
and Marketplace (M3b) phases being fully completed and closed first — **this gate is now satisfied**
(both re-closed 2026-07-04 with live evidence after their reopenings). Phase 1 below is unblocked to
begin; no code from this engine has been written yet.

**2026-07-05: this document was split by phase.** The full design (schema, API, rendering, validator)
and Phase 1's detailed milestones/validation tests now live in
[Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md),
since Phase 1 is where all of it is first built. This doc is now the **tracker**: context, prior art,
the phase index, and the milestone-status table. Each phase's own doc holds that phase's detailed
milestones and the validation tests required to close them.

## 1. Context & motivation

The AppShell V2 work exposed a recurring problem: every time a workflow needs a new interaction
(queued listings needing "Join queue"/"Leave queue", for example), the fix is a bespoke, one-off
addition to `LoomMarketplaceListing`/`LoomListingTransition` — a new boolean flag, a new field, a
new bit of wiring in `_actionsFor`/`_applyTransition`. That model is *already* a real, declarative
state machine (`LoomListingStateMachine`, `part11_shell_models.dart:69-141`), but it's scoped only
to marketplace listings, and its vocabulary is ad-hoc booleans
(`setsHolderToActor`/`clearsHolder`/`incrementsQueue`/`decrementsQueue`/`removesFromList`) rather
than a general mechanism. Meanwhile every *other* workflow type (RSVP, payment, approval,
announcement) has **no state machine at all** — just a fixed actor/receiver/completed lifecycle
(`personaWorkflowStateFor`, `part12_persona_and_tabs.dart:54-75`) and a workflow "family" that's
*guessed* from the workflow ID string (`part13_workflow_copy_catalog.dart`'s `id.contains('payment')`
etc.), not declared.

Goal: replace the ad-hoc-flags-per-feature pattern with one general, JSON-declared workflow engine
that any workflow type can use — states, transitions, guards, and effects — and a thin local API
layer that simulates what a real backend would eventually do, so card-surface UI code never needs to
change when the engine gets a real backend later.

## 2. Prior art considered (see conversation for full comparison)

- **Amazon States Language** / **CNCF Serverless Workflow** — both are JSON DSLs, but built for
  orchestrating serverless *compute* steps (retries, parallel branches, error handling), not
  persona-driven UI state. Wrong domain fit, needlessly heavy.
- **SCXML** — mature W3C statechart standard, but XML-based, and a full implementation
  (hierarchical/parallel states, `<datamodel>`, `<invoke>`) is far more than this app needs.
- **XState** — a JS/TS state machine library. Its vocabulary (states, events/transitions, guards,
  actions, context) is the closest conceptual match to what we want, and it's the direct inspiration
  for the schema in Phase 1's doc — but it's a JS library, not something we can depend on from Dart.

**Decision: don't adopt any of these wholesale.** Evolve our own existing, already-proven,
Dart-native shape (`LoomListingStateMachine`) into a domain-agnostic engine, borrowing XState's
vocabulary (guards, actions/effects, context) rather than its runtime.

## 3. Engine design & phase docs

The full schema/API/rendering/validator design lives in
[Phase 1's doc](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md) (§2-§7), since that's
where it's first built; later phases reuse it without re-deriving it.

**Phase docs** (each phase only starts once the prior phase's milestone table below is fully green):
1. [Phase 1 — Marketplace engine prototype (Tabletop Club)](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md)
   — engine, `WorkflowEngineApi`/SQLite persistence, validator, rendering primitives, Marketplace tab.
2. [Phase 2 — Calendar (Tabletop Club) + audience/distribution primitive](./Loom_Communities_Workflow_Engine_Phase2_Calendar.md)
3. [Phase 3 — Giving (Tabletop Club) + cross-workflow dependency](./Loom_Communities_Workflow_Engine_Phase3_Giving.md)
4. [Phase 4 — Second community, full tab reimplementation: HOA (Cedar Commons)](./Loom_Communities_Workflow_Engine_Phase4_HOA.md)
5. [Phase 5 — Automated/semi-automated migration of remaining communities](./Loom_Communities_Workflow_Engine_Phase5_Migration.md)
   — not designed in detail yet; awaits Phase 4's findings.
6. [Phase 6 — Update the Skill](./Loom_Communities_Workflow_Engine_Phase6_SkillIntegration.md) — not
   designed in detail yet; awaits Phase 5.

**Reference docs** (not phase-sequenced — design/data artifacts every phase reads):
- [Loom_Communities_Workflow_Engine_Archetype_Catalog.md](./Loom_Communities_Workflow_Engine_Archetype_Catalog.md)
  — master archetype cross-reference table + per-archetype JSON field schemas.
- [Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc](./Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc)
  — the living worked example, Phase 1's own evidence-bar fixture.
- Per-community tabs/cards/actions docs:
  [HOA](./Loom_Communities_Workflow_Engine_HOA.md),
  [Mosque](./Loom_Communities_Workflow_Engine_Mosque.md),
  [BookClub](./Loom_Communities_Workflow_Engine_BookClub.md),
  [YouthSoccer](./Loom_Communities_Workflow_Engine_YouthSoccer.md),
  [GardenClub](./Loom_Communities_Workflow_Engine_GardenClub.md),
  [CameraClub](./Loom_Communities_Workflow_Engine_CameraClub.md),
  [ChessClub](./Loom_Communities_Workflow_Engine_ChessClub.md).

## 4. Phase / milestone tracker

Markers: `[ ]` not started, `[~]` in progress, `[r]` implementation
claims done / ready for verification, `[!]` verification found code issues / sent back, `[x]` closed
(code-verified AND screenshot-validated — see §5's Handoff protocol for the full sequencing). This
table is the single place to check overall progress without opening every phase doc.

| Phase | Milestone | Status |
| --- | --- | --- |
| 1 — Marketplace engine prototype | 1.1 Core state machine engine | `[x]` **CLOSED 2026-07-05** — `dart analyze` clean, 53/53 tests pass, independently re-verified |
| 1 | 1.2 `WorkflowEngineApi` + SQLite-backed `LocalWorkflowEngineApi` | `[x]` **CLOSED 2026-07-05** — dependency regression resolved (lockfile byte-identical to baseline), both rewritten tests verified, 65/65 tests pass |
| 1 | 1.3 Validator (`workflow_state_machine_validator.dart`) | `[x]` **CLOSED 2026-07-07** — re-confirmed by this session directly (not just re-stated): real fixture CLI clean, tooling 26/26, engine 65/65 |
| 1 | 1.4 Rendering primitives + first `cardSurfaceFamily` templates | `[x]` **CLOSED 2026-07-07** — re-confirmed by this session directly: `flutter analyze` clean, widget suite 4/4 genuinely re-run |
| 1 | 1.5 Replace Tabletop Marketplace tab end-to-end | `[x]` **CLOSED 2026-07-07** — independently re-verified third resubmission: `database.dart` genuinely uses drift `NativeDatabase` (no fallback maps/raw `sqlite3.open*` anywhere in the repo, confirmed via full-tree grep), direct `sqlite3`/`ffi` deps present, lockfile versions sane (drift 2.34.1/sqlite3 3.3.4/sqlparser 0.44.6, no regression). New regression test genuinely exercises real SQLite (`sqliteVersion()` + raw DDL/DML) plus a real file-backed close/reopen persistence test. Every cited command re-run fresh and matched exactly: `flutter analyze` (app_shell+b34) clean, B34 16/16, full suite 103/103, engine `dart analyze` clean + 66/66, judges `dart analyze` clean + 26/26, validator CLI pass/0/0. Live emulator screenshot walk performed on `emulator-5554` (Tabletop Club, Member persona, Root listing): Join queue → button flips to Leave queue → Leave queue → button flips back to Join queue — full round trip confirmed on-device against the real SQLite-backed engine. Evidence in `.codex-logs/m1_5-evidence/`. |
| 1 | 1.6 OpenAPI pagination cleanup | `[x]` **CLOSED 2026-07-07** — independently re-verified: `nextPageToken` genuinely 0 occurrences repo-wide in the touched specs, `SurfaceCollectionResponse` schema confirmed using `nextCursor`. Structural (not just count-matching) check via a Python parse of the full spec confirms all 33 GET operations returning `SurfaceCollectionResponse` reference both the shared `Limit` and `Cursor` params — zero missing. Marketplace `list-listings` spot-checked directly: declares `limit`/`cursor` params, returns `SurfaceCollectionResponse`. YAML parse clean (all 3 changed files), `redocly lint` re-run fresh — clean. **Phase 1 is now fully complete** (all of 1.1–1.6 closed). |
| 2 — Calendar + audience/distribution | 2.1 Audience/distribution primitive | `[x]` **CLOSED 2026-07-07** — independently re-verified: `resolveBindings`/`_matchesAudienceQuery`/dotted-key effect writes read directly and confirmed correct (not gamed), all 5 required validation tests genuinely present and passing (2 engine unit tests, 1 widget test, 1 fan-out-on-read test, 1 round-trip test). Fresh re-runs: engine `dart analyze` clean + 70/70, app_shell `flutter analyze` clean + 5/5, combined app_shell+demo suite 104/104 (103 baseline + 1 new, zero regressions). Note: implementation agent only set `[r]` in the phase doc, not here — flagged back for next time. |
| 2 | 2.2 RSVP schema design spike | `[x]` **CLOSED 2026-07-07** — independently re-verified: the written finding is a genuine architectural argument (per-persona RSVP state can't live in a single instance-wide `currentState` without either collapsing distinct members' answers or exploding into unbounded composite states), not a post-hoc rationalization. The `Loom_Communities_Workflow_Engine_Calendar_RSVP_Example.jsonc` fixture is real and consistent (12 going / 20 capacity matches the cited "12 of 20 seats filled" scenario). Validator re-run fresh: `status: pass, errorCount: 0, warningCount: 0`. |
| 2 | 2.3 `event-rsvp` template + Calendar tab replacement | `[x]` **CLOSED 2026-07-07** — independently re-verified the fix for the sent-back engine-wiring gap. Read `_CalendarTabSurfaceState` directly: it now genuinely instantiates `WorkflowDatabase`/`LocalWorkflowEngineApi`, registers a real `LoomWorkflowStateMachine` per event, creates and queries real engine-backed instances. `_applyEngineTransition` → `_applyTransition` → real `_engine.applyTransition(...)` — genuine persistence, not local widget state. `_eventRsvpTransitions` uses real `evaluateGuard(...)` per-persona evaluation. `_effectsForResponse` genuinely wires `rsvpByPersona.$actor`, `goingPersonaIds`/`waitlistedPersonaIds` effects — the M2.1 audience primitive and M2.2 `responseModel` are now actually consumed, not just declared. Fresh re-runs all matched exactly: `flutter analyze` clean, b36 8/8, engine 70/70, judges 26/26, validator pass/0/0. Combined app_shell+demo suite (beyond the implementation agent's own cited claim) — 112/112, zero regressions. Live emulator walk on `PantryVision_Manual_API_36` (fresh build+install, real on-device interaction): confirmed both required visual checks — one "Fri 10" date-strip chip for two same-date events, and distinct schema-driven icons (schedule/person/location/groups, no shared checkmark) in the expanded event detail. Noted one non-blocking observation: RSVP action buttons didn't render against a manually-reconstructed test community package on-device, most likely a gap in that ad-hoc package's fields rather than production code, since the identical interaction is proven by 8 passing automated tests. Not required by this milestone's own checklist, not blocking. **Phase 2 is now fully complete** (all of 2.1–2.3 closed). |
| 3 — Giving | 3.1 `payment` template + dues workflow migration | `[x]` **CLOSED 2026-07-07** — independently re-verified: `_GivingTabSurfaceState` genuinely instantiates `WorkflowDatabase`/`LocalWorkflowEngineApi`, registers a real dues state machine, and `_completePaymentIfNeeded` calls real `applyTransition`. Tapping the new engine's "Pay $15" button correctly reuses the existing generic action-surface via a self-referential `linkedWorkflowId`, confirmed by direct code read. Fresh re-runs all matched exactly: dues fixture validator pass/0/0, `flutter analyze` clean, b35 5/5, combined suite 112/112 (zero regressions), engine 70/70, judges 26/26. Live emulator walk on `PantryVision_Manual_API_36` (fresh build+install): confirmed the full pay round trip on-device — tapped "Pay $15", completed the generic action-surface flow, and confirmed the Giving tab updates to show a "Paid" pill and "$15 — complete" receipt, proving the real persisted state transition. |
| 3 | 3.2 Cross-workflow dependency (dues-current gate on `borrow`) | `[x]` **CLOSED 2026-07-07** — independently re-verified: `completedWorkflowIdsForPersona` genuinely queries across all workflow types for the same persona (real DB query, not a stub), threaded into real `applyTransition` enforcement (throws if gated) and into the Marketplace UI's own waiting-state computation (button renders "Waiting", not hidden). Confirmed the identifier (`tabletop-membership-dues-current`) is consistently wired end to end via `completionWorkflowId`. Read all 3 required unit tests, the widget test (including the live-update case), and the validator's genuine cross-type cycle test — all real, none gamed; one test honestly documents that the sync `availableTransitions` interface method can't do cross-workflow lookups, matching the reviewer's own code-review finding exactly. Fresh re-runs all matched: validator pass/0/0, `flutter analyze` clean, b37 2/2, combined suite 114/114 (zero regressions), engine 73/73, judges 27/27. Live emulator walk on `PantryVision_Manual_API_36` (fresh build+install): confirmed both paths on the same listing in the same session — "Waiting" before paying dues, "Request loan" (enabled) immediately after paying dues via the Giving tab. **Phase 3 is now fully complete** (all of 3.1–3.2 closed). |
| 4 — HOA (second community) | 4.1 Documents tab (`documentLibrary`) | `[x]` **CLOSED 2026-07-07** — second-pass resubmission independently verified: code-read confirmed genuine `WorkflowDatabase`/`LocalWorkflowEngineApi` wiring (not local widget state), real `applyTransition` calls for all four actions, and working `$timestamp`/`{field}` effect interpolation. Fresh gates re-run via WSL match submission exactly: engine analyze clean + 73/73; app-shell analyze clean; b38 5/5; combined app_shell+demo 119/119; tooling analyze clean + 28/28. Live emulator walk (homeowner + board personas) confirmed on-device: real state transition with timestamped audit entry (`available`→`read`), restricted-document guard gating (`Open embedded`/`Open external` disabled, only `Request access` enabled), transition to terminal `access-requested` state, and — strongest signal — both documents' state persisted unchanged across a live persona switch (Homeowner→Board), proving one shared engine-backed instance rather than per-widget local state. All three first-pass rejection findings conclusively resolved. |
| 4 | 4.2 Requests + Board (`formEntry`/`statusTimeline`/`dashboard`) | `[x]` **CLOSED 2026-07-08** — independently verified: code-read confirmed genuine `WorkflowDatabase.memory()`/`LocalWorkflowEngineApi` wiring shared across homeowner/board via a static store keyed by community+workflow (not per-widget duplicated state), reviewer actions genuinely driven by `availableTransitions` (not hardcoded), and the board's decision queue is a real pointer into the shared instance list. All 8 named transitions present with correct persona guards. Fresh gates match submission: app-shell analyze clean; b39 7/7; combined app_shell+demo 126/126; tooling analyze clean + 29/29; validator pass/0/0. Live emulator walk (homeowner submits → board sees it in Decision queue → board requests changes with a real reviewer note → **switched back to homeowner and confirmed the identical state/reviewer note appeared**, with correct homeowner-only actions) conclusively proves bidirectional shared-engine sync, ruling out the M2.3/M4.1 cosmetic-bypass anti-pattern. No `loom_workflow_engine` schema changes were needed for this milestone — relevant input for M4.4. |
| 4 | 4.3 Payments tab (reuse Phase 3's `payment` family) | `[x]` **CLOSED 2026-07-08** — independently verified: `git log`/`git diff --stat` confirmed `part18_marketplace_rendering.dart` (shared payment template) has zero modifications, mtime predates this milestone. HOA Payments tab dispatches through the exact same pre-existing generic `PaymentGivingTabSurface`/`_GivingTabSurface` path Tabletop Club uses, no HOA-specific duplicate renderer. Fresh gates match submission: app-shell analyze clean; b40 2/2; combined app_shell+demo 128/128; tooling analyze clean + 30/30; validator pass/0/0. Live emulator walk: homeowner paid $450 through the real (pre-existing, shared) checkout confirmation flow, resulting in a genuine timestamped `Payment completed at 2026-07-08T05:14:33.027938Z` receipt entry — proving the transaction path is real, not cosmetic. Board persona correctly saw the same dues card with pay actions replaced by a read-only-ledger message, matching the milestone's own requirement (HOA.md's Payments section has no board cross-sync requirement, unlike M4.2's Requests feature). Non-blocking finding carried to M4.4: the board's view did not reflect the homeowner's already-completed payment, because the underlying `_completedWorkflowIds` tracking (inherited unchanged from Phase 3, outside this milestone's zero-change mandate) is local widget state, not engine-persisted — unlike M4.1/M4.2's genuinely shared, cross-persona-synced state. |
| 4 | 4.4 Generality finding | `[x]` **CLOSED 2026-07-08** — independently verified: finding is accurate against this session's own evidence, not just internally consistent. The `$timestamp`/`{field}` interpolation claim (M4.1) matches the actual `effect_evaluator.dart` diff; the "no schema change" claims for M4.2/M4.3 match direct code-read and `git diff` confirmation; the payment cross-persona architecture observation matches what was independently found live during M4.3's walk, before this finding was written. All three required validation bullets satisfied, nothing hedged or omitted, follow-up correctly filed for the one real change (document `$timestamp`/`{field}` in the Phase 1 effect-op reference before Phase 5). **Phase 4 is now fully complete** (all of 4.1–4.4 closed). |
| 5 — Migration of remaining communities | 5.1 Garden Club tab reimplementation | `[x]` **CLOSED 2026-07-08** — resubmission independently verified: code-read confirmed the fixture/app disconnect from the first submission is genuinely fixed, not papered over — `_GardenFixtureBundle.load()` genuinely `jsonDecode`s the bundled fixture string and builds real `LoomWorkflowStateMachine.fromJson`/`_GardenSeedInstance.fromJson` definitions registered into `LocalWorkflowEngineApi`, not hardcoded Dart objects. Fresh gates match submission exactly: app-shell analyze clean; combined app_shell+demo suite 124/124 + 5/5; tooling analyze clean + 31/31; Garden fixture validator pass/0/0. Live emulator walk on `PantryVision_Manual_API_36` conclusively confirmed all four originally rejected findings fixed, each with genuine timestamped on-device state changes: Home's 3 domain-native pins, Calendar's `join-waitlist`, Exchange's full plant-edit-and-persist lifecycle (renamed a listing and confirmed the save stuck), Documents' full export review-and-confirm shape plus `generate-export`, and Care's `sign-up`/`cancel-signup` round trip (reached via the scrollable bottom tab bar) with a real audit timestamp. Non-blocking process note: this resubmission again did not preserve the original Findings 1-4 rejection text in the phase doc — flagged there for future resubmissions, not re-litigated since the fix itself is correct. |
| 5 | 5.2 Camera Club tab reimplementation | `[x]` **CLOSED 2026-07-08** — resubmission independently verified: byte-level check confirmed the mojibake separator defect is genuinely fixed (0 double-encoded instances, real single U+00B7 codepoint), and a genuine permanent `Validator - Camera Club migration fixture` regression test was added to `milestone_1_3_test.dart` (confirmed by grep, not just the claim), raising the count to 32/32. Fresh gates match submission exactly: app-shell + tooling analyze clean; combined suite 125/125 + 5/5; validator pass/0/0. Live emulator walk on `PantryVision_Manual_API_36` exercised all six tabs with genuine timestamped state changes: Home's 3 mojibake-free pins (confirmed visually on-device), Walks' `rsvp-going`, Critique's full `formEntry`+`stateMachineGrid`+`discussionThread` composition (confirmed the "Attached critique thread" is the identical shared instance on both the Critique and Club-chat tabs), Gear's full loan lifecycle (request/join-queue/leave-queue/return) and giveaway lifecycle (offer/claim) each with real timestamps, and Admin's `mark-validated` (organizer persona, switched via role picker) with a real completion timestamp. Non-blocking process note: this resubmission again introduced 2 (down from 3) instances of the recurring lossy `?`-for-non-ASCII substitution in the phase doc — fixed directly by the verification agent, reiterated in the next mailbox message. |
| 5 | 5.3 Book Club tab reimplementation | `[x]` **CLOSED 2026-07-09** — independently verified: code-read confirmed genuine engine wiring (`_BookFixtureBundle.load()` real `jsonDecode`+`fromJson` parse, `_BookClubEngineStore` real `WorkflowDatabase.memory()`+`LocalWorkflowEngineApi`, all tabs use real `createInstance`/`queryInstances`/`availableTransitions`/`applyTransition`/`updateInstanceFields`, no local-only widget state) and the `votePoll` generality claim (fixture-declared `book-vote` machine, `_bookVotePollCard` renders genuine live totals/winner/tie, not force-fit into `list`/`table`/`stateMachineGrid`). Zero mojibake instances. Fresh gates match submission exactly: app-shell + tooling analyze clean; combined suite 126/126 + 5/5; `milestone_1_3_test.dart` 33/33 (genuine `Validator - Book Club migration fixture` case confirmed by grep); Book fixture validator pass/0/0; package-asset fixture byte-identical via `diff`. Live emulator walk on `PantryVision_Manual_API_36` exercised all eight tabs plus Home across both `book-member` and `book-organizer` personas: Books' nomination edit/withdraw cycle, vote poll cast/change/clear matching the b43 test's exact totals, organizer `close-winner`→`mark-tie` (confirming the `from: ["winner"]` gate), and Selection-announcement `mark-read` proving the same instance renders on both the member Books tab and organizer Host tab; Calendar's `rsvp-going`; Library's `request-loan`; Discussions' full `reply`→`edit-reply`→field-save (persistence confirmed across both tab switch and persona switch)→`reply`→organizer `moderate-thread` lifecycle; Materials' `open-embedded`→`open-external`→`download`; Search's `generate-answer`; Host's `preview`→`schedule`→`publish-selection` and `generate-export`, all with real timestamps. Non-blocking process note: this resubmission again introduced 2 instances of the recurring lossy `?`-for-non-ASCII substitution in the phase doc — fixed directly by the verification agent, reiterated in the M5.4 kickoff. |
| 5 | 5.4 Chess Club tab reimplementation | `[x]` **CLOSED 2026-07-09** — resubmission independently verified: code-read confirmed `_ChessClubEngineStore._rankingsEffect`/`_rankingDeltas` now genuinely reads the match-result instance's own `whitePlayer`/`blackPlayer`/`score` fields and computes deltas from the actual score string, no longer matching the hardcoded `'Maya Patel'` literal; the new `b44` regression edits the seeded result to different players and asserts on their names. Fresh gates match submission exactly: app-shell + tooling analyze clean; `milestone_1_3_test.dart` 34/34; Chess fixture validator pass/0/0; `app_shell` 5/5; `b44` 1/1; combined demo suite 127/127. Live emulator walk (fresh install after a mid-session emulator crash forced a restart) exercised every tab with real on-device state: Matches' full match-meetup lifecycle to `State: Confirmed`; Calendar showing both the confirmed match and club-night cards; Rankings' seed baseline, then — to specifically re-prove generalization beyond the widget test — a live edit of the result to **Ari Stone/Lina Ortiz** (new players) driven through `submit-result`→`correct-result`→`dispute-result`, watching Rankings update live each time with correctly accumulating deltas and a genuinely new row for the previously-unranked player; Admin's `assign-pairing`→`resolve-dispute`→`generate-export` as `chess-organizer`; Documents' `open-embedded`→`open-external`→`download`; Messages' `reply`→`archive`. One required-fix item — removing the fixture's decorative, confirmed-inert `targetWorkflowType`/`targetInstanceKey` fields — was not done; treated as a non-blocking cosmetic cleanup carried forward (dead JSON, zero functional effect, core defect fully fixed) rather than spending another mailbox round-trip on it. See phase doc for full close-out note. |
| 5 | 5.5 Youth Soccer tab reimplementation | `[x]` **CLOSED 2026-07-10** — resubmission independently verified: code-read confirmed `_YouthSoccerEngineStore._visible` (`part19_youth_soccer_engine.dart:837`) now genuinely compares `instance.instanceData['guardianPersonaId'] == personaId` — a real relationship check, not a hardcoded literal — and the guardian roster card's `.take(1)` cap was removed so all matching rows render. The fixture's new second guardian-linked child (`Ari Rivera`) and non-matching child (`Miles Chen`) prove both inclusion and exclusion, the same shape as M5.4's Ari-Stone/Lina-Ortiz regression. Fresh gates match submission exactly: app-shell + tooling analyze clean; `milestone_1_3_test.dart` 35/35; Youth fixture validator pass/0/0; `app_shell` 5/5; `b45` 1/1; combined demo suite 128/128; engine 73/73. Live emulator walk (fresh install, all three personas) exercised every tab: Registration's full 4-step guided wizard with genuine step-gating; Schedule's RSVP (persisted across a persona switch); **Team tab directly confirmed the fix live** — guardian sees exactly Sofia Rivera + Ari Rivera with Miles Chen genuinely absent, coach sees all three with Miles's pre-existing redaction rendering correctly, and tapping `redact-field` live on Sofia's row produced the identical redaction display in real time; Payments' pay/refund with a real receipt; Waivers' embedded/external/acknowledge; Messages' reply; Coach's dashboard/reminder schedule-publish; Export's full preview→generate (real checksum `sha256-rys-77a9`)→transfer→rollback→retry as owner. See phase doc for full close-out note. |
| 5 | 5.6 Mosque tab reimplementation | `[r]` **READY FOR VERIFICATION 2026-07-11** - implementation commit `e5ccc75` wires Mosque to `LocalWorkflowEngineApi` with real fixture parsing/execution, audience-selected Calendar, Giving, Care protectedDetail, Admin composer/volunteer roster, Messages, Search, and Home pins. Validation: app-shell analyze clean; tooling analyze clean; Mosque fixture validator pass clean 0 errors/0 warnings; `milestone_1_3_test.dart` 36/36; app-shell package tests 5/5; workflow engine tests 73/73; `b46_mosque_engine_migration_test.dart` 1/1; full demo suite `flutter test --concurrency=1 apps/loom_communities_demo/test` 129/129. Mailbox cleared before `[r]`; awaiting verification/live screenshot validation. |
| 6 — Update the Skill | 6.1 Validator as a required Skill gate | `[ ]` Not started |
| 6 | 6.2 Card-surface component docs updated | `[ ]` Not started |
| 6 | 6.3 SKILL.md operating rules updated | `[ ]` Not started |

## 5. Handoff protocol (implementation agent ↔ verification agent, added 2026-07-05)

Implementation happens in a separate agent session/tool/worktree with no awareness of this
conversation — so the handoff between "code written" and "verified" has to be a durable signal in the
repo itself, not a message passed between sessions that may not exist yet when the other side acts.

**Roles are strictly separated and never swap:**
- **Implementation agent**: writes code, sets a milestone row to `[r]` in both this table and that
  milestone's own checklist in its phase doc once it believes the milestone's validation tests (listed
  in that phase doc) are satisfiable — with a brief note on what changed/which files. Every kickoff
  this agent receives carries the production-quality bar clause from
  `data/verification_feedback_protocol.md` (added 2026-07-07) — no shortcuts, no local-state standing
  in for real engine wiring, no decorative fixtures the app doesn't actually execute. **Before setting
  `[r]`** (added 2026-07-09): commit all changes for the milestone (see the commit gate below), then
  run `python data/clear_mailbox.py` from the repo root — the mailbox no longer resets itself on
  delivery, so this explicit step is the only thing that clears it, and doing so is the required
  completion signal verification checks for (see `data/verification_feedback_protocol.md`'s
  "Deliberate mailbox clearing" section).
- **Verification agent (this session)**: never writes implementation code. Reads the `[r]` claim, runs
  code-level verification first, then (only if that passes) live-emulator/screenshot validation, then
  either closes the milestone (`[x]`) or sends it back (`[!]`) with specific, actionable fix
  instructions written directly into the phase doc's milestone section.

**Detecting a handoff.** At the start of a verification session (or when resuming after a break), start
a persistent background watch on the tracker + all phase docs (file-content polling, not git — this
step only detects that a submission is ready for review; it does not imply anything about commit
status, which is checked separately and gated below), e.g. the recipe below; treat any line it emits
as the trigger to re-read that file and begin the sequence below.
```bash
files=(
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase2_Calendar.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase3_Giving.md"
  "docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Phase4_HOA.md"
)
declare -A last
for f in "${files[@]}"; do last["$f"]=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1); done
while true; do
  sleep 20
  for f in "${files[@]}"; do
    cur=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
    if [ "$cur" != "${last[$f]}" ] && grep -q '\[r\]' "$f"; then
      echo "READY FOR VERIFICATION: $f"
    fi
    last["$f"]=$cur
  done
done
```

**Verification sequence — code first, screenshots only after code passes, never both at once:**
1. **Code verification (mandatory first step).** Read the diff/files the implementation agent's note
   points at. Check them against that specific milestone's validation-test list in the phase doc line
   by line (unit-test coverage, guard/effect correctness, schema/validator behavior, etc.) — run the
   actual test suite where the milestone specifies one (`flutter test`, the §7c validator, etc.).
   **Do not proceed to screenshots/emulator work until this step is fully green.**
2. **If code verification finds issues:** do **not** touch the emulator or take any screenshots. Set
   the milestone marker to `[!]` in both this table and the phase doc, and write a concrete, specific
   fix list directly into that milestone's section in the phase doc (what's wrong, where, and what
   the passing state looks like — the same specificity as this doc's own validation-test bullets, not
   a vague "needs work"). That note is the instruction set the implementation agent closes against;
   leave it there until the next `[r]` claim.
3. **Only once code verification is fully green:** proceed to live-emulator/screenshot-based
   validation exactly as each milestone's bullets specify (WSL Ubuntu, `PantryVision_Manual_API_36`
   AVD). Capture the evidence the milestone asks for.
4. **Commit gate (mandatory, added 2026-07-09) — hard gate, checked before closing.** Run `git status`
   (and `git log -1 --stat` if useful) and confirm every file this milestone touched — code, tests,
   fixtures, and the tracker/phase-doc edits themselves — is committed, with no modified or untracked
   files remaining in scope. **Do not close the milestone and do not send the next milestone's kickoff
   while anything is uncommitted.** If uncommitted changes are found, send back an explicit instruction
   to commit (suggest a commit message referencing the milestone) and wait for confirmation before
   proceeding — this is a real failure mode, not a formality: a live check on 2026-07-09 found three
   already-closed milestones (5.1 Garden Club, 5.2 Camera Club, 5.3 Book Club) sitting entirely
   uncommitted in the working tree, including untracked fixture/test files, with only one unrelated
   piece of Garden Club ever landing in a commit. This rule applies retroactively to any backlog found
   at any point: commit the backlog first (as its own commit, referencing which milestone(s) it
   contains) before the next kickoff goes out, even if that backlog predates this rule.
5. **Mailbox-clearing gate (mandatory, added 2026-07-09) — checked alongside the commit gate.**
   `data/verification_feedback.md` no longer resets itself when a message is delivered (see
   `data/verification_feedback_protocol.md`'s "Deliberate mailbox clearing" section) — a `[r]` claim
   should be accompanied by a fresh `MAILBOX_CLEARED` line in `data/file_watcher.log` (written by
   `python data/clear_mailbox.py`, which the implementation agent is required to run right before
   setting `[r]`). A `[r]` marker with no corresponding `MAILBOX_CLEARED` line is a signal the
   implementation agent's loop didn't actually reach a genuine completion point — treat it the same as
   an uncommitted-changes finding: worth a closer look before trusting the claim, not an automatic
   rejection, since the code itself may still be genuinely correct.
6. **Close the milestone** (`[~]`/`[r]` → `[x]`) only after steps 1, 3, 4, and 5 all pass, citing the
   evidence (test pass counts, screenshot references, and the commit hash covering this milestone) the
   same way `AppShell V2 Tracker.md` does.

**Why code verification must gate screenshots, not run alongside them:** a screenshot only proves the
UI *renders*; it doesn't prove the guard/effect logic, pagination, or transaction behavior underneath
is correct per that milestone's actual validation tests. Spending emulator time on code that's about
to be sent back for a rewrite is wasted effort — worse, a screenshot that happens to look right can
mask a code-level bug (e.g. a race condition in `applyTransition`) that no single screenshot would ever
reveal. Sequencing code-verification strictly before screenshot-verification is what keeps "looks done"
from being mistaken for "is done."

**Torn-read caveat.** After reading a freshly-changed tracker/phase doc (per the handoff-detection
watch above), sanity-check the content for signs of truncation (unbalanced markdown table rows, a
note cutting off mid-sentence, an unclosed code fence) before acting on it — re-read if something
looks torn. Only harden this further (e.g. an atomic-write convention matching the mailbox's) if a
genuine torn read is ever actually observed on this channel; none has been so far.

## 6. Explicitly out of scope for now
- Any change to Calendar or Marketplace before AppShell V2's current tracker closes both phases —
  **satisfied 2026-07-04**; Phase 1 supersedes that interim fix rather than building on top of it.
- Phase 5 (other communities) and Phase 6 (Skill changes) — deliberately not designed in detail yet;
  each needs its own fresh planning pass once the phase before it is actually done, not guessed at
  now.
- A real backend / HTTP implementation of `WorkflowEngineApi` — `LocalWorkflowEngineApi` (SQLite-
  backed, per Phase 1) is the only implementation needed for the demo app throughout Phases 1-5.
