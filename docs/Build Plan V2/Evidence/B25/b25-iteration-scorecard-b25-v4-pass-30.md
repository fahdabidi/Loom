# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-30` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 16 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 16 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 16 | 16 | 0 |
| Minor | 1 | n/a | n/a |
| Polish | 0 | n/a | n/a |

## Judge Summary

| Field | Value |
| --- | --- |
| Judge status | `fail` |
| Criteria passed | 7 / 16 |
| Blocking criterion failures | 9 |
| Holistic direct-question pass | `false` |
| Workflow/persona direct-question pass | `false` |

## Blocking Findings

| Finding | Severity | Status | Required fix |
| --- | --- | --- | --- |
| `B25-LLM-VISION-001-GLOBAL-REPEATED-CARD-SCAFFOLD` | major | open | Replace the generic renderer with distinct production IA and component families per domain surface: event detail pages, real roster tables/lists with editable role/redaction controls, payment checkout and receipt screens, export wizard/progress/rollback screens, message thread/inbox surfaces, announcement composer/inbox surfaces, and care/request queues. Recapture every affected workflow after the UI proves distinct surface structure, hierarchy, and lifecycle state from screenshots. |
| `B25-LLM-VISION-002-AD-OFF-CHECKOUT-USES-SPONSORED-MESSAGE-CONTEXT` | major | open | Build focused ad-off checkout/entitlement/settlement/receipt screens. The action/review screenshots must center amount, payer, payment method, plan/entitlement scope, renewal or settlement status, receipt ID, manage/cancel/restore/retry actions, and confirmation/history. Sponsored-message previews can be secondary evidence only after the payment or entitlement decision is visually primary. |
| `B25-LLM-VISION-003-PROTECTED-REDACTION-LACKS-REQUIRED-YOUTH-GUARDIAN-PROOF` | major | open | Update the protected redaction surface to show concrete protected records and role visibility: youth/minor or protected profile rows, source value vs exported safe value, policy reason, guardian/coach/owner reveal permissions, redaction count, checksum, and export/download/transfer state. Recapture entry/action/result screens that visibly prove these required groups. |
| `B25-LLM-VISION-004-PERSONA-PICKER-EXPOSES-HARNESS-LANGUAGE` | major | open | Replace the visible harness language with production account/member-role UX or remove it from product-surface review evidence. If role selection remains in local demo evidence, label it as test harness evidence outside the user-facing production surface inventory; otherwise show a member/account settings surface with natural copy, role status, permissions, and request-access/help actions. |
| `B25-LLM-VISION-005-WORKFLOW-LIFECYCLE-GAPS-STILL-BLOCK-PRODUCTION-UX` | major | open | For each failing workflow, add screenshot-visible concrete object/context, decision information, semantic primary action, domain-required alternate/change/reject/defer path, and persistent result or receiver state. Recapture start/action/result/receiver screens and rerun the lifecycle judge. |
| `B25-LLM-VISION-006-DIMMED-ACTION-CONTENT-LOW-CONTRAST` | major | open | Remove the dark disabled-overlay treatment for content that users must read, or restyle it with accessible contrast and clear active/disabled states. Action/review screens should keep decision data and alternate actions readable without relying on OCR-derived text. |
| `LLM-B25-WR-001` | major | open | Implement and recapture the roster lifecycle the doc requires: coach update/save or waiver action, edit/request-guardian-update/redact/undo alternate path, roster history, and guardian receiver/read-only state. The current screenshots prove roster viewing/opening, not the documented roster management interaction model. |
| `LLM-B25-WR-002` | major | open | Add concrete donation amount/fund context, explicit saved visibility preference, receipt visibility, and change path to the donor-visibility screenshots, then recapture. The current evidence uses generic care/privacy labels and does not visibly prove the amount/fund requirement in the product doc. |
| `LLM-B25-WR-003` | major | open | Recapture a ballot surface that visibly lists the candidate books, selected/winning state, recorded vote result, and change-vote path. The result screenshot records Parable of the Sower, but the required candidate comparison and selected/winning state are under-proven. |
| `LLM-B25-WR-004` | major | open | Replace the generic semantic row with a knowledge-search model matching the documented and visible surface: query, answer, citations/source visibility, save/share digest, follow-up prompts, stale-citation/refresh handling, and durable saved digest state. |
| `LLM-B25-WR-005` | major | open | Replace the generic submit/save/send semantic row with an HOA notice model: sender/audience/body/delivery timing, send notice, edit audience/body, cancel/defer delivery, sent/read receipt, owner inbox receiver state, and appeal/follow-up state. |
| `LLM-B25-WR-006` | major | open | Remove payment-surface labels from platform ad/no-fill surfaces and recapture ad-native surfaces with the documented actions: reserved/no-fill state, policy or no-fill inspection, hide/report/dismiss where applicable, and stable layout without cross-surface payment terminology. |
| `LLM-B25-WR-007` | major | open | Align the product doc semantic model and B25 review target with the entitlement-status surface instead of a generic payment/donation surface. If price is required, add it to Section 6 and the UI; otherwise stop scoring this workflow against payment amount proof and recapture against active state, renewal/expiry, managed subscription, affected ad surfaces, receipt link, restore/manage path. |
| `LLM-B25-WR-008` | major | open | Make the settlement row and UI settlement-specific: funded amount, settlement ID, member/payer or plan context, utility impact, audit status, correction/rollback path, and owner/settlement receiver state. The current screenshot has amount and utility allocation but no settlement ID and the semantic row is still a generic payment template. |
| `LLM-B25-WR-009` | major | open | Repair the B25 evidence/review mapping for this workflow: the current review scorecard fails it for missing youth/minor/guardian proof, but the product doc defines a data-portability redaction preview with protected fields, policy reasons, before/after preview, checksum/audit, and owner artifact. Keep the product doc source of truth and rerun the scorecard against the correct redaction criteria. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
