# Ticket status: CAL.Notify2.5

## Change applied
Status: blocked

Added `NotificationFixedCard` as an engine-backed, live-polling inline card with
persona-scoped rows, guarded tap-to-mark-read behavior, a capped inner list, and
a collapsed empty state. Wired it between the selected-tab header and native tab
renderer only when `notificationPresentation.style` is `fixedCard` and the
selected tab is `home`. The home-tab pin is deliberate because the current
grammar has one community-wide style and no per-tab target field.

## Verification
flutter analyze: clean, exact issue count 0 before / 0 after. The normal Flutter
launcher hit the sandbox's WSL vsock/read-only SDK startup limits; the cached
Flutter analyzer ran successfully with `--no-pub` and reported no issues both
before and after the change.
Test suite: 150/150 before (ticket baseline); after blocked before test
execution. The Flutter runner could not create its required localhost server
socket at `127.0.0.1:0` (`Operation not permitted`), so 0 tests executed and no
after pass count is claimed. The targeted fixed-card test hit the same blocker.

## Commit
staged, not committed + full Flutter test execution is blocked by the sandbox
localhost socket policy; the verification agent must run the full suite.
