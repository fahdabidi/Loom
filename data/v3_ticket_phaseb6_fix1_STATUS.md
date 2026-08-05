# Ticket status: Phase B.6 fix-round 1 (two test-only bugs)

## Change applied
Status: blocked

Only the existing votePoll test file changed. `_waitForState` now follows the
file's proven `_pumpUntil` rhythm: each attempt queries through
`tester.runAsync`, waits briefly in the real async zone, and calls
`tester.pump(const Duration(milliseconds: 50))` before the next attempt. Both
close-vote call sites pass `tester` directly. The two tie votes now use the
literal allowed actor persona `tabletop-member`; no assertions or production
files changed.

## Verification
flutter analyze: clean via the underlying Dart analyzer (`No issues found!`).
The standard Flutter launcher exits before analysis with
`WSL ... UtilBindVsockAnyPort:309: socket failed 1`.
Test suite: pass count unavailable. The direct four-test file run and the full
`loom_communities_app_shell` suite both exited before test loading with the same
WSL vsock error, so no assertions ran and no `X/Y` result was produced. The
known pre-existing A.11 date-picker flake was not reached.

## Commit
Commit hash: pending until the controlled commit completes.
