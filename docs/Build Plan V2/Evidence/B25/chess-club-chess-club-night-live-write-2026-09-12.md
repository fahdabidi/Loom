**Workflow:** `chess-club-night` in Chess Club
**Outcome:** Both halves of the proof standard were met — signed in as `loom-chess-organizer-1` through the real Keycloak form, created a club night through the Calendar tab's "Schedule club night" FAB, and drove it organizer-guarded through `scheduled` → `reminded` → the terminal `cancelled`, confirming every step in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Package identity:** `Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc`
- `skillVersion`: `3.3.0`
- `sha256`: `92547b0c0be7292771748ab9c11083ffc5b759d494c5da522290e921b392a609`
- Verified byte-identical to the copy **bundled in the installed APK**: extracted from the device's
  own `base.apk` at
  `assets/flutter_assets/packages/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc`
  and hashed to the same sha256. So this hash describes the package actually driven, not merely the
  one in the working tree.
- The working-tree copy was `git status`-clean throughout; no community JSON was touched.

---

## Why this run exists

The prior claim of a live write for this row was reopened as untrusted because no matching row
existed in the database. That was **correct**: at the start of this run `workflow_instances` held
**30 rows and zero of `workflow_type = 'chess-club-night'`**. This run does not look for that
instance — it creates a new one.

The brief's baseline hint ("about 30 rows, few or none of `chess-club-night`") was **accurate this
time**, measured independently before touching anything. Recorded because the same hint has been
stale twice before, on 2026-09-09.

## Identity

- **Authenticated as:** Keycloak `loom-chess-organizer-1`
- **Fan id:** `fan-chess-organizer-1`
- **Role:** `chess-organizer`

Verified independently before driving the UI: a password-grant token request against
`loom-test-client` returned HTTP 200, and the decoded access token carried
`preferred_username: loom-chess-organizer-1` and `fanId: fan-chess-organizer-1`
(`sub: e40f464b-3a0f-40f3-bae3-2942d7418e46`).

**No escalation was needed.** `chess-club-night`'s create action is declared
`byRoleIds: ["chess-organizer"]`, and both transitions driven below are guarded
`allowedRoleIds: ["chess-organizer"]`. The account named in the brief was exactly the right one.

### All three seeding layers confirmed before driving anything

A seeded fan is only real when authentication, identity and authorization all exist; missing any one
still looks correct from the other two.

| Layer | Where | Found |
|---|---|---|
| Authentication | Keycloak account carrying the `fanId` attribute | `loom-chess-organizer-1` → `fan-chess-organizer-1` |
| Identity | `fan_passport` row | `fan-chess-organizer-1` / "Chess Organizer 1" |
| Authorization | `group_membership_role` | `fan-chess-organizer-1` holds `chess-organizer` in `loom_communities_chess-club` |

### The workflow type was confirmed published before driving it

A `createInstance` naming an unpublished type returns success and does nothing, so this was checked
first rather than inferred from the create succeeding:

    definition_id                          | workflow_type    | version
    community_chess_club_chess-club-night  | chess-club-night |       4

## The stale-identity trap was pre-empted, not merely survived

The app opened holding a **Camera Club** session from the previous dispatch. Rather than trusting a
sign-in screen to reveal that, both stores were cleared up front, per the rule that clearing one is
not enough in either direction:

    adb shell pm clear com.android.chrome
    adb shell pm clear com.example.loom_communities_demo

Both were required and both behaved as documented. Clearing app data dropped the installed
communities, and the relaunch's **"Loaded 10 example communities"** banner confirmed the
`LOOM_PRELOAD_EXAMPLE_COMMUNITIES` flag is compiled into the build being driven. Opening Chess Club
then produced the account-list error branch carrying **"Continue to secure sign-in"** — the only
route to a fresh login — and Keycloak served a **real, empty username/password form**, proving no
SSO cookie survived to silently re-authenticate the previous fan.

Chrome's first-run onboarding intercepted the OAuth redirect exactly as the brief warned; dismissed
with "Use without an account".

After sign-in the app rendered **"Signed in as Chess Organizer 1 / Organizer"**, and the resulting
row's `created_by_fan_id` is `fan-chess-organizer-1` — so the identity was confirmed at both ends,
not just on the success screen.

## The path driven

All steps were performed on the Windows-hosted `emulator-5554`, reached from the VM via
`adb -H 192.168.56.1 -P 5037`.

