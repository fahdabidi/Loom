# HARNESS — a recorded row failure must restore the surface, and the Garden sign-in wait needs instrumenting

**Status:** written 2026-10-02, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Follows:** `61a2e01b` (watchdog beats + record-and-continue), measured on-device by me immediately after.
**Evidence:** Garden precheck at `61a2e01b` against a scratch evidence root. `exit=0`,
`workflows=8`, `b25Proven=0/7`, `b25RowExecutionFailed=6`, one `row_stalled_inconclusive`,
`screenshots=9/9`, `screenshotStatus=complete`, canonical `Evidence/` untouched (0 modified files).

## What `61a2e01b` fixed, confirmed on-device — do not redo this

- **The run completes.** `exit=0` and `workflows=8`, against `exit=1` and `workflows=1` before.
- **The watchdog is no longer the limiter.** Row 1 now expires at **2m 45s / limit 2m 45s** — the
  *inner* wait budget — where it previously died at `3m 0s / limit 3m 0s`. The beats work.
- **Record-and-continue works**, and `row_stalled_inconclusive` is correctly its own outcome,
  distinct from `primary_action_unavailable` and `blocked_by_arrangement`.

## Change 1 — the cascade: one stall fails five innocent rows

Five of the six failures are the *same* failure, and the harness names its own cause:

    B25 surface mismatch before <row>:
      expected community ext_garden_club;
      found modal-barrier.
      Likely leaked from the previous row: <previous row>

The chain is complete — `garden-event-rsvp` stalls, then `plant-exchange-submission`,
`garden-tool-loan`, `garden-tool-giveaway`, `garden-export-custom-schemas` and
`garden-volunteer-shift` each report a barrier leaked from their predecessor. **So only ONE row has a
real problem and five are collateral.**

This is the recorded defect where an `unavailable` return path left a dialog open and covered the
next row's identity picker. `61a2e01b` made the run continue past a failure — which is right — but
**continuing past a failure requires leaving the UI as the next row expects to find it**, and nothing
does that.

**Do:** when a row's outcome is recorded rather than thrown, restore the surface before the next row
begins — dismiss any overlay the row opened, then **assert** the expected community surface. Own this
explicitly:

- **Do not** dismiss an unknown overlay blindly and call the row fine. The existing
  `_returnToCommunityList` hunts a Back button with `warnIfMissed: false`, so under a covering dialog
  it taps the *covered* button and misses silently — a recovery path built on a suppressed signal.
- If restoration fails, **report the ORIGINAL row's failure**, not the cleanup error, and mark the
  run as needing attention rather than silently continuing into a dirty surface.
- Keep the "likely leaked from the previous row" attribution. It is what made this diagnosis one read
  instead of a trace, and it should survive any refactor here.

**Assert it in a test:** a row that records a failure while an overlay is open must leave the next
row a clean surface. That is exactly the property a single-row fixture cannot show.

## Change 2 — instrument what the Garden sign-in is actually waiting for

Row 1 stalls at its full inner budget:

    Walkthrough stalled: a step could not proceed within its bounded wait (2m 45s elapsed, limit 2m 45s).
      Last completed step: (none; the walkthrough had not completed a step before ...)
      Attempted step:  signing in as garden-member
      Waiting for:     community content to load after signing in as garden-member

**Do not lengthen the budget.** 2m 45s to load community content is already far beyond anything
healthy, so the question is *what it is waiting for*, not whether to wait longer. The previous run at
`7e263a94` stalled at this same wait site, so this is not new and is not caused by the beats.

**Do:** make this wait report its own state on expiry the way the row-level diagnostic does — which
finder it is polling, what is on screen, and whether the identity/auth calls completed. This project's
own rule applies: instrument the silence before theorising about it. The stall instrumentation added
by `3cb47f8e` is the model; this wait site has none.

**A specific hypothesis to test first, not to assume:** two-identity rows now perform a logout and a
second live Keycloak login inside this step, so the wait may be sitting behind an auth round trip
whose result never reaches the UI — or behind a surface that needs reopening after the *second*
login, the way `ea169ea7` had to reopen it after the first. Check whether the second
`authenticateEvidenceFanForRemote` call's `openEvidenceTarget` actually lands before concluding
anything.

## Do not

- **Do not touch the budget constants.** Row 1 expiring at the inner budget is the budget working.
- **Do not "fix" the five collateral rows individually.** They have no defect; fix the cascade.
- **Do not run a capture against the canonical evidence root.** Pass `--evidence-root` at a scratch
  path — verified twice now to leave `docs/Build Plan V2/Evidence` with 0 modified files, where the
  default overwrites manifests for phases the run never attempted.
- **Do not touch `docs/references/**`** — hard-locked. No package edits.

## Verification

- All five suites, skip counts before pass counts: demo **288** (0 failed, 0 skipped), app shell
  **448** (+2), judges **525** (0 failed), engine **345** (+1, both credential sets), service **168**
  (+1, the one skip being the App Access one and **not** PostgreSQL). All measured green by me at
  `61a2e01b`, **run sequentially** — judges beside the engine produces a false timeout.
- `flutter analyze` on the demo app: **3** pre-existing issues; take the count from flutter's own
  `N issues found` line.
- The success criterion for Change 1 is specific: a Garden precheck should show **at most one**
  failing row, not six. If five rows still report a leaked barrier, the cascade is not fixed whatever
  the suites say.
- **Report what you actually ran.** Six consecutive dispatches in this programme have exited status 0
  reporting only their intent. If you cannot finish verification, name the parts you skipped.
