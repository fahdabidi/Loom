# Root cause — Member can focus an Owner-only editable field

## Outcome: confident root-cause diagnosis and recommended fix

The defect is a deterministic missing authorization check in `GenericWorkflowInstanceCard`, not a stale Owner role left behind by persona switching. The Export/Migration Home card never reaches the calendar event editor at `part28_engine_native_calendar_surface.dart:1632`; it reaches the generic instance card, whose `_editableKeys` implementation does not inspect `LoomWorkflowState.editGuard` and does not receive a role at all.

Confidence is high because the complete render path and both sides of the local write path are statically closed: the package declares a guarded editable field, the generic renderer unconditionally turns that field into an enabled `TextField`, and the local engine independently checks the same guard before its first mutation.

## Exact render path and failure mechanism

1. The affected instance is `export-redacted-bundle` in state `complete`. The current package declares `editableFields: ["redactionValidationResult"]` and an `editGuard` allowing only `portability-owner` at `Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc:1262-1266`.
2. That workflow's Home binding is `cardSurfaceFamily: "statusTimeline"` at the same asset's lines 1461-1466.
3. The Home tab has no explicit non-default renderer. `_rendererContractIdForDeclarativeTab` / `_derivedRendererContractIdForTab` in `part12_actor_identity_and_tabs.dart:321-360` therefore derives the default `engine-native-generic-list` contract (`app_shell_capabilities.dart:59-70`). `_TabNativeRenderer` dispatches that contract to `EngineNativeListSurface` at `part02_tab_shell.dart:1108-1116`.
4. `EngineNativeListSurface.build` resolves the signed-in account ID as `fanId` and passes both that ID and `widget.actorIdentity.roleId` to `EngineNativeArchetypeCard` (`part32_engine_native_list_surface.dart:107-123, 175-200`). Thus the correct Member role is available at the card dispatcher.
5. `EngineNativeArchetypeCard` has no bespoke `statusTimeline` branch, so its `default` case creates `GenericWorkflowInstanceCard` (`part27_engine_native_binding_dispatcher.dart:471-499`). Although `EngineNativeArchetypeCard` itself has a required `roleId`, this call does not forward it because `GenericWorkflowInstanceCard` has no role property.
6. `_GenericWorkflowInstanceCardState._editableKeys` at `part26_generic_instance_card.dart:104-115` filters only the state's `editableFields`, schema existence, formula/machine ownership, and conditional visibility. It never reads `state.editGuard` and never calls `evaluateGuard`. Consequently `redactionValidationResult` is returned for Owner and Member alike.
7. `GenericWorkflowInstanceCard.build` renders editors whenever `showEditors` is true and that list is non-empty (`part26_generic_instance_card.dart:557-582`). The Home list call uses the defaults `EngineNativeArchetypeCard.showEditors == true` and `GenericWorkflowInstanceCard.showEditors == true`. `_editor` then builds the ordinary text schema as a `TextField` whose `enabled` value is only `!_mutating` (`part26_generic_instance_card.dart:654-660, 743-759`). No authorization state participates in `enabled`, which precisely explains the enabled field, cursor, focus underline, and soft keyboard seen in the walkthrough. The Save button is produced by the same unchecked list.

The same mechanism explains the Member-visible `verificationResult` editor on the complete `export-full-bundle` card: it is another guarded `editableFields` declaration rendered through the same `statusTimeline` generic fallback.

## Why the stale-role hypothesis is ruled out

The local persona flow refreshes role state from the newly signed-in account:

- `LocalAuthApi.signUp` constructs the account with the selected `roleId`, makes that account the current session, and gives it a unique role-prefixed account ID (`part30_local_auth_api.dart:139-175`).
- `LocalExtensionScreen._activeRoleId` reads `currentSession.account.roleId`, not the prior manual selection (`part01_local_extension_screen.dart:214-225`). `_activeActorIdentity` resolves its `roleId` from that current value and carries the current account ID (`part01_local_extension_screen.dart:725-747`).
- The specific-person sign-up callback runs `_refreshCommunityEntryGate(rebuildAuthScreen: true)` (`part01_local_extension_screen.dart:1157-1175`). That refresh withholds the community content while it awaits `_ensureEngineAuthorizationSync` (`part01_local_extension_screen.dart:298-315, 1258-1283`).
- The rebuilt screen passes this newly resolved actor identity to `_TabNativeRenderer` (`part01_local_extension_screen.dart:1294-1306, 1757-1778`), and `EngineNativeListSurface` forwards its role to `EngineNativeArchetypeCard` as described above.

