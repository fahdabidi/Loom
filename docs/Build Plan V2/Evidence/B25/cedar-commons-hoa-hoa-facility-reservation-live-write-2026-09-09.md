**Workflow:** `hoa-facility-reservation` in Cedar Commons HOA
**Outcome:** BLOCKED — not proven. No live write was performed. Creation is refused HTTP 403 for *every* role in this community (no role holds `calendar.create`), and every instance-listing surface in Cedar Commons HOA returns HTTP 500, so neither the member half nor the board half can be driven.

**Package identity:** `Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `38c70ed08eabe2ef07011658bdea2434008e385b271e4ae6b98a29007369fd7f`

**APK:** `com.example.loom_communities_demo` versionName 0.1.0, lastUpdateTime 2026-09-09 09:56:01, on `emulator-5554` (Android 16).
**Run date:** 2026-09-09, ~20:26–21:00 UTC.

---

## Identity actually authenticated

Signed in through the real Keycloak form in a Chrome custom tab (no SSO shortcut):

- Keycloak user `loom-hoa-member-1`, fan id `fan-hoa-member-1`, role `hoa-member`.
- The app rendered **"Signed in as Hoa Member 1 — Homeowner"** in the Cedar Commons HOA shell.

Identity hygiene performed before signing in, and it mattered:

- The app carried a **stale session for `fan-ad-off-owner-1`** (left by an earlier Ad-Free run). Tapping "Hoa Member 1" returned
  `LoomAuthException(accountNotFound): The authenticated Loom identity cannot sign in as account "fan-hoa-member-1"` —
  the anti-impersonation guard working correctly.
- Cleared `com.example.loom_communities_demo` and `com.android.chrome`, then signed in fresh. The Keycloak form appeared
  **genuinely empty** (screenshot `15_form.png`), confirming no stale SSO cookie re-issued a previous fan's token.

## Path driven on the device

Cedar Commons HOA → **Calendar** tab → FAB **"Reserve a facility"** → create form completed and verified field-by-field
on screen before submitting:

| Field | Value submitted |
|---|---|
| Title | `B25-Reverify-2026-09-09` |
| Facility | `Clubhouse-Annex-B25` |
| Event Date | `2026-09-23` (chosen from the date picker) |
| Event Time | `19:00` (chosen from the time picker) |
| Window | `Evening-Window` |
| Location | `Cedar-Clubhouse-Annex` |

**Result: "Could not create the instance. Please try again."** (screenshot `38_created.png`). Retried once; same result.

## Defect 1 — `hoa-facility-reservation` cannot be created by anyone (HTTP 403)

Client log at the moment of the second Create tap:

```
LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/
  scope=ext_cedar_commons_hoa outcome=failure status=403 error=http_403 at=2026-09-09T20:41:57.600267Z
```

Mechanism, read from the deployed service source (`loom_workflow_service/lib/src/workflow_service.dart:566-599`):
creation resolves the workflow's archetype family, derives `permissionId = <family>.create`, and calls
`_appAccessClient.checkAccess(...)`; `if (!allowed) return _createRefused(request)` → HTTP 403
`workflow_create_refused`.

The deployed definition resolves to the `calendar` family (control included — a sibling workflow resolves elsewhere):

| workflow_type | `cardSurfaceFamily` in deployed definition | required permission |
|---|---|---|
| `hoa-facility-reservation` | `calendar` | `calendar.create` |
| `hoa-dues-payment` (control) | `paymentCheckout` | `payment_checkout.create` |

**No role anywhere in App Access holds any `calendar.*` permission** — `select ... from role_permission where
permission_id like 'calendar.%'` returns **0 rows**, across every role of every community. The nine `calendar.*` ids
*do* exist in the deployed catalog (137 ids total, matching the brief). So the catalog layer is correct and the
**grant layer was never populated**.

Confirmed against the live authorization service — the identical `POST /v1/access-decisions` call the workflow service
makes — with a passing control to prove the query shape and ids are right:

| fan | permission | decision |
|---|---|---|
| `fan-hoa-member-1` | `calendar.create` | **deny** — `"No active role granted the requested permission"` |
| `fan-hoa-board-1` | `calendar.create` | **deny** — same reason |
| `fan-hoa-member-1` | `event_rsvp.create` (control) | allow, granting role `hoa-member` |
| `fan-hoa-board-1` | `event_rsvp.create` (control) | allow, granting role `hoa-board` |

Both provisioned roles are correct in `group_membership_role` (`fan-hoa-member-1`→`hoa-member`,
`fan-hoa-board-1`→`hoa-board`). This is **not** a seeding or role-provisioning gap: it is a missing permission grant,
and it denies the board exactly as it denies the member.

*Why the three existing rows exist anyway:* all three were created **2026-08-26** by `fan-test-alice`. That account is
itself denied `calendar.create` today (`allowed:false`, `grantingRoleIds:[]`, same "No active role granted the requested
permission" reason), so the rows cannot be reproduced by the account that produced them, and they are not evidence that
the path works now. I did not establish *when* the configuration changed — only that it refuses that account today.

## Defect 2 — every instance-listing surface in this community returns HTTP 500

Independent of the 403, both tabs that bind this workflow fail to list anything. On-device error text, with
correlation ids that match the service's own logs exactly:

- **Calendar** tab: `Remote workflow error (workflow_service_error, HTTP 500, correlationId: c1ef773c-a4da-43ba-8949-0e18e2ecb1b7): Workflow instances could not be queried.`
- **Home** tab: same error, `correlationId: 8d2bfd6f-e15d-4dc1-a8b6-35650ad31c7b`

Server-side, same correlation id:

```
{"event":"workflow_service_unexpected_error","correlationId":"c1ef773c-...","method":"GET",
 "path":"/v1/communities/community_cedar_commons_hoa/instances",
 "errorType":"JsonUnsupportedObjectError",
 "error":"Converting object to an encodable object failed: Instance of 'DateTime'",
 ... WorkflowService._queryInstances (workflow_service.dart:1156)}
