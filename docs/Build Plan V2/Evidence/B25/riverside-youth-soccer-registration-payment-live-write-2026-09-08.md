# Riverside Youth Soccer — `soccer-registration-payment` live write, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles = UTC-7; engine stamps are UTC, so
`11:38:44.046479Z` is 04:38 local)
**Device:** `emulator-5554`, Android 16 (SDK 36), `sdk_gphone64_x86_64`, 1080x2400
**adb path:** the emulator is **Windows-hosted**; this session ran **on the Loom VM itself**
(`192.168.56.10`), which has no AVD. It was reached by talking to the **Windows host's adb server** —
`adb -H 192.168.56.1 -P 5037`. The VM-local adb server saw zero devices.
**App:** `com.example.loom_communities_demo/.MainActivity`, APK installed 2026-09-08 00:17:13
**Workflow:** `soccer-registration-payment` in Riverside Youth Soccer
(`community_riverside_youth_soccer`, `ext_youth_soccer`)
**Supersedes:** the reopened Riverside Youth Soccer claim, which had no corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and the UI evidence and the Postgres
row are reported together and **agree**.

- Signed in for real as `loom-soccer-guardian-1` through the in-app OAuth flow against Keycloak.
- Created a `soccer-registration-payment` **from nothing** through the real UI, reaching `unpaid`.
- Drove `confirm-payment-authorization` through the real UI (`consentConfirmed` → `true`).
- Drove `start-checkout` through the real UI, reaching **`processing`**.
- Read the row back from Postgres with `kubectl exec … psql` after each step.

`processing` is the furthest state the **guardian** can reach. The one transition that leaves it
toward `paid` is guarded `allowedRoleIds: ["soccer-coach"]`, so I escalated — see the escalation and
the finding it produced below.

## Baseline — confirmed, not stale

The ticket's control was *"`workflow_instances` held **9** rows total, and **zero** of
`workflow_type = 'soccer-registration-payment'`."*

**That was exactly correct** at this session's first database read (03:47 local, before any device
interaction):

```
 total
-------
     9

      workflow_type       | count
--------------------------+-------
 hoa-facility-reservation |     3
 hoa-dues-payment         |     2
 chess-match-result       |     1
 mosque-donation-payment  |     1
 hoa-owner-notification   |     1
 critique-submission      |     1
```

Zero `soccer-registration-payment` rows. The rows below are therefore necessarily this session's.
The total moved 9 → 12, because one guardian action legitimately creates three instances (see
"How this workflow is actually created").

## Identity

Seeded Keycloak accounts on the documented convention, **authenticated for real** against realm
`loom` at `192.168.56.10:30082` via the in-app OAuth flow (Chrome custom tab) — not selected from a
list. Password `LoomTest123!` was accepted for both. No credential was created or reset.

| Display name | fan id | Keycloak username | Role (label) | Role id |
| --- | --- | --- | --- | --- |
| Soccer Guardian 1 | `fan-soccer-guardian-1` | `loom-soccer-guardian-1` | Guardian (Guardian) | `soccer-guardian` |
| Soccer Coach 1 | `fan-soccer-coach-1` | `loom-soccer-coach-1` | Coach (Coach) | `soccer-coach` |

**The stale-SSO trap fired for real and was defeated, not assumed absent.** The app opened holding
the *previous* dispatch's session (`fan-masjid-member-1`). Selecting Soccer Guardian 1 was refused
outright by the app's anti-impersonation guard:

```
Sign-in failed: LoomAuthException(accountNotFound): The authenticated Loom identity cannot sign in
as account "fan-soccer-guardian-1". Sign in with that person's identity provider session instead.
```

That is the guard working. `pm clear com.android.chrome` and
`pm clear com.example.loom_communities_demo` were then run; the app reported
`LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required` — a clean
slate — and Keycloak presented a **real, empty login form**, not a silent re-issue.

Before the coach escalation the same discipline was repeated: Keycloak's `/logout` endpoint was
driven in the browser (it presented *"Do you want to log out?"*, confirming a live SSO session
existed, then *"You are logged out"*), and the app's stored session was cleared. The coach login
again showed a **real, empty form**.

**Every typed credential value was read back off the device before submitting**, guarding against the
`adb shell input text` truncation trap. This was not theoretical — **the trap fired twice**: typing
`loom-soccer-guardian-1` in one call landed as `loom-soccer` (11 of 22 characters), and a retry landed
as `loom-soccer-`. Both were caught by reading the field back, and the value was completed in small
chunks until the field showed `loom-soccer-guardian-1` in full. Passwords were revealed with the eye
toggle and read as `LoomTest123!` in full.