1. Launch → "Loaded 10 example communities" → **Chess Club**
2. Entry gate → "Continue to secure sign-in" → Chrome onboarding dismissed
3. Real Keycloak form → `loom-chess-organizer-1` / `LoomTest123!` → redirect back to app
4. Account list loaded → selected **Chess Organizer 1** (`fan-chess-organizer-1`)
5. **Calendar** tab → **"Schedule club night"** FAB (the `byRoleIds: ["chess-organizer"]` create action)
6. Filled the six required `formEntry` fields → **Create** → instance created in `scheduled`
7. **Send reminder** → `scheduled` → `reminded`
8. **Cancel club night** → `reminded` → **`cancelled` (terminal)**

The date and time were set through the **native pickers**, not typed, so neither was exposed to the
`adb shell input text` truncation trap.

## The database row

    instance_id       | community_chess_club_chess-club-night_76xn91zd78n6
    community_id      | community_chess_club
    workflow_type     | chess-club-night
    created_by_fan_id | fan-chess-organizer-1
    current_state     | cancelled
    created_at        | 1789224593810   (2026-09-12T14:49:53.810Z)

**The two halves agree.** The device showed "Club night cancelled" with no remaining actions; the
row reads `current_state = cancelled`. `created_by_fan_id` is `fan-chess-organizer-1`, matching the
identity authenticated and driven.

**This row is identified by its instance id and timestamp, not by a change in row count.** The
shell timestamp captured immediately before tapping Create was `2026-09-12T14:49:53Z`, and the
stored `created_at` is `2026-09-12T14:49:53.810Z` — the same second. (The count did also move,
30 → 31, but that is corroboration, not the identification.)

### Every stored field was checked against the database, not the screen

A field that scrolls horizontally can show a plausible prefix while the stored value is truncated,
so all six form-entry values were read back out of `instance_data`:

    eventTitle    : "B25 Club Night"
    eventKind     : "Club night"
    eventDate     : "2026-09-19"
    eventTime     : "19:00"
    location      : "Community Hall"
    pairingNote   : "Open pairings all levels"

All six are complete; **no truncation occurred**. The create action's `prefill` also landed
correctly (`reminderStatus: "scheduled"`, and `reminderHistory`/`attendingFanIds`/`reminderFanIds`
as empty lists).

### The transition effects wrote real fan ids

Final `reminderHistory` after both transitions:

    { "action": "reminder-sent", "recipientFanId": null,
      "sentByFanId": "fan-chess-organizer-1", "at": "2026-09-12T14:51:36.905323Z" }
    { "action": "cancelled",
      "actorFanId":  "fan-chess-organizer-1", "at": "2026-09-12T14:52:14.526351Z" }

`$actor` resolved to the genuinely authenticated fan id in both cases — **not** a role-id-shaped
string. `reminderStatus` ended at `"cancelled"`.

## Guard behaviour observed (all correct)

- As `chess-organizer`, only the two organizer-guarded transitions rendered. The three
  `chess-member`-guarded ones (`rsvp-club-night`, `withdraw-club-night-rsvp`, `add-event-reminder`)
  correctly did **not** appear.
- After `send-reminder`, the "Send reminder" button disappeared — correct, since that transition is
  `from: ["scheduled"]` only.
- In the terminal `cancelled` state, **no** action buttons remained.

## One observation worth recording (not a defect)

The optional `recipientFanId` field (`type: "fanId?"`) rendered a **"Reminder recipient" picker
listing real fan identities** — `fan-chess-admin`, `fan-chess-member-1`, `fan-chess-member-2`,
`fan-chess-organizer-2`, `fan-chess-owner-1`, `fan-chess-owner-2` — each with a display name, an
`Active` status and its role id. These are backend fan ids, not role ids.

That is worth noting because the documented `AudienceMultiSelectPicker` defect writes **role** ids
into `fanId[]` fields. **This run does not settle whether the two paths differ**: the field here is
singular `fanId?` rather than `fanId[]`, and **the recipient was deliberately left unselected**, so
nothing was stored through it and no claim is made about what it would have written. What was
observed is only what the picker *displayed*. `recipientFanId` is `null` in the stored row, and the
`reminder-sent` history entry records `recipientFanId: null` consistently.

## Defects observed

**None.** No ANR or crash dialog (`dumpsys window` reported `<no ANR has occurred since boot>`; no
`FATAL EXCEPTION` in logcat), no permission refusal, no missing affordance, and no `403` /
`unknown_permission_id`.

## What this run does not cover

- The member-side interactions (`rsvp-club-night`, `withdraw-club-night-rsvp`,
  `add-event-reminder`) were not exercised. They are `chess-member`-guarded and correctly invisible
  to this organizer; proving them needs a run signed in as a `chess-member`.
- No UX judge pass was run — this manifest is the live-walkthrough half only.
- Screenshots were captured at every step but `*.png` is gitignored, so they are transient by
  policy; this manifest is the durable record.
