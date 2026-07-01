# B25 Remediation Plan

| Field | Value |
| --- | --- |
| Review run | `b25-v4-pass-22` |
| Status | `open` |
| Source tickets | `../docs/Build Plan V2/Evidence/B25/b25-remediation-tickets-b25-v4-pass-22.json` |
| Ticket count | 9 |
| Scorecard status | `fail` |
| Remaining blocker/major | 6 |
| Blocking criteria failures | 9 |
| Product spec work items | 3 |
| Evidence repair work items | 17 |
| UI remediation work items | 18 |
| Work item sequencing | Product-spec work items must close first, then evidence repair work items, then matching UI remediation work items. |

## Source Tickets

| Ticket | Source criterion | Severity | Status | Title |
| --- | --- | --- | --- | --- |
| `B25-RT-001-b25-c01-no-blocker-major` | `b25-c01-no-blocker-major` | major | open | No unresolved blocker or major findings |
| `B25-RT-002-b25-c03-production-grade-experience` | `b25-c03-production-grade-experience` | major | open | Reviewer can state the experience feels production-grade |
| `B25-RT-003-b25-c14-llm-vision-ux-review` | `b25-c14-llm-vision-ux-review` | major | open | LLM vision UX judge has inspected screenshots semantically |
| `B25-RT-004-b25-c04-modern-intentional-ui` | `b25-c04-modern-intentional-ui` | major | open | UI looks modern and intentionally designed |
| `B25-RT-005-b25-c05-community-content-ia` | `b25-c05-community-content-ia` | major | open | Screens are organized around community content and jobs-to-be-done |
| `B25-RT-006-b25-c06-domain-native-primary-surfaces` | `b25-c06-domain-native-primary-surfaces` | major | open | Primary workflows use domain-specific product surfaces |
| `B25-RT-007-b25-c13-workflow-lifecycle-complete` | `b25-c13-workflow-lifecycle-complete` | major | open | Every primary workflow has complete lifecycle UX |
| `B25-RT-008-b25-c08-visible-text-specific-critique` | `b25-c08-visible-text-specific-critique` | major | open | Every row has visible text and screen-specific critique |
| `B25-RT-009-b25-c09-no-layout-production-defects` | `b25-c09-no-layout-production-defects` | major | open | No blocking or major layout/content defects remain |

## B25-RB-001-independent-review-evidence: Complete independent review evidence and critique

Turn captured screenshots into complete independent UX review evidence before attempting UI remediation.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-002-b25-c03-production-grade-experience, B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-008-b25-c08-visible-text-specific-critique, B25-RT-009-b25-c09-no-layout-production-defects |

### Worker Actions
- Fill holistic direct-question answers with screenshot-grounded yes/no/partial judgments.
- Fill every screen row with visible text and screen-specific critique.
- Fill workflow/persona scorecards for every reviewed workflow/persona pair.
- Resolve every evidenceRepairWorkItem before assigning UI implementation work for that same community/workflow/persona.
- Keep reviewer context limited to screenshots, blueprint, evidence, and pass criteria.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.
- Update the B25 judge/review artifact, not only app UI code.
- Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowPersonaScorecards` with screenshot-specific content.
- Regenerate markdown review and matrix files from the updated schema v4 JSON.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`
- `app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter payment-donation mobile UI example GitHub
- payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile UX pattern
- Material Design payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile pattern
- government design system payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail form review confirmation pattern
- open source Flutter form-review mobile UI example GitHub
- protected care request form and private response/status surface mobile UX pattern
- Material Design protected care request form and private response/status surface mobile pattern
- government design system protected care request form and private response/status surface form review confirmation pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- request detail and admin review queue with submitted data, decision action, status, and notification mobile UX pattern
- Material Design request detail and admin review queue with submitted data, decision action, status, and notification mobile pattern
- government design system request detail and admin review queue with submitted data, decision action, status, and notification form review confirmation pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern

### Evidence Repair Work Items

Showing 17 of 17 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donation-payment-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-mosque-care-request-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-care-request` | member | 3 | 1 | protected care request form and private response/status surface |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-camera-club-gear-loan-request-community-camera-club-member` | `evidence-repair` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connections-entry-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connection-invite-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-blocked-target-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |  |
| `b25-wi-evidence-repair-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-member-checkout-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-member-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-community-checkout-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-community-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-receipt-evidence-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-receipt-evidence` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-ad-suppression-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-ad-suppression` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Affected Coverage Rows

