# Ticket status: Phase B.2-3 fix-round 1 (test-only engine-fetch ordering)

## Change applied
Status: blocked

The test now installs only the community in `_install()` and defers `workflowEngineForExtensionId(...)` until `_voteRows()`, which is called after `LocalExtensionScreen` has been pumped. The production votePoll widget and dispatcher were not changed.

## Verification
flutter analyze: clean.
Test suite: pass count unavailable. The targeted test exited before test execution with `0:00 +0 -1` because Flutter could not create its localhost tester server (`Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`). The full package suite ended `00:00 +0 -48: Some tests failed`; all 48 test files were blocked at loading by the same socket-permission error, including the votePoll test. The known pre-existing A.11 date-picker flake was not reached and cannot be confirmed as the only non-your-test failure in this sandbox.

## Commit
Commit hash: a5c1723f.
