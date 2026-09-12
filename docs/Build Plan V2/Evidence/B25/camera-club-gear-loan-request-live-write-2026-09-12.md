**Workflow:** `gear-loan-request` in Camera Club
**Outcome:** Both halves of the proof standard were met — signed in as `loom-camera-organizer-1` through the real Keycloak form, created a gear listing through the Gear tab's "List gear" FAB, drove the complete loan lifecycle (request → approve → pickup → return → relist) and then the owner-guarded `delist` into the terminal `delisted` state, confirming every step in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Package identity:** `Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc`
- `skillVersion`: `3.3.0`
- `sha256`: `199913fcc8d76fcb345d889d09631fce09efd6cd0bced6b9cf0d2b5c8fa254f9`
- Verified byte-identical to the copy **bundled in the installed APK**: extracted from the device's
  own `base.apk` at `assets/flutter_assets/packages/loom_communities_app_shell/assets/…` and hashed
  to the same sha256. The installed APK was further confirmed byte-identical to the local build by
  md5 (`3dbe8d714a37a5c8b8762a92af805e42`, device and host agreeing), so this hash describes the
  package actually driven, not merely the one in the working tree.

---

## Why this run exists

The prior claim of a live write for this row was reopened as untrusted because no matching row
existed in the database. That was **correct**: at the start of this run `workflow_instances` held
**29 rows and zero of `workflow_type = 'gear-loan-request'`**. This run does not look for that
instance — it creates a new one.

The brief's baseline hint ("about 29 rows, few or none of `gear-loan-request`") was **accurate this
time**, measured independently before touching anything. Recorded because the same hint has been
stale twice before.

## Identity

- **Authenticated as:** Keycloak `loom-camera-organizer-1`
- **Fan id:** `fan-camera-organizer-1`
- **Role:** `camera-club-organizer`

Verified independently before driving the UI: a password-grant token request against
`loom-test-client` returned HTTP 200, and the decoded access token carried
`preferred_username: loom-camera-organizer-1` and `fanId: fan-camera-organizer-1`.

No escalation was needed. `gear-loan-request`'s create action is declared
`byRoleIds: ["camera-club-member", "camera-club-organizer"]`, and every transition driven below is
guarded either on one of those roles or on `ownerFanId` — which the create action's
`prefill: {ownerFanId: "$actor"}` set to this fan.

### The stale-SSO trap fired, and was defeated rather than worked around

The app initially held a stored OAuth session for a **different** fan (left by an earlier Garden Club
run). Tapping "Camera Organizer 1" produced the anti-impersonation refusal, quoted verbatim from the
device:

> Sign-in failed: LoomAuthException(accountNotFound): The authenticated Loom identity cannot sign in
> as account "fan-camera-organizer-1". Sign in with that person's identity provider session instead.

That guard is the only reason this evidence is attributable. Clearing Chrome alone was **not**
sufficient — the account list still loaded from the stored session, and "Check membership status"
succeeded, so the error branch carrying "Continue to secure sign-in" never appeared. Clearing the
app's own data as well emptied the session, at which point `listAccounts` failed with
`LoomAuthNotLoggedInException`, the sign-in button appeared, and the **real Keycloak form** rendered
at `192.168.56.10:30082`. Chrome's first-run onboarding intercepted the redirect exactly as
documented and was dismissed with "Use without an account".

Clearing app data was confirmed safe *before* doing it, not after: the launch screen reports "Loaded
10 example communities", so the preload flag is compiled into this APK and the packages re-seed on
next launch. (Grepping the APK's `kernel_blob.bin` for `LOOM_PRELOAD_EXAMPLE_COMMUNITIES` proves
nothing — the constant name is present whether or not the define was passed.)

Both credential fields were revealed on screen and read back before submitting, because
`adb shell input text` truncates silently: `loom-camera-organizer-1` and `LoomTest123!` were both
intact.

## The path driven

Gear tab (the package's `marketplace` tab) → **"List gear"** FAB → form (Title, Description,
Condition, Mode) → Create. Then the instance card → detail sheet → one transition at a time.

Every step below was confirmed in Postgres immediately after firing it, not inferred from the screen.

| # | Transition fired | Guard it had to satisfy | `availabilityState` after | Confirmed in DB |
|---|---|---|---|---|
| 0 | *create* ("List gear") | `byRoleIds` member/organizer | `available` | yes |
| 1 | `request-loan` | roles + `listingMode == 'loan' && availabilityState == 'available'` | `requested` | yes |
| 2 | `approve-loan` | `actorEqualsField: ownerFanId` + `availabilityState == 'requested'` | `reserved` | yes |
| 3 | `mark-picked-up` | roles + `availabilityState == 'reserved'` | `onLoan` | yes |
| 4 | `return-gear` | roles + `availabilityState == 'onLoan' \|\| 'overdue'` | `returned` | yes |
| 5 | `relist-returned` | `actorEqualsField: ownerFanId` + `availabilityState == 'returned'` | `available` | yes |
| 6 | `delist` | `actorEqualsField: ownerFanId` + `availabilityState == 'available'` | — → **`current_state: delisted`** | yes |

`delisted` is declared `isTerminal: true`. Steps 1–5 all declare `"to": null`, so they correctly
preserve `current_state: published` while advancing the `availabilityState` sub-machine and running
archetype bookkeeping; step 6 is the first to move the workflow state itself.