Showing 17 of 17 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor |  |
| `b25-wp-029-mosque-donation-payment-community-mosque-donor` | Masjid Nur | `mosque-donation-payment` | donor |  |
| `b25-wp-030-mosque-care-request-community-mosque-member` | Masjid Nur | `mosque-care-request` | member |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-040-platform-connections-entry-community-platform-social-member` | Member Social Space | `platform-connections-entry` | member |  |
| `b25-wp-041-platform-connection-invite-community-platform-social-member` | Member Social Space | `platform-connection-invite` | member |  |
| `b25-wp-042-platform-blocked-target-community-platform-social-member` | Member Social Space | `platform-blocked-target` | member |  |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member |  |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member |  |
| `b25-wp-047-ad-off-member-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-member-checkout` | member |  |
| `b25-wp-048-ad-off-community-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-community-checkout` | member |  |
| `b25-wp-049-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-050-ad-off-receipt-evidence-community-ad-off-member` | Ad-Free Community | `ad-off-receipt-evidence` | member |  |
| `b25-wp-051-ad-off-ad-suppression-community-ad-off-member` | Ad-Free Community | `ad-off-ad-suppression` | member |  |
| `b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin |  |
| `b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member |  |

### Affected Screen Rows

Showing 30 of 54 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-087-mosque-donation-payment-2` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-090-mosque-care-request-2` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-112-gear-loan-request-0` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_start | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-113-gear-loan-request-1` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_action | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-114-gear-loan-request-2` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_complete | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-118-platform-connections-entry-0` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-119-platform-connections-entry-1` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-120-platform-connections-entry-2` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-121-platform-connection-invite-0` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-122-platform-connection-invite-1` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-123-platform-connection-invite-2` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-124-platform-blocked-target-0` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-125-platform-blocked-target-1` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-126-platform-blocked-target-2` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-133-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-134-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-135-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-136-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-137-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-138-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-139-ad-off-member-checkout-0` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-140-ad-off-member-checkout-1` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-141-ad-off-member-checkout-2` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_complete | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-142-ad-off-community-checkout-0` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-143-ad-off-community-checkout-1` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-144-ad-off-community-checkout-2` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_complete | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-145-ad-off-entitlement-status-0` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-146-ad-off-entitlement-status-1` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |

### Evidence To Update
- independent-production-ux-review.json holisticQuestionAnswers
- independent-production-ux-review.md holistic review summary
- product-ux-screen-review-matrix.md relevant screen rows
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json workflowPersonaScorecards
- independent-production-ux-review.json screenRows
- product-ux-screen-review-matrix.md every workflow/persona row
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.
- Visible text extracts for every reviewed row.
- Non-boilerplate screen-specific critique for every reviewed row.
- Updated markdown matrix matching the JSON evidence.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-084-mosque-donor-visibility-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-084-mosque-donor-visibility-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-084-mosque-donor-visibility-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Primary surface for `mosque-donor-visibility` is documented as `donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donor-visibility`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-087-mosque-donation-payment-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-087-mosque-donation-payment-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-087-mosque-donation-payment-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donation-payment`, and the exact product UX issue.
- Primary surface for `mosque-donation-payment` is documented as `payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donation-payment`.
- Screen row `b25-v4-row-090-mosque-care-request-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-090-mosque-care-request-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-090-mosque-care-request-2` names visible UI elements, visible text, persona `member`, workflow `mosque-care-request`, and the exact product UX issue.
- Primary surface for `mosque-care-request` is documented as `protected care request form and private response/status surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-care-request`.
- Screen row `b25-v4-row-093-mosque-neutral-notification-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-093-mosque-neutral-notification-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-093-mosque-neutral-notification-2` names visible UI elements, visible text, persona `member`, workflow `mosque-neutral-notification`, and the exact product UX issue.
- Primary surface for `mosque-neutral-notification` is documented as `notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-neutral-notification`.
- Screen row `b25-v4-row-112-gear-loan-request-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-112-gear-loan-request-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-112-gear-loan-request-0` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Primary surface for `gear-loan-request` is documented as `request detail and admin review queue with submitted data, decision action, status, and notification` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `gear-loan-request`.
- Screen row `b25-v4-row-113-gear-loan-request-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-113-gear-loan-request-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-113-gear-loan-request-1` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Screen row `b25-v4-row-114-gear-loan-request-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-114-gear-loan-request-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-114-gear-loan-request-2` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Screen row `b25-v4-row-118-platform-connections-entry-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-118-platform-connections-entry-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-118-platform-connections-entry-0` names visible UI elements, visible text, persona `member`, workflow `platform-connections-entry`, and the exact product UX issue.
- Primary surface for `platform-connections-entry` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

### Commit Boundary

Commit this remediation batch, refreshed evidence, judge outputs, scorecards, and tracker updates before the next UX feedback loop. If the committed pass still fails, the following pass starts by sending its tickets to the Remediation Planner.

## B25-RB-002-domain-native-ux-remediation: Remediate domain-native IA and primary workflow surfaces

