# Root cause: the created instance is not returned by `queryInstances`

## Outcome: confident root-cause diagnosis and recommended fix

The creator rule is correct, the persisted creator is decoded correctly, and the
definition is visible to the querying engine. The creator rule is never reached.

The row fails earlier, while `_hydrateQueryRow` evaluates the definition's computed
fields. The persisted instance legitimately omits the non-required
`reminderEnabled` field, but both Cedar formulas use that nullable/missing value
directly as an `if` condition. The first formula evaluated is `dueAt`:

```text
if(reminderEnabled,
   subtractHours(combineDateAndTime(eventDate, eventTime), 24),
   null)
```

`reminderEnabled` therefore resolves to `null`. `formula_evaluator.dart:365` passes
that value to `_bool`; `_bool` throws `FormulaEvaluationException: Expected bool,
got null` at `formula_evaluator.dart:408`.

The exact query-path line that prevents the instance from being included is
`local_workflow_engine_api.dart:470`:

```dart
instanceData: _withComputedFields(hydrated, machine, viewerId: fanId),
```

That call throws while `_hydrateQueryRow` is running at
`local_workflow_engine_api.dart:408`. No `_QueryCandidate` is returned, the visibility
call at lines 409-414 does not run, and the candidate is never added at line 415.
In particular, `_isVisibleToFan` and its creator comparison at lines 556-558 are not
reached. This is an exception before visibility evaluation, not a `membersOnly`
decision and not a row whose decoded creator is empty.

## The row as the engine decodes it

The live PostgreSQL row, passed through `WorkflowInstanceRow.fromRow`
(`database.dart:601-611`) and `_rawInstance` (`local_workflow_engine_api.dart:448-454`),
is exactly:

```text
WorkflowInstance(
  instanceId: community_cedar_commons_hoa_hoa-facility-reservation_sx2yfw5tsmou,
  workflowType: hoa-facility-reservation,
  currentState: open,
  instanceData: {
    title: Clubhouse - live chain probe,
    facility: Clubhouse,
    eventDate: 2026-09-15,
    eventTime: 18:00,
    requesterFanId: fan-test-alice,
    durationMinutes: 120,
    locationDetails: Main hall,
    reservationWindow: Evening
  },
  createdByFanId: fan-test-alice
)
```

The underlying typed row also has
`communityId: community_cedar_commons_hoa`, `createdAt: 1787717425046`, and
`updatedAt: 1787717425046`. There is no creator-column decoding defect:
`WorkflowInstanceRow.fromRow` reads `created_by_fan_id` at `database.dart:610`,
`_rawInstance` copies it at `local_workflow_engine_api.dart:453`, and hydration would
copy it again at line 471 if computed-field evaluation completed.

The exact equality which would be evaluated is therefore:

```text
"fan-test-alice" is non-empty
"fan-test-alice" == "fan-test-alice"
```

It would return `true` at lines 556-558.

## The definition is visible; missing-definition fail-closed behavior is not involved

The live `workflow_definitions` row is:

```text
definition_id: community_cedar_commons_hoa_hoa-facility-reservation
workflow_type: hoa-facility-reservation
version: 4
visibility: {"default":"membersOnly"}
```

That is the exact ID `_getDefinition` constructs at
`local_workflow_engine_api.dart:261`. More decisively, the production stack reaches
`_withComputedFields` from the `machine != null` arm of `_hydrateQueryRow` at lines
462-470. A missing definition would take the raw-data arm and could not execute the
failing formulas. `setFailClosedOnMissingDefinition(true)` is therefore functioning
as designed but is irrelevant to this row.

The stored definition has two affected computed fields, in evaluation order:

```text
dueAt:
  if(reminderEnabled, subtractHours(combineDateAndTime(eventDate, eventTime), 24), null)

reminderState:
  if(reminderEnabled, 'on', 'off')
```

Fixing only `dueAt` would merely move the same exception to `reminderState`.

## Live trace and the reported HTTP 200

The current live cluster does not return the reported `HTTP 200 {"items":[]}` for
this row. The row was created at `2026-08-25T21:10:25.046-07:00`. At
`2026-08-25T21:10:25.215-07:00`, 169 ms later, the current workflow-service pod logged
this exact collection path failing:

```text
FormulaEvaluationException: Expected bool, got null
#0 _bool (formula_evaluator.dart:408)
#1 _call (formula_evaluator.dart:365)
#5 LocalWorkflowEngineApi._withComputedFields
   (local_workflow_engine_api.dart:2130)
#6 LocalWorkflowEngineApi._hydrateQueryRow
   (local_workflow_engine_api.dart:470)
#7 LocalWorkflowEngineApi._filteredQueryPage
   (local_workflow_engine_api.dart:408)
#8 WorkflowService._queryInstances
   (workflow_service.dart:785)
```

