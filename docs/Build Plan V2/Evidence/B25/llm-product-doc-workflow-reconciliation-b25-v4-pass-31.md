# B25 Product Docs To Evidence Workflow Reconciliation - b25-v4-pass-31

| Field | Value |
| --- | --- |
| Decision | fail |
| Fresh review | true |
| App commit SHA | 1341976 |
| Reviewed screen rows | 195 |
| Reviewed screenshot hashes | 195 |
| Findings | 15 major, 0 blocker |

## Summary

This fresh reconciliation reviewed the Product Docs V2 community examples against the current B25 review JSON, screen matrix, workflow/persona matrix, lifecycle scorecards, and B12-B20 screenshot evidence for app commit `1341976`. B25 cannot close because current evidence still proves major reconciliation gaps: some Product Docs semantic rows are generic or mismatched to their workflows, some current card-surface/evidence mappings contradict the Product Docs source of truth, and several screenshots do not yet prove the concrete lifecycle/result/receiver states the docs require.

No B25-scoped Section 6 workflow is completely missing screen-row coverage, and no current B25 workflow lacks a Product Docs V2 Section 6 row. The `loom-communities-shell` local install workflow is explicitly scoped out of B25 community screenshot reconciliation by its Product Doc.

## Communities Reviewed

| Community | Product doc | Status | Declared workflows | Implemented workflows | Gap IDs |
| --- | --- | --- | ---: | ---: | --- |
| Ad-Free Community | `docs/Product Docs V2/Community Examples/ad-off-product-experience.md` | fail | 6 | 6 | LLM-B25-WR-013, LLM-B25-WR-014 |
| Camera Club | `docs/Product Docs V2/Community Examples/camera-club-product-experience.md` | fail | 3 | 3 | LLM-B25-WR-007 |
| Cedar Commons HOA | `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` | fail | 7 | 7 | LLM-B25-WR-006 |
| Chess Club | `docs/Product Docs V2/Community Examples/chess-club-product-experience.md` | pass | 3 | 3 | none |
| Data Portability Community | `docs/Product Docs V2/Community Examples/export-and-migration-product-experience.md` | fail | 9 | 9 | LLM-B25-WR-015 |
| Garden Club | `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` | pass | 3 | 3 | none |
| Loom Communities shell | `docs/Product Docs V2/Community Examples/loom-communities-shell-product-experience.md` | pass | 0 | 0 | none |
| Masjid Nur | `docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md` | fail | 11 | 11 | LLM-B25-WR-002, LLM-B25-WR-005 |
| Neighborhood Book Club | `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md` | fail | 7 | 7 | LLM-B25-WR-003, LLM-B25-WR-004 |
| persona-role-inventory | `docs/Product Docs V2/Community Examples/persona-role-inventory-product-experience.md` | pass | 1 | 1 | none |
| Member Social Space | `docs/Product Docs V2/Community Examples/platform-social-product-experience.md` | fail | 8 | 8 | LLM-B25-WR-008, LLM-B25-WR-009, LLM-B25-WR-010, LLM-B25-WR-011, LLM-B25-WR-012 |
| Riverside Youth Soccer | `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` | fail | 7 | 7 | LLM-B25-WR-001 |

## Product Doc Rows Missing Evidence

None for B25-scoped Section 6 workflows. Shell local install remains explicitly out of scope for this B25 reconciliation pass.

## Evidence Rows Missing Product Doc Coverage

None. Every current B25 workflow ID in `screenRows` maps to a reviewed Product Docs V2 Section 6 row.

## Product Doc Updates Required