Apply product UX fixes found by the independent critique so primary screens feel like production community surfaces.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-005-b25-c05-community-content-ia, B25-RT-006-b25-c06-domain-native-primary-surfaces, B25-RT-009-b25-c09-no-layout-production-defects |

### Worker Actions
- Start only after the matching evidenceRepairWorkItems have concrete personas, screenshot-derived visible text, and screen-specific critiques.
- Replace any primary global workflow lists, metadata pages, checklist modals, or repeated generic cards with domain-native surfaces.
- Rebuild primary homes and flows around community content and jobs-to-be-done.
- Improve hierarchy, spacing, typography, component quality, navigation clarity, and mobile layout.
- Update copy/content so visible UI speaks to the target persona and task, not to validation mechanics.

### Implementation Guidance
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.
- Inspect workflow surface builders and replace primary generic card/checklist/modal renderers with task-specific widgets.
- Use B21 production UX contracts to choose the target surface type for each workflow/persona pair.
- Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Reference Research Queries
- modern mobile app information architecture visual hierarchy examples
- Material Design 3 mobile UI hierarchy navigation cards examples
- open source Flutter production app dashboard detail screen examples
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter payment-donation mobile UI example GitHub
- payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile UX pattern
- Material Design payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile pattern
- government design system payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail form review confirmation pattern
- open source Flutter form-review mobile UI example GitHub
- protected care request form and private response/status surface mobile UX pattern
- Material Design protected care request form and private response/status surface mobile pattern
- government design system protected care request form and private response/status surface form review confirmation pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- request detail and admin review queue with submitted data, decision action, status, and notification mobile UX pattern
- Material Design request detail and admin review queue with submitted data, decision action, status, and notification mobile pattern
- government design system request detail and admin review queue with submitted data, decision action, status, and notification form review confirmation pattern
- open source Flutter message-thread mobile UI example GitHub

### UI Remediation Work Items

Showing 18 of 18 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-care-request` | member | 3 | 1 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-gear-loan-request-community-camera-club-member` | `ui-remediation` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connections-entry-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connection-invite-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-blocked-target-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-member-checkout-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-member-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-community-checkout-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-community-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-receipt-evidence-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-receipt-evidence` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-ad-suppression-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-ad-suppression` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Affected Coverage Rows

Showing 17 of 17 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor |  |
| `b25-wp-029-mosque-donation-payment-community-mosque-donor` | Masjid Nur | `mosque-donation-payment` | donor |  |
| `b25-wp-030-mosque-care-request-community-mosque-member` | Masjid Nur | `mosque-care-request` | member |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-040-platform-connections-entry-community-platform-social-member` | Member Social Space | `platform-connections-entry` | member |  |
| `b25-wp-041-platform-connection-invite-community-platform-social-member` | Member Social Space | `platform-connection-invite` | member |  |
| `b25-wp-042-platform-blocked-target-community-platform-social-member` | Member Social Space | `platform-blocked-target` | member |  |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member |  |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member |  |
| `b25-wp-047-ad-off-member-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-member-checkout` | member |  |
| `b25-wp-048-ad-off-community-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-community-checkout` | member |  |
| `b25-wp-049-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-050-ad-off-receipt-evidence-community-ad-off-member` | Ad-Free Community | `ad-off-receipt-evidence` | member |  |
| `b25-wp-051-ad-off-ad-suppression-community-ad-off-member` | Ad-Free Community | `ad-off-ad-suppression` | member |  |
| `b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin |  |
| `b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member |  |

### Affected Screen Rows

Showing 30 of 54 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-087-mosque-donation-payment-2` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-090-mosque-care-request-2` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-112-gear-loan-request-0` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_start | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-113-gear-loan-request-1` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_action | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-114-gear-loan-request-2` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_complete | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-118-platform-connections-entry-0` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-119-platform-connections-entry-1` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-120-platform-connections-entry-2` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-121-platform-connection-invite-0` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-122-platform-connection-invite-1` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-123-platform-connection-invite-2` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-124-platform-blocked-target-0` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-125-platform-blocked-target-1` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-126-platform-blocked-target-2` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-133-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-134-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-135-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-136-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-137-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-138-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-139-ad-off-member-checkout-0` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-140-ad-off-member-checkout-1` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-141-ad-off-member-checkout-2` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_complete | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-142-ad-off-community-checkout-0` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-143-ad-off-community-checkout-1` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-144-ad-off-community-checkout-2` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_complete | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-145-ad-off-entitlement-status-0` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-146-ad-off-entitlement-status-1` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |

### Evidence To Update
- independent-production-ux-review.json holisticQuestionAnswers
- independent-production-ux-review.md holistic review summary
- product-ux-screen-review-matrix.md relevant screen rows
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json workflowPersonaScorecards
- independent-production-ux-review.json screenRows
- product-ux-screen-review-matrix.md every workflow/persona row
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.
- Fresh screenshots for every primary workflow/persona surface that was replaced or reviewed.
- `workflowPersonaScorecards` with task-specific domain-native surface judgments.
- Screen matrix rows showing `primarySurfaceType` or classification is not generic for primary workflows.

### Acceptance Checks
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.

### Concrete Acceptance Criteria
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-084-mosque-donor-visibility-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-084-mosque-donor-visibility-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-084-mosque-donor-visibility-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Primary surface for `mosque-donor-visibility` is documented as `donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donor-visibility`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-087-mosque-donation-payment-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-087-mosque-donation-payment-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-087-mosque-donation-payment-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donation-payment`, and the exact product UX issue.
- Primary surface for `mosque-donation-payment` is documented as `payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donation-payment`.
- Screen row `b25-v4-row-090-mosque-care-request-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-090-mosque-care-request-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-090-mosque-care-request-2` names visible UI elements, visible text, persona `member`, workflow `mosque-care-request`, and the exact product UX issue.
- Primary surface for `mosque-care-request` is documented as `protected care request form and private response/status surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-care-request`.
- Screen row `b25-v4-row-093-mosque-neutral-notification-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-093-mosque-neutral-notification-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-093-mosque-neutral-notification-2` names visible UI elements, visible text, persona `member`, workflow `mosque-neutral-notification`, and the exact product UX issue.
- Primary surface for `mosque-neutral-notification` is documented as `notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-neutral-notification`.
- Screen row `b25-v4-row-112-gear-loan-request-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-112-gear-loan-request-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-112-gear-loan-request-0` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Primary surface for `gear-loan-request` is documented as `request detail and admin review queue with submitted data, decision action, status, and notification` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `gear-loan-request`.
- Screen row `b25-v4-row-113-gear-loan-request-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-113-gear-loan-request-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-113-gear-loan-request-1` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Screen row `b25-v4-row-114-gear-loan-request-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-114-gear-loan-request-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-114-gear-loan-request-2` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Screen row `b25-v4-row-118-platform-connections-entry-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-118-platform-connections-entry-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-118-platform-connections-entry-0` names visible UI elements, visible text, persona `member`, workflow `platform-connections-entry`, and the exact product UX issue.
- Primary surface for `platform-connections-entry` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

