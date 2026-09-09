# Ad-Free Community — `ad-off-community-checkout` live write, 2026-09-09

**Workflow:** `ad-off-community-checkout` in Ad-Free Community
**Outcome:** Both halves of the proof standard were met — driven live to `funded` as `fan-ad-off-owner-1`, screen and database agreeing on state, all seven field values, both effect timestamps and the acting fan id.
**Declared `createInstance` effect fired:** a `ad-off-settlement-utility` instance in `allocated` whose `fundingCheckoutId` points back at this checkout — both rows confirmed in Postgres.
**Frames:** 38, gitignored; this record is durable.
**Source manifest:** `a0528ec7` — `evidence/b25-adfree-community-checkout-20260909/MANIFEST.md`

# B25 live walkthrough — Ad-Free Community / `ad-off-community-checkout`

**Date:** 2026-09-09 (device clock 12:27–12:52 PDT / 19:47–19:51 UTC)
**Result:** PROVEN — live UI drive to `funded`, confirmed by Postgres row in the same session.

## Package identity exercised

    skillVersion: 3.6.0
    sha256: dd455f4890eec4fb71d6dc9ef189f9ef2c60e225effb07f59cb72a9dbd16a44c
    file:   app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc

The asset **bundled inside the installed APK** was extracted and hashed independently; it is
byte-identical to the on-disk package above (same sha256). APK built 2026-09-09 09:53, installed
09:56, `versionName=0.1.0`, package `com.example.loom_communities_demo` on `emulator-5554`.

## Identity

- Keycloak user: `loom-ad-off-owner-1` (realm `loom`, client `loom-test-client`)
- Fan id: `fan-ad-off-owner-1`
- Role: `ad-off-owner` ("Owner")
- Token `fanId` claim verified `fan-ad-off-owner-1` before the run (HTTP 200 password grant).

All three seeding layers verified present **before** driving:

| Layer | Evidence |
|---|---|
| Authentication | Keycloak token HTTP 200, `fanId=fan-ad-off-owner-1` |
| Identity | `fan_passport` row `fan-ad-off-owner-1` ("Ad Off Owner 1") |
| Authorization | `group_membership_role`: `fan-ad-off-owner-1` → `ad-off-owner` in `loom_communities_ad-free-community` |

Stale-SSO precaution: `pm clear` on both the app and `com.android.chrome`, plus the Keycloak logout
endpoint (HTTP 200). The **real** Keycloak login form appeared (screenshot 09), and credentials were
typed and visually verified untruncated (screenshot 11) — so this is not a silently re-issued prior
session.

## Baseline measured in-session (not trusted from the brief)

    total workflow_instances          = 23
    ad-off-community-checkout rows    = 0   (zero — the reopened prior claim is confirmed absent)

The brief's hint of "about 22" was close; the measured figure was 23. The prior dispatch's claimed
row genuinely does not exist. A **new** instance was created rather than sought.

## Path driven (all through the real UI, as `ad-off-owner`)

1. Community list → **Ad-Free Community** → account-list entry gate
2. "Continue to secure sign-in" → Chrome custom tab → Keycloak form → redirect back
3. Selected **Ad Off Owner 1** (`fan-ad-off-owner-1`) — matches token `fanId`
4. **Giving** tab → FAB **"Fund community ad-off"** (`create`, `byRoleIds: ["ad-off-owner"]`)
5. Filled all 7 required `formEntry` fields → **Create** → state `unfunded`
6. **"Give community ad-off"** (`start-funding`) → `reviewing`; effect set `payerFanId = $actor`
7. **"Checkout funding"** (`submit-funding`) → `funding-pending`; effect set `submittedAt`
8. **"Record verified funding"** (`record-funding-confirmed`), input `coverageEndsAt = 2026-12-08`
   → **`funded`**

Final UI state (screenshot 39): **"Community ad-off funded"**, showing Funding amount 250,
Coverage 90 days, Community ad suppression, Utility impact, `Funded 2026-09-09T19:51:58.411618Z`,
`Coverage ends 2026-12-08`, and the sole remaining exit "Request funding refund".

