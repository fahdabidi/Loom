# LLM Vision UX Review - b25-v4-pass-24

| Field | Value |
| --- | --- |
| Schema version | 4 |
| Run ID | `b25-v4-pass-24` |
| Fresh review | `true` |
| App commit SHA | `afc8425` |
| Status | `fail` |
| Reviewed screen rows | 195 |
| Reviewed unique screenshot hashes | 179 |
| Instruction file | `docs/Build Plan V2/Tools/b25-llm-vision-ux-review-instructions.md` missing |

## Scope
Reviewed only the named B25 evidence artifacts and referenced screenshots. I did not read implementation notes, worker claims, or code diffs. All referenced PNG files existed and matched their declared SHA-256 hashes.

## Direct Answers

| Question | Answer | Severity | Evidence |
| --- | --- | --- | --- |
| Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona? | `no` / `fail` | `blocker` | All 10 contact sheets show the same full-height rounded-card renderer repeated across communities and workflow states.<br>Representative full-resolution rows b25-v4-row-074, b25-v4-row-161, b25-v4-row-193, and b25-v4-row-194 show dense stacked panels with primary actions embedded in repeated cards. |
| Is information architecture centered on real community jobs and content? | `partial` / `fail` | `major` | Community nouns are present, such as Garden Club events, Masjid announcements, HOA documents, and Data Portability exports.<br>The visible structure is still repeated workflow cards with sections like Ready to save, Ready to publish, Member state, Receiver state, Local package details, and Member tools. |
| Does copy sound product-native rather than workflow/spec/test language? | `no` / `fail` | `major` | Rows repeatedly show phrasing such as Decide whether..., Decide what to save..., Ready to save, Ready to publish, Receiver state, Member state, and Review member-visible summary.<br>Row b25-v4-row-074 says Decide whether the request should be approved, rejected, revised, or sent back for changes on a member care request screen. |
| Are hierarchy, spacing, typography, color, and component variety shippable? | `partial` / `fail` | `major` | Typography is legible and spacing is generally stable, but nearly every screen uses oversized rounded cards, chips, icon badges, and one dominant hue per community.<br>Action/review states often look like the same template with a different title rather than distinct forms, detail views, receipts, or inbox screens. |
| Is repeated-card fatigue absent? | `no` / `fail` | `blocker` | Rows 001-183 are overwhelmingly repeated card stacks; rows 190-195 repeat the same Masjid announcement card flow for multi-persona proof.<br>The same Ready to..., Decide..., chips, and bottom primary-button construction appears across garden, book club, soccer, HOA, mosque, chess, camera, platform, ad-off, and export workflows. |
| Does each screen provide concrete content and lifecycle actions a real user needs? | `partial` / `fail` | `major` | Many rows include concrete content such as dates, amounts, venues, counts, authors, receipts, and privacy chips.<br>Deterministic lifecycle evidence still fails for book-search-ai-digest, hoa-owner-notification, platform-messages-entry, export-import-replay, platform-message-stream, export-protected-redaction, and export-import-preview.<br>Workflow/persona evidence fails for export-protected-redaction / owner. |

## Findings

### b25-v4-pass-24-vision-blocker-001 - BLOCKER: Primary UX is still a repeated workflow-card scaffold across the evidence set
- Community: all reviewed communities
- Workflow: `all reviewed workflows`
- Persona: `all reviewed personas`
- Screen rows: 195 rows
- Visible evidence: All 195 reviewed rows render as variations of the same stacked rounded-card template.; Contact sheets 01-10 show repeated hero cards, chip rows, Ready to... panels, Decide... helper panels, and bottom primary buttons across unrelated communities.; Representative rows b25-v4-row-074, b25-v4-row-161, b25-v4-row-193, and b25-v4-row-194 confirm the issue at full resolution.
- Why: B25 requires production community UX, not a generic renderer. Even when domain labels are present, the visual system and layout do not differentiate events, payments, messages, exports, care requests, documents, approvals, and receipts enough for a shippable product experience.
- Required fix: Replace the universal card scaffold with domain-native screens by workflow family: event detail/RSVP, marketplace offer form/detail, payment checkout and receipt, care request form and status, admin review queue, inbox/thread, document library, export wizard, transfer status, and role-aware home surfaces.

### b25-v4-pass-24-vision-major-002 - MAJOR: Visible copy exposes workflow-contract language instead of product-native task language
- Community: multiple communities
- Workflow: `multiple workflows`
- Persona: `multiple personas`
- Screen rows: 9 rows
- Visible evidence: b25-v4-row-074 shows Decide whether the request should be approved, rejected, revised, or sent back for changes on a member care request action screen.; b25-v4-row-161 shows Decide the scope, redaction, checksum, destination, and whether to retry, roll back, or change scope.; b25-v4-row-193 and b25-v4-row-194 show Ready for final review, Update ready, and repeated Preview announcement prompts in member receiver states.
- Why: This wording tells users about validation and workflow state instead of naturally guiding the community task. It keeps the UI feeling like a test harness or UX contract artifact.
- Required fix: Remove Decide..., Ready to..., Receiver state, Member state, and similar contract phrasing from user-visible screens. Replace it with concrete task copy, object status, next action, and consequence language.

