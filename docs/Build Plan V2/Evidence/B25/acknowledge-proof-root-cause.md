# `acknowledge-proof` root-cause trace request

## Outcome: precise instrumentation request

I cannot make a confident root-cause diagnosis from the captured output. The
Android capture cannot run on this VM, and the committed Windows log records
only that the button existed before and after `tester.tap`; it does not record
whether the button callback fired, whether `applyTransition` was entered, or
which error the generic card caught. Those are the facts that distinguish a
missed tap, an availability/guard disagreement, and a stale post-mutation UI.

Do not implement a behavior change yet. Add the temporary traces below, run the
single Windows shard described below, return the complete `B25_ACK_*` output,
and then remove the temporary traces before an implementation ticket is
applied.

## What source inspection establishes before tracing

The leading actor-mismatch hypothesis is not supported by the static data path:

- The shipped seed `ad-off-suppression-proof` has
  `memberFanId = "ad-off-member"`, `createdByFanId = "ad-off-member"`, and
  state `unreviewed`.
- `_transitionAccountId` in
  `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart:3117`
  reads the transition's `actorEqualsField` from the seed. For this row it
  returns `ad-off-member` because `_fanIdMatchesRole` accepts exact equality.
- `_shippedWorkflowSelector` stores that value as `selector.accountId` at
  `workflow_ui_evidence_test.dart:2697-2726`; the walkthrough seeds and signs in
  an account with that exact ID at lines 1345-1363.
- `LocalExtensionScreen._activeFanId` at
  `app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:208`
  prefers the signed-in account ID, and `_activeActorIdentity` passes it to the
  engine-native surface at lines 637-658.
- The action availability path does not stop at `allowedRoleIds`.
  `LocalWorkflowEngineApi.availableTransitionsAsync` calls the shared
  transition evaluator at
  `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:821-871`.
  That evaluator calls `evaluateGuard`, whose `actorEqualsField` comparison is
  explicit at
  `app/packages/core/loom_workflow_engine/lib/src/evaluator/guard_evaluator.dart:43-47`.
  `applyTransition` resolves through the same evaluator at
  `local_workflow_engine_api.dart:969-999`.

Therefore the package seed contains an actor the walkthrough can assume, and
the availability implementation is written to consult both guard clauses. The
missing runtime evidence is whether those paths received the values the source
code predicts, and whether the tap reached them at all.

## Temporary trace points

Use one line per event, prefixed exactly as shown, so the output can be ordered
without relying on surrounding Flutter/Android noise.

### 1. Record the selector's intended actor

In
`app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`,
immediately after constructing `selector` at lines 2717-2727 and before either
return path, emit `B25_ACK_SELECTOR` with:

- `workflowType`
- `instanceId`
- `seedCurrentState`
- `roleId`
- `selectorAccountId`
- `memberFanId = instance.instanceData['memberFanId']`
- `createdByFanId`
- `bindingTabId`
- every selected transition ID
- for `acknowledge-proof`, `allowedRoleIds`, `actorEqualsField.key`, and the
  value read from that field

The expected values from the shipped package are
`roleId=ad-off-member`, `selectorAccountId=ad-off-member`, and
`memberFanId=ad-off-member`.

### 2. Record the account that actually became active

In the same file, immediately after `signInEvidenceAccount` returns at line
1363, obtain the rendered `LocalExtensionScreen` and emit
`B25_ACK_SIGNED_IN` with:

- `selectorAccountId`
- `selectorRoleId`
- `screen.authApi.currentSession?.account.accountId`
- `screen.authApi.currentSession?.account.roleId`
- `selector.instance.instanceData['memberFanId']`

This distinguishes correct selector derivation from stale or failed auth-state
publication. The three actor/account values must all be `ad-off-member`.

### 3. Record whether the tap target is hittable

In the same file, immediately before `tester.tap` at line 1494, emit
`B25_ACK_TAP_TARGET` with:

- `visibleAction.candidate.transition.id`
- `visibleAction.finder.evaluate().length`
- `visibleAction.finder.hitTestable().evaluate().length`
- the target widget key
- `tester.getRect(visibleAction.finder.first)`
- the current physical/logical test view size

Immediately after `tester.tap` returns, emit `B25_ACK_TAP_RETURNED`.
`TAP_RETURNED` means only that the test API returned; the callback trace below
is the proof that the tap landed.

### 4. Record availability and the button callback

In
`app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart`:

1. Immediately after `availableTransitionsAsync` returns at lines 193-199,
   emit `B25_ACK_CARD_AVAILABILITY` when
   `instance.instanceId == 'ad-off-suppression-proof'`. Include
   `instanceId`, `instance.currentState`, `fanId`,
   `instance.instanceData['memberFanId']`, `generation`, `request`, and every
   returned transition ID.
2. At the first statement of `_applyTransition` at line 278, before looking up
   the transition, emit `B25_ACK_BUTTON_CALLBACK` with `transitionId`,
   `_instance.instanceId`, `_instance.currentState`, `widget.fanId`,
   `_instance.instanceData['memberFanId']`, `_mutating`, and `mounted`.
   This event is the definitive proof that the tap landed and propagated from
   `WorkflowActionButtonRow`.
3. Immediately before `engine.applyTransition` at lines 300-307, emit
   `B25_ACK_CARD_DISPATCH` with the same actor/instance/state values.
4. Immediately after it returns, emit `B25_ACK_CARD_RESULT` with
   `result.newState` and `result.newInstanceData['acknowledgedAt']`.
5. Change only the temporary catch binding at line 345 from the discarded
   error to `(error, stackTrace)` and emit `B25_ACK_CARD_ERROR` with the error
   runtime type, exact message, and stack trace before preserving the existing
   error UI behavior.

