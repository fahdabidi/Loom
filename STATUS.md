# Phase E — Admin-tab access-control leak

## What changed

- Updated `_mergeDeclarativeTabSpecs` in
  `app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart`.
  When a declarative override uses one of the four cosmetic-only engine-native
  IDs (`calendar`, `marketplace`, `giving`, or `admin`) and there is no
  generated tab with that ID for the active persona, the merge now skips the
  override. It can no longer fall through to `override.toTabSpec()` and become
  a standalone tab with the generic navigation-read permission.
- Left the existing positive merge branch unchanged. When a generated special
  tab exists, the declarative label, icon, and description still decorate it,
  while the generated renderer, required permission, pinning metadata, and
  upstream persona gate remain authoritative.
- Added focused Tabletop regression coverage to
  `v3_milestone_phasee_purchase_proposal_test.dart`. The new case proves both
  sides of the invariant:
  - `tabletop-member` receives no Admin tab from a cosmetic-only override.
  - `tabletop-organizer` still receives Admin with distinctive override
    cosmetics (`Organizer desk`, the `board` icon, and the custom description)
    layered over the generated Admin renderer, configure permission, and
    organizer persona gate.
- Kept the existing widget assertion that
  `community-tab-admin` is absent for `tabletop-member`; no test was weakened
  or removed.
- Grepped every real `appShell.tabs` declaration under
  `docs/references/communities`. No current `calendar`, `marketplace`, or
  `giving` declaration has the same missing-generated-entry shape:
  - Every declarative Calendar community has a real Calendar render binding.
  - All four declarative Marketplace communities (Camera Club, Garden Club,
    Neighborhood Book Club, and Tabletop Club) have an `equipment-loan`
    surface family, which generates Marketplace.
  - Every declarative Giving community has a real Giving render binding.
  Therefore no fabricated regression fixture was added for those three IDs.
- Did not edit community JSON or any protected file under
  `docs/references/{reference,guide,archetypes,communities}`. The unrelated
  untracked `ROOT_CAUSE_REPORT_2.md` and `ROOT_CAUSE_REPORT_3.md` files were
  preserved and are not part of this change.

## Verification

The original Flutter SDK is read-only in this sandbox, so the commands below
used an exact temporary copy at `/tmp/loom-flutter-sdk-phasee`. Dependency
resolution was disabled with `--no-pub` because the workspace package graph was
already resolved and outbound DNS is unavailable.

The pre-fix focused command was attempted before any source edit. Flutter Test
could not start its test harness because this sandbox forbids the required
localhost server, so it did not reach the known assertion:

```text
$ flutter test --no-pub test/v3_milestone_phasee_purchase_proposal_test.dart \
    --plain-name 'member proposals flow from Home creation through the live Admin queue, decisions, and revision' \
    --reporter expanded
00:00 +0: loading .../v3_milestone_phasee_purchase_proposal_test.dart
00:00 +0 -1: loading .../v3_milestone_phasee_purchase_proposal_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
00:00 +0 -1: Some tests failed.
```

The post-fix focused Flutter Test attempt hit the identical environment error
before loading the test body. Running with `--ipv6` did not change the harness'
loopback bind behavior:

```text
$ flutter test --no-pub --ipv6 \
    test/v3_milestone_phasee_purchase_proposal_test.dart \
    --plain-name 'cosmetic-only Admin override decorates the generated organizer tab without granting one to members' \
    --reporter expanded
00:00 +0: loading .../v3_milestone_phasee_purchase_proposal_test.dart
00:00 +0 -1: loading .../v3_milestone_phasee_purchase_proposal_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
00:00 +0 -1: Some tests failed.
```

As a runtime fallback, I compiled a temporary one-shot program with Flutter's
patched SDK and ran it directly with `flutter_tester`, avoiding only the
socket-based test harness. It used the frozen Tabletop JSON, called the real
`appShellTabsFor`, asserted the member exclusion and all organizer cosmetics
plus generated metadata, and exited successfully. The temporary source and
compiled output are not in the repository:

```text
$ flutter_tester --disable-vm-service --enable-checked-mode \
    --non-interactive --use-test-fonts \
    --packages=/home/fahd/Loom/app/.dart_tool/package_config.json \
    /tmp/phasee_tab_smoke.dill
PASS: member excluded; organizer cosmetics preserved
exit_code=0
```

Static analysis of exactly the changed Dart files passes:

```text
$ flutter analyze --no-pub \
    lib/src/part12_persona_and_tabs.dart \
    test/v3_milestone_phasee_purchase_proposal_test.dart
Analyzing 2 items...
No issues found! (ran in 23.8s)
exit_code=0
```

Package-wide analysis completed with nine pre-existing informational lints in
unrelated files and no diagnostic in either changed file:

```text
$ flutter analyze --no-pub
9 issues found. (ran in 14.9s)
exit_code=1
```

The post-fix full-suite command was allowed to finish. All 58 test files failed
at the same harness setup step; zero test bodies executed:

```text
$ flutter test --no-pub --reporter compact
00:00 +0 -1: loading .../authz_p4b_permission_wiring_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
...
01:57 +0 -58: loading .../v3_milestone_phasee_purchase_proposal_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
01:57 +0 -58: Some tests failed.
exit_code=1
```

Because the environment fails before test discovery/execution, there is no
honest passing-suite before/after count to report. The observed harness counts
are pre-fix focused `+0 -1`, post-fix focused `+0 -1`, and post-fix full-suite
`+0 -58`; these are infrastructure load errors, not test results. The direct
Flutter-engine fallback and changed-file analysis are green, but they do not
replace the requested test-suite proof.

Final whitespace validation is clean:

```text
$ git diff --check
<no output; exit_code=0>
```

## Proposed next steps

1. In an environment that permits binding a localhost test-harness socket, run
   the exact focused widget test command above and confirm the existing
   `community-tab-admin` `findsNothing` assertion passes for
   `tabletop-member`.
2. Run the new focused cosmetic-merge case and confirm the organizer's label,
   icon, description, generated renderer, configure permission, and persona
   gate assertions all pass.
3. Run `flutter test --no-pub` for the full
   `loom_communities_app_shell` package before and after this commit (or against
   the parent and this commit) and record the actual passing test counts.

## Anything I could not do

- I could not truthfully claim the exact previously failing widget assertion
  passed, because Flutter Test cannot bind its mandatory localhost harness
  socket in this sandbox and never executes the test body.
- I could not produce the requested full-suite passing before/after count or
  confirm the full suite has no regressions for the same environment reason.
  The complete post-fix attempt reached all 58 files and every one failed at
  harness startup, before any product code or assertion ran.
- No other requested implementation work remains. The isolated merge fix,
  focused permanent regression coverage, real-declaration scan, direct
  Flutter-engine runtime check, and changed-file analysis are complete.
