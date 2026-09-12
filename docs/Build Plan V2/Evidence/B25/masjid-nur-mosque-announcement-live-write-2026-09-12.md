**Workflow:** `mosque-announcement` in Masjid Nur
**Outcome:** Both halves of the proof standard were met — signed in as `loom-masjid-owner-1`, created an announcement through the Admin-tab FAB and drove it `draft` → `previewed` → `sent` → `archived` (declared terminal), with the row confirmed in Postgres at every step.

**Package identity:** `Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `7a7b48223d14f7ae50237af3a7c290f646eb84ca2c1efa4c0f54ec9d6b6fe1ff`

Date: 2026-09-12 · Device: `emulator-5554` (Windows host, via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)
APK `versionName=0.1.0`, `lastUpdateTime=2026-09-12 11:28:15` · Repo `main` @ `4f6eef87`

---

## Identity

| | |
|---|---|
| Keycloak username | `loom-masjid-owner-1` |
| Fan id | `fan-masjid-owner-1` |
| Role | `owner` (2 holders provisioned: `fan-masjid-owner-1`, `fan-masjid-owner-2`) |
| App Access group | `loom_communities_masjid-nur` |
| workflow-service `community_id` | `community_mosque` (read off the row, not constructed) |

This was an identity switch from the previous runs (`loom-portability-owner-1`), so **both** Chrome and
the Loom app were cleared:

    adb shell pm clear com.android.chrome
    adb shell pm clear com.example.loom_communities_demo

Launch screen then showed **"Loaded 10 example communities"**, confirming the preload flag is compiled
into this build. A real Keycloak login form appeared (no SSO auto-signin), and the app reported
*"Signed in as Test masjid-owner-1"*. `created_by_fan_id` on the resulting row is `fan-masjid-owner-1`,
matching the identity driven — no impersonation and no stale-cookie attribution.

## Baseline, measured in this session before touching anything

`workflow_instances` held **48** rows, of which **zero** were `mosque-announcement`. This matched the
brief's hint. The row below is distinguished by its own instance id and `created_at`, not by the count
(which moved 48 → 49).

Pre-flight also confirmed `mosque-announcement` **is published** — `workflow_definitions` row
`community_mosque_mosque-announcement`, version 4 — so a `createInstance` naming it could not
silently no-op.

## Path driven through the real UI

1. Masjid Nur → **Admin** tab (declares `visibleRoleIds: ["owner"]`; it rendered, confirming the role resolves).
2. Create FAB → **"New announcement"**.
3. Filled the four required fields, then **Create**.
4. **Preview announcement** → `previewed`.
5. **Publish announcement** → `sent`.
6. **Archive announcement** → `archived` *(declared terminal)*.

At `draft` the card offered exactly the five package-declared transitions — Save draft, Preview,
Schedule, Publish, Cancel. `mark-announcement-read` was **never** offered, which is correct: it is
guarded on `community-member`, not `owner`. Not a missing affordance.

## The DB row

    select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at
      from workflow_instances where workflow_type='mosque-announcement' order by created_at desc limit 5;

| field | value |
|---|---|
| `instance_id` | `community_mosque_mosque-announcement_haf78u7gkfie` |
| `community_id` | `community_mosque` |
| `workflow_type` | `mosque-announcement` |
| `created_by_fan_id` | `fan-masjid-owner-1` |
| `current_state` | `archived` |
| `created_at` | `1789239899103` = **2026-09-12 19:04:59 UTC** |

Final `instance_data`:

    {"senderFanId":"fan-masjid-owner-1","deliveryState":"sent","readFanIds":[],
     "deliveryHistory":[{"status":"sent","by":"fan-masjid-owner-1","at":"2026-09-12T19:06:45.518207Z"}],
     "revisionHistory":[{"action":"previewed","by":"fan-masjid-owner-1","at":"2026-09-12T19:06:14.435294Z"}],
     "title":"B25 Eid Notice","body":"Jumuah time change","audience":"All members",
     "channel":"In-app","sentAt":"2026-09-12T19:06:45.518207Z"}

**Do the two halves agree? Yes.** Each transition was confirmed in Postgres immediately after firing
it (`draft` → `previewed` → `sent` → `archived`), and the final UI badge read **Archived** while the
row read `archived`. Every history entry is attributed to `fan-masjid-owner-1`. `senderFanId` and
`sentAt` were platform/effect-written as declared. Every engine call logged
`LOOM_BINDING … scope=ext_mosque outcome=ok status=200`; no `FATAL EXCEPTION` and no ANR in logcat.

**Field values verified against the stored row, not the screen** (the documented `input text`
truncation trap): `title`, `body`, `audience` and `channel` are all intact and complete.

## Where each state renders — verified on device, matches the package

| states | tab | surface family |
|---|---|---|
| `draft`, `previewed`, `scheduled` | Admin | `formEntry` |
| `sent` | Home *(and Messages)* | `notificationInbox` |
| `archived`, `cancelled` | Admin | `statusTimeline` (summary) |

This is worth recording because **the card moves tabs as it advances**. After Publish the card left the
Admin tab entirely and reappeared on **Home**, which is where `archive-announcement` had to be fired
from; after Archive it returned to Admin as a summary. A run that only watched the Admin tab would read
the disappearance as a lost instance. All three placements are exactly what the package declares.

## Defects observed

**None in the product.** The workflow is reachable end to end by the role that owns it, guards behave
as declared, required-field validation is honest (an empty `audience` produced *"Audience is required."*
and, correctly, **no** database row), and no state was orphaned.

Two environment/tooling notes, neither a product finding:

- **Chrome rendered the Keycloak page blank on first load** (title bar populated, body empty; a renderer
  child process died in logcat). A pull-to-refresh rendered the real form. Keycloak itself was healthy
  throughout — a `curl` that appeared to show a fault was my own malformed request, missing the PKCE
  `code_challenge_method` the client requires.
- **`adb shell input text` splits on spaces**, so `'B25 Eid Notice'` typed only `B25`. Combined with the
  dialog re-laying-out when the keyboard appears, two separate strings landed in one field as
  `B25Jumuah`. Using `%s` for spaces and re-locating each field between entries fixed it. This is the
  same family as the documented truncation trap and is why every value here was settled against the
  database rather than the screen.
