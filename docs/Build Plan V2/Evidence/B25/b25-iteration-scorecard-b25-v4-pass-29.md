# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-29` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 11 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 11 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 1 | 1 | 0 |
| Major | 10 | 10 | 0 |
| Minor | 0 | n/a | n/a |
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
| `llm-b25-p29-blocker-generic-action-review-checklist` | critical-blocker | unresolved | Replace the shared action/review checklist renderer with domain-specific decision screens. Each affected workflow must show the concrete object, decision data, natural primary action, real alternate/change/reject path, and a durable result/receiver state using copy specific to that community task. Remove the generic Decision/Change-or-reject/Saved-status checklist text from user-facing UI and recapture entry/action/result screenshots. |
| `llm-b25-p29-major-payment-summary-used-as-generic-container` | major | unresolved | Route non-payment workflows to their documented product surfaces. Facility reservation needs facility/date/status and reserve/cancel state; announcements need body/sender/audience/timing/draft or sent state; ad/no-fill screens need sponsor/disclosure/no-fill layout proof; neutral notification needs sender/body/timestamp/read state. Keep payment summaries only for real payment, dues, checkout, donation, receipt, settlement, entitlement, or registration-payment flows. |
| `llm-b25-p29-major-export-surfaces-too-generic` | major | unresolved | Create a true export/portability workspace with selected scope, included objects, redaction preview, destination/provider, file count/size, checksum, verification state, download/transfer controls, retry/cancel/rollback controls, and audit trail. Avoid repeating the same stepper card as the primary UI for all export workflows. |
| `llm-b25-p29-major-persona-handoff-not-production-grade` | major | unresolved | Keep any local persona switcher clearly outside the production community surface or restyle it as account settings. For multi-persona evidence, show the admin-created announcement, then a member inbox/detail screen with sender, body, timestamp, read/received state, and member-native actions such as Open, Mark read, Archive, or Ask follow-up. Remove synthetic "Receive announcement" copy from the member action surface. |
| `llm-b25-p29-major-repeated-card-visual-fatigue` | major | unresolved | Introduce domain-specific layouts and information architecture per surface family: event detail pages, announcement composer/feed/inbox, donation/payment receipt, protected request form, roster/schedule views, document center, message thread, ad/no-fill placement, and export wizard. Vary layout, hierarchy, density, and actions by job while preserving shell consistency. Reduce card nesting, improve contrast, and make primary content visible without repetitive framework panels. |
| `LLM-B25-WR-001` | major | open | Resolve the export redaction criteria drift before the next judge pass: either update the product doc and seed content to require a concrete protected-person/guardian visibility example and capture that UI, or repair/re-run the evidence mapping so export-protected-redaction is judged against export-specific protected fields, redaction choices, preview, and audit state. |
| `LLM-B25-WR-002` | major | open | Implementation/evidence remediation: make the result screen unambiguously show the selected RSVP state as confirmed/attending or not attending, preserve the change-response path, update attendee/capacity context, and recapture the three workflow screenshots so the lifecycle scorecard passes persistent result state. |
| `LLM-B25-WR-003` | major | open | Implementation/evidence remediation: show the saved donor visibility setting, receipt destination/visibility, amount context, status/history or account result, and the available change path on the result state, then recapture the donor workflow screenshots. |
| `LLM-B25-WR-004` | major | open | Implementation/evidence remediation: make the completed vote state durable and specific, including selected title, voted status, whether the ballot remains open/changed, and organizer/aggregate continuation state, then recapture the workflow evidence. |
| `LLM-B25-WR-005` | major | open | Implementation/evidence remediation: show a persistent message-thread result such as sent/received/read state, reply history, archive or mute state, and recipient/thread continuation state, then recapture the workflow screenshots. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
