# Root cause: authenticated role-picker selections are shadowed, and the marketplace test is a loading-frame false positive

**Outcome: confident root-cause diagnosis and recommended fix.**

## Diagnosis

The B25 walkthroughs observed the real behavior: after an account is signed in, tapping a different role in `Account role and permissions` does not change the effective role, the effective fan/account, role-gated tabs, workflow-card authorization, or engine-native transition authorization. This is a full functional no-op, not a narrower header/tab rendering defect.

The apparently conflicting marketplace widget test does not perform a successful role switch. Its final `findsNothing` assertion lands while the equipment-loan card is asynchronously reloading its actions, when every guarded action is temporarily absent. The same signed-in member remains authoritative throughout. Thus alternative (a), a split between stale header/tab state and correctly updated per-card state, is ruled out. Alternative (b)'s underlying production-session mechanism is correct, but the test does **not** have a null session: it has a populated member session and obtains its green result through a timing false positive.

## Exact control and data flow

1. `_showActorIdentityPicker` renders every package-declared `LoomActorIdentity` as an enabled radio-style `ListTile`. Its tap handler returns only `actorIdentity.roleId` from the dialog (`part01_local_extension_screen.dart:1060-1087`).
2. The caller receives that string and writes the matching role seed's `fanId` to `_selectedFanId` and the returned role to `_selectedRoleId` inside `setState` (`part01_local_extension_screen.dart:1178-1185`). It does not update `LoomAuthApi.currentSession`, change the account's membership, or call `LoomAuthApi.signIn`.
3. Both fallback selections are shadowed whenever a session exists:
   - `_activeFanId` returns `currentSession.account.accountId` before `_selectedFanId` (`part01_local_extension_screen.dart:214-219`).
   - `_activeRoleId` returns `currentSession.account.roleId` before `_selectedRoleId` (`part01_local_extension_screen.dart:221-225`).
4. `_activeActorIdentity` immediately resolves the role definition using `_activeRoleId` and reconstructs the identity with `_activeFanId` and the session account (`part01_local_extension_screen.dart:725-747`). Therefore a signed-in member who taps Organizer is rebuilt as the same member account and the same member role.
5. All material role-gated rendering consumes that unchanged `activeActorIdentity`:
   - `appShellTabsFor(... roleId: activeActorIdentity.roleId)` produces the visible tab set, selected tab, and bottom bar (`part01_local_extension_screen.dart:1294-1313, 1864-1870`).
   - The identity status strip and selected-tab header receive that same identity (`part01_local_extension_screen.dart:1707-1715, 1741-1747`).
   - Legacy workflow cards call `roleWorkflowViewFor(... roleId: activeActorIdentity.roleId)` (`part01_local_extension_screen.dart:1188-1209`).
   - Tab-scoped and instance-scoped create actions test `byRoleIds` against `activeActorIdentity.roleId` (`part01_local_extension_screen.dart:1346-1366` and the analogous instance-action block immediately below it).
   - `_TabNativeRenderer` receives the same identity (`part01_local_extension_screen.dart:1757-1777`). `EngineNativeMarketplaceSurface` then resolves its engine `fanId` through `ActiveIdentityScope`, which also contains `_activeFanId`, and passes both that fan and the unchanged role into the native surface (`part36_engine_native_marketplace_surface.dart:86-129`). Equipment-loan actions come from `availableTransitionsAsync(... fanId: widget.fanId)` (`part36_engine_native_marketplace_surface.dart:456-476`).

There is consequently no independent, correctly updating card-level role source. `_selectedRoleId` matters only when `currentSession` is null.

## Why the marketplace test passes

The test harness models production sign-in more closely than the proposed null-session explanation:

- `_app` injects `activeAuthForInstalledCommunity` with an already-populated organizer session (`v3_milestone_phasec_marketplace_archetype_test.dart:180-188`; `authz_p6_test_helpers.dart:6-32`).
- `_selectActorIdentity(tester, 'tabletop-member')` delegates to `selectTestTabletopActorIdentity`, which opens `Sign in as a specific person...` and taps the Jordan W. account (`v3_milestone_phasec_marketplace_archetype_test.dart:176-177`; `authz_p6_test_helpers.dart:200-239`). `TestActiveAuthApi.signIn` replaces `_session` with the delegate's signed-in session (`authz_p6_test_helpers.dart:39-43`).
- The fixture contains separate accounts: Alex T. is `tabletop-organizer`, while Jordan W. is `tabletop-member` (`authz_p6_test_helpers.dart:107-122`). It does not give one account two actor identities or two roles.
- The later raw tap on `actor-identity-option-tabletop-organizer` (`v3_milestone_phasec_marketplace_archetype_test.dart:806-821`) bypasses that account-sign-in helper. It changes only the shadowed fallback fields described above, so the session remains Jordan/member.

The green assertion is explained by the following deterministic reload path:

1. The no-op role tap still calls `setState`.
2. `_buildScreen` reparses the package through `experienceForExtensionId` on every build (`part01_local_extension_screen.dart:1288-1293`). For a package experience, `experienceForExtensionId` returns a newly parsed `LoomExperienceDefinition` and therefore a different `workflowDefinitions` map (`part15_evidence_catalog.dart:3-17`).
3. `EngineNativeBindingDispatcher.didUpdateWidget` compares the definitions map by identity. The newly parsed map is not identical, so it calls `_startLoad(clearBindings: true)` and temporarily removes all bindings (`part27_engine_native_binding_dispatcher.dart:101-114`).
4. `_selectMarketplace` waits only until `engine-native-marketplace-root` reappears (`v3_milestone_phasec_marketplace_archetype_test.dart:191-200`). That proves the binding query completed; it does not prove each newly created card finished loading its available transitions.
5. A new `EquipmentLoanArchetypeCard` starts with `_loadingActions = true` and calls `_loadActions` asynchronously (`part36_engine_native_marketplace_surface.dart:412-430, 456-476`). The borrow control renders only when `_loadingActions` is false and the returned actions contain `borrow` (`part36_engine_native_marketplace_surface.dart:969-986`).
6. The test immediately expects the borrow key to be absent after the marketplace root returns (`v3_milestone_phasec_marketplace_archetype_test.dart:822-827`). It therefore samples the normal loading gap. Once `availableTransitionsAsync` completes for the still-signed-in Jordan/member fan, `Request loan` is eligible to return.