### b25-v4-pass-24-vision-major-003 - MAJOR: Several workflow/persona lifecycles still lack concrete object context or persistent result state
- Community: Neighborhood Book Club; Cedar Commons HOA; Member Social Space; Data Portability Community
- Workflow: `book-search-ai-digest; hoa-owner-notification; platform-messages-entry; export-import-replay; platform-message-stream; export-protected-redaction; export-import-preview`
- Persona: `community-book-club-member; community-hoa-owner; community-platform-social-member; community-export-migration-owner; community-platform-social-member; community-export-migration-owner; community-export-migration-owner`
- Screen rows: 21 rows
- Visible evidence: Lifecycle scorecards fail for book-search-ai-digest and hoa-owner-notification because concrete object/context is missing.; Lifecycle scorecards fail for platform-messages-entry, export-import-replay, platform-message-stream, export-protected-redaction, and export-import-preview because persistent result state is missing.; The screenshots for these rows use generic result labels and repeated review panels instead of durable task-specific completion states.
- Why: A real user must be able to return later and understand what object changed, what decision was made, and what state persists. The current evidence does not prove that for all required workflows.
- Required fix: For each failed workflow, add after screenshots that visibly show the named object, final status, actor/receiver context, audit/receipt where relevant, and a durable continuation path. Rerun the workflow lifecycle judge and the LLM vision review.

### b25-v4-pass-24-vision-major-004 - MAJOR: Persona picker and role inventory evidence exposes local test-harness UI as reviewed product surface
- Community: Masjid Nur; persona-role-inventory
- Workflow: `wf_demo-app-persona-picker; wf_persona-role-inventory-capability-matrix`
- Persona: `community-mosque-member; persona-role-inventory-admin; persona-role-inventory-member`
- Screen rows: 4 rows
- Visible evidence: b25-v4-row-186 shows a modal titled Choose persona with the helper copy Preview the community experience for each member role.; Rows b25-v4-row-184 and b25-v4-row-185 include persona inventory / picker surfaces inside the reviewed UX evidence rather than a production account or role-aware screen.
- Why: The B25 standard treats the people-icon persona picker as a local test harness only. Including it as a reviewed workflow surface weakens the production UX evidence and exposes role-switching mechanics that should come from identity and membership state.
- Required fix: Keep persona switching in test harness evidence only, or replace these rows with production role-aware states that show the signed-in persona, permissions, and unavailable actions without exposing a Choose persona dialog.

## Workflow/Persona Result

All 68 workflow/persona scorecards are marked failing in this fresh vision review because the global repeated-card scaffold and contract-copy findings block B25. Additional deterministic failures remain for:

- `book-search-ai-digest` / `community-book-club-member`: concrete object/context (b25-v4-row-037-book-search-ai-digest-0, b25-v4-row-038-book-search-ai-digest-1, b25-v4-row-039-book-search-ai-digest-2)
- `hoa-owner-notification` / `community-hoa-owner`: concrete object/context (b25-v4-row-088-hoa-owner-notification-0, b25-v4-row-089-hoa-owner-notification-1, b25-v4-row-090-hoa-owner-notification-2)
- `platform-messages-entry` / `community-platform-social-member`: persistent result state (b25-v4-row-115-platform-messages-entry-0, b25-v4-row-116-platform-messages-entry-1, b25-v4-row-117-platform-messages-entry-2)
- `export-import-replay` / `community-export-migration-owner`: persistent result state (b25-v4-row-130-export-import-replay-0, b25-v4-row-131-export-import-replay-1, b25-v4-row-132-export-import-replay-2)
- `platform-message-stream` / `community-platform-social-member`: persistent result state (b25-v4-row-142-platform-message-stream-0, b25-v4-row-143-platform-message-stream-1, b25-v4-row-144-platform-message-stream-2)
- `export-protected-redaction` / `community-export-migration-owner`: persistent result state (b25-v4-row-154-export-protected-redaction-0, b25-v4-row-155-export-protected-redaction-1, b25-v4-row-156-export-protected-redaction-2)
- `export-import-preview` / `community-export-migration-owner`: persistent result state (b25-v4-row-175-export-import-preview-0, b25-v4-row-176-export-import-preview-1, b25-v4-row-177-export-import-preview-2)
- `export-protected-redaction` / `community-export-migration-owner`: workflow/persona scorecard failed (b25-v4-row-154-export-protected-redaction-0, b25-v4-row-155-export-protected-redaction-1, b25-v4-row-156-export-protected-redaction-2)

## Verdict

Fail. The evidence shows meaningful progress from raw workflow harness copy, but the visible UI is not yet shippable as a modern production community app. B25 should remain blocked until the repeated-card renderer, exposed contract copy, test-harness persona surfaces, and lifecycle failures are remediated and recaptured.
