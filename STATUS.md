# App-shell local package loading — `specVersion: 4`

## What changed

- Completed fix 1 in `loom_workflow_engine` without renaming any Dart fields:
  - `WorkflowAction.fromJson` now reads `byRoleIds` first and falls back to
    `byPersonaIds`, while retaining the internal `byPersonaIds` field.
  - `RenderBinding.fromJson` now reads `audience` first and falls back to
    `role`, while retaining the required internal `role` field.
- Completed fix 2 in app-shell tab parsing: `visibleRoleIds` is now the first
  alias read for `visiblePersonaIds`; the legacy `visiblePersonaIds` and
  `personas` aliases remain unchanged fallbacks.
- Completed fix 3 in the evidence catalog:
  - `experienceForExtensionId` and its private parsers now accept a
    per-package `specVersion`.
  - `specVersion: 4` selects the same engine-native path as legacy
    `experienceSchemaVersion: 2` plus `workflowGrammarVersion: 1`, without
    requiring either legacy field inside `experience`.
  - Both direct top-level identity declaration reads prefer `roles` over
    `personas`; the shared declaration parser prefers `roleId` over
    `personaId`. The parsed representation remains `LoomPersonaDefinition`.
  - The audit found one additional direct legacy access-control read outside
    the workflow-engine models: `_parseTransition` read only
    `allowedPersonaIds`. It now reads `allowedRoleIds` first and falls back to
    `allowedPersonaIds`.
- Completed fix 4 through the real local loading chain:
  - `parseLocalPackagePair` reads `initialization['specVersion'] as int?`.
  - `LocalPackagePairInstallPlan`, `installLocalPackagePairFromFiles`,
    `importInitializationPackage`, `LocalInstalledCommunity`, snapshots, the
    local extension screen, and the demo app's auth resolver preserve/pass the
    per-community value through to `experienceForExtensionId`.
  - Legacy communities retain `specVersion == null`, so installed legacy and
    v4 communities can coexist.
- Added focused regression coverage for both spellings of `WorkflowAction`,
  `RenderBinding`, tab visibility, root package version propagation, and
  legacy `personas/personaId` versus v4 `roles/roleId` package loading.
- Deliberately did not add `instanceDataSchema[].type` handling, rename any
  existing Dart identifier, touch the validator, or touch any reference,
  guide, archetype, or community fixture. All 11 shipped primary community
  fixtures remain on the legacy version scheme; the two additional backup/
  slice JSONC files are also unchanged.

## Verification

Scoped Flutter analysis is clean for every changed Dart surface. Representative
real output:

```text
$ flutter analyze --no-pub \
    lib/src/part01_local_extension_screen.dart \
    lib/src/part12_persona_and_tabs.dart \
    lib/src/part15_evidence_catalog.dart \
    test/v3_milestone_a4_engine_native_parsing_test.dart
Analyzing 4 items...
No issues found! (ran in 6.3s)

$ flutter analyze --no-pub  # loom_workflow_engine
Analyzing loom_workflow_engine...
No issues found! (ran in 1.1s)

$ flutter analyze --no-pub  # loom_demo_local_backend
Analyzing loom_demo_local_backend...
No issues found! (ran in 0.9s)

$ flutter analyze --no-pub lib/main.dart  # loom_communities_demo
Analyzing main.dart...
No issues found! (ran in 2.4s)
```

The whole `app/` analysis command is not clean on unchanged `HEAD`: it reports
14 pre-existing diagnostics (including the unresolved `flutter_lints` include,
three `unawaited_futures` infos in `part18_marketplace_rendering.dart`, and
existing test lint infos). None point to a changed file. The app-shell package
alone reports the same eight pre-existing infos. No unrelated lint was changed
as part of this ticket.

The complete workflow-engine suite ran before and after through the repository's
direct Dart test runner, which avoids the sandbox-blocked Flutter localhost
harness:

