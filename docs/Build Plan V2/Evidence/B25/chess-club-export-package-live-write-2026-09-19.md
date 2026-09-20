**Workflow:** `chess-export-package` in Chess Club
**Outcome:** Both halves of the proof standard were met — signed in as `loom-chess-owner-1` through a real, empty Keycloak form after clearing BOTH Chrome and the app, created the instance through the Admin tab's "New export" FAB, and drove `ready → generated → rolled-back → ready → generated → rolled-back → cancelled` (terminal), firing five of the workflow's six declared transitions and confirming every state and every `instance_data` mutation directly in Postgres in the same session.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Package identity:** `Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc`
- `skillVersion`: `3.3.0`, `specVersion`: `4`
- `sha256`: `92547b0c0be7292771748ab9c11083ffc5b759d494c5da522290e921b392a609`
- Verified byte-identical across three copies: the app-shell asset, the locked
  `docs/references/communities/` copy (`cmp` clean), and **the copy bundled in the installed APK** —
  extracted from the device's own `base.apk` at
  `assets/flutter_assets/packages/loom_communities_app_shell/assets/…` and hashed to the same
  sha256. This hash therefore describes the package actually driven, not merely the one in the
  working tree.

**Date:** 2026-09-19 (local, PDT). All timestamps below are **UTC**, so they read as `2026-09-20T03:xx`.
**Device:** `emulator-5554`, reached from this VM through the pre-established ssh reverse tunnel
(`adb devices` → `emulator-5554 device`; no `adb kill-server`/`start-server` was run).

**Judge half:** `phase-b15-ux-judge-ev36-2026-09-19.md`, which records
*"Chess Club — chess-export-package, owner: **pass-with-findings**"* and names the workflow in its
machine-readable `**Workflow:** \`chess-export-package\`` line. It is a pass-with-findings, not a
clean pass; its three findings (washed-out state chip, raw `{action: …, actorFanId: …}` history
syntax rendered to members, and the unexplained "This is an off-path export state" string) are all
reproduced in this run's frames and remain open.

---

## Who holds this workflow, read from the package before driving anything

Every one of the six transitions — `change-export-scope`, `generate-export`, `download-export`,
`rollback-export`, `reopen-export`, `cancel-export` — is guarded `allowedRoleIds: ["chess-owner"]`,
and the create action is `byRoleIds: ["chess-owner"]` on the `admin` tab, which itself declares
`visibleRoleIds: ["chess-organizer", "chess-owner"]`. So the whole graph is walkable by one role and
needs no second party. I signed in as the owner because the package says so, not because the row is
owner-shaped.

Capability confirmed at every layer before touching the device, each read independently:

| Layer | State |
|---|---|
| Package | create FAB + 6 transitions, all `chess-owner` |
| Published definition | `community_chess_club_chess-export-package`, version 4 |
| App Access role | `chess-owner` exists in `loom_communities_chess-club`, `role_kind = package_domain` |
| Permissions | all 7 `export_wizard.*` ids granted to `chess-owner` (`create`, `run`, `download`, `rollback`, `retry`, `configure_scope`, `cancel`) |
| Role holder | `fan-chess-owner-1`, membership `active` |
| Fan passport | `fan-chess-owner-1` present |
| Keycloak | `loom-chess-owner-1` → HTTP 200, token claim `fanId = fan-chess-owner-1` |

## Control read, taken before the first write

    select instance_id, current_state, created_by_fan_id, created_at, updated_at
      from workflow_instances where workflow_type='chess-export-package';
    -> (0 rows)

    select workflow_type, count(*) from workflow_instances
      where workflow_type like 'chess-%' group by workflow_type;
    -> chess-club-night 1, chess-match-result 1

The control proves the query works against this table and this prefix, so the empty result for
`chess-export-package` is a real negative: **no live row of this type existed**. The row below is
therefore unambiguously new, and is identified by instance id regardless.

## Identity, and how the stale-SSO trap was closed

`pm clear com.example.loom_communities_demo` **and** `pm clear com.android.chrome`, then
`POST_NOTIFICATIONS` pre-granted so no permission dialog could steal focus.

Proof the clear worked rather than an SSO cookie silently re-issuing a previous fan: Chrome came up
at its **first-run** screen, and the Keycloak page rendered a **real, empty "Sign in to your
account" form** with blank username and password fields — not a green "You're signed in". Username
was typed and read back on screen in full (`loom-chess-owner-1`, no truncation); the password field
showed exactly 12 masked characters for a 12-character password.

The app's own telemetry confirms the remote path, before and after:

    LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/
                 scope=ext_chess_club outcome=failure error=authentication_required   (before sign-in)
    LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/
                 scope=ext_chess_club outcome=ok status=200                            (after selecting the account)