## How this workflow is actually created — there is no standalone create form

`soccer-registration-payment` has **no create action of its own**. It is created as a
`createInstance` effect of `soccer-guardian-join-approval`'s `submit-request` transition:

```json
{ "op": "createInstance", "workflowType": "soccer-registration-payment",
  "fields": { "registrationCaseId": "{id}", "guardianFanId": "{guardianFanId}",
              "playerLabel": "{playerLabel}", "amountLabel": "{registrationFeeLabel}",
              "purpose": "Riverside season registration", "consentConfirmed": false, ... } }
```

This is why the Payments tab shows no create FAB — correctly, not as a defect. The real create path
is the **"Register a player"** FAB on Home, and that one guardian action fans out into three
instances (`soccer-guardian-join-approval`, `soccer-registration-payment`, `soccer-waiver-document`),
which is why the row total moved by 3.

`guardianFanId` was **not typed** — it is `writableBy: platform`, resolved server-side to the
authenticated actor. The card rendered *"Guardian: Fan Soccer Guardian 1"* and the stored value is
`fan-soccer-guardian-1`.

## The path driven, through the real UI

1. Community list → **Riverside Youth Soccer**.
2. Identity gate → **Continue to secure sign-in** → Chrome custom tab → Keycloak form → **Sign In**.
3. Identity picker → **Soccer Guardian 1**. The shell opened with *"Signed in as Soccer Guardian 1 /
   Guardian"*.
4. **Home** tab → **"Register a player"** FAB → filled the seven `formEntry` fields → **Create** →
   join-approval in `draft`.
5. Scrolled the card → **"Send registration request"** (`submit-request`) → join-approval `submitted`,
   and the payment instance came into existence in `unpaid`.
6. **Payments** tab → the payment card rendered → **"Confirm payment authorization"**
   (`confirm-payment-authorization`) → `consentConfirmed: true`, state stays `unpaid` by design
   (`"to": null`).
7. **"Pay registration"** (`start-checkout`) → **`processing`**.

### Values entered, each read back off the device before submitting

| Field | Schema key | Value |
| --- | --- | --- |
| Case Title | `caseTitle` | `Reg-2026-Ella` |
| Player | `playerLabel` | `Ella-R` |
| Request | `requestDetails` | `Season-registration-request` |
| Fee | `registrationFeeLabel` | `USD-120` |
| Waiver Title | `waiverTitle` | `Season-Waiver-2026` |
| Waiver Version | `waiverVersion` | `v1.0` |
| Waiver Url | `waiverUrl` | `https://example.org/waiver.pdf` |

Hyphenated values were chosen deliberately: `adb shell input text` passes the string through a device
shell, so a literal `$` would have been expanded to nothing. `USD-120` is an honest label, not a
placeholder standing in for a value that failed to type.

### The `instanceDataEquals` guard was observed working, not assumed

Before `confirm-payment-authorization`, the payment card offered **only** that one action.
**"Pay registration" was absent** — correctly, because `start-checkout` is guarded
`instanceDataEquals: { key: "consentConfirmed", value: true }`. It appeared only after consent was
confirmed. That is the guard evaluating live against server state, visible in the UI.

## The database row — read back with an independent query

```
                                instance_id                                |           community_id           |        workflow_type        |   created_by_fan_id   | current_state |     created_utc
---------------------------------------------------------------------------+----------------------------------+-----------------------------+-----------------------+---------------+---------------------
 community_riverside_youth_soccer_soccer-registration-payment_831tpmuqct6u | community_riverside_youth_soccer | soccer-registration-payment | fan-soccer-guardian-1 | processing    | 2026-09-08 11:38:44
```

`created_at = 1788867524049`, `updated_at = 1788867678643`.

All three instances created by the one guardian action, all attributed to the same fan:

```
                                 instance_id                                 |         workflow_type         |   created_by_fan_id   | current_state |     created_utc
-----------------------------------------------------------------------------+-------------------------------+-----------------------+---------------+---------------------
 community_riverside_youth_soccer_soccer-guardian-join-approval_qh3begb23hjv | soccer-guardian-join-approval | fan-soccer-guardian-1 | submitted     | 2026-09-08 11:37:35
 community_riverside_youth_soccer_soccer-registration-payment_831tpmuqct6u   | soccer-registration-payment   | fan-soccer-guardian-1 | processing    | 2026-09-08 11:38:44
 community_riverside_youth_soccer_soccer-waiver-document_waq8c9ywhdbq        | soccer-waiver-document        | fan-soccer-guardian-1 | unread        | 2026-09-08 11:38:44
```

