# Ticket status: AS.2 fix-round 1 (stale detail card)

## Change applied
Status: done

## Root cause found
Hypothesis 1: `_EventRsvpDetailCardState.didUpdateWidget` in `app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart` used `oldWidget.instance != widget.instance` as the gate for replacing its cached rendered instance. Under AS.2 retained bindings, that identity-only gate can leave the card's State rendering a stale cached instance across a mutation refresh. The card now synchronizes the cached instance on every parent widget update and reloads actions only for an action-context change.

## Verification
flutter analyze: not clean (sandbox WSL vsock failure prevents Flutter from starting).
Test suite: not run (sandbox WSL vsock failure prevents Flutter from starting) -- must be 112/112.

## Commit
staged, not committed + the first commit attempt left `.git/index.lock` with no live Git process; the required `rm -f .git/index.lock`, two-second wait, and single retry was rejected by the sandbox command policy before it could run. No alternate Git recovery was attempted.