- `LLM-B25-WR-004` `book-search-ai-digest` (Neighborhood Book Club): The visible UI implements a cited reading-guide flow with query, answer, source snippets, source visibility, open sources, refine query, save/share/follow-up actions, and saved guide state. The product doc semantic row still uses the generic submit/save/send model and generic result wording, so the docs do not fully specify the workflow visible in screenshots. Update Sections 6-8 and the B25 semantic/card-surface rows to name the cited-answer lifecycle, concrete primary and alternate actions, saved digest result, stale/private-source handling, and receiver/continuation state before judging implementation complete.
- `LLM-B25-WR-006` `hoa-owner-notification` (Cedar Commons HOA): The screenshots show a concrete owner notice flow with sender, recipient, body, delivery time, edit notice, save draft, change audience, send notification, delivered state, inbox receipt, and appeal/reopen follow-up. The B25 semantic row is still the generic submit/save/send template, so the product doc does not fully specify the lifecycle now visible in evidence. Replace the generic semantic model with owner-notice-specific decision data, primary send action, edit/save-draft/change-audience alternatives, delivery result, and owner receiver/read state.
- `LLM-B25-WR-009` `platform-top-banner-no-fill` (Member Social Space): The docs specify a top-banner no-fill surface with reserved space, no-fill reason, no click/impression state, refresh-slot or inspect-reason alternative, and stable layout. Current screenshots prove the reserved slot, but the action row mixes unrelated ad-off entitlement, receipt, report, and restore controls and the lifecycle scorecard fails alternate/semantic model. Either document those extra ad-off controls for this workflow or remove them from the no-fill flow; in either case show the refresh/inspect no-fill alternative and recapture.
- `LLM-B25-WR-011` `platform-sensitive-no-fill` (Member Social Space): The docs require protected context, privacy-safe no-fill reason, no-click state, preserved content layout, and review-policy or hide-explanation alternatives. Current rows show sensitive no-fill, but the action screen switches into sponsored-message/ad-off account controls such as manage entitlement, report ad issue, and restore receipt. The lifecycle scorecard fails alternate/semantic model. Align the UI and docs around the sensitive no-fill policy interaction, add the documented policy/hide alternative, and recapture.
- `LLM-B25-WR-013` `ad-off-ad-suppression` (Ad-Free Community): The product doc maps this workflow to ad suppression proof and the B25 registry maps it to an ad surface / CommunityAdSurfaceApi. Current screen rows classify it as payment / CommunityPaymentSurfaceApi with target surface requiring amount, so the workflow/persona scorecard fails missing amount even though the visible UI is an ad-suppression proof. Align the evidence/card-surface mapping and semantic model to the documented ad suppression surface, or explicitly update the doc if a payment amount is truly required, then recapture.
- `LLM-B25-WR-014` `ad-off-entitlement-status` (Ad-Free Community): The product doc maps entitlement status to active/inactive state, renewal/expiry, managed subscription, affected ad surfaces, and the ad-off entitlement / CommunityAdSurfaceApi registry. Current rows classify it as payment / CommunityPaymentSurfaceApi with a payment amount requirement, causing the scorecard to fail despite visible entitlement status. Align the card-surface/target mapping to entitlement status or revise the doc if payment amount is required on this screen, then recapture.
- `LLM-B25-WR-015` `export-protected-redaction` (Data Portability Community): Current screenshots show protected values, policy reasons, before/after preview, audit trail, change scope, retry, and generate export. The current workflow/persona semantic proof still fails because it expects concrete protected subject/persona terms such as protected youth/minor profile and guardian/coach visibility, while the product doc only specifies generic protected fields/redaction choices. Make the source of truth concrete: either update the product doc/seed requirements to name the protected record classes and reveal personas the proof expects, or update the evidence mapping to the generic Data Portability protected-field model, then recapture.

## UI Or Evidence Remediation Required

