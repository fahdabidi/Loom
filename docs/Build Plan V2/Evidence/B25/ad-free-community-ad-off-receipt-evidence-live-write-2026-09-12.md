**Workflow:** `ad-off-receipt-evidence` in Ad-Free Community
**Outcome:** Both halves of the proof standard were met — the row was spawned live by an owner firing `record-payment-confirmed` on a member checkout I created through the UI, then advanced by the member firing `view-receipt` and `request-receipt-export`, each confirmed as a distinct `instance_data` mutation in Postgres.

**Package identity:** `skillVersion: "3.6.0"`, sha256 `dd455f4890eec4fb71d6dc9ef189f9ef2c60e225effb07f59cb72a9dbd16a44c`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc`)

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)
**Community id (workflow-service):** `community_ad_free_community` — read off the row.

## Identities authenticated

Two real Keycloak logins, each preceded by `pm clear` of **both** Chrome and the Loom app. A real
login form rendered both times (no silent SSO re-issue); both fields were read back off the form
before submitting.

| Step | Keycloak user | fan id | role |
|---|---|---|---|
| create vehicle, advance this row | `loom-ad-off-member-1` | `fan-ad-off-member-1` | `ad-off-member` |
| spawn this row | `loom-ad-off-owner-1` | `fan-ad-off-owner-1` | `ad-off-owner` |

## Baseline, measured before touching anything

`workflow_instances` held **67** rows. A **prior partial run existed** (checkout `…_9kmvxftjpbjr`
from 2026-09-08 plus three spawned rows at their initial states). I did not reuse it; this manifest
describes only my own row, distinguished by instance id and `created_at`. Final count **71**.

## How this row is created — no create action exists

`ad-off-receipt-evidence` has **no create action anywhere in the package**. It is spawned, together
with `ad-off-entitlement-status` and `ad-off-ad-suppression`, by a single owner transition
`record-payment-confirmed` on an `ad-off-member-checkout`. The absence of a create FAB is by design
and is not reported as a defect.

Vehicle: `ad-off-member-checkout` `…_o1otolp4pkda`, created by `fan-ad-off-member-1`, driven
`offer` → `reviewing` → `payment-pending` by the member, then `record-payment-confirmed` by the owner
(inputs `renewalDate 2026-10-12`, `expiryDate 2027-09-12`, both settled against the DB untruncated).

## Half 1 — driven live through the real UI

This workflow declares **no terminal state**, and both member actions are `to: null`, so the row
legitimately stays in `issued`. The proof is therefore the **`instance_data` mutation**, as the
ticket requires — not a state change.

| # | Actor | Transition (UI label) | Effect |
|---|---|---|---|
| 1 | owner | `record-payment-confirmed` | spawned this row in `issued` |
| 2 | member | `view-receipt` ("View receipt") | sets `lastViewedAt` |
| 3 | member | `request-receipt-export` ("Export receipt") | sets `exportRequestedAt` |

The card was identified on-device by its rendered reference — *"Entitlement purchase: … Checkout
O1otolp4pkda"* and *"Issued 2026-09-12T23:16:27.475774Z"* — which distinguishes it from the prior
run's card (`9kmvxftjpbjr`, issued 2026-09-08) sitting directly below it in the same list.

## Half 2 — confirmed independently in Postgres, same session

| field | value |
|---|---|
| instance_id | `community_ad_free_community_ad-off-receipt-evidence_1soi5ctv9ivk` |
| created_by_fan_id | `fan-ad-off-owner-1` |
| current_state | `issued` (unchanged by design — both actions are `to: null`) |
| created_at | 1789254987475 — 2026-09-12T23:16:27Z |
| updated_at | 1789255627313 — 2026-09-12T23:27:07Z |
| checkoutInstanceId | `community_ad_free_community_ad-off-member-checkout_o1otolp4pkda` |
| memberFanId | `fan-ad-off-member-1` |
| **lastViewedAt** | **`2026-09-12T23:26:29.627063Z`** — was absent before step 2 |
| **exportRequestedAt** | **`2026-09-12T23:27:07.313043Z`** — was absent before step 3 |

Both fields were empty on the prior run's row `…_gp6hlkqbd21l` throughout, which serves as an
in-table control that the writes came from my two taps and not from spawning.

**Do the two halves agree? Yes.** Each tap produced exactly one new timestamp field on exactly the
row whose reference the card displayed, and `updated_at` advanced with each.

**On `created_by_fan_id`:** `fan-ad-off-owner-1` is correct, not a mismatch — the row has no create
path, so its creator is the owner who fired the spawning transition; the member I drove steps 2–3 as
is recorded in `memberFanId`.

## Cross-references

- **The `{id}`-in-`transitionRelated`-filter measurement** (step 4 of this campaign) is recorded in
  `ad-free-community-ad-off-entitlement-status-live-write-2026-09-12.md`. Result: the cascade
  silently did nothing.
- **`ad-off-ad-suppression`, spawned by the same transition, is completely blocked** by a server-side
  `FormulaEvaluationException` — see
  `ad-free-community-ad-off-ad-suppression-live-write-2026-09-12.md`. It did not affect this row.

## Expected-empty fields

The package's `NEEDS IMPLEMENTATION` annotations on receipt-id generation and related fields sit on
**fields**, not transitions, and nothing guards on them. Those fields are empty — the designed state
against platform services that do not exist, not a blocker.

One observation, not a defect: `request-refund` on this row is gated by `formula: refundEligible`
and its affordance rendered only later in the session. I did not fire it; it is outside this row's
proof.
