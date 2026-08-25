# Root-cause diagnosis: the result was never anchored

## Outcome

Confident root-cause diagnosis with a concrete recommended fix.

This is not evidence of nondeterministic product rendering. The capture harness does not contain the result-positioning code that the Run A evidence commit says it used. Run A happened to capture the badge in its unanchored viewport; Run B's new visible gate inspected the equally unanchored viewport, failed before the result capture, and therefore never produced a comparable result frame.

## Decisive evidence

1. Commit `162e4597` is titled `re-capture Camera with result frames anchored to the subject`, but its diff changes only four evidence files:

   - `docs/Build Plan V2/Evidence/B15/workflow-ui-evidence.json`
   - `docs/Build Plan V2/Evidence/B20/all-workflow-ui-evidence.json`
   - `docs/Build Plan V2/Evidence/B20/flutter-drive-workflow-ui-evidence.log`
   - `docs/Build Plan V2/Evidence/B25/b25-capture-progress.json`

   It changes no Dart file. Searching the repository and the history of `workflow_ui_evidence_test.dart` finds no `_positionShippedResultForCapture` definition or call.

2. In the `162e4597` snapshot, `_finishB25WalkthroughAfterPrimary` calls `tester.ensureVisible(alternate.finder.first)` at line 1668, taps the alternate, verifies the engine result, and calls `capture(result)` at line 1725. There is no scroll or positioning operation between the alternate-action capture and the result capture.

3. In `3940c001`, the same sequence remains. The alternate is positioned at line 1839. After the transition, the engine assertion runs at lines 1877-1883 and the new viewport gate starts at line 1884. `capture(result)` is later, at line 1909. Again, there is no post-transition `ensureVisible` or result-positioning call before either the gate or the capture.

4. The Windows run log emitted four `screenshot-start` events for `critique-submission`: `start`, `primary_action`, `primary_result`, and `alternate_action`. It then emitted the visible-postcondition failure. It emitted no `result_receiver` event. The generated B15 manifest accordingly has `workflowCount: 0`, `requestedScreenshotCount: 4`, and an empty `workflows` array. Its zero occurrences of `Critique withdrawn` do not establish that the label was absent from the widget tree; the failed row and its never-requested result frame are absent from the manifest altogether.

5. The product widget has stable instance identity across the transition. `EngineNativeListSurface` keys the card with the tab, instance id, and binding index; `GenericWorkflowInstanceCard` keys its state badge with `generic-instance-state-<instanceId>`. Its build reads `widget.machine.states[_instance.currentState]` and renders that state's label. Nothing in this path keys the card or badge by current state. The engine-native dispatcher also retains its last successful bindings while it refreshes after `onInstanceChanged`. A state-dependent re-key is therefore not the mechanism exposed by the committed code.

## Mechanism

`tester.ensureVisible(alternate.finder.first)` deliberately leaves the outer list positioned around the alternate control, which is near the lower part of the subject card. Withdrawing the critique rebuilds that card and removes its action controls. That changes the card and list geometry, but the harness never establishes where the source card's top/status badge is relative to the viewport after the reflow.

Run A continued directly to `capture(result)` and, in that particular unanchored layout, the physical viewport included `Critique withdrawn`. That was a valid image of one incidental viewport position, not proof that the harness had anchored the result.

Run B inserted `_expectVisibleShippedAlternateStatePostcondition` before `capture(result)`. `_visibleShippedResultSurfaces` correctly scopes candidates to the `EngineNativeArchetypeCard` for `critique-lighthouse-portrait`, and `_visibleTextValuesWithin` deliberately retains only hit-testable `Text` render objects. Thus a state badge outside the physical viewport is excluded even though its card can remain built in the scrollable widget tree. The gate polls that unchanged, unanchored viewport and fails. Because failure precedes `capture(result)`, Run B has no result image with which to demonstrate a rendering difference.

Device-persisted list contents or timing can alter the incidental geometry and therefore amplify the symptom, but neither is required for it. The load-bearing defect is that the post-transition viewport has no deterministic semantic anchor. The two runs also did not use an identical capture harness: `3940c001` adds the pre-capture gate, while `162e4597` lacks it; neither committed snapshot contains the claimed positioning helper.

## Recommended fix

Add the missing post-transition positioning operation and make the visible gate and PNG capture observe the same positioned frame:

1. After the engine postcondition and the refreshed source instance are available, locate a semantic result anchor for that exact instance.
2. For a state-changing result, use the stable state-badge key `generic-instance-state-<instanceId>` (or an equivalent instance-scoped state-label finder), call `tester.ensureVisible` on that badge, and pump the resulting scroll/rebuild frames.
3. Only then run `_expectVisibleShippedAlternateStatePostcondition`. Capture `result_receiver` immediately after it, without another navigation or scroll, so the assertion and image prove the same viewport.
4. Do not merely call `ensureVisible` on an entire tall instance card: Flutter may satisfy that request while leaving the card's top/status badge outside the viewport. Anchor the exact postcondition the frame is supposed to prove.
5. For a removal-shaped result where the source instance legitimately no longer exists, first establish that removal as the engine postcondition, then anchor a stable enclosing list/tab surface and capture the honest absence. Do not skip the frame and do not treat a missing subject as an implicit pass.

The same ordering must be used for every primary and alternate result capture: engine proof, semantic result positioning, visible proof, then capture. Adding logging cannot make the present sequence reliable; the missing positioning behavior must be implemented and committed.

## Runtime limitation

This VM has no Android emulator, so I did not perform a new device run. No new instrumentation was necessary for this diagnosis: the existing Windows test failure is system-emitted runtime evidence, and the two committed source snapshots conclusively show that the claimed result anchor is absent and that Run B aborts before a result frame is requested.
