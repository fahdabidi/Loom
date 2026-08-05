# Ticket status: Phase B.7 fix-round 1 (stale widget-type assertion)

## Change applied
Status: blocked

## Verification
flutter analyze: clean via the direct Flutter Dart SDK analyzer (`No issues
found!`). The Flutter wrapper exits before analysis with the known WSL vsock
error: `UtilBindVsockAnyPort:309: socket failed 1`.
Test suite: unavailable (0/0 executed). The direct votePoll test and the full
`loom_communities_app_shell` suite both exit before test discovery with that
same WSL vsock error. The expected 4-test result and full-suite baseline could
not be independently observed in this sandbox.

## Commit
pending until the controlled commit completes.
