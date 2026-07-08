# Phase 5 â€” Automated/Semi-Automated Migration of Remaining Communities

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 4](./Loom_Communities_Workflow_Engine_Phase4_HOA.md) being fully closed, **including its
Milestone 4.4 generality finding** â€” that finding directly determines how much of this phase can be
mechanical (fixture JSON transformation) versus needing per-community judgment calls.

Status: in progress as of 2026-07-08. Milestone 5.1 is marked `[r]` after
implementation and local validation, pending Verification Agent review.

**Handoff:** once a milestone below is implemented, set its marker to `[r]` here and in the main
tracker, then run this in-session watcher call and wait for delivery:

```python
from data.file_watcher import check_file_update
import asyncio

async def main():
  await check_file_update("data/verification_feedback.md")  # baseline call, returns immediately
  print(await check_file_update(
    "data/verification_feedback.md",
    timeout_seconds=3600,
    reset_template_path="data/verification_feedback_template.md",
    activity_process_names=["wsl", "dart"],
  ))

asyncio.run(main())
```

Then follow the embedded delivery instructions directly.
[Â§5 Handoff protocol](./Loom_Communities_Workflow_Engine.md#5-handoff-protocol-implementation-agent--verification-agent-added-2026-07-05)
for the full sequencing (code verification always runs before any screenshot validation).

## 1. Scope & goal

Targets: Mosque, Book Club, Youth Soccer, Garden Club, Chess Club, Camera Club, and any others with
real fixture data. Each gets its own per-community doc already in this folder
([Mosque](./Loom_Communities_Workflow_Engine_Mosque.md),
[BookClub](./Loom_Communities_Workflow_Engine_BookClub.md),
[YouthSoccer](./Loom_Communities_Workflow_Engine_YouthSoccer.md),
[GardenClub](./Loom_Communities_Workflow_Engine_GardenClub.md),
[ChessClub](./Loom_Communities_Workflow_Engine_ChessClub.md),
[CameraClub](./Loom_Communities_Workflow_Engine_CameraClub.md)) with their tabs/cards/archetypes/
customizations already mapped â€” this phase reimplements each on the engine, it does not redesign them.

## 2. Planning pass — migration order and automation strategy (2026-07-08)

Phase 4's generality finding is the input to this plan. The main lesson is that the Phase 1 schema
generalized across HOA's Documents, Requests/Board, and Payments with only one small effect-value
interpolation addition (`$timestamp` and `{field}`), and no new `cardSurfaceFamily`, guard op,
transition op, or `instanceDataSchema` concept. That makes Phase 5 mostly a fixture-and-rendering
migration, but not a blind bulk conversion: the later communities concentrate the remaining
high-scrutiny surfaces (`protectedDetail`, `guidedProcess`, `votePoll`, `searchAiAnswer`,
`exportWizard`, and cross-workflow table effects).

### Migration order

1. **Milestone 5.1 — Garden Club tab reimplementation.** Garden Club is first because its dominant
   surfaces are already proven or near-proven: `calendarAgenda` from Phase 2, `stateMachineGrid`
   loan/giveaway from Phase 1/Marketplace, `formEntry` from HOA Requests, and `discussionThread`
   as a support surface. Its plant exchange and tool loan/giveaway flows are different domain data
   over the same queue/custody/listing primitives. It still needs scrutiny for `volunteerRoster` and
   `exportWizard`, but it is the best first migration because most of its user-visible behavior is
   mechanical transformation from existing fixture shapes.
2. **Milestone 5.2 — Camera Club tab reimplementation.** Camera Club is second because photo-walk
   RSVP and gear loan reuse proven `calendarAgenda` and `stateMachineGrid`. The critique flow is a
   composition test (`formEntry` + image-forward `stateMachineGrid` + attached `discussionThread`),
   not a new archetype if implemented correctly. This should validate composition without forcing
   protected-data or guided-process complexity yet.
3. **Milestone 5.3 — Book Club tab reimplementation.** Book Club adds `votePoll`,
   `notificationInbox`, `documentLibrary`, `discussionThread`, `searchAiAnswer`, and the richest
   shared-library `stateMachineGrid` variant. It should follow the two mechanical migrations because
   ballot/winning/tie state and search citations need more hand-authored tests and likely cannot be
   trusted to pure JSON conversion.
4. **Milestone 5.4 — Chess Club tab reimplementation.** Chess Club should come after Book Club
   because it combines `formEntry`, `statusTimeline`, `calendarAgenda`, `table` with `rankingMode`,
   `dashboard`, `exportWizard`, and a match-result-to-rankings cross-workflow effect. The archetypes
   are cataloged, but the cross-workflow write path needs direct scrutiny.
5. **Milestone 5.5 — Youth Soccer tab reimplementation.** Youth Soccer is the canonical
   `guidedProcess` + reviewer `statusTimeline` split, plus protected minor data and role-specific
   roster table/grid views. It should run after the simpler table/status migrations because
   redaction/consent and wizard-step gating are higher-risk.
6. **Milestone 5.6 — Mosque tab reimplementation.** Mosque is last and should get HOA-level scrutiny:
   it combines audience-selected events, donations, donor visibility preferences, protected care
   details, announcements, volunteer roster, privacy-safe notifications, and permission-guarded
   search citations. It is most likely to expose a real generality gap if one remains.

### Scripted versus hand-authored migration

Much of Phase 5 can be scripted as JSON transformation:
- Workflow identity, persona policies, `states`, `transitions`, guards, `effects`, and
  `renderBindings` can be generated from each community doc's tab/card/action matrix.
- Known surface families (`calendarAgenda`, `stateMachineGrid`, `paymentCheckout`,
  `documentLibrary`, `formEntry`, `statusTimeline`, `discussionThread`, `dashboard`) can be mapped
  mechanically to template slots and default fact-pill schemas.
- Repeated marketplace/library patterns can share a generator for browse/search/list/edit/borrow/
  queue/return/giveaway/custody fields.
- Audit/history effects should use the now-documented `$timestamp` and `{field}` interpolation
  rather than per-community custom string handling.

The following parts still need hand authoring and review:
- Persona-specific privacy/redaction semantics (`protectedDetail`, donor visibility, minor data).
- `guidedProcess` step gating and resume semantics.
- `votePoll` live totals, winning/tie state, and change/clear-vote semantics.
- `searchAiAnswer` citation filtering and permission-guarded sources.
- `exportWizard` redaction preview, checksum, transfer/rollback/retry behavior.
- Cross-workflow effects such as Chess result submission updating the rankings table.
- Image-forward display contexts for Camera critique submissions.

### Expected new schema needs

No community is currently known to require a new top-level archetype or a new guard/effect operation
beyond the Phase 1 catalog plus the Phase 4 effect-value interpolation addition. However, three areas
must be treated as scrutiny points rather than assumed solved:
- **Protected detail/privacy:** Mosque and Youth Soccer may require field-level masking behavior that
  is more than ordinary persona guard hiding. If existing `protectedDetail` semantics cannot express
  same-instance different-field visibility, that is a real schema/design finding.
- **Guided process:** Youth Soccer's registration wizard must prove sequential step gating and
  reviewer status tracking on the same instance. If this cannot be expressed with existing state,
  guard, and render-binding primitives, it needs a Phase-5 generality note.
- **Cross-workflow table effects:** Chess result-to-rankings writes must prove existing effect
  semantics can update related backing data safely. If not, that is a schema/effect-model gap, not a
  UI-only task.

Unless one of those scrutiny points fails, per-community generality findings can be short and
community-specific: state whether the migration required no schema change, cite any implementation
architecture caveat, and explicitly name any follow-up before moving to the next community.

## 3. Milestones

### Milestone 5.1 — Garden Club tab reimplementation
**Status:** `[!]` SENT BACK 2026-07-08 — code verification found a confirmed orphaned-fixture defect
(the exact anti-pattern that sent M4.1 back on its first pass) plus real feature gaps. Live emulator
walk was not performed, per protocol: code verification runs first, and it did not pass.

**Findings (all independently confirmed via direct code/fixture read, not assumed):**

1. **Orphaned fixture — the fixture is never read by the running app.** Confirmed via
   `grep -rn "GardenClub_Example" packages/core/loom_communities_app_shell/lib/` returning zero
   matches. `_GardenClubEngineStore._seedInstances()` (`part02_tab_shell.dart`) hardcodes its own
   separate, simplified Dart state machines (`_gardenEventMachine`, `_gardenToolMachine`,
   `_gardenPlantMachine`, `_gardenVolunteerMachine`, `_gardenExportMachine`) directly in code, with
   literal seed data — it does not parse or execute
   `Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc` in any way. The fixture passing the
   validator proves nothing about what the app actually does; the two are disconnected. This is the
   identical defect class documented in M4.1's first-pass rejection.
2. **The fixture is demonstrably richer than the app it's supposed to describe** — direct evidence
   the app under-implements what was already correctly designed: the fixture's `plant-exchange`
   `draft` state declares `editableFields: [plantType, quantity, pickupNotes, privacyNote]`, and its
   export workflow has real `redactionPreview`/`checksum`/`downloadStatus` instance-data fields with
   populated seed values. The app's `_gardenPlantMachine` has no edit capability at all, and
   `_gardenExportMachine`'s `instanceDataSchema` is only `title`/`schemaNames`/`exportStatus`/
   `history` — none of the fixture's redaction/checksum/download fields exist in the app. The fixture
   also models `cancel-event`, `report-lost`, and `close-shift` transitions that don't exist in the
   app at all.
3. **Plant exchange "edit" is missing entirely**, not just untested — required by this milestone's own
   checklist ("submit/edit/withdraw/claim/cancel-claim") and by
   `Loom_Communities_Workflow_Engine_GardenClub.md` ("list own item, edit, withdraw"). No edit
   transition exists in `_gardenPlantMachine`, and no field-editing UI exists in `_gardenWorkflowCard`.
4. **Export feature reproduces the exact anti-pattern GardenClub.md explicitly warns against.** That
   doc states the export card was "explicitly tightened from 'generic evidence' to this full
   review-and-confirm shape [schema selection, redaction preview, checksum, destination, change-scope,
   download status] — direct evidence a plain singleItem/list was insufficient here." The app's
   export workflow is a bare `generate-export`/`rollback-export` toggle rendering only a static
   "Schemas: …" text line — none of the required review/redaction/checksum/destination/scope surface
   exists.
5. **Home tab is not engine-backed at all.** `_isGardenEngineExperience` gates exactly 4 switch cases
   (`CalendarTabSurface`, `MarketplaceTabSurface`, `DocumentsTabSurface`, `CareVolunteerTabSurface`) —
   there is no Home/dashboard case, so Garden Club's Home tab falls through to whatever generic
   default exists for all communities, not the domain-native "this week's activity + help/exchange
   needed + records" composite this milestone's checklist explicitly requires ("domain-native Home
   pins") and `Loom_Communities_Workflow_Engine_GardenClub.md` describes.
6. **Test coverage gaps consistent with the above** (secondary to the defects, not independent): the
   `join-waitlist` transition exists in the app's calendar machine but has zero test coverage; no test
   exercises edit/withdraw for plant exchange (edit doesn't exist to test; withdraw exists but is
   untested); no test or live-walk anchor exists for Home pins.

**What does verify cleanly, for the record:** `dart analyze packages/core/loom_communities_app_shell`
clean; `flutter test apps/loom_communities_demo/test/b41_garden_engine_migration_test.dart` 1/1;
combined demo suite 124/124; app_shell suite 5/5; `dart analyze packages/tooling/loom_ux_judges`
clean; `dart test packages/tooling/loom_ux_judges/test/milestone_1_3_test.dart` 31/31 (including the
Garden Club fixture validator case). All cited commands re-run fresh and matched exactly — the
engine wiring pattern used (`WorkflowDatabase.memory()`/`LocalWorkflowEngineApi`/
`availableTransitions`/`applyTransition`) is genuinely real, not the local-widget-state anti-pattern.
The defect here is scope completeness and fixture/app disconnection, not fake engine wiring.

**Required to close this milestone:**
- [ ] Wire `_GardenClubEngineStore` to actually parse and register the state machines from
  `Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc` (or a package-parsed equivalent), not
  hand-duplicated Dart machines — the fixture must be the source of truth the app executes, matching
  the pattern M4.1's resubmission and M4.2/M4.3 all use.
- [ ] Add plant-exchange edit capability (transition and/or editable-field UI) matching the fixture's
  `editableFields` declaration and this milestone's own checklist.
- [ ] Bring the export workflow up to the required review-and-confirm shape: schema selection,
  redaction preview, checksum, destination, change-scope, download status — using the fixture's
  already-modeled `redactionPreview`/`checksum`/`downloadStatus` fields.
- [ ] Implement domain-native Home pins for Garden Club (activity + help/exchange needed + records
  composite), engine-backed, with its own live-walk anchor key.
- [ ] Add test coverage for `join-waitlist`, plant-exchange edit/withdraw, and Home pins.
- [ ] Re-run the full validation bar (fixture validator, widget tests, live emulator walk, full suite)
  once the above are fixed, and cite exact fresh pass counts.

- [x] Garden Club workflow fixtures parse and pass the Phase 1 §7c validator. Added
  `Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc`; `dart test
  packages/tooling/loom_ux_judges/test/milestone_1_3_test.dart` passes 31/31 and the live fixture
  validator returns `status: pass`, `errorCount: 0`, `warningCount: 0`.
- [x] Garden Club app path is engine-backed. `part02_tab_shell.dart` now routes Garden Calendar,
  Marketplace, Care, and Documents tabs through a seeded `WorkflowDatabase.memory()` +
  `LocalWorkflowEngineApi` store, with transitions rendered from `availableTransitions()` and applied
  through `applyTransition()`. Built-in Garden catalog/policies now include
  `garden-tool-loan` and `garden-volunteer-shift`.
- [x] Behavioral-parity widget tests cover calendar RSVP/cancel, tool loan request/join queue/leave
  queue/return, plant exchange submit/claim/cancel-claim, volunteer signup/cancel, and export
  generate/rollback in `apps/loom_communities_demo/test/b41_garden_engine_migration_test.dart`.
  Focused run: `flutter test apps/loom_communities_demo/test/b41_garden_engine_migration_test.dart`
  passes 1/1.
- [x] Live emulator/screenshot validation preparation is complete for the Verification Agent. Stable
  anchors are `garden-engine-calendar`, `garden-engine-marketplace`, `garden-engine-care`,
  `garden-engine-documents`, and action keys `garden-action-rsvp-going`,
  `garden-action-request-loan`, `garden-action-join-queue`, `garden-action-leave-queue`,
  `garden-action-return-tool`, `garden-action-submit-listing`, `garden-action-claim`,
  `garden-action-cancel-claim`, `garden-action-sign-up`, `garden-action-cancel-signup`,
  `garden-action-generate-export`, and `garden-action-rollback-export`.
- [x] Full relevant Flutter suite green, zero regressions in changed app paths. Exact runs:
  `dart analyze packages/core/loom_communities_app_shell` clean;
  `flutter test apps/loom_communities_demo/test` passes 124/124;
  `flutter test packages/core/loom_communities_app_shell` passes 5/5;
  `dart analyze packages/tooling/loom_ux_judges` clean;
  `dart test packages/tooling/loom_ux_judges/test/milestone_1_3_test.dart` passes 31/31;
  Garden fixture validator returns `status: pass`, `errorCount: 0`, `warningCount: 0`.
- [x] Garden Club generality note: no workflow-engine schema changes were required for this
  migration. `volunteerRoster` and `exportWizard` are represented with existing state-machine
  bindings, schema fields, guarded transitions, and template/action-row primitives; the app-shell
  work was a community-specific renderer/store integration rather than an engine-schema extension.

### Milestone 5.2 — Camera Club tab reimplementation
- [ ] Camera Club workflow fixtures parse and pass the Phase 1 §7c validator.
- [ ] Behavioral-parity widget tests cover photo-walk RSVP/change, critique submission/edit/withdraw,
  image-forward critique grid, attached critique thread, gear loan/giveaway queue/custody actions,
  and organizer validation status.
- [ ] Live emulator walk with screenshot evidence for Calendar, Critique, Gear, Admin, and Home.
- [ ] Full `flutter test` suite green, exact pass count cited.
- [ ] Camera Club generality note confirms whether composition (`formEntry` + `stateMachineGrid` +
  `discussionThread`) avoided new schema surface.

### Milestone 5.3 — Book Club tab reimplementation
- [ ] Book Club workflow fixtures parse and pass the Phase 1 §7c validator.
- [ ] Behavioral-parity widget tests cover nomination submit/edit/withdraw, ballot cast/change/clear
  and close/winner/tie states, meeting RSVP, shared-library loan/queue/giveaway/return, discussion
  reply/moderation, reading-material document open, selection publish/receive, and search citations.
- [ ] Live emulator walk with screenshot evidence for Books, Calendar, Library, Discussions,
  Documents, Search, and Home.
- [ ] Full `flutter test` suite green, exact pass count cited.
- [ ] Book Club generality note focuses on `votePoll`, `searchAiAnswer`, and the richest
  `stateMachineGrid` library variant.

### Milestone 5.4 — Chess Club tab reimplementation
- [ ] Chess Club workflow fixtures parse and pass the Phase 1 §7c validator.
- [ ] Behavioral-parity widget tests cover match proposal, accept/decline/reschedule/cancel,
  confirmed calendar event, result report/correction/dispute, rankings table update, organizer
  pairing queue, export, and documents.
- [ ] Live emulator walk with screenshot evidence for Matches, Calendar, Rankings, Admin, Documents,
  and Home.
- [ ] Full `flutter test` suite green, exact pass count cited.
- [ ] Chess Club generality note focuses on ranking-mode table and result-to-rankings
  cross-workflow effects.

### Milestone 5.5 — Youth Soccer tab reimplementation
- [ ] Youth Soccer workflow fixtures parse and pass the Phase 1 §7c validator.
- [ ] Behavioral-parity widget tests cover guided registration steps, waiver gate, payment gate,
  reviewer status timeline, schedule RSVP/reminders, guardian roster card, coach roster table,
  protected minor detail redaction, reminders, documents, and export.
- [ ] Live emulator walk with screenshot evidence for Registration, Schedule, Team, Payments,
  Documents, Coach/Admin, and Home.
- [ ] Full `flutter test` suite green, exact pass count cited.
- [ ] Youth Soccer generality note focuses on `guidedProcess` and `protectedDetail` for minor data.

### Milestone 5.6 — Mosque tab reimplementation
- [ ] Mosque workflow fixtures parse and pass the Phase 1 §7c validator.
- [ ] Behavioral-parity widget tests cover admin event creation with `audienceSelector`, member RSVP
  visibility by audience, donation/receipt and donor-visibility preference, care request submit/edit,
  protected care detail review/assign/respond/close, announcement compose/publish/receive, volunteer
  signup/open/close/contact gating, messages/notifications, search citations, and Home pins.
- [ ] Live emulator walk with screenshot evidence for Calendar, Giving, Care, Admin, Messages,
  Search, and Home across admin/member personas.
- [ ] Full `flutter test` suite green, exact pass count cited.
- [ ] Mosque generality finding is mandatory and Phase-4-level detailed because this is the
  highest-risk remaining privacy/audience/volunteer migration.

Each milestone follows the same evidence-bar shape used in every prior phase:
- [ ] Community's workflow fixtures parse and pass the Phase 1 Â§7c validator.
- [ ] Full behavioral-parity widget-test suite against the community's existing tab implementation,
  one test per interaction named in its own per-community doc.
- [ ] Live emulator walk with screenshot evidence for each reimplemented tab.
- [ ] Full `flutter test` suite green, exact pass count cited, zero regressions elsewhere.
- [ ] A generality finding, same shape as Phase 4 Milestone 4.4, per community (or waived if Phase 4's
  finding already established the schema needs zero further changes and this phase turns out to be
  purely mechanical â€” decide during the fresh planning pass, not here).

## 3. What the fresh planning pass (post-Phase-4) needs to determine
- Migration order across the 6 remaining communities â€” likely sequenced by how much each diverges
  from patterns Phases 1-4 already proved (Garden Club/Camera Club were noted in Phase 4 as
  dominated by already-proven loan/giveaway + RSVP patterns â€” likely earliest/most mechanical; Mosque
  was the Phase-4 runner-up specifically because Care/protected-vault and Admin/volunteer-signup are
  still novel â€” likely needs the same scrutiny Phase 4 gave HOA).
- How much of the migration can be scripted (JSON transformation from existing fixture shapes into the
  engine schema) versus requiring hand authoring per community.
- Whether any community surfaces a genuinely new archetype or guard/effect need beyond the 15+1
  cataloged in Phase 1 Â§2b â€” if so, that's a signal this phase isn't purely mechanical after all and
  needs its own Phase-4-style generality finding before continuing to the next community.

