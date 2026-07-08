# Phase 3 — Giving (Tabletop Club)

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 1](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md) and
[Phase 2](./Loom_Communities_Workflow_Engine_Phase2_Calendar.md) being fully closed.

Status: Phase 1 and Phase 2 fully closed 2026-07-07. This phase is now unblocked; Milestone 3.1
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
[§5 Handoff protocol](./Loom_Communities_Workflow_Engine.md#5-handoff-protocol-implementation-agent--verification-agent-added-2026-07-05)
for the full sequencing (code verification always runs before any screenshot validation).

## 1. Scope & goal

Also reuses Phase 1 infrastructure. Two things land: (1) a new `payment` `cardSurfaceFamily` template
migrating the dues-payment workflow onto the new engine; (2) the first real cross-workflow-type
dependency — `requiresWorkflowsComplete` (designed in
[Phase 1 §7b](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md#7b-cross-workflow-dependencies-get-a-real-field))
wired for real on Marketplace's `borrow` transition, gating it on the dues workflow being complete.

## 2. Milestones

### Milestone 3.1 - `payment` cardSurfaceFamily template + dues workflow migration
`[x]` **CLOSED 2026-07-07**

**2026-07-07: Verification result — CLOSED.** Independently re-verified, first pass, no issues.
- Read `_GivingTabSurfaceState` (`part02_tab_shell.dart:3216` onward) directly: `initState`
  genuinely instantiates `_database = WorkflowDatabase.memory()` and
  `_engine = LocalWorkflowEngineApi(...)`, registers a real `LoomWorkflowStateMachine` (`unpaid`/
  `paid` states, a real `pay` transition with a real guard and a real `receiptStatus` effect) via
  `_paymentMachineFor`/`registerDefinition`.
- Confirmed the `linkedWorkflowId` reuse mechanism genuinely works: the `pay` transition sets
  `linkedWorkflowId: workflowId` (self-referential), `onTransitionPressed` checks
  `linkedWorkflowId == widget.workflow.workflowId` and calls the existing
  `widget.onConfirmWorkflow?.call(widget.workflow)` — the same generic action-surface completion
  path used elsewhere in the app, not a bespoke payment flow. `didUpdateWidget` watches
  `widget.paid` (driven by the app-level `completedWorkflowIds` set) and calls
  `_completePaymentIfNeeded()` → real `_engine.applyTransition(..., transitionId: 'pay', ...)` on
  completion — genuine persistence, not cosmetic state.
- Read `b35_giving_payment_test.dart` in full: 5 genuine tests, including
  `wf_giving-checkout-to-receipt` — a real full round-trip test (tap `giving-action-pay` → tap the
  generic action-surface's `workflow-action-submit-...` button → re-navigate → assert the receipt
  key renders with `"$15 — complete"`). Not gamed.
- Fresh re-runs, all matched exactly: dues fixture validator `status: pass, errorCount: 0,
  warningCount: 0`; `flutter analyze` (app_shell + b35) clean; `flutter test` b35 5/5; `dart
  analyze`/`dart test` `loom_workflow_engine` clean/70/70; `dart analyze`/`dart test`
  `loom_ux_judges` clean/26/26. Also ran the broader combined suite:
  `flutter test packages/core/loom_communities_app_shell/test apps/loom_communities_demo/test` —
  112/112 (same total as the Phase 2 baseline, since this migrates existing Giving tests rather
  than adding new ones — zero regressions).
- Live emulator walk on `PantryVision_Manual_API_36` (fresh debug APK build + install, real
  on-device interaction): confirmed the full pay round trip. Giving tab showed real engine-backed
  fact pills ($15/Quarterly club dues/Recipient: Tabletop Club treasury/recurring/Voting member
  badge) and a real "Pay $15" action button; tapping it opened the generic action-surface
  completion UI ("Quarterly club dues" / "Pay and save receipt"); completing it returned to the
  Giving tab now showing a green "Paid" pill and a "$15 — complete" receipt card — the real,
  persisted `paid` state, not a UI mock.

**Milestone 3.1 is closed.** Continuing to Milestone 3.2 (cross-workflow dependency gate) next.

---

**Implementation note (2026-07-07, first pass):** implemented the dues-payment workflow on the new engine.

**Implementation changes:**
- Added `payment` and `paymentCheckout` card surface templates backed by `WorkflowFactPillRow` and `WorkflowActionButtonRow`.
- Added schema-driven payment fact fields for `amountLabel`, `purpose`, `recipient`, `cadence`, and `entitlement` via `paymentCheckoutDefaultInstanceDataSchema`.
- Extended `LoomGivingPayment` and package parsing with `recipient`.
- Migrated `_GivingTabSurface` to `WorkflowDatabase.memory()` + `LocalWorkflowEngineApi`.
- Registered a dues state machine with `unpaid`/`paid` states and a `pay` transition with `linkedWorkflowId` pointing to the existing generic action surface workflow.
- The `pay` action renders as `giving-action-pay`; completing the existing action surface updates the engine instance from `unpaid` to `paid` and renders the receipt state.
- Added `Loom_Communities_Workflow_Engine_Giving_Dues_Example.jsonc` as the dues workflow validator fixture.

**Changed files:**
- `app/packages/core/loom_communities_app_shell/lib/src/part02_tab_shell.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part11_shell_models.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part15_evidence_catalog.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part18_marketplace_rendering.dart`
- `app/apps/loom_communities_demo/test/b35_giving_payment_test.dart`
- `docs/Build Plan V2/Loom Communities Workflow Engine V2/Loom_Communities_Workflow_Engine_Giving_Dues_Example.jsonc`

**Validation evidence:**
- [x] Dues fixture validator: `status: pass`, `errorCount: 0`, `warningCount: 0`, `findings: []`.
- [x] `flutter analyze packages/core/loom_communities_app_shell apps/loom_communities_demo/test/b35_giving_payment_test.dart` - clean.
- [x] `flutter test apps/loom_communities_demo/test/b35_giving_payment_test.dart` - 5/5 passed.
- [x] `flutter test packages/core/loom_communities_app_shell/test apps/loom_communities_demo/test` - 112/112 passed.
- [x] `dart test packages/core/loom_workflow_engine` - 70/70 passed.
- [x] `dart test packages/tooling/loom_ux_judges` - 26/26 passed.
- [x] `dart analyze packages/core/loom_workflow_engine && dart analyze packages/tooling/loom_ux_judges` - clean.
- [ ] Live emulator screenshot validation remains for the Verification Agent; implementation-side automated proof is complete and emulator availability was previously confirmed on `emulator-5554` / `PantryVision_Manual_API_36`.

Waiting for Verification Agent result through `data/verification_feedback.md`.
### Milestone 3.2 — Cross-workflow dependency: dues-current gate on Marketplace `borrow`
**Status:** `[x]` CLOSED 2026-07-07.

**2026-07-07: Verification result — CLOSED.** Independently re-verified, first pass, no issues.
- Read `completedWorkflowIdsForPersona` (`local_workflow_engine_api.dart`) directly: a genuine
  database query (`_db.queryInstancesForPersona`) across **all** workflow types for the acting
  persona, not scoped to one type — checks `currentState == 'paid'` or `state.isTerminal`, and adds
  `row.workflowType`, `data['workflowId']`, and `data['completionWorkflowId']` to the completed set,
  so a guard can reference any of those identifiers.
- Confirmed `applyTransition` genuinely enforces the gate: it awaits
  `completedWorkflowIdsForPersona` and threads it into `trans_eval.availableTransitions` before
  matching the requested transition, so a gated `borrow` call throws `StateError`, not just fails
  silently in the UI.
- Confirmed the Marketplace UI (`_actionsFor`, `part02_tab_shell.dart`) computes its own
  `_completedWorkflowIds` via the same method and re-evaluates the guard both with and without the
  `requiresWorkflowsComplete` clause to distinguish "not allowed at all" from "waiting on a
  prerequisite" — rendering `waitingForPrerequisite: true` (shows "Waiting") rather than hiding the
  button, exactly as required.
- Confirmed `_syncDuesCompletionFromShell`/`_seedAndLoad` keep the Marketplace surface's own local
  mirror of the dues instance in sync with the Giving tab's real payment state, and that both use
  the same `completionWorkflowId: 'tabletop-membership-dues-current'` identifier as the marketplace
  fixture's guard — the whole chain is consistently wired end to end, not just superficially
  plausible.
- Read all 3 required engine unit tests (`milestone_3_2_test.dart`): dues-current member borrows
  successfully; dues-not-current member's `applyTransition` throws; persona-specific lookup proven
  by a second persona whose own dues remain unpaid. Notably, one test explicitly documents that the
  *synchronous* `availableTransitions` interface method cannot do cross-workflow lookups and
  therefore returns empty — an honest disclosure of a real architectural boundary, not hidden.
- Read `b37_marketplace_dues_gate_test.dart`: 2 genuine widget tests, including the live-update case
  (pay dues via the Giving tab → navigate to Marketplace → borrow flips from "Waiting" to enabled),
  exercising the real widget tree end to end.
- Read the validator's new cross-type cycle test (`milestone_1_3_test.dart`): two genuinely distinct
  `workflowType`s (`equipment-loan`, `tabletop-club-dues-payment`) each requiring the other's
  completion, correctly flagged as a `dependency_cycle` — not just a same-type cycle.
- Fresh re-runs, all matched exactly: marketplace fixture validator pass/0/0; `dart analyze`
  `loom_workflow_engine`/`loom_ux_judges` clean; `dart test` engine 73/73, judges 27/27; `flutter
  analyze` (app_shell) clean; `flutter test` b37 2/2; combined app_shell+demo suite 114/114 (zero
  regressions).
- Live emulator walk on `PantryVision_Manual_API_36` (fresh debug APK build + install, real
  on-device interaction): on the same "Root" listing in the same session, confirmed the "Waiting"
  state before paying dues, then paid dues via the Giving tab's "Pay $15" → generic action-surface
  completion flow, then returned to the same listing and confirmed the button had flipped live to
  "Request loan" (enabled) — the full cross-workflow round trip, genuinely persisted and reflected.

**Milestone 3.2 is closed. Phase 3 is now fully complete — all of Milestones 3.1 and 3.2 are `[x]`
CLOSED.** Phase 4 (HOA / Cedar Commons, second community) begins next.

---

Wire `requiresWorkflowsComplete: ["tabletop-membership-dues-current"]` for real onto Marketplace's
`borrow` transition (the illustrative, commented-out example already present in the marketplace
`.jsonc` fixture) — treated as its own small sub-milestone with its own evidence, not a rider on
Milestone 3.1's bar, since it's the first genuine test of a guard that spans two different
`workflowType`s.

**Validation tests required to close this milestone:**
- [x] Unit test, dues-current path: a member whose dues workflow instance is in `paid` state sees
  `borrow` as available and can execute it successfully.
- [x] Unit test, dues-not-current path: a member whose dues workflow instance is in `unpaid` state
  does NOT see `borrow` execute — the button renders in the `waitingForPrerequisite`/"Waiting" state
  (Phase 1 §7b/§7d), not hidden and not silently allowed.
- [x] Unit test: the guard evaluator correctly resolves `requiresWorkflowsComplete` against a
  *different* `workflowType`'s instance data for the *same persona* — i.e. it looks up the dues
  instance belonging to the acting persona, not the marketplace listing's own instance, proving the
  cross-workflow lookup mechanism itself (not just the boolean gate) works.
- [x] Widget test: the waiting-state UX shows correctly in the Marketplace detail view when gated,
  and updates live once the member's dues instance transitions to `paid` (re-query or re-evaluate on
  next render — assert the specific mechanism used, whichever the implementation chooses).
- [x] Validator test: the §7c validator's dangling-reference and dependency-cycle checks (Phase 1
  §7c) both correctly evaluate `requiresWorkflowsComplete` across `workflowType` boundaries — confirm
  a genuinely cross-type cycle (dues requires marketplace requires dues) is caught, not just a
  same-type cycle.
- [ ] Live emulator walk: screenshot evidence of both paths (dues-current member can borrow;
  dues-not-current member sees waiting state) on-device, same session, same listing.
- [x] Full `flutter test` suite green, exact pass count cited.

**Implementation note (2026-07-07):** M3.2 is implemented and ready for independent verification.

**Implementation changes:**
- Added same-persona completed-workflow lookup to `LocalWorkflowEngineApi`, backed by a new database query over the persona's workflow instances.
- Enforced `requiresWorkflowsComplete` in real `applyTransition` calls, so a Marketplace `borrow` transition cannot execute until the acting persona's dues workflow is complete.
- Parsed and propagated `requiresWorkflowsComplete` from extension listing transitions into the generated engine transitions.
- Seeded the Marketplace path with the dues workflow definition when present, synced completion from the Giving tab, and kept non-marketplace workflow instances out of the Marketplace grid.
- Updated the live marketplace `.jsonc` fixture so the previously-commented dues gate is now real and validator-clean.
- Added M3.2 engine unit tests, Marketplace widget tests for Waiting-to-enabled behavior, and validator coverage for cross-type dependency cycles.

**Validation evidence:**
- [x] `dart analyze packages/core/loom_workflow_engine` - clean.
- [x] `dart analyze packages/core/loom_communities_app_shell` - clean.
- [x] `dart test packages/core/loom_workflow_engine/test/milestone_3_2_test.dart` - 3/3 passed.
- [x] `dart test packages/core/loom_workflow_engine` - 73/73 passed.
- [x] `dart analyze packages/tooling/loom_ux_judges` - clean.
- [x] `dart test packages/tooling/loom_ux_judges/test/milestone_1_3_test.dart` - 27/27 passed.
- [x] `dart test packages/tooling/loom_ux_judges` - 27/27 passed.
- [x] `flutter test apps/loom_communities_demo/test/b37_marketplace_dues_gate_test.dart` - 2/2 passed.
- [x] `flutter test packages/core/loom_communities_app_shell/test apps/loom_communities_demo/test` - 114/114 passed.
- [x] `dart run packages/tooling/loom_ux_judges/bin/workflow_state_machine_validator.dart --definitions ../docs/Build\ Plan\ V2/Loom\ Communities\ Workflow\ Engine\ V2/Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc` - `status: pass`, `errorCount: 0`, `warningCount: 0`, `findings: []`.
- [ ] Live emulator screenshot validation remains for the Verification Agent: dues-not-current Waiting path and dues-current borrow-enabled path on the same listing.

Waiting for Verification Agent result through `data/verification_feedback.md`.
