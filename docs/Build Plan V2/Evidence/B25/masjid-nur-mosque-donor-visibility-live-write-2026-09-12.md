**Workflow:** `mosque-donor-visibility` in Masjid Nur
**Outcome:** Both halves of the proof standard were met — driving the real UI on `emulator-5554` I created a `mosque-donation-payment` as `fan-masjid-member-1`, confirmed it as `fan-masjid-owner-1` (which spawned the donor-visibility row), then advanced that row `restricted` -> `public` as the donor, and independently confirmed every step in Postgres in the same session.

**Package identity exercised**
- Asset: `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`
- `  "skillVersion": "3.6.0",`
- `7a7b48223d14f7ae50237af3a7c290f646eb84ca2c1efa4c0f54ec9d6b6fe1ff  app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`) · **App:** `com.example.loom_communities_demo` versionName 0.1.0, `lastUpdateTime=2026-09-12 11:28:15`

---

## Identities authenticated

Both accounts were verified by password-grant against Keycloak realm `loom` (`192.168.56.10:30082`, client `loom-test-client`) **before** any device work, and each token's `fanId` claim was decoded:

| Keycloak user | HTTP | token `fanId` | role held | used for |
|---|---|---|---|---|
| `loom-masjid-member-1` | 200 | `fan-masjid-member-1` | `community-member` | steps 1 and 3 |
| `loom-masjid-owner-1` | 200 | `fan-masjid-owner-1` | `owner` | step 2 |

No credential was created or reset. Each of the three sign-ins was preceded by `pm clear` on **both** `com.android.chrome` and `com.example.loom_communities_demo`; a real Keycloak login form was observed and screenshotted every time, so no step ran on a stale SSO cookie. After each clear the launch screen showed **"Loaded 10 example communities"**, confirming the preload flag is compiled into this APK.

## Baseline — measured, not assumed

Queried before touching anything:

- `workflow_instances` total: **63 rows**
- `mosque-donor-visibility`: **0 rows** (a genuine negative result — the row did not exist)
- `mosque-donation-payment`: 1 pre-existing row, `..._xwr38n4tfb7z`, $75/Zakat/Private, `pending`, created 2026-09-08

That pre-existing donation was **not** reused. I created my own so every step is my own observation; my rows are distinguished by instance id and `created_at`, not by the row count. Final total: **65 rows** (+2 = my donation + the row it spawned).

## Path driven

**Step 1 — as `fan-masjid-member-1`.** Giving tab -> **Donate** FAB -> form (Amount `125`, Fund `Sadaqah`, Privacy `Public`, Giving plan `One-time`). The form carries **no `payerFanId` field**; it is prefilled from `$actor` and declared `writableBy: "platform"`, and the stored value came out as `fan-masjid-member-1` — full, untruncated. Then fired **"Submit donation"** (`draft` -> `pending`, guard `actorEqualsField: payerFanId`).

**Step 2 — as `fan-masjid-owner-1`.** The owner-only **Admin** tab appeared (it does not render for the member). Both donations render there; I identified mine by its payment-history timestamp `2026-09-12T22:22:40.131963Z` and confirmed the `$125 / Sadaqah / Public` chips before acting, so as not to fire on the 2026-09-08 row sitting directly below it. Fired **"Record offline payment"** (`confirm-offline-donation`, `pending` -> `paid`, guard `allowedRoleIds: ["owner"]`), supplying the required `receiptSummary` input `cash-b25-20260912`. **This is the transition that spawned the row under proof.**

**Step 3 — as `fan-masjid-member-1`.** The spawned donor-visibility card rendered on the Giving tab as *"Restricted to donation records"*, offering **"Reveal name"** and **"Keep anonymous"** — and correctly **not** "Restrict name", since the row was already `restricted`. Fired **"Reveal name"** (`restricted` -> `public`, guard `actorEqualsField: donorFanId`).

## The row under proof — Postgres

```
instance_id       community_mosque_mosque-donor-visibility_vpmkl5kxpmzl
community_id      community_mosque
workflow_type     mosque-donor-visibility
created_by_fan_id fan-masjid-owner-1
current_state     public
created_at        2026-09-12 22:28:37+00
```

```
instance_data
{"donorFanId":"fan-masjid-member-1","amount":125,"fund":"Sadaqah",
 "receiptVisibility":"Identity restricted to donor's private record","visibilityHistory":[]}   <- at spawn

visibilityHistory after "Reveal name"
[{"at": "2026-09-12T22:33:06.020042Z", "by": "fan-masjid-member-1", "choice": "public"}]
```

**`donorFanId` is `fan-masjid-member-1`, verbatim.** The `createInstance` effect's `{payerFanId}` token interpolated correctly — it is not empty, not null, and not the literal `{payerFanId}`. `amount` (125) and `fund` (Sadaqah) carried across from the donation too.

Note on `created_by_fan_id`: it is `fan-masjid-owner-1` because the owner fired the spawning transition, while `donorFanId` is the member. That is the designed split, and it is exactly why step 3 requires switching back — all three of this workflow's transitions are guarded `actorEqualsField: donorFanId`, so the owner cannot advance the row they caused to exist.

### Vehicle row (already-proven `mosque-donation-payment`, driven only to produce the above)

```
instance_id       community_mosque_mosque-donation-payment_cn6z8xrgfp6j
created_by_fan_id fan-masjid-member-1
current_state     paid          paymentStatus: paid-manual
payerFanId        fan-masjid-member-1
receiptSummary    cash-b25-20260912
paymentHistory    [{intent-submitted, by fan-masjid-member-1, 2026-09-12T22:22:40.131963Z},
                   {offline-payment-recorded, by fan-masjid-owner-1, 2026-09-12T22:28:37.400321Z}]
```

No second manifest is filed for this workflow; it is already proven and is recorded here only as the vehicle.

## Do the two halves agree?

**Yes, on every field checked.** The device rendered *"Public donor"*, `Amount: $ 125`, `Fund: Sadaqah`, *"Name visible on donor-facing receipt and public roll"*, and a Preference history reading `Choice: public / By: fan-masjid-member-1 / At: 2026-09-12T22:33:06.020042Z` — which is byte-identical to the `visibilityHistory` entry in Postgres. The donation card likewise showed *"Paid — manually recorded"* with both history entries attributed to the correct, different fans. `created_by_fan_id` on the vehicle row matches the identity I drove it as.

## Defects observed

**None.** Every guard behaved as declared, the spawn effect fired, the interpolation resolved, and the member-guarded transition was reachable by the member and not the owner.

Two non-defect observations worth recording:

1. **The receipt summary is title-cased for display.** I typed and stored `cash-b25-20260912`; the card renders `Receipt: Cash B25 20260912`. The stored value is exactly what was entered (confirmed in `instance_data`), so this is a presentation transform, not data mutation. Flagged only because reading that value off the screen would not have matched the database — the stored row is the right thing to settle against.
2. **The paid donation left the owner's Admin surface.** After `pending` -> `paid` the $125 card was no longer in the Admin list, which still showed the older `pending` row. The member's Giving tab shows it correctly as *"Paid — manually recorded"*, and the DB is authoritative and correct, so nothing is lost; noted only as observed rendering behaviour, not investigated further as it is outside this row's scope.

## Environment

- All six `loom` pods `1/1 Running` throughout.
- No ANR (`dumpsys window lastanr`: *"no ANR has occurred since boot"*), and `0` occurrences of `FATAL EXCEPTION` in logcat.
- No application code, community JSON, or tracker was modified. No credential was created or reset. This manifest is the only file committed.
