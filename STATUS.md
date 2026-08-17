# Community migration tool — full-roster role translation

## What changed

- `PersonaRoleTranslator.translate` now recognizes one additional exact,
  lossless translation shape after the existing single-role check fails: when
  a multi-role persona list is set-equal to the union of every persona declared
  across every package role, it translates to every package role id.
- The translated role ids are sorted before being returned. Member Social
  Space's full-roster guards therefore produce exactly
  `allowedRoleIds: ["member", "moderator"]`.
- A multi-role list that is not the exact full roster still returns
  `mixed_role_labels`. The focused negative test omits one of the two Members
  while including the Moderator, proving this case was not widened.
- The existing single-role, partial single-role, unknown-persona, and empty-set
  paths were not changed. Because the rule lives in the shared `translate`
  method, it applies equally to guard and create-action audits.
- Member Social Space guard audits changed from **14 clean / 7 flagged** to
  **21 clean / 0 flagged**. No reference fixture, parser, CLI, live executor,
  or live API was changed or called.

## Verification

The focused migration tests increased from 9 to 10 and all pass. The added
positive case checks the sorted two-role result, while the separate negative
case still checks `mixed_role_labels` for an incomplete cross-role roster:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    test/community_remote_migration_test.dart --reporter expanded
00:00 +0: PersonaRoleTranslator full persona set for one role translates cleanly
00:00 +1: PersonaRoleTranslator strict subset of one role is flagged instead of widened
00:00 +2: PersonaRoleTranslator partial persona set from two roles is flagged as mixed
00:00 +3: PersonaRoleTranslator full persona roster across roles translates to sorted role ids
00:00 +4: Member Social Space derivation (setUpAll)
00:00 +4: Member Social Space derivation uses the existing workflow model parser for the real fixture
00:00 +5: Member Social Space derivation derives createRoleIds from create-action byPersonaIds
00:00 +6: Member Social Space derivation cardSurfaceFamily matches an independent resolver call
00:00 +7: Member Social Space derivation audits every real legacy guard and translates full rosters
00:00 +8: Member Social Space derivation passes definitions through under specVersion 4 with clean guards translated
00:00 +9: Member Social Space derivation default dry run constructs no live executor and makes no calls
00:00 +10: Member Social Space derivation (tearDownAll)
00:00 +10: All tests passed!
```

The real dry-run command completed with exit code 0:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart run \
    bin/community_remote_migration.dart \
    ../../../../docs/references/communities/Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc
```

Its install payload showed all seven formerly flagged transitions with the
same sorted role ids:

```text
platform-in-stream-ad: record-impression, open-sponsor-link, report-sponsor
platform-top-banner-no-fill: refresh-slot, inspect-reason
platform-sensitive-no-fill: acknowledge-suppression, review-policy
allowedRoleIds: ["member", "moderator"]
```

The updated findings report from that command was:

```json
{
  "summary": {
    "guardsTranslatedCleanly": 21,
    "guardsFlagged": 0,
    "createActionsTranslatedCleanly": 2,
    "createActionsFlagged": 0,
    "networkCallsMade": 0
  },
  "findings": []
}
```

Whole-package Dart analysis is clean:

```text
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart analyze .
Analyzing ....
No issues found!
```

The full package suite was run both before and after the change. One new test
accounts for the one-test increase; the same 16 HTTP-server tests could not
bind localhost in this sandbox in either run:

| Run | Passed | Sandbox socket failures | Total discovered |
| --- | ---: | ---: | ---: |
| Before | 246 | 16 | 262 |
| After | 247 | 16 | 263 |

The common failure was unchanged:

```text
SocketException: Failed to create server socket
(OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
```

Excluding only `validator_http_server_test.dart`, which owns all 16
socket-binding tests, the complete remaining package suite passes:

```text
$ mapfile -t migration_test_files < <(rg --files test -g '*_test.dart' | \
    sort | rg -v '^test/validator_http_server_test\.dart$')
$ /home/fahd/flutter/bin/cache/dart-sdk/bin/dart \
    /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    "${migration_test_files[@]}" --reporter expanded
00:04 +247: All tests passed!
```

## Proposed next steps

- Use the same dry-run workflow on the next opted-in community fixtures to
  identify other exact-full-roster guards and any genuine partial/mixed sets.
- Keep live execution separate and explicitly authorized; reconcile the known
  grammar-version contract mismatch before any live migration attempt.

## Anything I could not do

- I could not produce an all-green unexcluded package-suite run because this
  execution sandbox prohibits the localhost server socket required by
  `validator_http_server_test.dart`. The failure count was identical before
  and after this change, and all 247 non-socket tests passed after the change.
- Nothing else required by this ticket was blocked. No live API was called.