The live observation that Member saw only Home and Messages is independent confirmation that this upstream `activeActorIdentity.roleId` was `portability-member`; the same value drives tab visibility. A stale `portability-owner` value would have retained the five Owner-visible tabs. The role is correct at `EngineNativeArchetypeCard` and is then discarded specifically at the generic-card boundary.

## Safety-critical write-path verdict

For the local engine used by the observed bundled Demo App, a Member save would be rejected with `WorkflowAuthorizationError` before any persisted data is changed. This conclusion does not depend on UI-supplied role data.

The call chain is:

1. `GenericWorkflowInstanceCard._save` calls `engine.updateInstanceFields` with the signed-in `fanId` (`part26_generic_instance_card.dart:221-275`). `EngineNativeListSurface` obtained that ID through `ActiveIdentityScope.resolveEngineFanId`, which prefers the current signed-in account ID (`part25_engine_native_community_store.dart:20-21, 82-84`; `part32_engine_native_list_surface.dart:107-109`).
2. Before content is restored after sign-up, `_syncEngineRoleIds` lists all community accounts and calls `LocalWorkflowEngineApi.setRoleForFan(account.accountId, account.roleId)` (`part01_local_extension_screen.dart:578-619`). Sam's unique account ID is therefore mapped to the singleton set `{portability-member}`. Even a missing map entry would fail closed, because `evaluateGuard` treats absent/empty roles as no allowed role.
3. `LocalWorkflowEngineApi.updateInstanceFields` reloads the persisted row and its current state, obtains that state's `editGuard`, and calls `_passesGuard` before validating or merging updates (`local_workflow_engine_api.dart:1645-1687`).
4. `_passesGuard` supplies `_roleIdsByFanId[fanId]` as `roleIds` to `evaluateGuard` (`local_workflow_engine_api.dart:1813-1843`). `evaluateGuard` requires at least one effective role to occur in `allowedRoleIds` and returns false otherwise (`guard_evaluator.dart:29-37`). `{portability-member}` does not intersect `{portability-owner}`.
5. The resulting `WorkflowAuthorizationError` is thrown at `local_workflow_engine_api.dart:1683-1685`. Execution never reaches `data.addAll(fieldUpdates)` or `_db.updateInstanceState` at lines 1710-1715.

There is already a focused engine test of this mechanism in `loom_workflow_engine/test/cal_calendar2_guard_enforcement_test.dart:49-75`: a Member role attempting an Owner/organizer-guarded editable-field update is expected to receive `WorkflowAuthorizationError`. No live write against seeded data is needed to establish the local engine behavior.

Therefore this observed bug is an authorization-affordance defect, not a local-engine privilege escalation. If the user had typed and pressed Save, the generic card would have caught the engine exception and shown its generic save failure; the seeded field would have remained unchanged.

## Recommended implementation fix

Make the generic card enforce every present state `editGuard` before it derives or renders editable fields:

1. Add the current role to `GenericWorkflowInstanceCard` as an explicit required input. In both generic construction sites in `EngineNativeArchetypeCard` (`part27_engine_native_binding_dispatcher.dart:395-422` and `471-499`), forward the dispatcher's already-required `roleId`. Do not obtain the role from the old calendar widget or from process-global selection state.
2. In `_GenericWorkflowInstanceCardState._editableKeys`, read `state?.editGuard` before enumerating fields. If a guard is present, call `evaluateGuard(guard, widget.fanId, currentInstanceData, roleId: widget.roleId)` and return an empty list when it fails. This preserves the existing behavior of states with no `editGuard` while enforcing every explicitly declared guard. For the affected state, Member then gets no editor and no Save button; Owner retains both.
3. Include `roleId` in `didUpdateWidget`'s authorization-context invalidation and clear controllers/unsaved edits when it changes. The observed persona change also changes `fanId`, but invalidating on role directly prevents retained edit state if an account's membership changes without its account ID changing.
4. Add a generic-card widget regression test using a state with `editableFields` plus an Owner-only `editGuard`: assert that the editor and Save button are absent for Member and present for Owner. Exercise the production dispatcher path with `cardSurfaceFamily: statusTimeline`, not the calendar event card, so the test covers the boundary that dropped the role. Keep or add the engine assertion that a direct Member `updateInstanceFields` call throws and leaves the stored value unchanged.

For this app's current single-role account model, `activeActorIdentity.roleId` is the correct render-time source: it comes directly from the signed-in session and is already at `EngineNativeArchetypeCard`. The UI should not reach into the local engine's private `_roleIdsByFanId`; that would couple rendering to one engine implementation, and the engine must remain the final authority on every write. If multi-role UI authorization is later exposed, it should be added as an authenticated role-set/authorization capability across `WorkflowEngineApi`, not inferred from a widget-selected label.
