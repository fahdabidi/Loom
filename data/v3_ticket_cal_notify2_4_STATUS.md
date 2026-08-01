# Ticket status: CAL.Notify2.4

## Change applied
Status: done

## Verification (independent, verification agent)
flutter analyze on `loom_communities_app_shell`: clean, 0 issues (implementation
agent's own sandbox hit a WSL vsock error and could not run the real toolchain).
Test suite: real `flutter test` run found the new
`notification_dedicated_tab_test.dart`'s row-tap failing (`tap()` derived an
offset outside the 800x600 test viewport — the row was off-screen and
`ensureVisible` was never called before tapping it, unlike the tab-selection
helper in the same file which does call it). Fixed by adding
`tester.ensureVisible(...)` + a `pump()` before the tap — test logic only, no
production code changed. Full suite: 148/148 before → 150/150 after (both new
tests pass), zero regressions.

## Commit
92f27c7 (implementation agent) + follow-up fix commit (verification agent, see
below) for the missing `ensureVisible` call in the test.
