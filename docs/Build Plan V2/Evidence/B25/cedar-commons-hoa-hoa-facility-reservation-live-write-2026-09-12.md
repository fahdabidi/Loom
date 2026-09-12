**Workflow:** `hoa-facility-reservation` in Cedar Commons HOA
**Outcome:** Both halves of the proof standard were met — signed in as `loom-hoa-member-1` through the real Keycloak form, created a facility reservation through the Calendar tab's "Reserve a facility" FAB, then fired the member-guarded `reserve-facility` and `cancel-reservation` transitions to drive it `open → reserved → cancelled`, confirming each step in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Package identity driven:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `38c70ed08eabe2ef07011658bdea2434008e385b271e4ae6b98a29007369fd7f`
- Verified byte-identical to the copy **bundled inside the installed APK**: the APK was pulled from
  the device (`pm path` → `base.apk`, 193,851,555 bytes) and its
  `assets/flutter_assets/packages/loom_communities_app_shell/assets/…CedarCommonsHOA….jsonc`
  hashed to the same sha256. The hash therefore describes the package actually driven, not merely
  the one in the working tree.

Date: 2026-09-12. Run host: Loom VM (`fahd-VirtualBox`), emulator hosted on Windows, reached via
`adb -H 192.168.56.1 -P 5037`.

---

## Why this run exists

The previous claim for this row was reopened as untrusted. That reopening was **correct, and the
reason is now on the record**: the immediately prior manifest,
`cedar-commons-hoa-hoa-facility-reservation-live-write-2026-09-11.md`, is itself marked
`BLOCKED — not a proof` (the emulator ANR'd repeatedly at the Keycloak form, so no instance was
ever created). This run is the first actual proof for this row. It does not look for any earlier
instance; it creates a new one.

## Baseline — measured independently before touching anything

The brief's hint ("about **31** rows, and few or none of `hoa-facility-reservation`") was **half
right, and the half it got wrong matters**:

- `workflow_instances` held **31 rows** — the hint's count was accurate.
- But there were **three** existing `hoa-facility-reservation` rows, not "few or none". All three
  were created by `fan-test-alice` on **2026-08-26**, over two weeks before this run.

Those three are recorded here precisely so this run's row is not confused with them. This is also
why the brief forbids judging success by a change in row count: three rows already existed, and a
fourth appearing is only meaningful because its `instance_id`, `created_by_fan_id` and `created_at`
identify it.

| instance_id | created_by_fan_id | state at baseline | created_at |
|---|---|---|---|
| `…_uc8clw8jfw8z` | `fan-test-alice` | open | 2026-08-26 05:48:38Z |
| `…_3pbmhxf5srqh` | `fan-test-alice` | reserved | 2026-08-26 04:30:49Z |
| `…_sx2yfw5tsmou` | `fan-test-alice` | open | 2026-08-26 04:10:25Z |

## Identity

- **Authenticated as:** Keycloak `loom-hoa-member-1`
- **Fan id:** `fan-hoa-member-1`
- **Role:** `hoa-member` (labelled "Homeowner")

**No escalation was needed**, and none was performed. `hoa-facility-reservation`'s create action is
declared `byRoleIds: ["hoa-member", "hoa-board"]`, and both transitions driven below are guarded on
`allowedRoleIds: ["hoa-member"]` plus `actorEqualsField: {key: requesterFanId}` — which the create
action's `prefill: {requesterFanId: "$actor"}` set to this fan.

Verified before driving the UI: a password-grant token request against `loom-test-client` returned
HTTP 200, and the decoded access token carried `preferred_username: loom-hoa-member-1` and
`fanId: fan-hoa-member-1`. That check was read-only — every write below went through the UI.

### The stale-SSO trap was pre-empted, not merely survived

The device arrived holding a session for a **different** fan (`fan-chess-organizer-1`, left by the
preceding Chess Club run). Per the corrected rule, **both** the app's data and Chrome's were
cleared. That produced the intended clean state: the app relaunched showing
*"Loaded 10 example communities"* (confirming the `LOOM_PRELOAD_EXAMPLE_COMMUNITIES` define is
compiled into the build actually running), opening Cedar Commons HOA failed account discovery with
`LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required`, and
that error branch is what rendered **"Continue to secure sign-in"**.

The **real Keycloak login form** then appeared at `192.168.56.10:30082` — an empty username and
password form, not a silent re-issue. Chrome's first-run onboarding intercepted the redirect exactly
as documented and was dismissed with "Use without an account".

Attribution was confirmed from the other end too: `created_by_fan_id` on the resulting row is
`fan-hoa-member-1`, the fan intended.

## Authorization — checked in advance, because a 403 here would have been a new finding

