**Workflow:** `mosque-neutral-notification` in Masjid Nur
**Outcome:** Both halves of the proof standard were met — the row was brought into existence by the owner's `approve-and-assign-care-request` effect, then archived through the real UI by its recipient, and Postgres confirms it at the declared terminal state `archived`.

**Package identity:** `Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`
- `"skillVersion": "3.6.0"`
- `sha256 = 7a7b48223d14f7ae50237af3a7c290f646eb84ca2c1efa4c0f54ec9d6b6fe1ff`

**Date:** 2026-09-12 · **Device:** `emulator-5554` (Windows host, reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)

## Why this row has no create path

`mosque-neutral-notification` has **no create action anywhere in the package**. It exists only as a
`createInstance` effect on `approve-and-assign-care-request`. This is by design and the absence of a
create FAB is **not** a defect. Consequently this row could only be produced by first driving
`mosque-care-request` to `assigned` — see the paired manifest,
`masjid-nur-mosque-care-request-live-write-2026-09-12.md`.

## Identities authenticated

Three sign-ins across the run, each preceded by clearing **both** Chrome and the app. The genuine
Keycloak login form appeared every time; no stale-SSO re-auth occurred.

| Step | Keycloak user | fan id | Why |
|---|---|---|---|
| spawned the row | `loom-masjid-owner-1` | `fan-masjid-owner-1` | fires the owner-guarded approval whose effect creates it |
| archived the row | `loom-masjid-member-1` | `fan-masjid-member-1` | every notification transition is `actorEqualsField: recipientFanId` |

The owner cannot advance this workflow at all — its transitions are recipient-guarded, and the
recipient is the member. That is correct, and it is why the run needed a second identity switch back.

## Baseline, measured in this session before touching anything

    select count(*) from workflow_instances;                            -> 61
    ... where workflow_type='mosque-neutral-notification'               -> 0 rows

## Path driven

1. *(as owner)* **`approve-and-assign-care-request`** on the care request — its `createInstance`
   effect minted this row in the initial state `unread`.
2. *(identity switch back to the member)* The notification rendered on the **Home** tab as
   "Received — unread", carrying `Care request received`, **From Fan Masjid Owner 1**, **For Fan
   Masjid Member 1**, `Audience: requester only`, the message body, and all four recipient-guarded
   actions (`Mark read`, `Keep unread`, `Request follow-up`, `Archive notice`).
3. **`archive-notification`** (`unread` → **`archived`**, a declared terminal).

After archiving, the card correctly disappeared from Home — that binding covers `states: ["unread"]`
only.

## Postgres confirmation (same session)

| field | value |
|---|---|
| `instance_id` | `community_mosque_mosque-neutral-notification_aty862w13sqr` |
| `community_id` | `community_mosque` |
| `workflow_type` | `mosque-neutral-notification` |
| `created_by_fan_id` | `fan-masjid-owner-1` |
| `current_state` | `archived` |
| `created_at` | `1789250363835` (2026-09-12 21:59:23 UTC) |

`created_by_fan_id` is the **owner**, not the member — correct, because the row was created by the
owner's transition effect. The member is the *recipient*, which is a data field, not the creator.

### The `{requesterFanId}` interpolation — the thing the brief asked to check

    {
      "title": "Care request received",
      "audience": "requester only",
      "createdAt": "2026-09-12T21:59:23.724313Z",
      "messageBody": "Your request was received. A care reviewer will follow up privately; no protected details are included here.",
      "senderFanId": "fan-masjid-owner-1",
      "recipientFanId": "fan-masjid-member-1"
    }

**`recipientFanId` resolved to `fan-masjid-member-1`** — verbatim from Postgres. It is not empty, not
null, and not the literal string `{requesterFanId}`. The data-field interpolation in a
`createInstance` effect's `fields` works correctly here, and it addressed the notification to the fan
who actually raised the care request. `senderFanId: "$actor"` likewise resolved to the approving owner.

This was independently visible in the UI as **"For Fan Masjid Member 1"**, and the member could in
fact act on the row, which is the functional proof that the recipient guard matched a real fan.

## Do the two halves agree?

**Yes.** The device showed the notification addressed to Masjid Member 1 and let that member archive
it; Postgres shows `recipientFanId = fan-masjid-member-1` and `current_state = archived`. Total rows
went 61 → 63, the +2 being this row and its parent care request.

## Defects observed

None in this workflow.

One structural observation, recorded as an observation rather than a defect because the terminal was
reached anyway: this workflow's **primary** render binding targets `tabId: "messages"`, and the
Masjid package declares no `messages` tab (its declared tabs are `calendar`, `giving`, `admin`,
`resources`). Only the `home` binding — `states: ["unread"]`, `bindingKind: "summary"` — is reachable
in the shipped shell. That summary binding does render the full action set, so `archived` is
reachable; but the `read` state is rendered **only** on the unreachable `messages` tab, so a
notification moved to `read` via `mark-notification-read` would have no surface at all until it is
archived. I did not drive that state, so I am reporting the binding arithmetic I read in the package
and confirmed against the live tab bar, not an observed dead end.

## Method notes

No application code, community JSON, tracker, or credential was modified. A soft keyboard disable
used earlier in the run for form entry was reverted, and the device was left as found.