## Database confirmation (same session)

    instance_id       | community_ad_free_community_ad-off-community-checkout_kn40pzdekrn3
    community_id      | community_ad_free_community
    workflow_type     | ad-off-community-checkout
    created_by_fan_id | fan-ad-off-owner-1
    current_state     | funded
    created_at        | 2026-09-09 19:47:32+00

`created_by_fan_id` **matches the identity driven**. The instance is distinguished by its instance id
and `created_at`, not by a change in row count.

### Stored `instance_data` (verified against typed input — no truncation)

    fundedAmount         250
    currency             USD
    coverageDurationDays 90
    coverageDescription  "Community ad suppression"
    paymentMethodLabel   "Community operations card"
    utilityImpact        "Funds ad-free access"
    allocationDetails    "Ad-serving replacement"
    payerFanId           "fan-ad-off-owner-1"      (effect, start-funding)
    submittedAt          "2026-09-09T19:50:31.884220Z"  (effect, submit-funding)
    fundedAt             "2026-09-09T19:51:58.411618Z"  (effect, record-funding-confirmed)
    coverageEndsAt       "2026-12-08"                   (transition input)

### Downstream `createInstance` effect also verified

`record-funding-confirmed` declares a `createInstance` of `ad-off-settlement-utility`. It fired:

    instance_id       | community_ad_free_community_ad-off-settlement-utility_w4t179a9qkqi
    workflow_type     | ad-off-settlement-utility
    created_by_fan_id | fan-ad-off-owner-1
    current_state     | allocated
    created_at        | 2026-09-09 19:51:58+00
    fundingCheckoutId | community_ad_free_community_ad-off-community-checkout_kn40pzdekrn3

The back-reference matches the checkout instance, so the effect target resolved against a **published**
definition rather than silently no-op'ing. Both `ad-off-community-checkout` and
`ad-off-settlement-utility` are present in `workflow_definitions`.

Row totals across the run: **23 → 24** (create) **→ 25** (settlement spawned by effect).

**Do the two halves agree? Yes.** Screen and database agree on state, on every field value, on the
funded/coverage timestamps, and on the acting fan id.

## Defects and incidents observed

1. **`adb shell input text` truncated two fields** (a tooling artifact of this harness, not a product
   defect). "Community-wide ad suppression for 90 days" (41 chars) stored as 35; "Funds ad-free
   access for all members" (35 chars) stored as 24. Both were caught **on screen** and retyped with
   shorter values, and the final stored values were then settled against `instance_data`. Consistent
   with the standing warning that this input path truncates silently.
2. **The create dialog collapses when the IME opens**, hiding all unfocused fields. A tap aimed at a
   later field landed in the focused one ("250USD" in Funding amount). `KEYCODE_TAB` advances focus,
   but walked focus **out of the dialog**, after which typed spaces activated whatever control held
   focus — which navigated away and attempted a sign-in as an unrelated account. This is a usability
   hazard for scripted input, not a defect in the workflow.
3. **The anti-impersonation guard fired correctly** during that stray navigation:
   `LoomAuthException(accountNotFound): The authenticated Loom identity cannot sign in as account
   "fan-hoa-admin"`. Working as designed — the owner session was unaffected and no row was written.
   Confirmed by querying the table immediately: still 23 rows, zero checkout rows.
4. No `403`, no `unknown_permission_id`, no crash. `FATAL EXCEPTION` count in logcat: **0**. The
   `system_app_anr` dropbox entries present on the device timestamp to 11:34 local, ~73 minutes
   before this run began, and are not attributable to it.

**No product defect was found in `ad-off-community-checkout`.** Every owner-guarded transition was
reachable, every guard was satisfiable by the role actually provisioned, the create surface rendered
for the acting role, and the effect target existed in the deployed catalog.

## Screenshots

38 frames, `01-launch.png` … `39-funded.png` (numbering is non-contiguous; two intermediate captures went to /tmp), in this directory. They are `*.png` and therefore
**gitignored and transient** — this manifest is the durable record.