### Commit Boundary

Commit this remediation batch, refreshed evidence, judge outputs, scorecards, and tracker updates before the next UX feedback loop. If the committed pass still fails, the following pass starts by sending its tickets to the Remediation Planner.

## B25-RB-003-recapture-rerun-closeout: Recapture evidence, rerun judges, and close resolved tickets

Prove the remediation with fresh screenshots, scorecards, and a committed iteration boundary.

| Field | Value |
| --- | --- |
| Status | open |
| Ticket IDs | B25-RT-001-b25-c01-no-blocker-major, B25-RT-002-b25-c03-production-grade-experience, B25-RT-003-b25-c14-llm-vision-ux-review, B25-RT-004-b25-c04-modern-intentional-ui, B25-RT-005-b25-c05-community-content-ia, B25-RT-006-b25-c06-domain-native-primary-surfaces, B25-RT-007-b25-c13-workflow-lifecycle-complete, B25-RT-008-b25-c08-visible-text-specific-critique, B25-RT-009-b25-c09-no-layout-production-defects |

### Worker Actions
- Rebuild and relaunch the Demo App on the reviewed emulator/device.
- Recapture affected screenshots with hashes, timestamps, device metadata, and app commit SHA.
- Regenerate B25 schema v4 review JSON, markdown review, screen matrix, remediation tickets, and iteration scorecard.
- Commit the full iteration before starting the next UX feedback loop.

