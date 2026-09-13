**Workflow:** `platform-blocked-target` in Member Social Space
**Outcome:** Both halves of the proof standard were met — signed in as `fan-social-member-1`, created a `platform-connection`, fired `send-invite` then `block` (which spawned the `platform-blocked-target` instance), then fired `confirm-block` and `close-review` to reach the declared terminal state `closed`, confirmed independently in Postgres.

**Package identity:** `Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc`
- `skillVersion`: `3.3.0`
- `sha256`: `3b2081ccf7fd223e5254276f4d70f08411df3a49659b0c00ad417a277d1ea3d5`

**Date:** 2026-09-12 (device clock 2026-09-13 UTC)
**Device:** `emulator-5554` (Windows-hosted, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

---

## Identity

| Item | Value |
|---|---|
| Keycloak username | `loom-social-member-1` |
| Fan id | `fan-social-member-1` |
| Role | `member` |
| Escalation | **None.** One identity drove the entire run. |

The previous run had left the app signed in as `fan-ad-off-owner-1`, so this was an identity
switch. Both Chrome and the Loom app were cleared (`pm clear com.android.chrome` and
`pm clear com.example.loom_communities_demo`) plus a Keycloak logout call. The **real Keycloak
login form appeared** — no silent SSO re-issue — and the relaunched app showed
*"Loaded 10 example communities"*, confirming the preload flag is compiled into this build.

`created_by_fan_id` on the resulting row is `fan-social-member-1`, matching the identity driven.

## Baseline (measured in this session, not taken from the brief)

    select count(*) from workflow_instances;                      ->  74
    ... where workflow_type='platform-blocked-target'             ->  0 rows

The brief's hint (~74 rows, none of this type) was accurate on this occasion. After the run the
total is **76** (+1 `platform-connection` vehicle, +1 `platform-blocked-target`).

Both workflow types were confirmed **published** before driving (`workflow_definitions`,
version 4 each), ruling out the silent-no-op failure mode where a `createInstance` naming an
unpublished type returns success and does nothing.

## Path driven (real UI, no test harness)

1. Community list -> **Platform Social** -> account list -> **Social Member 1**.
2. Create FAB -> **"Send connection invite"**. Selected invitee **Test social-member-2**
   (`fan-social-member-2`) from the picker; typed reason `B25-reverify-connect`.
   -> `platform-connection` created in `draft`.
3. **"Send invite"** -> `draft` -> `invited`.
4. **"Block"** -> required `reason` input, typed `B25-unwanted-contact` -> `invited` -> `blocked`.
   **This is the step that spawned the row.**
5. Spawned card rendered as **"Block active"** with target Fan Social Member 2.
   **"Confirm block"** -> `confirmedAt` written, state correctly stayed `active` (`to: null`).
6. **"Mark reviewed"** (`close-review`) -> `active` -> **`closed`** (declared terminal).
   Final UI state reads **"Reviewed"** with actions withdrawn.

`moderator-close-review` was **not offered**, which is correct — it is `moderator`-guarded and this
run held only `member`. No identity switch was made for it.

## The DB row

    instance_id       community_member_social_space_platform-blocked-target_28q832se34nq
    community_id      community_member_social_space
    workflow_type     platform-blocked-target
    created_by_fan_id fan-social-member-1
    current_state     closed
    created_at        1789263122333   (2026-09-13 01:32:02 UTC)

Full `instance_data`:

    {
      "connectionId": "community_member_social_space_platform-connection_9vb0d8awdrms",
      "blockerFanId": "fan-social-member-1",
      "targetFanId":  "fan-social-member-2",
      "blockReason":  "B25-unwanted-contact",
      "confirmedAt":  "2026-09-13T01:33:01.364887Z",
      "reviewedAt":   "2026-09-13T01:33:40.603667Z"
    }

Exactly **one** `platform-blocked-target` row exists in the table, so attribution is unambiguous.

## Do the two halves agree?

**Yes.** The device showed `Block active` -> (confirm, no state change) -> `Reviewed`; Postgres shows
`active` -> `confirmedAt` written with state still `active` -> `closed` with `reviewedAt`. The final
UI label "Reviewed" is the declared label of the `closed` state. `created_by_fan_id` matches the
authenticated identity.

## Interpolated values (requested verbatim)

| Field | Stored value | Verdict |
|---|---|---|
| `connectionId` (`"{id}"`) | `community_member_social_space_platform-connection_9vb0d8awdrms` | **Equals my connection instance's id exactly.** `{id}` in an effect's `fields` resolved correctly. |
| `targetFanId` (`"{inviteeFanId}"`) | `fan-social-member-2` | Correct — a **real fan id**, not a role id. |

The `block` effect's `$actor == inviterFanId` branch was taken correctly: I was the inviter, so
`targetFanId` was populated from `inviteeFanId`.

**No truncation.** `blockReason` stored the full `B25-unwanted-contact`, and the connection's
`reason` stored the full `B25-reverify-connect`; both were settled against Postgres rather than the
screen.

**The known audience-picker defect did not manifest on this path.** The invitee picker offered real
fan ids (`fan-social-admin`, `fan-social-member-1/2`, `fan-social-moderator-1/2`) with role labels,
and the stored `inviteeFanId`/`targetFanId` are genuine fan ids. Nothing needs reporting there.

## Observation — inconsistent invitee chip across scroll positions (NOT re-reproduced)

Immediately after firing `send-invite`, one screenshot showed the two simultaneously-visible
"Invite sent" cards **both** captioned `Invitee: Fan Social Moderator 1`; after scrolling up, the two
cards were **both** captioned `Invitee: Fan Social Member 2`. The database holds two `invited`
connections with *different* invitees (`fan-social-member-2` and `fan-social-moderator-1`), so at
least one of those renders disagreed with stored state. The per-card *reason* chips stayed correct
and distinct throughout.

Stated with deliberate caution: **I did not re-reproduce this on purpose and am not asserting a
mechanism** (card recycling during list refresh is a guess, not a finding). It did not affect this
proof — the target instance was disambiguated by its unique reason chip, the action was confirmed
against Postgres, and the two neighbouring connections were verified **unchanged** afterwards
(`dk85uakyedz4` still `invited`, `s7w9bdft4lhb` still `connected`). Recording it because a card
showing another instance's participant is worth its own investigation.

## Not done / limitations

- No UX judge run accompanies this walkthrough; this manifest covers the live-write half only.
  Screenshots are transient (`*.png` is gitignored) and were not committed.
- `moderator-close-review` was deliberately not exercised (would have required a moderator identity,
  which the ticket forbids escalating to).
- No application code, community JSON, tracker, or credential was created or modified.