- `LLM-B25-WR-001` `soccer-team-roster` (Riverside Youth Soccer, coach): rows b25-v4-row-016-soccer-team-roster-0, b25-v4-row-017-soccer-team-roster-1, b25-v4-row-018-soccer-team-roster-2; fix: The docs require a coach roster management lifecycle with roster rows, protected minor fields, waiver/status history, edit/request-guardian-update/redact/undo paths, and guardian receiver state. Current rows prove viewing/opening/filtering/exporting the roster, while the current lifecycle scorecard still fails primary semantic action, alternate/change/reject affordance, and semantic interaction model. Add a concrete roster update/save/waiver action, a real edit or undo/redaction alternate path, and a guardian continuation/receiver state, then recapture.
- `LLM-B25-WR-002` `mosque-donor-visibility` (Masjid Nur, donor): rows b25-v4-row-028-mosque-donor-visibility-0, b25-v4-row-029-mosque-donor-visibility-1, b25-v4-row-030-mosque-donor-visibility-2; fix: The docs require visibility choice, amount/fund context, receipt visibility, saved preference, visibility history, and a change path. Current screenshots show an anonymous donor preference and saved record, but the current lifecycle scorecard fails persistent result state; the result state does not make the durable chosen visibility/history/receipt visibility concrete enough for later review. Add explicit saved visibility value, receipt visibility, timestamp/history, and change/manage state, then recapture.
- `LLM-B25-WR-003` `book-vote` (Neighborhood Book Club, member): rows b25-v4-row-034-book-vote-0, b25-v4-row-035-book-vote-1, b25-v4-row-036-book-vote-2; fix: The docs require candidates, selected/voted result, change/clear vote path, and member receiver state. Current screenshots show candidates and a saved vote, but the current lifecycle scorecard still fails persistent result state. Strengthen the result screen with a durable ballot receipt/audit state, selected title, close/deadline state, and organizer/member continuation state, then recapture.
- `LLM-B25-WR-005` `mosque-event-rsvp` (Masjid Nur, member): rows b25-v4-row-070-mosque-event-rsvp-0, b25-v4-row-071-mosque-event-rsvp-1, b25-v4-row-072-mosque-event-rsvp-2; fix: The docs require RSVP choice/result plus capacity or attendee state updates and continuation/receiver state. Current screenshots show event details, Going confirmation, and change response, but the lifecycle scorecard fails receiver/continuation state and the capacity/attendee value is not visibly updated after RSVP. Add the post-RSVP attendee/capacity update, reminder/inbox continuation, or receiver state required by the doc, then recapture.
- `LLM-B25-WR-007` `photo-walk-rsvp` (Camera Club, member): rows b25-v4-row-106-photo-walk-rsvp-0, b25-v4-row-107-photo-walk-rsvp-1, b25-v4-row-108-photo-walk-rsvp-2; fix: The docs require named route/date/location/capacity, RSVP choice, change path, and confirmed state. Current screenshots prove route/event detail and action choices, but the current lifecycle scorecard fails persistent result state; the completion screen says RSVP saved without a concrete selected response and later reminder/calendar or capacity continuation. Show the selected attendance value, durable confirmation, change-until deadline, and reminder/capacity continuation state, then recapture.
- `LLM-B25-WR-008` `platform-blocked-target` (Member Social Space, member): rows b25-v4-row-118-platform-blocked-target-0, b25-v4-row-119-platform-blocked-target-1, b25-v4-row-120-platform-blocked-target-2; fix: The docs require blocked member, reason/status, disabled message/invite state, unblock/appeal/keep-blocked or cancel-invite alternatives, safety audit, and protected receiver state. Current screenshots show the blocked guard and disabled send, but the current lifecycle scorecard fails alternate/change/reject affordance and semantic model; the action row exposes reply/mute/archive rather than the documented unblock/appeal/keep-blocked/cancel-invite choices. Add the documented safety alternatives and receiver protection state, then recapture.
- `LLM-B25-WR-009` `platform-top-banner-no-fill` (Member Social Space, member): rows b25-v4-row-121-platform-top-banner-no-fill-0, b25-v4-row-122-platform-top-banner-no-fill-1, b25-v4-row-123-platform-top-banner-no-fill-2; fix: The docs specify a top-banner no-fill surface with reserved space, no-fill reason, no click/impression state, refresh-slot or inspect-reason alternative, and stable layout. Current screenshots prove the reserved slot, but the action row mixes unrelated ad-off entitlement, receipt, report, and restore controls and the lifecycle scorecard fails alternate/semantic model. Either document those extra ad-off controls for this workflow or remove them from the no-fill flow; in either case show the refresh/inspect no-fill alternative and recapture.
- `LLM-B25-WR-010` `platform-message-stream` (Member Social Space, member): rows b25-v4-row-142-platform-message-stream-0, b25-v4-row-143-platform-message-stream-1, b25-v4-row-144-platform-message-stream-2; fix: The docs require participants, preview/body, timestamp, reply/mark-read/mute/archive state, and sender/receiver delivery/read continuation. Current screenshots show the thread and actions, but the current lifecycle scorecard fails persistent result state; the completion state does not sufficiently prove a durable reply/read history and receiver continuation beyond a generic thread-updated message. Add explicit read/delivery or reply-history state tied to sender/recipient, then recapture.
- `LLM-B25-WR-011` `platform-sensitive-no-fill` (Member Social Space, member): rows b25-v4-row-145-platform-sensitive-no-fill-0, b25-v4-row-146-platform-sensitive-no-fill-1, b25-v4-row-147-platform-sensitive-no-fill-2; fix: The docs require protected context, privacy-safe no-fill reason, no-click state, preserved content layout, and review-policy or hide-explanation alternatives. Current rows show sensitive no-fill, but the action screen switches into sponsored-message/ad-off account controls such as manage entitlement, report ad issue, and restore receipt. The lifecycle scorecard fails alternate/semantic model. Align the UI and docs around the sensitive no-fill policy interaction, add the documented policy/hide alternative, and recapture.
- `LLM-B25-WR-012` `platform-in-stream-ad` (Member Social Space, member): rows b25-v4-row-166-platform-in-stream-ad-0, b25-v4-row-167-platform-in-stream-ad-1, b25-v4-row-168-platform-in-stream-ad-2; fix: The docs require sponsor identity, disclosure, body/content context, impression/click state, and report/dismiss/hide or continue controls. Current screenshots show sponsor and report/open details, but the lifecycle scorecard fails alternate/semantic model and the result state is only reviewed. Add visible dismiss/hide/report alternatives, preserve stream position, and show the resulting impression/click/dismiss state, then recapture.
- `LLM-B25-WR-013` `ad-off-ad-suppression` (Ad-Free Community, member): rows b25-v4-row-127-ad-off-ad-suppression-0, b25-v4-row-128-ad-off-ad-suppression-1, b25-v4-row-129-ad-off-ad-suppression-2; fix: The product doc maps this workflow to ad suppression proof and the B25 registry maps it to an ad surface / CommunityAdSurfaceApi. Current screen rows classify it as payment / CommunityPaymentSurfaceApi with target surface requiring amount, so the workflow/persona scorecard fails missing amount even though the visible UI is an ad-suppression proof. Align the evidence/card-surface mapping and semantic model to the documented ad suppression surface, or explicitly update the doc if a payment amount is truly required, then recapture.
- `LLM-B25-WR-014` `ad-off-entitlement-status` (Ad-Free Community, member): rows b25-v4-row-148-ad-off-entitlement-status-0, b25-v4-row-149-ad-off-entitlement-status-1, b25-v4-row-150-ad-off-entitlement-status-2; fix: The product doc maps entitlement status to active/inactive state, renewal/expiry, managed subscription, affected ad surfaces, and the ad-off entitlement / CommunityAdSurfaceApi registry. Current rows classify it as payment / CommunityPaymentSurfaceApi with a payment amount requirement, causing the scorecard to fail despite visible entitlement status. Align the card-surface/target mapping to entitlement status or revise the doc if payment amount is required on this screen, then recapture.
- `LLM-B25-WR-015` `export-protected-redaction` (Data Portability Community, owner): rows b25-v4-row-154-export-protected-redaction-0, b25-v4-row-155-export-protected-redaction-1, b25-v4-row-156-export-protected-redaction-2; fix: Current screenshots show protected values, policy reasons, before/after preview, audit trail, change scope, retry, and generate export. The current workflow/persona semantic proof still fails because it expects concrete protected subject/persona terms such as protected youth/minor profile and guardian/coach visibility, while the product doc only specifies generic protected fields/redaction choices. Make the source of truth concrete: either update the product doc/seed requirements to name the protected record classes and reveal personas the proof expects, or update the evidence mapping to the generic Data Portability protected-field model, then recapture.

