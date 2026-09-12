**Workflow:** `garden-event-rsvp` in Garden Club
**Outcome:** Both halves of the proof standard were met — signed in as `loom-garden-coordinator-1` through the real Keycloak form, created a garden event through the Calendar tab's "New garden event" FAB, and drove it through the UI to its terminal `cancelled` state, confirmed by the Postgres row.

**Package identity:** `Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc` — `skillVersion` **3.6.0**, `sha256` **71659f0896f3d28d27f2d24b20da616b42834e66b6e313150e6c654e42b9ef3b`

---

## Identity

| | |
|---|---|
| Keycloak account | `loom-garden-coordinator-1` |
| Fan id | `fan-garden-coordinator-1` |
| Role | `garden-coordinator` (group `loom_communities_garden-club`) |
| Escalation | none — the brief's nominated account was sufficient |

The account was verified across all three identity layers **before** the device run: a `fan_passport` row
exists, `group_membership_role` binds the fan to `garden-coordinator`, and a password-grant token request
against `loom-test-client` returned HTTP 200 with claim `fanId=fan-garden-coordinator-1`.

**Stale-SSO precaution taken.** `pm clear` was run against **both** `com.example.loom_communities_demo`
and `com.android.chrome` before launching. The app then reported
`LoomAuthNotLoggedInException: No Loom authentication session is stored`, and Keycloak presented a **real
login form** (not a silent re-issue). Chrome's first-run onboarding did intercept the redirect once and was
dismissed with "Use without an account". Both typed credential fields were read back on screen before
submitting — `loom-garden-coordinator-1` and `LoomTest123!`, neither truncated.

## Baseline — measured, not assumed

Queried before touching the device:

- `workflow_instances` held **27** rows across 22 workflow types.
- **Zero** rows of `workflow_type = 'garden-event-rsvp'`.

So the brief's hint was accurate this time, and the previously-claimed live write for this community has
**no row behind it**. This run creates a new instance rather than looking for that one.

`garden-event-rsvp` is published in `workflow_definitions` as
`community_garden_club_garden-event-rsvp`, version 4 — so a `createInstance` naming it could not
silently no-op.

## APK provenance

The engine-contract fix `58e9e122` ("stop asking the remote engine about a response row that cannot
exist") was committed **2026-09-12 06:13**. The APK on the device was built **06:17** and installed
**06:19**, both after it, from a clean tree. This matters because `garden-event-rsvp` uses the same
`responseTable` shape as Camera Club's `photo-walk-rsvp`, which that commit unblocked.

## The path driven

1. Launch → 10 example communities preloaded → **Garden Club** → "Open community".
2. Account entry gate → "Continue to secure sign-in" → Chrome → Keycloak form → signed in.
3. Account list → selected **Garden Coordinator 1** (`fan-garden-coordinator-1`).
4. Community opened: *"Signed in as Garden Coordinator 1 — Coordinator"*.
5. **Calendar** tab → the `garden-coordinator`-guarded **"New garden event"** FAB rendered.
6. Filled the create form and submitted.
7. Card rendered with attendee roster → tapped **Going** (response row `pending` → `going`).
8. Tapped **Cancel event** → event reached terminal `cancelled`.

### Form values, settled against the stored row

`adb shell input text` truncated the title to "Fall" on the first attempt (it splits on spaces); it was
cleared and retyped as `Fall%sBed%sPrep`. Event Date and Event Time are **picker** widgets, not text
fields — values were selected, not typed. Every value below was verified against `instance_data` in
Postgres, not just against the screen:

| Field | Entered | Stored in `instance_data` |
|---|---|---|
| `title` | Fall Bed Prep | `'Fall Bed Prep'` |
| `eventDate` | picker → 2026-09-26 | `'2026-09-26'` |
| `eventTime` | picker → 10:00 AM | `'10:00'` |
| `location` | North Plot | `'North Plot'` |
| `capacity` | 12 | `12` |
| `recurrenceLabel` | Weekly | `'Weekly'` |
| `reminderOffsetHours` | 24 | `24` |
| `durationMinutes` | 90 | `90` |
| `coordinatorFanId` | *(prefill `$actor`)* | `'fan-garden-coordinator-1'` |

No truncation in any field.

## Half 1 — final UI state

The event left the `open` primary binding and now renders under the `cancelled` **summary** binding on the
Calendar tab: the agenda entry and summary card remain ("Fall Bed Prep", 10:00, North Plot, Repeats:
Weekly, Default reminder: 24 hours before, 90 minutes), while the editable field form, the **Save changes**
button and **every transition action** are gone. That disappearance is the on-screen evidence of the
terminal state.

## Half 2 — the database row

```
instance_id       | community_garden_club_garden-event-rsvp_gwrvhmw1ztbk
community_id      | community_garden_club
workflow_type     | garden-event-rsvp
created_by_fan_id | fan-garden-coordinator-1
current_state     | cancelled
created_at        | 2026-09-12 13:46:28 UTC
updated_at        | 2026-09-12 13:49:11 UTC
```

The companion response row, auto-created by the calendar archetype in the same second:

```
instance_id       | community_garden_club_garden-event-rsvp-response_g45yq8qnsj95
workflow_type     | garden-event-rsvp-response
created_by_fan_id | fan-garden-coordinator-1
current_state     | going          (was 'pending' at creation)
```

`workflow_instances` went from **27 → 29** rows. The `+2` rather than `+1` is fully accounted for: the
event plus its auto-created response row, both stamped `13:46:28` and both by `fan-garden-coordinator-1`.
The instance is identified by its **instance id and `created_at`**, not by the count moving.

## Do the two halves agree?

**Yes.** The UI showed the event demoted to a summary card with no actions; the row reads
`current_state = cancelled`. `created_by_fan_id` is **`fan-garden-coordinator-1`**, exactly the identity
authenticated and acted as — no impersonation, no stale-SSO attribution. Every remote engine call in
logcat during the run reported `outcome=ok status=200`; there were no errors, ANRs or crash dialogs.

---

## Defect observed — `cancel-event`'s `transitionRelated` cascade did not fire

**This does not affect the proof above** (the event itself reached its terminal state), but it is a real
finding and is reported rather than papered over.

`cancel-event` declares five `transitionRelated` effects that should drive every response row in
`pending` / `going` / `maybe` / `declined` / `waitlisted` through the `event-cancelled` transition into
`cancelled`. After the event reached `cancelled`, the response row was **still `going`**.

What was verified, so this is not a mis-read:

- The row is genuinely still `going` — re-queried after the event's transition; not lag.
  Its `updated_at` (`13:48:27`, my RSVP) predates the event's (`13:49:11`).
- The linkage is exact: the response row's `eventId` is
  `community_garden_club_garden-event-rsvp_gwrvhmw1ztbk`, character-for-character the event's `instance_id`.
  So the effect's `filter: {eventId: "{id}", $state: "going"}` had a real target to match.
- The target transition accepts it: `event-cancelled` is `from: [pending, going, maybe, declined,
  waitlisted] → cancelled`, guarded `allowedRoleIds: ["garden-coordinator"]` — and I held that role.
- No error surfaced anywhere: the transition returned HTTP 200 and logcat showed no exception.

**User-visible symptom:** the cancelled event's summary card still reads **"1 / 12 going"**, so a cancelled
event continues to advertise a live attendee count, and the attendee's own RSVP row still says they are
attending an event that no longer exists.

**Mechanism — candidates, not asserted.** `transitionRelated` in `local_workflow_engine_api.dart` has two
distinct paths that both fail *silently* and would look identical from outside:

- `if (matches.isEmpty) continue;` — if `"{id}"` does not resolve against `computed` on this path, the
  filter matches nothing and the effect is skipped with no error.
- `on _TransitionGuardFailure { /* deliberately does not affect the source */ }` — if the caller's roles
  are not resolved in the nested transition's server-side context, the target guard returns false and the
  cascade is swallowed by design.

I did not discriminate between these two, and I am not claiming which it is. Worth noting for whoever
does: the same code also transitions only `matches.first`, so even once the cascade works it would move
**one** response row per effect, not all of them — with five effects and one state each, an event with two
`going` respondents would strand the second. That is a reading of the source, not something this run
exercised.

Related to the local-vs-remote contract note already in `CLAUDE.md`: a green
`transition_related_effect_test.dart` runs through the local engine and would not catch this on the
shipped remote path.

## Scope note

No application code, community JSON, or tracker was modified, and no credential was created or reset.
This manifest is the only file added.
