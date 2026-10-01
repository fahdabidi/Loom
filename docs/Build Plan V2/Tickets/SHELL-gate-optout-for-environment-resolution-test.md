# SHELL — the package-wide local opt-in broke the test that guards the live-backend default (ticket A follow-up)

**Status:** written 2026-10-01, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. **One test file. No product code.**
**Follows** [SHELL-gate-local-engine-behind-explicit-optin.md](SHELL-gate-local-engine-behind-explicit-optin.md), whose work is otherwise correct and must not be reverted.

## What happened

Ticket A added `packages/core/loom_communities_app_shell/test/flutter_test_config.dart`, which sets
`debugForceLoomLocalBackend = true` before **every** test in the package. That is right for the ~447
tests that install engine-native stores without an app `main()`.

It is wrong for exactly one test, and that test is the guardian of the very property this programme
exists to enforce:

    remote_service_configuration_environment_test.dart:45
    'no remote-service defines uses the default environment, not local'

Forcing the local flag makes `resolveLoomServiceEnvironment()` return `null`, so
`expect(environment, isNotNull)` fails. Measured: app shell `447 +2 ~ -1`, exit 1 — **this is the
single failure**; the other four suites are green (demo 262, judges 525, engine 345 +1, service 168 +1).

## Why this test must NOT be weakened, skipped or deleted

Read its own comment first (`:47-51`): *"The default is the real backend. Before 2026-08-26 an
unconfigured build silently returned null and ran an in-memory engine, which made 'uses the real
backend' a property of the build command rather than of the codebase — and a capture that forgot the
defines proved nothing while looking like proof."*

That is a description of the exact defect the user's 2026-10-01 decision is correcting. **This test is
on our side.** Deleting or relaxing it to make the suite green would remove the only assertion that
the default is the real backend — while we are in the middle of enforcing that the default is the real
backend. If you find yourself editing its expectations, stop and report instead.

## The fix — a pattern this same change already established

Have the test opt **out** of the package-wide flag for its own body, and restore it afterwards:

```dart
debugForceLoomLocalBackend = false;
addTearDown(() => debugForceLoomLocalBackend = true);
```

`flutter_test_config.dart`'s own doc comment already prescribes this ("A test that wants to prove the
gate fires for a non-local process must flip this back to `false` for its own body and restore it with
`addTearDown`"), and ticket A's new gate-fires test in `remote_auth_session_test.dart` already does
exactly it. Follow that precedent rather than inventing a mechanism.

**Apply it to the whole file if the file's other tests need it too** — check them; several may assert
environment resolution and be passing only incidentally. State which tests you touched and why.

**`addTearDown` matters and is not decoration:** without restoring the flag, every test that runs
after this one in the same process loses the opt-in and hits the gate's `StateError`. That failure
would appear in unrelated tests and look like a far bigger problem than it is.

## Verification

- App shell returns to **448 passed (+2 skipped), 0 failed** — 447 plus ticket A's gate-fires test.
  A total of 447 with one failure means the fix did not land.
- The other four suites stay green: demo 262, judges 525, engine 345 (+1), service 168 (+1) with both
  credential sets.
- **The guarded assertions still exist**: `configureLoomRemoteServicesFromEnvironment()` returns
  non-null and `resolveLoomServiceEnvironment()` returns non-null in that test. Diff it and confirm
  nothing was softened — this ticket is as much about keeping that test honest as about going green.
- `flutter analyze` clean on the app shell.
