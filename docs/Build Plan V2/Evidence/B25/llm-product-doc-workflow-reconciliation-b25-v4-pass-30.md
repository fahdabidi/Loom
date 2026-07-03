# B25 Product Docs To Evidence Workflow Reconciliation - b25-v4-pass-30

## Decision

Final decision: fail.

This is a fresh LLM product-doc workflow reconciliation for run b25-v4-pass-30 at app commit 066b7dd. I reviewed 12 product experience docs, 195 B25 screen rows, 195 screenshot hashes, the current independent production UX review JSON, the screen review matrix, workflow/persona coverage matrix, B25 lifecycle scorecards, visual audit, and B12-B20 workflow UI manifests.

Severity counts: blockers 0, majors 9, minors 1.
Communities reviewed: 12 total, 5 pass, 7 fail.

## Product Doc Rows Missing Evidence

No Section 6 workflow row is completely missing B25 screenshot rows. The shell doc explicitly scopes local-build-download-sideload-install out of B25 community screenshot reconciliation.

## Evidence Rows Missing Product Doc Coverage

No captured workflow ID is wholly absent from the reviewed Product Docs V2 community experience docs. The unresolved failures are mismatches between documented required proof, companion B25 semantic/card-surface rows, current review target metadata, and what the screenshots visibly prove.

## Product-Doc Sections To Update

- docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md: replace the generic book-search-ai-digest B25 semantic row with a knowledge-search model.
- docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md: replace the generic hoa-owner-notification B25 semantic row with a notification-specific lifecycle.
- docs/Product Docs V2/Community Examples/ad-off-product-experience.md: reconcile Section 6, B25 semantic rows, and card-surface mapping for ad-off-entitlement-status and ad-off-settlement-utility; the current semantic/review targets still behave like generic payment templates.

## UI, Evidence, Or Mapping Gaps

- Riverside Youth Soccer soccer-team-roster: screenshots prove roster viewing/opening, but not the documented coach update/save, waiver, alternate edit/request/redact/undo path, roster history, or guardian receiver state.
- Masjid Nur mosque-donor-visibility: screenshots do not visibly prove concrete donation amount/fund context and saved visibility state required by Section 6 and the semantic row.
- Neighborhood Book Club book-vote: screenshots record a vote, but under-prove candidate comparison and selected/winning state.
- Member Social Space ad/no-fill surfaces: screenshots expose Payment summary on platform ad surfaces, diverging from the social/ad product doc.
- Ad-Free Community ad-off-settlement-utility: screenshots show amount and utility allocation, but not a settlement ID or payer/member/plan context; the semantic row is still generic payment language.
- Data Portability Community export-protected-redaction: the screenshots match the product doc protected redaction preview, but the current review scorecard fails it for youth/minor/guardian proof from another domain. The B25 evidence/review mapping must be repaired and rerun.

## Ticket-Ready Findings

