# Garden Club — `garden-tool-loan` live write, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles = UTC-7; engine stamps are UTC, so
`12:15:24.626Z` is 05:15 local)
**Device:** `emulator-5554`, Android 16 (SDK 36), `sdk_gphone64_x86_64`, 1080x2400
**adb path:** the emulator is **Windows-hosted**; this session ran **on the Loom VM itself**
(`192.168.56.10`), which has no AVD. It was reached by talking to the **Windows host's adb server** —
`adb -H 192.168.56.1 -P 5037`. The VM-local adb server saw zero devices.
**App:** `com.example.loom_communities_demo/.MainActivity`, APK installed 2026-09-08 00:17:13
**Workflow:** `garden-tool-loan` in Garden Club (`community_garden_club`, `ext_garden_club`)
**Supersedes:** the reopened Garden Club claim, which had no corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and the UI evidence and the Postgres
row are reported together and **agree**.

- Signed in for real as `loom-garden-member-1` through the in-app OAuth flow against Keycloak.
- Created a `garden-tool-loan` **from nothing** through the real UI, reaching `published`.
- Drove `delist` through the real UI, reaching the **terminal state `delisted`**.
- Read the row back from Postgres with `kubectl exec … psql` after each step.

No escalation was needed. `garden-member` — the exact role the ticket named — both creates the
listing and reaches its terminal state.

## Baseline — confirmed, not stale

The ticket's control was *"`workflow_instances` held **12** rows total, and **zero** of
`workflow_type = 'garden-tool-loan'`."*

**That was exactly correct** at this session's first database read, before any device interaction:

```
 total
-------
    12

 instance_id | community_id | workflow_type | created_by_fan_id | current_state | created_at
-------------+--------------+---------------+-------------------+---------------+------------
(0 rows)
```

Zero `garden-tool-loan` rows. The row below is therefore necessarily this session's. The total moved
**12 → 13** — exactly one new row. `delist` declares no `createInstance` effect, so reaching the
terminal state correctly added nothing further.

Final distribution:

```
 hoa-facility-reservation      |     3
 hoa-dues-payment              |     2
 soccer-registration-payment   |     1
 soccer-guardian-join-approval |     1
 chess-match-result            |     1
 mosque-donation-payment       |     1
 hoa-owner-notification        |     1
 soccer-waiver-document        |     1
 critique-submission           |     1
 garden-tool-loan              |     1      <- this session
```

## Identity

Seeded Keycloak account on the documented convention, **authenticated for real** against realm
`loom` at `192.168.56.10:30082` via the in-app OAuth flow (Chrome custom tab) — not selected from a
list. Password `LoomTest123!` was accepted. No credential was created or reset.

| Display name | fan id | Keycloak username | Role (label) | Role id |
| --- | --- | --- | --- | --- |
| Garden Member 1 | `fan-garden-member-1` | `loom-garden-member-1` | Member (Member) | `garden-member` |

The live App Access roster was read directly from `loom_app_access` before driving anything, and
matches the ticket:

```
          fan_id          | state  |       roles
--------------------------+--------+--------------------
 fan-garden-admin         | active | garden-club-admin
 fan-garden-coordinator-1 | active | garden-coordinator
 fan-garden-member-1      | active | garden-member
```

**The stale-SSO trap was defeated by evidence, not assumed absent.** The device opened still holding
the previous dispatch's Riverside Youth Soccer session. Rather than trust a green "signed in", the
app's data and Chrome's cookie jar were both cleared (`pm clear` on
`com.example.loom_communities_demo` **and** `com.android.chrome`). The community entry gate then
reported, in its own words:

> `LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required.`

That is a real negative control: the session was genuinely gone, not merely assumed gone. The
Keycloak form then **did** appear and **did** ask for credentials — no silent re-issue.

## Path driven

| Step | Surface | Result |
| --- | --- | --- |
| Open Garden Club | community list | entry gate → secure sign-in |
| Sign in | Keycloak form in Chrome custom tab | returned to app, identity picker populated |
| Select Garden Member 1 | identity picker | "Signed in as Garden Member 1 / Member" |
| Marketplace tab | tab bar | empty (correct — remote communities start empty) |
| Create FAB | `marketplace` tab | expanded to two actions |
| "List a tool to loan" | FAB action | create form |
| Create | form | **`published`** |
| "Delist" | listing detail | **`delisted`** (terminal) |

Tab gating was correct: as `garden-member` the tab bar showed Home / Calendar / Marketplace / Care
and **not** Documents or Organize, which the package restricts to `garden-coordinator`.

## The database row

Read independently, in this same session, with the ticket's own query.

After create:

```
                     instance_id                     |     community_id      |  workflow_type   |  created_by_fan_id  | current_state |  created_at
-----------------------------------------------------+-----------------------+------------------+---------------------+---------------+---------------
 community_garden_club_garden-tool-loan_apm56a7rijn4 | community_garden_club | garden-tool-loan | fan-garden-member-1 | published     | 1788869724626
```

After `delist`:

```
 current_state | created_at    | updated_at
---------------+---------------+---------------
 delisted      | 1788869724626 | 1788869978420
```

| Field | Value |
| --- | --- |
| `instance_id` | `community_garden_club_garden-tool-loan_apm56a7rijn4` |
| `community_id` | `community_garden_club` |
| `created_by_fan_id` | **`fan-garden-member-1`** |
| `current_state` | **`delisted`** (the workflow's only terminal state) |
| `created_at` | `1788869724626` = 2026-09-08T12:15:24.626Z |
| `updated_at` | `1788869978420` = 2026-09-08T12:19:38.420Z |

**Do the UI and the row agree? Yes, on every point checked.**
`created_by_fan_id` is `fan-garden-member-1`, which is the identity the sign-in was performed as and
the identity the UI displayed. The timestamps bracket the interactions exactly: Create was tapped at
12:15:23Z and the row is stamped 12:15:24.626Z; Delist was tapped at 12:19:38Z and the row is
stamped 12:19:38.420Z.

`instance_data` confirms all three of the create action's declared prefills fired:

```
ownerFanId        = 'fan-garden-member-1'      <- $actor
mode              = 'loan'
availabilityState = 'available'  -> None after delist   <- delist's declared effect
conditionState    = 'good'
title             = 'Cordless hedge trimmer'
coordinatorFanId  = 'fan-garden-coordinator-1'
```

The detail dialog independently rendered **"Owner: Fan Garden Member 1"**, matching `ownerFanId`.

## FINDING — the terminal state is unreachable once the item is on loan

The ticket asked whether this workflow's terminal states are actually reachable by a real account.
**For the path I drove, yes** — and I proved it live. But there is one state from which no account
can reach it.

`garden-tool-loan` has exactly one terminal state, `delisted`, reached by exactly two transitions,
both owner-guarded and both gated on `availabilityState`:

| Transition | Actor | Requires `availabilityState` |
| --- | --- | --- |
| `delist` | `ownerFanId` | `available` |
| `retire-lost-item` | `ownerFanId` | `lost` |

Enumerating every transition available at each `availabilityState` value gives:

| `availabilityState` | Who can change it | Escape exists? |
| --- | --- | --- |
| `available` | owner (`pause-listing`, `delist`), member (`request-loan`) | yes — terminal directly |
| `reserved` | owner (`decline-loan`), borrower (`cancel-loan`) | yes — owner has recourse |
| `paused` | owner (`resume-listing`) | yes |
| `lost` | owner (`retire-lost-item`) | yes — terminal directly |
| **`onLoan`** | **borrower only** (`return-item`, `report-lost`) | **no owner or coordinator recourse** |

From `onLoan`, every transition that changes `availabilityState` is guarded
`actorEqualsField: borrowerFanId`. The owner's only remaining action is `report-issue`, which writes
a note and changes no state. There is no coordinator override and no admin override — the generated
`garden-club-admin` role holds only the five `community.*` permissions and appears in no transition
guard in this workflow.

**Consequence:** if a borrower stops engaging while holding the item, the listing is permanently
stuck in `published` / `onLoan`. The owner cannot `delist` (needs `available`), cannot
`retire-lost-item` (needs `lost`), and cannot `pause-listing` (needs `available`). The terminal state
becomes unreachable by **any** account in the community, and the owner cannot withdraw their own
property from the marketplace.

This is the mirror image of the documented "owner-only delist strands an active borrower" pattern:
here an *absent borrower* strands the *owner*. It is invisible to a validator run, because every
individual guard is well-formed — the gap is only visible in the reachability graph.

The natural repair is an owner- or coordinator-guarded recovery transition out of `onLoan`
(a "mark not returned" / "reclaim item" leading to `lost` or `available`), so that the obligation can
be ended by someone who is still present. Recording it here rather than acting: package JSON is
Skill-authored and out of scope for this dispatch.

## FINDING — "Join queue" is offered to the owner on an available item, then silently withdrawn

On the freshly created listing, as the **owner**, the detail dialog offered a **"Join queue"**
button. Its declared guard denies it on two independent grounds:

```json
"guard": {
  "allowedRoleIds": ["garden-member"],
  "formula": "if(ownerFanId == $actor, false, availabilityState == 'reserved' || availabilityState == 'onLoan')"
}
```

The owner is the actor, so the formula returns `false`; and `availabilityState` was `available`, not
`reserved`/`onLoan`. The button should not have rendered.

Tapping it wrote nothing — `instance_data` after the tap contained no queue field and was otherwise
unchanged, so **the engine correctly enforced the guard**. But the UI gave no error: the queue
section simply relabelled itself from *"Queue length: 0 / You are not queued"* to
**"Queue unavailable."** and both queue buttons disappeared.

So this is a **UI-only defect, not a data-integrity one**: an affordance is offered that can never
succeed, and its failure is silent. Worth contrasting with `request-loan`, which carries the same
`if(ownerFanId == $actor, false, …)` shape and *was* correctly hidden from the owner — so the formula
is honoured for that transition and not for this one.

## Checked and found correct — not a defect

The delisted listing continues to render in the Marketplace tab after reaching the terminal state.
This was initially suspected to be a binding failure and **it is not**: `garden-tool-loan` declares
three render bindings, and the second is exactly this case.

```
renderBinding[0]: states=['published'] tabId=marketplace bindingKind=primary
renderBinding[1]: states=['delisted']  tabId=marketplace bindingKind=summary
renderBinding[2]: states=['published'] tabId=home        bindingKind=summary
```

The delisted card renders as a **summary** with no action buttons and an empty availability chip
(`availabilityState` is `null` by `delist`'s own effect), which is correct. Verified across a full
app restart and re-authentication, so it is a genuine server-backed render, not a stale client view.
The initial suspicion came from reading only the first binding in the file; the correction is
recorded here because the false finding was one step from being reported.

## Roster note — the loan cycle is only driveable in one direction today

`request-loan` is guarded `allowedRoleIds: ["garden-member"]` plus
`if(ownerFanId == $actor, false, true)`. The live roster holds exactly **one** `garden-member`
(`fan-garden-member-1`), and `fan-garden-coordinator-1` holds `garden-coordinator`, which that guard
does not admit. So a listing owned by the member cannot be borrowed by anyone at present, and the
`reserved` → `onLoan` → returned cycle can only be exercised on a **coordinator-owned** listing
(the create action admits both roles) requested by the member.

This is a **seeding limitation, not a package defect** — a real community would have many members.
It is recorded because it bounds what any future walkthrough of this workflow can reach with the
current accounts, and because it is why the `onLoan` dead-end above was established from the
transition graph rather than driven live.

## Environmental note — `adb shell input text` drops trailing text under load

Two distinct failures, both caught by reading values back, both mine and **not** product defects.

1. **Unquoted text splits on the first space.** `input text "Cordless hedge trimmer"` put
   **`Cordless`** in the field — the device shell received three arguments and `input` used one.
   Quoting for the *device* shell (`$ADB shell "input text 'Cordless hedge trimmer'"`) fixed it.
2. **Long strings lose their tail under load.** With the emulator at load 8–10, several prose fields
   stored short of what was typed — e.g. `toolDescription` typed as *"Battery hedge trimmer with
   charger and spare blade guard"* stored as *"Battery hedge trimmer with charger"*. Two fields
   (`conditionNote`, `returnInstructions`) survived intact, so it is load-dependent flakiness, not a
   fixed length cap.

The two load-bearing values were verified character-exact on screen before submitting and are exactly
right in the database: `title` = `Cordless hedge trimmer` and `coordinatorFanId` =
`fan-garden-coordinator-1`. The identifier did **not** truncate.

Worth carrying: **reading a value back off the screen is necessary but not sufficient.** A field that
scrolls horizontally shows its tail off-screen, and a short value is indistinguishable from a
scrolled one. Only the stored row settles it. That is how the prose truncation above went unnoticed
through an on-screen check and was caught only by reading `instance_data`.

## Device health

No app crash. `logcat -b crash` contains **zero** entries mentioning `loom_communities`, and
`FATAL EXCEPTION` count in the main log is **0**. Run with a control: the crash buffer is **not**
empty (154 lines), holding an unrelated `libbluetooth_jni.so` fault from before this session — so the
zero is a real negative rather than a query that silently matched nothing.

Chrome's first-run onboarding did intercept the OAuth redirect on the first attempt, as documented,
and was dismissed with "Use without an account". Device load peaked at 10.50 during Chrome's cold
start and drained afterwards; no ANR occurred (`dumpsys window lastanr`: no ANR since boot).

## What was not done

- **No second identity was driven.** The ticket permitted escalation to `loom-garden-coordinator-1`
  if the workflow required it. It did not: `garden-member` both creates the listing and reaches the
  terminal state. The `onLoan` finding is therefore established from the transition graph plus the
  live roster, not from a live borrower walkthrough — which, as noted above, the current roster
  cannot support on a member-owned listing.
- **No test suites were run.** This dispatch changed no application code, no community JSON and no
  tracker; it only drove the shipped build and read the database. The five suite baselines are
  therefore untouched and unmeasured by this session, and nothing here should be read as a claim
  about them.
