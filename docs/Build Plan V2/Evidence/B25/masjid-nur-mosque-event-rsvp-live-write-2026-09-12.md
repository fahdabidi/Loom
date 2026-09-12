**Workflow:** `mosque-event-rsvp` in Masjid Nur
**Outcome:** Both halves of the proof standard were met — created a new event through the Calendar FAB as the authenticated owner, published it to `open`, and cancelled it to the declared terminal state `cancelled`, with the row confirmed in Postgres at every step.

**Package identity exercised**

    P=app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_Mosque_Example.jsonc
    "skillVersion": "3.6.0"
    sha256  7a7b48223d14f7ae50237af3a7c290f646eb84ca2c1efa4c0f54ec9d6b6fe1ff

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

---

## Identity

| | |
|---|---|
| Keycloak account | `loom-masjid-owner-1` |
| Fan id | `fan-masjid-owner-1` |
| Role driven | `owner` (package label "Masjid Admin", `roleLabel` "Admin") |
| Sign-in performed this run | **No** — the pre-existing session was already this account |

The session was already signed in as the required identity, so per the ticket no `pm clear` was
performed and no credential was created or reset. Identity was confirmed **live on device**, not
inferred: the AppBar account dialog read *"Signed in as Test masjid-owner-1 … ID: fan-masjid-owner-1"*
with **Masjid Admin** as the active role.

That label needed checking rather than assuming, because the create action guards on `byRoleIds:
["owner"]` while the UI displays "Masjid Admin" — the same string that names Masjid's *generated
governance* role. Read from the package: `"roleId": "owner"` carries `"label": "Masjid Admin"`. The
displayed label is the domain role's label, so the signed-in role is exactly the guarded one. No
escalation to another account was needed.

---

## Baseline — measured, not assumed

Queried before touching the device:

    total rows in workflow_instances          49
    rows where workflow_type='mosque-event-rsvp'   0  (zero rows)
    community_mosque rows   mosque-announcement 1, mosque-donation-payment 1

The brief's hint ("about 49 rows, few or none of `mosque-event-rsvp`") was accurate this time. The
Calendar tab independently agreed, showing *"No events are scheduled yet."* This run's row is
distinguished by its own instance id and `created_at`, not by the count moving.

---

## The path driven

| # | Action | Surface | Resulting state |
|---|---|---|---|
| 1 | **New event** FAB → filled 6 required fields → **Create** | Calendar tab | `draft` |
| 2 | **Publish event** | Admin tab (draft card) | `open` |
| 3 | **Cancel event** | Calendar tab (open card) | **`cancelled`** (terminal) |

All six `instanceDataSchema` fields are `required: true` and all six were supplied. Date and time
were set through the native pickers (selecting rather than typing); the three text/number fields were
typed in short chunks, then settled against the stored row below.

**A note on step 2's surface.** After Create, the Calendar tab still read *"No events are scheduled
yet."* That is **not** a defect and was confirmed against the package before proceeding: the `draft`
state binds to `tabId: "admin"` with the `formEntry` surface, while the calendar binding covers only
`open` and `cancelled`. The draft card was found exactly where the package says it renders, carrying
its three owner transitions (Save draft / Publish event / Cancel event).

---

## Database confirmation (same session)

Final state:

    instance_id        community_mosque_mosque-event-rsvp_c6nox774ydtf
    community_id       community_mosque
    workflow_type      mosque-event-rsvp
    created_by_fan_id  fan-masjid-owner-1
    current_state      cancelled
    created_at         1789240736803   (2026-09-12 19:18:56 UTC)

State was re-queried after each transition, not only at the end: `draft` after Create, `open` after
Publish event, `cancelled` after Cancel event. Total rows moved 49 → 50.

**Stored fields, read back to rule out silent input truncation** (`instance_data` is a `text` column
and needs a `::jsonb` cast):

| field | stored value |
|---|---|
| `title` | `B25 Eid Prayer` |
| `eventDate` | `2026-09-26` |
| `eventTime` | `12:00` |
| `location` | `Main Hall` |
| `recurrence` | `None` |
| `capacity` | `200` |
| `publishedAt` | `2026-09-12T19:20:04.825081Z` |

Nothing was truncated. `publishedAt` is effect-written by `publish-event` (`{"op": "set", "key":
"publishedAt", "value": "$timestamp"}`), so its presence is independent evidence that the publish
transition's effect actually executed rather than the state merely changing.

`eventHistory` is **empty, and that is correct** — it is appended only by `save-event-draft`, which
was deliberately not fired; `publish-event` sets only `publishedAt`, and `cancel-event` declares no
effects at all. Checked against the package rather than reported as an unwritten field.

**Do the two halves agree?** Yes. The UI reached the terminal card with no remaining actions, and the
row reads `cancelled`, created by `fan-masjid-owner-1` — the identity confirmed on device before the
run. Screen and database agree on state, on authorship, and on all six field values.

---

## Two expected conditions, confirmed and NOT filed as defects

1. **The six RSVP transitions were never offered.** `rsvp-going`, `rsvp-maybe`, `rsvp-not-going`,
   `join-event-waitlist`, `cancel-rsvp` and `add-event-reminder` are all `allowedRoleIds:
   ["community-member"]`. Driving as `owner`, the `open` card offered exactly **Open volunteer shift**
   (`["community-member", "owner"]`) and **Cancel event** (`["owner"]`) — precisely the owner-reachable
   set. No identity switch was attempted.
2. **`cancel-event` swept nothing.** Masjid has no response workflow and zero `transitionRelated`
   effects; RSVPs are lists on the event instance itself. No spawned rows were looked for.

---

## Observation (not a blocker, and not a workflow defect)

The cancelled event still renders in the Calendar agenda **with no visible state indicator**. The
terminal card shows title, `0 / 200 going`, time, location, repeats, `Published …` and `Open spots:
200` — but nothing saying *Cancelled*, despite the state declaring `"label": "Cancelled"` and
`"tone": "negative"`.

Reported with its limits stated: the `open` card carried no state chip either, so this is a
characteristic of the **`event-rsvp` card surface generally**, not something specific to cancellation
— unlike Masjid's announcement card, which renders an "Archived" chip prominently. The distinguishing
signal that does exist is behavioural: on cancellation the card loses every action button and becomes
read-only, matching its `bindingKind: "summary"`. The engine state is correct in the database.

The practical consequence worth someone's judgement: a member scanning the calendar sees a cancelled
event styled identically to a live one, including an inviting `Open spots: 200`. Whether that warrants
a state chip on this surface is a product decision, not something this run can settle.

## Device health

No ANR since boot (`dumpsys window` → `<no ANR has occurred since boot>`), and no `FATAL EXCEPTION`
or `E/flutter` entries in logcat across the run.

## Scope

No application code, community JSON, or tracker was modified. No credential was created or reset.
This manifest is the only committed artifact. Screenshots were captured at every step but `*.png` is
gitignored, so they are transient.