```

Isolated by workflow type with read-only GETs against the live service (member token):

| workflowType filter | HTTP |
|---|---|
| `hoa-facility-reservation` | 200 |
| `hoa-owner-notification` | 200 |
| **`hoa-dues-payment`** | **500** |
| *(no filter — what the tabs actually issue)* | **500** |

So a single workflow type poisons the community-wide listing: the tabs query unfiltered, one item fails to encode, and
**no instance of any type renders in Cedar Commons HOA**.

Root cause is consistent with the data: nothing in `instance_data` is stored as a `DateTime` (all values are strings),
so the value is produced at projection time. `hoa-dues-payment` is the only listed type carrying **`date`/`time`-typed
formula fields** (`eventDate` = formula `dueDate`, `eventTime` = formula `dueTime`); the formula evaluator yields a real
`DateTime`, and `_workflowInstanceJson` passes `instanceData` straight to `jsonEncode`.
`hoa-facility-reservation`'s only formula (`reminderState`) returns a string, and it returns 200.

A sweep of all ten shipped packages finds date/time-typed formula fields in **exactly one community — Cedar Commons
HOA** (4 fields: `hoa-dues-payment.eventDate/eventTime`, `hoa-architectural-request.eventDate/eventTime`), which matches
the observation that this is the only community whose `/instances` endpoint errors.
*(`hoa-architectural-request` has no stored rows, so it could not be used as a live confirming test — stated rather than
implied.)*

## Database verification (this session)

Baseline measured before touching anything: **25 rows total**, and `hoa-facility-reservation` already had **3 rows** —
so the brief's premise that "no corresponding row exists in the database today" was **wrong**; the three rows are simply
old and belong to a different fan.

Final state, using the brief's exact query:

```
                            instance_id                            |        community_id         |      workflow_type       | created_by_fan_id | current_state |  created_at
-------------------------------------------------------------------+-----------------------------+--------------------------+-------------------+---------------+---------------
 community_cedar_commons_hoa_hoa-facility-reservation_uc8clw8jfw8z | community_cedar_commons_hoa | hoa-facility-reservation | fan-test-alice    | open          | 1787723318899
 community_cedar_commons_hoa_hoa-facility-reservation_3pbmhxf5srqh | community_cedar_commons_hoa | hoa-facility-reservation | fan-test-alice    | reserved      | 1787718649321
 community_cedar_commons_hoa_hoa-facility-reservation_sx2yfw5tsmou | community_cedar_commons_hoa | hoa-facility-reservation | fan-test-alice    | open          | 1787717425046
(3 rows)
```

- Total instances still **25** (unchanged from baseline).
- Rows created after this session began (`created_at > 1788986123957`): **0**.
- No row bears `created_by_fan_id = fan-hoa-member-1` for this workflow type.

**Screen and database agree:** the UI said the create failed, and no row was written. Nothing in this run was mutated —
no instance created, no state advanced, no grant or credential changed.

## Two-party status

Not reached, and unreachable as deployed rather than merely unattempted:

- The **member half** cannot create (403, proven live on device).
- The **board half** has nothing to act on, because no reservation can be created, and no reservation — including the
  three pre-existing ones — renders on any surface (500 on Calendar and Home).
- `fan-hoa-board-1` is refused `calendar.create` by the live authorization service just as the member is, so signing in
  as the board on the device could not have changed the outcome. I did not fire a create as the board, to avoid writing
  a row outside the UI path.

## What would unblock this row

1. Grant the `calendar.*` permissions to the appropriate Cedar Commons HOA roles (`hoa-member` for
   `calendar.create/edit/cancel/set_reminder/view`; `hoa-board` additionally for `record_outcome`/`reopen`). The ids
   already exist in the catalog; only the grants are missing. **Not applied here** — the brief forbids provisioning
   changes.
2. Fix `date`/`time`-typed formula projection so `instanceData` carries ISO-8601 strings rather than `DateTime`
   instances (or serialise in `_workflowInstanceJson`). Application code is out of scope for this dispatch.

Both are required. Fixing only the grant leaves the reservation invisible; fixing only the encoding leaves it
uncreatable.
