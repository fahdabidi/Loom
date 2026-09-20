# B25 live walkthrough — Neighborhood Book Club, `book-meeting-rsvp`

**Workflow:** `book-meeting-rsvp` in Neighborhood Book Club
**Outcome:** Both halves of the proof standard were met — signed in through the real Keycloak form as `loom-book-organizer-1`, created a meeting through the Calendar "New meeting" FAB, fired `publish-meeting` and then `cancel-meeting` into the terminal state `cancelled`, confirming the instance id, every stored field, `created_by_fan_id` and both state changes directly in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Community:** Neighborhood Book Club (`community_neighborhood_book_club`)
**Date:** 2026-09-19 local / 2026-09-20 UTC
**Device:** `emulator-5554` (Windows-hosted AVD reached over the ssh reverse tunnel to `:5037`)
**Backend:** workflow-service `http://192.168.56.10:30083`, Keycloak `:30082`, app-access `:30080`,
fan-passport `:30081`; all six pods `1/1 Running` throughout.

## Package identity

`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_BookClub_Example.jsonc`

- `specVersion`: `4`
- `skillVersion`: `3.6.0`
- `sha256`: `71e1f0688b7dffd1b29cb90a1066998f003abdf920523cac8dcb535837726957`
- Last touched by `38f41976` (2026-09-05)
- **Verified byte-identical to the copy bundled in the installed APK**: pulled `base.apk`
  (232,240,791 bytes) off the device, extracted
  `assets/flutter_assets/packages/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_BookClub_Example.jsonc`,
  and its sha256 is the same `71e1f068…`. The app under test rendered *this* package, not a stale one.

## Layer checks, before believing anything downstream

| Layer | State | How checked |
|---|---|---|
| Package | declares `book-meeting-rsvp`, 3 organizer-guarded transitions | read the package |
| Published definition | `book-meeting-rsvp` **version 4**, `book-meeting-rsvp-response` version 4 | `workflow_definitions` query |
| Deployed guard vs package | identical | deployed `definition_json` substring for `publish-meeting` returned `"guard":{"allowedRoleIds":["book-organizer"],"formula":"publishedAt == null"}` — matching the package exactly |

The deployed-guard query carried its own control: it returned a non-empty match, so a later
empty result would have meant absence rather than a broken query.

## Control read, taken before any write

    select workflow_type, count(*) from workflow_instances group by workflow_type;
    -- 58 types present; `book-meeting-rsvp` ABSENT from the grouping

    select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at
      from workflow_instances where workflow_type='book-meeting-rsvp' order by created_at desc limit 5;
    -- (0 rows)

**Baseline measured, not assumed: zero `book-meeting-rsvp` rows.** This matched the brief's hint,
but was re-derived here rather than trusted. The row below is distinguished by its own instance id
and `created_at`, not by any change in a count.

## Identity — authenticated, and proven by a deliberate refusal

Both halves cleared first (`pm clear com.android.chrome` **and**
`pm clear com.example.loom_communities_demo`). The app then showed
`LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required.`, which
is the positive confirmation that no stale session survived. Launch reported
**"Loaded 10 example communities"**, so the preload flag is compiled into this build.

The **real Keycloak form rendered** (username + password fields at `192.168.56.10:30082`) — it was
not a silent SSO re-issue, which is the failure mode that banks evidence under the wrong fan.

**Anti-impersonation guard used as a control.** Tapping the *wrong* account on purpose produced, on
screen:

    Sign-in failed: LoomAuthException(accountNotFound): The authenticated Loom identity cannot
    sign in as account "fan-book-member-1". Sign in with that person's identity provider session instead.

That is positive proof of whose token was held, independent of what any success screen claimed.
Selecting the correct account then signed in as **Book Organizer 1 / Organizer**.

- Keycloak account: `loom-book-organizer-1`
- Fan id: `fan-book-organizer-1`
- Role: `book-organizer`

