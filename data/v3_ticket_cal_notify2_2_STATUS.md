# Ticket status: CAL.Notify2.2

## Change applied
Status: done

Added the community-wide `notificationPresentation` grammar model, parsing in both
legacy and engine-native experience paths, the resolved `bell` default accessor,
and focused parser/fixture coverage. No widget or fixture changes were made.

## Verification
flutter analyze: clean, 0 issues after the change. The standard launcher was
blocked by the sandbox WSL vsock/read-only SDK environment; the cached Flutter
tool ran successfully through an isolated writable temporary SDK root.
Test suite: 144/144 before (ticket baseline); after unavailable — 0 tests passed
because all 39 test files failed before loading when the sandbox denied the
Flutter test runner's localhost server socket (`Operation not permitted`,
`127.0.0.1`, port `0`). The external verification agent must run the full suite.

## Commit
staged, not committed + the full App Shell test suite could not start in this sandbox because the Flutter test runner was denied its localhost server socket (`Operation not permitted`, `127.0.0.1`, port `0`); the external verification agent must run it.
