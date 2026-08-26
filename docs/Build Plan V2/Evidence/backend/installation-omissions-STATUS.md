# Installation omissions status

## Result

The App Access provisioning deriver now omits a workflow from its installation
request when `ArchetypeResolver` returns no `cardSurfaceFamily`. It does not
substitute a placeholder, generic family, empty string, or `null`.

The local provisioning plan now records each exclusion in
`omittedWorkflowTypes`; the plan format is schema version 4. The metadata is
not part of `InstallCommunityPackageRequest`, so the only request-shape change
is that a derived-nothing workflow is absent from `workflows`. The request DTO
also makes `cardSurfaceFamily` non-nullable, preventing a future plan from
serializing a null family.

`--dry-run` prints an explicit `OMITS workflows with no resolved
cardSurfaceFamily` line for every affected community before showing its POST
body. Its regression test proves both that output and that the omission metadata
is not included in the POST body.

No live cluster, Keycloak, or external App Access endpoint was called. The
provisioning HTTP tests use their in-process fake server; all corpus checks read
the checked-in packages only. No client secret was logged or persisted.

## Omitted workflows per shipped community

The fraction is `omitted workflows / all declared workflows` for that package.

| Community | Omitted | Workflow types |
| --- | ---: | --- |
| Ad-Free Community | 0/6 | None |
| Camera Club | 0/6 | None |
| Cedar Commons HOA | 0/7 | None |
| Chess Club | 0/8 | None |
| Export and Migration | 0/9 | None |
| Garden Club | 0/8 | None |
| Masjid Nur | 0/10 | None |
| Platform Social | 0/6 | None |
| Neighborhood Book Club | 0/12 | None |
| Tabletop Club | **2/13** | `tournament-vote`, `notification` |
| Riverside Youth Soccer | 0/10 | None |

Corpus-wide, the request now carries **93/95** workflows and explicitly omits
**2/95**. The omitted set is exactly Tabletop Club's `tournament-vote` and
`notification`.

## Assertions added or strengthened

1. A workflow with an unresolved archetype is absent from the generated request
   by `workflowType`, not merely represented with a non-null family.
2. Tabletop Club omits both listed workflow types and retains its other
   **11/13** workflows.
3. Every workflow in every generated request has a non-null
   `cardSurfaceFamily`: **93/93** request workflows across **11/11** packages.
4. The plan exposes the shipped corpus's exact omission set: **2/95**, only in
   Tabletop Club.
5. The existing Cedar inversion (`cedar_commons_hoa_admin` appears nowhere) and
   the invariant that no generated request contains `permissionIds` remain
   passing without modification.

## Verification

| Command | Exact final total |
| --- | --- |
| `cd app/packages/tooling/loom_app_access_provisioning && flutter test` | **15 passed** |
| `cd app/packages/tooling/loom_app_access_provisioning && flutter analyze` | **No issues found** |
| `cd app/packages/core/loom_communities_app_shell && flutter test` | **273 passed** |
| `cd app/packages/core/loom_workflow_engine && flutter test` | **284 passed, 3 skipped** |
| `cd app/packages/tooling/loom_ux_judges && flutter test` | **432 passed** |
| `cd app/apps/loom_communities_demo && flutter test` | **160 passed** |

The focused provisioning suite was **11 passed** before this change and **15
passed** after it: four requested corpus regressions were added, while the
existing dry-run test was strengthened in place. No test total moved down.
