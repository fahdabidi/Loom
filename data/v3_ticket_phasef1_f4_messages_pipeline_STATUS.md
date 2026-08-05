# Ticket status: Phase F.1-F.4

## Change applied
Status: blocked

## What was built
- Enabled `messages` in the engine-native tab allowlist and added the additive
  engine-native Messages dispatch ahead of the unchanged legacy
  `_MessagesTabSurface` path.
- Reused `EngineNativeListSurface` for the top-level thread list and the
  `EngineNativeArchetypeCard` default dispatch to
  `GenericWorkflowInstanceCard`; no `discussionThread` bespoke card or surface
  was added.
- Extended the generic card with a schema-driven structured renderer for
  map-valued in-instance lists, presenting message sender, body, and timestamp
  while preserving existing schema visibility behavior for `unread` and the
  tile `messageCount` fact.
- Reused the generic `WorkflowActionButtonRow`, transition-input dialog, and
  real `WorkflowEngineApi.applyTransition` path for `post-message`,
  `mark-read`, and `archive`.
- Reused the existing tab-scoped creation-FAB grammar and
  `AudienceMultiSelectPicker`; added generic `personaId[]` candidate plumbing
  and list normalization so `discussion-thread` creation collects
  `subject` and `participantPersonaIds` through the real engine. No changes
  were made to `_MessagesTabSurface` or `_MessagesEngineStore`.
- Added the end-to-end Phase F regression test and updated the A7 disabled-tab
  assertion to use `marketplace`, which remains disabled in that fixture.

## Verification
flutter analyze: clean.
Test suite: not executed (0/50 test files ran). The Flutter tester could not
create its localhost server socket in this sandbox: `Failed to create server
socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1,
port = 0`. The focused Phase F test and the full app-shell suite both stopped
at that loader failure; no pass count is available. Independent rerun is
required outside this sandbox.

## Commit
staged, not committed + final commit pending after the protected tracked-file
count sanity check; runtime Flutter tests are blocked by the server-socket
restriction above.
