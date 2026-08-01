# Ticket status: CAL.Notify2.1

## Change applied
Status: done

Added the reusable `NotificationInboxController` data layer and its real
in-memory engine test. The controller scopes unread counts with the
notification FSM's reserved `$state` value, post-filters live pages by
`recipientPersonaId`, and marks rows read only through the guarded
`mark-read` transition.

## Verification
flutter analyze: blocked before analyzer startup by `WSL (169 - ) ERROR:
UtilBindVsockAnyPort:307: socket failed 1` (same before and after). Direct Dart
analyzer result: 0 issues before and 0 issues after (`No issues found!`).
Test suite: blocked before test discovery by the same WSL/vsock error; before:
0 tests executed / 0 passes, after: 0 tests executed / 0 passes. The focused
test was also not runnable with plain Dart because this Flutter package loads
`dart:ui`; the Flutter runner was blocked before it could execute the test.

## Commit
Commit hash pending until the one final commit is created.
