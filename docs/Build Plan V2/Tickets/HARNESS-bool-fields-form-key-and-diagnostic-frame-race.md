# HARNESS — three precisely-named blockers after the cascade fix

**Status:** written 2026-10-02, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Follows:** `baef95d2` (surface restoration), measured on-device by me immediately after.
**Evidence:** Garden precheck at `c88b9b67`, scratch evidence root. `exit=66`, `workflows=4`,
`b25Proven=0/3`, `b25RowExecutionFailed=0`, `screenshots=3/3`, `screenshotStatus=complete`,
canonical `Evidence/` untouched (0 modified files).

## What `baef95d2` fixed, confirmed on-device — do not redo this

**The cascade is gone.** Measured against the criterion the previous ticket set:

| Measure | at `61a2e01b` | at `c88b9b67` |
|---|---|---|
| `b25RowExecutionFailed` | **6** | **0** |
| `found modal-barrier` leaks | **5** | **0** |

Rows now record meaningful outcomes instead of five innocent rows failing on a leaked dialog. **And
date/time field support landed** — the unsupported-type message now reads
*"only text/textarea/number/date/time fields are arranged today"*.

## Change 1 — `bool` creation fields

    plant-exchange-submission requires creation field "privacyAcknowledged" of type "bool",
    which this dispatch does not know how to fill -- only text/textarea/number/date/time
    fields are arranged today.

A checkbox or switch is the simplest remaining field type. **Read the creation card to find how a
`bool` field renders and what key it carries** before writing anything — the date/time work had to
discover that the picker was the *only* input path, and `bool` may likewise have no programmatic
setter.

**Mind the direction question, as with `fanId`:** a `bool` required at creation may be a consent
field whose *true* value is what makes the row's action reachable, so defaulting to `false` could
produce a crisp block that is really a wrong-value problem. Check whether any candidate guard or
formula reads it before choosing a default.

## Change 2 — the creation form's title editor never appears

    garden-event-rsvp: stalled (2m 45s elapsed, limit 2m 45s)
      Attempted step: shipped garden-event-rsvp creation form (remote arrangement)
      Waiting for:    widgets with key [<'new-garden-event-rsvp-editor-title'>]

The arranger opened the creation flow and then waited out its full budget for the `title` editor.
**Establish which of these it is before fixing anything** — they need different repairs and the
evidence does not yet distinguish them:

- the FAB tap did not open the form (so no editor exists to find);
- the form opened but `title` is not an editable field on *this* workflow at creation;
- the key prefix is wrong — the harness builds `new-<workflowType>-editor-<field>`, so confirm the
  rendered key for this workflow rather than assuming the pattern holds.

Capture a diagnostic frame at this wait so the next run shows what was on screen. The frame here was
`(not captured)`, which is the one thing that would have settled it.

## Change 3 — `resolving the creator identity` has no beat

    garden-tool-loan: stalled (3m 0s elapsed, limit 3m 0s)
      Attempted step: resolving the creator identity for garden-tool-loan (actor garden-member)
      Waiting for:    whether a different creator role must authenticate before arranging a remote instance

**`3m 0s / limit 3m 0s` is the watchdog, not an inner wait** — the same signature as before
`61a2e01b`, so this is a step the two-identity work added that still reports no progress. Add a
`beat()` at this boundary. **Do not widen the budget**, and do not assume the step is slow: the
previous occurrence of this signature turned out to be legitimate work exceeding an un-beaten
stretch, not a hang.

## Change 4 — the diagnostic frame races teardown

    refusing frame B13_..._STALL_DIAGNOSTIC -- kind=no-focused-window stage=before-capture
      detail="the device reported no focused window, so the app under test was not on top"
    ... prebuilt APK flutter drive teardown uninstalled the app (expected).
    DEVICE SYSTEM DIALOG DETECTED. 1 frame(s) were refused and not written.

**The guard is right and the run was right to fail (`exit=66`).** An unguarded frame is worse than
no frame, and a `STALL_DIAGNOSTIC` showing an empty screen would be evidence wrong in the one field
nobody re-reads. The defect is that the last row's diagnostic capture is attempted *after* teardown
has begun uninstalling the app.

**Do:** capture the diagnostic frame before teardown can start, or skip it and record
`diagnosticFrame: not captured (teardown in progress)` explicitly. **Do not** relax the focused-window
guard to make the refusal go away.

## Do not

- **Do not touch the budget constants.**
- **Do not relax the device dialog guard.**
- **Do not run a capture against the canonical evidence root.** Pass `--evidence-root` at a scratch
  path — now verified three times to leave `docs/Build Plan V2/Evidence` with 0 modified files.
- **Do not touch `docs/references/**`** — hard-locked. No package edits.

## Verification

- All five suites, skip counts before pass counts: demo **292** (0 failed, 0 skipped), app shell
  **448** (+2), engine **345** (+1, both credential sets), service **168** (+1, the one skip being
  App Access and **not** PostgreSQL), judges **525**. Run them **sequentially**.
- **`b25_capture_prebuilt_binary_test.dart` is known flaky** — a different test in it times out at 30s
  about one run in three, because each spawns the capture tool as a real subprocess. Confirm any
  single failure there is a `TimeoutException` and that the file passes isolated
  (`--concurrency=1`), then treat it as environmental. Do not chase the test name.
- `flutter analyze` on the demo app: **3** pre-existing issues; take the count from flutter's own
  `N issues found` line.
- **Success criterion in the run's own units:** all six Garden rows attempted (`workflows` back to 7+),
  `b25RowExecutionFailed` still 0, and zero `found modal-barrier`. `b25Proven` may well still be 0 —
  say so plainly rather than implying otherwise.
- **Report what you actually ran.** Seven consecutive dispatches here have exited status 0 reporting
  only their intent. Name anything you skipped.
