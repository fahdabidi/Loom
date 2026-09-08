# Cedar Commons HOA — `hoa-dues-payment` live write, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles; engine stamps are UTC — `08:14:12Z` and
`08:46:12Z` are 01:14 and 01:46 local)
**Device:** `emulator-5554`, Android 16, `sdk_gphone64_x86_64`, 1080x2400
**adb path:** the emulator is **Windows-hosted**; this VM has no AVD and no `qemu-system` process.
It was reached by talking to the **Windows host's adb server directly** —
`adb -H 192.168.56.1 -P 5037 -s emulator-5554 …`. See Finding 6: the VM-local adb server died
mid-run and the `-H/-P` form is what recovered it. No `kill-server`, no `connect`/`disconnect`.
**App:** `com.example.loom_communities_demo/.MainActivity`, APK built 2026-09-08 00:15, installed 00:17
**Workflow:** `hoa-dues-payment` in Cedar Commons HOA (`community_cedar_commons_hoa`)
**Supersedes:** `cedar-dues-live-write-2026-09-04.md`, whose claim was reopened for having no
corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and this time the UI evidence and the
Postgres row are reported together and agree.

- **Homeowner half** — signed in as `fan-hoa-member-1`, drove `start-checkout` ("Pay dues") through
  the real UI. Instance advanced `due → processing`.
- **Board half** — signed in as `fan-hoa-board-1`, **created a new dues charge from nothing** and
  drove it `due → paid` via `record-offline-payment`.

Every claim below is anchored to a Postgres row read back with `kubectl exec … psql` after the fact.

## Correction to the ticket's stated baseline

The ticket's control was *"`workflow_instances` held exactly 4 rows … **Zero** `hoa-dues-payment`.
Any `hoa-dues-payment` row afterwards is necessarily yours."*

**That was already stale when this session began.** The first query of the session (01:07:16 local)
found **5** rows, including one `hoa-dues-payment`:

| instance_id | state | created_by | created_at | = local |
|---|---|---|---|---|
| `…hoa-dues-payment_m5k32qsqumkb` | `due` | `fan-hoa-board-1` | 1788854279297 | 2026-09-08 **00:57:59** |

That is **9 minutes 17 seconds before this session's first database read**, and ~7 minutes before
this dispatch process started. **It is not mine and is not claimed as mine.** It is also not the
reopened 2026-09-04 claim — its timestamp is today and outside the Postgres outage window. The
immediately preceding dispatch (`b25-cedar-dues`, 00:19) cannot be its author either: its log is 15
bytes containing only `Execution error`. Its origin is therefore **not established by this session**;
recorded here so the next reader does not attribute it to this run.

Because creation is board-only (below), this pre-existing row is what made the Homeowner half
possible at all — a Homeowner has no way to create a dues charge to pay.

## Identities

Both are seeded Keycloak accounts on the documented convention, authenticated for real against
realm `loom` at `192.168.56.10:30082` via the in-app OAuth flow (Chrome custom tab), not selected
from a list. Password `LoomTest123!` was accepted for both.

| # | Display name | fan id | Keycloak username | Role (label) | Role id |
|---|---|---|---|---|---|
| 1 | Hoa Member 1 | `fan-hoa-member-1` | `loom-hoa-member-1` | Homeowner | `hoa-member` |
| 2 | Hoa Board 1 | `fan-hoa-board-1` | `loom-hoa-board-1` | Board | `hoa-board` |

## Half A — Homeowner drives `start-checkout`

| # | Step | Result |
|---|---|---|
| 1 | Community entry gate, tap **Hoa Board 1** | **Refused** — see Finding 1 |
| 2 | Tap **Hoa Member 1** | Signed in as Hoa Member 1 / Homeowner |
| 3 | **Giving** tab | One dues card: "Q4 2026 HOA dues", $250, `Receipt: Due` |
| 4 | Member actions offered | Pay dues · Change amount · Edit payment method · Subscribe to quarterly autopay — exactly the four `hoa-member` transitions valid from `due`. No create affordance. |
| 5 | Tap **Pay dues** (`start-checkout`) at epoch_ms **1788855252453** | State chip → **Checkout started** |

