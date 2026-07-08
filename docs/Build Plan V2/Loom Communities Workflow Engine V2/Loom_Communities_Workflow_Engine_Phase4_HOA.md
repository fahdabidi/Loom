# Phase 4 â€” Second Community, Full Tab Reimplementation: HOA (Cedar Commons)

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
Phases [1](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md),
[2](./Loom_Communities_Workflow_Engine_Phase2_Calendar.md), and
[3](./Loom_Communities_Workflow_Engine_Phase3_Giving.md) being fully closed.

Status: Phases 1, 2, and 3 fully closed 2026-07-07. This phase is now unblocked; Milestone 4.1
starts next.

**Handoff:** once a milestone below is implemented, set its marker to `[r]` here and in the main
tracker, then run this in-session watcher call and wait for delivery:

```python
from data.file_watcher import check_file_update
import asyncio

async def main():
  await check_file_update("data/verification_feedback.md")  # baseline call, returns immediately
  print(await check_file_update(
    "data/verification_feedback.md",
    timeout_seconds=1200,
    reset_template_path="data/verification_feedback_template.md",
    activity_process_names=["wsl", "dart"],
  ))

asyncio.run(main())
```

Then follow the embedded delivery instructions directly.
[Â§5 Handoff protocol](./Loom_Communities_Workflow_Engine.md#5-handoff-protocol-implementation-agent--verification-agent-added-2026-07-05)
for the full sequencing (code verification always runs before any screenshot validation).

## 1. Scope & goal

Prove the schema generalizes beyond Tabletop's three patterns (loan/giveaway marketplace, RSVP
calendar, dues payment) before building any automation or touching the Skill. Full tab detail
(personas, cards, per-archetype customizations) already lives in
[Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md) â€” this doc adds
the phase's milestones and validation bar.

