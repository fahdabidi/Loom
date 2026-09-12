**Workflow:** `photo-walk-rsvp` in Camera Club
**Outcome:** PARTIAL — a live UI write was driven and independently confirmed in Postgres, but the
instance rests in its **initial** state `draft`; the only advance out of `draft` (`publish-walk`) is
blocked by a client-side defect, so this run does **not** meet the "terminal or clearly-advanced
state" half of the proof standard and must not be counted as a full proof.

**Package identity:** `Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc`
- `skillVersion`: `3.3.0`
- `sha256`: `199913fcc8d76fcb345d889d09631fce09efd6cd0bced6b9cf0d2b5c8fa254f9`
- Verified byte-identical to the copy **bundled in the installed APK** (extracted from
  `base.apk` at `assets/flutter_assets/packages/loom_communities_app_shell/assets/…`, same sha256),
  so the hash above describes the package actually driven, not merely the one in the working tree.

---

## Identity — escalated from the brief's account, deliberately

The brief specified `loom-camera-member-1` (`camera-club-member`). **That role cannot create this
workflow**, so I escalated, as the brief permits, and name the account used:

- **Authenticated as:** Keycloak `loom-camera-organizer-1`
- **Fan id:** `fan-camera-organizer-1` (confirmed as the `fanId` claim in the decoded access token)
- **Role:** `camera-club-organizer`

Why the escalation was necessary — `photo-walk-rsvp` is organizer-gated at every relevant point in
the package:

| Element | Guard |
|---|---|
| `publish-walk` (the `create` action, `draft → open`) | `allowedRoleIds: ["camera-club-organizer"]` |
| `cancel-walk` (`draft`/`open` → `cancelled`) | `allowedRoleIds: ["camera-club-organizer"]` |
| the create FAB on the `calendar` tab | `byRoleIds: ["camera-club-organizer"]` |

A `camera-club-member`'s photo-walk affordance is the **separate** `photo-walk-response` workflow
type, not this one. All three identity layers were verified present for the organizer before use
(Keycloak account carrying `fanId`, a `fan_passport` row, and a `group_membership_role` membership),
and the password-grant returned HTTP 200. **No credential was created or reset.**

Sign-in was a genuine Keycloak form — not a silent SSO re-issue. `pm clear` on both Chrome and the
app forced the real login form to appear, and the app's account list only loaded *after*
authentication, consistent with `listAccounts` requiring a token.

## Baseline — measured, and the brief's figure was stale

The brief guessed "about **0** rows". Measured at the start of this session, before touching
anything:

- `workflow_instances` total: **25**
- `workflow_type = 'photo-walk-rsvp'`: **0 rows** (a real negative — the reopened claim is confirmed;
  no prior row existed)

After the run: total **26**, `photo-walk-rsvp` **1**. The row is identified below by instance id and
`created_at`, not by the count moving.

Ruled out in advance: `photo-walk-rsvp` **is** published in the deployed catalog
(`community_camera_club_photo-walk-rsvp`, version 4, alongside 3 sibling Camera types as controls),
so the "unpublished type returns success and does nothing" explanation for the missing row does not
apply here.

## What was driven, through the real UI

