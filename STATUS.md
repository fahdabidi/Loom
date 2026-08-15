## What changed

- Restored the referenced Phase A.2 engine changes from `acf514b3` into this single commit because current `main` contains the documentation closure but is not descended from that implementation commit. This supplies the existing `ArchetypeResolver` wiring and the one D8 identity-field straddle helper required by this ticket.
- Added archetype-owned actor-set bookkeeping for the contract-backed corpus mappings:
  - `documentLibrary`: `open`, `acknowledge`, `save` / `unsave`, `download`, and `request_access` / `withdraw_access_request`.
  - `equipment-loan`: `join_queue` / `leave_queue`.
  - `event-rsvp`: `set_reminder`.
- Applied authored effects first, then archetype bookkeeping. During the Phase A-to-F dual-writer straddle, the archetype normalizes its selected actor set so an authored effect and the built-in writer still leave exactly one actor entry.
- Reused `_identityFieldMatchesDuringD8Straddle` for reads and extended that same helper to expose its two temporary candidate spellings. Writes prefer the spelling declared in `instanceDataSchema`, then an existing instance-data spelling, and finally the specVersion 4 `*FanIds` spelling when the community declares neither.
- Preserved unrelated community effects exactly. Archetype bookkeeping runs only when the resolved family and the transition's explicit `action` match a contract mapping.
- Added the three required named coexistence tests plus a table-driven test covering every mapped add/remove action and repeat-application idempotence under the legacy `*PersonaIds` spelling.
- Did not implement response-row fan-out and did not edit any locked file under `docs/references/{reference,guide,archetypes,communities}/`.

## Verification

The repository's `dart` wrapper tries to rewrite the read-only Flutter SDK cache in this environment, so Dart commands used the same installed SDK binary by putting `/home/fahd/flutter/bin/cache/dart-sdk/bin` first on `PATH`.

`PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH dart analyze` in `app/packages/core/loom_workflow_engine`:

```text
Analyzing loom_workflow_engine...
No issues found!
```

`PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH dart test -r compact` in `app/packages/core/loom_workflow_engine`:

```text
Running build hooks...Running build hooks...00:00 +0: loading test/notification_delivery_service_test.dart
...
00:06 +227: All tests passed!
```

The new total is **227 passing**: the required 223-test Phase A.2 baseline plus four new tests. No suite or test count dropped.

Focused bookkeeping run, `dart test test/archetype_bookkeeping_test.dart`:

```text
Running build hooks...Running build hooks...00:00 +0: loading test/archetype_bookkeeping_test.dart
00:00 +0: dual writer: archetype and community effect leave one bookkeeping entry
00:00 +1: undeclared owned field: archetype bookkeeping creates the field
00:00 +2: unowned field: community effect remains untouched
00:00 +3: contract action mappings maintain each actor set idempotently
00:00 +4: All tests passed!
```

The requested `flutter test` in `app/packages/core/loom_communities_app_shell` first hit the read-only SDK wrapper:

```text
/home/fahd/flutter/bin/internal/update_engine_version.sh: line 64: /home/fahd/flutter/bin/cache/engine.stamp: Read-only file system
```

Running the same Flutter tool through a writable temporary SDK mirror reached dependency resolution, but the environment has no pub.dev access:

```text
Resolving dependencies in `/home/fahd/Loom/app`...
Downloading packages...
ClientException with SocketException: Failed host lookup: 'pub.dev' (OS Error: Name or service not known, errno = -2), uri=https://pub.dev/api/packages/archive/advisories
Failed to update packages.
```

Rerunning with `--no-pub` used the already-resolved dependencies, but the managed sandbox refused Flutter's required localhost test-harness socket before any test loaded:

```text
00:00 +0: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/authz_p4b_permission_wiring_test.dart
00:00 +0 -1: loading /home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/authz_p4b_permission_wiring_test.dart [E]
  Failed to load "/home/fahd/Loom/app/packages/core/loom_communities_app_shell/test/authz_p4b_permission_wiring_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
  dart:io-patch/socket_patch.dart 1216:7                           _NativeSocket.bind
  ===== asynchronous gap ===========================
  package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
```

The same environment-level load error repeated for each test file, so this run could not produce or compare the requested `+231 -8` application result.

As a non-socket compile check, `PATH=/home/fahd/flutter/bin/cache/dart-sdk/bin:$PATH dart analyze` in `app/packages/core/loom_communities_app_shell` completed with the same 13 pre-existing info-level lints and no errors or warnings:

```text
Analyzing loom_communities_app_shell...
...
13 issues found.
```

`git diff --check`:

```text
```

(No output; clean.)

## Proposed next steps

- Rerun `flutter test --no-pub` for `loom_communities_app_shell` in an environment that permits an ephemeral `127.0.0.1` test-harness socket, and confirm the documented `+231 -8` baseline.
- Proceed to the separately scoped response-row fan-out ticket; this change deliberately leaves that behavior untouched.
- At Phase F closeout, remove the single D8 straddle helper after the corpus fields have been regenerated to `*FanIds` and the hand-written bookkeeping writers are gone.

## Anything I could not do

- I could not obtain the app-shell `+231 -8` result because this managed sandbox blocks the localhost socket required by Flutter's test harness. The engine analyzer, all 227 engine tests, and the app-shell analyzer completed; no attempt was made to change the eight pre-existing app-shell failures.
