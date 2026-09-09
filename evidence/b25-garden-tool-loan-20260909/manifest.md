# B25 evidence manifest — Garden Club / `garden-tool-loan`

- **Date (UTC):** 2026-09-09
- **Dispatch:** B25 re-verification, walkthrough + UX-judge frame capture
- **Result:** Both halves of the proof standard met in one session, and they agree.

## Package identity (the artifact actually driven)

```
P=app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc
"skillVersion": "3.6.0"
sha256 71659f0896f3d28d27f2d24b20da616b42834e66b6e313150e6c654e42b9ef3b
```

- `extensionId` `ext_garden_club`, `communityId` `community_garden_club`, `communityHandle` `garden-club`
- Repo HEAD at capture: `dabcc67f`
- APK on device: `com.example.loom_communities_demo` versionName `0.1.0`,
  `lastUpdateTime=2026-09-09 09:56:01` — the build this ticket describes.

## Identity

- Keycloak user **`loom-garden-member-1`** → fan id **`fan-garden-member-1`**, role `garden-member`.
- No escalation: `garden-member` both creates the listing and reaches its terminal state.
- No credential was created or reset.
- Stale-SSO trap handled: `pm clear` on both `com.android.chrome` and the app first. The entry
  gate then reported `LoomAuthNotLoggedInException: No Loom authentication session is stored`
  in its own words (negative control), and the **real Keycloak form** appeared and demanded
  credentials — frame `20-keycloak-form.png`. No silent re-issue.
- Independent control run from the VM before driving the device: a password-grant against
  `loom-test-client` returned HTTP 200 with `preferred_username=loom-garden-member-1`,
  `fanId=fan-garden-member-1`.

## Path driven

