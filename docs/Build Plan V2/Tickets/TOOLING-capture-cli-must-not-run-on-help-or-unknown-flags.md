# TOOLING — the capture CLI runs a canonical full-b25 capture when asked for `--help`

**Status:** written 2026-10-18, **NOT dispatched**. Queue it after the five tickets already queued.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Found by** the implementation agent during the renderer-aware-reader dispatch (2026-10-18), which
ran `--help`, found `Evidence/B25/b25-capture-progress.json` rewritten, and reverted it. **The
mechanism below is mine, read from the source** — the agent's report was the trigger, not the
evidence.

## The defect

`app/packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart` reads its arguments
only through `_argValue(args, '--<name>')` (`:581`). Nothing rejects an argument it does not know,
and there is no `--help`. Every flag has a default, and the defaults are the canonical ones:

| line | flag | default |
|---|---|---|
| `:26` | `--device` | `emulator-5554` |
| `:29` | `--mode` | **`full-b25`** |
| `:44` | `--phases` | all of B12-B20 |
| `:125-128` | `--evidence-root` | **`<repo>/docs/Build Plan V2/Evidence`** — the canonical, committed tree |
| `:138-140` | `--progress-report` | `<evidence-root>/B25/b25-capture-progress.json` |

`:129` creates the evidence root and `:158` writes the progress report (`status: starting`)
**before** `flutter drive` is launched. So:

    dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --help

is a canonical `full-b25` capture into the committed evidence tree. On a host with no device it
fails after writing the progress file (what happened on 2026-10-18). On a host where
`emulator-5554` answers, it runs the whole capture and overwrites committed manifests. A typo'd flag
(`--evidence_root`, `--evidenceRoot`) is silently dropped, and the run then writes to the canonical
path, which is worse because the operator believes they passed a scratch root.

## The change

Before **any** filesystem write or subprocess:

1. **`--help` / `-h`** prints a usage text naming every flag, its default, and the fact that the
   default `--evidence-root` is the canonical committed tree. Then exit **0**, having written
   nothing.
2. **Reject unknown arguments.** The accepted set is exactly the 11 flags the file reads today:
   `--app-package --communities --device --evidence-root --log --mode --only-shard --phases
   --progress-report --shards --use-application-binary`. Each takes a value, as `--name value` or
   `--name=value` (both forms `_argValue` already accepts). Anything else, including a stray
   positional argument, exits **64** naming every offending argument and pointing at `--help`. A
   flag given with no value counts as an error too.
3. Keep every existing default and every existing `exit(64)` guard exactly as they are. This ticket
   does not change what a correct invocation does.

**Do not** change the default `--evidence-root`. A real `full-b25` run is meant to write canonical
evidence; the defect is that a non-run reaches that write. **Do not** remove or weaken any of the
guards at `:76-100`. They are deliberate.

## Honesty tests — each must be able to FAIL against today's code

Put them beside the existing subprocess tests (`test/b25_capture_prebuilt_binary_test.dart` and
`test/b25_capture_integrity_test.dart` already spawn this CLI). Run the child with its working
directory and `--evidence-root`-equivalent paths inside a **temporary** directory, so a test can
never touch the real Evidence tree even when it fails.

- `--help` exits 0, prints the flag list, and **creates no file and no directory** under the temp
  root. Against today's code this must fail, because today `--help` is ignored and the run writes
  `B25/b25-capture-progress.json`.
- An unknown flag (`--evidence_root /x`) exits 64, names `--evidence_root`, and writes nothing.
- A flag with no value (`--phases` as the last argument) exits 64.
- A known-good invocation still reaches the point it reaches today (reuse the existing fake-harness
  pattern; do not launch a real `flutter drive`).

Run the new tests against the unmodified CLI first and put the verbatim failures in your reply. A
test that passes before and after proves nothing.

**Note on flakiness:** `b25_capture_prebuilt_binary_test.dart` is known to time out about one run in
three under load, because each test spawns a real subprocess against a 30 s budget. If one of its
tests times out, confirm it is a `TimeoutException` and that the file passes run on its own before
treating it as a failure. Do not raise its timeouts.

## Scope limit

Only `bin/b25_capture_workflow_screenshots.dart`'s argument handling and its tests. No other CLI in
`bin/`, no product code, no community JSON, nothing under `docs/references/**`. Do not run the
capture CLI against a device and do not run it without a scratch `--evidence-root`.

## Verification

- All five suites, **sequentially**, skip counts before pass counts: demo **319** (0 failed, 0
  skipped), app shell **448** (+2), judges **525**, engine **345** (+1, with BOTH Postgres
  credential sets), service **168** (+1, the one skip being App Access, not PostgreSQL). If you
  cannot supply the Postgres credentials, report engine and service as `NOT_RUN(reason)` rather than
  quoting a credential-less total.
- Judges is the suite this ticket grows. Name the exact increment and which file each new case is
  in.
- `flutter analyze` in `app/apps/loom_communities_demo`: **3** pre-existing issues, read from the
  tool's own `N issues found` line.
- Then `git status -- "docs/Build Plan V2/Evidence"` must show nothing modified.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2.
  `NOT_RUN(reason)` is a correct entry for anything you genuinely could not run.
