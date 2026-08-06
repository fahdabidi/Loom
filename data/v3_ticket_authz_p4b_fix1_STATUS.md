# Ticket status: AuthZ.P4b fix1

## Root cause found

The four failing engine-native notification surfaces all use
`NotificationInboxController`, whose `queryPage`/live-query default is the
synthetic `tabId: 'notification-inbox'`. `NotificationFab`, `NotificationFixedCard`,
and the bell sheet use that path; the real Tabletop Club bell fixture creates the
same `workflowType: 'notification'` instances and then queries through the same
controller.

`LocalWorkflowEngineApi.queryInstances` receives only that tab ID and calls
`_requireSurfacePermission` before reading rows. The app-shell authorization
callback therefore resolved `requiredPermissionForTab('notification-inbox')`.
P4b had a fallback for `notifications` and `messages` to
`community.surface.messages.read`, but no fallback for the internal
`notification-inbox` ID. With no configured tab spec for the FAB/fixed-card
surfaces (and no notification render binding in the Tabletop fixture), the
resolver returned `null`, the callback returned `false`, and the engine threw
`StateError('Permission denied for surface "notification-inbox" ...')`.

The `notification` workflow intentionally has no `renderBindings`: it is a
cross-cutting inbox workflow, not a content-tab workflow. Its row-level
recipient scope remains separate from this surface-reachability check.

## Change applied

Status: done

Added `notification-inbox` to the existing messages/inbox permission fallback in
`requiredPermissionForTab`, resolving the synthetic notification surface to
`community.surface.messages.read`. This keeps `_requireSurfacePermission`
active for other surfaces and does not alter notification workflow data,
grammar, visibility, or transitions.

AuthZ.P4a recipient scoping was not weakened: `NotificationInboxController.filterMine`
still requires both `workflowType == 'notification'` and
`item.instanceData['recipientPersonaId'] == personaId`; `unreadCount` still
filters by `recipientPersonaId`, and `markRead` still goes through the
`actorEqualsField` guard.

## Verification

`flutter analyze`: unavailable in this sandbox. The literal Flutter launcher
failed before startup with `WSL ... UtilBindVsockAnyPort:309: socket failed 1`.
The direct Dart analyzer reported `No issues found!` for both
`loom_communities_app_shell` and `loom_workflow_engine`; its process also
reported the sandbox's read-only Dart telemetry-session write after analysis.

Test suite: `loom_workflow_engine` passed **206/206** with the cached direct
Dart test runner. The four previously failing app-shell tests were each
attempted individually with Flutter, but Flutter failed before loading any test
for the same WSL interop error, so their individual passes cannot be truthfully
confirmed here. The app-shell full suite was likewise attempted but could not
start; independent verification must confirm the required **191/192**, with
only the known `organizer creates an event and one pending response per member`
a11 flake failing.

Recipient scoping remains covered by the existing
`notification_inbox_controller_test.dart` test
`scopes count and live list, and preserves the guarded mark-read transition`,
as well as the persona-isolation assertions in
`notification_fab_test.dart`, `notification_fixed_card_test.dart`,
`notification_bell_button_test.dart`, and
`notification_dedicated_tab_test.dart` (each hides the other persona's row).

## Commit

staged, not committed — pending the final Git integrity check and the single
requested commit.
