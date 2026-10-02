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

## CORRECTION 2026-10-01, BEFORE ANYONE ACTS ON THIS — both causes above are REFUTED by the live data. Read this first.

I queried the backend rather than leaving the two causes open, and **neither is what happened.** The
display name the harness waits for is exactly the one the backend holds:

    loom_fan_passport:
      fan-garden-member-1       | Garden Member 1
      fan-garden-coordinator-1  | Garden Coordinator 1

All **five** Garden group members (`fan-garden-admin`, `-coordinator-1`, `-coordinator-2`,
`-member-1`, `-member-2`) exist in `group_membership_role` **and** every one has a `fan_passport`
row. So:

- **(a) is false** — the label is not different; it is character-for-character what the title-cased
  slug produces.
- **(b) is false** — the list is not empty, and remote `listAccounts`
  (`part39_remote_auth_api.dart:211`) throws only when a membership has no passport, which cannot
  happen here because all five have one.

**So the selector was looking for the right text, and the right text exists.** The defect is
therefore *not* in how the account is identified, and **changing the selection logic would be fixing
something that is not broken** — the exact shape this project records as an agent "fixing" what was
never wrong.

**What the evidence does establish**, and all it establishes: the walkthrough got past the identity
picker and the specific-person chooser (its stall names the step *after* those), then found no
`ListTile` containing a name the backend does hold. Four states are collapsed in that sentence and
only the first is measured:

    authenticated → listAccounts called → listAccounts returned → the rows rendered

**So the FIRST instruction below stands and is now the whole job: instrument before diagnosing.**
Capture what the app actually saw — whether `listAccounts` was called, whether it threw, what it
returned, and what the chooser rendered — and report that. Do not change selection logic in the same
change. If the list did return five accounts and the row still did not render, that is a rendering or
navigation defect and belongs in its own ticket.

**Note also that `signInEvidenceAccount` has two paths** — an existing-account row, and an
open-signup form keyed `open-signup-display-name`. Which of those the remote chooser presents is not
established either, and it matters: one selects an existing identity, the other creates one, and
creating one under remote auth would be a different and worse outcome than failing.

### Narrowed again, same day: three of the four states are now PROVEN OK, from the run's own telemetry

The capture log carries binding telemetry for the identity services across those Garden rows:

    service=fan-passport mode=remote scope=ext_garden_club outcome=ok status=200   x15
    service=app-access   mode=remote scope=ext_garden_club outcome=ok status=200   x4
    (plus one never-called each, from registration before first use)

So, against the four states this ticket listed:

| State | Verdict |
|---|---|
| authenticated | **proven** — the token endpoint answered 200 and the engine calls carry a bearer |
| `listAccounts` called | **proven** — 4 app-access calls (resolve membership, list group members) |
| `listAccounts` returned | **proven** — 15 fan-passport fetches, every one 200, zero failures |
| the rows rendered findably | **the only unproven state, and therefore the defect** |

**So this is a rendering or finder problem, not auth, not data, and not a service call.** The harness
looks for `find.ancestor(of: find.text(displayName), matching: find.byType(ListTile))`. Two
possibilities remain and the stall message cannot separate them, because an absent text and a text
outside a `ListTile` produce the identical diagnostic:

- the account text renders, but **not inside a `ListTile`** — the remote chooser may build a different
  widget than the local one the finder was written against;
- the account text does not render at all despite the data being present and fetched — e.g. the
  chooser is showing a different surface, or the rows are off-viewport and never scrolled to.

**The one concrete gap worth closing first, because it would have answered this already:** the stall
reported `Diagnostic frame: (not captured)`. A stall at an account chooser should capture a frame —
without it, every investigation of this class starts from a text description of an absent widget.
Make the stall capture a frame, and dump the candidate widget types around the expected text.

**Do not widen the finder to `byType(Widget)` or match the text alone.** That would make the step
pass by selecting whatever happens to contain the string, which on an identity chooser is the single
most dangerous shortcut available — this repo already records a stale session banking evidence under
the wrong fan, and the `signIn` `fanId` guard is the only reason it surfaced.

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
