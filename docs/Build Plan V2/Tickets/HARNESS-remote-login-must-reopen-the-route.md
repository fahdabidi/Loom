# HARNESS — after a remote login, reopen the community route so the auth screen re-reads the session

**Status:** written 2026-10-02, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Size:** one call, mirroring the sibling path that already does it.
**Diagnosis:** fully established in [HARNESS-remote-account-selection-by-identity.md](HARNESS-remote-account-selection-by-identity.md) — read its CONFIRMED section; do not re-derive it.

## PROVEN ON-DEVICE 2026-10-02 — sign-in now completes, and the failures moved to the data layer

The route-reopen fix (`ea169ea7`) was verified on a real device against the deployed backend. It works,
and it revealed the next layer rather than curing the campaign — the documented pattern.

**The quantitative proof, pre-fix against post-fix on the same rows:**

| Measure | before | after |
|---|---|---|
| token-endpoint `200`s | 6 | 6 |
| `app-access outcome=ok` | **4** | **87** |
| `fan-passport outcome=ok` | **15** | **411** |

Same six logins; `listAccounts` now succeeds throughout instead of throwing before it reached the
network. The pre-fix 4 and 15 came entirely from the one row that happened not to stall.

**And the stalls MOVED, which is the finding.** Every pre-fix stall read
`Attempted step: seeded account Garden Member 1`. Now they read:

    shipped plant-exchange-submission instance basil-start-request on home
    shipped garden-volunteer-shift   instance mulch-delivery-shift on care
    shipped garden-tool-loan         instance compact-tiller on marketplace
    shipped garden-tool-giveaway     instance cedar-compost-bin-giveaway on marketplace
    ... waiting for: widgets with engine-native widget for <instance-id>

**Those are all seeded instance ids, and remote communities start empty by design** (the 2026-09-07
decision: package `workflowInstances` seed only the local engine). So the harness is now authenticating
correctly and then addressing rows that cannot exist on the remote path. **That is ticket C's residue,
already scoped**: the capture harness addresses a seeded instance *by id*, while the live-verification
walkthroughs *create* the instance they then act on.

**Read the message, not the outcome name.** All six rows still record `row_execution_failed` with
"Walkthrough stalled", so a count of failures is unchanged at six and would say the fix did nothing.
The step name is what changed, and it changed from an auth problem to a data problem. A completion
figure built on outcome names would have hidden an entire layer being cleared.

**One separate finding, not Garden's:** Book Club's row stalls at
`Waiting for: community content to load after signing in as book-member` — past sign-in, so not the
fixed defect, and at a 3m budget rather than 2m45s, so a different wait site. It needs its own
investigation and must not be folded into either the auth fix or the data gap.

**What this does and does not change about the bar.** The walkthrough half is unaffected (54 rows,
proven by the live-verification agent, which creates its own rows). The judge half remains
**CONFIRMED 0** under the live-backend standard. No row became provable today; what became true is
that the capture harness can authenticate against live services and reach real surfaces, which was the
precondition for everything else.

## The change

In `authenticateEvidenceFanForRemote` (`test/workflow_ui_test_harness.dart`), after
`loginWithTestCredentials` succeeds and **before** `signInEvidenceAccount` is called, reopen the
community route so the auth screen rebuilds and re-reads the now-stored session:

    await openEvidenceTarget(tester, target);

**The local path already does exactly this, for exactly this reason.** `seedEvidenceAccounts` ends:

    // The entry screen may already have loaded its account list. Reopen the
    // community route so the real auth UI reads the newly seeded identities.
    await openEvidenceTarget(tester, target);

The remote path has **zero** `openEvidenceTarget` calls. One path learned this lesson and its sibling
never did — which is this repo's recorded "a fallback path is where a new capability silently fails to
exist", with the added sting that the sibling documents the reason in a comment.

**You will need `target` in scope.** `authenticateEvidenceFanForRemote` currently takes
`(tester, {roleId, diagnosticFrameName, captureDiagnostic})`; the call site in
`integration_test/workflow_ui_evidence_test.dart` has the `LoomEvidenceTarget`. Thread it through, or
pass whatever the existing `openEvidenceTarget` signature needs — do not reconstruct a target.

## Why this is the fix, in one paragraph

Per stalled row: the auth screen mounted, called `listAccounts`, threw
`LoomAuthNotLoggedInException` because no session existed **yet**, and rendered its error. The harness
then logged in successfully — six token-endpoint `200`s, one per stalled row, spaced at exactly the
2m45s budget — and **nothing re-ran the fetch**, so the harness waited out its budget for account rows
behind a stale error. The proof is an absence: **no identity HTTP call occurs during any stall window**;
the first `app-access` and `fan-passport` successes land after the last stall, in the one row that did
not stall, because by then a persisted session was present when that screen mounted.

## Do not

- **Do not change account selection.** It looks for the right text and the right text exists — the
  passport display names match character-for-character, verified against `loom_fan_passport`.
- **Do not make the shipped auth screen re-fetch.** A real user is not stuck: the error branch's
  `Continue to secure sign-in` is `onPressed: _startRemoteLogin` and works. Changing it would be
  altering the product to suit the test.
- **Do not lengthen the 2m45s budget.** The wait is correct; what it was waiting behind was stale.
- **Do not remove the stall instrumentation** added by `3cb47f8e`. It is what produced this diagnosis
  and it is how the next one of these gets found in one run instead of six.

## Verification

- A regression test that **fails before the fix and passes after**: an auth screen whose first
  `listAccounts` throws for want of a session, then a login, then an assertion that the account row
  becomes findable. Run it against the un-fixed code first — a test that cannot fail for the reason it
  claims proves nothing.
- All five suites, skip counts before pass counts: app shell **448 (+2)**, demo **265**, judges **525**,
  engine **345 (+1)**, service **168 (+1)** with both credential sets. All five measured green at these
  values on 2026-10-01, so any movement is yours. **If you lack Postgres access, say so** — engine and
  service will show more skips, which means your run proved less, and I will re-run them.
- `flutter analyze` on the demo app: **3** pre-existing issues; take the count from flutter's own
  `N issues found` line. A fourth is yours.

## And the honest note on provenance

This gap is mine. Ticket B said "authenticate as the seeded fan that actually holds this role" and said
nothing about making the surface re-read afterwards — even though the sibling path it sat beside
demonstrates that reopening is required. That is the fourth time in this programme that a specific of
mine, rather than an agent's judgement, turned out to be the defect, and all four share one shape:
**I specified the effect and left the mechanism to be inferred.**
