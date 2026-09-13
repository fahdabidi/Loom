**Workflow:** `ad-off-ad-suppression` in Ad-Free Community
**Outcome:** Both halves of the proof standard were met — signed in as `loom-ad-off-member-1`, opened the live "Suppression proof ready" card on the Home tab and fired `acknowledge-proof` ("Mark reviewed"), advancing instance `…_bessl9tachgu` from `unreviewed` to `reviewed` in Postgres with `updated_at` no longer equal to `created_at`.

**This row was previously BLOCKED and is now reachable.** The manifest this file replaces recorded that every transition against this instance failed server-side with `FormulaEvaluationException: Expected bool, got null`, leaving it immovable in `unreviewed`. The fix (Loom `03b93f1c` — a throwing guard now disqualifies only its own transition) was deployed as **`loom-workflow-service:1.0.6`**, and this run confirms the button works on a real device.

**Package identity:** `skillVersion: "3.6.0"`, sha256 `dd455f4890eec4fb71d6dc9ef189f9ef2c60e225effb07f59cb72a9dbd16a44c`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc`)

**Date:** 2026-09-13 (UTC; device clock 2026-09-12 local) · **Device:** `emulator-5554` (Windows host, via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)
**Community id (workflow-service):** `community_ad_free_community` — read off the row.
**Deployed image at time of run:** `loom-workflow-service:1.0.6` (pod `workflow-service-666578b69b-8rw8l`, 3 minutes old at session start), `loom/app-access:0.3.11`.

## Identity

Authenticated as **`loom-ad-off-member-1`** / fan id **`fan-ad-off-member-1`**, role `ad-off-member`.
The session was already live from an earlier run; the in-app "Account role and permissions" dialog was
opened first and read **"Signed in as Ad Off Member 1 … ID: fan-ad-off-member-1"**, role `Member`,
before anything was driven. No credential was created or reset.

## Half 1 — driven live through the real UI

1. Ad-Free Community → **Home** tab. Card **"Suppression proof ready"** rendered. (The affordance was
   never missing — this matches what the prior run reported.)
2. Two suppression cards render on this tab. They were disambiguated by the `checkoutInstanceId`
   shown in the card's Linked Entitlements block, joined against Postgres, so the correct instance
   was targeted rather than whichever card happened to be on screen:
   - `…_o1otolp4pkda` → instance `…_bessl9tachgu` ← **the target**
   - `…_9kmvxftjpbjr` → instance `…_2d0t7n4botql` (left untouched, see control below)
3. Tapped **"Mark reviewed"** on the target card.
4. The card's state pill changed to **"Suppression proof reviewed"** and its button changed to
   **"Review later"** — which is `review-again`, firable only from `reviewed`.

## Half 2 — independently confirmed in Postgres, same session

| | |
|---|---|
| instance_id | `community_ad_free_community_ad-off-ad-suppression_bessl9tachgu` |
| community_id | `community_ad_free_community` |
| created_by_fan_id | `fan-ad-off-owner-1` — see note below |
| current_state | **`reviewed`** (was `unreviewed`) |
| created_at | 1789254987485 |
| updated_at | **1789261021760 — no longer equal to `created_at`** |
| acknowledgedAt | `2026-09-13T00:57:01.760119Z` (written by the transition's effect) |
| memberFanId | `fan-ad-off-member-1` |

**The two halves agree.** The UI showed `reviewed` and the database holds `reviewed`, with the
`acknowledgedAt` effect written.

**On `created_by_fan_id` being the owner, not me.** This row is *spawned* by a `createInstance` effect
on the owner's `record-payment-confirmed`, so the creator column records the owner and always did —
it is not evidence about who fired `acknowledge-proof`. The actor is established instead by the
guard: `acknowledge-proof` carries `allowedRoleIds: ["ad-off-member"]` **and**
`actorEqualsField: {key: memberFanId}`, and `memberFanId` on this row is `fan-ad-off-member-1`. Only
that fan could have fired it, and it fired.

## Control — the sibling row proves the write was targeted

The other suppression row, `…_2d0t7n4botql`, was left alone and still reads `unreviewed` with
`updated_at = created_at` (never mutated) and `acknowledgedAt` null. So the state change is
attributable to the specific button pressed, not to a broad sweep or a re-render.

## `request-restoration` — absent, as expected, but NOT cleanly diagnostic

`request-restoration` ("Restore ad-off") did not render, which the ticket predicted. **I cannot
distinguish the two possible reasons from the device**, and am not claiming the stronger one:

- its guard formula is `!isSuppressionActive`, and the card itself displayed **"Ads suppressed now:
  Yes"** — so `!isSuppressionActive` is legitimately **false** here, which alone suffices to hide it;
- the ticket's expectation is that the same formula yields `null` server-side and the transition is
  now *excluded* rather than aborting the whole enumeration.

Both predict absence. The decisive evidence that the fix took is elsewhere and is unambiguous:
**under the old behaviour a single throwing guard killed all three transitions, and here
`acknowledge-proof` succeeded and `review-again` subsequently rendered.** The enumeration no longer
aborts.

## Defects observed

**None in this workflow.** The previously reported blocker is resolved on the deployed build.

Two notes carried forward, neither a defect in this row:

- The deeper render/guard asymmetry behind `request-restoration`'s `null`-valued query-sourced field
  is tracked separately and was deliberately not fixed. It is not observable as a failure here.
- As the owner (during the Row 2 session on the same device), this same card correctly rendered
  **"Suppression proof reviewed"** with **no** "Mark reviewed" button — the member-only guard is
  enforced on the render side too. This is a second, independent confirmation of the state change
  from a different identity.

## Verification commands used

    PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
    kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom -d loom_workflow_service \
      -c "select instance_id, created_by_fan_id, current_state, created_at, updated_at,
                 (updated_at=created_at) as never_mutated,
                 instance_data::jsonb->>'acknowledgedAt'
          from workflow_instances where workflow_type='ad-off-ad-suppression' order by created_at;"

Baseline measured at session start, before anything was driven: **71** rows in `workflow_instances`,
**2** of `ad-off-ad-suppression`, both `unreviewed` and both with `updated_at = created_at`.
