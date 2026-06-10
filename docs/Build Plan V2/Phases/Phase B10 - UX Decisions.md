# Phase B10 - UX Decisions

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow
walkthrough, and open tradeoffs for replaying arbitrary Skill-generated local-demo artifacts.

## Reference Sources Reviewed

| Source | Surface reviewed | Why it applies | Patterns observed | Applicability / gaps | Review date |
| --- | --- | --- | --- | --- | --- |
| B9 arbitrary local package ingestion | Parsed file install, arbitrary card render, local latest open | B10 reuses B9 ingestion but changes the source to Skill-generated example artifacts. | Keep selected/generated artifacts as source of truth; fail on fixture substitution. | B9 did not validate a saved Skill example folder. | 2026-06-09 |
| Skill requirements-gathering plan | Owner-approved workflows, screens, features, permissions, schemas, rules, jobs, assets, UI guidelines | B10 is the first replay checkpoint after Skill output generation. | Generated docs and artifacts need a repeatable review/rebuild loop. | Full interactive Skill session is still manual. | 2026-06-09 |
| Skill local-demo package examples | JSON manifests, local branding references, export metadata | B10 must accept the documented Skill artifact shape. | Plain JSON is easy to review, diff, and copy into local package suffixes. | Real archive creation remains deferred. | 2026-06-09 |
| Demo App local loader tests | Add Community, loader errors, card confirmation, open action | B10 must preserve user-visible validation behavior from B1a/B9. | The card and local latest route are the visible success confirmation. | Widget test is not a full emulator file-picker run. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | What B10 applies |
| --- | --- |
| Generated artifacts need replayable evidence. | The Skill example folder stores the exact manifests used by the B10 workflow test. |
| Approval follows a working local run. | A generated extension is not approved until the Demo App imports, displays, and opens it. |
| Iteration starts from observed failure. | If replay fails, update Skill instructions or component tests before rebuilding. |
| Alias fields should be builder-friendly. | The local parser accepts `displayName` and `branding.cardImage/logo/heroImage`, matching Skill examples. |
| Fixture leakage must be obvious. | Any Book Club fields in B10 output are a validation failure. |

## Key UX Decisions

| Decision | Rationale | Affected surface | Covering test |
| --- | --- | --- | --- |
| B10 uses an arbitrary Garden Club example. | It is outside the anchor verticals and proves generated-package generality. | Skill examples, replay test | `wf_skill-arbitrary-extension-test-run` |
| The replay test reads docs artifacts directly. | Keeps review artifacts and validation artifacts aligned. | Skill example folder | `wf_skill-arbitrary-extension-test-run` |
| The parser accepts Skill-friendly aliases. | Builders should not need backend-internal field names in review docs. | Local In-App Backend | `wf_skill-arbitrary-extension-test-run` |
| The visible success state is card plus local latest open. | Owners can verify the generated extension is installed and runnable. | Demo App/App Shell | `wf_skill-arbitrary-extension-test-run` |

## Key Implementation Decisions

| Decision | Impact | Owner | Covering test |
| --- | --- | --- | --- |
| Add `Skill/examples/arbitrary-garden-club/`. | Creates a non-anchor replay fixture for Skill output validation. | ai-skill-extension-builder | `wf_skill-arbitrary-extension-test-run` |
| Copy docs JSON into temp package-suffix files during the test. | Exercises the Demo App local package parser without needing archive tooling yet. | workflow-validation-harness | `wf_skill-arbitrary-extension-test-run` |
| Accept `displayName` and `branding.*` aliases in the parser. | Aligns parser behavior with the Skill artifact format. | local-in-app-backend | `wf_skill-arbitrary-extension-test-run` |

## Workflow Walkthrough

| Step | User goal / action | Screen or state | Owner | UX decision applied | Covering test |
| --- | --- | --- | --- | --- | --- |
| 1 | Review generated arbitrary extension artifacts. | Skill example folder contains extension/init manifests. | ai-skill-extension-builder | Generated artifacts need replayable evidence. | `wf_skill-arbitrary-extension-test-run` |
| 2 | Prepare local package files. | Manifests are copied to locked package suffixes. | workflow-validation-harness | Replay through the actual local loader path. | `wf_skill-arbitrary-extension-test-run` |
| 3 | Import generated package pair. | Local backend parses Skill-friendly fields and imports seed references. | local-in-app-backend | Alias fields should be builder-friendly. | `wf_skill-arbitrary-extension-test-run` |
| 4 | Confirm installed card. | Garden Club card uses generated branding references. | community-card | Approval follows a working local run. | `wf_skill-arbitrary-extension-test-run` |
| 5 | Open extension. | App Shell opens `local:ext_garden_club@latest`. | app-shell-runtime | Local latest open is required success evidence. | `wf_skill-arbitrary-extension-test-run` |

## Open Questions / Tradeoffs

| Question | Options | Recommendation | Owner | Resolution phase |
| --- | --- | --- | --- | --- |
| Should Skill replay use a CLI packager now? | Test copy step now, CLI packager now, real archive builder now. | Keep test copy step for B10; add CLI packager with archive hardening. | extension-package-validator | Next package-builder phase |
| Should asset paths be verified now? | Accept path references, require files in docs, require archive hashes. | Accept path references now; require hashes once archive tooling exists. | ai-skill-extension-builder | Next package-builder phase |
| Should owner approval artifacts be tested here? | Docs-only, partial checklist, full interactive session. | Keep B10 to replay artifacts; run a manual Codex Skill session next and promote gaps. | Skill owner | Next implementation pass |