## Ticket-Ready Findings

### LLM-B25-WR-001 - major - visible-proof-gap

- Community/workflow/persona: Riverside Youth Soccer / `soccer-team-roster` / coach
- Product doc: `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-016-soccer-team-roster-0, b25-v4-row-017-soccer-team-roster-1, b25-v4-row-018-soccer-team-roster-2
- Screenshot hashes: bd97de277beca442672855c309b7b548286bdf19b4e060066ec57129da323f50, 3b8b9e956f0ba4e174bf716ae592eba2c8e46f62620ce4097f7217b2ddffeb3f, 9ef993352f9fc891a8119ebf166c33ace84250c544a93a76c25a9d401520fa16
- Visible text excerpt: U10 Falcons roster | Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details. | Roster and visibility | Featured player | Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday. | Protected fields | Birthdates and medical notes are redacted unless the coach has permission. | Team context | U10 Falcons practice Saturday at Riverside Field 3. | ...
- Required fix: The docs require a coach roster management lifecycle with roster rows, protected minor fields, waiver/status history, edit/request-guardian-update/redact/undo paths, and guardian receiver state. Current rows prove viewing/opening/filtering/exporting the roster, while the current lifecycle scorecard still fails primary semantic action, alternate/change/reject affordance, and semantic interaction model. Add a concrete roster update/save/waiver action, a real edit or undo/redaction alternate path, and a guardian continuation/receiver state, then recapture.
- Ticket mode: implementation-remediation

### LLM-B25-WR-002 - major - visible-proof-gap

- Community/workflow/persona: Masjid Nur / `mosque-donor-visibility` / donor
- Product doc: `docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models
- Screen rows: b25-v4-row-028-mosque-donor-visibility-0, b25-v4-row-029-mosque-donor-visibility-1, b25-v4-row-030-mosque-donor-visibility-2
- Screenshot hashes: d13a23805f731806b730f7a0f27f07c487e1f7f58309f04babc6dbd628a9aa9f, e3ba96cff8657a06d507415bbf9b02f0e46db0d7a0b3418f3ce18d1430237447, f8dbff6d4fae57deef815ba5682da90f645def5dbe09b5608334883fea0a79cd
- Visible text excerpt: Anonymous donor preference | Member-safe update with respectful language and privacy boundaries. | Amount, donor visibility, receipt destination, and giving history are visible before saving. | Community care | Privacy checked | Receipt record | Member inbox | This view shows editable details, current progress, and the next step before saving. | Edit response | Save details | Member-visible summary, protected details...
- Required fix: The docs require visibility choice, amount/fund context, receipt visibility, saved preference, visibility history, and a change path. Current screenshots show an anonymous donor preference and saved record, but the current lifecycle scorecard fails persistent result state; the result state does not make the durable chosen visibility/history/receipt visibility concrete enough for later review. Add explicit saved visibility value, receipt visibility, timestamp/history, and change/manage state, then recapture.
- Ticket mode: implementation-remediation

### LLM-B25-WR-003 - major - visible-proof-gap

