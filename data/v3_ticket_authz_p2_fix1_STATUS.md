# Ticket status: AuthZ.P2 fix1

## Root cause found

`_EventRsvpDetailCardState.initState()` called `_loadAccountNames()` while the
state was still in Flutter's `created` lifecycle phase. `_loadAccountNames()`
then called `ActiveIdentityScope.of(context)`, which is an inherited-widget
lookup. Flutter rejects that lookup from `initState` with a `FlutterError`
because the state has not yet completed initialization and cannot safely
register an inherited dependency. The method's existing `catch (_)` handled
that error as designed for an unavailable account service, set
`_accountNames` to an empty map, and left attendee entries displaying their
raw persona IDs. The `ActiveIdentityScope` at the test harness's `MaterialApp`
root was the correct ancestor and contained the correctly seeded `authApi`; no
route, overlay, or tree-disconnection issue was involved. The two A11 tests
were the only tests that asserted the resolved display name, which is why the
regression presented specifically there.

## Change applied

Status: blocked

Moved the initial account-name load to `didChangeDependencies()`, after the
scope can be safely resolved, so the card also reloads when the active identity
scope changes. `_loadAccountNames()` now captures the scoped `authApi` before
awaiting `listAccounts()`, while retaining the existing graceful swallowed
error handling for genuine lookup failures. No tests, expectations, or AuthZ.P1
code were changed.

## Verification

flutter analyze: clean. Using the writable temporary Flutter SDK overlay and
`--no-pub`, `flutter analyze packages/core/loom_communities_app_shell` reported
`No issues found!`. The changed Dart file also passed `dart format --set-exit-if-changed`.

Test suite: pass count unavailable (0/183 test cases executed in this sandbox).
Both attendee-name tests were attempted individually after the fix, but each
failed before loading the test body because Flutter's widget-test runner could
not bind its localhost tester socket:
`Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0`. The full app-shell suite was also attempted;
all discovered files hit the same loader failure, so no test body ran. I
therefore cannot honestly confirm the two individual passes or the required
182/183 result in this sandbox; independent verification outside the sandbox
must confirm 182 passing with only the pre-existing A11 organizer-create flake
remaining.

## Commit

staged, not committed + required Flutter widget-test verification is blocked by
the sandbox's denied localhost tester socket (`Operation not permitted` on
`127.0.0.1:0`).