In-app confirmation: the community header read **"Signed in as Chess Owner 1 / Owner"**, and the
account selected in the picker was `ID: fan-chess-owner-1` — the same identity whose token was
issued, which is what the shell's anti-impersonation check compares.

## The stored row

    instance_id        community_chess_club_chess-export-package_5tnhgc1gng7q
    community_id       community_chess_club
    workflow_type      chess-export-package
    created_by_fan_id  fan-chess-owner-1
    current_state      cancelled          (terminal)
    created_at         1789875884614      = 2026-09-20T03:44:44.614Z
    updated_at         1789876322596      = 2026-09-20T03:52:02.596Z

`updated_at` is 7m 18s after `created_at`, so this is a walked instance and not a bare insert.

## Every step, settled against Postgres rather than against the screen

Each row below was read from `workflow_instances` in this same session immediately after the tap.
"tap→write" is the interval between the `adb input tap` and the timestamp the engine stored.

| # | Transition | State before → after | Stored `updated_at` | tap→write |
|---|---|---|---|---|
| 1 | create (FAB "New export") | — → `ready` | `03:44:44.614Z` | 343 ms |
| 2 | `generate-export` | `ready` → `generated` | `03:45:40.597Z` | 249 ms |
| 3 | `download-export` | `generated` → *(no write)* | **unchanged** | — **see finding** |
| 4 | `rollback-export` | `generated` → `rolled-back` | `03:48:26.549Z` | 113 ms |
| 5 | `change-export-scope` | `rolled-back` → `rolled-back` (`to: null`) | `03:49:26.382Z` | 363 ms |
| 6 | `reopen-export` | `rolled-back` → `ready` | `03:50:20.350Z` | 463 ms |
| 7 | `generate-export` (2nd) | `ready` → `generated` | `03:51:04.592Z` | 551 ms |
| 8 | `rollback-export` (2nd) | `generated` → `rolled-back` | `03:51:42.022Z` | 697 ms |
| 9 | `cancel-export` | `rolled-back` → **`cancelled`** (terminal) | `03:52:02.596Z` | 274 ms |

Steps 7 and 8 repeat already-proven transitions; they exist because step 6 returned the instance to
`ready`, and because step 7 was a deliberate second observation of the export-bundle path (below).

### Typed values settled against the stored row, not the screen

Both form fields were typed with `adb shell input text`, which truncates silently, so each was
settled against `instance_data`:

- `exportLabel` typed `B25-live-owner-export` → stored **`"B25-live-owner-export"`** (21 chars, intact).
- `exportScope` typed `matches,rankings` → stored **`["matches","rankings"]`** (parsed to a 2-element
  list; the card rendered "2 data groups").
- Step 5 retyped `matches,rankings,pairings` → stored **`["matches","rankings","pairings"]`**, and
  the card moved to "3 data groups". This is the only field a transition takes as input, and it was
  changed and re-read specifically so the `inputs` path is proven rather than assumed.

### Final `instance_data`

    {
      "ownerFanId": "fan-chess-owner-1",
      "statusMessage": "Export cancelled",
      "exportLabel": "B25-live-owner-export",
      "exportScope": ["matches", "rankings", "pairings"],
      "generatedAt": "2026-09-20T03:51:04.592325Z",
      "rolledBackAt": "2026-09-20T03:51:42.022030Z",
      "exportHistory": [
        {"action": "generated",     "actorFanId": "fan-chess-owner-1", "at": "2026-09-20T03:45:40.597413Z"},
        {"action": "rolled-back",   "actorFanId": "fan-chess-owner-1", "at": "2026-09-20T03:48:26.549348Z"},
        {"action": "scope-changed", "actorFanId": "fan-chess-owner-1", "at": "2026-09-20T03:49:26.382249Z"},
        {"action": "reopened",      "actorFanId": "fan-chess-owner-1", "at": "2026-09-20T03:50:20.350870Z"},
        {"action": "generated",     "actorFanId": "fan-chess-owner-1", "at": "2026-09-20T03:51:04.592325Z"},
        {"action": "rolled-back",   "actorFanId": "fan-chess-owner-1", "at": "2026-09-20T03:51:42.022030Z"},
        {"action": "cancelled",     "actorFanId": "fan-chess-owner-1", "at": "2026-09-20T03:52:02.596312Z"}
      ]
    }

Every one of the seven `exportHistory` entries carries `actorFanId: fan-chess-owner-1` — the
authenticated fan, written by the engine's `$actor` substitution, not by anything the device typed.
`ownerFanId` likewise came from the create action's `prefill: {"ownerFanId": "$actor"}`.