This also explains the reported failure caused by disabling the non-account role row: the disabled row no longer pops the modal, so the test cannot proceed through its assumed dialog-dismissal path. That failure does not prove that the old tap changed roles.

The exact test was rerun on the unmodified tree with `flutter test --no-pub ... --plain-name 'paid-up members see Request loan from the real borrow guard while organizers and unpaid members do not'`; it passed. The source trace above explains that pass without requiring a role change.

## Intended identity model

The currently implemented contract is one active community role per account, with role changes occurring by selecting/signing into another account (or, in production, by receiving a different server-authoritative membership/grant). Package `actorIdentities`/`roles` are the community's role catalog; they are not a list of identities owned by the signed-in account.

Evidence:

- `LoomAccount` has one singular `roleId`, and `LoomSession` binds one such account (`part29_auth_api.dart:30-62`). Sign-up creates an account for one requested role (`part29_auth_api.dart:133-142`).
- `RemoteLoomAuthApi._onlyRoleId` explicitly throws unless App Access returns exactly one non-empty role ID, stating that `LoomAccount` currently requires exactly one role (`part39_remote_auth_api.dart:569-586`). The backend wire model may carry `roleIds`, but multi-role membership is not representable by the current App Shell auth model.
- Remote `signIn` refuses to select any account other than the fan authenticated by the bearer session (`part39_remote_auth_api.dart:155-165`). A client-side selection must never impersonate a different fan or locally override that fan's authoritative role.
- The Loom workflow skill states that the people-icon picker is a local testing harness; production persona/role comes from logged-in identity, memberships, grants, and policy (`.agents/skills/using-loom-to-build-an-extension/SKILL.md:86-87`).
- The current Demo App evidence helper already encodes this distinction: for shipped engine-native packages it creates/signs into a real account; when an account is signed in and another role is requested, it routes through `Sign in as a specific person...` and selects or creates the account for that role. Only sessionless legacy metadata fixtures use the direct role option (`app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart:365-448`).

Supporting one fan/account with multiple simultaneously held roles would be a separate identity-model feature. It would require a session/membership type carrying the authorized role set and a server-authoritative active-role selection. Merely preferring `_selectedRoleId` would let a client claim any role declared by a package and is not a valid fix.

## Recommended fix

Implement an explicit separation between authenticated account management and the sessionless legacy test harness in `_showActorIdentityPicker`; do not add the previously attempted per-row `enabled: signedInRoleId == null || ...` gate.

For an authenticated engine-native community:

1. Render the current account and its single membership role as a non-interactive account/permissions summary, not as one selected radio option beside other apparently selectable package roles.
2. Replace the misleading role-choice affordance with a clear `Switch account`/`Sign in as a specific person...` action that uses the existing `LoomAuthScreen` and `LoomAuthApi.signIn` flow. Other package roles may be described as available account/signup roles, but must not be rendered as radio choices that dismiss the dialog without changing the authoritative session.
3. Keep `currentSession.account.accountId` and `.roleId` as the only effective fan and role for authenticated content. Do not make `_selectedFanId` or `_selectedRoleId` override a session.
4. Preserve the existing direct `_selectedFanId`/`_selectedRoleId` fallback only for the explicitly sessionless legacy metadata/test-harness path, where there is no authenticated membership to contradict it.
5. Adjust the AppBar tooltip/title/copy to describe account and membership management rather than promising an in-place role change that the model does not support. The status strip's current package-role count must likewise be labelled as community-wide available roles or removed; it must not imply that the signed-in account owns every declared role.

This is structurally different from disabling every nonmatching `ListTile`: it removes the false choice in authenticated mode and gives the user the supported path to a different role/account.

Keep the marketplace test's real authorization requirement green, but correct its invalid interaction and false-negative timing:

1. At the organizer step, call the existing `_selectActorIdentity(tester, 'tabletop-organizer')` helper (or its underlying specific-person sign-in flow) instead of directly tapping `actor-identity-option-tabletop-organizer`. That changes `TestActiveAuthApi.currentSession` to the separate Alex/organizer account.
2. Assert the postcondition before checking the guarded action: the active identity key is `active-actor-identity-tabletop-organizer`, the signed-in account is Alex T., and/or `authApi.currentSession.account.roleId == 'tabletop-organizer'`.
3. Wait for the Catan card's action load to complete (for example, wait for `equipment-loan-progress-listing-catan` to disappear after the listing is present) before asserting that the borrow control remains absent. Also retain or add a direct engine assertion that `availableTransitionsAsync` for the organizer fan does not contain `borrow`.

Add a focused regression test for the B25 symptom: sign in as a one-role account, open account/permissions, verify that other package roles are not presented as immediately selectable roles, then switch through a second account and verify all three downstream effects together: the identity strip role changes, the role-specific tab set/count changes, and a stable role-gated workflow action changes. A separate legacy-schema test should retain the sessionless direct-role harness behavior if that compatibility path is still required.

No change is required in tab filtering or workflow-card authorization for this bug; those consumers already use the correct session-derived identity. The fix belongs at the picker/account-switch boundary, plus the marketplace test's switch and settling logic.
