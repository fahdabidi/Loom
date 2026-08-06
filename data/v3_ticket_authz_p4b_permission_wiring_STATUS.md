# Ticket status: AuthZ.P4b

## Change applied

Status: done

Exact locations:

- `personaHasPermission`: `app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart:1414` (with the async membership-lookup companion at `:1467`), immediately next to the reused `_personaCanAdministerAnyWorkflow` check at `:1349`.
- Tab-visibility wiring: `app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart:196` and `app/packages/core/loom_communities_app_shell/lib/src/part11_shell_models.dart:611`; explicit `visiblePersonaIds` remains the first decision, and the computed fallback is enabled only for package declarative or engine-native paths.
- Engine-boundary enforcement: `app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart:173` (`queryInstances`), `:353` (`_requireSurfacePermission`), and `:665` (`applyTransition`), wired to the app-shell policy from `app/packages/core/loom_communities_app_shell/lib/src/part25_engine_native_community_store.dart:183` and `:275`.

No JSON grammar or JSON field was added, removed, or changed. The existing `requiredPermission` parsing is only consumed at runtime. The tab-spec `requiredPermission` values present in the app-shell code consistently use the existing `.read` / non-`.read` (`.configure`) taxonomy; unrelated generic API permissions elsewhere are not tab-spec inputs. Hardcoded Dart archetypes' explicit `visiblePersonaIds` declarations were left untouched.

The engine-boundary check is surface reachability; AuthZ.P4a's row-level filtering still runs inside `queryInstances`, and transition guards remain the action-level re-check inside `applyTransition`.

## Verification

Flutter analyzer: the literal `flutter analyze` launcher was not runnable in this sandbox; both package invocations failed before startup with the WSL interop `UtilBindVsockAnyPort ... socket failed 1` error. The direct Flutter SDK Dart analyzer reported `No issues found!` for both `loom_communities_app_shell` and `loom_workflow_engine`; its final nonzero exit was only the sandbox's read-only telemetry-session write.

Test suites: `loom_workflow_engine` full suite passed **206/206** using the direct test runner. The literal `flutter test` for `loom_communities_app_shell` failed before the suite started with the same WSL interop socket error, so its sandbox pass count is unavailable; the required baseline remains **185/186**, with only the known a11 flake, and independent verification is required.

New tests in `app/packages/core/loom_communities_app_shell/test/authz_p4b_permission_wiring_test.dart`:

- `personaHasPermission allows public read permissions`
- `personaHasPermissionAsync reuses active membership lookup`
- `personaHasPermission evaluates guarded read admissibility`
- `personaHasPermission derives configure access from transition, edit, and creation guards`
- `declarative tabs use computed permission fallback while hardcoded archetypes keep explicit lists`
- `engine boundary re-checks query and transition surface access`

## Commit

Commit hash: `d4135ede` (the implementation commit; this status report was embedded by the final amend)