`loom-book-member-1` was **not** used and **not** reset — its credential is known-broken and the
brief's guidance to use another holder of the role was followed.

## What was driven, through the real UI

1. **Calendar tab** → the **"New meeting"** FAB rendered, confirming the create action's
   `byRoleIds: ["book-organizer"]` resolves for this identity.
2. **Created the meeting.** Every required field was verified on screen before submitting, and each
   typed value was re-verified against the stored row afterwards rather than against the screen:
   `title`, `eventDate` (native date picker), `eventTime` (native time picker), `location`, `capacity`.
3. **Fired `publish-meeting`** — guard `allowedRoleIds:["book-organizer"]` + formula
   `publishedAt == null`, effect `set publishedAt=$timestamp`, `to: null`.
4. **Fired `cancel-meeting`** — into the terminal state `cancelled`.

App telemetry for the create, from the app's own binding log (`mode=remote`, so this is the service
and not a local database):

    LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/ \
      scope=ext_neighborhood_book_club outcome=ok status=201 error=- at=2026-09-20T05:27:42.652046Z

## The transition was proven to reach the engine, not merely tapped

A tap that returns is not a transition that happened, so `publish-meeting` was settled two ways:

- **Postcondition in Postgres**, polled on the *target condition* rather than on the row existing:
  `publishedAt=2026-09-20T05:29:43.526211Z`.
- **The guard re-evaluated on the device.** After the tap, the **"Publish meeting" button
  disappeared** from the card while "Cancel meeting" and "Make recurring" remained — exactly what
  `formula: "publishedAt == null"` implies once the field is set. A before/after change in the
  rendered affordance set is independent evidence the write landed.

## Independent database confirmation (same session)

    select instance_id, community_id, workflow_type, created_by_fan_id, current_state,
           created_at, instance_data
      from workflow_instances where workflow_type='book-meeting-rsvp';

    instance_id       | community_neighborhood_book_club_book-meeting-rsvp_s0jqhu4bnl9n
    community_id      | community_neighborhood_book_club
    workflow_type     | book-meeting-rsvp
    created_by_fan_id | fan-book-organizer-1
    current_state     | cancelled
    created_at        | 1789882062537   (2026-09-20 05:27:42 UTC)
    instance_data     | {"title":"B25 Reverify Sep19","eventDate":"2026-09-26","eventTime":"19:00",
                         "location":"Community Library","capacity":12,
                         "publishedAt":"2026-09-20T05:29:43.526211Z"}

**Do the two halves agree? Yes, on every point that was checked.**

| Claim | Device | Database |
|---|---|---|
| Actor | signed in as Book Organizer 1 | `created_by_fan_id = fan-book-organizer-1` |
| `title` | `B25 Reverify Sep19` | `B25 Reverify Sep19` (untruncated) |
| `eventDate` | `2026-09-26` | `2026-09-26` |
| `eventTime` | `19:00` | `19:00` |
| `location` | `Community Library` | `Community Library` (untruncated) |
| `capacity` | `12` | `12` (stored as a number, not a string) |
| publish | Publish button disappeared | `publishedAt` set |
| cancel | all actions gone, `Published …` chip remains | `current_state = cancelled` |

`created_by_fan_id` is the fan whose Keycloak session was used, so this row is attributed to the
identity actually driven. No value was accepted from the screen alone — `adb shell input text`
truncates silently, and the two free-text fields were confirmed against `instance_data`.

## Why this row is single-sided, stated explicitly

The brief asks for a two-party proof "if the workflow has two sides". **This workflow does not.**
All three of its transitions — `publish-meeting`, `cancel-meeting`, `make-recurring` — are
`allowedRoleIds: ["book-organizer"]`. The member half of the interaction is a *different workflow
type*, `book-meeting-rsvp-response`, which is its own B25 row. So a second identity was not used,
and that is a property of the declaration rather than a gap in this run.

## Observations

