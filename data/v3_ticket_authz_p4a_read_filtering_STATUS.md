# Ticket status: AuthZ.P4a

## Change applied

Status: done

The row-level visibility filter is applied in `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:250-258`, using the shared visibility/read-guard policy at `:335-358`. Rows are hydrated and computed before that policy runs at `:296-314`, so formula-based read guards see the same computed data as the rest of the engine. Omitted/public visibility keeps the legacy query path at `:165-220`, including its existing result shape and pagination behavior.

The optional aggregate parameter is declared at `app/packages/core/loom_workflow_engine/lib/src/api/workflow_engine_api.dart:159-166` and implemented at `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:449-463`. Supplying `personaId` uses the separate viewer-scoped aggregate reader at `:407-446`; omitting it continues to use `_readAllInstancesOfType` exactly as before.

The pagination fix is `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:223-285`. Restricted pages scan over-fetched keyset batches, hydrate and filter until `limit + 1` visible candidates are available, then calculate `hasMore` at `:275` and the next cursor from the last returned filtered row at `:280-283`. The database query was left unchanged: its raw `limit + 1` keyset batches are the contained over-fetch mechanism needed for formula guards that cannot be pushed into SQL.

(a) `membersOnly` uses the injected `ActiveMembershipLookup` constructor parameter at `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:104-114`. The lookup is bound by the caller to this community's account store and must return true only for `MembershipStatus.active`; when no lookup is injected, the engine fails closed. Full `LocalAuthApi` wiring was deferred because the workflow-engine package should not depend on the app-shell auth implementation, and the injected lookup is sufficient to make the policy correct and testable. Production wiring can be added in AuthZ.P4b or a later integration ticket.

(b) Every internal system-truth read path was left unfiltered. `_readAllInstancesOfType` remains unfiltered at `:388-405`; `_passesRelatedAggregateGuard` still calls `aggregate` without `personaId` at `:1182-1187`; `_passesLocationOverlapGuard` still iterates that unfiltered reader at `:1134`; `dueNotifications` still reads its raw database page at `:489-518`; and `_hydrateSourceFields` still uses `_readAllInstancesOfType` at `:1492-1519`. The `transitionRelated` effect path also remains unfiltered at `:1323-1341`. Thus capacity, overlap, related aggregates, source hydration, notifications, and related transitions continue to see system truth rather than a viewer's filtered subset.

(c) Both existing external aggregate call sites now pass `personaId` as defense in depth. `notification_inbox_controller.dart:23-29` already has an explicit recipient-persona equality filter, so the new parameter is redundant for that particular filter but protects it if the workflow visibility policy changes. The Part02 store at `part02_tab_shell.dart:1402-1410` now receives and passes the effective persona used by the tab; its aggregate filter is unread/archived while recipient-list scoping is otherwise performed by the tab's list path, so the new parameter is not redundant there. No `personaHasPermission`, `requiredPermission`, or tab-visibility changes were made.

## Verification

`flutter analyze` (both packages): the literal Flutter launcher cannot run in this sandbox because it exits with `UtilBindVsockAnyPort:309: socket failed 1`. The cached Flutter analyzer snapshot, run with `--no-pub` against both packages, reported `No issues found!`; the direct Dart analyzers also reported clean for both packages. The literal command limitation is recorded here rather than treating the cached invocation as an unrestricted Flutter-launcher run.

Test suites: `loom_workflow_engine` passed `206/206` through the cached package test runner, comprising the established `200/200` baseline plus six new tests. The `loom_communities_app_shell` Flutter suite could not run in this sandbox: every cached Flutter test isolate failed before loading with `Failed to create server socket (OS Error: Operation not permitted, errno = 1)`. Its direct Dart fallback cannot bootstrap Flutter widget types. Therefore this session cannot independently confirm the established `185/186` outcome (185 passing and the one known a11 flake); that exact known baseline remains for independent verification outside the sandbox.

New tests are in `app/packages/core/loom_workflow_engine/test/authz_p4a_visibility_filtering_test.dart`: guarded allowlist plus author ownership, state-level guard override, injected `membersOnly` membership lookup, omitted/public no-op behavior, computed-field read-guard evaluation, and filtered pagination cursor/`hasMore` correctness. All six pass.

## Commit

Commit hash: `b47c3c3b`.
