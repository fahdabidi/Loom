# Root Cause: engine-native Messages test failures

## Outcome: confident diagnosis

This is a **test-fixture/test-contract migration problem, not a real app defect**. More specifically, the fixture's seed data is already correctly expressed as specVersion 4 `workflowInstances`; the remaining stale part is the test's expectation that those instances will be rendered by the pre-v4 bespoke Messages widget.

A correctly shaped v4 package does render these threads. The second and third failing tests prove that directly: both `_openMessages` calls successfully find their unique seeded subject (`Persistence thread` and `Archive persistence thread`) before execution reaches the reported failures at lines 240 and 291. Those strings have no other source in the mounted experience. If the engine query had returned zero rows, both tests would instead have failed at `_openMessages` line 164, as the cardinality test does with its invalid `repeater-item-0` finder.

The apparent empty list is therefore a finder mismatch. All three `Bad state: No element` exceptions are raised by `ensureVisible`/tap operations on widgets that exist only in the legacy `_MessagesTabSurface`, which the presence of a v4 `messages` render binding deliberately makes unreachable.

## Exact mechanism

1. `v3_milestone_1_7_messages_test.dart:24-115` declares a valid engine-native definition and one `workflowInstances` seed per supplied thread. Each seed has a valid `instanceId`, `workflowType`, `currentState`, `createdByFanId`, and `instanceData`.

2. The seeds are installed before the Messages tab is queried. `activeAuthForInstalledCommunity` calls `experienceForExtensionId` at `authz_p6_test_helpers.dart:184-189`. `experienceForExtensionId` parses the v4 configuration and calls `_installEngineNativeExperience` at `part15_evidence_catalog.dart:9-17`. The parser reads `workflowInstances` at `part15_evidence_catalog.dart:144-153`, and `_EngineNativeCommunityStore._initialize` converts and persists them with `seedInstances` at `part25_engine_native_community_store.dart:234-260`.

3. The v4 Messages binding selects a different renderer from the one the test was written against. `_hasEngineNativeBinding(experience, 'messages')` is true because the fixture declares the binding at test lines 68-76. Consequently, the `MessagesTabSurface` dispatch at `part02_tab_shell.dart:1122-1132` returns `EngineNativeListSurface`; it does **not** return `_MessagesTabSurface` at lines 1133-1138.

4. `EngineNativeListSurface` obtains the already-installed shared engine at `part32_engine_native_list_surface.dart:53-59`. `EngineNativeBindingDispatcher._load` calls `engine.queryInstances(tabId: 'messages', personaId: ...)` at `part27_engine_native_binding_dispatcher.dart:149-168`, then resolves each instance's current-state binding at lines 185-217.

5. Nothing filters these fixture rows out:

   - The omitted workflow `visibility` block resolves to public visibility (`workflow_models.dart:734-746`), and `LocalWorkflowEngineApi.queryInstances` preserves the unfiltered path for public/omitted visibility (`local_workflow_engine_api.dart:279-303`).
   - The render binding has `audience: 'any'`, which always matches in `resolveBindings` (`binding_resolver.dart:17-23`).
   - Every seed is in `currentState: 'open'`, which is included in the binding's `states`.
   - Messages surface permission is always admitted by `personaHasPermission` (`part12_persona_and_tabs.dart:524-533`).

6. `discussionThread` has no bespoke case in `EngineNativeArchetypeCard`, so it intentionally reaches the schema-driven `GenericWorkflowInstanceCard` fallback at `part27_engine_native_binding_dispatcher.dart:321-323,446-458`. That card renders one card per seed, the subject field, the structured `messages` list, and transition buttons. This is the exact pipeline exercised by the passing `v3_milestone_phasef_messages_test.dart`.