`instance_data` after both transitions:

```json
{
    "purpose": "Riverside season registration",
    "amountLabel": "USD-120",
    "playerLabel": "Ella-R",
    "guardianFanId": "fan-soccer-guardian-1",
    "receiptStatus": "not-issued",
    "paymentHistory": [
        { "at": "2026-09-08T11:40:11.454253Z", "event": "Guardian confirmed payment authorization", "byFanId": "fan-soccer-guardian-1" },
        { "at": "2026-09-08T11:41:18.643766Z", "event": "Guardian started checkout",                "byFanId": "fan-soccer-guardian-1" }
    ],
    "consentConfirmed": true,
    "paymentMethodNote": "Checkout requested",
    "registrationCaseId": "community_riverside_youth_soccer_soccer-guardian-join-approval_qh3begb23hjv",
    "consentRequiredLabel": "Guardian payment authorization required"
}
```

Every declared effect of both transitions fired: `consentConfirmed` set to `true`,
`paymentMethodNote` set to `"Checkout requested"`, and `paymentHistory` appended twice with `$actor`
and `$timestamp`. `registrationCaseId` correctly carries the join-approval's instance id, so the
`createInstance` field templating resolved.

## Do the two halves agree?

**Yes, on every field that both sides express.**

| Claim | UI showed | Postgres held | Agree |
| --- | --- | --- | --- |
| State | chip *"Checkout started"* | `current_state = processing` | yes |
| Player | `Player: Ella R` | `playerLabel = "Ella-R"` | yes |
| Fee | `Fee: USD 120` | `amountLabel = "USD-120"` | yes |
| Purpose | `For: Riverside season registration` | `purpose = "Riverside season registration"` | yes |
| Consent | `Payment authorization: Yes` | `consentConfirmed = true` | yes |
| Receipt | `Receipt: Not Issued` | `receiptStatus = "not-issued"` | yes |
| Actor | both history entries *"By Fan Id: fan-soccer-guardian-1"* | `created_by_fan_id = fan-soccer-guardian-1` | yes |
| Timestamps | *"At: …11:40:11.454253Z"*, *"…11:41:18.643766Z"* | `paymentHistory[0].at`, `[1].at` | yes |

*"Checkout started"* is the package's own `states.processing.label`. The action set reduced
correctly on entering `processing`: **"Confirm payment authorization" and "Pay registration"
disappeared**, leaving **"Record payment failure"** and **"Cancel checkout"** — exactly the
transitions whose `from` includes `processing` and whose guard a guardian satisfies.
`record-offline-payment` was correctly **not** offered to the guardian.

## Escalation — performed, and named

`processing` → `paid` is only reachable through `record-offline-payment`, guarded
`allowedRoleIds: ["soccer-coach"]`. The ticket permits escalation provided the account is named, so I
escalated to the seeded **`loom-soccer-coach-1` / `fan-soccer-coach-1`** (role `soccer-coach`). I did
**not** substitute the generated `riverside-youth-soccer-admin` role.

The escalation authenticated cleanly — the shell opened with *"Signed in as Soccer Coach 1 / Coach"*,
and the tab bar changed to the coach's role-tuned set. **But the transition could not be reached.**

## FINDING — `record-offline-payment` is guarded to `soccer-coach`, and no coach-visible surface renders the instance

**`soccer-registration-payment` cannot advance past `processing` through the UI by anyone.** The
transition that must move it is coach-only, and the coach has nowhere to see the instance.

The payment declares exactly two render bindings:

```json
"renderBindings": [
  { "states": ["unpaid","processing","failed","paid","refunded"], "tabId": "giving", "bindingKind": "primary" },
  { "states": ["paid","refunded"],                                 "tabId": "home",   "bindingKind": "summary"  }
]
```

and the `giving` tab is guardian-only:

```json
{ "tabId": "giving", "label": "Payments", "pinnedWorkflowIds": ["soccer-registration-payment"],
  "visibleRoleIds": ["soccer-guardian"] }
```

So for a coach, in `processing`: the `giving` binding is behind a tab they cannot see, and the `home`
binding does not apply because its `states` list covers only `paid` and `refunded` — the two states
that can only be reached *by way of* the transition being blocked. The binding that would show the
result is gated on the outcome it is needed to produce.

