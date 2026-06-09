# Phase B1 - Build, Publish, Discover, Install

Workflow bundle: Skill build -> publish -> certify -> discover by handle/QR -> install -> open latest.
Components involved: Skill, Builder App ID, Extension Registry, Certification, Community Registry, App
Shell, Extension Runtime.
UX gate: high
Gate: `wf_build-publish-discover-install` plus affected component regressions pass.

## 0. Prerequisite Gate

- A6 complete and committed.
- All Set A required tests pass and are not stale.
- Manifest has no unresolved required contract tests among built components.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_build-publish-discover-install` | Owner-generated extension is signed, certified, discoverable by QR/handle, installed, and opened as latest certified version in App Shell. |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Skill generates package | AI Skill / Extension Builder | `vt_skill_skeleton`, `vt_ai-skill_generate-package` |
| Builder signs artifact | builder-app-id-service | `vt_builder-app-id_signing-scope` |
| Registry stores version | extension-registry | `vt_extension-registry_resolve-latest` |
| Certification approves package | certification-system | `vt_certification_validate-package` |
| QR/handle resolves community | community-registry | `vt_community-registry_discovery` |
| App Shell opens latest | app-shell-runtime | `ct_extension-registry__app-shell_resolve-latest`, `vt_app-shell_route-host` |

## 3. UX Research and Decisions

Create `Phase B1 - UX Decisions.md`. Review QR install, app install, package permission review, and
owner publish flows. Record how permission review, certification status, and latest-version behavior
are displayed.

## 4. Execution and Issue-Triage Loop

Run `wf_build-publish-discover-install`. On failure:

1. Add or strengthen the owning component's `vt_` or `ct_` test.
2. Route fix to that component agent.
3. Update downstream tests.
4. Rerun the workflow and affected component regressions.

## 5. Per-Component Regression Gate

If any involved component changes, run all its validation tests and every workflow test in which it
participates per manifest lookup.

## 6. Skill Contribution

Add:

- `Skill/workflows/build-publish-discover-install.md`
- Example package fragment under `Skill/examples/book-club/phase-b1-package/`

Update the master walkthrough with publish, QR, install, and latest-open steps.

## 7. Manifest Update

Stamp `wf_build-publish-discover-install` and all affected component tests with latest component/test
hashes.

## 8. API Review

Create `Phase B1 - API Review.md`. Record any package, registry, certification, App Shell, or QR API
gaps.

## 9. Definition of Done

Workflow test passes, component regressions pass, UX Decisions and API Review filed, Skill updated,
manifest current, tracker and commit SHA recorded.

## 10. Next Phase

Proceed to [Phase B2 - Book Club Headline Flow.md](./Phase%20B2%20-%20Book%20Club%20Headline%20Flow.md).
