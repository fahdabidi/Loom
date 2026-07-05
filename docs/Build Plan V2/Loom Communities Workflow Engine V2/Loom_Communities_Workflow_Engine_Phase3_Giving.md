# Phase 3 — Giving (Tabletop Club)

Part of [Loom_Communities_Workflow_Engine.md](./Loom_Communities_Workflow_Engine.md). Depends on
[Phase 1](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md) and
[Phase 2](./Loom_Communities_Workflow_Engine_Phase2_Calendar.md) being fully closed.

Status: not started.

## 1. Scope & goal

Also reuses Phase 1 infrastructure. Two things land: (1) a new `payment` `cardSurfaceFamily` template
migrating the dues-payment workflow onto the new engine; (2) the first real cross-workflow-type
dependency — `requiresWorkflowsComplete` (designed in
[Phase 1 §7b](./Loom_Communities_Workflow_Engine_Phase1_MarketplaceEngine.md#7b-cross-workflow-dependencies-get-a-real-field))
wired for real on Marketplace's `borrow` transition, gating it on the dues workflow being complete.

## 2. Milestones

### Milestone 3.1 — `payment` cardSurfaceFamily template + dues workflow migration
Migrate the dues-payment workflow onto the new engine: `unpaid`/`paid` states, a `pay` transition with
`linkedWorkflowId` firing the existing generic action-surface (that layer is already type-agnostic —
no change needed there).

**Validation tests required to close this milestone:**
- [ ] Unit test: the dues workflow fixture (`unpaid` → `pay` → `paid`) parses and passes the Phase 1
  §7c validator.
- [ ] Widget test: `paymentCheckout` archetype renders amount/purpose/recipient + pay action correctly
  from `instanceDataSchema`-declared fields, no hardcoded per-field Dart.
- [ ] Widget test: tapping `pay` fires the existing generic action-surface completion UI (via
  `linkedWorkflowId`) and, on completion, the dues instance transitions `unpaid` → `paid` — full round
  trip, not just the transition call in isolation.
- [ ] Full behavioral-parity widget-test suite against today's Giving tab (the b35 test suite's
  existing scenarios re-run against the new engine implementation): entitlement badge display, receipt/
  history view, retry/refund/manage-subscription alternates where applicable.
- [ ] Live emulator walk (WSL Ubuntu): screenshot evidence of the Giving tab on the new engine
  performing a pay round trip on-device.
- [ ] Full `flutter test` suite green, exact pass count cited, zero regressions elsewhere.

### Milestone 3.2 — Cross-workflow dependency: dues-current gate on Marketplace `borrow`
Wire `requiresWorkflowsComplete: ["tabletop-membership-dues-current"]` for real onto Marketplace's
`borrow` transition (the illustrative, commented-out example already present in the marketplace
`.jsonc` fixture) — treated as its own small sub-milestone with its own evidence, not a rider on
Milestone 3.1's bar, since it's the first genuine test of a guard that spans two different
`workflowType`s.

**Validation tests required to close this milestone:**
- [ ] Unit test, dues-current path: a member whose dues workflow instance is in `paid` state sees
  `borrow` as available and can execute it successfully.
- [ ] Unit test, dues-not-current path: a member whose dues workflow instance is in `unpaid` state
  does NOT see `borrow` execute — the button renders in the `waitingForPrerequisite`/"Waiting" state
  (Phase 1 §7b/§7d), not hidden and not silently allowed.
- [ ] Unit test: the guard evaluator correctly resolves `requiresWorkflowsComplete` against a
  *different* `workflowType`'s instance data for the *same persona* — i.e. it looks up the dues
  instance belonging to the acting persona, not the marketplace listing's own instance, proving the
  cross-workflow lookup mechanism itself (not just the boolean gate) works.
- [ ] Widget test: the waiting-state UX shows correctly in the Marketplace detail view when gated,
  and updates live once the member's dues instance transitions to `paid` (re-query or re-evaluate on
  next render — assert the specific mechanism used, whichever the implementation chooses).
- [ ] Validator test: the §7c validator's dangling-reference and dependency-cycle checks (Phase 1
  §7c) both correctly evaluate `requiresWorkflowsComplete` across `workflowType` boundaries — confirm
  a genuinely cross-type cycle (dues requires marketplace requires dues) is caught, not just a
  same-type cycle.
- [ ] Live emulator walk: screenshot evidence of both paths (dues-current member can borrow;
  dues-not-current member sees waiting state) on-device, same session, same listing.
- [ ] Full `flutter test` suite green, exact pass count cited.
