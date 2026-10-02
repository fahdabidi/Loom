# HARNESS — under remote auth, the account is selected by a locally-derived display name

**Status:** written 2026-10-01, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Follows** [HARNESS-remote-picker-race-and-auth-branch.md](HARNESS-remote-picker-race-and-auth-branch.md), whose fixes are confirmed working on-device — see "What this run proved".

## The defect

`authenticateEvidenceFanForRemote` (`test/workflow_ui_test_harness.dart:2071`) authenticates the
seeded fan, then at line 2105 calls:

    await signInEvidenceAccount(tester, _seededEvidenceFanDisplayName(slug));

`_seededEvidenceFanDisplayName` (`:2121`) is a pure local string transform — it title-cases the
credential slug, so `garden-member-1` becomes `"Garden Member 1"`. `signInEvidenceAccount` then waits
for a `ListTile` whose subtree contains `find.text(displayName)`.

**That display name is a convention of the LOCAL seeding path and has no authority over the remote
account list.** Under production wiring the list comes from `RemoteLoomAuthApi.listAccounts` for the
authenticated fan, and nothing guarantees the backend labels that fan with the title-cased slug. The
wait therefore times out at its full budget.

Measured on-device, 2026-10-01, diagnostic `targeted-precheck`: **six** rows stalled identically,
each burning its full 2m 45s — roughly sixteen minutes of one run — with this verbatim diagnostic:

    Walkthrough stalled: a step could not proceed within its bounded wait (2m 45s elapsed, limit 2m 45s).
      Last completed step: (none; the walkthrough had not completed a step before this wait).
      Attempted step: seeded account Garden Member 1
      Waiting for: widgets with type "ListTile" that are ancestors of widgets with text "Garden Member 1"

## FIRST: establish which of two causes this is. They are indistinguishable from the evidence above.

A timeout waiting for that text is produced equally by both of these, and **this run does not
separate them**:

| Cause | What the fix is |
|---|---|
| (a) the account **exists under a different label** than the title-cased slug | select by identity, not by display text |
| (b) `listAccounts` returns **nothing** for this fan in this community | a provisioning or scope problem, and no selector change helps |

**Do not assume (a).** Log what `listAccounts` actually returned — count, and each entry's
`accountId` — and say which case it is in your reply before changing selection logic. If it is (b),
stop and report; that is a different ticket.

## If it is (a): select by identity

The authenticated fan's own id is already the only legal choice, because `RemoteLoomAuthApi.signIn`
rejects any `accountId` that is not the token's `fanId` — this repo records that guard as the reason
nine communities' evidence is attributed to the right person. So matching on display text is both
fragile and unnecessary: under remote, pick the account whose `accountId` equals the authenticated
`fanId`.

**Keep the local path exactly as it is.** `signInEvidenceAccount(displayName)` is correct for
`LocalAuthApi`, where the harness itself seeded those display names and they are authoritative. The
change belongs on the remote branch only — and remember the sibling lesson from the predecessor
ticket: when you add a capability to one path, grep for the other path that answers the same
question, and prefer one shared helper over two implementations.

## What this run proved, so it is not re-litigated

The predecessor ticket's two fixes **work on-device**, confirmed by reasons rather than by counts:

- **The async picker race is gone.** Not one row reported `No element`, "obscured", or a leaked
  `actor-identity-picker-dialog` surface mismatch. Every row reached `workflow-complete` and the next
  started cleanly, so nothing leaks across a row boundary any more.
- **The auth-branch reorder works.** `plant-exchange-submission` no longer hits
  "Evidence accounts can only be seeded into the Demo App LocalAuthApi"; it now authenticates and
  proceeds, which ticket B defined as its success condition.

This defect was **masked** by the cascade: rows previously died before reaching the account chooser.
That is the recorded pattern where fixing a real defect exposes the next one, and the new failure
surfaces far from its cause.

## And the gap in my own specification, recorded so the next ticket avoids it

Ticket B said "authenticate as the seeded fan that actually holds this role" and said nothing about
**how the picker should then identify that fan's row**. The agent reasonably reused the existing
local helper, which carries the local naming convention with it. That is this project's own rule —
never specify an effect without its mechanism — and it is the third time a specific of mine, rather
than an agent's judgement, turned out to be the defect.

## Do not

- **Do not lengthen the 2m 45s budget.** The wait is correct; what it waits for is wrong. A longer
  timeout would turn a sixteen-minute diagnostic into a longer one.
- **Do not match the display name more loosely** (substring, case-insensitive, prefix). This repo
  forbids substring matching of product vocabulary for exactly this reason, and a looser match would
  make the selector pass on the wrong person's row — the one failure mode that banks evidence
  attributed to the wrong fan.
- **Do not touch community JSON or `docs/references/**`.**

## Verification

- A regression test that **fails before the fix and passes after**: a remote-configured auth API whose
  account list labels the fan with something other than the title-cased slug, asserting the harness
  still selects the right account by id. Run it against the un-fixed behaviour first.
- All five suites, skip counts before pass counts: app shell **448 (+2)**, demo **264**, judges
  **525**, engine **345 (+1)**, service **168 (+1)** with both credential sets — all five measured
  green at these values today, so any movement is yours.
- `flutter analyze`: the demo app carries **3** pre-existing issues; take the count from flutter's own
  `N issues found` line, not a grep. A fourth is yours.
