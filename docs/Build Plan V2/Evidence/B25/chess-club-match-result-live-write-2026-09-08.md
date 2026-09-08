# Chess Club — `chess-match-result` live write and dispute, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles = UTC-7; engine stamps are UTC, so
`09:48:16Z`, `09:50:35Z` and `09:51:16Z` are 02:48, 02:50 and 02:51 local)
**Device:** `emulator-5554`, Android 16 (SDK 36), `sdk_gphone64_x86_64`, 1080x2400
**adb path:** the emulator is **Windows-hosted**; this session ran **on the Loom VM itself**
(`fahd-VirtualBox`), which has no AVD. It was reached by talking to the **Windows host's adb
server** — `adb -H 192.168.56.1 -P 5037`. The VM-local adb server saw zero devices.
**App:** `com.example.loom_communities_demo/.MainActivity`, APK installed 2026-09-08 00:17:13
**Workflow:** `chess-match-result` in Chess Club (`community_chess_club`)
**Supersedes:** the reopened Chess Club dispute claim, which had no corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and the UI evidence and the Postgres
row are reported together and **agree**.

- Signed in for real as `loom-chess-member-1` through the in-app OAuth flow against Keycloak.
- Created a `chess-match-result` **from nothing** through the real UI ("Record match" on the Matches
  tab speed-dial), reaching `draft`.
- Drove `submit-result` through the real UI, reaching **`submitted`**.
- Drove `dispute-result` — the destructive transition this row was reopened for — reaching
  **`disputed`**.
- Read the row back from Postgres with `kubectl exec … psql` after each step.

**No role escalation was needed.** `chess-member` is sufficient for the create action and for both
the `submit-result` and `dispute-result` transitions. I signed in as, and acted as, exactly one
identity throughout.

## Baseline — confirmed, not stale

The ticket's control was *"`workflow_instances` held **7** rows total, and **zero** of
`workflow_type = 'chess-match-result'`."*

**That was exactly correct** at this session's first database read (02:29 local, before any device
interaction):

```
 count
-------
     7

      workflow_type       |        community_id         | count
--------------------------+-----------------------------+-------
 critique-submission      | community_camera_club       |     1
 hoa-dues-payment         | community_cedar_commons_hoa |     2
 hoa-facility-reservation | community_cedar_commons_hoa |     3
 hoa-owner-notification   | community_cedar_commons_hoa |     1
```

Zero `chess-match-result` rows. The single row below is therefore necessarily this session's, and
the total moved 7 → 8.

## Identity

Seeded Keycloak account on the documented convention, **authenticated for real** against realm
`loom` at `192.168.56.10:30082` via the in-app OAuth flow (Chrome custom tab) — not selected from a
list. Password `LoomTest123!` was accepted. No credential was created or reset.

| Display name | fan id | Keycloak username | Role (label) | Role id |
|---|---|---|---|---|
| Chess Member 1 | `fan-chess-member-1` | `loom-chess-member-1` | Player | `chess-member` |

Independent control before driving the UI — a direct password grant against `loom-test-client`
returned HTTP 200, and the decoded access token carried `preferred_username=loom-chess-member-1`
and **`fanId=fan-chess-member-1`**. That token was used only to read the claim; the app performed
its own browser login.

App Access state was also read directly, as ground truth rather than inference:

```
          group_id           |        fan_id         | state  |     role_id
-----------------------------+-----------------------+--------+------------------
 loom_communities_chess-club | fan-chess-member-1    | active | chess-member
```

## The path driven

1. **Community list → Chess Club.** Entry gate appeared (`community-entry-gate`).
2. **Keycloak logout first.** Opened `…/realms/loom/protocol/openid-connect/logout` in the browser.
   Keycloak answered *"Do you want to log out?"* — proving a live SSO session from the prior Camera
   Club dispatch existed. Confirmed logout.
3. **Gate refresh → "Continue to secure sign-in".** See Finding 1.
4. **Real Keycloak form.** Username and password typed; username read back off the device as
   exactly `loom-chess-member-1` (19 chars, no truncation) before submitting.
5. **Account selection.** Tapped "Chess Member 1 / ID: fan-chess-member-1"; app entered the
   community showing *"Signed in as Chess Member 1 — Player"*.
6. **Matches tab → `+` speed-dial → "Record match".** Filled the seven required fields.
   `participantFanIds` is a **checkbox list**, not a text field, so the `adb shell input text`
   truncation trap could not apply to the identifier; "Player" and "Organizer" were ticked.
7. **Create** → `draft`.
8. **"Submit score"** → `submitted`.
9. **"Dispute result"** (red, destructive) → `disputed`.

Final UI state offers **"Resolve dispute"**, which is the correct and only transition out of
`disputed`.

## The database row

Read with `kubectl exec -i -n loom postgres-0 -- env PGPASSWORD=… psql -U loom -d
loom_workflow_service`, in this same session, after each step.

| Field | Value |
|---|---|
| `instance_id` | `community_chess_club_chess-match-result_8mmrvshrps22` |
| `community_id` | `community_chess_club` |
| `workflow_type` | `chess-match-result` |
| `created_by_fan_id` | **`fan-chess-member-1`** |
| `current_state` | `draft` → `submitted` → **`disputed`** |
| `created_at` | `1788860896472` = 2026-09-08 09:48:16.472 UTC |
| `updated_at` | `1788861076372` = 2026-09-08 09:51:16.372 UTC |

State after each observed step, read separately:

| Step | UI state chip | `current_state` in Postgres |
|---|---|---|
| Create | Draft result | `draft` |
| Submit score | Result submitted | `submitted` |
| Dispute result | Result disputed | `disputed` |

