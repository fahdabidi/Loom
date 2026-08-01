# Ticket status: CAL.Notify2.6

## Change applied
Status: blocked

Added the global `NotificationFab` trigger, reusing `_NotificationBellSheet` and
the bell trigger's engine/controller polling lifecycle. Wired it into the
Scaffold FAB slot for `notificationPresentation.style == 'fab'`, including the
zero-creatable-actions null-check case, and added host-level widget coverage for
persona scoping, guarded mark-read, badge refresh, global tab visibility, and
style exclusivity.

## Verification (independent, verification agent)
flutter analyze on `loom_communities_app_shell`: clean, 0 issues (implementation
agent's own sandbox hit a WSL vsock/localhost-socket restriction and could not
run the real test runner — this was run outside that sandbox).
Test suite: 154/154 before → 157/157 after (all 3 new tests pass, including the
critical zero-creatable-actions FAB-visibility case, implicitly covered since
the test fixture registers no workflow type with a `create` action), zero
regressions. Clean on the first round — all four notification presentation
styles (`bell`/`dedicatedTab`/`fixedCard`/`fab`) are now shipped.

## Commit
ed56d4f
