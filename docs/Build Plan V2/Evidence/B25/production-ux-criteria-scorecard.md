# production-ux-judge Scorecard

Status: `fail`

| Criterion | Scope | Direct question | Score | Verdict | Blocks pass | Why | Required fix |
| --- | --- | --- | ---: | --- | --- | --- | --- |
| `b25-c01-no-blocker-major` No unresolved blocker or major findings | evidence | Are there zero unresolved blocker or major findings in the current production UX evidence? | 0 | fail | true | Unresolved blocker/major counts are blocker=0 major=3. | Resolve blockers/majors, rerun review, and record zero unresolved blocker/major findings. |
| `b25-c02-blueprint-complete` Every community has a complete production UX blueprint | holistic | Does every community or test app have a complete production UX blueprint that the review actually uses? | 100 | pass | false | Required evidence is present and no blocking derived failures were found. | None. |
| `b25-c03-production-grade-experience` Reviewer can state the experience feels production-grade | holistic | Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness? | 0 | fail | true | The evidence does not contain a defensible production-grade verdict. Missing evidence fields: holisticQuestionAnswers. | Run the independent screenshot-first review and record a production-grade verdict grounded in screen evidence. |
| `b25-c04-modern-intentional-ui` UI looks modern and intentionally designed | holistic | Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | 0 | fail | true | Screen rows do not prove modern hierarchy, spacing, and intentional design. Missing evidence fields: holisticQuestionAnswers. | Remediate visual hierarchy, spacing, typography, component quality, and recapture screenshots. |
| `b25-c05-community-content-ia` Screens are organized around community content and jobs-to-be-done | holistic | Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces? | 0 | fail | true | Primary screens still read as workflow lists, metadata, or validation surfaces. Missing evidence fields: holisticQuestionAnswers. | Rebuild home and primary screens around community content and user jobs. |
| `b25-c06-domain-native-primary-surfaces` Primary workflows use domain-specific product surfaces | workflow-persona | For every workflow and persona, is the primary UI a domain-native product surface rather than a generic card, checklist modal, or metadata page? | 0 | fail | true | A primary workflow is still generic-card/checklist/modal/metadata-only. Missing evidence fields: workflowPersonaScorecards. | Replace primary generic surfaces with domain-native product surfaces. |
| `b25-c07-screenshot-freshness` Every screen row has fresh screenshot evidence | evidence | Does every reviewed screen row use fresh screenshot evidence from the app version under review, with hash, timestamp, device metadata, and app commit SHA? | 100 | pass | false | Required evidence is present and no blocking derived failures were found. | None. |
| `b25-c08-visible-text-specific-critique` Every row has visible text and screen-specific critique | workflow-persona | Does every holistic and workflow/persona review answer cite visible UI/text and provide a critique specific to that screenshot and user task? | 0 | fail | true | Visible text or non-boilerplate row critique is missing. Missing evidence fields: workflowPersonaScorecards. | Extract visible text and write a specific critique for each screenshot row. |
| `b25-c09-no-layout-production-defects` No blocking or major layout/content defects remain | holistic | Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects? | 0 | fail | true | No holistic direct-question answers were supplied. | Fix layout/content defects and rerun the review. |
| `b25-c10-full-screen-inventory` Every implemented screen/state appears in the matrix | evidence | Does the screen inventory cover every user-facing screen, state, dialog, card, feed item, form, confirmation, error, empty state, persona variant, and action result? | 100 | pass | false | Required evidence is present and no blocking derived failures were found. | None. |
| `b25-c11-schema-v4-consistency` Schema v4 JSON is complete and internally consistent | evidence | Is the schema v4 evidence complete and internally consistent across JSON, markdown review, matrix, remediation log, screenshots, and tracker? | 100 | pass | false | Required evidence is present and no blocking derived failures were found. | None. |
| `b25-c12-remediation-proof` Failed prior iterations have proof of remediation | remediation | If any prior loop iteration failed, does the remediation log prove fixes, screenshot refresh, evidence regeneration, tests, commit SHA, and zero remaining blockers/majors? | 100 | pass | false | Required evidence is present and no blocking derived failures were found. | None. |

## Errors
- b25-c01-no-blocker-major: Unresolved blocker/major counts are blocker=0 major=3.
- b25-c03-production-grade-experience: The evidence does not contain a defensible production-grade verdict. Missing evidence fields: holisticQuestionAnswers.
- b25-c04-modern-intentional-ui: Screen rows do not prove modern hierarchy, spacing, and intentional design. Missing evidence fields: holisticQuestionAnswers.
- b25-c05-community-content-ia: Primary screens still read as workflow lists, metadata, or validation surfaces. Missing evidence fields: holisticQuestionAnswers.
- b25-c06-domain-native-primary-surfaces: A primary workflow is still generic-card/checklist/modal/metadata-only. Missing evidence fields: workflowPersonaScorecards.
- b25-c08-visible-text-specific-critique: Visible text or non-boilerplate row critique is missing. Missing evidence fields: workflowPersonaScorecards.
- b25-c09-no-layout-production-defects: No holistic direct-question answers were supplied.
- finalDecision is fail, not pass.
- holistic direct-question pass: No holistic direct-question answers were supplied.
- workflow/persona direct-question pass: No workflow/persona direct-question scorecards were supplied.
- Unresolved major finding: B25-V4-REVIEW-PENDING.
- Unresolved major finding: B25-HOLISTIC-UNPROVEN.
- Unresolved major finding: B25-WORKFLOW-PERSONA-UNPROVEN.