`created_by_fan_id` is `fan-chess-member-1`, which **matches the identity I authenticated as and
drove**. Stored `instance_data`:

```json
{
 "statusMessage": "Result disputed",
 "participantFanIds": ["chess-member", "chess-organizer", "fan-chess-member-1"],
 "resultHistory": [
  {"action": "score-submitted", "actorFanId": "fan-chess-member-1",
   "at": "2026-09-08T09:50:35.175328Z", "score": "1-0", "outcome": "white-win"},
  {"action": "disputed", "actorFanId": "fan-chess-member-1",
   "at": "2026-09-08T09:51:16.372407Z"}
 ],
 "submittedAt": "2026-09-08T09:50:35.175328Z",
 "resultTitle": "Ladder round 5 result",
 "playerOneName": "Chess Member 1",
 "playerTwoName": "Chess Organizer 1",
 "roundLabel": "Ladder round 5",
 "score": "1-0",
 "outcome": "white-win"
}
```

**Do the two agree?** Yes, to the microsecond. The on-screen result-history card rendered
`Action: disputed / Actor Fan Id: fan-chess-member-1 / At: 2026-09-08T09:51:16.372407Z`, and the
row's `updated_at` is `1788861076372` — the same instant. Both `resultHistory` actors are
`fan-chess-member-1`.

## Findings

### Finding 1 — the entry gate can deadlock: it lists accounts but offers no way to log in

**This is the defect that cost the most time here, and it is a real product finding.**

`LoomAuthScreen` (`part31_auth_screens.dart`) renders the "Continue to secure sign-in" button —
the *only* route to `LoomProductionLoginScreen` from outside a community — **exclusively inside its
`_error != null` branch** (line ~163). The account list and that button are mutually exclusive.

Meanwhile `signIn()` and `listAccounts()` in `RemoteLoomAuthApi` both begin with
`_fanIdFromCurrentSession()`. So when a stored access token is still readable but the session is
otherwise unusable, `listAccounts` succeeds, the account list renders, the login button is hidden —
and every account tap fails with:

> Sign-in failed: LoomAuthNotLoggedInException: No Loom authentication session is stored; login is
> required.

The gate then sits there indefinitely: it says *"Choose an active account or create one to continue
to Chess Club"*, the accounts are listed and tappable, and none of them can be signed into. Four
taps produced no visible change at all before the snackbar was caught with a zero-delay screenshot.

**The escape is non-obvious:** press "Check membership status", which rebuilds the auth screen via
`_entryGateRevision`; `listAccounts` then throws, and *only then* does "Continue to secure sign-in"
appear. A user with no knowledge of the internals has no reason to press a *membership* button to
fix a *login* problem.

Worth stating plainly: a first-run user whose `listAccounts` happens to succeed has **no login
affordance at all** on this screen.

### Finding 2 — `BACKEND UNREACHABLE` was displayed while the backend was fully reachable

On entering the community the AppBar showed a red **BACKEND UNREACHABLE** badge. It was wrong:
in that same state the app created a workflow instance that landed in Postgres. After the
successful create the badge **disappeared on its own** and the AppBar reverted to "Chess Club".

This corroborates the existing mislabel ticket (`6ca8dfce`) with a second community and adds a
detail: the badge is not merely cosmetic-on-load, it **clears on the first successful write**,
which suggests it reflects "no successful request yet this session" rather than reachability.

### Finding 3 — app-access returns HTTP 500 for unknown routes, not 404

`GET /api/v1/communities/{id}/members` and `GET /api/v1/groups` both returned:

```json
{"code":"internal_error","message":"Unexpected server error","correlationId":"…"}
```

The service log shows the real cause is
`NoResourceFoundException: No static resource api/v1/groups.` — an ordinary 404 surfaced as a 500
through `GlobalApiExceptionAdvice`. This is a genuine finding in its own right, and it is also a
trap: a wrong path is indistinguishable from a broken service at the client. I very nearly reported
app-access as broken on this evidence. The service was healthy throughout.

### Finding 4 — `ESC` (keyevent 111) dismisses the whole create dialog, losing all input

Used to dismiss the soft keyboard, `keyevent 111` closed the "Record match" dialog and discarded six
filled fields. `keyevent 4` (back) behaves the same way. What works is tapping the keyboard's own
hide-chevron, or `keyevent 61` (TAB) to advance focus, which also auto-scrolls the dialog to the
next field. Noted for future walkthroughs rather than as a product defect.

### Finding 5 — `participantFanIds` mixes role ids and fan ids

The stored array is `["chess-member", "chess-organizer", "fan-chess-member-1"]`. The two checkbox
selections contributed **role ids** (`chess-member`, `chess-organizer`) while the signed-in actor
contributed a **fan id** (`fan-chess-member-1`). The field is declared `fanId[]`.

It did not block anything — the `actorInList` guard matched on `fan-chess-member-1` and both
transitions fired — but two identifier spaces are being written into one `fanId[]` field, which is
exactly the class of confusion that identifier-space discipline exists to prevent. Anything that
later resolves these as fan ids will find two of the three unresolvable. Flagged, not fixed; no
application code or community JSON was touched.

## What I did not do

- **No test suites were run.** This ticket is a live-device walkthrough plus a database read; it
  changed no code, so the five suites have no bearing on its claim and no baseline is quoted.
- No application code, community JSON, or tracker was modified. No credential was created or reset.
- `integration_test/on_device_remote_backend_proof_test.dart` was **not** used.
- The instance was deliberately left in `disputed`. "Resolve dispute" was not driven — `disputed`
  is the state this row was reopened to prove, and resolving it would have moved the evidence off
  the target state.
