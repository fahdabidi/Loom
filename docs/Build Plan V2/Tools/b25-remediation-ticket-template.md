# B25 Remediation Ticket Template

Use this template whenever the Production UX Judge finds a blocking or major B25 issue. The ticket is
the handoff artifact from the Judge Agent to the Remediation Planner and Worker Agent. It must be
specific enough that the next worker can implement a fix without relying on the prior worker's intent
or a generic pass/fail summary.

## Required Ticket Fields

| Field | Required content |
| --- | --- |
| `ticketId` | Stable ID for the remediation ticket, such as `B25-RT-001-b25-c04-modern-intentional-ui`. |
| `ticketSchemaVersion` | Current schema version. Use `1` until the template changes. |
| `phase` | `B25`. |
| `reviewRunId` | The review pass that produced the ticket, such as `b25-v4-pass-1`. |
| `status` | `open`, `in-progress`, `resolved`, `owner-accepted`, or `deferred-with-rationale`. |
| `severity` | `critical-blocker`, `major`, `minor`, or `polish`. |
| `priority` | `P0` for blockers, `P1` for major production UX failures, `P2` for minor/polish. |
| `sourceCriterionId` | Failed production UX criterion ID. |
| `sourceFindingIds` | Related finding IDs from the review JSON. |
| `directQuestion` | The exact direct question the evidence failed to satisfy. |
| `whyItFailed` | Evidence-grounded explanation of why the criterion failed. |
| `affectedScope` | Communities, personas, workflows, screen rows, and screenshots affected. |
| `problemStatement` | Plain-language user-facing problem, not implementation jargon. |
| `rootCauseHypothesis` | Likely UX/design root cause behind the failure. |
| `targetExperience` | What the user should see, understand, and be able to do after the fix. |
| `uxPrinciples` | Production UX principles being enforced. |
| `concreteImprovements` | Specific UI/content/IA changes to make. |
| `implementationGuidance` | Likely files/components/surfaces to inspect or change. |
| `contentGuidance` | Copy/content changes needed to make the screen domain-native and useful. |
| `visualGuidance` | Layout, spacing, hierarchy, component, navigation, or polish changes needed. |
| `evidenceToCollect` | Screenshots, visible text, scorecards, or manifests required after the fix. |
| `acceptanceChecks` | Conditions that must be true before the ticket can close. |
| `rerunCommands` | Commands to regenerate evidence, rerun the judge, and regenerate the iteration scorecard for the current remediation pass. Do not include the Remediation Planner here; the planner runs only at the start of the next pass if the committed pass still fails. |
| `nonGoals` | What not to do, especially superficial fixes that would not satisfy the criterion. |
| `commitBoundary` | Reminder that the iteration must be committed before the next UX feedback loop. |

## Markdown Shape

Each ticket Markdown section should use this structure:

```markdown
## B25-RT-001-b25-c04-modern-intentional-ui

| Field | Value |
| --- | --- |
| Status | open |
| Severity | major |
| Priority | P1 |
| Source criterion | b25-c04-modern-intentional-ui |
| Source findings | B25-HOLISTIC-UNPROVEN |
| Direct question | Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? |

### Why It Failed

Evidence-grounded explanation.

### Affected Scope

- Communities:
- Personas:
- Workflows:
- Screen rows:
- Screenshots:

### Target Experience

What the target user should experience after the fix.

### Concrete Improvements

- Specific UI/content/IA change.
- Specific UI/content/IA change.

### Implementation Guidance

- Likely files/components/surfaces.
- Tests or helpers likely needing updates.

### Evidence To Collect

- Fresh screenshot rows.
- Visible text extracts.
- Holistic or workflow/persona answers.

### Acceptance Checks

- Judge criterion no longer blocks pass.
- Screenshots and hashes are fresh.
- Iteration scorecard shows the ticket resolved or non-blocking.

### Rerun Commands

- `...`

### Non-Goals

- Do not rename a generic card and call it domain-native.
- Do not pass without fresh screenshots.
```

## Quality Bar

A remediation ticket is invalid if it only says "fix UX" or repeats the failed criterion. It must name
the user-facing problem, describe the target experience, identify the artifacts to update, and define
how the next pass will prove the fix.

The ticket is not an implementation plan by itself. The next pass sends committed tickets and the
iteration scorecard to the Remediation Planner, which creates the ordered fix batches for the Worker
Agent.
