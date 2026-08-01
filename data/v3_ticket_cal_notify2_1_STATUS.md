# Ticket status: CAL.Notify2.1

## Change applied
Status: done

Added the reusable `NotificationInboxController` data layer and its real
in-memory engine test. The controller scopes unread counts with the
notification FSM's reserved `$state` value, post-filters live pages by
`recipientPersonaId`, and marks rows read only through the guarded
`mark-read` transition.

## Verification (independent, verification agent)
flutter analyze on `loom_communities_app_shell`: clean, 0 issues, both before and
after (the implementation agent's own sandbox hit a WSL vsock error and could
not run the real Flutter toolchain — this was run outside that sandbox).

Test suite: real `flutter test` run found the new
`notification_inbox_controller_test.dart` failing (`type 'Null' is not a
subtype of type 'String' in type cast` in `LoomWorkflowTransition.fromJson` —
the test's inline `mark-read` transition JSON omitted the required `label`
field). Fixed by adding `'label': 'Mark read'` to the test fixture's
transition JSON — no production code changed. Full suite: 143/143 before →
144/144 after, all passing, zero regressions.

## Commit
6125aa0 (implementation agent) + follow-up fix commit (verification agent, see
below) for the missing `label` field in the test's transition JSON.
