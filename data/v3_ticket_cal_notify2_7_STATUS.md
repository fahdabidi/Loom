# Ticket status: CAL.Notify2.7

## Change applied
Status: blocked

Added `app/packages/core/loom_communities_app_shell/test/v3_calnotify2_7_bell_activation_test.dart`.
The test installs the actual frozen Tabletop Club fixture through the ZIP package pipeline, switches
to the fixture's real `tabletop-member` persona, seeds one real `notification` instance through the
installed workflow engine, verifies the parsed `bell` style renders
`notification-bell-button` with a `1` badge and a sheet row containing the notification, and verifies
the dedicated-tab, fixed-card, and FAB entry points are absent.

## Verification
flutter analyze: not run; exact issue count unavailable. The baseline and post-change commands both
failed before analysis with `WSL (2/3) ERROR: UtilBindVsockAnyPort:307: socket failed 1`.
Test suite: 157/157 before (ticket baseline); after unavailable because the full suite failed before
test discovery with the same WSL vsock error.

## Commit
staged, not committed + Flutter/Dart verification is blocked by the sandbox WSL vsock error above.
