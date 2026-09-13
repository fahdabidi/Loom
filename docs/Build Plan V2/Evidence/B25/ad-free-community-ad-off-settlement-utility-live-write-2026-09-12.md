**Workflow:** `ad-off-settlement-utility` in Ad-Free Community
**Outcome:** Both halves of the proof standard were met — signed in as `loom-ad-off-owner-1`, drove a community checkout from creation through `funded` to spawn instance `…_q8kq0j0ebi73`, then advanced that spawned row `allocated` → `settled` → **`audited`** through the Admin tab, confirmed in Postgres.

**Package identity:** `skillVersion: "3.6.0"`, sha256 `dd455f4890eec4fb71d6dc9ef189f9ef2c60e225effb07f59cb72a9dbd16a44c`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc`)

**Date:** 2026-09-13 (UTC; device clock 2026-09-12 local) · **Device:** `emulator-5554` (Windows host, via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)
**Community id (workflow-service):** `community_ad_free_community` — read off the row.
**Deployed image at time of run:** `loom-workflow-service:1.0.6`, `loom/app-access:0.3.11`.

## Identity — a real switch, not a stale session

Authenticated as **`loom-ad-off-owner-1`** / fan id **`fan-ad-off-owner-1`**, role `ad-off-owner`.

Switching from the member identity used for the suppression row, **both** stores were cleared, as the
standing rule requires:

    adb shell pm clear com.android.chrome
    adb shell pm clear com.example.loom_communities_demo

Confirmations that this produced a genuine re-authentication rather than an SSO replay:

- the launch screen showed **"Loaded 10 example communities"** (preload flag compiled into the APK);
- the account screen rendered `LoomAuthNotLoggedInException: No Loom authentication session is
  stored; login is required` with a **"Continue to secure sign-in"** route;
- Keycloak presented the **real username/password form** at `192.168.56.10:30082` — no silent
  re-issue of the previous fan's token;
- the account list was then selected as **Ad Off Owner 1 / `fan-ad-off-owner-1`**, matching the
  token's `fanId` (the app rejects a mismatch);
- the in-app header read **"Signed in as Ad Off Owner 1 — Owner"**, and the owner-only **Admin** tab
  appeared in the tab bar.

Chrome's first-run onboarding intercepted the redirect once and was dismissed with "Use without an
account". No credential was created or reset.

## Half 1 — driven live through the real UI

The spawning checkout (`ad-off-community-checkout`) is **not** a B25 row and needs no manifest; it is
recorded here only because it is the sole route to this workflow. This workflow has no create action
by design — it is spawned by `record-funding-confirmed`. That is not a defect.

| # | Surface | Action | Resulting state |
|---|---|---|---|
| 1 | Giving tab FAB **"Fund community ad-off"** | filled all 7 fields, **Create** | checkout `unfunded` |
| 2 | checkout card **"Give community ad-off"** | `start-funding` | `reviewing` |
| 3 | **"Checkout funding"** | `submit-funding` | `funding-pending` |
| 4 | **"Record verified funding"** (+ `Coverage Ends At` = `2026-10-13`) | `record-funding-confirmed` | `funded` — **spawns this row** |
| 5 | **Admin** tab → **"Record settlement"** | `record-settlement` | `settled` |
| 6 | **"Mark audited"** | `mark-audited` | **`audited`** |

Final UI state: state pill **"Allocation audited"**, showing `Settled 2026-09-13T01:11:30.401008Z`
and `Audited 2026-09-13T01:12:04.101643Z`.

## Half 2 — independently confirmed in Postgres, same session

| | |
|---|---|
| instance_id | `community_ad_free_community_ad-off-settlement-utility_q8kq0j0ebi73` |
| community_id | `community_ad_free_community` |
| created_by_fan_id | **`fan-ad-off-owner-1`** — matches the identity driven |
| current_state | **`audited`** |
| created_at | 1789261798428 — 2026-09-13T01:09:58Z |
| updated_at | 1789261924101 — 2026-09-13T01:12:04Z |
| fundingCheckoutId | `community_ad_free_community_ad-off-community-checkout_4hjswojdswwq` |

`instance_data` as stored:

    currency            USD
    fundedAmount        250.0
    fundedAt            2026-09-13T01:09:58.428316Z
    settledAt           2026-09-13T01:11:30.401008Z
    auditedAt           2026-09-13T01:12:04.101643Z
    payerFanId          fan-ad-off-owner-1
    utilityImpact       Removes ads slots for all members
    coverageEndsAt      2026-10-13
    allocationDetails   Ad slot buyout fund
    fundingCheckoutId   community_ad_free_community_ad-off-community-checkout_4hjswojdswwq

**The two halves agree**, including `created_by_fan_id` matching the authenticated identity, and both
`settledAt`/`auditedAt` effect writes landing with the same timestamps shown on screen.

## No terminal state is claimed

This workflow **declares no terminal state** and cycles by design (`record-refunded-allocation` and
`request-audit-export` remain available from `audited`). `audited` is the furthest state the intended
settlement path reaches and is reported as a clearly-advanced state, not a terminal one.

## Controls and integrity checks

- **Row count accounting.** Baseline at session start: **71** rows. After this run: **74**. All three
  are accounted for and none is unexplained:
  `…_4hjswojdswwq` (`ad-off-community-checkout`, `funded`), `…_q8kq0j0ebi73` (this row, `audited`),
  `…_ywc4cthhgy3g` (`ad-off-notification`, `unread` — spawned by `record-settlement`'s own
  `createInstance` effect, which independently confirms that effect ran).
- **The pre-existing settlement row was not touched.** `…_w4t179a9qkqi` (2026-09-09) still reads
  `allocated` with `updated_at = created_at`. This row is distinguished by its own instance id and
  `created_at`, not by the count moving.
- **No silent truncation.** `adb shell input text` truncates without erroring, so every typed value
  was settled against the stored row rather than against the screen. All survived in full — including
  `coverageDescription: "Community-wide ad-off coverage for 30 days"` on the parent checkout, which
  *displayed* as the truncated-looking `"nity-wide ad-off coverage for 30 days"` in the form because
  the field scrolls horizontally. The screen was misleading; the database was not.

## Device notes worth carrying

- **The creation dialog collapses to only the focused field when the IME opens**, hiding the other
  six. Coordinates read before the keyboard opened land on nothing. The working cycle was
  tap → type → `keyevent 4` to dismiss the IME → re-screenshot; the layout is stable only with the
  keyboard closed.
- **A card's screen position moves when its state changes**, because the card re-renders at a
  different height. After each transition the list had to be re-located rather than tapped from the
  previous screenshot.

## Defects observed

**None.** Every transition in the intended path fired as declared, every guard admitted the owner,
and every effect wrote. The six `NEEDS IMPLEMENTATION` fields in this package were empty as designed;
no transition guards on any of them.

## Verification command used

    PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
    kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom -d loom_workflow_service \
      -c "select instance_id, community_id, created_by_fan_id, current_state, created_at, updated_at
          from workflow_instances where workflow_type='ad-off-settlement-utility' order by created_at desc;"
