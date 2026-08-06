# Ticket status: AuthZ.P6

## Change applied

Status: done

The community entry gate is in `app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:241-335`, with the content decision at `:1059-1082`. Engine-native communities (`workflowDefinitions` present and non-empty) now query the community-scoped account list and render normal content only when the current session account is present there with `MembershipStatus.active`. The old anonymous `personas.first` fallback is therefore no longer an entry path for those communities.

`requiresApproval` keeps the existing AuthZ.P5 pending-account state inside `LoomAuthScreen`: the account list shows `Pending approval` and signup reports that the account is waiting for approval. The gate remains in place and adds a `Check membership status` action. That action reloads the community account list and recreates the auth surface, which gives the demo a deliberate retry path after an administrator approves the account without adding polling or changing the AuthZ.P5 dialog.

The Demo App now caches one `LocalAuthApi` per community in `app/apps/loom_communities_demo/lib/main.dart:219-233` and passes it into `LocalExtensionScreen`. This preserves the existing in-memory, app-process session when a community route is closed and reopened; no disk persistence was invented. Callers that do not inject an API retain the existing screen-scoped local-demo provider behavior.

Legacy communities whose `experience.workflowDefinitions == null || .isEmpty` explicitly skip the new gate and continue through the prior rendering path. This preserves behavior for schemas without a meaningful persona/access declaration.

No JSON grammar or production JSON field was added or changed.

Existing tests updated to enter engine-native content with an explicit active account, or to handle the new initial gate in the individual sign-in UI test:

- `notification_dedicated_tab_test.dart`
- `notification_fab_test.dart`
- `notification_fixed_card_test.dart`
- `v3_calnotify2_7_bell_activation_test.dart`
- `v3_calr3b_tournament_creation_test.dart`
- `v3_calr3g_creatable_action_fab_test.dart`
- `v3_calr3h1_popup_presentation_test.dart`
- `v3_calr3h1_slideoutright_presentation_test.dart`
- `v3_calr4b_individual_sign_in_ui_test.dart`
- `v3_calr4e_instance_scoped_create_test.dart`
- `v3_calr4f_instance_scoped_create_fab_test.dart`
- `v3_calr4g_marketplace_transition_action_test.dart`
- `v3_milestone_a8_calendar_end_to_end_test.dart`
- `v3_milestone_a11_event_rsvp_archetype_test.dart`
- `v3_milestone_b1_home_engine_native_test.dart`
- `v3_milestone_gp2_giving_end_to_end_test.dart`
- `v3_milestone_phaseb_votepoll_archetype_test.dart`
- `v3_milestone_phasec_marketplace_archetype_test.dart`
- `v3_milestone_phasee_purchase_proposal_test.dart`
- `v3_milestone_phasef_messages_test.dart`

These tests previously mounted engine-native communities with no account and therefore relied on the bug’s anonymous content path. The test-only `authz_p6_test_helpers.dart` supplies an active session, and role-switching cases now select the corresponding seeded account. Legacy-schema tests were not changed for this reason.

## Verification

flutter analyze: clean (`flutter analyze --no-pub packages/core/loom_communities_app_shell`).

Test suite: the pre-change shell-package baseline was 0 passed, with 52 test files failing to load because Flutter could not create its local test server socket. After the change, the package contains 53 test files (including the new gate test); the full run was again 0 passed, with all 53 files failing before test bodies for the same sandbox error: `Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`. The focused new gate test hit the identical error. The repository-level `melos test` attempt was also unavailable because the sandbox could not resolve `pub.dev` while activating/resolving Melos. Independent verification must rerun the test suite outside this sandbox.

New tests added in `authz_p6_entry_gate_test.dart`:

- `open-only community gates entry, then renders content after signup`
- `requiresApproval community stays at the gate with pending membership state`
- `requiresInvite community exposes invite redemption at the entry gate`
- `legacy-schema community still renders without the entry gate`

## Commit

Commit hash: f09df5a6 (implementation commit before the final status-metadata amend; the final amended hash is reported in the handoff)
