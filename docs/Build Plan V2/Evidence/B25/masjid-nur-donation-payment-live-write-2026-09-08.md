# Masjid Nur — `mosque-donation-payment` live write, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles = UTC-7; engine stamps are UTC, so
`10:42:05.791229Z` is 03:42 local)
**Device:** `emulator-5554`, Android 16 (SDK 36), `sdk_gphone64_x86_64`, 1080x2400
**adb path:** the emulator is **Windows-hosted**; this session ran **on the Loom VM itself**
(`fahd-VirtualBox`), which has no AVD. It was reached by talking to the **Windows host's adb
server** — `adb -H 192.168.56.1 -P 5037`. The VM-local adb server saw zero devices.
**App:** `com.example.loom_communities_demo/.MainActivity`, APK installed 2026-09-08 00:17:13
**Workflow:** `mosque-donation-payment` in Masjid Nur (`community_mosque`, `ext_mosque`)
**Supersedes:** the reopened Masjid Nur claim, which had no corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and the UI evidence and the Postgres
row are reported together and **agree**.

- Signed in for real as `loom-masjid-member-1` through the in-app OAuth flow against Keycloak.
- Created a `mosque-donation-payment` **from nothing** through the real UI (the "Donate" FAB on the
  Giving tab), reaching `draft`.
- Drove `submit-donation-intent` through the real UI, reaching **`pending`**.
- Read the row back from Postgres with `kubectl exec … psql` after each step.

**No role escalation was needed for what was driven**, and none was performed. `community-member` is
sufficient for the create action and for the `submit-donation-intent` transition. I signed in as, and
acted as, exactly one identity throughout.

**`pending` is where a member's authority ends.** Every transition past it is guarded
`allowedRoleIds: ["owner"]`, and no account can hold `owner` — see the finding below. `pending` is
therefore the furthest clearly-advanced state reachable by any real account on the give path.

## Baseline — confirmed, not stale

The ticket's control was *"`workflow_instances` held **8** rows total, and **zero** of
`workflow_type = 'mosque-donation-payment'`."*

**That was exactly correct** at this session's first database read (03:24 local, before any device
interaction):

```
 total
-------
     8

                            instance_id                            |        community_id         |      workflow_type       |  created_by_fan_id  | current_state
-------------------------------------------------------------------+-----------------------------+--------------------------+---------------------+---------------
 community_chess_club_chess-match-result_8mmrvshrps22              | community_chess_club        | chess-match-result       | fan-chess-member-1  | disputed
 community_camera_club_critique-submission_hqn35lcajo7l            | community_camera_club       | critique-submission      | fan-camera-member-1 | submitted
 community_cedar_commons_hoa_hoa-dues-payment_cd93iaf2sfem         | community_cedar_commons_hoa | hoa-dues-payment         | fan-hoa-board-1     | paid
 community_cedar_commons_hoa_hoa-dues-payment_m5k32qsqumkb         | community_cedar_commons_hoa | hoa-dues-payment         | fan-hoa-board-1     | processing
 community_cedar_commons_hoa_hoa-owner-notification_gbduggeiojjd   | community_cedar_commons_hoa | hoa-owner-notification   | fan-hoa-board-1     | sent
 community_cedar_commons_hoa_hoa-facility-reservation_uc8clw8jfw8z | community_cedar_commons_hoa | hoa-facility-reservation | fan-test-alice      | open
 community_cedar_commons_hoa_hoa-facility-reservation_3pbmhxf5srqh | community_cedar_commons_hoa | hoa-facility-reservation | fan-test-alice      | reserved
 community_cedar_commons_hoa_hoa-facility-reservation_sx2yfw5tsmou | community_cedar_commons_hoa | hoa-facility-reservation | fan-test-alice      | open
```

Zero `mosque-donation-payment` rows. The single row below is therefore necessarily this session's,
and the total moved 8 → 9.

## Identity

Seeded Keycloak account on the documented convention, **authenticated for real** against realm
`loom` at `192.168.56.10:30082` via the in-app OAuth flow (Chrome custom tab) — not selected from a
list. Password `LoomTest123!` was accepted. No credential was created or reset.

| Display name | fan id | Keycloak username | Role (label) | Role id |
| --- | --- | --- | --- | --- |
| Masjid Member 1 | `fan-masjid-member-1` | `loom-masjid-member-1` | Community Member (Member) | `community-member` |

**The stale-SSO trap was actively defeated, not assumed absent.** `pm clear com.android.chrome` and
`pm clear com.example.loom_communities_demo` were run before the flow. The app then reported
`LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required` — a
clean slate — and Keycloak presented a **real, empty login form**, not a silent re-issue. The
resulting `created_by_fan_id` is `fan-masjid-member-1`, matching the identity driven.

**Both typed credential values were read back off the device before submitting**, guarding against
the `adb shell input text` truncation trap: the username field showed `loom-masjid-member-1` in
full, and the password was revealed with the eye toggle and read as `LoomTest123!` in full.