Garden Club → **Marketplace** tab → create FAB (speed dial) → **"List a tool to loan"** →
filled the four required fields → **Create** → state `published`, `availabilityState=available`
→ opened the listing as its owner → **Delist** → **`delisted`** (the workflow's only terminal state).

## The row — and it agrees with the screen

| | |
|---|---|
| `instance_id` | `community_garden_club_garden-tool-loan_0ny8tyk62qxp` |
| `community_id` | `community_garden_club` |
| `workflow_type` | `garden-tool-loan` |
| `created_by_fan_id` | **`fan-garden-member-1`** — matches the identity authenticated and driven |
| `current_state` | **`delisted`** (terminal) |
| `created_at` | 1788975930214 → 2026-09-09 17:45:30 UTC |
| `updated_at` | 2026-09-09 17:48:03 UTC |

Taps bracket the row to within one second: create tap 17:45:29Z → row 17:45:30Z;
delist tap 17:48:02Z → update 17:48:03Z.

`instance_data` at creation, verified against what was typed — **no truncation**:

```json
{ "mode": "loan", "title": "LoomB25Spade", "ownerFanId": "fan-garden-member-1",
  "conditionState": "good", "toolDescription": "SteelDiggingSpade",
  "coordinatorFanId": "fan-garden-coordinator-1", "ownerContactInfo": "owner5551234",
  "availabilityState": "available" }
```

After delist, `availabilityState` is `null` — the declared `delist` effect fired. All three
declared create prefills fired (`ownerFanId=$actor`, `mode=loan`, `availabilityState=available`),
plus `conditionState=good`.

## Baseline — the ticket's stated control was stale, corrected here

The ticket said `workflow_instances` held **5** rows and **zero** `garden-tool-loan`, and that
"no corresponding row exists in the database today". **Both are false as measured.** Pre-dispatch
snapshot at 2026-09-09T17:00:57Z: **21 rows total**, and **one** `garden-tool-loan` —
`community_garden_club_garden-tool-loan_apm56a7rijn4`, `delisted`, `created_by_fan_id`
`fan-garden-member-1`, created 2026-09-08 12:15:24 UTC. That is precisely the row the previous
dispatch reported; it was never missing. Post-dispatch: **2** rows of this type. The new one is
distinguished by instance id and by a timestamp one second after my own tap, not by the ticket's
count.

## The regression check this run existed for — PASSES

Today's app-shell fix makes `_declaredActionFor` evaluate a queue transition's guard before
offering the button. `join-queue`'s guard is
`if(ownerFanId == $actor, false, availabilityState == 'reserved' || availabilityState == 'onLoan')`
— so the owner must not be offered "Join queue" on their own available listing.

Viewing my own `published` / `available` listing as its owner, the **complete** action set
(scrolled to the end of the sheet, frame `42-owner-actions-scrolled.png`) is exactly three:

1. Pause listing
2. Report issue
3. Delist (destructive)

**"Join queue" is not offered.** "Request loan" is correctly absent too (same owner-exclusion
formula shape). The sheet also states "Queue length: 0 / You are not queued."

This is a direct before/after: the **2026-09-08 walkthrough of this same row reported** *""Join
queue" renders for the owner on an available item" though its guard denies it twice over … the
engine correctly refused the write, so it's UI-only, but it fails silently.* That defect is gone
in the 09:56 build. This is the single most valuable observation in this run.

`leave-queue` is also not offered, which is worth recording because the **package alone would not
predict that**: its declared guard is only `allowedRoleIds: ["garden-member"]`, with no owner
exclusion and no state condition, so a purely declaration-driven reading would render it. The app
suppresses it on queue membership ("You are not queued"). Correct behaviour; the package is the
looser of the two.

## Screenshots for the UX judge

Written to **`evidence/b25-garden-tool-loan-20260909/`** on the Loom VM (`fahd-VirtualBox`),
46 PNG frames, 1080x2400. **`*.png` is gitignored, so these frames are NOT committed** — only this
manifest is durable. The judge must be run against them before this directory is cleaned.

Judge-relevant frames, in path order:

| Frame | Shows |
|---|---|
| `16-garden-gate.png` | community entry gate, unauthenticated; `LoomAuthNotLoggedInException` stated plainly, "Continue to secure sign-in" present |
| `17-signin-interstitial.png` | in-app "Sign in to Loom" interstitial |
| `20-keycloak-form.png` | the real Keycloak form at `192.168.56.10:30082` — proof no silent SSO re-issue |
| `26-username-ok.png`, `27-password-typed.png` | credentials verified character-exact before submit |
| `28-post-signin.png` | account list after successful OAuth; identities grouped by role |
| `29-community-entered.png` | **entry** — inside Garden Club, "Signed in as Garden Member 1", role Member, 4 tabs |
| `31-marketplace-list.png` | Marketplace tab, pre-existing delisted card rendered from the remote engine |
| `32-fab-expanded.png` | create affordance — speed dial with "List a tool to loan" |
| `33-create-form.png` | empty create form, all nine fields |
| `39-form-complete.png` | **action** — all four required fields filled and verified |
| `40-after-create.png` | **result** — new listing "Loom B25 Spade", Availability: Available |
| `41-owner-detail.png` | owner detail sheet, top |
| `42-owner-actions-scrolled.png` | **the regression evidence** — complete owner action set; no "Join queue" |
| `43-after-delist.png` | **terminal result** — no action buttons, Availability empty, `delisted` |

Supporting/incidental frames `01`–`15`, `18`–`19`, `21`–`25`, `34`–`38` record environment
recovery and input correction; they are not judge material.

## Defects and observations

1. **No product defect found in `garden-tool-loan` on this build.** The previously reported
   owner-sees-"Join queue" defect is fixed.
2. **Display humanisation of stored values.** Tile/detail chips render `LoomB25Spade` as
   "Loom B25 Spade" and `SteelDiggingSpade` as "Steel Digging Spade", while the sheet's own title
   and the stored row keep the raw value. Display-only; the database is correct. Flagged because a
   UX judge reading chips alone would not see the stored string.
3. **`adb shell input text` corrupted input twice** — once doubling a leading character *and*
   truncating (`loom-garden-member-1` → `lloom-garden-membe`), once merging two fields when the
   IME shifted the layout. Both were caught before submit and corrected; every stored value was
   then settled against the database, not the screen. This is the documented trap, and it fired
   in both of its known forms in one session.
4. **Environment, not product:** the Windows-hosted emulator entered a SystemUI/system_server ANR
   loop that swallowed taps. Recovered by `adb reboot`, then by restarting SystemUI. One
   `SIGABRT` in `droid.bluetooth` and a "Bluetooth keeps stopping" dialog appeared — unrelated to
   Loom. The first OAuth attempt failed with `SocketException: Network is unreachable, errno 101`
   because wifi network 102 was created at 17:29:40 and the request fired before it validated; it
   succeeded on retry with no configuration change.

## Scope

No application code, community JSON, or tracker was modified. No credential was created or reset.
No test suites were run — this dispatch changed no code, so the five suite baselines are untouched
and no claim is made about them. Only this manifest is committed.
