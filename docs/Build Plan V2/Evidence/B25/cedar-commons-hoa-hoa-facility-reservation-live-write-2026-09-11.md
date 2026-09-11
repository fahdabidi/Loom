**Workflow:** `hoa-facility-reservation` in Cedar Commons HOA
**Outcome:** BLOCKED — not a proof. The device could not complete Keycloak credential entry: the emulator ANR'd repeatedly (Chrome and the system process) at the sign-in form, so no instance was created and no live write was performed.

**Package identity driven:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `38c70ed08eabe2ef07011658bdea2434008e385b271e4ae6b98a29007369fd7f`
- Verified byte-identical to the copy **bundled inside the installed APK** (extracted from
  `app-debug.apk` → `assets/flutter_assets/packages/loom_communities_app_shell/...`; same sha256).
  APK built 2026-09-09 09:53, installed on `emulator-5554` 2026-09-09 09:56, `versionName=0.1.0`.

Date: 2026-09-11. Run host: Loom VM (`fahd-VirtualBox`, 192.168.56.10), emulator hosted on Windows,
reached via `adb -H 192.168.56.1 -P 5037`.

---

## 1. Identity attempted

`loom-hoa-member-1` / fan id `fan-hoa-member-1` / role `hoa-member`.

**Never authenticated in the app.** No escalation to another account was performed.

All three identity layers were verified present *before* device work (so this is not a seeding gap):

| Layer | Check | Result |
|---|---|---|
| Authentication | Keycloak password grant against `loom-test-client` | **HTTP 200**; token claim `fanId = fan-hoa-member-1`, `preferred_username = loom-hoa-member-1` |
| Identity | `loom_fan_passport.fan_passport` | row present (`fan-hoa-member-1`, "Hoa Member 1") |
| Authorization | `loom_app_access.group_membership_role` | `fan-hoa-member-1` → `hoa-member` in `loom_communities_cedar-commons-hoa` |

So the credentials in the brief are correct and working. The blocker is **not** authentication.

## 2. Baseline — measured, and the brief's hint was stale again

