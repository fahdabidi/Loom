# Ticket status: Phase B.2-3 fix-round 2 (zone-crossing hang)

## Change applied
Status: blocked

The test now calls `experienceForExtensionId(...)` to register the engine-native store and then awaits `workflowEngineForExtensionId(...)` inside `_install()`, within the existing `tester.runAsync(...)` call. The ready engine is stored on `_InstalledTabletop` and `_voteRows()` reads that engine directly. The production votePoll widget and dispatcher were not changed.

## Verification
flutter analyze: clean.
Test suite: pass count unavailable. The targeted test did not reach its test body; it exited at `00:00 +0 -1` in 2.98 seconds because Flutter could not create its localhost tester server (`Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`). The full package suite ended `00:00 +0 -48: Some tests failed` in 19.66 seconds, with all 48 test files blocked at loading by the same socket-permission error. The previously observed 10-minute hang was not reproduced, but the test did not execute, so its real completion time and pass result remain unverified. The known pre-existing A.11 date-picker flake was not reached.

## Commit
Commit hash: 2aa29d31.
