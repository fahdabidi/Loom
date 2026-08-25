# Camera Club alternate-action root cause

## Outcome: confident root-cause diagnosis and recommended fix

The two failed screenshots are not caused by a missed tap, an undispatched transition, or an engine rejection. Both transitions reach the engine and are applied. The defect is at the rendering/evidence boundary: the capture harness accepts a persisted state or data mutation as action proof even when the captured surface does not render a semantic result of that mutation.

For `critique-submission`, the post-transition card stops rendering the available actions but never renders its new `withdrawn` state. For `gear-loan-request`, the engine appends the damage report to `issueLog`, but that field is declared for the detail context and is filtered out of the marketplace tile that the walkthrough captures. The tile therefore remains semantically unchanged.

This is a third cause, not either of the two proposed suspects.

## System-emitted evidence

The committed capture manifest reports `b25ActionProofStatus: pass`, `assertionStatus: pass`, and `screenshotStatus: complete` for all three Camera Club workflows. Those statuses are significant because the harness emits them only after its live-engine postcondition checks return successfully.

The same manifest's captured visible-text snapshots show:

- `photo-walk-rsvp`: the alternate frame shows `2 / 12 going`, the evidence member in Going, and a `Maybe` action. The result shows `1 / 12 going`, moves the evidence member to Maybe, and reverses the enabled/disabled action state. This is a visible semantic state change.
- `critique-submission`: the alternate frame contains the Lighthouse submission with `2 comments`, `Reply`, and `Withdraw critique`. The result still contains the same Lighthouse submission and `2 comments`, but the two actions are absent. The screenshots otherwise show the list at a different scroll offset. The transition changed the action set, but there is no rendered label identifying the resulting state.
- `gear-loan-request`: the alternate and result visible-text snapshots are identical. The screenshots differ only in scroll position.

No temporary instrumentation was added. The existing capture already emitted both sides needed for this diagnosis: its live-engine postcondition result and its visible-text/screenshot result. This VM has no Android emulator, so I could not rerun the device capture here.

## Tap, dispatch, and engine application

### `critique-submission` / `withdraw`

The tap lands and the transition is dispatched and applied.

The transition has no required inputs. `_classifyShippedTransition` classifies it as `stateChanging`, because it moves the source instance from `submitted` to `withdrawn`. For a self-shaped workflow with a non-null source instance, the alternate leg then calls `_expectShippedInstanceState` and polls the shared engine until that exact target state is present. The manifest records the assertion and action proof as passing. A missed tap, missing dispatch, rejected transition, or failed write would leave the instance in `submitted` and make that poll fail rather than emit a passing result.

The final visible-text snapshot independently corroborates the mutation: the actions available in `submitted` disappear after the transition.

### `gear-loan-request` / `report-damage`

The tap lands and the transition is dispatched and applied.

`report-damage` requires `issueDescription`. After the action tap, `_completeShippedTransitionInputs` waits for the engine-native input dialog, fills the required field, confirms it, and checks for validation failure. A missed action tap would therefore fail while waiting for the dialog rather than continue successfully.

The transition has no `to` state and has a direct source-instance `append` effect on `issueLog`, so `_classifyShippedTransition` returns `sourceInstanceEffect`. The alternate leg consequently calls `_expectShippedInstanceDataChanged` and polls the shared engine until the source instance's serialized data differs from its pre-action data. The manifest records that assertion and action proof as passing. A missed confirm tap, an undispatched transition, an engine rejection, or an unapplied effect would leave the data unchanged and fail that check.

The engine's normal application path validates the transition, guard, and inputs, applies the transition and effects in a transaction, persists the updated instance, and returns the updated state/data to the card. Both the generic card and equipment-loan card catch application failures and surface an error instead of manufacturing a successful engine result. The successful persisted postcondition therefore establishes that the engine applied both transitions.

## Why the applied results do not render differently

### Critique: the generic card does not render current state

The Camera package binds the submitted critique and the withdrawn/reviewed summary to `statusTimeline`, but `EngineNativeArchetypeCard` has no dedicated `statusTimeline` case. It falls through to `GenericWorkflowInstanceCard`.