### Implementation Guidance
- Use each open remediation ticket as the implementation backlog.
- Update review JSON, remediation log, scorecards, tracker, and screenshots together.
- Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.
- Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.
- Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.
- Treat the imported LLM vision review as the independent semantic critique.
- Prioritize screen rows and workflows named in `llmVisionReview.findings` and `llmVisionReview.screenReviews`.
- Do not close the ticket until a fresh LLM vision review over after-screenshots passes.
- Inspect workflow surface builders and replace primary generic card/checklist/modal renderers with task-specific widgets.
- Use B21 production UX contracts to choose the target surface type for each workflow/persona pair.
- Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.
- Inspect workflow surface builders and identify where current UI collapses lifecycle into a single action card.
- For each failed lifecycle scorecard, implement missing object/context, decision data, primary and alternate actions, result/receipt/status, and receiver/continuation state.
- Update product docs, seed data, widget tests, and B25 evidence expectations so the lifecycle is documented and screenshot-proven.
- Update the B25 judge/review artifact, not only app UI code.
- Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowPersonaScorecards` with screenshot-specific content.
- Regenerate markdown review and matrix files from the updated schema v4 JSON.

### Likely Files / Widgets
- `app/apps/loom_communities_demo/lib/main.dart`
- `app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart`
- `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`
- `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md`
- `docs/Build Plan V2/Build Tracker.md`
- `app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart`
- `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart`
- `app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart`
- `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md`

### UX Reference Patterns To Copy

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |
| Screenshot-first critique method | B25 production UX gate / methodology | docs/Build Plan V2/Tools/b25-remediation-ticket-template.md | Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix. |

### Reference Research Queries
- production mobile UX review screenshot critique examples
- open source Flutter mobile app UX patterns GitHub
- open source Flutter domain-native-surface mobile UI example GitHub
- donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile UX pattern
- Material Design donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state mobile pattern
- open source Flutter payment-donation mobile UI example GitHub
- payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile UX pattern
- Material Design payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail mobile pattern
- government design system payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail form review confirmation pattern
- open source Flutter form-review mobile UI example GitHub
- protected care request form and private response/status surface mobile UX pattern
- Material Design protected care request form and private response/status surface mobile pattern
- government design system protected care request form and private response/status surface form review confirmation pattern
- notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile UX pattern
- Material Design notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state mobile pattern
- request detail and admin review queue with submitted data, decision action, status, and notification mobile UX pattern
- Material Design request detail and admin review queue with submitted data, decision action, status, and notification mobile pattern
- government design system request detail and admin review queue with submitted data, decision action, status, and notification form review confirmation pattern
- open source Flutter message-thread mobile UI example GitHub
- inbox, message thread, connection card, invite, or block-state surface mobile UX pattern

### Product Spec Repair Work Items

Showing 3 of 3 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-product-spec-interaction-model-camera-club` | `product-spec-update` | Camera Club | `gear-loan-request` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-platform-social` | `product-spec-update` | Member Social Space | `platform-blocked-target` | product-experience-steward | 3 | 1 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |
| `b25-wi-product-spec-interaction-model-ad-off` | `product-spec-update` | Ad-Free Community | `ad-off-member-checkout, ad-off-community-checkout, ad-off-entitlement-status, ad-off-receipt-evidence, ad-off-ad-suppression` | product-experience-steward | 15 | 5 | community product experience spec with semantic interaction models | the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow |

### Evidence Repair Work Items

Showing 17 of 17 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-evidence-repair-community-mosque-mosque-donor-visibility-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state |  |
| `b25-wi-evidence-repair-community-mosque-mosque-donation-payment-community-mosque-donor` | `evidence-repair` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-mosque-care-request-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-care-request` | member | 3 | 1 | protected care request form and private response/status surface |  |
| `b25-wi-evidence-repair-community-mosque-mosque-neutral-notification-community-mosque-member` | `evidence-repair` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state |  |
| `b25-wi-evidence-repair-community-camera-club-gear-loan-request-community-camera-club-member` | `evidence-repair` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connections-entry-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-connection-invite-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-blocked-target-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface |  |
| `b25-wi-evidence-repair-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap |  |
| `b25-wi-evidence-repair-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `evidence-repair` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-member-checkout-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-member-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-community-checkout-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-community-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-receipt-evidence-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-receipt-evidence` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-ad-off-ad-off-ad-suppression-community-ad-off-member` | `evidence-repair` | Ad-Free Community | `ad-off-ad-suppression` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |
| `b25-wi-evidence-repair-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `evidence-repair` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action |  |

### Evidence Repair Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### UI Remediation Work Items

Showing 18 of 18 work items. Full detail is in the JSON artifact.

| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `b25-wi-ui-remediation-community-mosque-mosque-donor-visibility-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donor-visibility` | donor | 3 | 1 | donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-donation-payment-community-mosque-donor` | `ui-remediation` | Masjid Nur | `mosque-donation-payment` | donor | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-care-request-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-care-request` | member | 3 | 1 | protected care request form and private response/status surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-mosque-neutral-notification-community-mosque-member` | `ui-remediation` | Masjid Nur | `mosque-neutral-notification` | member | 3 | 1 | notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-camera-club-gear-loan-request-community-camera-club-member` | `ui-remediation` | Camera Club | `gear-loan-request` | member | 3 | 1 | request detail and admin review queue with submitted data, decision action, status, and notification | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connections-entry-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connections-entry` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-connection-invite-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-connection-invite` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-blocked-target-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-blocked-target` | member | 3 | 1 | inbox, message thread, connection card, invite, or block-state surface | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-top-banner-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-top-banner-no-fill` | member | 3 | 1 | App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-platform-social-platform-sensitive-no-fill-community-platform-social-member` | `ui-remediation` | Member Social Space | `platform-sensitive-no-fill` | member | 3 | 1 | sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-member-checkout-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-member-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-community-checkout-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-community-checkout` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-entitlement-status-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-entitlement-status` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-receipt-evidence-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-receipt-evidence` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-ad-suppression-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-ad-suppression` | member | 3 | 1 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-ad-off-ad-off-settlement-utility-community-ad-off-member` | `ui-remediation` | Ad-Free Community | `ad-off-settlement-utility` | member | 3 | 0 | payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-admin` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |
| `b25-wi-ui-remediation-community-mosque-wf-multi-persona-workflow-evidence-community-mosque-member` | `ui-remediation` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member | 3 | 1 | multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action | Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique. |

