# Ticket status: CAL.Notify2.7

## Change applied
Status: blocked

Added `app/packages/core/loom_communities_app_shell/test/v3_calnotify2_7_bell_activation_test.dart`.
The test installs the actual frozen Tabletop Club fixture through the ZIP package pipeline, switches
to the fixture's real `tabletop-member` persona, seeds one real `notification` instance through the
installed workflow engine, verifies the parsed `bell` style renders
`notification-bell-button` with a `1` badge and a sheet row containing the notification, and verifies
the dedicated-tab, fixed-card, and FAB entry points are absent.

## Verification (independent, verification agent)
flutter analyze on `loom_communities_app_shell`: clean, 0 issues (implementation
agent's own sandbox hit a WSL vsock error and could not run the real toolchain).
Test suite: real `flutter test` run found the new test's own assertion failing —
`find.text('The summer tournament ballot opens soon.')` never matches because
the bell sheet's row combines body+createdAt into ONE `Text` widget
(`'$body\nCreated $createdAt'`), not a separate standalone body Text. Fixed by
switching to `find.textContaining(...)` (substring match) — test logic only, no
production code changed. Full suite: 157/157 before → 158/158 after, zero
regressions.

## Commit
af1e013 (implementation agent) + follow-up fix commit (verification agent, see
below) for the `find.text` → `find.textContaining` correction.