**Why HOA, not another option**: surveyed the other built-out community examples first (Mosque,
Book Club, Youth Soccer, Garden Club, Chess Club, Camera Club â€” via `docs/Build Plan V2/Phases/`,
`docs/Product Docs V2/Community Examples/`, and B14 evidence folders). Garden Club and Camera Club
are dominated by direct re-skins of the same loan/giveaway + RSVP patterns Tabletop already covers â€”
weak contrast. HOA's tab IA (Home, **Board**, **Documents**, Payments, **Requests**, Messages) is the
best genuine contrast: **Documents** is a wholly new card-surface family (library/permissioned
reading, nothing like it in Tabletop), and **Requests**/**Board** (architectural-request â†’
committee-decision, submitted by the homeowner via `formEntry`, tracked by both sides via
`statusTimeline`) is a multi-step approval/case-task workflow â€” the "approval/review" family the
schema hasn't been proven against yet. Only HOA's Payments tab overlaps with what Marketplace/Giving
already proved. Mosque is a strong runner-up (Care/protected-vault and Admin/announcements+
volunteer-signup are equally novel) if HOA surfaces a blocking issue.

This is a **reimplementation with parity**, not a redesign â€” HOA's existing customizations/UI (per
[Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md)'s
Personas/Tabs/Customizations tables) are the acceptance bar.

## 2. Milestones

### Milestone 4.1 — Documents tab (`documentLibrary`)
**Status:** `[x]` CLOSED 2026-07-07 — resubmission independently verified, engine-backed implementation confirmed genuine.

Reimplement HOA's Documents tab: categorized library/folders, document detail, embedded-vs-external
open choice, version/access/acknowledgement state, audit trail.

**Validation tests required to close this milestone:**
- [x] Unit test: the HOA documents fixture parses and passes the Phase 1 §7c validator.
- [x] Widget test: category/folder navigation, document detail open (both embedded and external-open
  paths), version display, and access-request gating each work as their own test.
- [x] Widget test: audit trail records and displays an entry on document open/acknowledge — assert
  the actual entry content (who, when, what action), not just "a list item appeared."
- [x] Live emulator walk: screenshot evidence of the new Documents tab matching the existing
  implementation's behavior for both personas (homeowner, board).
- [x] Full `flutter test` suite green, exact pass count cited, zero regressions elsewhere.

**Resubmission note (2026-07-07):** the previous `[r]` implementation used local widget state only. This pass fixes that blocker.

**Implementation changes:**
- Added `LoomDocumentLibrary` and `LoomDocumentItem` to the shell model and package parser.
- Replaced the Documents tab placeholder path with a schema-backed document library renderer when a workflow declares `documentLibrary`.
- The Documents surface now instantiates a real `WorkflowDatabase` and `LocalWorkflowEngineApi`, registers a real `cedar-commons-document-library` state machine, creates one persisted workflow instance per document, and reloads UI state from `queryInstances`/persisted `instanceData`.
- Embedded open, external open, acknowledge, and request-access actions now call real `applyTransition`; access state and audit history are not maintained by local override fields.
- Added engine effect support for plain `append` plus `$timestamp` and `{field}` interpolation, used by the document audit trail.
- Added category chips, document rows, detail pane, embedded/external open actions, version/access fact pills, acknowledge/access-request actions, and exact timestamped audit entries.
- Added `Loom_Communities_Workflow_Engine_HOA_Documents_Example.jsonc` as the validator-clean HOA document-library fixture.
- Added M4.1 widget coverage in `b38_hoa_documents_test.dart` and validator coverage in `milestone_1_3_test.dart`.

**Board-capability decision:** HOA.md notes board-only upload/version/retire and acknowledgement-management capabilities. Those are not implemented in M4.1 because the milestone checklist scopes document library browsing, detail, open modes, version/access/acknowledgement state, access-request gating, and audit trail. Board administrative document-management actions should land with later Board/admin workflow scope rather than being silently hardcoded into the document reader.

**Validation evidence:**
- [x] `dart analyze packages/core/loom_workflow_engine` - clean.
- [x] `dart test packages/core/loom_workflow_engine` - 73/73 passed.
- [x] `dart analyze packages/core/loom_communities_app_shell` - clean.
- [x] `flutter test apps/loom_communities_demo/test/b38_hoa_documents_test.dart` - 5/5 passed.
- [x] `flutter test packages/core/loom_communities_app_shell/test apps/loom_communities_demo/test` - 119/119 passed.
- [x] `dart analyze packages/tooling/loom_ux_judges` - clean.
- [x] `dart test packages/tooling/loom_ux_judges/test/milestone_1_3_test.dart` - 28/28 passed.
- [x] `dart test packages/tooling/loom_ux_judges` - 28/28 passed.
- [x] `dart run packages/tooling/loom_ux_judges/bin/workflow_state_machine_validator.dart --definitions ../docs/Build\ Plan\ V2/Loom\ Communities\ Workflow\ Engine\ V2/Loom_Communities_Workflow_Engine_HOA_Documents_Example.jsonc` - `status: pass`, `errorCount: 0`, `warningCount: 0`, `findings: []`.
- [x] Live emulator screenshot validation: homeowner and board persona Documents tab parity confirmed.

**Verification Agent second-pass result (2026-07-07): PASS — CLOSED.**

Independently re-read the fixed code (not re-trusting the resubmission note): `_DocumentLibraryWorkflowSurfaceState` in `part02_tab_shell.dart` now constructs a real `WorkflowDatabase`/`LocalWorkflowEngineApi`, registers `_documentMachineFor` (states `available`/`read`/`acknowledged`/`access-requested`, all four transitions guarded by `WorkflowGuard(allowedPersonaIds: ...)`), creates one persisted instance per document, and every action button (`open-embedded`, `open-external`, `acknowledge`, `request-access`) calls real `applyTransition` followed by a `queryInstances`-backed reload. `effect_evaluator.dart`'s `_resolveValue` genuinely resolves `$timestamp` to `DateTime.now().toUtc().toIso8601String()` and interpolates `{field}` tokens — confirmed by reading the diff, not just the claim.

Re-ran every cited command fresh (WSL): `dart analyze packages/core/loom_workflow_engine` clean; `dart test packages/core/loom_workflow_engine` 73/73; `dart analyze packages/core/loom_communities_app_shell` clean; `flutter test .../b38_hoa_documents_test.dart` 5/5; `flutter test packages/core/loom_communities_app_shell/test apps/loom_communities_demo/test` 119/119; `dart analyze packages/tooling/loom_ux_judges` clean; `dart test packages/tooling/loom_ux_judges` 28/28 (includes the new "HOA documents fixture" validator case). All match the submission exactly.

Live emulator walk (fresh debug APK build, clean uninstall/reinstall, community package pushed via `run-as`, "Cedar Commons HOA" installed and opened): as **Avery Brooks (Homeowner)**, tapped "Open embedded" on Community Rules (bylaws) — `accessState` flipped `available` → `read` on-device and the audit trail rendered a genuinely timestamped entry, `"Avery Brooks at 2026-07-08T00:23:23.256503Z opened Community Rules embedded"`. Switched to the covenants category — CCR Amendment Packet (`restricted`) correctly showed "Open embedded"/"Open external" disabled via guard evaluation, only "Request access" enabled; tapping it transitioned the document to the terminal `access-requested` state, at which point all three actions (including "Request access" itself) went disabled. **Strongest evidence of genuine engine wiring**: switched persona via the header's "Switch role" control to **HOA Board** and confirmed both documents' state persisted unchanged — Community Rules still showed `read` with the *identical* timestamped audit entry, and the CCR packet still showed `access-requested` — proving this is one shared `WorkflowDatabase` instance read by both personas via `queryInstances`, not per-widget local state that a persona-switch rebuild would have reset. This directly rules out the M2.3/M4.1-first-pass "cosmetic engine bypass" anti-pattern.

All three first-pass findings (no real engine plumbing, orphaned fixture, timestamp-less audit trail) are conclusively resolved. Board-capability deferral decision (upload/version/retire held for later Board/admin scope) is reasonable and explicitly documented, not silently omitted. Milestone 4.1 is CLOSED.
### Milestone 4.2 â€” Requests + Board (submitted `formEntry`, tracked `statusTimeline`, reviewed `dashboard` queue)
Reimplement the architectural-request workflow: homeowner submits via `formEntry`, both sides track
progress via role-keyed `statusTimeline` bindings (Phase 1 Â§2a's actor/receiver split), board persona
also sees a `dashboard` review queue.

**Validation tests required to close this milestone:**
<br>
**This is the milestone most likely to be the "did the schema actually have to change" test case
(Â§3 below) â€” give it the most scrutiny.**
- [ ] Unit test: the HOA architectural-request fixture (submit â†’ under-review â†’ changes-needed â†’
  approved/rejected â†’ reopened, per
  [Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md)) parses and
  passes the Phase 1 Â§7c validator, including its multi-role `renderBindings` (homeowner `actor`,
  board `receiver`/reviewer) staying under the â‰¤32/â‰¤16 cap.
- [ ] Widget test: homeowner's `formEntry` submission creates an instance in the initial state, with
  `editableFields` (Phase 1 Â§7a-i) matching the fixture's declared per-state editability.
- [ ] Widget test: homeowner's `statusTimeline` view (role: actor/tracking) and board's
  `statusTimeline` view (role: receiver/reviewer) render from the **same instance**, showing the
  correct state-specific alternate actions on the reviewer side (request changes, reopen, appeal,
  retry) via `availableTransitions`, not hardcoded per-surface logic.
- [ ] Widget test: board's `dashboard` review queue lists pending requests and tapping one navigates
  to the same `statusTimeline` reviewer surface (proves the queue is a pointer, not a duplicate
  render, per Phase 1 Â§2a's `bindingKind: "summary"` vs `"primary"` distinction).
- [ ] Full behavioral-parity walk against every state transition named in
  [Loom_Communities_Workflow_Engine_HOA.md](./Loom_Communities_Workflow_Engine_HOA.md)'s Requests/Board
  section: submit, approve, reject/send-back, request-changes, reopen â€” each with its own test.
- [ ] Live emulator walk: screenshot evidence of both personas' views of the same request instance,
  at least one state transition performed on-device by the board persona and reflected live (or on
  next load, whichever the implementation's refresh model is) in the homeowner's view.
- [ ] Full `flutter test` suite green, exact pass count cited.

### Milestone 4.3 â€” Payments tab (reuse Phase 3's `payment` family)
Reimplement HOA dues on the `payment` `cardSurfaceFamily` built in Phase 3 â€” the one HOA tab expected
to require no new schema capability.

**Validation tests required to close this milestone:**
- [ ] Unit test: HOA dues fixture parses and passes the validator, reusing the exact `payment` family
  template from Phase 3 with zero template changes (confirm via diff that the template file itself
  is untouched â€” only the fixture/JSON differs).
- [ ] Widget test: full HOA dues pay/receipt/history flow, parity with existing implementation.
- [ ] Live emulator walk: screenshot evidence of HOA Payments tab on-device.
- [ ] Full `flutter test` suite green, exact pass count cited.

### Milestone 4.4 â€” Generality finding (mandatory evidence artifact, not optional)
A written note â€” added to this doc once each milestone above is closed â€” stating explicitly what, if
anything, the schema had to be *changed* to support across all three tabs (new guard/effect ops, a
new `cardSurfaceFamily` concept, anything `instanceDataSchema` couldn't express cleanly).

**Validation required to close this milestone:**
- [ ] The finding is written and cites, for each of Milestones 4.1-4.3, either "no schema change
  needed" or the specific change made and why the existing primitives couldn't express it.
- [ ] If nothing needed to change, that finding is stated plainly as the strongest possible signal
  the schema is genuinely general â€” not hedged or omitted.
- [ ] If something DID need to change, a follow-up note on whether Phase 1's design docs
  (state machine schema, `instanceDataSchema`, or the archetype catalog) need a corresponding update,
  filed as a fast-follow task before Phase 5 begins.

