# Ticket status: Phase B.4 fix-round 1 (assertion mechanics)

## Change applied
Status: blocked

Only the ineligible-call assertion in `app/packages/core/loom_communities_app_shell/test/v3_milestone_phaseb_votepoll_archetype_test.dart` changed. The engine call now runs inside `tester.runAsync` with an explicit try/catch, and the captured error is asserted as `StateError`. The eligible-member contrast and all before/after row-count assertions are unchanged. No production file was touched.

## Verification
analyze: clean.
Test suite: pass count unavailable. The direct file run, containing both votePoll tests, exited before loading at `00:00 +0 -1` in 2.81 seconds because Flutter could not create its localhost tester server (`Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`). The full app-shell suite ended `00:00 +0 -48: Some tests failed` in 13.49 seconds, with all 48 test files blocked at loading by the same socket-permission error. No assertions ran, so the expected 169-test baseline could not be measured here.

## Commit
Commit hash: pending until the controlled commit completes.