The state machine's own bookkeeping is visible and correct: `change-export-scope` reset
`statusMessage` to "Ready to generate" **without changing state** (it declares `to: null`), and the
affordance sets were state-correct throughout — `Change scope`/`Generate export`/`Cancel export` in
`ready`, `Download export`/`Rollback` in `generated`, `Change scope`/`Generate again`/`Cancel export`
in `rolled-back`, and **no actions at all** on the terminal `cancelled` card, which rendered through
the `summary` binding as the package declares.

---

## Finding: `download-export` cannot be reached through the UI, and the tap never reaches the engine

**What happened.** In `generated`, the card offers **"Download export"**. Tapping it at
`03:46:01.353Z` produced **no write of any kind**: `updated_at` stayed at `03:45:40.597Z`, no
`downloadedAt` appeared, and no `downloaded` entry was appended to `exportHistory`. The card instead
rendered, in place, the message:

> **Export download is unavailable until this app session generates a bundle.**

**What is established, and what is not.** The message is an explicit, loud product refusal — not a
silent failure — so this is not the "a tap that returned is not a transition that happened" trap: the
tap reached the card's handler and the handler declined. What is **not** established is why the
bundle was missing. I did not trace the generate path at runtime and I am not naming a culprit.

**Three independent observations that bound the problem:**

1. **Firing `generate-export` produced no bundle, twice, and reported no error.** After both
   generations (`03:45:40` and `03:51:04`), `select count(*) from workflow_export_bundles` returned
   **0** — and 0 is the whole-table count, so the table works and is simply empty. No `checksum` key
   ever appeared in `instance_data`, and the card showed no error on either generation.
2. **The server-side export-bundle surface is live on this cluster.** Probed directly with a fresh
   `loom-chess-owner-1` token:

        GET /v1/communities/community_chess_club/export-bundles/does-not-exist
          -> 404 {"code":"export_bundle_not_found"}          <- route EXISTS
        GET /v1/communities/community_chess_club/not-a-real-route/x
          -> 404 {"code":"route_not_found"}                  <- control: a missing route looks different

   (An earlier probe returned `401 authentication_required`; that was an expired token, and re-minting
   produced the 404 above. The discrimination between the two 404 codes is what makes this a route
   existence check rather than a guess.)
3. **The state chain is unaffected.** `download-export` declares `to: null`, so it is an
   effects-only action, not a state transition. Its absence does not block any state: the graph was
   walked end to end to the terminal `cancelled` without it.

**Why this is worth a row of its own.** `docs/Build Plan V2/Build Tracker.md` §9 item 4a records the
export checksum service as *built and integrated* (2026-08-27), and observation 2 confirms its routes
are deployed today. The `Access Control and Workflow Service Tracker.md:893` note that
`workflow_export_bundles` is **empty** is still true as of this run. So the gap is not "the service
was never built" — it is that in a live, remote-wired app driven by a correctly-permissioned owner,
generation never produced a bundle and nothing reported that it hadn't. `checksum` is declared
`writableBy: "platform"`, `platformSource: "checksum"`, `hideWhenEmpty: true`, so an absent checksum
renders as nothing at all; the only visible symptom is a download button that refuses when pressed.

**What a follow-up should establish, in this order:** whether the app invoked
`POST /v1/communities/{id}/instances/{id}/export-bundle` at all during `generate-export` (device-side
HTTP telemetry — `LOOM_BINDING` covers `workflow-engine` only and says nothing about the export
client), and if it did, what the service returned. Both are cheap and neither was available to me
from this session.

## Judge findings reproduced in this run

All three of the B15 judge's findings were visible on the live remote path, not only in the judged
local-engine frames:

1. The `rolled-back` state chip rendered pale amber on a light background — the least legible element
   on a screen whose whole job is to say what state the export is in.
2. The History block rendered raw developer syntax to the member, verbatim:
   `{action: generated, actorFanId: fan-chess-owner-1, at: 2026-09-20T03:45:40.597413Z}`.
3. **"This is an off-path export state"** appeared above the card in `rolled-back` — system
   vocabulary that says something is unusual without saying what to do about it. Note the card
   simultaneously showed `statusMessage: "Ready to generate"` after step 5, which is the actionable
   sentence; the two sit adjacent and disagree in tone.

## Where I stopped, and why

At the terminal state `cancelled`, which is as far as the package allows: it is the only state
declaring `isTerminal: true`, and it has no outgoing transitions. Nothing was escalated — every
action was fired as `fan-chess-owner-1`, the package's own declared domain role, and the generated
governance role `chess-club-admin` was never used or substituted for it.

Five of six declared transitions fired live and are proven by stored rows. The sixth,
`download-export`, is the finding above: it is declared, it is permitted (`export_wizard.download` is
granted to `chess-owner`), its button renders — and the app refuses it before the engine is ever
asked.