**1. A `book-meeting-rsvp-response` row appeared, and I am not claiming why.**
Baseline had none. After the run:

    instance_id       | community_neighborhood_book_club_book-meeting-rsvp-response_sypey4wff0z5
    created_by_fan_id | fan-book-organizer-1
    current_state     | cancelled
    created_utc       | 2026-09-20 05:29:43   (the same second as `publishedAt`)
    instance_data     | {"eventId":"community_neighborhood_book_club_book-meeting-rsvp_s0jqhu4bnl9n",
                         "fanId":"fan-book-organizer-1"}

It is correctly keyed to this event and this fan, and it ended `cancelled`. `cancel-meeting`
declares five `transitionRelated` sweeps filtered on `eventId: "{id}"`, and CLAUDE.md records that
`{id}` in a `transitionRelated` filter resolves as an ordinary data-field lookup and therefore
silently matches nothing. **This observation is consistent with that sweep having worked, which
would contradict the recorded limitation — but I did not establish the mechanism and am not
asserting one.** `workflow_service` has no transition-history table (10 tables, none an audit log),
so the database cannot distinguish the engine's sweep from a client-side follow-up call. Recorded
here as a lead worth a proper check, not as a finding.

**2. The reminder chip renders with no number.** The card shows `Reminder  hours before` — a literal
double space where the value belongs — because `reminderOffsetHours` was left unset. The definition
declares `leadHours: 24` as the default and `leadHoursField: reminderOffsetHours` as the override,
so a default of 24 exists and is simply not rendered. Cosmetic, on both the chip and the edit field.

**3. The terminal `cancelled` state is not visually labelled on the calendar surface.** After
cancellation the card still reads `B25 Reverify Sep19 / 0 / 12 going / 12 seats left / 19:00 /
Community Library`, and the agenda entry is unchanged; the only visible difference is that the
action buttons are gone. The package declares the state as `label: "Cancelled", tone: "negative"`,
and the `cancelled` binding is `bindingKind: "summary"`. So a member opening this meeting after it
was cancelled sees no cancellation notice — the information is present in the model and not on the
surface. Reported as observed; no code or package change was made.

**4. The reminder block is unconditional, and it did NOT break listing here.** `book-meeting-rsvp`
declares `reminder` with no gating field — the shape CLAUDE.md records as leaking a raw `DateTime`
into `instanceData` and 500-ing Cedar's listing. Every listing call after creation returned
`status=200`, and no `JsonUnsupportedObjectError` appeared in logcat. Noted because the structural
precondition is present and the failure is not, so the two are not equivalent.

**5. The calendar's response-row circular dependency did not reproduce.** The card rendered
"No response record is available for you for this event." *alongside* the parent's own actions
(Publish / Cancel / Make recurring), rather than suppressing them. That is the opposite of the
2026-09-12 defect in which a failed secondary load discarded a successful primary one.

## Infrastructure note — the brief's `adb` instruction is wrong on this VM

The brief says to `export ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`. **That hangs**: the Windows adb
server binds `127.0.0.1` only, so the host's `:5037` is not reachable across the host-only network,
and the first `adb devices` blocked until it was killed. What works is the ssh reverse tunnel, which
was already up — `sshd` (pid 13841) held VM `127.0.0.1:5037`, confirmed with `ss -ltnp`. With **no**
`ADB_SERVER_SOCKET` set, plain `adb devices` listed `emulator-5554 device` immediately. This matches
CLAUDE.md's 2026-09-19 correction and contradicts the brief; the brief's line should be dropped.

## Scope discipline

No application code, community JSON or tracker was modified; no credential was created or reset.
`git status` was clean before this manifest. Book Club's regeneration remains held (row-247) and
nothing here proposes a package change. `book-nomination` was not touched, so the known
`nominatorFanId` draft-visibility defect was neither exercised nor re-investigated.

Screenshots were taken at every step and are **transient** — `*.png` is gitignored — so this
committed manifest is the durable artifact.
