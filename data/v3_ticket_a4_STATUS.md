# Ticket status: Parse workflowDefinitions/workflowInstances at install (A.4)

## Item 1 of 1: version-gated engine-native parsing branch

Status: done

Source production parsing commit: `9cecf12c6c54275355d4fc39ff85b60401d70cd8`.

Permanent coverage remediation commit: `4f4d4bb146a93b1e7238d5f647cd7187862e10a6`.

Legacy-package evidence remediation commit: `4c3daf9cfa3e3085624a3cb7b728b3b577750951`.

## Commands and results

```text
cd app/packages/core/loom_communities_app_shell
dart format --set-exit-if-changed test/v3_milestone_a4_engine_native_parsing_test.dart
Exit code: 0

flutter analyze
Analyzing loom_communities_app_shell...
No issues found! (ran in 6.5s)
Exit code: 0

flutter test
00:06 +40: All tests passed!
Exit code: 0
```

Pre-existing app-shell tests passed unmodified.

## Permanent test outcomes

1. The real Tabletop JSONC parsed 11 exact workflow types and 17 seed instances; the Friday event is open with 12 going personas and representative state/transition assertions passed.
2. The tracked pre-existing shallow package `docs/Build Plan V2/Skill/examples/verify-tabletop-club/loom.initialization.json` was loaded fresh without a stamp and retained its exact static projection: Tabletop Club display name, all six workflow IDs and title/entry/action/result fields, both persona IDs, and null engine-native definitions/instances.
3. A second fresh copy of that same tracked package with explicit `experienceSchemaVersion: 1` produced the complete same projection.
4. `experienceSchemaVersion: 99` threw `FormatException`.
5. Unsupported v2 `workflowGrammarVersion` threw `FormatException`.
6. A malformed definition was skipped while the valid definition remained parsed.
7. A v2 configuration without legacy `workflows[]` returned engine-native definitions and instances.

Test 7 closes the former early-return trap: before the v2 branch, `_experienceFromConfiguration` returned null whenever `workflows` was absent/not a list, so a pure v2 package would fall through to the placeholder experience rather than retain its parsed definitions and seed instances.

The throwaway `_tmp_a4_verify_test.dart` was removed. The permanent test imports the shared `stripJsonComments` helper, contains no copied stripper, and contains no `print` calls.

The frozen Tabletop fixture was not edited. SHA-256 before and after was:

```text
822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813
```

`git diff c5eb7aa -- docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc` was empty.

The real legacy initialization JSON also had an empty diff from `c5eb7aa`. No production parser file changed during the legacy-evidence remediation. The rerun formatting check was clean; `flutter analyze` reported `No issues found!`; and the full app-shell suite passed.