- Community/workflow/persona: Neighborhood Book Club / `book-vote` / member
- Product doc: `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models
- Screen rows: b25-v4-row-034-book-vote-0, b25-v4-row-035-book-vote-1, b25-v4-row-036-book-vote-2
- Screenshot hashes: 44b76f2b0e6ad8762c8614e1057236ccc34eab5b7171b4f04967f3aad10e8c57, e32a11ee741f0148d6dc064d83b5d0f5c12661bbc255e4ca38795547c226fb59, eabac36feacf73ae8be01a78828b2ca4fce90ad1aac3892f8ecf058c2ec75568
- Visible text excerpt: February book ballot | Vote between three member nominations. | Parable of the Sower is leading the ballot for the next monthly discussion. | 3 nominations | Closes Jan 20 | 1 member vote | Leading title | This view shows editable details, current progress, and the next step before saving. | Change vote | Ballot choice | Your vote will count once for Parable of the Sower and can be changed before the ballot closes. |...
- Required fix: The docs require candidates, selected/voted result, change/clear vote path, and member receiver state. Current screenshots show candidates and a saved vote, but the current lifecycle scorecard still fails persistent result state. Strengthen the result screen with a durable ballot receipt/audit state, selected title, close/deadline state, and organizer/member continuation state, then recapture.
- Ticket mode: implementation-remediation

### LLM-B25-WR-004 - major - product-doc-interaction-gap

- Community/workflow/persona: Neighborhood Book Club / `book-search-ai-digest` / member
- Product doc: `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-037-book-search-ai-digest-0, b25-v4-row-038-book-search-ai-digest-1, b25-v4-row-039-book-search-ai-digest-2
- Screenshot hashes: 12463bc898e0d29d6dd1bfedda63ed896184e8981474e9b8244707fe43c1a8ba, 40740868e4ac1e4f8cd7ee5725967e28bd55f93613da276e2a04b6aac626e19f, 347e17572310a0742721ecea5a33b585951523b5c73f1f6bd24834019f981f6d
- Visible text excerpt: Answer with sources | Query | Query: "What should we discuss before chapter 6?" | Answer summary | Focus the chapter 6 discussion on mutual aid, scarcity, and Lauren's journal voice. | Source snippets | Cites member notes, the February nomination rationale, and the March discussion prompt. | Citation detail | Each citation shows source title, author or member, and why it is visible to this member. | Reading guide ans...
- Required fix: The visible UI implements a cited reading-guide flow with query, answer, source snippets, source visibility, open sources, refine query, save/share/follow-up actions, and saved guide state. The product doc semantic row still uses the generic submit/save/send model and generic result wording, so the docs do not fully specify the workflow visible in screenshots. Update Sections 6-8 and the B25 semantic/card-surface rows to name the cited-answer lifecycle, concrete primary and alternate actions, saved digest result, stale/private-source handling, and receiver/continuation state before judging implementation complete.
- Ticket mode: product-doc-update

### LLM-B25-WR-005 - major - persona-state-gap

- Community/workflow/persona: Masjid Nur / `mosque-event-rsvp` / member
- Product doc: `docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models
- Screen rows: b25-v4-row-070-mosque-event-rsvp-0, b25-v4-row-071-mosque-event-rsvp-1, b25-v4-row-072-mosque-event-rsvp-2
- Screenshot hashes: 75a97ee0f0a575bce23db530da089b39c0c0c1fbe4415d919f92156dae3d2abd, f47713eb6df7182a208ba1810ed186f0014354b85eb5470cc98dd6079bd898fc, 3b1f63d13561b16f321d7f77f3042fbf16674f2edabbd3f669d04eff127378bd
- Visible text excerpt: Community iftar RSVP | Fri, Mar 14 at 6:45 PM - Fellowship hall. | Reserve a seat after checking event time, location, host, capacity, and reminder details. | Fri, Mar 14 | 6:45 PM | Fellowship hall | 86 of 120 spots | Event date, time, location, capacity, and Going/Maybe/Not going options are visible. | Change response | Choose RSVP response | Going reserves a spot; maybe keeps the event visible without taking capac...
- Required fix: The docs require RSVP choice/result plus capacity or attendee state updates and continuation/receiver state. Current screenshots show event details, Going confirmation, and change response, but the lifecycle scorecard fails receiver/continuation state and the capacity/attendee value is not visibly updated after RSVP. Add the post-RSVP attendee/capacity update, reminder/inbox continuation, or receiver state required by the doc, then recapture.
- Ticket mode: implementation-remediation

### LLM-B25-WR-006 - major - product-doc-interaction-gap

- Community/workflow/persona: Cedar Commons HOA / `hoa-owner-notification` / owner
- Product doc: `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-088-hoa-owner-notification-0, b25-v4-row-089-hoa-owner-notification-1, b25-v4-row-090-hoa-owner-notification-2
- Screenshot hashes: 331e5d3ba4d4bbd59a478fac3dc30188d28643301a8f8520a06ffe68c5e07c4a, 786d3ac23cfdf6a828805bfe6febb7b4990a851217eeafc767fe2705740b7dcf, 6c5424f53856dfba531e7742fcb0964f32b9a8f684670871bfc48f512ef11457
- Visible text excerpt: Notice preview | Sender and recipient | From Cedar Commons HOA Board to Avery Brooks, homeowner for Lot 42. | Message body | Your slate gray fence repaint is approved if trim remains cedar and work starts within 30 days. | Delivery | Send today at 4:15 PM to owner inbox and email receipt. | Owner inbox | Owner sees decision, sender, message body, timestamp, condition, and appeal option. | Owner decision notice | Send...
- Required fix: The screenshots show a concrete owner notice flow with sender, recipient, body, delivery time, edit notice, save draft, change audience, send notification, delivered state, inbox receipt, and appeal/reopen follow-up. The B25 semantic row is still the generic submit/save/send template, so the product doc does not fully specify the lifecycle now visible in evidence. Replace the generic semantic model with owner-notice-specific decision data, primary send action, edit/save-draft/change-audience alternatives, delivery result, and owner receiver/read state.
- Ticket mode: product-doc-update

