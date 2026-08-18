# Phase E.4e DI seam — per-community remote engine enablement

## What changed

- Added a per-`extensionId` `EngineNativeCommunityEngineFactory` registry in
  `part25_engine_native_community_store.dart`. When a store first builds its
  `late final` engine, it consults that registry first and falls back to the
  existing process-wide `_engineNativeCommunityEngineFactory` when no entry is
  present.
- The precedence rule is explicit and tested: **a per-community registration
  wins for its exact `extensionId`; the existing global factory remains the
  fallback for every unregistered community**. This satisfies the required
  registry-first routing while preserving the existing global testing override
  for all communities that do not opt in.
- Kept `EngineNativeCommunityEngineFactory`,
  `overrideEngineNativeCommunityEngineFactoryForTesting`, and
  `resetEngineNativeCommunityEngineFactoryForTesting` unchanged.
- Added `enableRemoteEngineForCommunity(...)` and
  `disableRemoteEngineForCommunity(...)` in
  `part37_remote_auth_session.dart`. The public remote lifecycle API lives
  there because that part already owns the auth-session/HTTP-facing remote
  construction API. Enablement composes the existing
  `createRemoteEngineNativeCommunityEngineFactory(...)`; it does not duplicate
  `RemoteWorkflowEngineApi` construction.
- Added
  `resetEngineNativeCommunityFactoryRegistrationsForTesting()`, which clears
  every per-community registration independently of the existing global
  override/reset seam.
- Handled the cached-store ordering trap with a fail-loud rule. Enablement and
  removal of an existing registration must happen before
  `experienceForExtensionId(...)` installs that community's engine-native
  store. If the static store map already contains the `extensionId`, changing
  its routing throws a descriptive `StateError`. This is intentionally stricter
  than checking whether the `late final engine` has been touched: callers get
  deterministic behavior and can never silently retain a cached engine.
  Disabling an ID that has no registration is idempotent because it changes no
  routing state.
- Extended `remote_auth_session_test.dart` with five focused cases and routed
  the existing real-remote Local-gate case through the new public path:
  - one registered community is `RemoteWorkflowEngineApi` while a second is
    `LocalWorkflowEngineApi` in the same test;
  - clearing all registrations restores Local routing for two communities;
  - disabling before store installation restores Local routing;
  - enabling after the store and engine already exist throws and leaves the
    original Local engine intact;
  - a per-community registration wins for its ID while the global override is
    still used for an unregistered ID;
  - the per-community remote engine passes through `_initialize()` and
    `configureAuthorization()` without running Local-only definition seeding or
    authorization lookup wiring.
- Every test in the focused file clears all registrations in `tearDown`, so
  process-global routing state cannot leak between cases.
- No production code calls `enableRemoteEngineForCommunity`. The default
  registry is empty, the fallback remains the existing Local factory, and no
  shipped community becomes remote in this change.

## Verification

The installed Flutter SDK cannot update its cache stamps because it is mounted
read-only in this environment. As in the preceding phase, verification used
the disposable SDK copy at `/tmp/loom_phase_e4_flutter`; its test coordinator
uses stdin/stdout because this sandbox rejects the normal localhost protocol
socket. Test programs still execute under the real `flutter_tester`. Neither
the installed SDK nor repository Flutter sources were modified.

### Analyzer before and after

Command, run from `app/packages/core/loom_communities_app_shell`:

```text
/tmp/loom_phase_e4_flutter/bin/flutter analyze --no-pub
```

| App-shell analysis | Infos | Warnings | Errors |
| --- | ---: | ---: | ---: |
| Before | 8 | 0 | 0 |
| After | 8 | 0 | 0 |

Real final output:

```text
# Before
Analyzing loom_communities_app_shell...
8 issues found. (ran in 9.9s)

# After
Analyzing loom_communities_app_shell...
8 issues found. (ran in 11.4s)
```

All eight are unchanged informational lints: three `unawaited_futures` in
`lib/src/part18_marketplace_rendering.dart` and five
`prefer_const_constructors` findings in unchanged test files. There are zero
new analyzer diagnostics.

### Full app-shell suite before and after

Command, run from `app/packages/core/loom_communities_app_shell`:

```text
/tmp/loom_phase_e4_flutter/bin/flutter test --no-pub
```

| Full app-shell suite | Passed | Failed | Delta |
| --- | ---: | ---: | ---: |
| Before | 238 | 3 | baseline |
| After | 243 | 3 | +5 focused passes, zero new failures |

Real final summaries:

```text
# Before
02:52 +238 -3: Some tests failed.

# After
02:58 +243 -3: Some tests failed.
```

The same three pre-existing failures occurred before and after, by exact name:

- `organizer creates an event and one pending response per member`
- `custom event creation and recurring generation seed custom response rows`
- `missing custom response row keeps organizer event-level actions visible`

No other test failed.

### Focused routing and compatibility coverage

New/extended focused file:

```text
$ /tmp/loom_phase_e4_flutter/bin/flutter test --no-pub test/remote_auth_session_test.dart
00:00 +0: session seam defaults to null and reset restores that default
00:00 +1: remote factory exposes the session access-token provider tear-off
00:00 +2: one registered community is remote while another remains local
00:00 +3: resetting all registrations restores local routing for all
00:00 +4: disable removes remote routing before store installation
00:00 +5: enablement after store installation fails loudly
00:00 +6: per-community registration precedes global override and global remains fallback
00:00 +7: per-community remote engine passes through the store Local-only gates
00:00 +8: All tests passed!
```

The untouched E.4e global seam test remains green:

```text
$ /tmp/loom_phase_e4_flutter/bin/flutter test --no-pub test/engine_native_community_engine_factory_test.dart
00:00 +0: non-Local factory engine skips Local-only setup
00:00 +1: All tests passed!
```

The Local-gate test uses a `MockClient` that throws on any HTTP request. Its
passing result proves the per-community-routed real remote engine traverses
store initialization and authorization configuration without executing the
Local-only `registerDefinition`/`seedInstances` or the two Local authorization
lookup setters.

Final scope checks:

```text
$ git diff --check
# no output

$ git diff --name-only -- docs/references/reference docs/references/guide \
    docs/references/archetypes docs/references/communities
# no output
```

The `EngineNativeCommunityEngineFactory` typedef is unchanged. The only
production occurrence of `enableRemoteEngineForCommunity` is its API
declaration; all other occurrences are focused tests, so this commit performs
no rollout.

## Proposed next steps

- Keep selection of the first real remote community as separate Phase F-gated
  work. This mechanism deliberately does not choose Member Social Space or any
  other shipped community.
- After Phase F approves a specific community, its host startup should call
  `enableRemoteEngineForCommunity(...)` with the configured
  `LoomRemoteServiceConfiguration` before any call path installs that
  community's experience, then run the real browser-auth and workflow-service
  end-to-end verification for that one opt-in.
- Rollback for that later selection should remove the registration before the
  community store is installed. A runtime route change after installation
  requires a separate explicit store teardown/disposal design; this ticket
  intentionally fails loudly instead of pretending a cached engine changed.

## Anything I could not do

- I could not run the installed SDK's unmodified Flutter coordinator because
  its cache is read-only and this sandbox rejects its localhost test protocol
  socket. The disposable SDK path above closed that environment gap and
  produced real before/after analyzer and `flutter_tester` results.
- The full suite cannot be reported fully green because the three named A11
  tests already failed at baseline. The before/after run proves this change
  introduced no additional failure.
- No live remote service call was made; the requested scope was DI routing and
  Local-gate behavior, and actually enabling a community remains separate,
  Phase F-gated work.
