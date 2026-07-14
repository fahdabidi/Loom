# Ticket status: CommunityPackageValidator (Ticket B)

## Item 1 of 1: community package validator + CLI + tests

Status: done

## A.2 remediation evidence

Implementation/test commit: `4494df4c735c052c8b597954f654823eb4ef5416`

The validator test file now contains exactly 15 independent `test()` cases, one for every original Ticket B rule.

Commands and observed results:

```text
dart format --set-exit-if-changed test/community_package_validator_test.dart
Exit code: 0

dart analyze
Analyzing loom_ux_judges...
No issues found!
Exit code: 0

full loom_ux_judges test suite
00:01 +64: All tests passed!
Exit code: 0
```

Canonical Tabletop package hard-gate invocation:

```text
community_package_validator --warnings-as-errors
Exit code: 0
stderr: empty
stdout:
{
  "status": "pass",
  "errorCount": 0,
  "warningCount": 0,
  "findings": []
}
```

The single-quoted formula literal parses successfully. The ballot eligibility reference resolves to its event, and the cross-instance `selectedGame` write resolves without dangling or computed-write findings.

The Tabletop fixture was not modified. Its SHA-256 before and after verification was identical:

```text
822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813
```

`git diff c5eb7aa -- docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc` was empty.

## A.2 independent-validation isolation correction

Test correction commit: `d16a0d51661f8504c1501c9b50faa1414d7a168e`.

Rule 2 now begins from the otherwise-valid `pkg()` fixture, removes only the root `schemaVersion`, validates once, and asserts exactly one `missing_schema_version` finding at exactly `schemaVersion`.

Rerun results: formatting clean; `dart analyze` reported `No issues found!`; the full suite reported `00:01 +64: All tests passed!`; and the canonical Tabletop CLI with `--warnings-as-errors` exited 0 with empty stderr and the same 0-error/0-warning JSON. The fixture SHA-256 remained `822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`.
