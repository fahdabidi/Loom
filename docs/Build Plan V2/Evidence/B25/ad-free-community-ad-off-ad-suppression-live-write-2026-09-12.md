**Workflow:** `ad-off-ad-suppression` in Ad-Free Community
**Outcome:** BLOCKED — not a proof. The row was spawned live and confirmed in Postgres, but it **cannot be advanced by anyone**: every transition request against it fails server-side with `FormulaEvaluationException: Expected bool, got null`, so `acknowledge-proof` never fires and the row is stuck in `unreviewed`. Half 1 of the proof standard was not met; I am not claiming it.

**Package identity:** `skillVersion: "3.6.0"`, sha256 `dd455f4890eec4fb71d6dc9ef189f9ef2c60e225effb07f59cb72a9dbd16a44c`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc`)

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)
**Community id (workflow-service):** `community_ad_free_community` — read off the row.

## What DID succeed

| | |
|---|---|
| instance_id | `community_ad_free_community_ad-off-ad-suppression_bessl9tachgu` |
| created_by_fan_id | `fan-ad-off-owner-1` (spawned by the owner's `record-payment-confirmed`) |
| current_state | **`unreviewed`** — the initial state, never advanced |
| created_at | 1789254987485 — 2026-09-12T23:16:27Z |
| updated_at | 1789254987485 — **identical to `created_at`; the row was never mutated** |
| checkoutInstanceId | `community_ad_free_community_ad-off-member-checkout_o1otolp4pkda` |
| memberFanId | `fan-ad-off-member-1` |

The row was spawned correctly and renders correctly. Its card is visible to the member, shows
*"Suppression proof ready"*, the suppressed surfaces, the no-fill reason, a **Linked Entitlements**
block resolving to my entitlement `…_jam3e7fa6bqx`, and a **"Mark reviewed"** button. The affordance
is present — this is not a missing-affordance report.

## Where it stopped

Signed in as `loom-ad-off-member-1` (`fan-ad-off-member-1`, role `ad-off-member`) — exactly the role
`acknowledge-proof` requires, and the fan in this row's `memberFanId`. Tapped **"Mark reviewed"**.

The device showed: **"Could not save this change. Please try again."** with a Retry button.
Tapped again; identical failure. Postgres confirms no state change on either attempt.

`workflow-service` logged, both times, for
`POST /v1/communities/community_ad_free_community/instances/community_ad_free_community_ad-off-ad-suppression_bessl9tachgu/transitions`:

    "errorType":"FormulaEvaluationException"
    "error":"FormulaEvaluationException: Expected bool, got null"
      #0  _bool            (formula_evaluator.dart:408)
      #1  _evaluate        (formula_evaluator.dart:239)
      #2  evaluateFormula  (formula_evaluator.dart:139)
      #3  evaluateGuard    (guard_evaluator.dart:64)
      #4  availableTransitions.<anonymous closure> (transition_evaluator.dart:27)
      #10 availableTransitions                     (transition_evaluator.dart:48)
      #11 LocalWorkflowEngineApi._resolveTransition (local_workflow_engine_api.dart:1205)
      #12 LocalWorkflowEngineApi.applyTransition    (local_workflow_engine_api.dart:1085)

## Mechanism

The package declares `isSuppressionActive` as a **formula field** over a **query-sourced** field:

    linkedEntitlements      source:  query(ad-off-entitlement-status where checkoutInstanceId == checkoutInstanceId)
    entitlementStateCounts  formula: groupCount(linkedEntitlements, '$state')
    isSuppressionActive     formula: mapGet(entitlementStateCounts,'active') + … > 0

and the third transition, `request-restoration`, guards on `formula: "!isSuppressionActive"`.

On the **render** path that formula evaluates fine — the card displays *"Ads suppressed now: Yes"*.
On the **server guard** path it resolves to `null`, and `!null` throws.

**The damage is not confined to `request-restoration`.** `_resolveTransition` calls
`availableTransitions`, which evaluates **every** transition's guard eagerly inside a `.where(...)`.
One guard throwing aborts the whole enumeration, so the request fails before `acknowledge-proof` is
ever considered — even though `acknowledge-proof`'s own guard (`ad-off-member` +
`actorEqualsField: memberFanId`) is perfectly satisfiable and was satisfied. **All three transitions
are therefore dead, and the workflow has no reachable state beyond `unreviewed`.**

## Evidence this is deterministic and pre-existing, not my run

- **Two identical failures** on two attempts, same exception, same instance.
- **The prior run's row is stuck the same way.** `…_2d0t7n4botql`, spawned 2026-09-08, is still
  `unreviewed` with `updated_at` equal to its `created_at` — it was never advanced either. Two rows,
  four days apart, same terminal-at-birth state.
- **Contrast, same session, same actor, same community:** the sibling rows spawned by the *same*
  transition advanced without trouble — `ad-off-entitlement-status` through three transitions
  (`active` → `change-requested` → `change-declined` → `active`) and `ad-off-receipt-evidence`
  through two `instance_data` mutations. So this is not authentication, authorization, membership,
  connectivity or node load; it is specific to this workflow's guard.

This is the shape `CLAUDE.md` already describes — a capability that is well-formed in the package and
unreachable as deployed, and a formula that evaluates in one context and not another. It is recorded
here rather than fixed: **no fix was attempted, and no code, JSON or tracker was modified.**

## Not the cause

The package's six `NEEDS IMPLEMENTATION` annotations are all on **fields**, and **no transition
guards on any of them** — including this one. They are not implicated, and the empty
`paymentConfirmationId` / receipt-id / settlement-id fields are the expected designed state.

## Cross-references

- `ad-free-community-ad-off-entitlement-status-live-write-2026-09-12.md` — proven, and carries the
  step-4 `{id}`-in-`transitionRelated`-filter measurement (result: the cascade silently did nothing).
- `ad-free-community-ad-off-receipt-evidence-live-write-2026-09-12.md` — proven.