### 5. Record both guard clauses at availability and apply time

In
`app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart`,
filter these traces to `workflowType == 'ad-off-ad-suppression'` and
`instanceId == 'ad-off-suppression-proof'`:

1. In `availableTransitionsAsync`, around the evaluator call at lines 835-844,
   emit `B25_ACK_ENGINE_AVAILABLE` with `fanId`,
   `roleId = _roleIdByFanId[fanId]`, `currentState`,
   `instanceData['memberFanId']`, the declared `allowedRoleIds`, and two
   explicit booleans:
   `roleClausePass = allowedRoleIds.contains(_roleIdByFanId[fanId])` and
   `actorEqualsClausePass = fanId == instanceData['memberFanId']`.
   After the filtering loop at line 869, include both the evaluator candidate
   IDs and final result IDs.
2. At the first line of `applyTransition` (line 900), emit
   `B25_ACK_ENGINE_APPLY_ENTER` with the four call arguments. Immediately after
   `_requireSurfacePermission` at line 908, emit
   `B25_ACK_ENGINE_PERMISSION_PASS`.
3. In `_resolveTransition`, after loading `row`, `data`, and
   `declaredTransition` (lines 958-983), emit `B25_ACK_ENGINE_RESOLVE` with
   `row.currentState`, `fanId`, `_roleIdByFanId[fanId]`,
   `data['memberFanId']`, the declared guard values, the same two clause
   booleans, and the evaluator's candidate IDs.
4. Immediately after the transaction completes at line 926, emit
   `B25_ACK_ENGINE_COMMIT` with `result.newState` and
   `result.newInstanceData['acknowledgedAt']`.

These values identify `allowedRoleIds`, `actorEqualsField`, surface permission,
and any pre-state rejection separately. There is no formula or other declared
guard on `acknowledge-proof`.

### 6. Record persisted state and every surviving button

In `workflow_ui_evidence_test.dart`, immediately before the assertion at lines
1520-1530:

- read the source instance again through the shared engine and emit
  `B25_ACK_POST_TAP_STATE` with its persisted `currentState` and
  `acknowledgedAt`;
- emit `B25_ACK_SURVIVING_ACTIONS` with the number of elements matched by
  `visibleAction.finder`, each matched widget key, whether each match is
  hit-testable, and the keys of its ancestor generic instance card and
  engine-native tab binding surface;
- include whether each match has an `Offstage` ancestor.

This distinguishes an engine failure from an accepted mutation followed by a
stale or offstage copy of the source-state action.

## Exact Windows scenario

Run the same diagnostic shard that failed, through the B25 capture CLI:

```powershell
cd C:\LoomWin\app
dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode targeted-precheck --phases B16 --communities ext_ad_free_community --shards 12 --only-shard 4 --device emulator-5554
```

Preserve the complete console output and
`docs/Build Plan V2/Evidence/B20/flutter-drive-workflow-ui-evidence.log`. Do
not use a raw integration-test command; the B25 CLI is the path that reproduces
the Windows capture interaction and screenshot timing.

## How the trace decides the cause

### Missed tap

`B25_ACK_TAP_TARGET` shows zero hit-testable matches, or
`B25_ACK_BUTTON_CALLBACK` is absent. No card dispatch or engine-apply event
follows. This confirms the harness tap did not land; neither package guards nor
engine application caused the unchanged state.

### Actor or role rejected

The callback and dispatch events are present, followed by
`B25_ACK_ENGINE_RESOLVE` and `B25_ACK_CARD_ERROR`, but no commit event.

- `roleClausePass=false` identifies the `allowedRoleIds` rejection and the
  logged role mapping shows why.
- `roleClausePass=true` with `actorEqualsClausePass=false` identifies the
  `actorEqualsField` rejection. Comparing `SELECTOR`, `SIGNED_IN`,
  `CARD_DISPATCH`, and `ENGINE_RESOLVE` identifies whether the wrong value came
  from selector derivation, auth-state propagation, or persisted instance
  data.
- If both clauses pass but the permission event is absent and the card error
  says permission denied, this is a surface-authorization disagreement, not a
  workflow guard failure.

### Availability offered an ineligible action

`B25_ACK_ENGINE_AVAILABLE` reports either guard-clause boolean false while its
final result IDs still contain `acknowledge-proof`. That is an availability
defect. If engine availability omits it but `CARD_AVAILABILITY` includes it,
the wrong engine/result or stale action publication is in use above the
engine.

### Engine accepted, UI remained stale

`B25_ACK_ENGINE_COMMIT` and `B25_ACK_POST_TAP_STATE` both report `reviewed`, but
`B25_ACK_SURVIVING_ACTIONS` still finds `acknowledge-proof`. The ancestor keys
and offstage status then identify whether the assertion is seeing the active
card, a retained pre-refresh card, or another tab/binding copy.

### Package defect

Classify this as a package defect only if the trace shows that the live seeded
`memberFanId` cannot be represented by a selectable/signed-in account or is
different from the package value inspected above. If the selector and signed-in
account both equal the live field, the package actor binding is coherent and
the failure lies in dispatch, authorization, engine/UI synchronization, or the
test tap.

## Why no diagnosis is claimed yet

The existing Windows log proves only: the action was rendered before the tap,
the test called `tester.tap(..., warnIfMissed: false)`, and the same finder
matched one widget roughly 1.2 seconds later. The generic card intentionally
turns every mutation exception into the same user-facing retry message and
discards the error object, while `warnIfMissed: false` suppresses the other
decisive signal. Without the trace above, choosing between those mechanisms
would be inference rather than system-emitted evidence.