That generic card renders schema fields, editors, progress/errors, and currently available actions. It does not render the instance's `currentState` or the corresponding declared state label/tone. Once `withdraw` changes `submitted` to `withdrawn`, the action buttons disappear, shortening the card and shifting the list, but the card supplies no positive outcome such as `Critique withdrawn`. This precisely accounts for the system-emitted result: same content and count, absent buttons, and a changed scroll offset.

### Gear loan: the changed field is detail-only

`report-damage` keeps the instance in `published` and appends the submitted issue to `issueLog`. The `issueLog` schema is labelled as a reported-issue count, is hidden when empty, and declares only the `detail` display context.

The walkthrough captures the marketplace tile. The equipment-loan card's fact-schema selection filters out fields whose `displayContexts` do not include the active widget context, so the changed `issueLog` is not present on that tile. Because the state stays `published`, the action remains available as well. The engine data changes, but no changed value, new state, or success acknowledgement appears on the captured surface. This accounts for the byte-identical visible-text snapshots and the scroll-only visual change.

### Photo RSVP: a bespoke renderer exposes the state change

The selected alternate is `respond-maybe` on the paired `photo-walk-response` machine. It changes the response from Going to Maybe and `_classifyShippedTransition` returns `stateChanging`. That classification is correct. The event-RSVP renderer exposes the result through attendee grouping/counts and selected action state, so the captured output visibly proves the transition even though the paired shape is outside the self-shaped postcondition branch.

## Classification audit

| Workflow | Alternate transition | Classification | Correct? | Verification path |
| --- | --- | --- | --- | --- |
| `photo-walk-rsvp` | `respond-maybe` | `stateChanging` | Yes; the response state changes from Going to Maybe. | Paired action/source machine, so the self-shaped live-engine branch is not entered; the rendered result nevertheless changes visibly. |
| `critique-submission` | `withdraw` | `stateChanging` | Yes; `submitted` changes to `withdrawn`. | `_expectShippedInstanceState(..., withdrawn)` runs and passed. |
| `gear-loan-request` | `report-damage` | `sourceInstanceEffect` | Yes; there is no target state and the transition appends to source-instance `issueLog`. | `_expectShippedInstanceDataChanged` runs and passed. |

The unchecked third classification path is therefore not responsible for either failure. Both failing workflows enter one of the two asserted branches. The classifications themselves are correct.

## Disposition of the two proposed suspects

- `warnIfMissed: false` did not hide a missed tap in these two captures. The critique state assertion and the gear required-input plus data-change assertions could not all pass after a missed tap.
- The verification fall-through did not apply. `withdraw` is `stateChanging`; `report-damage` is `sourceInstanceEffect`. Each invokes and passes a live-engine postcondition check.

`warnIfMissed: false` and the unchecked classification case are still weak harness behavior worth hardening separately, but changing either alone would not make these two results observable.

## Concrete recommended fix

Change the product rendering and the capture proof contract together:

1. Make the critique result explicit. Either add a real `statusTimeline` dispatch/card or change `GenericWorkflowInstanceCard` to persistently render the current state's declared label and tone. The post-withdraw card must show a semantic result such as `Critique withdrawn`; disappearing controls alone are not adequate action evidence.
2. Make the damage-report result visible on the surface used for evidence. After the `report-damage` source effect succeeds, render a persistent acknowledgement or schema-derived changed value on the marketplace tile (for example, the reported-issue count), or deliberately navigate to and capture the detail surface where `issueLog` is declared visible. Do not silently retake or accept the unchanged tile.
3. Strengthen the alternate-leg evidence check after the existing engine assertion. For a `stateChanging` transition, require the target state's declared label to be visible for the source instance before capturing `result_receiver`. For a `sourceInstanceEffect`, compute the changed data keys and require either a changed key's rendered value or an explicit success acknowledgement on the captured surface. If every changed key is excluded by the active display context, navigate to the declared context or fail loudly with the changed keys and their display contexts.
4. Add regression coverage that proves `withdraw` renders its resulting state, `report-damage` renders or navigates to its persisted issue result, and a backend-only mutation with no visible semantic postcondition cannot receive `b25ActionProofStatus: pass`.

As harness hardening, make a missed hit test fail loudly rather than suppressing `tester.tap` warnings, and make unverified classifications fail rather than fall through. Those changes prevent future false evidence, but they are safeguards rather than the root fix for these two already-applied transitions.
