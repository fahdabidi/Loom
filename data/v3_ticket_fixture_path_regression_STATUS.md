# Ticket status: fixture path regression fix

## Fix applied
Status: done

5 files changed (confirmed by `grep -rn` — no other occurrences exist):
- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a4_engine_native_parsing_test.dart` — split path constant, updated first line
- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a5_shared_engine_test.dart` — single-line constant
- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a8_calendar_end_to_end_test.dart` — single-line constant
- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a9_calendar_theming_test.dart` — single-line constant
- `app/packages/core/loom_communities_app_shell/test/v3_multiuser_login_test.dart` — single-line constant

Old path prefix: `docs/Build Plan V2/Loom Communities Workflow Engine V3/`
New path prefix: `docs/references/communities/`

## Git tracking
Confirmed: the JSON relocation is staged as a proper rename (`R079`) in `git diff --cached --name-status`:
```
R079  docs/Build Plan V2/.../TabletopClub_Example.jsonc  →  docs/references/communities/.../TabletopClub_Example.jsonc
```

## Verification
- `dart analyze packages/core/loom_communities_app_shell packages/core/loom_workflow_engine`: **clean** ("No issues found!")
- `flutter test` full suite: **could not run** in this sandbox — `flutter test` requires creating a local server socket (`127.0.0.1:0`) and this sandbox blocks socket creation (`Operation not permitted`). The same sandbox restriction was encountered in the prior remediation ticket.
- The validator was not run for the same reason (sandbox socket/network restrictions).

**What WAS verified:**
- `dart analyze` confirms all 5 path changes compile correctly
- `grep -rn` across `app/` confirms exactly 5 files reference the fixture and all 5 are now updated
- Git tracking correctly shows the rename (`R079`)
- The JSON file exists at the new path and is now git-tracked at that location

**What could NOT be verified in this sandbox:**
- `flutter test` full suite (requires server sockets)
- Community package validator (likely requires the Flutter engine)
- Whether the a6 failures were bleed-through or independent bugs (requires running the actual tests)

## Commit
Commit hash: 977d4e04d29586e05f23663d190b718f277ee82e
