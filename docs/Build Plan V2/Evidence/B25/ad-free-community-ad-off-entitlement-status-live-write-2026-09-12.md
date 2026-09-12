**Workflow:** `ad-off-entitlement-status` in Ad-Free Community
**Outcome:** Both halves of the proof standard were met — the row was spawned live by an owner firing `record-payment-confirmed` on a member checkout I created through the UI, then advanced by the member through `request-plan-change` → `withdraw-plan-change` → `acknowledge-change-decision` and confirmed in Postgres at every step.

**Package identity:** `skillVersion: "3.6.0"`, sha256 `dd455f4890eec4fb71d6dc9ef189f9ef2c60e225effb07f59cb72a9dbd16a44c`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc`)

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)
**Community id (workflow-service):** `community_ad_free_community` — read off the row, not constructed.

## Identities authenticated

Two real Keycloak logins, each preceded by `pm clear` of **both** `com.android.chrome` and
`com.example.loom_communities_demo`. Both times a real login form rendered (no silent SSO re-issue),
and both username and password were read back off the form before submitting, untruncated.

| Step | Keycloak user | fan id | role |
|---|---|---|---|
| 1, 3, 4 | `loom-ad-off-member-1` | `fan-ad-off-member-1` | `ad-off-member` |
| 2 | `loom-ad-off-owner-1` | `fan-ad-off-owner-1` | `ad-off-owner` |

## Baseline, measured before touching anything

`workflow_instances` held **67** rows, not "few or none" of the ad-off types: a **prior partial run
existed** — checkout `…_9kmvxftjpbjr` (2026-09-08) plus three spawned rows, all still at their
initial states, i.e. steps 3 and 4 had never been driven. Per the ticket I did not reuse it; I
created my own instance and distinguish every claim below by instance id and `created_at`.
Final count **71** (+4: one vehicle checkout and the three spawned rows).

## The vehicle (not a B25 row)

`ad-off-member-checkout` `…_o1otolp4pkda`, created_by `fan-ad-off-member-1`, `created_at`
1789254587469 (2026-09-12T23:09:47Z), driven `offer` → `reviewing` → `payment-pending`.

`disclosureAcknowledged` — the bool that gates `submit-payment` — is entered through a **toggle**,
not a text field, and stored as a real JSON boolean `true` (not the string `"true"`). The
"Checkout" affordance was present, so the formula guard was satisfied. `coverageDescription`
stored in full despite the on-screen field scrolling horizontally.

## Half 1 — driven live through the real UI

| # | Actor | Transition | Result |
|---|---|---|---|
| 1 | member | `record-payment-confirmed` (fired by owner) | spawned this row in `active` |
| 2 | member | `request-plan-change` ("Manage subscription", input `requestedPlan: annual`) | `active` → `change-requested` |
| 3 | member | `withdraw-plan-change` ("Keep current plan") | `change-requested` → `change-declined` |
| 4 | member | `acknowledge-change-decision` ("Keep current plan") | `change-declined` → `active` |

Note the ticket's step-3 wording ("fire `acknowledge-change-decision` **or** `withdraw-plan-change`
to bring it back to `active`") is inexact: `withdraw-plan-change` goes to `change-declined`, so
returning to `active` requires **both**, in that order. That is what I drove.

This workflow declares **no terminal state** — it cycles by design — so the proof is the advanced
states above, not a terminal one.

## Half 2 — confirmed independently in Postgres, same session

    select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at
    from workflow_instances where workflow_type='ad-off-entitlement-status' ...

| field | value |
|---|---|
| instance_id | `community_ad_free_community_ad-off-entitlement-status_jam3e7fa6bqx` |
| created_by_fan_id | `fan-ad-off-owner-1` |
| current_state | `active` (after the four-step walk above) |
| created_at | 1789254987440 — 2026-09-12T23:16:27Z |
| updated_at | 1789255544878 — 2026-09-12T23:25:44Z |
| checkoutInstanceId | `community_ad_free_community_ad-off-member-checkout_o1otolp4pkda` |
| memberFanId | `fan-ad-off-member-1` |
| renewalDate / expiryDate | `2026-10-12` / `2027-09-12` — both settled against the DB, untruncated |

**Do the two halves agree? Yes.** Every state the UI showed matched the stored row at the moment it
was read.

**On `created_by_fan_id`:** it is `fan-ad-off-owner-1`, not the member — and that is correct, not a
mismatch. This row has **no create action anywhere in the package**; it is spawned by the owner's
`record-payment-confirmed`, so the owner is its creator, while `memberFanId` records the member it
belongs to. The member identity I drove in steps 3–4 is the one in `memberFanId`.

## THE MEASUREMENT — `{id}` inside a `transitionRelated` filter

Controlled test of the open defect, run last, with the entitlement deliberately returned to `active`.

**Pre-state**, read immediately before firing:

    ad-off-member-checkout    …_o1otolp4pkda   active   (updated_at 1789254987485)
    ad-off-entitlement-status …_jam3e7fa6bqx   active   (updated_at 1789255544878)
                                               checkoutInstanceId = …_o1otolp4pkda

Fired `cancel-subscription` on the checkout as `fan-ad-off-member-1`, whose effects declare

    transitionRelated → relatedQuery { workflowType: "ad-off-entitlement-status",
                                       filter: { "checkoutInstanceId": "{id}", "$state": "active" } }
                        transitionId: "member-deactivate"

**Post-state, verbatim from Postgres:**

    ad-off-member-checkout    …_o1otolp4pkda   cancelled   (updated_at 1789255685494)
    ad-off-entitlement-status …_jam3e7fa6bqx   active      (updated_at 1789255544878 — UNCHANGED)

### Result: **the cascade silently did nothing.**

The entitlement's `current_state` is still `active` and its `updated_at` did not move at all, so it
was never touched. Per the ticket's table this is the second outcome.

**Three things make this a clean measurement rather than a guess:**

- **The rest of the same effect list ran.** `cancelledAt: "2026-09-12T23:28:05.494016Z"` was written
  to the checkout by the sibling `set` effect. So the transition executed and its effects were
  applied; only the three `transitionRelated` entries matched nothing.
- **The request succeeded.** No error, no non-2xx, nothing in `workflow-service` logs for this
  request. It is a silent no-op, not a reported failure.
- **The `{id}`-in-`fields` control works, and was proven three times in this very run.**
  `start-checkout`'s `checkoutReferenceId: "{id}"` stored the checkout's own id, and all three
  spawned rows carry `checkoutInstanceId` = `…_o1otolp4pkda`. Same token, same instance, same
  session — resolving correctly in `fields` and matching nothing in a filter.

**Guards cannot confound it:** `cancel-subscription` and the target `member-deactivate` carry the
identical guard (`allowedRoleIds: ["ad-off-member"]` + `actorEqualsField: memberFanId`), I held that
role, and I fired `member-deactivate`'s sibling transitions on this very row minutes earlier. The
target row was in `active`, exactly the state the first filter names.

This is an independent live reproduction, on a different community, of the behaviour recorded in
`CLAUDE.md` under "Interpolation tokens resolve differently in different contexts". **No fix was
attempted.**

## Defect observed in a sibling row (cross-reference)

`ad-off-ad-suppression` — spawned by the same transition — is **completely blocked** by a server-side
`FormulaEvaluationException`. See
`ad-free-community-ad-off-ad-suppression-live-write-2026-09-12.md`. It does not affect the two
halves proven above.

## Expected-empty fields

The package's six `NEEDS IMPLEMENTATION` annotations (`paymentConfirmationId`, receipt- and
settlement-id generation) sit on **fields**, and no transition guards on any of them. Those fields
are empty, which is the designed state against platform services that do not exist — not a blocker
and not a finding.