Community list → Camera Club → entry gate ("No Loom authentication session is stored") → **Continue
to secure sign-in** → Chrome first-run onboarding dismissed → Keycloak form → account selection
(`Camera Organizer 1`, matching the token's `fanId`) → community shell → **Walks** tab (`tabId:
calendar`) → **New photo walk** FAB → create form → **Create**.

All eight fields were entered and verified on screen before submitting:

| Field | Value entered |
|---|---|
| Title | `B25VerifyWalk0912` |
| Route | `Marina Green loop` |
| Event Date | `2026-09-26` (Material date picker — selected, not typed) |
| Event Time | `06:00` (time picker — selected, not typed) |
| Location | `Marina Green trailhead` |
| Led by | `Camera Organizer 1` |
| Capacity | `8` |
| Weather Checklist Notes | `Bring ND filter and tripod` |

## The database row

```
instance_id       community_camera_club_photo-walk-rsvp_ak8lexbtkj3r
community_id      community_camera_club
workflow_type     photo-walk-rsvp
created_by_fan_id fan-camera-organizer-1
current_state     draft
created_at        2026-09-12 11:59:04.974 UTC
```

**Do the two halves agree? Yes.** `created_by_fan_id` is `fan-camera-organizer-1` — exactly the
identity authenticated and driven, with no impersonation. `created_at` (11:59:04.974Z) falls inside
the pre/post stamps taken around the Create tap (11:59:04Z / 11:59:17Z).

Stored `instance_data`, checked against the database rather than the screen:

```json
{"title":"B25VerifyWalk0912","routeName":"Marina Green loop","eventDate":"2026-09-26",
 "eventTime":"06:00","location":"Marina Green trailhead","organizerName":"Camera Organizer 1",
 "capacity":8,"weatherChecklistNotes":"Bring ND filter and tripod"}
```

Every field is byte-exact, with no truncation, and `capacity` stored as a number.

## DEFECT — "Could not load available actions" blocks `publish-walk` from the UI

On the created card, where the transition buttons belong, the UI renders:

> Could not load available actions.  **Retry**

**Reproducible and deterministic.** Tapping **Retry** did not clear it; neither did a full
`am force-stop` + relaunch and re-navigation. The consequence is that the organizer cannot publish
their own walk through the app — `draft → open` is unreachable via the UI, and `draft` is the initial
state, so the instance cannot be advanced at all.

What I verified about it:

- **The backend is not at fault.** `GET /v1/communities/community_camera_club/instances/<id>/available-transitions`
  as this organizer returns **HTTP 200** listing *both* transitions:
  `publish-walk` ("Publish walk") and `cancel-walk` ("Cancel walk").
- **Not a transport failure.** Every `LOOM_BINDING` line during the failure reads
  `service=workflow-engine mode=remote outcome=ok status=200`. (Noting the documented caveat that the
  badge records only the latest outcome per service+scope, so this is suggestive, not conclusive.)
- **Not an authorization refusal.** No `403`, no `unknown_permission_id`; `workflow-service` and
  `app-access` logged no error in the window.
- **Swallowed client-side.** No Dart exception or stack trace appears in `logcat` — the failure
  produces a message with no diagnosable cause, which is what made it expensive to characterise.

**Mechanism NOT established — and one attractive explanation is explicitly not claimed.** Probing the
endpoint with non-canonical ids returns `503 authorization_service_unavailable` (`ext_camera_club`
and a bogus `camera-club` both do), which resembles the known extensionId-vs-communityId bug. **That
row is Closed** (`Access Control and Workflow Service Tracker.md`, commit `9a7b2760`, 2026-09-06),
and my probe only shows what the *server* does with ids **I** chose — it is not evidence of what the
app sent. Against that reading: the create call in this very run persisted under the canonical
`community_camera_club`, so the app is using the canonical id on at least that path. Whatever the
cause is, it should be traced from the app's actual outbound request, not assumed to be a regression
of the closed row.

**Control not run:** whether the same message appears on another community's card (Cedar HOA and
Garden Club both hold instances) would settle app-wide vs Camera-specific. It needs a different
seeded identity, and switching identity carries the stale-SSO risk, so it was left for a follow-up
rather than done carelessly. That is the single highest-value next check.

## Lesser observations

- `adb shell input text` **silently truncated on spaces**: `Marina Green loop` landed as `Marina`.
  Caught on screen and corrected using `%s` escaping; every value was then settled against the stored
  row. Worth noting the failure is silent and the partial value looks plausible.
- On the card's chip row, one chip renders the raw field name **`weatherChecklistNotes`** rather than
  a label or its value, while its sibling chips render properly (`Route: …`, `06:00`, the location,
  `Led by …`). Cosmetic, but it exposes an internal key to members.
- The card polls `workflow-engine` very frequently — roughly 4–5 requests per second sustained while
  simply displayed.

## Environment notes

- Run from the Loom VM; the emulator is Windows-hosted and was driven via `adb -H 192.168.56.1 -P 5037`.
- The emulator hit a `Process system isn't responding` ANR early on (triggered by back-to-back
  `pm clear`s) and rebooted; it came back healthy and all evidence above was gathered after that.
- All six `loom` pods `1/1 Running` throughout.

## Scope

No application code, community JSON, or tracker was modified. No credential was created or reset.
`integration_test/on_device_remote_backend_proof_test.dart` was **not** used. Screenshots were taken
throughout but `*.png` is gitignored, so this manifest is the durable record.

**No test suites were run** — this was a device walkthrough and touched no code, so suite totals
would be unchanged and reporting them would add nothing verifiable.
