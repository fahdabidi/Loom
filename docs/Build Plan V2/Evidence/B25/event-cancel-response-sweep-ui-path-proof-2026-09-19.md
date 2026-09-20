# Live proof — the APP's cancel affordance sweeps response rows (`workflow-service:1.0.8`)

**Date:** 2026-09-19 (UTC 2026-09-20T00:40–01:00)
**Community:** Garden Club (`community_garden_club`)
**Workflows:** `garden-event-rsvp` (parent), `garden-event-rsvp-response` (response table)
**Device:** `emulator-5554` (Windows-hosted AVD, reached from the VM over an ssh reverse tunnel to `:5037`)
**Build under test:** remote-wired **debug** APK `com.example.loom_communities_demo` versionName `0.1.0`,
installed 2026-09-19 17:00. **Not** the instrumented capture build.
**Deployed image:** `loom-workflow-service:1.0.8`, pod started `2026-09-19T23:29:46Z` (0 restarts)
**Engine hook under test:** `_sweepEventRsvpResponseRows`, commit `2e29b792`
**Package:** `Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc`,
`specVersion 4`, `skillVersion 3.6.0`,
`sha256 e82a8b39015268dba34e2782bb81613e247fa7c7f7e94e402a80309c5b439d97`
(docs/references copy and app-shell asset are byte-identical)
**Deployed definition version:** 4 (both `garden-event-rsvp` and `garden-event-rsvp-response`)

---

## Verdict, stated exactly

**PROVEN through the UI path.** A fresh event was created **by tapping the app's own "New garden
event" form**, two response rows were driven into **two different** non-terminal states by **taps
from two separately-authenticated fans**, and the event was then cancelled by **tapping the app's
"Cancel event" button**. Both response rows left their distinct states for `cancelled` in the same
write, with before-and-after Postgres reads taken in one session and negative controls held.

This closes the claim the previous manifest
(`event-cancel-response-sweep-live-proof-2026-09-19.md`) explicitly left open: that run proved the
**service/engine boundary** over the HTTP API and recorded the emulator as unreachable. **Every
write in this run was a device tap.** No HTTP call was issued by this dispatch against
`workflow-service`; Postgres was read-only, for evidence.

---

## Identities — each separately authenticated, no stale SSO

Both signed in through the app's real Keycloak browser flow at
`http://192.168.56.10:30082`, using the documented convention (`loom-<slug>` / `LoomTest123!`).
No credential was created or reset.

| Step | Keycloak user | Selected account | Fan id |
|---|---|---|---|
| create event, respond `maybe`, **cancel** | `loom-garden-coordinator-1` | Garden Coordinator 1 | `fan-garden-coordinator-1` |
| respond `going` | `loom-garden-member-1` | Garden Member 1 | `fan-garden-member-1` |

**The stale-SSO trap was actively defended against.** Before each identity switch **both**
`com.android.chrome` and `com.example.loom_communities_demo` were `pm clear`ed. Evidence that this
worked, rather than being assumed: each sign-in re-showed Chrome's first-run screen **and** an
**empty** Keycloak username/password form — never a silent "You're signed in". The app then
rendered "Signed in as Garden Coordinator 1 / Coordinator" and "Signed in as Garden Member 1 /
Member" respectively.

**Role guarding was observed, not assumed.** As the member the card offered only
`Going / Maybe / Not attending / Add reminder`; **"Cancel event" and "Repeat this event" were
absent**, matching `cancel-event`'s `allowedRoleIds: ["garden-coordinator"]`. The tab strip
likewise showed the member-only `Care` tab for the member and the coordinator-only `Documents`
tab for the coordinator.

---

## Setup — all of it through the device

| # | Actor | Device action | Engine result |
|---|---|---|---|
| 1 | coordinator | "New garden event" FAB → filled the form → **Create** | event `..._garden-event-rsvp_o0z96svbuc9f`, state `open`, `created_at 1789865263596` (`00:47:43.596Z`) |
| 2 | — | platform fan-out on create | two response rows materialized, both `pending` |
| 3 | coordinator | selected the agenda entry → tapped **Maybe** | `..._1ja0y2585wrn` untouched; `..._tp8tz0fyfwku` `pending` → **`maybe`** at `1789865400402` (`00:50:00.402Z`) |
| 4 | member | selected the agenda entry → tapped **Going** | `..._1ja0y2585wrn` `pending` → **`going`** at `1789865680642` (`00:54:40.642Z`) |

