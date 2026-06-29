# B25 Production UX Blueprint

Purpose: define the production UX bar used by B25 before each screenshot review pass. This blueprint
is the shared bar; the community-specific source of truth is the Product Docs V2 community experience
doc for each reviewed community.

## Required Inputs

| Artifact | Requirement |
| --- | --- |
| Product Docs V2 community experience docs | Every reviewed community/test app must have a doc under `docs/Product Docs V2/Community Examples/` with product promise, personas/jobs, IA, home requirements, domain-native surfaces, workflow-to-surface mapping, persona/state matrix, seed content, visual standard, and B25 review log. |
| Fresh screenshots | Every reviewed screen row must have screenshot path, hash, timestamp, device metadata, app commit SHA, visible text, and screenshot-specific critique. |
| Workflow/persona coverage | Every workflow/persona combination must have entry, action/review, result/receiver, error/empty/disabled/hidden states where applicable. |
| Independent UX review | The reviewer must answer direct holistic and workflow/persona questions from the screenshots and product docs, not from implementation intent. |
| Production judge scorecard | The deterministic judge must verify Product Doc coverage, visual inspection, direct-question quality, workflow/persona scorecards, screen matrix completeness, and zero unresolved blocker/major findings. |

## Production Experience Bar

The app passes B25 only when a fresh reviewer can say all of the following from the evidence:

- The experience feels like a real production community product for the target user, not a workflow
  harness or validation screen.
- The UI looks modern, intentional, visually appealing, easy to use, and easy to navigate.
- The main user-facing screens are organized around community content and jobs-to-be-done.
- Primary workflows use domain-native product surfaces, not generic workflow cards or checklist modals.
- Each screen is judged against the matching community product experience doc.
- The visible UI has no blocking or major overlap, clipping, crowding, default scaffold,
  repeated-card, checklist-modal, or thin-content findings.

## Community Product Experience Docs

Each reviewed community/test app must have a Product Docs V2 community-specific experience doc before
remediation continues. For native Loom repo development, these docs live under:

```text
docs/Product Docs V2/Community Examples/<community>-product-experience.md
```

For standalone Skill-created extensions, the same content lives inside the generated extension working
repo:

```text
docs/Product Experience/<extension-id>-product-experience.md
```

B25 native repo runs validate the Product Docs V2 location. The Skill validates the extension-local
location and may use the native docs only as reference examples.

## Review Sequence

1. Product Experience Steward updates missing or thin community product docs.
2. Worker Agent implements or remediates UI against those docs.
3. Evidence Collector captures fresh workflow/persona screenshots, visible text, hashes, timestamps,
   device metadata, and app commit SHA.
4. Independent UX Judge reviews only Product Docs, screenshots, visible text, scorecards, and pass
   criteria.
5. Production UX Judge validates schema v4 evidence and emits remediation tickets.
6. Remediation Planner turns tickets into product-spec, evidence, and UI batches.
7. Iteration scorecard records pass/fail counts, new issues, resolved blocker/major issues, and
   convergence.
8. Commit the iteration before the next UX feedback loop.

## Community Coverage

The B25 collector writes `productDocCoverage` into `independent-production-ux-review.json`. A row
passes only when the doc exists, has all required sections, contains no placeholders, is not thin, maps
workflows to domain-native product surfaces, and has a B25 review/remediation log.
