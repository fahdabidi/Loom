# Retired vocabulary gate status

## Outcome

The retired-vocabulary gate now allows the single exact legacy database column
identifier `created_by_persona_id`.  The allowlist entry is authorised by
`docs/Build Plan V2/Evidence/backend/create-instance-500-root-cause.md` and
uses the required `Identifier:` comment.

The gate now removes an allowlisted value only when it is a complete identifier
token (ASCII letter, digit, and underscore boundaries).  Consequently, the
exception covers the required legacy column in SQL and diagnostic strings, but
does not cover prefixes, suffixes, regular expressions, wildcards, files, or
directories.  The migration and its legacy-schema tests were not changed.

## Gate-still-armed proof

1. I added the temporary unrelated source file
   `app/apps/loom_communities_demo/lib/retired_vocabulary_gate_temporary_proof.dart`
   containing:

   ```dart
   const temporaryGateProofIdentity = 'persona';
   ```

2. `flutter test test/retired_vocabulary_gate_test.dart` failed, 0 passed / 1
   failed, with this gate output:

   ```text
   Expected: empty
     Actual: [
               'apps/loom_communities_demo/lib/retired_vocabulary_gate_temporary_proof.dart:1: const temporaryGateProofIdentity = \'persona\';'
             ]
   Rename every retired token according to whether it names a fan, a role, or an actor identity. Exact locked identifiers are the only exceptions.
   apps/loom_communities_demo/lib/retired_vocabulary_gate_temporary_proof.dart:1: const temporaryGateProofIdentity = 'persona';
   ```

3. I removed that temporary file immediately.  Re-running the same targeted
   gate test then passed: 1 passed / 1 total.

## Test totals

| Command / suite | Result |
| --- | --- |
| `flutter test test/retired_vocabulary_gate_test.dart` before the change | 0 passed / 1 total; expected failure listing 11 legacy-column occurrences |
| Same targeted gate test after adding only the allowlist entry | 0 passed / 1 total; diagnostic finding: 7 required occurrences remained because the old scanner recognised only wholly quoted Dart literals, not the same exact token embedded in SQL and diagnostic strings |
| Same targeted gate test after the exact-token allowlist handling | 1 passed / 1 total |
| Same targeted gate test with the temporary unrelated violation | 0 passed / 1 total; expected failure, shown above |
| Same targeted gate test after removing the temporary violation | 1 passed / 1 total |
| `app/packages/core/loom_workflow_engine && flutter test -r compact` | 287 passed / 287 total; 4 skipped |
| `app/packages/core/loom_workflow_service && flutter test -r compact` | 54 passed / 54 total; 5 skipped |
| `app/packages/core/loom_communities_app_shell && flutter test -r compact` | 273 passed / 273 total |
| `app/packages/tooling/loom_ux_judges && flutter test -r compact` | 432 passed / 432 total |
| `app/packages/tooling/loom_app_access_provisioning && flutter test -r compact` | 15 passed / 15 total |
| `app/apps/loom_communities_demo && flutter test -r compact` | 160 passed / 160 total |

No total moved down.  The skipped engine and workflow-service integration tests
remain at their stated baselines (4 and 5 respectively).

An initial parallel attempt at the engine, workflow-service, and app-shell
commands contended on Flutter's shared startup lock and did not return reliable
completion summaries, so those invocations were not used as evidence; each was
re-run serially above to obtain its authoritative total.

## Scope confirmation

- No file under `docs/references/` was modified.
- No community JSON was modified.
- No migration or legacy-schema test was modified.
- The temporary proof file was removed and is not part of the final change.