Row ownership, read from `instance_data`:

    ..._garden-event-rsvp-response_1ja0y2585wrn   fanId=fan-garden-member-1
    ..._garden-event-rsvp-response_tp8tz0fyfwku   fanId=fan-garden-coordinator-1

Two **different** non-terminal states, which is the point: a sweep handling only one state would
look correct against two identical rows.

**Each tap is tied to its write by a sub-second gap** — tap `00:50:00.090Z` → write
`00:50:00.402Z` (312 ms); tap `00:54:40.214Z` → write `00:54:40.642Z` (428 ms). This is stated
because *a tap that returned is not a transition that happened*: the evidence for each transition
is the stored row, not the tap returning.

**No typed value was truncated.** `adb shell input text` is known to truncate silently, so every
form value was settled against the stored row rather than the screen:

    {"coordinatorFanId":"fan-garden-coordinator-1","title":"UISweepProof","eventDate":"2026-09-26",
     "eventTime":"17:00","location":"PlotA","capacity":10,"recurrenceLabel":"None",
     "reminderOffsetHours":24,"durationMinutes":90,"workType":"Autumn"}

`eventDate` and `eventTime` were **selected** from the app's date/time pickers rather than typed.

---

## BEFORE the cancel — control read (`2026-09-20T00:55:03Z`)

    instance_id                                                   | workflow_type              | current_state | created_at    | updated_at    | really_transitioned
    community_garden_club_garden-event-rsvp_o0z96svbuc9f          | garden-event-rsvp          | open          | 1789865263596 | 1789865263596 | f
    community_garden_club_garden-event-rsvp-response_1ja0y2585wrn | garden-event-rsvp-response | going         | 1789865263596 | 1789865680642 | t
    community_garden_club_garden-event-rsvp-response_tp8tz0fyfwku | garden-event-rsvp-response | maybe         | 1789865263596 | 1789865400402 | t

Both response rows have `updated_at > created_at`, so each had a **real transition**, not a bare
insert. Without this read a sweep that did nothing would be indistinguishable from one with
nothing to do.

## THE CANCEL — a tap, not an API call (`2026-09-20T00:58:33.561Z`)

Signed in as `fan-garden-coordinator-1`, the `2026-09-26` agenda entry "UISweepProof" was selected,
the card scrolled until **"Cancel event"** was on screen and clear of the floating action button,
and that button was tapped. The tap is the only cancel this dispatch performed.

## AFTER the cancel — read (`2026-09-20T00:58:51Z`)

    instance_id                                                   | workflow_type              | current_state | created_at    | updated_at
    community_garden_club_garden-event-rsvp_o0z96svbuc9f          | garden-event-rsvp          | cancelled     | 1789865263596 | 1789865913772
    community_garden_club_garden-event-rsvp-response_1ja0y2585wrn | garden-event-rsvp-response | cancelled     | 1789865263596 | 1789865913782
    community_garden_club_garden-event-rsvp-response_tp8tz0fyfwku | garden-event-rsvp-response | cancelled     | 1789865263596 | 1789865913782

### Before → after, per row

| Instance | Fan | Before | After |
|---|---|---|---|
| `..._garden-event-rsvp_o0z96svbuc9f` | created by `fan-garden-coordinator-1` | `open` | `cancelled` |
| `..._garden-event-rsvp-response_1ja0y2585wrn` | `fan-garden-member-1` | **`going`** | **`cancelled`** |
| `..._garden-event-rsvp-response_tp8tz0fyfwku` | `fan-garden-coordinator-1` | **`maybe`** | **`cancelled`** |

**The two response rows share an identical `updated_at` — `1789865913782`
(`00:58:33.782Z`) — 10 ms after the parent's `1789865913772`.** Both rows were written in the same
pass, which is the observable signature of the sweep running inside the parent's transaction as
`2e29b792` describes. The whole thing lands **221 ms after the tap** (`00:58:33.561Z`).

Two rows in different states converged on the response workflow's own `event-cancelled`
transition (`from: [pending, going, maybe, declined, waitlisted] → cancelled`).

### Corroboration from the app's own read projection

`goingCount` / `seatsRemaining` are computed at read time (they are absent from stored
`instance_data`), so the rendered card is an independent view of the same fact.

