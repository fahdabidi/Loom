# Ticket status: A.11f waitlist test arithmetic fix

## Fix applied

Status: done

The test now sets `capacity` to `11` after `tabletop-member` moves from going
to maybe, so the resulting state is 11 going / 11 capacity. The updated text
assertions are `11 / 11 going` and `0 seats left`.

## Verification

dart analyze: clean. Ran with the installed Dart SDK binary because the normal
wrapper cannot update its read-only engine stamp; analyzer output was `No issues
found`.

Test in isolation: fail before test execution. Flutter could not bind its
required loopback test server: `Failed to create server socket (OS Error:
Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`.

Test in-file: fail before test execution for the same sandbox loopback-socket
restriction.

Full-suite: fail before test execution for the same restriction. The app-shell
package command reported 0 passed / 25 failed loads; every failure was the
same loopback-server permission error, including the A.11 file.

Full app-shell suite: 0 pass / 25 failed loads (not the expected test result;
the sandbox prevents Flutter widget tests from starting).

Any other test observed failing: all listed app-shell test files failed to load
because the sandbox blocks Flutter's loopback test server. This is unrelated to
the event-rsvp/Calendar change; no test body, including the noted A.6 test,
executed.

## Commit

staged, not committed: required Flutter test verification cannot complete in
this sandbox because binding `127.0.0.1` is denied (`Operation not permitted`).
