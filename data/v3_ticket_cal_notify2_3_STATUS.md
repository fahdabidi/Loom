# Ticket status: CAL.Notify2.3

## Change applied
Status: done

Added `NotificationBellButton`/`_NotificationBellSheet`
(`notification_bell.dart`) and wired it into the shared AppBar's `actions`
list when `experience.resolvedNotificationPresentationStyle == 'bell'`.

## Verification (independent, verification agent)
flutter analyze on `loom_communities_app_shell`: clean, 0 issues (the
implementation agent's own sandbox hit a WSL vsock error and its own
`git add`/commit was blocked by a stale index.lock its sandbox policy
wouldn't let it clear — no live git process/lock was present on recheck, so
verification proceeded and committed directly).
Test suite: 146/146 before → 148/148 after (both new widget tests pass), zero
regressions.

## Commit
c.f. below — committed by the verification agent after independent review.
