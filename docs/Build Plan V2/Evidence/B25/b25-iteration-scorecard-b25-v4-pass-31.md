# B25 Iteration Scorecard

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-31` |
| Status | `fail` |
| Final decision | `fail` |
| B25 can pass | `false` |
| Remaining critical/blocker + major | 20 |
| Resolved critical/blocker + major this pass | 0 |
| New critical/blocker + major this pass | 20 |

## Finding Counts

| Severity | Total | Unresolved | Resolved |
| --- | ---: | ---: | ---: |
| Critical/blocker | 0 | 0 | 0 |
| Major | 20 | 20 | 0 |
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
| `LLM-B25-VISION-001` | major | open | Replace the repeated stacked-card shell with differentiated product surfaces for each community and workflow, then recapture B25 screenshots and rerun the LLM vision review. |
| `LLM-B25-VISION-002` | major | open | Convert utility-looking evidence panels into full product flows with concrete records, tables, previews, and task-specific controls before B25 can pass. |
| `LLM-B25-VISION-003` | major | open | Redesign action, decision, review, and confirmation states so they are clear production interaction surfaces, not dimmed evidence overlays. |
| `LLM-B25-VISION-004` | major | open | Raise visual identity and product-surface depth across all communities before another B25 review. |
| `LLM-B25-WR-001` | major | open | The docs require a coach roster management lifecycle with roster rows, protected minor fields, waiver/status history, edit/request-guardian-update/redact/undo paths, and guardian receiver state. Current rows prove viewing/opening/filtering/exporting the roster, while the current lifecycle scorecard still fails primary semantic action, alternate/change/reject affordance, and semantic interaction model. Add a concrete roster update/save/waiver action, a real edit or undo/redaction alternate path, and a guardian continuation/receiver state, then recapture. |
| `LLM-B25-WR-002` | major | open | The docs require visibility choice, amount/fund context, receipt visibility, saved preference, visibility history, and a change path. Current screenshots show an anonymous donor preference and saved record, but the current lifecycle scorecard fails persistent result state; the result state does not make the durable chosen visibility/history/receipt visibility concrete enough for later review. Add explicit saved visibility value, receipt visibility, timestamp/history, and change/manage state, then recapture. |
| `LLM-B25-WR-003` | major | open | The docs require candidates, selected/voted result, change/clear vote path, and member receiver state. Current screenshots show candidates and a saved vote, but the current lifecycle scorecard still fails persistent result state. Strengthen the result screen with a durable ballot receipt/audit state, selected title, close/deadline state, and organizer/member continuation state, then recapture. |
| `LLM-B25-WR-004` | major | open | The visible UI implements a cited reading-guide flow with query, answer, source snippets, source visibility, open sources, refine query, save/share/follow-up actions, and saved guide state. The product doc semantic row still uses the generic submit/save/send model and generic result wording, so the docs do not fully specify the workflow visible in screenshots. Update Sections 6-8 and the B25 semantic/card-surface rows to name the cited-answer lifecycle, concrete primary and alternate actions, saved digest result, stale/private-source handling, and receiver/continuation state before judging implementation complete. |
| `LLM-B25-WR-005` | major | open | The docs require RSVP choice/result plus capacity or attendee state updates and continuation/receiver state. Current screenshots show event details, Going confirmation, and change response, but the lifecycle scorecard fails receiver/continuation state and the capacity/attendee value is not visibly updated after RSVP. Add the post-RSVP attendee/capacity update, reminder/inbox continuation, or receiver state required by the doc, then recapture. |
| `LLM-B25-WR-006` | major | open | The screenshots show a concrete owner notice flow with sender, recipient, body, delivery time, edit notice, save draft, change audience, send notification, delivered state, inbox receipt, and appeal/reopen follow-up. The B25 semantic row is still the generic submit/save/send template, so the product doc does not fully specify the lifecycle now visible in evidence. Replace the generic semantic model with owner-notice-specific decision data, primary send action, edit/save-draft/change-audience alternatives, delivery result, and owner receiver/read state. |
| `LLM-B25-WR-007` | major | open | The docs require named route/date/location/capacity, RSVP choice, change path, and confirmed state. Current screenshots prove route/event detail and action choices, but the current lifecycle scorecard fails persistent result state; the completion screen says RSVP saved without a concrete selected response and later reminder/calendar or capacity continuation. Show the selected attendance value, durable confirmation, change-until deadline, and reminder/capacity continuation state, then recapture. |
| `LLM-B25-WR-008` | major | open | The docs require blocked member, reason/status, disabled message/invite state, unblock/appeal/keep-blocked or cancel-invite alternatives, safety audit, and protected receiver state. Current screenshots show the blocked guard and disabled send, but the current lifecycle scorecard fails alternate/change/reject affordance and semantic model; the action row exposes reply/mute/archive rather than the documented unblock/appeal/keep-blocked/cancel-invite choices. Add the documented safety alternatives and receiver protection state, then recapture. |
| `LLM-B25-WR-009` | major | open | The docs specify a top-banner no-fill surface with reserved space, no-fill reason, no click/impression state, refresh-slot or inspect-reason alternative, and stable layout. Current screenshots prove the reserved slot, but the action row mixes unrelated ad-off entitlement, receipt, report, and restore controls and the lifecycle scorecard fails alternate/semantic model. Either document those extra ad-off controls for this workflow or remove them from the no-fill flow; in either case show the refresh/inspect no-fill alternative and recapture. |
| `LLM-B25-WR-010` | major | open | The docs require participants, preview/body, timestamp, reply/mark-read/mute/archive state, and sender/receiver delivery/read continuation. Current screenshots show the thread and actions, but the current lifecycle scorecard fails persistent result state; the completion state does not sufficiently prove a durable reply/read history and receiver continuation beyond a generic thread-updated message. Add explicit read/delivery or reply-history state tied to sender/recipient, then recapture. |
| `LLM-B25-WR-011` | major | open | The docs require protected context, privacy-safe no-fill reason, no-click state, preserved content layout, and review-policy or hide-explanation alternatives. Current rows show sensitive no-fill, but the action screen switches into sponsored-message/ad-off account controls such as manage entitlement, report ad issue, and restore receipt. The lifecycle scorecard fails alternate/semantic model. Align the UI and docs around the sensitive no-fill policy interaction, add the documented policy/hide alternative, and recapture. |
| `LLM-B25-WR-012` | major | open | The docs require sponsor identity, disclosure, body/content context, impression/click state, and report/dismiss/hide or continue controls. Current screenshots show sponsor and report/open details, but the lifecycle scorecard fails alternate/semantic model and the result state is only reviewed. Add visible dismiss/hide/report alternatives, preserve stream position, and show the resulting impression/click/dismiss state, then recapture. |
| `LLM-B25-WR-013` | major | open | The product doc maps this workflow to ad suppression proof and the B25 registry maps it to an ad surface / CommunityAdSurfaceApi. Current screen rows classify it as payment / CommunityPaymentSurfaceApi with target surface requiring amount, so the workflow/persona scorecard fails missing amount even though the visible UI is an ad-suppression proof. Align the evidence/card-surface mapping and semantic model to the documented ad suppression surface, or explicitly update the doc if a payment amount is truly required, then recapture. |
| `LLM-B25-WR-014` | major | open | The product doc maps entitlement status to active/inactive state, renewal/expiry, managed subscription, affected ad surfaces, and the ad-off entitlement / CommunityAdSurfaceApi registry. Current rows classify it as payment / CommunityPaymentSurfaceApi with a payment amount requirement, causing the scorecard to fail despite visible entitlement status. Align the card-surface/target mapping to entitlement status or revise the doc if payment amount is required on this screen, then recapture. |
| `LLM-B25-WR-015` | major | open | Current screenshots show protected values, policy reasons, before/after preview, audit trail, change scope, retry, and generate export. The current workflow/persona semantic proof still fails because it expects concrete protected subject/persona terms such as protected youth/minor profile and guardian/coach visibility, while the product doc only specifies generic protected fields/redaction choices. Make the source of truth concrete: either update the product doc/seed requirements to name the protected record classes and reveal personas the proof expects, or update the evidence mapping to the generic Data Portability protected-field model, then recapture. |
| `B25-WORKFLOW-LIFECYCLE-INCOMPLETE` | major | open | Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence. |

## Required Next Action

Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.
