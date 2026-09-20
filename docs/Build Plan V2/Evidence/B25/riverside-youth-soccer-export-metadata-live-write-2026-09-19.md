**Workflow:** `soccer-export-metadata` in Riverside Youth Soccer
**Outcome:** Both halves of the proof standard were met — signed in as `loom-soccer-owner-1`, created a live export from the **Coach & Owner** tab's "New redacted export" action and drove it through **five** owner-guarded transitions, advancing instance `…_dmf8is40534u` from `draft` all the way to `completed` in Postgres, with `updated_at` no longer equal to `created_at` and every step stamped into `exportHistory` by `fan-soccer-owner-1`.

**Package identity:** `skillVersion: "3.3.0"`, `specVersion: 4`, sha256 `a36df7d62bea301e2e686db11d401027efce93c5e92210564b63569761777504`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_YouthSoccer_Example.jsonc`; byte-identical to `docs/references/communities/Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc`, verified with `cmp` in this session.)

**Date:** 2026-09-20 (UTC; device clock 2026-09-19 local) · **Device:** `emulator-5554` (Windows host, reached over an ssh reverse tunnel to :5037)
**Community id (workflow-service):** `community_riverside_youth_soccer` — read off the row, not assumed.
**Deployed images at time of run:** `loom-workflow-service:1.0.8` (pod `workflow-service-86f694557d-gd4k9`), `loom/app-access:0.3.11`, `loom/fan-passport:0.3.1`, `loom-keycloak:phase-c3`. All six `loom` pods `1/1`.
**Engine actually exercised:** remote. The app's own telemetry, not an assumption —
`LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/ scope=ext_youth_soccer outcome=ok status=200`.

## Identity — and how the stale-SSO hazard was excluded

The role that holds every transition on this workflow is **`soccer-owner`** (read off the package:
`visibility.readGuard.allowedRoleIds` and all ten transition guards are `["soccer-owner"]`). So the
walkthrough was driven as the owner, not as coach or guardian.

Authenticated as **`loom-soccer-owner-1`** / fan id **`fan-soccer-owner-1`**, role `soccer-owner`
(confirmed in `group_membership_role` before the run; `soccer-owner` holds the nine
`export_wizard.*` permissions including `.create`). No credential was created or reset.

**Both Chrome and the app were cleared before signing in**, and the clear is proven rather than
asserted:

- `pm clear com.example.loom_communities_demo` → the community entry gate rendered
  `LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required.`
- `pm clear com.android.chrome` → the custom tab opened on Chrome's **first-run** screen
  ("Make Chrome your own"), and after skipping it Keycloak served a **genuinely empty**
  `Sign in to your account` form at `192.168.56.10:30082`. No SSO cookie survived, so no previous
  fan could have been silently re-issued a token.

The account then selected in the picker was `fan-soccer-owner-1` — the same identity that
authenticated, which is what the app's anti-impersonation check requires. The in-app header read
**"Signed in as Soccer Owner 1 · League Owner"**.

## Half 1 — driven live through the real UI

Every step below is a tap on the app's own control. Nothing was invoked against the service directly.

1. Riverside Youth Soccer → **Coach & Owner** tab (`tabId: admin`, `visibleRoleIds: ["soccer-coach", "soccer-owner"]`).
2. Tapped the **"New redacted export"** FAB — the package's own `create` action on the
   `exportWizard` primary binding. Typed the title and tapped **Create**.
3. Card rendered **"Draft export"**. Tapped **"Select export scope"**, entered the two required list
   inputs, submitted.
4. Card rendered **"Export scope selected"**. Tapped **"Confirm redaction preview"**.
5. Card rendered **"Minor-data redaction reviewed"** / `Redaction approved: Yes`. Tapped
   **"Start export or transfer"**, entered `operationMode`, submitted.
6. Card rendered **"Export generation in progress"** / `Mode: Export`. Tapped **"Record export ready"**.
7. Card rendered **"Export ready"** with `Completed 2026-09-20T01:23:38.755635Z` and all four history
   entries, each showing `fan-soccer-owner-1`.

## Half 2 — independently confirmed in Postgres, same session

A **control read was taken before the first write**: `select count(*) … where workflow_type='soccer-export-metadata'`
returned **0**, while the same query grouped over all types returned real counts for eight other
workflows — so the query worked and the zero was a real absence, not a broken predicate.

| | |
|---|---|
| instance_id | `community_riverside_youth_soccer_soccer-export-metadata_dmf8is40534u` |
| community_id | `community_riverside_youth_soccer` |
| workflow_type | `soccer-export-metadata` |
| created_by_fan_id | **`fan-soccer-owner-1`** — the fan that authenticated |
| current_state | **`completed`** (was `draft` at creation) |
| created_at | 1789867244163 → `2026-09-20 01:20:44.163Z` |
| updated_at | **1789867418755 → `2026-09-20 01:23:38.755Z` — no longer equal to `created_at`** |

### Each transition, with the tap→write gap

Each row's evidence is the stored `exportHistory` entry, which carries the actor and the engine's own
timestamp. The taps were wall-clocked on the host immediately before `adb shell input tap`.

| # | Transition (button) | To state | Tap (UTC) | Stored effect timestamp | Gap |
|---|---|---|---|---|---|
| 1 | *create* ("New redacted export" → Create) | `draft` | 01:20:43.973 | `created_at` 01:20:44.163 | 190 ms |
| 2 | `select-export-scope` ("Select export scope") | `scope-selected` | 01:22:04.555 | `2026-09-20T01:22:04.692627Z` | 138 ms |
| 3 | `review-redaction-preview` ("Confirm redaction preview") | `redaction-reviewed` | 01:22:32.641 | `2026-09-20T01:22:32.847698Z` | 207 ms |
| 4 | `start-export` ("Start export or transfer") | `generating` | 01:23:15.465 | `2026-09-20T01:23:16.416471Z` | 951 ms |
| 5 | `record-export-ready` ("Record export ready") | `completed` | 01:23:38.472 | `2026-09-20T01:23:38.755635Z` | 284 ms |

Each state was read back from Postgres on the first poll after the tap, so the chain
*tap → UI re-render → persisted row → actor-stamped history entry* is complete for all five. No state
claim in this manifest comes from a screenshot alone.

### Stored `instance_data` at `completed`

```json
{
  "exportTitle": "B25LiveExport0919",
  "exportScope": ["rosters", "schedules"],
  "redactedFields": ["minorDOB", "minorPhone"],
  "redactionConfirmed": true,
  "operationMode": "export",
  "startedAt": "2026-09-20T01:23:16.416471Z",
  "completedAt": "2026-09-20T01:23:38.755635Z",
  "transferId": "f614a840-7c06-4229-a689-d1d41b2018b0",
  "exportReceiptId": "577cbb34-aab6-4303-b211-47fa764bafaa",
  "exportHistory": [
    { "event": "Owner selected export scope",                   "byFanId": "fan-soccer-owner-1", "at": "2026-09-20T01:22:04.692627Z" },
    { "event": "Owner confirmed minor-data redaction preview",  "byFanId": "fan-soccer-owner-1", "at": "2026-09-20T01:22:32.847698Z" },
    { "event": "Owner started portability operation",           "mode": "export", "byFanId": "fan-soccer-owner-1", "at": "2026-09-20T01:23:16.416471Z" },
    { "event": "Owner recorded redacted export as ready",       "byFanId": "fan-soccer-owner-1", "at": "2026-09-20T01:23:38.755635Z" }
  ]
}
```

### Every typed value settled against the stored row, not the screen

`adb shell input text` truncates silently, and this workflow has no pickers — all three inputs are
free text. Each was therefore compared byte-for-byte against `instance_data`:

| Typed | Stored | Verdict |
|---|---|---|
| `B25LiveExport0919` | `"exportTitle": "B25LiveExport0919"` (len 17) | exact |
| `rosters,schedules` | `["rosters", "schedules"]` | exact, parsed to a real 2-element list |
| `minorDOB,minorPhone` | `["minorDOB", "minorPhone"]` | exact, parsed to a real 2-element list |
| `export` | `"operationMode": "export"` | exact |

The card's *display* renders the title as "B25 Live Export0919" — that is label formatting inserting
spaces at case boundaries, not a stored value. The stored string is unspaced and exact, which is
precisely why this check reads the row rather than the tile.

### `$actor` resolved to a real fan id, not an aliased role id

Both `created_by_fan_id` and all four `byFanId` values are `fan-soccer-owner-1`. On the local
engine the app shell aliases `fanId` to `roleId`, which would have produced `soccer-owner` here.
It did not, which is independent corroboration that this ran against the remote engine with a
genuine authenticated identity.

## Control — the write was targeted

Exactly **one** `soccer-export-metadata` row exists after the run (the one created here), and the
other three Riverside Youth Soccer rows were untouched — `soccer-guardian-join-approval`,
`soccer-registration-payment` and `soccer-waiver-document` all still read
`updated_at = 2026-09-08`. So the five state changes are attributable to the five specific buttons
pressed, not to a sweep or a re-render.

## Guards proven by what the UI *withheld*

The addendum row expects "export disabled without scope/redaction preview". That negative was
observed live rather than reasoned about:

- At `draft`, the only actions rendered were **Select export scope** and **Cancel export**.
  No "Start export" — `start-export` is `from: ["redaction-reviewed"]`.
- At `scope-selected` with `redactionConfirmed: false`, the actions were **Change scope**,
  **Confirm redaction preview** and **Cancel export**. Still no "Start export".
- Only after `redactionConfirmed` became `true` did **Start export or transfer** appear, and its
  guard also requires `size(exportScope) > 0`, which the two-element scope satisfied.

## Where this stopped, and why

**Stopped at `completed`**, the workflow's success outcome. `completed` is deliberately *not*
`isTerminal` (the product doc records that flag being removed in the 2026-08-10 judge pass, because
`rollback-export` legitimately leaves it), so two transitions remain available from here and neither
was fired:

- **`rollback-export` ("Roll back export")** — owner-guarded, rendered and tappable. Not fired: it is
  a destructive branch *off* the success terminal, not progress past it, and firing it would move the
  banked row off `completed`. This is a deliberate stop, not a blocked one.
- **`record-export-download` ("Download export")** — **correctly withheld by its own guard**, and
  this is the finding worth recording. Its guard is
  `formula: "if(downloadUrl == null, false, true)"`, and `downloadUrl` is declared
  `writableBy: "platform"` with **no writer anywhere** — no effect sets it, and unlike `checksum`
  it does not even name a `platformSource`. At `completed` the card rendered **only** "Roll back
  export", so the button was absent rather than present-and-failing.

  This is the honest shape, not a defect in the package: the button is withheld because the export
  artifact does not exist, and the missing piece is the platform export/checksum service. `checksum`
  (`platformSource: "checksum"`) is likewise absent from `instance_data`, correctly, rather than
  being filled with a fabricated value. It belongs with the four missing platform services already
  tracked (payment, id generation, external search/AI, checksum), not with per-package authoring
  gaps. **The addendum row lists "download export" among this persona's interactions, so that
  interaction remains unprovable until that service exists** — it is not reachable by any account,
  role or sequence today.

  Note by contrast that the two `platformSource: "opaqueId"` fields **did** mint real values on this
  run (`transferId`, `exportReceiptId` — both genuine UUIDs), so opaque-id minting is live on the
  deployed engine while checksum/download generation is not.

## A UX observation, recorded because it is a real defect in the shipped app

**The creation dialog's only input is invisible while it is being typed into.** When the soft
keyboard opens over "New redacted export", the dialog collapses to its title and its
Cancel/Create buttons; the required **Export Title** field is pushed entirely off-screen with no
scroll, so the user cannot see what they are entering. The value does land correctly (settled above),
so this is presentation, not data loss — but on a field that is `required` and free-text it means
typing blind. The *transition* dialogs on the same card ("Select export scope", "Start export or
transfer") do **not** have this problem: they resize and keep their fields visible with the keyboard
up. So the defect is specific to the generic creation card, not to this community.

## What is not claimed

- Screenshots were taken at every step (28 frames) but `*.png` is gitignored, so they are transient;
  this manifest, not the images, is the durable artifact.
- The judge half of the bar for this row is covered by the pre-existing
  `llm-vision-ux-review-*.json` artifacts that key `"workflowId": "soccer-export-metadata"`. This
  manifest supplies the walkthrough half only, and makes no claim about that judge verdict's content.