| Run | Passed | Skipped | Result |
| --- | ---: | ---: | --- |
| Before | 257 | 3 | All executed tests passed |
| After | 259 | 3 | All executed tests passed |

The two-test increase is exactly the new legacy/v4 model coverage. Focused
output:

```text
$ dart .../test.dart-3.11.5.snapshot \
    test/v3_milestone_aprime_grammar_extensions_test.dart \
    --reporter expanded
00:00 +8: Model parsing render binding accepts legacy role and v4 audience identically
00:00 +13: Model parsing workflow action accepts legacy and v4 role keys identically
00:00 +23: All tests passed!
```

The backend focused suite also passes and proves both null legacy propagation
and v4 propagation through installation:

```text
$ dart .../test.dart-3.11.5.snapshot test/a6_local_backend_test.dart \
    --reporter expanded
00:00 +3: ... vt_fake-backend_parse-arbitrary-local-package-pair
00:00 +4: ... specVersion 4 is preserved from plan through installation
00:00 +14: All tests passed!
```

The standard app-shell Flutter test harness cannot bind localhost in this
sandbox. I ran the complete suite once against an isolated untouched
`fea0f157` worktree and once after the change; both reached all 51 test files
and failed before executing test bodies with the identical infrastructure
error:

| Run | Tests executed | Harness load failures | Summary |
| --- | ---: | ---: | --- |
| Before (`fea0f157`) | 0 | 51 | `+0 -51: Some tests failed.` |
| After | 0 | 51 | `+0 -51: Some tests failed.` |

```text
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
```

Because that failure occurs before test execution, the three known a11/calr2g
failures could not be re-observed here. The last runnable repository baseline
at this `HEAD` is 235/238, with exactly:

- `organizer creates an event and one pending response per member`
- `custom event creation and recurring generation seed custom response rows`
- `missing custom response row keeps organizer event-level actions visible`

As a non-socket execution proof, a temporary standalone program was compiled
with the Flutter kernel builder and run directly with `flutter_tester`. It
loaded one legacy and one v4 package through
`parseLocalPackagePair`/installation/`experienceForExtensionId`, compared their
internal workflow and persona representations, and checked visible and hidden
tab behavior for `visiblePersonaIds` and `visibleRoleIds`. It exited 0 with:

```text
legacy/v4 standalone loading smoke passed
```

The temporary source and build directory were removed. Final scope checks are
clean:

```text
$ git diff --check
# no output

$ git diff --name-only -- docs/references/reference \
    docs/references/guide docs/references/archetypes \
    docs/references/communities \
    app/packages/tooling/loom_ux_judges/lib/src/validator/community_package_validator.dart
# no output
```

## Proposed next steps

- Re-run the full app-shell Flutter suite on a host that permits the Flutter
  test coordinator to bind localhost. With the two added tests, the expected
  runnable count is 237 passing out of 240, with only the same three named
  a11/calr2g failures.
- Keep fixture regeneration separate. A later ticket should invoke the
  `loom-calendar-experience-authoring` Skill to regenerate the 11 shipped
  primary community fixtures at `specVersion: 4`; this ticket did not invoke
  that Skill or migrate any fixture.

## Anything I could not do

- I could not produce an executing full app-shell before/after suite in this
  sandbox because all 51 files fail at the Flutter harness's prohibited
  localhost bind. The identical before/after infrastructure counts, clean
  compilation/analysis, focused pure-Dart tests, and standalone Flutter smoke
  are recorded above, but they do not replace a runnable 240-test host run.
- I could not make the whole `app/` analysis report zero diagnostics without
  changing unrelated pre-existing lint issues. All changed files and the two
  affected non-app-shell packages analyze cleanly.
- No direct legacy identity-key read site in
  `part15_evidence_catalog.dart` was left unresolved. The two top-level
  `personas` reads, the shared `personaId` parser, and the otherwise easy-to-
  miss `_parseTransition.allowedPersonaIds` read were all confidently widened
  to prefer the v4 spelling and fall back to the legacy spelling.