7. The stale expectations each belong to the bypassed legacy surface:

   - **Cardinality failure, test line 164:** the ready finder is `repeater-item-0` from test line 196. `repeater-item-$index` is created only by `RepeaterSurface` (`repeater_surface.dart:191`). The v4 route creates `engine-native-list-item-messages-<instanceId>-<bindingIndex>` and `generic-instance-card-<instanceId>` instead. The threads can be present while `repeater-item-0` is necessarily absent.
   - **Post persistence failure, test line 240:** the test has already found and tapped `Persistence thread`, proving the seed rendered, but then looks for `messages-composer-field`. That key is owned by the legacy `_ThreadDetailView` (`part02_tab_shell.dart:638-675`). The v4 generic card exposes `post-message` as `generic-instance-persist-action-post-message`; tapping it opens `GenericTransitionInputDialog`, whose input/confirm keys are `generic-transition-input-body` and `generic-transition-input-confirm`. The passing Phase F test uses exactly that flow at `v3_milestone_phasef_messages_test.dart:156-172`.
   - **Archive persistence failure, test line 291:** the seeded subject was again found and tapped first. The test then looks for a legacy icon button with tooltip `Archive`. The generic path renders the transition through `WorkflowActionButtonRow` with key `generic-instance-archive-action-archive` and visible label `Archive`; it does not assign that button an `Archive` tooltip (`part18_marketplace_rendering.dart:1096-1166`).
   - The later `No messages yet` expectation at test line 298 is also legacy-only (`part02_tab_shell.dart:321-348`). An empty engine-native result is represented by `engine-native-list-empty-messages` / `engine-native-bindings-empty-messages-<personaId>` (`part32_engine_native_list_surface.dart:105-109` and `part27_engine_native_binding_dispatcher.dart:255-270`).

The historical split explains why the migration was incomplete: most of the behavioral assertions in this file still originate from the old Milestone 1.7 `RepeaterSurface`/composer test, while the fixture was later converted to `workflowDefinitions` and `workflowInstances`. Phase F is the authoritative v4 control and already asserts the replacement generic pipeline.

## Recommended fix

Change **only the test and its local test helpers** for this issue; do not change the App Shell renderer, workflow engine, or any community JSONC.

Use the Phase F setup and interaction contract:

1. Parse/install the test experience and await `workflowEngineForExtensionId` before pumping the widget, retaining the returned `WorkflowEngineApi` so persistence can be asserted directly. `activeAuthForInstalledCommunity` already performs the install side effect, but making initialization explicit and awaited removes timing ambiguity and matches the established Phase F SQLite/widget-test pattern.

2. For cardinality, wait for `engine-native-list-root-messages` or a known subject, then assert `generic-instance-card-one`, `generic-instance-card-two`, etc. (or query the retained engine and assert the returned instance IDs/count). Remove every `repeater-item-*` assertion and the obsolete `RepeaterSurface.live` timing comment.

3. For posting, do not tap the subject expecting a legacy detail view. Tap `generic-instance-persist-action-post-message`, enter the body in `generic-transition-input-body`, and tap `generic-transition-input-confirm`. Assert both the visible posted body and the retained engine instance's appended `messages` value. Reconstruct the full widget, reopen Messages, and assert the body is still rendered from that same shared engine instance.

4. For archiving, tap `generic-instance-archive-action-archive`. Wait for `generic-instance-card-archive`/the subject to disappear, and assert through the retained engine that the instance state is `archived`. Because this fixture intentionally declares only an `open` render binding, reconstructing the widget should still omit the archived card; wait for the engine-native empty marker or simply for the subject/card to remain absent. Do not wait for the legacy `No messages yet` text.

5. Adopt Phase F's bounded `tester.runAsync` pump helper for engine-backed asynchronous work. This test's current `_pumpUntilFound` silently falls through after its timeout and lets `ensureVisible` produce the uninformative `Bad state: No element`; the helper should instead throw a `TestFailure` naming the missing finder, as the Phase F helper does.

## Ownership and user impact

Ownership is the **app-shell test maintainer**. No production fix is indicated for the reported “no seeded threads” symptom.

A real user opening a correctly shaped v4 package reaches the engine-native Messages list and sees the seeded thread cards. Posts and archives go through real engine transitions and persist in the extension-scoped shared store. The failures here do not demonstrate an empty Messages tab; they demonstrate that a migrated v4 test is still searching for the retired legacy repeater, detail composer, archive tooltip, and empty-state widgets.