### UI Remediation Work Items Reference Patterns

| Reference | Source | URL | What to copy |
| --- | --- | --- | --- |
| Material detail surface composition | Material Design 3 / design-system | https://m3.material.io/components/cards/overview | Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card. |
| Material Design cards and lists | Material Design 3 / design-system | https://m3.material.io/components/cards/overview<br>Also: https://m3.material.io/components/lists/overview | Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow. |
| Flutter sample app implementation patterns | flutter/samples / open-source | https://github.com/flutter/samples | Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer. |
| Material navigation and information architecture | Material Design 3 / design-system | https://m3.material.io/components/navigation-drawer/overview<br>Also: https://m3.material.io/components/navigation-bar/overview | Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy. |
| Apple HIG navigation and content organization | Apple Human Interface Guidelines / design-system | https://developer.apple.com/design/human-interface-guidelines/navigation | Make navigation predictable, content-centered, and appropriate for the user’s current task. |
| Review-and-confirm payment flow | GOV.UK Design System / design-system | https://design-system.service.gov.uk/patterns/check-answers/ | Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail. |
| Multi-step payment/progress flow | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/step-indicator/ | Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status. |
| Form validation and review pattern | U.S. Web Design System / design-system | https://designsystem.digital.gov/components/form/<br>Also: https://designsystem.digital.gov/components/alert/<br>https://design-system.service.gov.uk/components/error-summary/ | Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment. |
| Inbox and message thread pattern | Material lists/text fields / pattern | https://m3.material.io/components/lists/overview<br>Also: https://m3.material.io/components/text-fields/overview | Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state. |

### Affected Coverage Rows

Showing 17 of 17 affected coverage rows.

| Coverage row | Community | Workflow | Persona | Missing evidence |
| --- | --- | --- | --- | --- |
| `b25-wp-028-mosque-donor-visibility-community-mosque-donor` | Masjid Nur | `mosque-donor-visibility` | donor |  |
| `b25-wp-029-mosque-donation-payment-community-mosque-donor` | Masjid Nur | `mosque-donation-payment` | donor |  |
| `b25-wp-030-mosque-care-request-community-mosque-member` | Masjid Nur | `mosque-care-request` | member |  |
| `b25-wp-031-mosque-neutral-notification-community-mosque-member` | Masjid Nur | `mosque-neutral-notification` | member |  |
| `b25-wp-038-gear-loan-request-community-camera-club-member` | Camera Club | `gear-loan-request` | member |  |
| `b25-wp-040-platform-connections-entry-community-platform-social-member` | Member Social Space | `platform-connections-entry` | member |  |
| `b25-wp-041-platform-connection-invite-community-platform-social-member` | Member Social Space | `platform-connection-invite` | member |  |
| `b25-wp-042-platform-blocked-target-community-platform-social-member` | Member Social Space | `platform-blocked-target` | member |  |
| `b25-wp-045-platform-top-banner-no-fill-community-platform-social-member` | Member Social Space | `platform-top-banner-no-fill` | member |  |
| `b25-wp-046-platform-sensitive-no-fill-community-platform-social-member` | Member Social Space | `platform-sensitive-no-fill` | member |  |
| `b25-wp-047-ad-off-member-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-member-checkout` | member |  |
| `b25-wp-048-ad-off-community-checkout-community-ad-off-member` | Ad-Free Community | `ad-off-community-checkout` | member |  |
| `b25-wp-049-ad-off-entitlement-status-community-ad-off-member` | Ad-Free Community | `ad-off-entitlement-status` | member |  |
| `b25-wp-050-ad-off-receipt-evidence-community-ad-off-member` | Ad-Free Community | `ad-off-receipt-evidence` | member |  |
| `b25-wp-051-ad-off-ad-suppression-community-ad-off-member` | Ad-Free Community | `ad-off-ad-suppression` | member |  |
| `b25-wp-067-wf-multi-persona-workflow-evidence-community-mosque-admin` | Masjid Nur | `wf_multi-persona-workflow-evidence` | admin |  |
| `b25-wp-068-wf-multi-persona-workflow-evidence-community-mosque-member` | Masjid Nur | `wf_multi-persona-workflow-evidence` | member |  |