**Database, read back immediately:**

```
instance_id       | community_cedar_commons_hoa_hoa-dues-payment_m5k32qsqumkb
current_state     | processing          <- was 'due'
created_by_fan_id | fan-hoa-board-1     <- unchanged; row pre-existed this session
updated_at        | 1788855252763
instance_data.receiptStatus | "Awaiting payment service"
instance_data.history[0]    | {"event":"Checkout started",
                               "actorFanId":"fan-hoa-member-1",
                               "at":"2026-09-08T08:14:12.763940Z"}
```

**UI and database agree.** `updated_at` is **310 ms** after the logged tap — the write is
unambiguously this action. `history[0].actorFanId` is `fan-hoa-member-1`, which **matches the
identity driven**. Note `created_by_fan_id` remains `fan-hoa-board-1` because this was an *update*
to a row the Board had created; the actor of the transition is carried in `history`, not in
`created_by_fan_id`.

## Half B — Board creates a new charge and drives it to `paid`

Reaching the Board identity required a real identity-provider switch (Finding 1). Sequence:
Keycloak SSO logout → **"Sign in securely with Loom…"** → Keycloak form → `loom-hoa-board-1` →
**"Switch account"** → **Hoa Board 1**.

| # | Step | Result |
|---|---|---|
| 6 | Signed in as Hoa Board 1 | "Signed in as Hoa Board 1 / Board" |
| 7 | Giving tab, same Q4 card | Actions are now **Record offline payment** / **Record failure**; the four member actions are gone — role gating correct, live |
| 8 | Bottom nav scrolled right → **Admin** tab | Tab appears only for Board (`visibleRoleIds: ["hoa-board"]`) |
| 9 | Create **FAB** → 4 actions | New HOA export · Send owner notice · Add HOA document · **New dues charge** |
| 10 | **New dues charge**, all 9 required fields filled, **Create** at epoch_ms **1788856901753** | Instance created |
| 11 | **Record offline payment** with required note, submitted at epoch_ms **1788857170388** | State → **Paid** |

### Values submitted on the create form

Every field marked `required: true, writableBy: formEntry` filled honestly — no placeholder, no stub.

| Field | Value entered |
|---|---|
| Title | `Q1 2027 HOA dues` |
| $ (amount) | `275` |
| Due (date) | `2026-09-30` (date picker) |
| Deadline time | `17:00` (time picker) |
| Payer (`payerFanId`) | `fan-hoa-member-1` |
| Recipient | `Cedar Commons HOA` |
| Entitlement | `Common area access` |
| Visibility | `Board and payer` |
| Method | `Offline check` |

### Database after create

```
instance_id       | community_cedar_commons_hoa_hoa-dues-payment_cd93iaf2sfem
current_state     | due
created_by_fan_id | fan-hoa-board-1
created_at        | 1788856902889     <- 1136 ms after the logged Create tap
```

`instance_data` held exactly the nine values above, plus the declared `prefill`
(`autopayEnabled: false`, `receiptStatus: "Due"`, `history: []`).

### Database after `record-offline-payment`

```
instance_id       | community_cedar_commons_hoa_hoa-dues-payment_cd93iaf2sfem
current_state     | paid
updated_at        | 1788857172215     <- 1827 ms after the logged submit
instance_data.receiptStatus | "Offline payment recorded"
instance_data.paidAt        | "2026-09-08T08:46:12.215880Z"
instance_data.history[0]    | {"event":"Offline payment recorded",
                               "note":"Check 1082 received",
                               "actorFanId":"fan-hoa-board-1",
                               "at":"2026-09-08T08:46:12.215880Z"}
```

All three declared effects fired (`set receiptStatus`, `set paidAt`, `append history`), the note is
stored verbatim, and the actor is the Board fan id. The card rendered **Paid**,
`Receipt: Offline payment recorded`, `Paid 2026-09-08T08:46:12.215880Z`, with the full history entry
— **identical to the row**.

## Final database state

6 rows, all `community_cedar_commons_hoa`. Both `hoa-dues-payment` rows:

| instance_id | state | created_by | created_at (local) |
|---|---|---|---|
| `…_cd93iaf2sfem` | `paid` | `fan-hoa-board-1` | 2026-09-08 01:41:42 — **created by this run** |
| `…_m5k32qsqumkb` | `processing` | `fan-hoa-board-1` | 2026-09-08 00:57:59 — pre-existing; **advanced** by this run |

## Findings

1. **The account list cannot switch identity; only the identity provider can.** Tapping an account
   row calls `authApi.signIn(accountId:)`, which fails when the stored Keycloak identity is someone
   else. Tapping **Hoa Board 1** while authenticated as member-1 produced, in a SnackBar:
   *"Sign-in failed: LoomAuthException(accountNotFound): The authenticated Loom identity cannot sign
   in as account "fan-hoa-board-1". Sign in with that person's identity provider session instead."*
   Correct behaviour — but the message is on screen for ~4 s and **nothing else changes**, so at a
   5-second screenshot cadence the tap reads as a dead button. The real switch path is
   **"Sign in securely with Loom…"** / **"Switch account"**, which live *below the fold* in the
   "Account role and permissions" dialog and are invisible without scrolling **inside** the dialog.
   This is the same shape as the keypatterns entry logged today, *a walkthrough identity must be
   authenticated, not merely selected*.

2. **"BACKEND UNREACHABLE" is shown for an authentication failure, not an unreachable backend.**
   After the Keycloak SSO session was ended, the AppBar displayed a red **BACKEND UNREACHABLE**
   chip. The backend was entirely healthy throughout — all six pods `1/1 Running`, and
   `curl http://192.168.56.10:30082/realms/loom` returned **200** from this VM at that moment. The
   app's own log gave the true cause: `outcome=failure status=- error=LoomAuthNotLoggedInException`,
   repeating from 01:19:46. **A session-expiry state rendered as an infrastructure outage will send
   an investigator to `kubectl` instead of to the login screen.** Worth a distinct
   "signed out / session expired" state.

3. **Chrome ANRs on the Keycloak RP-initiated logout URL.** Opening
   `…/realms/loom/protocol/openid-connect/logout` (no `post_logout_redirect_uri`) rendered a blank
   page and then produced a system dialog **"Chrome isn't responding — Close app / Wait"**, caught
   via `adb` (Flutter-side text checks cannot see system dialogs). The logout itself *did* take
   effect — the next sign-in attempt presented the credential form instead of completing silently.

4. **The dues create control is on the Admin tab, not Giving — confirmed independently.** This
   reproduces Finding 1 of the 2026-09-04 manifest. It is declared on the `admin` renderBinding
   (`presentation: "fab"`, `byRoleIds: ["hoa-board"]`), so Giving correctly shows no create
   affordance in any role. **Control run:** the Calendar tab *did* render its declared create action
   ("Reserve a facility", `tabId: "calendar"`) for the same Board account, so the absence on Giving
   is a real declaration difference and not a failure to render. Not a defect.

5. **`uiautomator dump` is unreliable against this app — prefer screenshots.** It twice returned a
   *stale* tree (the previously-dismissed overflow menu) while the screenshot showed the current
   dialog, and it **omitted the create FAB entirely** from the Admin tab where the screenshot shows
   it plainly. Any conclusion of "the affordance is absent" drawn from the dump alone would have
   been wrong — as one nearly was here.

6. **The emulator is on Windows and the VM-local adb server is a single point of failure.** Mid-run
   the VM's adb server died; `adb devices` then reported an empty list and a bare `adb connect` to
   `192.168.56.1:5555` / `localhost:5555` was refused. The emulator was still alive the whole time.
   Recovery was to address the **Windows host's adb server** directly: `192.168.56.1:5037` was open,
   and `adb -H 192.168.56.1 -P 5037 -s emulator-5554 …` restored full control immediately. No OOM
   kill was logged. Worth knowing before concluding the device is gone.