## The path driven, through the real UI

1. Community list → **Masjid Nur**.
2. Identity gate → **Continue to secure sign-in** → Chrome custom tab → Keycloak form → **Sign In**.
3. Identity picker → **Masjid Member 1** (`fan-masjid-member-1`). The community shell opened with
   *"Signed in as Masjid Member 1 / Community Member"*.
4. **Giving** tab → **"Donate"** FAB (the package's `create` action, `byRoleIds: ["community-member"]`,
   `presentation: fab`, `scope: tab`).
5. Filled the four `formEntry` fields and pressed **Create** → `draft`.
6. Scrolled the card → **"Submit donation"** → `pending`.

### Values entered, each read back off the device before submitting

| Field | Schema key | Value |
| --- | --- | --- |
| Amount: $ | `amount` | `75` |
| Fund | `fund` | `Zakat` |
| Privacy | `privacyChoice` | `Private` |
| Giving plan | `recurringPreference` | `One-time` |

`payerFanId` was not typed — it is `writableBy: platform`, prefilled by the create action as
`$actor`, and resolved server-side to `fan-masjid-member-1`.

## The database row — read back with an independent query

```
                      instance_id                      |   community_id   |      workflow_type      |  created_by_fan_id  | current_state |  created_at   |  updated_at
-------------------------------------------------------+------------------+-------------------------+---------------------+---------------+---------------+---------------
 community_mosque_mosque-donation-payment_xwr38n4tfb7z | community_mosque | mosque-donation-payment | fan-masjid-member-1 | pending       | 1788864022573 | 1788864125791
```

`instance_data` after the transition:

```json
{
    "payerFanId": "fan-masjid-member-1",
    "paymentStatus": "pending",
    "paymentHistory": [
        {
            "status": "intent-submitted",
            "by": "fan-masjid-member-1",
            "at": "2026-09-08T10:42:05.791229Z"
        }
    ],
    "amount": 75,
    "fund": "Zakat",
    "privacyChoice": "Private",
    "recurringPreference": "One-time",
    "requestedAt": "2026-09-08T10:42:05.791229Z"
}
```

All three declared effects of `submit-donation-intent` fired: `requestedAt` set to `$timestamp`,
`paymentStatus` set to `pending`, and `paymentHistory` appended with `$actor` and `$timestamp`.

## Do the two halves agree?

**Yes, on every field that both sides express.**

| Claim | UI showed | Postgres held | Agree |
| --- | --- | --- | --- |
| State | chip *"Pending recording"* (warning tone) | `current_state = pending` | yes |
| Status field | `Status: Pending` | `paymentStatus = "pending"` | yes |
| Amount | `Amount: $ 75` | `amount = 75` | yes |
| Fund | `Fund: Zakat` | `fund = "Zakat"` | yes |
| Privacy | `Privacy: Private` | `privacyChoice = "Private"` | yes |
| Giving plan | `One-time` | `recurringPreference = "One-time"` | yes |
| Actor | history entry *"By: fan-masjid-member-1"* | `created_by_fan_id = fan-masjid-member-1` | yes |
| Timestamp | *"At: 2026-09-08T10:42:05.791229Z"* | `paymentHistory[0].at`, `requestedAt` | yes |

The state label *"Pending recording"* is the package's own `states.pending.label`, and the card
switched from `cardSurfaceFamily: paymentCheckout` in `draft` to the same family in `pending` with
the action set correctly reduced — **"Submit donation" disappeared** once consumed, leaving only
`save-donation-changes` and `cancel-donation`, which are exactly the transitions whose `from`
includes `pending` and whose guard the actor satisfies.

## FINDING — the package's `owner` role does not exist in App Access, so this donation can never be receipted

The ticket warned that `owner` had **no seeded holder**. The live data is stronger than that: for
Masjid Nur, **`owner` was never provisioned as a role at all.**

```
=== declared roles for loom_communities_masjid-nur
     role_id      |          group_id           |   display_name
------------------+-----------------------------+------------------
 community-member | loom_communities_masjid-nur | Community Member
 masjid-nur-admin | loom_communities_masjid-nur | Masjid Admin

=== who holds them
          group_id           |       fan_id        | state  |     role_id
-----------------------------+---------------------+--------+------------------
 loom_communities_masjid-nur | fan-masjid-admin    | active | masjid-nur-admin
 loom_communities_masjid-nur | fan-masjid-member-1 | active | community-member
```

**Control run, because a search that finds nothing is not evidence of absence.** The same query
shape against every other community returns owner-flavoured roles, so the query works and the
absence is real:

```
 loom_communities_ad-free-community          | ad-free-community-admin, ad-off-member, ad-off-owner
 loom_communities_chess-club                 | chess-club-admin, chess-member, chess-organizer, chess-owner
 loom_communities_data-portability-community | data-portability-community-admin, portability-member, portability-owner, portability-receiving-provider
 loom_communities_riverside-youth-soccer     | riverside-youth-soccer-admin, soccer-coach, soccer-guardian, soccer-owner
 loom_communities_masjid-nur                 | community-member, masjid-nur-admin        <- no owner
```

Note the shape of the gap: the package's **other** declared role, `community-member`, *was*
provisioned verbatim. Only `owner` is missing. Peer communities provision their package's owner role
under a community-prefixed id (`chess-owner`, `soccer-owner`), so Masjid Nur is the outlier.

`masjid-nur-admin` is **generated community governance**, not the package's domain `owner` role —
they are different things, and it was not substituted.

### What that costs, concretely

Four of the twelve transitions in `mosque-donation-payment` are guarded `allowedRoleIds: ["owner"]`
and are therefore **unreachable by any account that exists**:

| Transition | from → to | Consequence of being unreachable |
| --- | --- | --- |
| `confirm-offline-donation` | `pending` → `paid` | **A donation can never be recorded as paid.** |
| `record-payment-failure` | `pending` → `failed` | A failed payment can never be recorded, so `retry-donation` is unreachable too. |
| `record-donation-refund` | `refundRequested` → `refunded` | — |
| `decline-donation-refund` | `refundRequested` → `paid` | — |

Because `paid` is unreachable, everything downstream of it is dead: `open-donation-receipt`,
`manage-recurring-preference`, `request-donation-refund`, and the terminal `refunded`. So are the
`paid`-only render bindings — the `home` tab summary card bound to `states: ["paid"]` can never
render, and the `admin` tab's `approvalQueueItem` binding has no role able to act on it.

The `confirm-offline-donation` effect also carries `createInstance` of **`mosque-donor-visibility`**,
so that workflow's only declared writer can never fire either.

**The only terminal state a real account can reach is `cancelled`.** The give path can be started and
submitted, and then never completed — the row banked above is, permanently, as far as this workflow
goes for Masjid Nur until `owner` is provisioned.

This is a provisioning gap, not a package defect: the package declares `owner` correctly in
`experience.roles`, and the guards are coherent. Nothing in the app or the engine is wrong.

## Environmental note — Chrome ANR from emulator memory pressure, not a Keycloak fault

The first OAuth attempt stalled: Chrome repeatedly raised *"Chrome isn't responding"*, and tapping
**Wait** did not clear it. The cause was on the **device**, not the backend — `/proc/meminfo` showed
**333 MB free of 4 GB** with 668 MB of swap in use, and logcat showed Chrome's sandboxed renderers
being spawned and killed in a loop (`isolated not needed`, `has died: vis BTOP`).

The VM was **not** the constraint: load average was `4.02` on 8 cores with 4.3 GB available, and all
six `loom` pods were `1/1 Running`.

Force-stopping unused Google apps on the device (Photos, Messages, Wellbeing, Safety Hub, TTS,
Quick Search, Android System Intelligence, Settings) took `MemAvailable` from ~330 MB to **2.1 GB**.
Chrome was then restarted and the Keycloak form rendered and stayed responsive for the rest of the
session.

**Recorded because it is reusable, and because it mimics a backend failure.** A Keycloak page that
renders and then wedges reads as a server problem; the tell that it was not is that unrelated Chrome
renderer processes were dying at the same time. Check `MemAvailable` on the device before blaming
the OAuth path.

## Two UI notes, neither a defect

- **The create dialog scrolls under the keyboard.** With the IME up, the Donate dialog collapses to
  its title and buttons, so later fields cannot be seen while typing. The keyboard's
  **hide-keyboard chevron** restores the full dialog; the **system Back key dismisses the whole
  dialog and discards the form**, which cost one re-entry here. Worth knowing for any future
  walkthrough of a four-field create form.
- **`keyevent 61` (TAB) advanced focus exactly once** (Amount → Fund) and then stopped landing text.
  Tapping each field directly is the reliable method. This is a harness observation, not a product
  finding — every field accepted input correctly when tapped.

## Not done, and why

- **No `paid`, `failed`, `refunded` or receipt evidence.** Unreachable — see the finding. Reaching
  them would have required substituting `masjid-nur-admin` for `owner`, which the ticket explicitly
  forbids and which would have been false evidence: `masjid-nur-admin` is not the package's `owner`.
- **No credential was created or reset**, and no application code, community JSON or tracker was
  modified.
- `integration_test/on_device_remote_backend_proof_test.dart` was **not** used; it bypasses the UI.

## Verdict

**Row 1 of the B25 addendum for Masjid Nur is proven for the give path up to `pending`**, by live
walkthrough and an independent database read that agree on every field. The give path **cannot be
proven to completion** in the current environment, and the reason is a named, verified provisioning
gap rather than an unexplained failure.
