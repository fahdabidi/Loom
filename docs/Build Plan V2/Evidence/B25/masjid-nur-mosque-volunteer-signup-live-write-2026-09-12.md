**Workflow:** `mosque-volunteer-signup` in Masjid Nur
**Outcome:** Both halves of the proof standard were met — signed in as `loom-masjid-owner-1`, created a volunteer shift from the Admin tab FAB, fired `record-coordinator-follow-up` (a `to: null` transition proven by an `instance_data` mutation) and then `close-volunteer-shift` to the declared terminal state `closed`, with the row confirmed in Postgres.

**Package identity:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`
- `"skillVersion": "3.6.0"`
- `sha256 7a7b48223d14f7ae50237af3a7c290f646eb84ca2c1efa4c0f54ec9d6b6fe1ff`

## Identity

- Keycloak account: `loom-masjid-owner-1`
- Fan id: `fan-masjid-owner-1`
- Role: `owner`
- No sign-in was performed this session. The app already held an authenticated `fan-masjid-owner-1`
  session from the two earlier Masjid runs today, so per the ticket neither Chrome nor the app was
  cleared. The identity was confirmed two ways before driving anything: the `Admin` tab
  (`visibleRoleIds: ["owner"]`) was rendered in the bottom nav, and the pre-existing announcement
  card on that tab reads `By: fan-masjid-owner-1`. It is confirmed a third time by
  `created_by_fan_id` on the row below.

## Baseline, measured in this session

Measured before touching the device, not taken from the brief:

- `workflow_instances` held **50** rows (the brief's hint of "about 50" was accurate this time).
- `select ... where workflow_type='mosque-volunteer-signup'` returned **0 rows**. A real negative
  result: this row had never been driven.
- Masjid's own rows were 3, all `community_mosque`: `mosque-event-rsvp` (cancelled),
  `mosque-announcement` (archived), `mosque-donation-payment` (pending).

After the run the total is **52** (this row plus `mosque-search-ai-citation`, filed separately).
The row below is distinguished by its instance id and `created_at`, not by the count moving.

## Path driven

1. **Create** — `Admin` tab → FAB → **"New volunteer shift"**. All seven `formEntry` fields are
   `required: true` and were filled: `title=B25Shift`, `shiftRole=Greeter`,
   `shiftDate=2026-09-26` (date picker), `shiftTime=12:00` (time picker), `location=MainHall`,
   `capacity=8`, `contactSharingPolicy=MembersOnly`. Landed in `open`.
2. **`record-coordinator-follow-up`** — owner-guarded, `to: null`. Inputs
   `memberFanId=fan-masjid-member-1`, `followUpNote=CalledB25`.
3. **`close-volunteer-shift`** — owner-guarded, `open → closed`. **`closed` is the declared terminal
   state** (`"isTerminal": true`).

The three member-only transitions (`sign-up-volunteer`, `update-volunteer-availability`,
`cancel-volunteer-signup`, all `allowedRoleIds: ["community-member"]`) were **not offered** to the
owner. That is correct, not a missing affordance, and no identity switch was attempted.

## Final UI state

The card re-renders under the `closed` binding
(`states: ["closed"], tabId: admin, cardSurfaceFamily: statusTimeline, bindingKind: summary`) as a
status-timeline summary headed **"Signup closed"**, carrying `B25 Shift`, `Role: Greeter`,
`2026-09-26`, `12:00`, `Main Hall`, `Capacity: 8`, `Volunteers: 0`, and a **Coordinator follow-ups**
section reading `Member: fan-masjid-member-1 / Note: CalledB25 / By: fan-masjid-owner-1 /
At: 2026-09-12T19:38:14.656911Z`. No action buttons remain, which is correct for a terminal state.

## Database row (independent confirmation, same session)

    instance_id       community_mosque_mosque-volunteer-signup_8cfgwuip63lo
    community_id      community_mosque
    workflow_type     mosque-volunteer-signup
    created_by_fan_id fan-masjid-owner-1
    current_state     closed
    created_at        1789241802634  (2026-09-12T19:36:42.634Z)

`coordinatorFollowUpHistory` in `instance_data`:

    [{ "at": "2026-09-12T19:38:14.656911Z",
       "by": "fan-masjid-owner-1",
       "note": "CalledB25",
       "member": "fan-masjid-member-1" }]

**Do the two halves agree? Yes, on every field checked.** `created_by_fan_id` is
`fan-masjid-owner-1`, the identity driven. `current_state` is `closed`, the state the card shows.
The follow-up entry the card renders is the entry stored on the row, to the microsecond.

**`record-coordinator-follow-up` is proven by the data, not the state.** It declares `to: null`, so
`current_state` stayed `open` when it fired — confirmed in Postgres at that moment — and its only
evidence is the `coordinatorFollowUpHistory` append above. State advanced to `closed` only on the
subsequent `close-volunteer-shift`.

## Truncation check

`adb shell input text` truncates silently, so every stored value was settled against the database
rather than the screen. **Nothing was truncated.** `instance_data` holds exactly
`title=B25Shift`, `shiftRole=Greeter`, `shiftDate=2026-09-26`, `shiftTime=12:00`,
`location=MainHall`, `capacity=8`, `contactSharingPolicy=MembersOnly`, and the 19-character
`fan-masjid-member-1` in full.

## Observations

- **Display-only word-splitting on chip labels, not a data defect.** The summary card renders
  `B25 Shift` and `Main Hall` where the stored values are `B25Shift` and `MainHall`. The renderer
  inserts spaces at camelCase boundaries for display; `instance_data` is unspaced and correct. Worth
  recording only because an on-screen read would have suggested the opposite of the truncation trap —
  the screen showed *more* than was stored, not less.
- The package's seed instance `masjid-volunteer-iftar-setup` is absent from Postgres, as expected
  under the deliberate 2026-09-07 decision that remote communities start empty.
- The `Resources` tab is a fifth nav destination reachable only by scrolling the bottom nav bar
  horizontally; four fit on screen at 1080x2400. Not a defect, but it is not discoverable without
  the swipe.

## Environment

- Emulator `emulator-5554` on the Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`.
- All six `loom` pods `1/1 Running`; load average 2.56 at the start of the run.
- No ANR (`<no ANR has occurred since boot>`) and no `FATAL EXCEPTION` in logcat during the run.
- No application code, community JSON, or tracker was modified. No credential was created or reset.