7. **`adb shell input text` silently truncates.** `input text 'Q1 2027 HOA dues'` landed as
   `Q1 2027 HO`; `input text 'fan-hoa-member-1'` landed as `fan-hoa-memb`. Every field was
   re-verified by screenshot after entry and corrected by retyping in ≤6-character chunks. **On a
   `payerFanId` this would silently produce a valid-looking instance addressed to a fan id that does
   not exist.** Also note `%s` (the space escape) must not be split across two `input text` calls —
   it then lands literally, which produced `Check 1082%sreceived` once.

8. **UI quirk, cosmetic, no data impact — confirmed independently.** Reproduces Finding 3 of the
   2026-09-04 manifest: while the soft keyboard is up the create dialog collapses to the focused
   field plus the action row. Costs steps, not correctness; every value was verified after entry.

## Stability

- No crash and no ANR **from the app** at any point. The one ANR observed was **Chrome's**
  (Finding 3), not `loom_communities_demo`.
- `topResumedActivity` was `com.example.loom_communities_demo/.MainActivity` before and after both
  submits.
- Around the `record-offline-payment` submit the app's own log showed **25** `outcome=ok` service
  bindings and **zero** `outcome=failure` lines. Control: the non-zero `ok` count proves the filter
  was reading a populated buffer, not an empty one.
- Service-binding diagnostics as rendered in-app: `Workflow engine — Mode: remote, Endpoint:
  http://192.168.56.10:30083/, Last call: success (200)`. App Access likewise `Mode: remote`. The
  app was talking to the deployed backend, not a local engine.

## Scope note

No test suites were run: this is a live-device walkthrough that changed **no** application code, no
community `*.jsonc`, nothing under `docs/references/**`, and no tracker. No credential was created
or reset. **This manifest is the only file added.** Per this repo's evidence rule `*.png` is
gitignored and `.codex-logs/**` is ignored by `.gitignore:2 (.codex*)`, so the screenshots below are
transient; their SHA-256 digests are recorded here so the images can be matched if still present.

Screenshots and database dumps written to
`.codex-logs/live-verification/b25-cedar-dues-2/evidence/`:

```
50f12f4428cba393cc7dd1807569811155816376c63dd886e5d9a22bd52c3bc0  01-signed-in-homeowner.png
84f07dc53798f47f4bec7d55d64333c435b5b9a1fc86d6953e34f93bd1c3d2f2  02-giving-before-pay.png
8dd13df8d80d1e183d3222b8b3074e4ab8e07d561da6ef31fefe7605445f2adc  03-after-pay-dues-processing.png
01526567529c6f52a5d1447aed4edfdbe6b99e0d447424ee506b1504c65b3261  04-board-impersonation-refused.png
b9921d0fd72b9343935b948b8a7eb74c83723d4c7504cf755feea219f93e4360  06-remote-binding-diagnostics.png
80e0ab8f97f4899172caa213b1da3efc4cfbc6426ca1c476d23138575a261fe4  07-signed-in-board.png
a4c872f2fd19e8f92e2a1c27f150d4a38e00d3f1e8e76f41be24b3ca50730afd  08-new-dues-charge-form.png
f8c237eae85b1b15b7593368ad52c2dc9dbcd4459a2af63772818ef605ce5a12  09-new-instance-rendered.png
ccdf18610eb062fffad47c8f7d83642b8d3819ffea0a67c52463a6f8b6ed0dbb  10-new-instance-paid.png
d6f8d1390bbedbae6b297d21cf2a36844abc55f285d1d04fb32e7103e2cf689d  00-baseline-db.txt
aaf89cd1385095b0c6105d019dabf680837c5b376156ef257446c8a8fae65761  05-post-action-db.txt
0011e6a1ed71154dd0148f55d72dde97cb733b2ad08c39498f26bfda2ff9d22c  11-final-db.txt
```

## Device state left behind

The app is left **signed in as Hoa Board 1 (`fan-hoa-board-1`)**, because reaching the Board role
required replacing the stored member-1 identity-provider session. The next dispatch needing the
Homeowner must re-run "Sign in securely with Loom…" as `loom-hoa-member-1`. Both credentials are
unchanged and were verified working today.
