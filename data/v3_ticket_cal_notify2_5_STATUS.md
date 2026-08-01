# Ticket status: CAL.Notify2.5

## Change applied
Status: blocked

Added `NotificationFixedCard` as an engine-backed, live-polling inline card with
persona-scoped rows, guarded tap-to-mark-read behavior, a capped inner list, and
a collapsed empty state. Wired it between the selected-tab header and native tab
renderer only when `notificationPresentation.style` is `fixedCard` and the
selected tab is `home`. The home-tab pin is deliberate because the current
grammar has one community-wide style and no per-tab target field.

## Verification (independent, verification agent)
flutter analyze on `loom_communities_app_shell`: clean, 0 issues (implementation
agent's own sandbox hit a WSL vsock/localhost-socket restriction and could not
run the real test runner — this was run outside that sandbox).
Test suite: 150/150 before → 154/154 after (all 4 new tests pass — the new test
already correctly used `ensureVisible` before tapping, learning from
CAL.Notify2.4's fix), zero regressions. Clean on the first round.

## Commit
13da877