### LLM-B25-WR-007 - major - visible-proof-gap

- Community/workflow/persona: Camera Club / `photo-walk-rsvp` / member
- Product doc: `docs/Product Docs V2/Community Examples/camera-club-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models
- Screen rows: b25-v4-row-106-photo-walk-rsvp-0, b25-v4-row-107-photo-walk-rsvp-1, b25-v4-row-108-photo-walk-rsvp-2
- Screenshot hashes: 03f70d5ca1798ade26a2671fb1f3b7c34c152962605fc45b6436b7eebaaeb9e5, 574cafe8d81975b1bc69675b69b43bf668fc9b5970d355c2b0e2e665b0f42e3e, 7006bccd9582f75dfa7360fccd97ebe5337bc3e9b74b1a9d11a3ac33e670044b
- Visible text excerpt: Downtown photo walk RSVP | Choose Going, Maybe, or Not going after checking the route, host, meetup time, capacity, and gear reminder. | Event details | Route | Dock 4, mural loop, riverfront pier, 75-minute walk. | Host | Avery Kim hosts and shares the rain-plan update. | Capacity | 12 going, 4 spots open, waitlist opens at 16. | Sat, 4:30 PM | Dock 4 meetup | 12 going / 4 open | Response choices | Going reserves a ...
- Required fix: The docs require named route/date/location/capacity, RSVP choice, change path, and confirmed state. Current screenshots prove route/event detail and action choices, but the current lifecycle scorecard fails persistent result state; the completion screen says RSVP saved without a concrete selected response and later reminder/calendar or capacity continuation. Show the selected attendance value, durable confirmation, change-until deadline, and reminder/capacity continuation state, then recapture.
- Ticket mode: implementation-remediation

### LLM-B25-WR-008 - major - visible-proof-gap

- Community/workflow/persona: Member Social Space / `platform-blocked-target` / member
- Product doc: `docs/Product Docs V2/Community Examples/platform-social-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-118-platform-blocked-target-0, b25-v4-row-119-platform-blocked-target-1, b25-v4-row-120-platform-blocked-target-2
- Screenshot hashes: f27e05b0c4e73566ccf27b4b95d04e22093418a80457c2f98eebae6e43382fcc, 0ef38f657bcc980b0d0a302fa416778e680ead092655e63c5baa91a34bd5a859, 184bfd610cf5b6573ca847429acb00505c71cc2fd38424d888e04c1246bdb6a2
- Visible text excerpt: Conversation | Sender and protected recipient | Maya Chen attempted to invite Jordan Lee; Jordan remains protected by an active block. | Attempted invite body | Invite text: "Join my community circle for Saturday event planning." | Community safety record | Safety note from moderator Alex, updated today at 10:30 AM. | Receiver protection | The protected member does not receive unsafe contact. | Blocked connection gua...
- Required fix: The docs require blocked member, reason/status, disabled message/invite state, unblock/appeal/keep-blocked or cancel-invite alternatives, safety audit, and protected receiver state. Current screenshots show the blocked guard and disabled send, but the current lifecycle scorecard fails alternate/change/reject affordance and semantic model; the action row exposes reply/mute/archive rather than the documented unblock/appeal/keep-blocked/cancel-invite choices. Add the documented safety alternatives and receiver protection state, then recapture.
- Ticket mode: implementation-remediation

### LLM-B25-WR-009 - major - surface-mismatch

