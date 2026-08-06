# Ticket status: AuthZ.P3

## Change applied
Status: done

The change is additive data-model and JSON-grammar support only. No read filtering,
membership enforcement, sign-up/sign-in enforcement, tab visibility enforcement, or
invite issuing/redeeming logic was added.

Exact file:line references for new fields and classes:

- `app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart:435`
  adds `LoomWorkflowState.readGuard`; its JSON mirror is parsed at lines 463-465.
- `app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart:472`
  adds `WorkflowVisibilityDefault`; `WorkflowVisibility` is the new workflow-level
  model at line 479, with `defaultValue`, `readGuard`, and `isDeclared` at lines
  480-482.
- `app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart:789`
  adds `LoomWorkflowStateMachine.visibility`; its omitted-field public compatibility
  default and parser are at lines 798 and 830-832.
- `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:1422`
  and lines 1513-1520 preserve the new state/workflow fields when serializing.
- `app/packages/core/loom_communities_app_shell/lib/src/part11_shell_models.dart:1506`
  adds `LoomPersonaAccessMode`; `LoomPersonaDefinition.accessMode` is at line 1543
  and defaults in its constructor at line 1532. JSON parsing is at
  `part15_evidence_catalog.dart:1077-1083`.
- `app/packages/core/loom_communities_app_shell/lib/src/part29_auth_api.dart:3`
  adds `MembershipStatus`; `LoomAccount.status` is at line 38 and defaults to
  `MembershipStatus.active` at line 44.
- `app/packages/core/loom_communities_app_shell/lib/src/part29_auth_api.dart:5`
  adds `InviteStatus`; `LoomCommunityInvite` is the new data-only record at line 9,
  with fields at lines 10-16.
- `app/packages/tooling/loom_ux_judges/lib/src/validator/workflow_validator.dart:139`
  registers the new check; its warning implementation and finding are at lines
  1490-1506. The documentation row is at
  `docs/references/guide/05-validation.md:118`.

All existing `LoomAccount(...)` call sites, including seeded/demo accounts and the
new-account path, receive the constructor default `MembershipStatus.active`; no
existing account is assigned another status. The existing account tests assert this.

Invalid values are rejected, not silently defaulted. An unknown persona `accessMode`
throws a `FormatException` naming the field and valid values. An unknown
`visibility.default`, a non-object visibility/readGuard, or `guarded` without its
sibling `readGuard` also throws a clear `FormatException`. Omitted `accessMode`
resolves to `open`; omitted workflow `visibility` resolves to `public` while retaining
an `isDeclared: false` marker for the warning.

## Verification
flutter analyze (all three packages): not runnable in this sandbox. The Flutter tool
exits before analysis because it cannot write
`/home/fahd_/flutter/bin/cache/engine.stamp` (`Read-only file system`). Equivalent
production Dart analysis with telemetry suppressed reports `No issues found!` for all
three `lib` trees; `loom_communities_app_shell` also reports no issues for `lib test`.

Test suites (all three packages): `loom_workflow_engine` 200/200 passed. The pure-Dart
`loom_ux_judges` suite is 137/137 when its 16 HTTP-server tests are excluded; the full
run is 137/153, with all 16 failures caused by the sandbox refusing loopback server
sockets (`Operation not permitted`), not by assertions. `loom_communities_app_shell`
could not run because the Flutter test tool is blocked by the same read-only SDK
cache limitation. Its required baseline remains 182/183 (182 passing, only the known
a11 flake failing), plus the new tests below; independent verification must rerun the
Flutter suite.

New parsing/model tests:

- `v3_milestone_aprime_grammar_extensions_test.dart`: state `readGuard`, all three
  workflow visibility defaults, omitted visibility default, invalid visibility default,
  and guarded-without-readGuard rejection.
- `v3_milestone_a4_engine_native_parsing_test.dart`: all three persona `accessMode`
  values plus the omitted `open` default, and invalid `accessMode` rejection.
- `v3_multiuser_login_test.dart`: active status for seeded/new accounts and the
  data-only invite record shape.

New validator tests in `workflow_validator_expected_affordance_test.dart` verify that
an omitted visibility produces exactly one `no_read_visibility_declared` warning and
that declared visibility produces none.

## Commit
Commit hash: `9498ed7769fd4256a0c81aa275416b15cc10f528`
