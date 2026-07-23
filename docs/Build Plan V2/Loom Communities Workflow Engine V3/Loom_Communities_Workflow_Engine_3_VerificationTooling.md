# CALR verification-agent tooling checklist

This doc exists because a real gap got caught live during CALR.5d (2026-07-23): a milestone with an
explicit visual-reference acceptance bar ("Google Calendar style") got marked closed on a self-reviewed
screenshot that missed a real, obvious styling defect (bare `ListTile`s with zero card decoration). A
genuine, already-built, independent pixel-analysis tool existed in this repo the whole time
(`b25_visual_inspection_auditor.dart`) and was never invoked. This doc is the fix: a checklist and a set
of concrete, low-cost recipes so that tool (and its neighbors) actually get used instead of forgotten.

**This is a companion to, not a replacement for,
[`docs/Build Plan V2/Tools/ux-gate-judge-tools.md`](../Tools/ux-gate-judge-tools.md)** — that doc is the
authoritative reference for the full B25 production-UX pipeline (role table, every CLI's exact schema,
the LLM reconciliation/vision-judge gates, the remediation-ticket schema). Read it before running any
`b25_*` tool for the first time in a session. This doc's job is narrower: what a CALR milestone's
verification agent should actually run, and when, without re-deriving the whole B25 pipeline from
scratch or skipping it entirely because it looks too heavy for a small fix.

## The full B25 pipeline is NOT the right size for a single CALR milestone

The sequence in `ux-gate-judge-tools.md` (capture → coverage gate → evidence collector → persona
coverage → visual auditor → independent judge → component-doc context → LLM reconciliation → LLM
freshness gate → LLM review importer → interaction-model judge → production judge → iteration scorecard)
is built for **whole-app production-readiness passes** (the B12-B25 phase sequence), not for "I just
changed one screen, does it look right." Running it in full per CALR milestone would be wildly
disproportionate — it expects a structured `docs/Build Plan V2/Evidence/` capture across every phase and
two separate external LLM-generated review artifacts.

## What to actually run per CALR milestone with a visual/UX acceptance bar

**1. Before any live walkthrough that exercises a filter/scope/sort feature**: confirm the real fixture
data actually varies along the dimension you're about to test. Grep the frozen fixture for the field in
question (e.g. `eventDate`) before touching the emulator. If it doesn't vary, create the needed data live
as part of the walkthrough (a second real event on a different date, created through the real UI) —
don't assume an automated test's synthetic fixture is a substitute for live proof, even when its logic is
provably correct.

**2. After taking your walkthrough screenshots, run the real pixel auditor directly** — no evidence
directory, no coverage collector, no LLM steps needed. Build a minimal `screenRows` JSON by hand (this is
data you write, not code) and run:

```bash
dart run packages/tooling/loom_ux_judges/bin/b25_visual_inspection_auditor.dart \
  --input <path-to-your-screenrows.json> \
  --output <path-to-result.json>
```

Minimal input shape (only these fields are read by `_inspectScreenshotVisually`,
`loom_ux_judges.dart:2689`):

```json
{
  "screenRows": [
    {
      "communityId": "ext_verify_tabletop_club",
      "workflowId": "event-rsvp",
      "personaId": "tabletop-organizer",
      "screenType": "list",
      "screenOrState": "calendar-agenda",
      "screenshotPath": "/absolute/path/to/screenshot.png",
      "visibleTextExtract": "whatever text is visible on screen, space-separated"
    }
  ]
}
```

Exit code is `0` only if every row's `visualInspection.status == "pass"`. A nonzero exit is a real,
independent finding — not a suggestion to second-guess, a blocker to actually investigate. This is
exactly the check that would have caught CALR.5c's missing card styling: run retroactively against the
pre-fix screenshot, it failed with `B25-REPEATED-CARD-SHELL-LIKELY` (5 undifferentiated "large surface
bands"); the post-fix screenshot must pass before the milestone is closed.

Findings it can raise: `B25-CHECKLIST-MODAL-LIKELY`, `B25-REPEATED-CARD-SHELL-LIKELY`,
`B25-THIN-CONTENT-LIKELY`, `B25-WEAK-VISUAL-IDENTITY`, `B25-DEFAULT-SCAFFOLD-LIKELY`,
`B25-VISUAL-INSPECTION-MISSING` (screenshot file not found/undecodable). None of these require an LLM —
they're computed from real decoded pixel metrics (edge density, accent/saturation ratios, card-band
count).

**3. Explicitly answer "does this look like the cited reference," in words, as its own step** — separate
from confirming structural position (own screenshot vs. what a positional/automated test already
checked) and separate from the pixel auditor's heuristic pass/fail (which catches *generic* red flags,
not "does this match Google Calendar specifically" — it won't tell you the reference comparison passed,
only that nothing looks obviously broken). All three checks are independent; passing one is not evidence
the others would too.

**4. For a genuine whole-app production-readiness pass** (not a single CALR milestone), use the full B25
sequence in `ux-gate-judge-tools.md` instead of the lightweight recipe above.

## Other tooling that exists and is easy to forget

| Tool | What it checks | Where documented |
|---|---|---|
| `community_package_validator` | Community/extension package JSON(C) schema, envelope, versioning | [`docs/references/guide/05-validation.md`](../../references/guide/05-validation.md) |
| `workflow_state_machine_validator` | `LoomWorkflowStateMachine` JSON: stuck/unreachable states, dangling refs, cycles, binding caps | same |
| `manifest_gate.dart` / `phase_gate.dart` (`app/packages/tooling/`) | `test-manifest.json` completeness; phase doc/registration completeness | own `--help` |
| `check_boundaries.dart` (`loom_lints`) | Package import boundaries (features → app-shell → design-system layering) | `melos run lint:boundaries` |
| `flutter analyze` / `flutter test` | Static analysis / unit+widget tests | already the standing per-round gate this whole CALR cycle |

## The dispatch/verification loop tooling (gitignored, `data/*.sh`)

Already the standing mechanism for every CALR dispatch this cycle — summarized here only so it's listed
alongside the judge tooling in one place, not duplicated. Each script's own header comment is the
authoritative reference:

- `call_implementation_agent.sh` — dispatches the Implementation Agent (Codex CLI, WSL) for one ticket.
- `wsl_dispatch_tracker.sh` — `baseline`/`capture`/`cleanup` around one dispatch, plus `sweep-zombies` for
  stale WSL processes.
- `handoff_gate.sh` — confirms a dispatch finished, cleanup closed, and the tree is already committed,
  before `flutter analyze`/tests run.
- `wsl_slot.sh` — caps concurrent ad-hoc `wsl.exe` calls.
- `watch_dispatch_log.sh` — self-terminating Monitor watch for a dispatch's completion line.

## Closing checklist for any CALR milestone whose ticket cites a visual reference

- [ ] Fixture data genuinely varies along whatever dimension is being visually demonstrated (scope,
      filter, sort) — created live test data if it didn't.
- [ ] `b25_visual_inspection_auditor` run against the walkthrough's own screenshots, exit code checked,
      any finding investigated (not dismissed).
- [ ] Explicit "does this look like the reference" judgment made and stated, separate from the above.
- [ ] `flutter analyze`/`flutter test` green (this was never the gap — keep doing it).
