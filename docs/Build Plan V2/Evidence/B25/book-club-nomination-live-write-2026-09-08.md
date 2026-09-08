# B25 re-verification — Neighborhood Book Club, `book-nomination` — **BLOCKED**

**Date:** 2026-09-08
**Outcome:** **Not proven. No live write was performed.** The walkthrough is blocked at Keycloak
authentication for the one account that can perform it. No `book-nomination` row exists, and none
was created.

This is an honest negative result, not a partial success. Both halves of the dual-proof standard
are unmet, and the reason is a single broken credential — not a product defect in the workflow.

---

## Verdict up front

| Half of the proof standard | Result |
| --- | --- |
| Drive `book-nomination` live through the real UI | **Not reached** — could not authenticate as the only role permitted to create it |
| Confirm the row in Postgres | **0 rows**, confirmed with a control |
| Do the two agree? | **Yes** — nothing was driven, and nothing was written. No contradiction. |

---

## The blocker: `loom-book-member-1`'s password is not `LoomTest123!`

The seeded convention (`loom-<slug>` / `fan-<slug>` / `LoomTest123!`) **does not hold for this one
account.** It holds for every other account tested.

### Evidence 1 — API level

Direct Access Grant against realm `loom`, client `loom-test-client`, at `192.168.56.10:30082`:

    loom-book-member-1     -> HTTP 401  {"error":"invalid_grant","error_description":"Invalid user credentials"}

### Evidence 2 — device level, through the real UI

Signed out of Keycloak, cleared Chrome's cookie jar, drove the real in-app OAuth flow, and reached
the genuine Keycloak **"Sign in to your account"** form. Both fields were read back off the device
before submitting (guarding against the known `adb shell input text` truncation trap) and were
character-exact: `loom-book-member-1` / `LoomTest123!` — the password revealed via the eye toggle
and visually confirmed.

Keycloak's own response:

> **Invalid username or password.**

The device and the API agree.

### Evidence 3 — controls, which is what makes this a finding rather than a guess

Four accounts accepted `LoomTest123!` at the API on the first try:

| Account | Result |
| --- | --- |
| `loom-camera-member-1` | HTTP 200 |
| `loom-book-organizer-1` | HTTP 200 |
| `loom-book-admin` | HTTP 200 |
| `loom-chess-member-1` | HTTP 200 |

And a device-level control: **`loom-book-organizer-1` signed in successfully through the identical
form, the identical OAuth flow, with the identical password**, and reached the community as
*"Signed in as Book Organizer 1 — Organizer"*. The flow, the client, the realm and the password are
all fine. The defect is scoped to one account's credential.

### Evidence 4 — the credential was replaced on 2026-09-04, and it is the only one that was

Comparing Keycloak's user `createdTimestamp` against the password credential's `createdDate`:

| Account | User created | Credential created |
| --- | --- | --- |
| `loom-book-admin` | 2026-08-31 02:42:06 | 2026-08-31 02:42:06 |
| **`loom-book-member-1`** | **2026-08-31 02:45:58** | **2026-09-04 02:46:28** |
| `loom-book-organizer-1` | 2026-08-31 02:46:02 | 2026-08-31 02:46:02 |
| `loom-camera-club-admin` | 2026-08-31 02:41:37 | 2026-08-31 02:41:37 |
| `loom-camera-member-1` | 2026-08-31 02:44:40 | 2026-08-31 02:44:40 |
| `loom-camera-organizer-1` | 2026-08-31 02:44:49 | 2026-08-31 02:44:49 |
| `loom-chess-admin` | 2026-08-31 02:41:45 | 2026-08-31 02:41:45 |
| `loom-chess-member-1` | 2026-08-31 02:43:10 | 2026-08-31 02:43:10 |
| `loom-chess-organizer-1` | 2026-08-31 02:45:09 | 2026-08-31 02:45:09 |
| `loom-chess-owner-1` | 2026-08-31 02:45:14 | 2026-08-31 02:45:14 |

Every other account's credential was created in the same second as the account, during the
2026-08-31 seeding run. `loom-book-member-1`'s was replaced **four days later, on 2026-09-04
02:46:28 UTC**, to a value that is not the documented convention.

The account itself is otherwise healthy: `enabled: true`, `emailVerified: true`,
`requiredActions: []`, no federation link, and the `fanId` attribute is correctly
`fan-book-member-1`.

**No record of that reset exists anywhere in the repo.** `grep` for `book-member-1` across all
`*.md` returns nothing, and `reset-password` appears in no file. The change is undocumented and its
new value is unrecorded.

**No credential was created or reset by this dispatch**, per the ticket's explicit prohibition.

---

## Why no other account can substitute

This is the part that makes the block hard rather than merely inconvenient. `fan-book-member-1` is
the **sole holder** of the `book-member` role:

    loom_communities_neighborhood-book-club | fan-book-admin       | active | neighborhood-book-club-admin
    loom_communities_neighborhood-book-club | fan-book-member-1    | active | book-member
    loom_communities_neighborhood-book-club | fan-book-organizer-1 | active | book-organizer

And `book-member` gates **every** step of `book-nomination` in the shipped package:

| Step | Guard |
| --- | --- |
| Create action "Nominate a book" (FAB on `books` tab) | `byRoleIds: ["book-member"]` |
| `draft` state field editing | `editGuard.allowedRoleIds: ["book-member"]` |
| `submit-nomination` transition | `guard.allowedRoleIds: ["book-member"]` |

`book-organizer` holds exactly one transition on this workflow — `select-for-ballot`, which acts on
an *already submitted* nomination. It cannot create one.