A walkthrough on 2026-09-09 recorded a live HTTP 403 on this exact create path. Before driving, the
grant chain was confirmed: `fan-hoa-member-1` is an `active` member of group
`loom_communities_cedar-commons-hoa` (the group carrying
`external_resource_id = community_cedar_commons_hoa`, which is the one the service resolves by)
holding role `hoa-member`, and `hoa-member` holds `calendar.create`, `calendar.cancel`,
`calendar.edit`, `calendar.reopen` and `calendar.set_reminder`.

`hoa-facility-reservation` resolves to the `calendar` archetype family, so `create` requires
`calendar.create`. **No 403 occurred.** The earlier gap is fixed on `app-access:0.3.10`.

## The path driven

All through the real UI, as `hoa-member`, on the Calendar tab.

1. **Create** — the tab's `presentation: "fab"` create action, labelled **"Reserve a facility"**,
   rendered for this role. The form exposed exactly the six `writableBy: "formEntry"` fields; the
   three `writableBy: "platform"` fields came from the binding's `prefill`. Values entered:
   Title `B25 Pool Deck Reservation`, Facility `Pool Deck`, Event Date `2026-10-20` (native date
   picker), Event Time `14:00` (native time picker), Window `Afternoon 2-4pm`, Location
   `Pool Deck East Terrace`. Result: instance created in initial state `open`.
   *Facility and date were deliberately chosen to differ from the three pre-existing rows (all
   `Clubhouse`) so the `reserve-facility` guard's `locationOverlap` check would not be the thing
   under test.*
2. **`reserve-facility`** (`open → reserved`) — guard `allowedRoleIds: ["hoa-member"]` +
   `actorEqualsField: requesterFanId` + `locationOverlap`. Card re-rendered as **Reserved**.
3. **`cancel-reservation`** (`reserved → cancelled`) — same guard shape. Card re-rendered as
   **Cancelled**, offering only **"Reopen request"**, which is exactly the one transition the
   package declares out of `cancelled` for `hoa-member`.

A useful negative control appeared unprompted: the pre-existing `fan-test-alice` cards rendered in
the same list with **no action buttons at all**, which is correct — their `requesterFanId` is a
different fan, so `actorEqualsField` fails. The affordances are genuinely actor-scoped, not
decorative.

## The database row — confirmed independently, in this same session

```
instance_id       community_cedar_commons_hoa_hoa-facility-reservation_rqz311p8xkqq
community_id      community_cedar_commons_hoa
workflow_type     hoa-facility-reservation
created_by_fan_id fan-hoa-member-1
current_state     cancelled
created_at        1789225852757   = 2026-09-12T15:10:52Z
updated_at        1789226052944   = 2026-09-12T15:14:12Z
```

**This row is identified by id and timestamp, not by a count.** A wall-clock reading was taken
immediately before each UI action and the row's own timestamps land within 200 ms of each:

| Action | Clock immediately before tap | Row timestamp written | Delta |
|---|---|---|---|
| Create | `1789225852585` | `created_at 1789225852757` | +172 ms |
| `cancel-reservation` | `1789226052775` | `updated_at 1789226052944` | +169 ms |

Stored `instance_data` at the terminal state:

```json
{
  "title": "B25 Pool Deck Reservation",
  "facility": "Pool Deck",
  "eventDate": "2026-10-20",
  "eventTime": "14:00",
  "reservedAt": "2026-09-12T15:12:05.811197Z",
  "cancelledAt": "2026-09-12T15:14:12.944Z",
  "requesterFanId": "fan-hoa-member-1",
  "durationMinutes": 120,
  "locationDetails": "Pool Deck East Terrace",
  "reminderEnabled": false,
  "reservedByFanId": "fan-hoa-member-1",
  "reservationWindow": "Afternoon 2-4pm"
}
```

**Every load-bearing value was settled against the stored row, not the screen** — the standing rule
is that reading a value back off the device is not sufficient, because a horizontally scrolling
field shows a plausible prefix while the stored value is short. Nothing was truncated here: all six
typed fields match character-for-character, including the longest (`Pool Deck East Terrace`, 22
chars) and the two containing spaces and a hyphen (`Afternoon 2-4pm`).

The three `writableBy: "platform"` prefill fields landed correctly —
`requesterFanId: "fan-hoa-member-1"` (from `$actor`, and independently corroborating the
authenticated identity), `durationMinutes: 120`, `reminderEnabled: false` — and the two
`writableBy: "effect"` fields were written by the transitions that own them:
`reservedByFanId`/`reservedAt` by `reserve-facility`, `cancelledAt` by `cancel-reservation`.

### The `createInstance` effect target exists and actually fired

