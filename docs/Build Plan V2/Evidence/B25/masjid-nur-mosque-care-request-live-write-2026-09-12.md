**Workflow:** `mosque-care-request` in Masjid Nur
**Outcome:** Both halves of the proof standard were met — a member created and submitted a care request through the real UI, the owner approved/assigned, sent a private response and resolved it, and the resulting row is confirmed in Postgres at the declared terminal state `resolved`.

**Package identity:** `Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`
- `"skillVersion": "3.6.0"`
- `sha256 = 7a7b48223d14f7ae50237af3a7c290f646eb84ca2c1efa4c0f54ec9d6b6fe1ff`

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

## Identities authenticated

Two real Keycloak logins, each preceded by clearing **both** Chrome and the app
(`pm clear com.android.chrome` + `pm clear com.example.loom_communities_demo`). The genuine Keycloak
login form rendered on every sign-in — no stale-SSO silent re-auth occurred.

| Step | Keycloak user | fan id | Role as shown in app |
|---|---|---|---|
| create + submit | `loom-masjid-member-1` | `fan-masjid-member-1` | Community Member |
| approve / respond / resolve | `loom-masjid-owner-1` | `fan-masjid-owner-1` | Masjid Admin (holds `owner`) |

Account selection matched the token `fanId` in both cases, so the app's anti-impersonation guard was
satisfied rather than bypassed.

## Baseline, measured in this session before touching anything

    select count(*) from workflow_instances;                     -> 61
    ... where workflow_type='mosque-care-request'                -> 0 rows

The brief's hint (~61 rows, few or none of this type) was accurate this time. The row below is
distinguished by its own instance id and `created_at`, not by the count moving.

## Path driven through the real UI

1. **Home tab → "Request care" FAB** (`byRoleIds: ["community-member"]`) — form with four fields.
   Filled `publicSummary`, `privateDetails`, `privacyLabel`, `contactPreference`. Created in `draft`.
2. **`submit-care-request`** (`draft` → `submitted`), guard `actorEqualsField: requesterFanId` —
   satisfied because the create action prefills `requesterFanId: "$actor"`, which resolved to the real
   authenticated fan id (not a role-id alias).
3. *(identity switch)* **Admin tab → approval queue** — the submitted request rendered for the owner
   with `Request changes` / `Approve and assign` / `Reject request`.
4. **`approve-and-assign-care-request`** (`submitted` → `assigned`), guard `allowedRoleIds: ["owner"]`.
   Set `assignedReviewerFanId = $actor` and spawned the `mosque-neutral-notification` row.
5. **`send-private-care-response`** (`assigned` → `responded`), guard
   `actorEqualsField: assignedReviewerFanId` — input dialog, `responseBody = B25-private-response`.
6. **`resolve-care-request`** (`responded` → **`resolved`**, a declared terminal), same guard.

Final UI state: card reads **"Resolved"** with a four-entry status history
(submitted / assigned / responded / resolved) whose actors and timestamps match the stored row
exactly. The card also correctly dropped out of the Admin approval queue, whose binding covers only
`submitted`/`assigned`/`responded`.

## Postgres confirmation (same session)

    select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at
    from workflow_instances where workflow_type='mosque-care-request';

| field | value |
|---|---|
| `instance_id` | `community_mosque_mosque-care-request_scarnyw148c5` |
| `community_id` | `community_mosque` |
| `workflow_type` | `mosque-care-request` |
| `created_by_fan_id` | `fan-masjid-member-1` |
| `current_state` | `resolved` |
| `created_at` | `1789249991219` (2026-09-12 21:53:11 UTC) |

Total rows went 61 → 63 (+2: this row and the notification it spawned).

### Stored `instance_data`, checked field-by-field against what was typed

    {
      "assignedAt": "2026-09-12T21:59:23.724313Z",
      "submittedAt": "2026-09-12T21:53:59.499923Z",
      "privacyLabel": "private",
      "publicSummary": "B25-care-summary",
      "statusHistory": [
        { "at": "2026-09-12T21:53:59.499923Z", "by": "fan-masjid-member-1", "status": "submitted" },
        { "at": "2026-09-12T21:59:23.724313Z", "by": "fan-masjid-owner-1",  "status": "assigned"  }
      ],
      "privateDetails": "B25-protected-detail",
      "requesterFanId": "fan-masjid-member-1",
      "contactPreference": "B25-contact",
      "assignedReviewerFanId": "fan-masjid-owner-1"
    }

All four typed values are stored byte-exact — **no `adb shell input text` truncation**, verified
against the database rather than the screen. (`statusHistory` above is the value read immediately
after step 4; the final row carries all four entries as shown in the UI.)

## Do the two halves agree?

**Yes, in every field checked.** `created_by_fan_id` is `fan-masjid-member-1`, the identity that
actually created it; `current_state` is `resolved`, matching the on-screen "Resolved" badge; and the
status-history actors in the stored JSON match the two fans who drove the transitions.

## Defects observed

None in this workflow. Every declared transition fired for the role its guard names, and the
`resolved` terminal is reachable end to end by real accounts.

Two non-defect observations worth recording:

- The owner account is labelled **"Masjid Admin"** in the identity picker while holding the package's
  `owner` domain role. The guard on `approve-and-assign-care-request` is `allowedRoleIds: ["owner"]`
  and it passed, so the holder genuinely has `owner`; the label is the app shell's derived display
  text, not the role id. Flagged only because "admin" and a package domain role are different things
  in this project and the label alone would not tell you which one is held.
- `submit-care-request` guards on a field (`requesterFanId`) that is only populated by the create
  action's `prefill`. That is the known "self-blocking guard rescued by prefill" shape. It is
  currently correct, and it is live-verified here, but it remains dependent on that prefill staying
  in place.

## Method notes

- The soft keyboard was temporarily disabled (`ime disable`) while filling the create form, because
  with the IME open the dialog scrolled its own fields off-screen and an earlier attempt tapped
  `Create` against empty required fields (which correctly did nothing — no row was written). The IME
  was re-enabled at the end of the run and the device left as found. No application code, community
  JSON, tracker, or credential was modified.
- One earlier tap missed because it used coordinates from a screenshot taken before a further scroll.
  Corrected by re-capturing and tapping within the same verified screen state; the missed tap wrote
  nothing, which the DB query confirmed at the time.