### Verified on the device, with controls — not concluded from config alone

Config was read *after* the device disagreement was established, not instead of it. As
`fan-soccer-coach-1`:

- The coach's tab bar is **Home, Schedule, Coach & Owner, Team, Documents, Messages**. There is no
  Payments tab. The bar was scrolled to both ends to confirm nothing was clipped.
- **Home** (which pins `soccer-registration-payment`) was scrolled to its end: it renders only the
  `soccer-guardian-join-approval` card, with **"Review request"**. No payment card.
- **Coach & Owner** was scrolled to its end: same join-approval card, same single action. No payment
  card.

The control that makes the absence meaningful: the *same* instance rendered a full card with live
actions on the guardian's Payments tab minutes earlier, and the coach's own surfaces render a
*different* instance of a *different* workflow correctly. The query works; the absence is real.

### What that costs, concretely

Three of the nine transitions in `soccer-registration-payment` are unreachable, and they include
every path out of `processing` that is not a failure or a cancellation:

| Transition | from → to | Guard | Consequence |
| --- | --- | --- | --- |
| `record-offline-payment` | `unpaid`/`processing`/`failed` → `paid` | `soccer-coach` | **A registration fee can never be marked paid.** No receipt is ever issued; `receiptStatus` stays `not-issued` forever. |
| `refund-payment` | `paid` → `refunded` | `soccer-coach` | Unreachable transitively — nothing can reach `paid`. |
| `mark-payment-failed` | `processing` → `failed` | `soccer-guardian`, `soccer-coach` | Reachable by the guardian only; the coach half of the guard has no surface. |

Downstream, `view-receipt` (`from: ["paid"]`) is also dead, and the join-approval's
`paymentCheckpoint` — which the coach's card displays as **"Payment: Unpaid"** — can never move,
because it is written by an effect on the payment's own coach-only transition. The coach's card
therefore shows a permanently stale checkpoint: it read *"Payment: Unpaid"* while the payment was in
fact `processing`.

This is the shape CLAUDE.md already names — *"a role-guarded transition whose guard comes from the
right obligation, but whose surface belongs to a different audience"*. The guard is arguably correct
(a coach should verify an offline payment); the **binding** is what is wrong. A coach-visible
binding — the `admin` tab, or widening the `home` summary's `states` — would close it. No
application-code change is implied; this is a package authoring gap, and the package is Skill-owned.

**This was not papered over.** No role was substituted, no assertion weakened, and the run stopped at
the real boundary rather than reporting a state it did not reach.

## Environment notes worth carrying

**Chrome ANR'd repeatedly during OAuth, and it was the device, not the backend.** Diagnosed rather
than assumed: the Chrome **browser process** showed `0.0%` CPU with `TIME+` frozen at `2:09` across
two samples sixteen seconds apart — the "hung, not slow" signature — while the emulator's own load
average was **11.94 on 4 CPUs** with 444 MB swapped. The Loom VM was fine at `1.76` on 8 cores, and
all six pods were `1/1 Running` throughout. The device reached both `8.8.8.8` and `192.168.56.10`.
`dumpsys window lastanr` gave the reason as `Input dispatching timed out … Waited 5002ms for
FocusEvent` — starvation, not a page or service fault.

Recovery was: reboot the emulator, wait for the post-boot storm to drain (load peaked ~40 and took
about six minutes to fall below 5 — it **climbed** for the first two minutes, so a single sample
would have read as a worsening failure), then force-stop the unused Google apps before starting the
flow. After that the OAuth form rendered and accepted input first time.

**Two Chrome first-run dialogs intercept the OAuth redirect, not one** — "Make Chrome your own"
*and* a later "Chrome notifications make things easier". Clearing them in a normal tab first is
cheaper than fighting them inside the custom tab.

**`input keyevent 111` (ESC) dismisses the whole create dialog, not the keyboard**, discarding
everything typed. The keyboard's own chevron is the safe way to restore the form's layout between
fields. `keyevent 61` (TAB) moves focus to the dialog's **buttons**, not the next field.

## What was not done

- No application code, community JSON, or tracker was modified. No credential was created or reset.
- `integration_test/on_device_remote_backend_proof_test.dart` was not used.
- No test suites were run; this ticket asked for a live walkthrough and a database read, and changed
  no code that any suite covers.
- `paid` was not reached, and is not claimed. The blocker is documented above.