`approve-loan` opened a second form for its effect fields (`Pickup By`, `Due Date`) rather than
firing immediately. That is the transition working as declared, not a failure — `2026-09-20` and
`2026-09-27` were entered and both stored exactly.

## Final UI state

The detail sheet for the delisted instance renders **no action buttons at all** — only "Close" —
which is correct for a terminal state whose only `delisted` render binding is
`bindingKind: summary`. Throughout the run the rendered affordances matched the declared guards
exactly: `Join queue` appeared only once the item left `available`, `Delist`/`Pause listing`
disappeared whenever `availabilityState` was not `available`, and `claim-giveaway` never appeared
(this listing is `listingMode: loan`).

No ANR and no crash: `dumpsys window lastanr` reports `<no ANR has occurred since boot>`, logcat
shows no `FATAL EXCEPTION` or `E AndroidRuntime`, and the app process was still alive at the end.

## The database row

    instance_id       community_camera_club_gear-loan-request_iw61o31vjzdz
    community_id      community_camera_club
    workflow_type     gear-loan-request
    created_by_fan_id fan-camera-organizer-1
    current_state     delisted
    created_at        1789222608467   (2026-09-12T14:16:48.467Z)
    updated_at        1789223087224   (2026-09-12T14:24:47.224Z)

`workflow_instances` went from **29 rows to 30**, and `gear-loan-request` from **0 rows to 1**.

**This row is mine, established by instance id and timestamp rather than by the count moving.**
`created_at` is `1789222608467`; the Create tap was bracketed by host clock readings of
`1789222608362` and `1789222618664`, so the row was written **105 ms** after the tap, inside a
10.3-second window. The count is corroboration, not the proof.

### Do the two halves agree?

**Yes, on every field.** `created_by_fan_id` is `fan-camera-organizer-1` — the identity
authenticated at the Keycloak form and the one named in the token's `fanId` claim. The terminal
`current_state: delisted` is the state the UI was driven to and the state the UI reflected by
withdrawing every action.

Stored `instance_data`, read back rather than trusted from the screen:

```json
{
 "availabilityState": "available",
 "borrowerClaimHistory": [
  { "approvedAt": "2026-09-12T14:20:59.187248Z",
    "borrowerFanId": "fan-camera-organizer-1",
    "mode": "loan" }
 ],
 "condition": "good",
 "custodyHistory": [
  { "event": "picked-up", "recordedAt": "2026-09-12T14:22:01.562515Z",
    "recordedByFanId": "fan-camera-organizer-1" },
  { "event": "returned",  "recordedAt": "2026-09-12T14:22:44.365683Z",
    "recordedByFanId": "fan-camera-organizer-1" }
 ],
 "description": "Prime lens available for club loan",
 "dueDate": null,
 "issueLog": [],
 "listingMode": "loan",
 "ownerFanId": "fan-camera-organizer-1",
 "pickupBy": null,
 "requesterFanId": null,
 "title": "B25 Canon 50mm Lens"
}
```

Every typed value survived intact — `title`, `description`, `condition` and `listingMode` all match
what was entered, so `adb shell input text` did not truncate on this run. The two `custodyHistory`
entries and the `borrowerClaimHistory` entry are **platform-written**, carrying server-side
microsecond timestamps and this fan's id: they are independent evidence that the transitions were
executed by the engine rather than simulated in the UI.

`pickupBy`, `dueDate` and `requesterFanId` are `null` at rest because `return-gear` and
`relist-returned` clear them. They were populated mid-run and verified then (step 2 read back
`pickupBy = 2026-09-20`, `dueDate = 2026-09-27`; step 1 read back
`requesterFanId = fan-camera-organizer-1`). A reader checking only the final row should not read
these nulls as fields that never got written.

### `ownerFanId` holds a real fan id, not a role id

Worth recording because this package's creation path is one where it could have gone wrong:
`prefill: {"ownerFanId": "$actor"}` resolved to **`fan-camera-organizer-1`**, the authenticated fan,
not to the role-id-shaped string `camera-club-organizer`. `ownerFanId` is a scalar `fanId` written by
prefill rather than a `fanId[]` filled by the audience picker, so the known identifier-space seam on
that picker was not exercised here and this field is clean.

## Observations — neither is a blocker, and neither is claimed as a package defect

**1. The marketplace list tile repainted stale once.** Immediately after `delist`, the tile still
read `Status: Requested` — two sub-states behind the database, which said `available`/`delisted`.
Switching tabs away and back corrected it to `Status: Available`. Transient and self-correcting; the
detail sheet was accurate throughout, and the database was authoritative at every check.

**2. A delisted listing's tile does not say it is delisted.** The tile's status chip renders
`availabilityState` (via that field's `labelTemplate: "Status: {value}"`), which `delist` does not
clear — so a terminally delisted item reads `Status: Available`. This is *faithful to the package*:
`availabilityState` genuinely is `available`, and the workflow state lives in `current_state`. It is
recorded as a product observation about which of the two states the tile surfaces, not as an
authoring error, and it needs a product decision rather than a JSON edit.

**A near-miss worth recording, since it would have been a false finding.** `Delist` is rendered
*below the fold* of the detail sheet. On first inspection only `Request loan`, `Report damage` and
`Pause listing` were visible, and the owner-guarded `Delist` looked absent even though its guard was
satisfied. Scrolling the sheet revealed it. Reporting a missing affordance from that first
un-scrolled view would have been wrong.

## Scope

No application code, community JSON, or tracker was modified. No credential was created or reset.
This manifest is the only file added.