**Confirmed on the device, not just read from the package.** Signed in as `loom-book-organizer-1`
and opened the `books` tab: the only create affordance rendered is a FAB labelled **"New ballot"**
(the `book-vote` create action). **"Nominate a book" is absent**, exactly as the package specifies.
The tab is otherwise empty, which is correct — remote communities start empty by the 2026-09-07
decision.

So escalating to another seeded account does not rescue this walkthrough. Reporting it as
"completed as organizer" would have been false.

---

## Database evidence

**Baseline, taken before any device work:**

    workflow_instances total: 8
    workflow_type='book-nomination': 0 rows

**Final, after the session:**

    workflow_instances total: 8      <- unchanged; this dispatch wrote nothing
    workflow_type='book-nomination': 0 rows

**Control** (proving the empty result is a real negative and not a broken query — the query shape
returns a hit when one exists):

    community_chess_club_chess-match-result_8mmrvshrps22 | chess-match-result | fan-chess-member-1 | disputed

Workflow types present in the table: `hoa-facility-reservation` (3), `hoa-dues-payment` (2),
`chess-match-result` (1), `hoa-owner-notification` (1), `critique-submission` (1). No book club rows.

---

## Secondary finding — the stale-SSO trap fired, and clearing app data alone did not fix it

Worth recording because the standard recovery was insufficient.

The device arrived holding a `fan-chess-member-1` session from the previous dispatch. Taps on
"Book Member 1" in the entry gate silently did nothing (the anti-impersonation guard rejecting a
mismatch between the selected account and the token's `fanId`).

1. Hitting Keycloak's logout endpoint in Chrome **did not clear the session** — the endpoint
   returned a blank page without terminating it.
2. `pm clear` on the app **was not enough either.** The app's stored session was wiped, the gate
   correctly reported `LoomAuthNotLoggedInException`, and the OAuth flow then completed **with no
   login form shown at all** — Keycloak's still-live SSO cookie in Chrome silently re-issued a token
   for the *old* fan. `FlutterSecureStorage.xml` was written, and the very next log line read:

   > `Loom community-membership fallback for fan "fan-chess-member-1", community "community_neighborhood_book_club"`

   A green "signed in" state, attributed to the wrong person.
3. **`pm clear com.android.chrome` was the step that actually worked.** Only after wiping Chrome's
   cookie jar did the genuine "Sign in to your account" form appear.

**Rule:** clearing the app's own storage does not clear the identity. The Keycloak SSO cookie lives
in the browser, and switching identity requires clearing *Chrome*, then confirming the real login
form appears before trusting the resulting session.

---

## Stack health — everything except the one credential is fine

Not a single service fault was observed. All four backend bindings answered `status=200` throughout,
for scope `ext_neighborhood_book_club`:

    LOOM_BINDING service=app-access      mode=remote endpoint=http://192.168.56.10:30080/ outcome=ok status=200
    LOOM_BINDING service=fan-passport    mode=remote endpoint=http://192.168.56.10:30081/ outcome=ok status=200
    LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/ outcome=ok status=200

All six pods `1/1 Running`. The community installs, themes, renders its tab bar, resolves all three
seeded accounts in the entry gate with correct fan ids and role labels, and signs a member in
through the real browser OAuth flow. No `403`, no `unknown_permission_id`, no ANR, no crash dialog.

---

## What would unblock this

One of:

1. Reset `loom-book-member-1`'s password back to `LoomTest123!` — a privileged action this dispatch
   is explicitly forbidden from taking, and which needs a human decision since it overwrites whatever
   was deliberately set on 2026-09-04.
2. Recover and record the value set on 2026-09-04, if it was set intentionally.
3. Grant `book-member` to a second account whose credential is intact.

Option 1 is the obvious fix but should be a deliberate choice, because the 2026-09-04 reset may have
been intentional and its rationale is unrecorded. That gap — a credential changed with no
accompanying note — is itself worth closing.

---

## Reproduction

    # API: the failing account and a passing control
    curl -s -o /dev/null -w "%{http_code}\n" -X POST \
      'http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token' \
      --data-urlencode 'client_id=loom-test-client' \
      --data-urlencode 'username=loom-book-member-1' \
      --data-urlencode 'password=LoomTest123!' \
      --data-urlencode 'grant_type=password'          # -> 401

    curl -s -o /dev/null -w "%{http_code}\n" -X POST \
      'http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token' \
      --data-urlencode 'client_id=loom-test-client' \
      --data-urlencode 'username=loom-book-organizer-1' \
      --data-urlencode 'password=LoomTest123!' \
      --data-urlencode 'grant_type=password'          # -> 200

    # DB: the negative result and its control
    PW=$(kubectl get secret postgres-credentials -n loom -o jsonpath='{.data.password}' | base64 -d)
    kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom -d loom_workflow_service \
      -c "select instance_id, created_by_fan_id, current_state from workflow_instances where workflow_type='book-nomination';"

    # Sole holder of book-member
    kubectl exec -i -n loom postgres-0 -- env PGPASSWORD="$PW" psql -U loom -d loom_app_access -c "
      select gm.group_id, gm.fan_id, gm.state, gmr.role_id
      from group_membership gm left join group_membership_role gmr using (app_id, group_id, fan_id)
      where gm.group_id like '%book%' order by gm.fan_id;"

Screenshots were captured at each step under `/tmp/b25book/` (34 frames). Per the evidence rules
`*.png` is gitignored and transient; this manifest is the durable record.

---

## Scope note

No application code, community JSON, tracker, or credential was modified. Device state was changed
only in the ordinary course of a walkthrough (`pm clear` on the demo app and on Chrome, both of which
repopulate on next launch — the demo app's ten example communities reloaded cleanly afterwards).
