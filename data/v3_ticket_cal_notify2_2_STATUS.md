# Ticket status: CAL.Notify2.2

## Change applied
Status: done

Added the community-wide `notificationPresentation` grammar model, parsing in both
legacy and engine-native experience paths, the resolved `bell` default accessor,
and focused parser/fixture coverage. No widget or fixture changes were made.

## Verification (independent, verification agent)
flutter analyze on `loom_communities_app_shell`: clean, 0 issues (implementation
agent's own sandbox hit a WSL vsock/localhost-socket restriction and could not
run the real test runner — this was run outside that sandbox).
Test suite: 144/144 before → 146/146 after (both new tests pass), zero
regressions.

## Commit
99fe065
