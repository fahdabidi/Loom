# Ticket status: CAL.Notify2.6

## Change applied
Status: blocked

Added the global `NotificationFab` trigger, reusing `_NotificationBellSheet` and
the bell trigger's engine/controller polling lifecycle. Wired it into the
Scaffold FAB slot for `notificationPresentation.style == 'fab'`, including the
zero-creatable-actions null-check case, and added host-level widget coverage for
persona scoping, guarded mark-read, badge refresh, global tab visibility, and
style exclusivity.

## Verification
flutter analyze: clean, 0 issues after the change. The CAL.Notify2.5 baseline
was clean at 0 issues.
Test suite: 154/154 before → after unavailable in this sandbox. The full suite
and focused `notification_fab_test.dart` run both stopped before test bodies
could execute because Flutter could not create its localhost test server socket:
`Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0`. No assertion-level test failures were observed;
independent verification is required for the after pass count (expected 157/157
with the three new test cases).

## Commit
fdec41d