The brief guessed "about **3** rows [total], and few or none of `workflow_type =
'hoa-facility-reservation'`". Measured before touching anything:

- `workflow_instances` total: **25 rows**
- `hoa-facility-reservation`: **3 rows, all pre-existing**

| instance_id | created_by_fan_id | current_state | created (UTC) |
|---|---|---|---|
| `community_cedar_commons_hoa_hoa-facility-reservation_uc8clw8jfw8z` | `fan-test-alice` | `open` | 2026-08-26 05:48:38 |
| `community_cedar_commons_hoa_hoa-facility-reservation_3pbmhxf5srqh` | `fan-test-alice` | `reserved` | 2026-08-26 04:30:49 |
| `community_cedar_commons_hoa_hoa-facility-reservation_sx2yfw5tsmou` | `fan-test-alice` | `open` | 2026-08-26 04:10:25 |

This is the **third** consecutive walkthrough whose supplied baseline was wrong (after the
2026-09-09 `garden-tool-loan` and `platform-connection` runs). The stale-baseline warning in the
brief is well earned; treat the number as a hint only.

**Correction to the brief's premise.** The brief states the earlier claim is untrusted because "no
corresponding row exists in the database today." That is not accurate — three rows exist. What is
true, and sharper, is that **all three are attributed to `fan-test-alice`**, which is not a seeded
community account under the documented `fan-<slug>` convention and is consistent with a
direct-engine harness write rather than a UI walkthrough. `fan-hoa-member-1` has **never** created a
workflow instance of any type (`select ... where created_by_fan_id='fan-hoa-member-1'` → 0 rows).
So the right reason to distrust the earlier claim is **attribution**, not absence.

## 3. Final DB state — unchanged, no write performed

Re-queried at `2026-09-11T10:31:47Z`: still **25 rows** total, still the **same 3**
`hoa-facility-reservation` rows with the same instance ids, states and `created_at`. No row was
created by this session, and none is claimed.

**The two halves do not agree, because only one half exists:** there is no UI-driven terminal state
and no new row. This run proves nothing about the workflow.

## 4. Path actually driven, and where it stopped

Reached, on the device, through the real UI:

1. App launch → **"Loaded 10 example communities"**
2. Community list → tapped **Cedar Commons HOA**
3. Entry gate → `LoomAuthNotLoggedInException: No Loom authentication session is stored; login is
   required` (clean auth state — confirms no stale SSO session was in play)
4. **"Continue to secure sign-in"** → "Sign in to Loom" → **"Opening secure sign-in"**
5. Chrome Custom Tab → Keycloak at `192.168.56.10:30082`, page title **"Sign in to loom"**
6. **The real Keycloak login form rendered** — "Sign in to your account", Username/Password fields,
   Sign In button. On the second attempt it rendered fully styled. This is a genuine form, **not** a
   silent SSO re-auth, so the stale-cookie trap did not occur.
7. **STOPPED HERE.** Every attempt to put the username into the field ended in an ANR.

Attempt 1: `input text` delivered `ll` instead of `loom-hoa-member-1` (truncation/garbling under
load). Retyping character-by-character triggered **"Chrome isn't responding"**.
Attempt 2 (after a full emulator reboot): tapping the username field triggered **"Chrome isn't
responding"**, then **"Process system isn't responding"**, with the field left empty.

The username field was never populated, Sign In was never pressed, and no token was ever issued to
the app. Nothing downstream of sign-in — the facility-reservation create form, `reserve-facility`,
the `reserved` state — was reached or observed, and none of it is described here.

## 5. Why it stopped — measured, not inferred

The emulator is resource-starved, and it is the **host-side** emulator that is sick, not the VM.

- First degraded window: device `loadavg` **26.55 on 4 cores**, `MemFree` 201 MB of 4 GB,
  552 MB swap in use — with **382% of 400% CPU idle** and no D-state processes, i.e. blocked on
  I/O, not compute.
- Freeing ~1.5 GB by force-stopping background Google apps, and force-stopping Chrome, did not
  restore it.
- A guest reboot (`adb reboot`, which keeps the emulator process alive) put the guest into a
  **system_server watchdog kill loop**: `WATCHDOG KILLING SYSTEM PROCESS: Blocked in handler on main
  thread (main) for 60s`, with `system_server` pid cycling (1988 → 2663 → 3398 …) and the registered
  service count repeatedly climbing to ~300 then collapsing to ~100. Every `FATAL EXCEPTION` in that
  window was a downstream `DeadSystemException`, not an independent crash.
- It eventually self-recovered to `sys.boot_completed=1` with 1.3 GB free and 360% idle — and
  **still** ANR'd on Chrome and on the system process at the first touch of the login field.

The Loom VM itself was healthy throughout (`loadavg` ~2 on 8 cores); all six `loom` pods stayed
`1/1 Running`. This is not the documented "heavy build starves the node" pattern.

**I could not repair it.** The emulator process lives on the Windows host, and from the VM there is
no path to it: ports 22 / 3389 / 5985 / 5986 on `192.168.56.1` are all closed and the emulator
console port 5554 is not exposed (only the adb server on 5037). Killing the emulator was
deliberately **not** attempted, because nothing on this side could start it again.

## 6. Environment facts confirmed in passing (all healthy)

These were checked as pre-flight and are reported because they rule out several plausible
explanations for the failure:

- All six `loom` pods `1/1 Running` (app-access, fan-passport, keycloak, minio, postgres,
  workflow-service).
- **Cedar instance listing serves HTTP 200.** `GET /v1/communities/community_cedar_commons_hoa/instances`
  with a real bearer token returned 200 with items — the `JsonUnsupportedObjectError: Instance of
  'DateTime'` listing failure recorded in CLAUDE.md did **not** reproduce. Consistent with the
  mechanism: that leak needs an *ungated* `reminder` block, and `hoa-facility-reservation`'s reminder
  is gated on `enabledField: reminderEnabled`.
- No `403` / `unknown_permission_id` was observed — but note this was never exercised at the create
  path, so it is **not** evidence that the create authorization is fixed.
- Keycloak served the login page (its `DefaultCookieProvider` non-secure-context warning is logged at
  each render). ICMP to `192.168.56.10` fails from the device, which is normal for emulator NAT and
  is not a reachability signal.

## 7. Reusable notes

- **`uiautomator dump` was stale here, exactly as the brief warns.** On the rendered login form it
  reported **0 `EditText` nodes** and no web content while the screenshot showed the form plainly.
  The screenshot won. An affordance must not be reported missing on the strength of a dump.
- **Chrome's first-run onboarding did intercept the first OAuth redirect** ("Make Chrome your own" →
  dismissed with "Use without an account"). It took ~3 minutes to appear on a loaded emulator, during
  which the screen was blank — indistinguishable from a hang without sampling CPU.
- **`adb shell input text` garbled a 17-character username into `ll`.** Under load this is worse than
  the documented truncation. Anything load-bearing must be settled against the stored row.
- **Per-character `input` calls make it worse**, not better: each spawns a process on the box whose
  starvation is the problem, and that is what triggered the first Chrome ANR.

## 8. What a follow-up needs

Nothing in the backend or the package needs changing for this run to succeed; the blocker is
entirely the Windows-hosted emulator. A retry needs someone with Windows access to restart the
emulator (ideally with more RAM than 4 GB, given a debug Flutter APK plus a Chrome Custom Tab), after
which the recorded path above should run unchanged — the credentials, all three identity layers, the
package identity and the Cedar listing endpoint are all verified good as of today.
