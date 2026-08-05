# Ticket status: Phase B.4 eligibility guard negative test

## Change applied
Status: blocked

## Where the test lives
`app/packages/core/loom_communities_app_shell/test/v3_milestone_phaseb_votepoll_archetype_test.dart`. This is a focused widget-test-file addition that makes direct `WorkflowEngineApi.applyTransition` calls against the real frozen fixture installed by the existing fix-round-2 `_install()` helper. It proves the ineligible organizer call throws, creates no vote row, and contrasts that with a successful eligible-member call that creates a row. The helper's `experienceForExtensionId`-before-pump ordering is preserved.

## Verification
analyze: clean.
Test suite: pass count unavailable. The focused test selection exited before loading at `00:00 +0 -1` in 2.88 seconds because Flutter could not create its localhost tester server (`Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`). The full app-shell suite ended `00:00 +0 -48: Some tests failed` in 17.68 seconds, with all 48 test files blocked at loading by the same socket-permission error. No test assertions ran, and the known pre-existing A.11 date-picker flake was not reached.

## Commit
Commit hash: 466648f7.