- Community/workflow/persona: Member Social Space / `platform-top-banner-no-fill` / member
- Product doc: `docs/Product Docs V2/Community Examples/platform-social-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-121-platform-top-banner-no-fill-0, b25-v4-row-122-platform-top-banner-no-fill-1, b25-v4-row-123-platform-top-banner-no-fill-2
- Screenshot hashes: 0e36c60c6ce8c104fef9fd875684061b3cb70f68c119aff09ea2ae1743113aa8, 4a2dafc487167e5fbcc7a3f67d3224fd6d3e99a90819d2eed0a0e263912289b9, 611ba47662c4771c76b78af6178809b423dc684d61cebec484c16d12ddcac818
- Visible text excerpt: Top banner no-fill | Show a clear no-sponsored-message state with reserved space, disclosure, and no overlap. | Ad slot state | No sponsored message right now | Reserved slot, no-fill reason, privacy-safe suppression, and manage-ad controls preserve layout without covering content. | Reserved placement | Top banner slot remains visible with no sponsored message right now. | Reason | No fill: no eligible sponsor for t...
- Required fix: The docs specify a top-banner no-fill surface with reserved space, no-fill reason, no click/impression state, refresh-slot or inspect-reason alternative, and stable layout. Current screenshots prove the reserved slot, but the action row mixes unrelated ad-off entitlement, receipt, report, and restore controls and the lifecycle scorecard fails alternate/semantic model. Either document those extra ad-off controls for this workflow or remove them from the no-fill flow; in either case show the refresh/inspect no-fill alternative and recapture.
- Ticket mode: mixed

### LLM-B25-WR-010 - major - persona-state-gap

- Community/workflow/persona: Member Social Space / `platform-message-stream` / member
- Product doc: `docs/Product Docs V2/Community Examples/platform-social-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models
- Screen rows: b25-v4-row-142-platform-message-stream-0, b25-v4-row-143-platform-message-stream-1, b25-v4-row-144-platform-message-stream-2
- Screenshot hashes: cb87aa49dccad06c0aa6ababe2d16c0c100b90eac3ea7b4b6597cbca2c77594f, 93ffbde5b47efd1b951588bc2591327d4d20aa17b0f113b7ecaee00cd1bed78e, 58ddf9716e6a522628588d0b5010adaf4734766c5b7824b548fce8f6cde9bfdb
- Visible text excerpt: Conversation | Sender and recipient | Maya Chen -> Jordan Lee, members of the same community. | Message body | Can you bring the sign-in sheets before the meetup? | Timestamp | Today 9:12 AM, unread until opened. | Actions | Reply, mute, archive, or block remain available. | Community message thread | Read sender, recipient, timestamp, message preview, unread receipt, reply option, mute, and archive controls. | Conve...
- Required fix: The docs require participants, preview/body, timestamp, reply/mark-read/mute/archive state, and sender/receiver delivery/read continuation. Current screenshots show the thread and actions, but the current lifecycle scorecard fails persistent result state; the completion state does not sufficiently prove a durable reply/read history and receiver continuation beyond a generic thread-updated message. Add explicit read/delivery or reply-history state tied to sender/recipient, then recapture.
- Ticket mode: implementation-remediation

### LLM-B25-WR-011 - major - surface-mismatch

- Community/workflow/persona: Member Social Space / `platform-sensitive-no-fill` / member
- Product doc: `docs/Product Docs V2/Community Examples/platform-social-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-145-platform-sensitive-no-fill-0, b25-v4-row-146-platform-sensitive-no-fill-1, b25-v4-row-147-platform-sensitive-no-fill-2
- Screenshot hashes: e3bdd065a3131bfadeb0483767747b04f88a2c167322cb366edd7ef13d606002, ad7431dc2317bada08ef250f08741db20b1d684f637d5b3f8ab16a17161a3ffa, 3d1634bf37ad22a0817630620470e12ec43d40f5c0a06451fb2e95e2b31ea48d
- Visible text excerpt: Sensitive page ad guard | Show the member why ads are suppressed, preserve layout, and avoid leaking protected context. | Ad slot state | No sponsored message right now | Reserved slot, no-fill reason, privacy-safe suppression, and manage-ad controls preserve layout without covering content. | Sensitive context | Care/protected content suppresses ad targeting and click tracking. | Reason | No fill: sensitive context....
- Required fix: The docs require protected context, privacy-safe no-fill reason, no-click state, preserved content layout, and review-policy or hide-explanation alternatives. Current rows show sensitive no-fill, but the action screen switches into sponsored-message/ad-off account controls such as manage entitlement, report ad issue, and restore receipt. The lifecycle scorecard fails alternate/semantic model. Align the UI and docs around the sensitive no-fill policy interaction, add the documented policy/hide alternative, and recapture.
- Ticket mode: mixed

### LLM-B25-WR-012 - major - visible-proof-gap

- Community/workflow/persona: Member Social Space / `platform-in-stream-ad` / member
- Product doc: `docs/Product Docs V2/Community Examples/platform-social-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-166-platform-in-stream-ad-0, b25-v4-row-167-platform-in-stream-ad-1, b25-v4-row-168-platform-in-stream-ad-2
- Screenshot hashes: cf4b257599faf41cad75b7d2a425fad29c27af87c9875155d860fd7cb9909ca4, 2b4952137ba959f3d8d52b0ef12ccd557cc2929f8f2190154ce7a5e1ba410f18, 5da0bc1c170800361ae6d68fb29f5d0f7730f043f8a8a4b2b187fcd90065e7c2
- Visible text excerpt: Sponsored stream message | Show sponsor, disclosure, message copy, impression state, and dismiss/report alternatives. | In-stream placement | Sponsored by Neighborhood Newsletter | Disclosure, sponsor creative, impression state, dismiss, report, and manage-ad controls sit inside the stream. | Sponsor | Disclosure: Sponsored by Neighborhood Newsletter. | Reason | Filled ad: eligible community stream placement. | Impre...
- Required fix: The docs require sponsor identity, disclosure, body/content context, impression/click state, and report/dismiss/hide or continue controls. Current screenshots show sponsor and report/open details, but the lifecycle scorecard fails alternate/semantic model and the result state is only reviewed. Add visible dismiss/hide/report alternatives, preserve stream position, and show the resulting impression/click/dismiss state, then recapture.
- Ticket mode: implementation-remediation

### LLM-B25-WR-013 - major - surface-mismatch