### Affected Screen Rows

Showing 30 of 54 affected screen rows.

| Screen row | Community | Workflow | Persona | State | Exact UX failure |
| --- | --- | --- | --- | --- | --- |
| `b25-v4-row-084-mosque-donor-visibility-2` | Masjid Nur | `mosque-donor-visibility` | donor | B14_ext_mosque_mosque-donor-visibility_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-087-mosque-donation-payment-2` | Masjid Nur | `mosque-donation-payment` | donor | B14_ext_mosque_mosque-donation-payment_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-090-mosque-care-request-2` | Masjid Nur | `mosque-care-request` | member | B14_ext_mosque_mosque-care-request_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-093-mosque-neutral-notification-2` | Masjid Nur | `mosque-neutral-notification` | member | B14_ext_mosque_mosque-neutral-notification_complete | LLM vision critique: These rows pass lifecycle, but the visible copy still exposes product-surface language to users and should be rewritten before a production UX pass. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-112-gear-loan-request-0` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_start | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-113-gear-loan-request-1` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_action | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-114-gear-loan-request-2` | Camera Club | `gear-loan-request` | member | B15_ext_camera_club_gear-loan-request_complete | LLM vision critique: The screen is no longer thin, but the decision model is not yet clear enough for a real borrower/lender gear-loan workflow. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-118-platform-connections-entry-0` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-119-platform-connections-entry-1` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-120-platform-connections-entry-2` | Member Social Space | `platform-connections-entry` | member | B16_ext_platform_social_platform-connections-entry_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-121-platform-connection-invite-0` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-122-platform-connection-invite-1` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-123-platform-connection-invite-2` | Member Social Space | `platform-connection-invite` | member | B16_ext_platform_social_platform-connection-invite_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-124-platform-blocked-target-0` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_start | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-125-platform-blocked-target-1` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_action | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-126-platform-blocked-target-2` | Member Social Space | `platform-blocked-target` | member | B16_ext_platform_social_platform-blocked-target_complete | LLM vision critique: The Platform Social workflows remain too generic for a production member social experience, and three Platform Social workflow/persona scorecards fail. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-133-platform-top-banner-no-fill-0` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_start | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-134-platform-top-banner-no-fill-1` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_action | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-135-platform-top-banner-no-fill-2` | Member Social Space | `platform-top-banner-no-fill` | member | B16_ext_platform_social_platform-top-banner-no-fill_complete | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-136-platform-sensitive-no-fill-0` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_start | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-137-platform-sensitive-no-fill-1` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_action | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-138-platform-sensitive-no-fill-2` | Member Social Space | `platform-sensitive-no-fill` | member | B16_ext_platform_social_platform-sensitive-no-fill_complete | LLM vision critique: The ad/no-fill evidence is functional, but the user-facing screen still reads like an ad-state audit surface rather than a native member feed or message area. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-139-ad-off-member-checkout-0` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-140-ad-off-member-checkout-1` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-141-ad-off-member-checkout-2` | Ad-Free Community | `ad-off-member-checkout` | member | B16_ext_ad_off_ad-off-member-checkout_complete | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-142-ad-off-community-checkout-0` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-143-ad-off-community-checkout-1` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-144-ad-off-community-checkout-2` | Ad-Free Community | `ad-off-community-checkout` | member | B16_ext_ad_off_ad-off-community-checkout_complete | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-145-ad-off-entitlement-status-0` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_start | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |
| `b25-v4-row-146-ad-off-entitlement-status-1` | Ad-Free Community | `ad-off-entitlement-status` | member | B16_ext_ad_off_ad-off-entitlement-status_action | LLM vision critique: The family has content but not distinct production surfaces. Receipt history should behave like receipt history, suppression proof like ad-state proof, and entitlement status like subscription management, not the same checkout card with different headers. Current row verdict is `fail` with severity `major`. |

### Evidence To Update
- independent-production-ux-review.json findings
- product-ux-remediation-loop.md
- b25-iteration-scorecard-latest.json/.md
- Build Tracker.md B25 row and execution ledger
- independent-production-ux-review.json holisticQuestionAnswers
- independent-production-ux-review.md holistic review summary
- product-ux-screen-review-matrix.md relevant screen rows
- production-ux-criteria-scorecard.json/.md
- independent-production-ux-review.json llmVisionReview
- independent-production-ux-review.json findings from source=llm-vision-ux-judge
- product-ux-screen-review-matrix.md affected screen rows
- independent-production-ux-review.json workflowPersonaScorecards
- independent-production-ux-review.json screenRows
- product-ux-screen-review-matrix.md every workflow/persona row
- independent-production-ux-review.json workflowLifecycleScorecards
- b25-workflow-lifecycle-scorecards.md
- Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.
- Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.
- `holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.
- `llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.
- Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.
- Fresh screenshots for every primary workflow/persona surface that was replaced or reviewed.
- `workflowPersonaScorecards` with task-specific domain-native surface judgments.
- Screen matrix rows showing `primarySurfaceType` or classification is not generic for primary workflows.
- Fresh entry/action/result/receiver screenshots for every remediated workflow/persona lifecycle.
- `workflowLifecycleScorecards` showing every required lifecycle group passes.
- Visible text excerpts proving object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.
- Visible text extracts for every reviewed row.
- Non-boilerplate screen-specific critique for every reviewed row.
- Updated markdown matrix matching the JSON evidence.