| Card field | Before the cancel | After the cancel |
|---|---|---|
| Attendees roster | `Going · Garden Member 1` / `Maybe · Garden Coordinator 1` | no live-RSVP grouping rendered |
| going counter | *(not captured at this point — see note)* | **`0 / 10 going`**, `10 seats left` |
| actions offered | `Cancel event`, `Repeat this event`, `Going/Maybe/Not attending` | none (terminal state) |

*Note on the counter:* the card was observed at **`0 / 10 going`, `10 seats left`** immediately
after creation (both rows `pending`) and again **after** the cancel. The intermediate reading with
the member at `going` was scrolled past and **not** captured, so no "1 / 10" frame is claimed here.
The roster grouping is the load-bearing before-picture, and it was captured: the coordinator's card
listed `Garden Member 1` under **Going** and `Garden Coordinator 1` under **Maybe** minutes before
the cancel.

The cancelled event no longer advertises a live RSVP on the surface a member actually sees, which
is the product outcome the hook exists to produce.

---

## Negative controls (all held)

1. **The pre-fix stale pair was NOT retroactively touched.** Event `..._garden-event-rsvp_gwrvhmw1ztbk`
   (`cancelled`) still has response row `..._garden-event-rsvp-response_g45yq8qnsj95` sitting at
   **`going`**, `updated_at` unchanged at `1789220907924`. It was cancelled before the hook existed.
   This is the ticket's before-picture, and it confirms the sweep is scoped to the event being
   cancelled rather than sweeping broadly.
2. **An uninvolved open event was untouched.** `..._garden-event-rsvp_4g0ny4uut0ay` remained `open`
   with `updated_at` unchanged at `1789862844669`.
3. **The previous (API) run's rows were untouched.** `..._p8pjguzd6hgx` and its two response rows
   all still read `cancelled` at `1789862946807`.
4. **The sibling event on the same day was untouched.** "Fall Bed Prep" still rendered
   `1 / 12 going` after the cancel.

---

## What this does and does not establish

**Establishes:** the app's own cancel affordance, tapped by an authenticated coordinator on a real
device against the deployed backend, reaches the engine and produces the response-row sweep —
across two rows that were in two different non-terminal states.

**Does not establish, and is not claimed:**

- Anything about the **instrumented capture** build or B25 screenshot evidence. This was the plain
  remote-wired debug APK; `*.png` is gitignored and this run's screenshots are transient. This
  manifest is the durable artifact.
- Any state other than `going` and `maybe` was exercised. `declined` and `waitlisted` are declared
  in the response workflow's `event-cancelled` `from` list and are covered by unit tests, but this
  device run did not drive them.
- That the package's **declared** `transitionRelated` cascade works. It does not, and that is why
  the engine hook exists: `cancel-event`'s effects filter on `{"eventId": "{id}"}`, and `{id}` in a
  `transitionRelated` filter resolves as an ordinary data-field lookup that matches nothing. The
  sweep observed here is the engine hook, which reads response rows and filters on the event field
  directly, bypassing that broken path.

---

## Reproduction

    PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
    PGPASSWORD="$PW" psql -h 127.0.0.1 -p 15432 -U loom -d loom_workflow_service \
      -c "select instance_id, workflow_type, current_state, created_at, updated_at \
          from workflow_instances where workflow_type like 'garden-event-rsvp%' order by created_at;"

Device access from the VM is via the already-established ssh reverse tunnel to the Windows adb
server on `:5037`. Do **not** run `adb kill-server` / `adb start-server` — a VM-local adb server
squatting on that port is what blocks the tunnel.

---

## Operational notes worth keeping

- **The soft keyboard hides the bottom of the creation dialog, and `keyevent 111` (ESCAPE) closes
  the whole dialog rather than just the keyboard.** Disabling the IME
  (`adb shell ime disable com.google.android.inputmethod.latin/...`) keeps the entire form visible
  while `input text` still injects normally. Note `pm clear` on the app appears to restore the IME,
  so re-check it after any clear.
- **`Repeats` (`recurrenceLabel`) and `Reminder Offset Hours` are required** by
  `garden-event-rsvp`'s `instanceDataSchema`; the first Create attempt failed validation with
  "Repeats is required" and wrote **nothing** — confirmed by an empty Postgres read, not by the
  screen.
- **Fan-out is scoped to fans the cached engine has seen since pod start** (observation carried
  from the previous manifest, and consistent with this run: both fans had issued requests earlier
  in the pod's life, and the create produced exactly two rows — one per fan).
