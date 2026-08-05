# Ticket status: Phase G.2 fix1

## Root cause confirmed
The mismatch was a shared test-fixture configuration error, not a production
theme-resolution bug and not two independent color bugs. Both failing tests
used `_detailCommunity`, whose `LocalInstalledCommunity.accentColor` metadata
was `'#4a3b2a'`, while its `experienceConfiguration` omitted
`'accentColor'`. `LocalExtensionScreen` resolves the shell theme from
`experienceForExtensionId(..., experienceConfiguration: ...)`, and the parser
correctly falls back to `0xff246b62` when that package-experience field is
absent. That single resolved teal value was therefore passed to both
`_ProtectedDetailTabSurfaceState` and `_WorkflowTile`, matching the reported
actual color. The fixture now declares `'#4a3b2a'` in the package experience as
well, so the unchanged exact assertions exercise the intended configured
accent. No production theming code was changed.

## Change applied
Status: blocked

## Verification
flutter analyze: clean (`flutter analyze --no-pub packages/core/loom_communities_app_shell`).
Test suite: 0/50 test files executed; the focused theming file was 0/1. Flutter
could not start any test because the sandbox forbids its localhost server
socket: `Failed to create server socket (OS Error: Operation not permitted,
errno = 1), address = 127.0.0.1, port = 0`. No assertion-level test failure
was observed, so the known a11 flake could not be isolated or confirmed as the
only runtime failure in this environment.

## Commit
staged, not committed; runtime widget tests are blocked by the exact
localhost server-socket restriction above.
