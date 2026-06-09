# Phase B1b - UX Decisions

Status: Complete - R20 second-pass UX decisions applied

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow walkthrough, and open tradeoffs for real-backend-publish mode, builder signing, certification, package permission review, QR/handle discovery, hosted-install preview, and latest certified open behavior validated through local fakes. This file is a phase gate artifact, not a placeholder.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [Google Play app signing](https://support.google.com/googleplay/android-developer/answer/9842756) and [release review](https://support.google.com/googleplay/android-developer/answer/9859751) | Signing identity, release artifacts, review/certification state. | Loom real-backend-publish mode needs builder signing scope and certification before discovery/install. | Publish UX separates artifact identity, review status, and rollout availability. | Loom validates through local fakes in B1b; real hosted rollout is later. | 2026-06-09 |
| [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | Review criteria, privacy/payment/safety expectations before distribution. | Loom certification must communicate why a package is approved or blocked. | Review state should be explicit and tied to user-impacting requirements. | Loom certification is extension-level, not full app-store review. | 2026-06-09 |
| [Microsoft Teams app permissions and consent](https://learn.microsoft.com/microsoftteams/platform/concepts/device-capabilities/browser-device-permissions) | Permission prompts and consent for installed app capabilities. | Loom install preview must show requested permissions before install. | Permission UX should show capability purpose before grant. | Loom permissions are community APIs, not device APIs, but the consent pattern carries over. | 2026-06-09 |
| [Microsoft Teams app publishing overview](https://learn.microsoft.com/microsoftteams/platform/concepts/deploy-and-publish/apps-publish-overview) | App package publication, validation, and store/admin review. | Loom builder supply chain mirrors package -> validation -> discovery. | Publish flow separates packaging, validation, approval, and distribution surfaces. | Loom community owners need lighter, community-scoped copy. | 2026-06-09 |
| [Android QR code scanner guidance](https://developer.android.com/develop/ui/views/notifications/permissions) and platform install affordances | Entry-point trust and permission-before-use patterns. | QR/handle discovery needs a clear preview before install. | Users should see what will be opened/installed before granting capabilities. | QR implementation details are not built in B1b; contract uses handle/QR resolution fakes. | 2026-06-09 |
| [Material Design 3 cards](https://m3.material.io/components/cards/guidelines) | Hosted install preview and certified community card summary. | Install preview should summarize one community/extension clearly. | Cards work for compact identity, status, and primary action. | Loom must add certification and permission content to the card, not just branding. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Mode labeling | Google Play release, Teams publish | Builders can confuse local-demo artifacts with hosted publish. | Skill and docs label `real-backend-publish` and say B1b still validates through local fakes. | Users may assume a real hosted backend exists; copy must state local validation target. |
| Certification as a gate before discovery | Apple review, Teams validation | Members need trust before installing community extensions. | Package must be certified before public registry entry and latest-open. | B1b certification fake is not full policy enforcement. |
| Permission preview before install | Teams permissions | Install requires informed consent to extension capabilities. | Install preview shows package permissions and trust state before local import/open. | Existing workflow test validates permissions in package metadata, not rendered UI. |
| QR/handle preview | Store/install entry patterns | QR codes can feel opaque without a preview. | QR/handle resolution returns community identity, certification state, and latest version before install. | B1b uses fake QR payloads; visual scanner UI is later. |
| Latest certified version routing | App release patterns | Users need to know they are opening the current approved version. | App Shell opens `local:<extensionId>@latest` only after registry resolution. | Local backend still loads a package summary; hosted fetch is deferred. |

## Key UX Decisions

List the UX decisions that must be reflected in implementation. Each decision must trace to either a reference pattern, a Loom platform invariant, or a workflow requirement.

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Keep `real-backend-publish` as a distinct Skill mode from `local-demo`. | The artifact includes publish metadata even though validation remains local. | Skill walkthrough, package manifest, B1b docs. | `vt_ai-skill_generate-package`, `wf_build-publish-discover-install` |
| Builder signing scope is shown as a publish prerequisite. | Owners need to know which builder/app identity can publish an extension. | Builder App ID, Skill output. | `vt_builder-app-id_signing-scope`, workflow builder registration step |
| Certification is required before discovery and install preview. | Public install should not proceed from uncertified packages. | Certification System, Public Registry. | `vt_certification_validate-package`, `wf_build-publish-discover-install` |
| QR/handle resolution returns an install preview, not an immediate install. | QR entry points must reveal identity, trust, and permissions before install. | Community Registry, App Shell. | `vt_community-registry_discovery`, `wf_build-publish-discover-install` |
| Install opens latest certified version through App Shell. | Members should not pin to stale or uncertified versions by accident. | Extension Registry, App Shell Runtime. | `ct_extension-registry__app-shell_resolve-latest`, `vt_app-shell_route-host` |
| B1b gates remain on the Demo App with Local Backend. | No phase gate may depend on an external backend yet. | Workflow Validation Harness, Local In-App Backend. | `wf_build-publish-discover-install` |

## Key Implementation Decisions

Record implementation decisions that materially alter the UX, including component ownership, state model, copy source, layout behavior, validation behavior, and test coverage.

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Use control-plane fakes to model builder signing, certification, registry publish, public projection, and discovery. | The publish UX can be validated without hosted infrastructure. | Community Registry Control Plane fakes. | `wf_build-publish-discover-install` |
| Reuse B1a local package/init artifacts and add publish metadata. | Builders can validate one artifact pair locally and later publish with additional metadata. | AI Skill / Extension Builder. | `vt_ai-skill_generate-package`, Skill example manifests |
| Represent install preview through workflow assertions rather than a new visual screen in B1b. | Keeps B1b focused on contracts while B6/B7/B8 add richer user-facing install/payment/data surfaces. | App Shell, Community Registry. | `wf_build-publish-discover-install` |
| Keep local import after certification to prove the same package works in the Demo App. | Hosted publish mode remains testable in the preliminary local backend. | Local In-App Backend. | `wf_build-publish-discover-install`, B1a regressions |

## Workflow Walkthrough

Workflow under review: `wf_build-publish-discover-install`. Walk through the experience step by step after the UX decisions are made. Include the screen or state shown, the user action, the owning component, and the covering test.

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Generate publish-ready package metadata. | Skill output includes package ID, builder ID, signing scope, permissions, and certification evidence. | AI Skill / Extension Builder. | Distinct `real-backend-publish` mode. | `vt_ai-skill_generate-package` |
| 2 | Register builder signing scope. | Builder app identity is created with publish scope. | Builder App ID Service. | Signing prerequisite. | `vt_builder-app-id_signing-scope` |
| 3 | Certify package. | Certification fake returns certified status when evidence and permissions pass. | Certification System. | Certification before discovery. | `vt_certification_validate-package` |
| 4 | Publish version. | Extension registry stores version and resolves latest. | Extension Registry. | Latest certified version routing. | `vt_extension-registry_resolve-latest` |
| 5 | Resolve by handle/QR. | Registry resolves handle and QR payload to community profile and public entry. | Community Registry, Public Registry. | QR/handle preview. | `vt_community-registry_discovery`, `wf_build-publish-discover-install` |
| 6 | Review permissions/install locally. | Local backend imports the same init package and card props after publish validation. | Local In-App Backend, Community Card. | Permission preview before install; local validation target. | `wf_build-publish-discover-install` |
| 7 | Open latest certified package. | App Shell opens `local:ext_book_club@latest`. | App Shell Runtime. | Latest certified version routing. | `ct_extension-registry__app-shell_resolve-latest`, `wf_build-publish-discover-install` |

## Open Questions / Tradeoffs

Capture unresolved UX questions and tradeoffs before implementation starts. A phase can proceed only when blockers are resolved or explicitly accepted.

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Should B1b build a visual install preview screen now? | Visual preview now, contract-only preview now and UI later. | Keep B1b contract-first; add richer visual install preview when discovery UI is built. | App Shell / Community Registry. | Discovery UI phase |
| How much app-store-like policy detail belongs in certification copy? | Full policy list, high-level trust state, remediation details only on failure. | B1b records certified trust state and defers detailed remediation UX to certification/admin surfaces. | Certification System. | Governance/certification polish |
| Should QR scan be implemented physically in B1b? | Real camera scanner, QR payload contract only. | Use QR payload contract in B1b; physical scanner belongs to mobile shell polish. | App Shell Runtime. | Mobile release readiness |
| Should hosted publish write to a real backend in this phase? | Real hosted backend, local fakes. | Keep all validation on Demo App with Local Backend until hosted backend exists. | Workflow Validation Harness. | Future backend iteration |

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
