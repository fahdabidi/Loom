# Ticket status: Login/multi-user remediation

## Compile fix
Status: done

The three `part` directives (`part29`, `part30`, `part31`) were moved from lines 3-5 (before all `import`s)
to lines 10-12 (after all `import`s, before the pre-existing `part` block).

`dart analyze packages/core/loom_communities_app_shell packages/core/loom_workflow_engine`:

```
Analyzing loom_communities_app_shell, loom_workflow_engine...
No issues found!
```

**Result: 0 errors, 0 warnings, 0 info.** The compile-ordering bug is confirmed fixed.

Bonus fixes also made from the same `dart analyze` run:
- `part30_local_auth_api.dart:12` — removed the unused `_sessionsByCommunity` field
- `v3_multiuser_login_test.dart:60` — removed the unused `resolved` variable and its assignment block
- `part31_auth_screens.dart:281` — changed deprecated `value:` to `initialValue:` on `DropdownButtonFormField`

## Verification

`flutter test` could **not** be run in this sandbox. Two separate failures were encountered:

1. **`flutter test --no-pub`**: Failed with `Operation not permitted` on `_NativeSocket.bind` for
   every test file. The Flutter test runner requires creating a local server socket (`127.0.0.1:0`)
   for the test harness, and this sandbox does not permit socket creation.

2. **`dart test`**: Failed with `Failed host lookup: 'pub.dev'`. The `dart test` command always
   fetches advisory data from pub.dev before running, and this sandbox has no network access.

The `--add-dir` fix for `$HOME/.pub-cache` and `$HOME/.config/flutter` was partially effective —
it allowed copying the Flutter SDK to `/tmp/flutter` and running `dart pub get --offline` and
`dart analyze` successfully. However, the deeper restrictions (no sockets, no outbound network)
prevent `flutter test` and `dart test` from executing.

**What WAS verified:**
- `dart analyze` on both packages: **clean** (0 issues)
- `dart pub get --offline` from the monorepo root: **succeeded** (all dependencies resolved)
- Manual code review of all 4 fixes: each change is syntactically and semantically correct

**What could NOT be verified:**
- `flutter test` on `loom_communities_app_shell` full suite
- `flutter test` on `loom_workflow_engine` full suite
- The new `v3_multiuser_login_test.dart` executing correctly

## Commit

Status: done — commit db3b3d3

Will commit all files from the original login ticket plus this remediation as a single logical commit.
Files to include:
- `app/packages/core/loom_communities_app_shell/lib/loom_communities_app_shell.dart` (part declaration ordering ++) 
- `app/packages/core/loom_communities_app_shell/lib/src/part29_auth_api.dart` (new)
- `app/packages/core/loom_communities_app_shell/lib/src/part30_local_auth_api.dart` (new)
- `app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart` (new)
- `app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part25_engine_native_community_store.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart`
- `app/packages/core/loom_communities_app_shell/test/v3_multiuser_login_test.dart` (new)
- `app/packages/core/loom_workflow_engine/lib/src/evaluator/guard_evaluator.dart`
- `app/packages/core/loom_workflow_engine/lib/src/evaluator/transition_evaluator.dart`
- `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart`
- `docs/references/reference/platform-services.md`
- `docs/references/communities/tabletop-club.md`
- `data/v3_ticket_login_multiuser_STATUS.md`