A second authenticated request for the same fan and same instance reproduced the
same stack and returned HTTP 500. `readVisibleInstance` reproduces it as well.
`FormulaEvaluationException` is not caught inside the engine, so the current service
cannot turn this mechanism into a successful empty page; its terminal service catch
returns `500 workflow_service_error`. The quoted HTTP 200 is therefore from a different
request/deployment state or was recorded incorrectly. It must not be used to infer a
membership rejection. The current, timestamped production trace explains why this
exact persisted instance is not returned.

## Minimal correct fix

Make both Cedar computed formulas null-safe by testing the optional flag explicitly:

```text
dueAt condition:        reminderEnabled == true
reminderState condition: reminderEnabled == true
```

In other words, change both formulas to use `if(reminderEnabled == true, ...)` and
republish the Cedar definitions. Formula equality already handles `null`; an absent
flag will then select `null` for `dueAt` and `"off"` for `reminderState`. This repairs
the already-persisted row as well as future rows without changing visibility or
backfilling stored data.

This is preferable to changing `_bool(null)` globally to `false`: the evaluator's
strict boolean check catches genuinely ill-typed formulas, and weakening it would
silently change every workflow's formula semantics. Adding `reminderEnabled: false`
to the round-trip POST is a valid immediate data workaround, but it is not the durable
fix: `reminderEnabled` is not declared `required`, `_validateSeedData` therefore
accepts its omission at `local_workflow_engine_api.dart:1397-1405`, and that workaround
would leave this existing row unreadable.

The implementation ticket should first add a regression which installs this exact
definition, creates a creator-owned instance with the observed data and no
`reminderEnabled`, then queries as the creator. Before the formula correction it must
fail with `FormulaEvaluationException`; after republishing it must return one item with
`createdByFanId == fanId`, `dueAt == null`, and `reminderState == "off"`. Because the
durable fix changes two community-definition formulas and requires the repository's
sanctioned community-authoring workflow, it is not a provable one-line implementation
change and was not applied by this root-cause round.

## Missing membership lookup: independent correctness gap, not this cause

The absent `activeMembershipLookup` does not cause Alice's failure. Creator ownership
is checked before the `membersOnly` branch; once hydration succeeds, Alice returns at
lines 556-558 without calling `activeMembership` at line 567. The live App Access
membership endpoint currently reports that `fan-test-alice` has no Cedar group
membership, which further proves that membership cannot be the mechanism that should
make this particular row visible: ownership is.

The missing lookup is nevertheless a real, separate service defect for non-creator
members. With no lookup, `_isActiveMember` returns `false` at
`local_workflow_engine_api.dart:490-493`, so every genuine active member who is not an
owner/archetype participant is filtered at line 567.

The minimal correct service wiring is:

1. Add an App Access client operation for
   `GET /v1/apps/{appId}/groups/{groupId}/members/{fanId}`. Reuse the service's
   client-credentials token and forward the inbound correlation ID. On HTTP 200,
   validate that `appId`, `groupId`, and `fanId` echo the request and treat only
   `state == "active"` as active. Treat the authoritative
   `group_membership_not_found` 404 as `false`; malformed bodies, transport failures,
   and other statuses are authorization-service errors.
2. Extend the existing per-request App Access resolution used by
   `_resolveRolesForRequest`: resolve the canonical community group once, resolve both
   role IDs and active membership from App Access, then register both server-derived
   results before calling the engine. Use a per-community/per-fan membership registry
   (or an additive engine `setActiveMembershipForFan` API) behind
   `activeMembershipLookup`; do not install a cached-engine callback which captures
   only the most recent request's fan.
3. On group-resolution, membership-resolution, or role-resolution error, replace the
   fan's registered roles with an empty set, register membership as false, and return
   the existing authorization-service-unavailable response. Clearing both values
   before returning prevents a cached engine from reusing a previous successful
   authorization result.
4. Never read membership or roles from the query string, request body, JWT role claim,
   or community JSON. The authenticated `fanId` identifies the subject; App Access is
   the sole authority for current membership and role state.

Add service regressions for an active non-creator seeing a `membersOnly` row, a
missing/inactive member not seeing it, an owner seeing their row while membership is
false, and an App Access failure clearing prior membership and returning 503. None of
this wiring should relax `membersOnly` or the missing-definition fail-closed policy.

No implementation, community JSON, or reference-document file was modified in this
root-cause round.