`reserve-facility` declares an effect creating an `hoa-owner-notification`. That is the shape that
silently no-ops when the target type is absent from the deployed catalog (`createInstance` returns
success and does nothing). It did **not** no-op here — a real row was written:

```
instance_id        community_cedar_commons_hoa_hoa-owner-notification_7wi6ylrjxdth
created_by_fan_id  fan-hoa-member-1
current_state      sent
created_at         1789225925811   (same millisecond as reservedAt)
instance_data      {"title": "Facility reservation confirmed",
                    "body": "Your facility reservation has been confirmed.",
                    "senderFanId": "fan-hoa-member-1",
                    "recipientFanId": "fan-hoa-member-1",
                    "sentAt": "2026-09-12T15:12:05.811197Z",
                    "deliveryState": "Sent"}
```

## Do the two halves agree?

**Yes, at every step.**

| Step | Device showed | Postgres held |
|---|---|---|
| After create | card in **Reservation open** | `current_state = open` |
| After `reserve-facility` | card in **Reserved** | `current_state = reserved`, `reservedByFanId = fan-hoa-member-1` |
| After `cancel-reservation` | card in **Cancelled**, only "Reopen request" offered | `current_state = cancelled`, `cancelledAt` set |

Row totals moved `31 → 33` (this reservation plus the notification its effect created), and
`hoa-facility-reservation` rows moved `3 → 4`. Those counts are reported as description, not as the
proof; the proof is the instance id and the timestamps above.

---

## Defect observed — the create dialog collapses its own form when the keyboard opens

**Reproducible, and it cost this run roughly fifteen minutes.** On the "Reserve a facility" dialog,
focusing any text field raises the soft keyboard, and the dialog's entire field region collapses to
**zero height**. What remains on screen is the title "Reserve a facility" and the Cancel/Create
buttons, with no field visible at all — the user is typing into a field they cannot see, and cannot
tell which field has focus or what it now contains.

Verified rather than assumed:

- Reproduced twice, and then a third time deliberately after the walkthrough was complete.
- **Swiping inside the collapsed strip reveals nothing** — the content area has no height to scroll,
  so this is a collapse, not merely a scroll position that needs adjusting.
- There is a large expanse of **unused blank space between the dialog and the keyboard**, so the
  space to render the fields exists; the dialog shrinks its content instead of repositioning into
  that space.
- Pressing ESC to dismiss the keyboard **closes the whole dialog**, discarding everything typed —
  so the obvious user recovery loses the work.

Impact is not cosmetic: a six-field required form where no field is visible while typing is a form
that cannot be filled with confidence, and the field most at risk is whichever the user cannot
re-read — which is the same class of hazard as the `adb shell input text` truncation rule (a
load-bearing value that looks fine and is not).

**Workaround used, and disclosed for honesty:** the walkthrough disabled the device's soft IME
(`adb shell ime disable …LatinIME`) so the dialog kept full height while fields stayed focusable,
filled the form with all fields visible, and **re-enabled and re-selected the IME afterwards**
(confirmed: `default_input_method` is back to `…LatinIME`). This is a device-side input-method
setting only — no application code, community JSON, or tracker was modified. It does not change
what the app did; it only made the fields observable while driving them. A real user on a real
phone has no such workaround, which is why this is filed as a defect rather than a note.

Screenshots: `/tmp/b25cedar/11-title.png`, `14b-tapped.png`, `33-kbcollapse.png`, `34-kbscroll.png`
(keyboard raised, no fields); `15-noime.png`, `24-allfilled.png` (IME disabled, all six fields
visible and filled). Note `*.png` is gitignored and therefore transient — this manifest is the
durable record.

## Things that did NOT go wrong, recorded so they are not re-investigated

- **No `403` / `unknown_permission_id`.** The 2026-09-09 calendar-permission gap is closed.
- **No `JsonUnsupportedObjectError: Instance of 'DateTime'` on this workflow.** That known Cedar
  listing failure belongs to `hoa-dues-payment`, whose `reminder` block is unconditional. This
  workflow's `reminder` block is gated by `enabledField: reminderEnabled`, and the create action
  prefills that to `false`, so the calendar listing rendered normally throughout.
- **No ANR and no crash** (`dumpsys window`: *"no ANR has occurred since boot"*; the app process
  stayed alive for the whole run) — unlike the 2026-09-11 attempt, which was blocked by exactly that.
- **No stray instance.** The post-run dialog reopened to reproduce the defect was dismissed with
  Cancel, and the table was re-counted afterwards to confirm it created nothing (still 4 / 33).

## Scope note

No application code, community JSON, spec or tracker was modified, and no credential was created or
reset. The only repository change from this run is this manifest.
