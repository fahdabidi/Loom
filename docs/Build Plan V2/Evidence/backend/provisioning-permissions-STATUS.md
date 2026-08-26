# App Access provisioning permissions status

## Result

Implemented permission-catalog reconciliation in
`app/packages/tooling/loom_app_access_provisioning`.

- The derived plan is now schema version 2 and has a top-level, sorted
  `permissions` array. Each record contains `permissionId` and a derived
  display name; for example, `document_library.publish` becomes `Document
  library: publish`.
- The final plan contains **65 permissions**. Its explicit permission set is
  **65/65** of the union of all planned role `permissionIds`; it includes
  `payment_checkout.create`. All **11/11** shipped communities derive into the
  same plan as before.
- Apply reconciliation now runs in the required order: **permissions → groups
  → roles**. It reads the catalog, POSTs only missing permission IDs, leaves
  existing entries unchanged, and reports catalog extras without deleting,
  renaming, or updating them. The existing 38 unused catalog entries remain
  outside mutation scope.
- Dry-run now lists each `WOULD ADD permission` record before groups and
  roles. Apply results separately report created, unchanged, and extra
  permission IDs.
- HTTP errors now include the response body (truncated above 4,096
  characters), so the `unknown_permission_id` code is visible to the caller.

The new applier guards its input before making HTTP calls: the plan permission
set must exactly equal the union of role permission IDs. That prevents a plan
from reporting a successful apply while omitting a role prerequisite.

## Regression coverage

The provisioning package now verifies all of the following against its fake
HTTP server, with no live-cluster calls:

1. The derived `permissions` set equals the complete role-grant union and
   contains `payment_checkout.create`.
2. Only absent catalog permissions are POSTed; catalog PUT and DELETE are not
   issued.
3. Permission POSTs occur before every role POST.
4. A second apply emits no App Access writes.
5. A JSON HTTP 400 leaves `unknown_permission_id` in the thrown error.

I also performed a reversible mutation check. Suppressing the new permission
POST made the ordering test fail with `firstPermissionPost == -1` where the
test requires a value greater than or equal to zero. The implementation was
then restored; the final suite passes.

## Verification

| Command / check | Final total |
| --- | --- |
| `cd app/packages/tooling/loom_app_access_provisioning && flutter test` | **12 passed** |
| `cd app/packages/core/loom_communities_app_shell && flutter test` | **273 passed** |
| `cd app/packages/core/loom_workflow_engine && flutter test` | **284 passed + 3 skipped** |
| `cd app/packages/tooling/loom_ux_judges && flutter test` | **432 passed** |
| `cd app/apps/loom_communities_demo && flutter test` | **160 passed** |
| `flutter analyze` in `loom_app_access_provisioning` | No issues found |

The provisioning suite's prior baseline was 8 tests. It is now 12, an increase
of four regressions; no total moved down. The four required repository suites
match their ticket baselines exactly.

One initial focused provisioning run ended at **8 passed, 1 failed** because
the newly extended fake server incorrectly attempted to JSON-decode the token
endpoint's form body. The fake server was corrected to leave that request body
unparsed; the final focused suite was rerun successfully at **12 passed**.
The intentional ordering mutation run was **0 passed, 1 failed**. An initial
parallel attempt at the four required suites encountered Flutter's shared
startup lock and yielded no final totals, so those commands were rerun one at a
time and the totals above are the verification record.

## Source-contract finding and limitation

The checked-in `~/loom-backend` source contradicts one verified fact in this
ticket: its App Access OpenAPI and controller expose `GET` plus catalog-wide
`PUT /v1/apps/{appId}/permissions`, but no `POST` permission endpoint. That
PUT is explicitly destructive in the implementation (`deleteById_AppId` before
reinsert), so this change intentionally does not call it. The ticket's stated
additive POST contract is what the applier and fake-server tests implement,
using the minimum requested body:

```json
{"permissionId":"…","displayName":"…"}
```

Accordingly, the exact POST request shape and live endpoint availability could
not be confirmed from the checked-in backend source. No live cluster was
called, no client secret was logged or persisted, and live apply remains
unverified until the backend source/API contract matches the stated additive
POST endpoint.