- Community/workflow/persona: Ad-Free Community / `ad-off-ad-suppression` / member
- Product doc: `docs/Product Docs V2/Community Examples/ad-off-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-127-ad-off-ad-suppression-0, b25-v4-row-128-ad-off-ad-suppression-1, b25-v4-row-129-ad-off-ad-suppression-2
- Screenshot hashes: 099114860db27369df342e9020428e6cc0fa54d47fa83bdc594572f98290302d, b412a9af6945b19ff7fb400467a6f8f221615e1ee5ab997c16f80d819c96b05a, 89073f38da1b44427cd90eb4e295a376f969ca809ce4536f5bf878072087fd87
- Visible text excerpt: Ad suppression proof | Verify which ad slots are suppressed, why no ad rendered, what entitlement applies, and how to restore or audit the decision. | Ad slot state | No sponsored message right now | Reserved slot, no-fill reason, privacy-safe suppression, and manage-ad controls preserve layout without covering content. | Top banner | Suppressed: member ad-off entitlement active. | In-stream placement | Suppressed: n...
- Required fix: The product doc maps this workflow to ad suppression proof and the B25 registry maps it to an ad surface / CommunityAdSurfaceApi. Current screen rows classify it as payment / CommunityPaymentSurfaceApi with target surface requiring amount, so the workflow/persona scorecard fails missing amount even though the visible UI is an ad-suppression proof. Align the evidence/card-surface mapping and semantic model to the documented ad suppression surface, or explicitly update the doc if a payment amount is truly required, then recapture.
- Ticket mode: mixed

### LLM-B25-WR-014 - major - surface-mismatch

- Community/workflow/persona: Ad-Free Community / `ad-off-entitlement-status` / member
- Product doc: `docs/Product Docs V2/Community Examples/ad-off-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-148-ad-off-entitlement-status-0, b25-v4-row-149-ad-off-entitlement-status-1, b25-v4-row-150-ad-off-entitlement-status-2
- Screenshot hashes: 550cc781871fea433c74019d99b1408501738732a25d4dd7bfdf132a6080bb17, fcac3cf779a08b0164eefe4968f7e766a8263aa05e95d365015741189a65d001, 5d36b3b3a91018888873c66b9328b0917746e149418652f43420673a680f633c
- Visible text excerpt: Ad-off entitlement record | Open entitlement scope, expiration, subscription state, restore option, receipt link, and ad-free member view. | Ad-free account | Ad-free status active | Entitlement, receipt, renewal, restore action, and affected ad slots stay together without payment-screen context. | Scope | Member-level ad-off for current account and communities. | Expiration | Active through Aug 30, renews monthly. |...
- Required fix: The product doc maps entitlement status to active/inactive state, renewal/expiry, managed subscription, affected ad surfaces, and the ad-off entitlement / CommunityAdSurfaceApi registry. Current rows classify it as payment / CommunityPaymentSurfaceApi with a payment amount requirement, causing the scorecard to fail despite visible entitlement status. Align the card-surface/target mapping to entitlement status or revise the doc if payment amount is required on this screen, then recapture.
- Ticket mode: mixed

### LLM-B25-WR-015 - major - product-doc-interaction-gap

- Community/workflow/persona: Data Portability Community / `export-protected-redaction` / owner
- Product doc: `docs/Product Docs V2/Community Examples/export-and-migration-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping; ## 7. Persona And State Matrix; ## 8. Content And Seed Data Requirements; ### B25 Semantic Interaction Models; ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-154-export-protected-redaction-0, b25-v4-row-155-export-protected-redaction-1, b25-v4-row-156-export-protected-redaction-2
- Screenshot hashes: 4e31628d05326dc236aa76233f9c7c2485223ec298195cc66d15ebd3a6b258c9, ea3f860ebd54d5b5c075160e1fc2d4ba97406861f95d6d38232ebbe299dfd6fa, 8d1d7522dedc02c4ff5a6f0c0db8944a60e86289381b968ba8f63c8f2aab37eb
- Visible text excerpt: Protected redaction preview | Mask protected fields with policy reasons before export. | Export steps | 1 | Protected values | Phone, care, vault, payment, and private notes are masked. | 2 | Policy reason | Each masked field shows the policy and persona allowed to reveal it. | 3 | Before/after | Owner compares source label, exported safe value, and redaction count. | 4 | Owner artifact | Owner can download or transf...
- Required fix: Current screenshots show protected values, policy reasons, before/after preview, audit trail, change scope, retry, and generate export. The current workflow/persona semantic proof still fails because it expects concrete protected subject/persona terms such as protected youth/minor profile and guardian/coach visibility, while the product doc only specifies generic protected fields/redaction choices. Make the source of truth concrete: either update the product doc/seed requirements to name the protected record classes and reveal personas the proof expects, or update the evidence mapping to the generic Data Portability protected-field model, then recapture.
- Ticket mode: mixed

## Final Decision

Fail. B25 cannot close until the major reconciliation findings above are converted into remediation tickets, the product docs or evidence mappings are repaired first where required, UI/evidence remediation is completed, and fresh screenshots prove the corrected workflow/state/lifecycle details.

