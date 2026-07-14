# A.5 shared-engine remediation evidence

This evidence records the initial A.5 implementation commit
`a646f76822f6eb6f6d3d5278ca158989c5114757` and the remediation implementation
commit `07ef1ed85b09c10af66d0347212288fd7a04d19a`, plus the final package-install
evidence implementation commit `d8db2b9a66984d09f54d0619fbfba035c695c65f`.

## Scope and acceptance evidence

`InstanceDataField.source` is now preserved as nullable schema metadata through
JSON parsing and SQLite definition serialization/reload. It is **not** hydrated,
queried, or evaluated. A formula is deferred only when it transitively depends
on an absent declared source field; ordinary absent inputs retain normal formula
error behavior. All formulas are parsed and statically checked for unknown
functions, undeclared references, and cycles before any deferral/evaluation.

The frozen Tabletop fixture was not modified. Its query-backed `ballots` source
remains metadata only: no query was executed, no `ballots` value was injected,
and no computed value was seeded. GAP-4 remains open.

The engine seed tests cover source parsing and persisted/reloaded preservation;
source-only direct and transitive deferral with an unrelated formula computing;
undeclared fields; unknown functions under an absent source; direct and
source-adjacent cycles; strict `count(items)` wrong-type failure; and the
existing conflict batch proving a preceding new row is rolled back while the
pre-existing row remains unchanged.

The app-shell acceptance test installs the complete normalized frozen JSONC via
temporary `.loom-init.zip` and matching `.loom-extension.zip` files through
`LocalInAppBackend.installLocalPackagePairFromFiles`. It resolves the returned
community's actual extension ID, display name, and experience configuration;
asserts exactly the 17 specified seed IDs and every seed's type/state/creator/
raw instance data; verifies proposal states and Friday's raw absence plus
computed `goingCount == 12`; repeats install/resolution and engine identity with
the same 17 rows; then creates the empty-schema `tabletop-game-loan` instance,
proving all 11 definitions registered.

## Frozen fixture integrity

- SHA-256:
  `822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`
- `git.exe diff --exit-code c5eb7aa6438f4679e08309f49ad568a985c99b75 -- docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc`
  — exit 0 (no diff).

## Verification

All commands below were run from the named package directory after writing the
formatter output over `lib test`. The scoped formatter, analyzer, and full test
suites all passed.

| Package | Command | Exit | Final output/count |
| --- | --- | ---: | --- |
| `loom_workflow_engine` | `dart format --output=none --set-exit-if-changed lib test` | 0 | `Formatted 20 files (0 changed) in 0.26 seconds.` |
| `loom_workflow_engine` | `dart analyze` | 0 | `No issues found!` |
| `loom_workflow_engine` | `dart test` | 0 | `+120: All tests passed!` |
| `loom_communities_app_shell` | `dart format --output=none --set-exit-if-changed lib test` | 0 | `Formatted 47 files (0 changed) in 0.71 seconds.` |
| `loom_communities_app_shell` | `flutter analyze` | 0 | `No issues found! (ran in 4.4s)` |
| `loom_communities_app_shell` | `flutter test` | 0 | `+41: All tests passed!` |

Independent validation, not this status file, owns A.5 closure. A.5 is not
marked complete here.