| Finding | Severity | Community | Workflow | Persona | Screen rows | Required fix |
| --- | --- | --- | --- | --- | --- | --- |
| LLM-B25-WR-001 | major | Riverside Youth Soccer | soccer-team-roster | coach | b25-v4-row-016-soccer-team-roster-0, b25-v4-row-017-soccer-team-roster-1, b25-v4-row-018-soccer-team-roster-2 | Implement and recapture the roster lifecycle the doc requires: coach update/save or waiver action, edit/request-guardian-update/redact/undo alternate path, roster history, and guardian receiver/read-only state. The current screenshots prove roster viewing/opening, not the documented roster management interaction model. |
| LLM-B25-WR-002 | major | Masjid Nur | mosque-donor-visibility | donor | b25-v4-row-028-mosque-donor-visibility-0, b25-v4-row-029-mosque-donor-visibility-1, b25-v4-row-030-mosque-donor-visibility-2 | Add concrete donation amount/fund context, explicit saved visibility preference, receipt visibility, and change path to the donor-visibility screenshots, then recapture. The current evidence uses generic care/privacy labels and does not visibly prove the amount/fund requirement in the product doc. |
| LLM-B25-WR-003 | major | Neighborhood Book Club | book-vote | member | b25-v4-row-034-book-vote-0, b25-v4-row-035-book-vote-1, b25-v4-row-036-book-vote-2 | Recapture a ballot surface that visibly lists the candidate books, selected/winning state, recorded vote result, and change-vote path. The result screenshot records Parable of the Sower, but the required candidate comparison and selected/winning state are under-proven. |
| LLM-B25-WR-004 | major | Neighborhood Book Club | book-search-ai-digest | member | b25-v4-row-037-book-search-ai-digest-0, b25-v4-row-038-book-search-ai-digest-1, b25-v4-row-039-book-search-ai-digest-2 | Replace the generic semantic row with a knowledge-search model matching the documented and visible surface: query, answer, citations/source visibility, save/share digest, follow-up prompts, stale-citation/refresh handling, and durable saved digest state. |
| LLM-B25-WR-005 | major | Cedar Commons HOA | hoa-owner-notification | owner | b25-v4-row-088-hoa-owner-notification-0, b25-v4-row-089-hoa-owner-notification-1, b25-v4-row-090-hoa-owner-notification-2 | Replace the generic submit/save/send semantic row with an HOA notice model: sender/audience/body/delivery timing, send notice, edit audience/body, cancel/defer delivery, sent/read receipt, owner inbox receiver state, and appeal/follow-up state. |
| LLM-B25-WR-006 | major | Member Social Space | platform-ad-surfaces | member | b25-v4-row-121-platform-top-banner-no-fill-0, b25-v4-row-122-platform-top-banner-no-fill-1, b25-v4-row-123-platform-top-banner-no-fill-2, b25-v4-row-145-platform-sensitive-no-fill-0, b25-v4-row-146-platform-sensitive-no-fill-1, b25-v4-row-147-platform-sensitive-no-fill-2, b25-v4-row-166-platform-in-stream-ad-0, b25-v4-row-167-platform-in-stream-ad-1, b25-v4-row-168-platform-in-stream-ad-2 | Remove payment-surface labels from platform ad/no-fill surfaces and recapture ad-native surfaces with the documented actions: reserved/no-fill state, policy or no-fill inspection, hide/report/dismiss where applicable, and stable layout without cross-surface payment terminology. |
| LLM-B25-WR-007 | major | Ad-Free Community | ad-off-entitlement-status | member | b25-v4-row-148-ad-off-entitlement-status-0, b25-v4-row-149-ad-off-entitlement-status-1, b25-v4-row-150-ad-off-entitlement-status-2 | Align the product doc semantic model and B25 review target with the entitlement-status surface instead of a generic payment/donation surface. If price is required, add it to Section 6 and the UI; otherwise stop scoring this workflow against payment amount proof and recapture against active state, renewal/expiry, managed subscription, affected ad surfaces, receipt link, restore/manage path. |
| LLM-B25-WR-008 | major | Ad-Free Community | ad-off-settlement-utility | member | b25-v4-row-151-ad-off-settlement-utility-0, b25-v4-row-152-ad-off-settlement-utility-1, b25-v4-row-153-ad-off-settlement-utility-2 | Make the settlement row and UI settlement-specific: funded amount, settlement ID, member/payer or plan context, utility impact, audit status, correction/rollback path, and owner/settlement receiver state. The current screenshot has amount and utility allocation but no settlement ID and the semantic row is still a generic payment template. |
| LLM-B25-WR-009 | major | Data Portability Community | export-protected-redaction | owner | b25-v4-row-154-export-protected-redaction-0, b25-v4-row-155-export-protected-redaction-1, b25-v4-row-156-export-protected-redaction-2 | Repair the B25 evidence/review mapping for this workflow: the current review scorecard fails it for missing youth/minor/guardian proof, but the product doc defines a data-portability redaction preview with protected fields, policy reasons, before/after preview, checksum/audit, and owner artifact. Keep the product doc source of truth and rerun the scorecard against the correct redaction criteria. |
| LLM-B25-WR-010 | minor | Ad-Free Community | ad-off-settlement-utility | member | b25-v4-row-151-ad-off-settlement-utility-0, b25-v4-row-152-ad-off-settlement-utility-1, b25-v4-row-153-ad-off-settlement-utility-2, b25-v4-row-166-platform-in-stream-ad-0, b25-v4-row-167-platform-in-stream-ad-1, b25-v4-row-168-platform-in-stream-ad-2 | Fix visible product-copy defects such as "Settlement detailsed" and "Sponsored message detailsed" before a polish pass; they conflict with the product docs visual/interaction standard for trust-first, product-native language. |

## Reviewed Artifacts

Product docs reviewed:

- docs/Product Docs V2/Community Examples/ad-off-product-experience.md
- docs/Product Docs V2/Community Examples/camera-club-product-experience.md
- docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md
- docs/Product Docs V2/Community Examples/chess-club-product-experience.md
- docs/Product Docs V2/Community Examples/export-and-migration-product-experience.md
- docs/Product Docs V2/Community Examples/garden-club-product-experience.md
- docs/Product Docs V2/Community Examples/loom-communities-shell-product-experience.md
- docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md
- docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md
- docs/Product Docs V2/Community Examples/persona-role-inventory-product-experience.md
- docs/Product Docs V2/Community Examples/platform-social-product-experience.md
- docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md

Evidence reviewed:

- docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md
- docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json
- docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md
- docs/Build Plan V2/Evidence/B25/workflow-persona-coverage-matrix.md
- docs/Build Plan V2/Evidence/B25/b25-workflow-lifecycle-scorecards.md
- docs/Build Plan V2/Evidence/B25/b25-visual-inspection-audit.md
- docs/Build Plan V2/Evidence/B12/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B13/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B14/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B15/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B16/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B17/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B18/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B19/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B20/workflow-ui-evidence.json
- docs/Build Plan V2/Evidence/B20/all-workflow-ui-evidence.json