### Acceptance Checks
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.
- Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.
- Every workflow lifecycle scorecard is present, screenshot-backed, and pass with no missing lifecycle groups.

### Concrete Acceptance Criteria
- Unresolved blocker and major finding counts are both zero.
- `production_ux_judge.dart` has no blocking failure for this criterion.
- `b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.
- Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.
- Screen row `b25-v4-row-084-mosque-donor-visibility-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-084-mosque-donor-visibility-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-084-mosque-donor-visibility-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donor-visibility`, and the exact product UX issue.
- Primary surface for `mosque-donor-visibility` is documented as `donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donor-visibility`.
- Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.
- Screen row `b25-v4-row-087-mosque-donation-payment-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-087-mosque-donation-payment-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-087-mosque-donation-payment-2` names visible UI elements, visible text, persona `donor`, workflow `mosque-donation-payment`, and the exact product UX issue.
- Primary surface for `mosque-donation-payment` is documented as `payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-donation-payment`.
- Screen row `b25-v4-row-090-mosque-care-request-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-090-mosque-care-request-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-090-mosque-care-request-2` names visible UI elements, visible text, persona `member`, workflow `mosque-care-request`, and the exact product UX issue.
- Primary surface for `mosque-care-request` is documented as `protected care request form and private response/status surface` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-care-request`.
- Screen row `b25-v4-row-093-mosque-neutral-notification-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-093-mosque-neutral-notification-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-093-mosque-neutral-notification-2` names visible UI elements, visible text, persona `member`, workflow `mosque-neutral-notification`, and the exact product UX issue.
- Primary surface for `mosque-neutral-notification` is documented as `notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `mosque-neutral-notification`.
- Screen row `b25-v4-row-112-gear-loan-request-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-112-gear-loan-request-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-112-gear-loan-request-0` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Primary surface for `gear-loan-request` is documented as `request detail and admin review queue with submitted data, decision action, status, and notification` or another explicit domain-native surface.
- After-screenshot visible text proves every required semantic surface group for `gear-loan-request`.
- Screen row `b25-v4-row-113-gear-loan-request-1` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-113-gear-loan-request-1` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-113-gear-loan-request-1` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Screen row `b25-v4-row-114-gear-loan-request-2` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-114-gear-loan-request-2` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-114-gear-loan-request-2` names visible UI elements, visible text, persona `member`, workflow `gear-loan-request`, and the exact product UX issue.
- Screen row `b25-v4-row-118-platform-connections-entry-0` has a specific persona/personaId, not `persona-under-review`.
- Visible text for `b25-v4-row-118-platform-connections-entry-0` is extracted from the screenshot or manually transcribed from the screenshot.
- Critique for `b25-v4-row-118-platform-connections-entry-0` names visible UI elements, visible text, persona `member`, workflow `platform-connections-entry`, and the exact product UX issue.
- Primary surface for `platform-connections-entry` is documented as `inbox, message thread, connection card, invite, or block-state surface` or another explicit domain-native surface.

### Rerun Commands
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\ Plan\ V2/Evidence`
- `dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-capture-coverage-report.json`
- `dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\ Plan\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/workflow-persona-coverage-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\ Plan\ V2/Evidence/B25/product-ux-screen-review-matrix.md`
- `dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md`
- `dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\ Plan\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\ Plan\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B25/b25-iteration-scorecard-latest.md`

### Commit Boundary

Commit this remediation batch, refreshed evidence, judge outputs, scorecards, and tracker updates before the next UX feedback loop. If the committed pass still fails, the following pass starts by sending its tickets to the Remediation Planner.

## Planner Rules

- Worker agents implement from remediation batches, not from optimistic summaries.
- Product-spec work items must be completed and rerun before evidence repair or UI remediation work items for the same community are assigned.
- Evidence repair work items must be completed and rerun before UI remediation work items for the same community/workflow/persona are assigned.
- UI remediation work must be scoped by community/workflow/persona and target production surface, not by a broad global ticket summary.
- The independent judge must rerun after each batch that changes UI, evidence, or critique.
- No next UX feedback loop starts until the current remediation iteration is committed.
