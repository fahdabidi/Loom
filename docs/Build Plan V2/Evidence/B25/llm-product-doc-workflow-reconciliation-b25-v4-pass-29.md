# B25 Product Docs To Evidence Workflow Reconciliation - b25-v4-pass-29

Final decision: **fail**

Fresh review: `true`
App commit SHA: `6803c4f`
Reviewed screen rows: 195
Reviewed screenshot hashes: 195
Finding counts: 0 blocker, 5 major, 0 minor, 0 polish

## Communities Reviewed
- `pass` - Ad-Free Community: 6 Section 6 workflow ID(s), 6 implemented/captured workflow ID(s).
- `fail` - Camera Club: 3 Section 6 workflow ID(s), 3 implemented/captured workflow ID(s).
- `pass` - Cedar Commons HOA: 7 Section 6 workflow ID(s), 7 implemented/captured workflow ID(s).
- `pass` - Chess Club: 3 Section 6 workflow ID(s), 3 implemented/captured workflow ID(s).
- `fail` - Data Portability Community: 9 Section 6 workflow ID(s), 9 implemented/captured workflow ID(s).
- `pass` - Garden Club: 3 Section 6 workflow ID(s), 3 implemented/captured workflow ID(s).
- `pass` - Loom Communities Shell: 0 Section 6 workflow ID(s), 0 implemented/captured workflow ID(s).
- `fail` - Masjid Nur: 11 Section 6 workflow ID(s), 11 implemented/captured workflow ID(s).
- `fail` - Neighborhood Book Club: 7 Section 6 workflow ID(s), 7 implemented/captured workflow ID(s).
- `pass` - persona-role-inventory: 1 Section 6 workflow ID(s), 1 implemented/captured workflow ID(s).
- `fail` - Member Social Space: 8 Section 6 workflow ID(s), 8 implemented/captured workflow ID(s).
- `pass` - Riverside Youth Soccer: 7 Section 6 workflow ID(s), 7 implemented/captured workflow ID(s).

## Product Doc Rows Missing Evidence
- None found. Every non-placeholder Section 6 workflow/persona row has matching B25 screen rows and workflow/persona coverage.

## Evidence Rows Missing Product Doc Coverage
- None found. Every captured B25 workflow/persona pair maps back to Section 6 in its reviewed product doc.

## Product Doc Sections That Must Be Updated Before UI Remediation
- Data Portability Community: reconcile `export-protected-redaction` criteria across Section 6, Section 7, B25 semantic interaction models, and the card-surface registry if the intended requirement is protected youth/minor plus guardian/coach visibility. Otherwise the evidence/judge mapping must be repaired and recaptured against the existing export-specific doc requirement.
- No other product doc row is missing coverage. The remaining blockers are implementation/evidence gaps against clear product-doc requirements.

## UI / Implementation Gaps
- `photo-walk-rsvp`, `mosque-donor-visibility`, `book-vote`, and `platform-message-stream` have current lifecycle scorecards failing persistent result state, despite Section 6 and companion semantic rows requiring durable result/receiver proof.
- `export-protected-redaction` has a workflow/persona direct-question failure because the current evidence criteria demand protected-youth/guardian proof that is not aligned with the export product doc row or current screenshots.

## Ticket-Ready Findings
### LLM-B25-WR-001 - major - Data Portability Community / `export-protected-redaction` / `owner`
- Product doc: `docs/Product Docs V2/Community Examples/export-and-migration-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping, ## 7. Persona And State Matrix, ### B25 Semantic Interaction Models, ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-154-export-protected-redaction-0, b25-v4-row-155-export-protected-redaction-1, b25-v4-row-156-export-protected-redaction-2
- Screenshots: /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_start.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_action.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_export_migration_export-protected-redaction_complete.png
- Hashes: 4e31628d05326dc236aa76233f9c7c2485223ec298195cc66d15ebd3a6b258c9, 464e2d56181e948bc3afc9bcd44a97230011d252c5ba861357ffff920e8d6a09, 8d1d7522dedc02c4ff5a6f0c0db8944a60e86289381b968ba8f63c8f2aab37eb
- Visible text: Protected redaction preview | Mask protected fields with policy reasons before export. | Export steps | 1 | Protected values | Phone, care, vault, payment, and private notes are masked. | 2 | Policy reason | Each masked field shows the policy and persona allowed to reveal it. | 3 | Before/after | Owner compares source label, exported safe value, and redaction count. | 4 | Owner artifact | Owner can download or transfer only after required verification succeeds. | 5 | Audit trail | Scope, decision, timestamp, checksum, and actor are preserved. | Package progress | Apply the protected-field mask and keep before/after preview, policy reason, and reveal permission visible. | Reveal field | Generate export | Data Portability Community | Export steps | 1 | Protected values | Phone, care, vault, payment, and private notes are masked. | 2 | Policy reason | Each masked field shows the policy a...
- Required fix: Resolve the export redaction criteria drift before the next judge pass: either update the product doc and seed content to require a concrete protected-person/guardian visibility example and capture that UI, or repair/re-run the evidence mapping so export-protected-redaction is judged against export-specific protected fields, redaction choices, preview, and audit state.
- Ticket mode: `mixed`

### LLM-B25-WR-002 - major - Camera Club / `photo-walk-rsvp` / `member`
- Product doc: `docs/Product Docs V2/Community Examples/camera-club-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping, ## 7. Persona And State Matrix, ### B25 Semantic Interaction Models, ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-106-photo-walk-rsvp-0, b25-v4-row-107-photo-walk-rsvp-1, b25-v4-row-108-photo-walk-rsvp-2
- Screenshots: /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_camera_club_photo-walk-rsvp_start.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_camera_club_photo-walk-rsvp_action.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B15/screenshots/B15_ext_camera_club_photo-walk-rsvp_complete.png
- Hashes: 03f70d5ca1798ade26a2671fb1f3b7c34c152962605fc45b6436b7eebaaeb9e5, 69edc883b7b49fe647dc86bce96c5c402caf1ea75b84475dab40b935f6bad45f, 7006bccd9582f75dfa7360fccd97ebe5337bc3e9b74b1a9d11a3ac33e670044b
- Visible text: Downtown photo walk RSVP | Choose Going, Maybe, or Not going after checking the route, host, meetup time, capacity, and gear reminder. | Event details | Route | Dock 4, mural loop, riverfront pier, 75-minute walk. | Host | Avery Kim hosts and shares the rain-plan update. | Capacity | 12 going, 4 spots open, waitlist opens at 16. | Sat, 4:30 PM | Dock 4 meetup | 12 going / 4 open | Response choices | Going reserves a spot; Maybe keeps the route in your inbox; Not going releases capacity for another member. | Change response | RSVP to event | Camera Club | Event details | Route | Dock 4, mural loop, riverfront pier, 75-minute walk. | Host | Avery Kim hosts and shares the rain-plan update. | Capacity | 12 going, 4 spots open, waitlist opens at 16. | Sat, 4:30 PM | Dock 4 meetup | 12 going / 4 open | Choose attendance | Review the event, capacity, location, and reminders before saving a r...
- Required fix: Implementation/evidence remediation: make the result screen unambiguously show the selected RSVP state as confirmed/attending or not attending, preserve the change-response path, update attendee/capacity context, and recapture the three workflow screenshots so the lifecycle scorecard passes persistent result state.
- Ticket mode: `implementation-remediation`

### LLM-B25-WR-003 - major - Masjid Nur / `mosque-donor-visibility` / `donor`
- Product doc: `docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping, ## 7. Persona And State Matrix, ### B25 Semantic Interaction Models, ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-028-mosque-donor-visibility-0, b25-v4-row-029-mosque-donor-visibility-1, b25-v4-row-030-mosque-donor-visibility-2
- Screenshots: /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_start.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_action.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_mosque_mosque-donor-visibility_complete.png
- Hashes: 7d2f25d6d2a37618ca9d4cf003678a97f9dab7fc4571b41cb82e0e9e13cacdcb, b3b2e1dc7e9b09da7b870ba88690c9d8373a36bca5e7e4ba4eb5d38b30cecba1, 3fb2aac187407268daf34a42bc8d934556a263d08d027396f707836d7a771e32
- Visible text: Anonymous donor preference | Member-safe update with respectful language and privacy boundaries. | Confirm amount, donor visibility, receipt destination, and giving history before saving. | Community care | Privacy checked | Receipt record | Member inbox | Confirm the details, editable fields, final progress, and next step before saving. | Edit response | Save details | Confirm member-visible summary, protected details, receipt or citation, and recipient preview before sending. | Update privacy | Save visibility | Community setup files | Masjid Nur | Anonymous donor preference | Member-safe update with respectful language and privacy boundaries. | Confirm amount, donor visibility, receipt destination, and giving history before saving. | Confirm the details, editable fields, final progress, and next step before saving. | Edit response | Save details | Confirm member-visible summary, pr...
- Required fix: Implementation/evidence remediation: show the saved donor visibility setting, receipt destination/visibility, amount context, status/history or account result, and the available change path on the result state, then recapture the donor workflow screenshots.
- Ticket mode: `implementation-remediation`

### LLM-B25-WR-004 - major - Neighborhood Book Club / `book-vote` / `member`
- Product doc: `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping, ## 7. Persona And State Matrix, ### B25 Semantic Interaction Models, ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-034-book-vote-0, b25-v4-row-035-book-vote-1, b25-v4-row-036-book-vote-2
- Screenshots: /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_start.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_action.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B14/screenshots/B14_ext_book_club_book-vote_complete.png
- Hashes: 3a7d6717915950efa6cc01c884689f7b756f605dfee5fd511e3214fca16f7a96, f27d5dcc5003b7a068194639c7b66569dd3841fbdb1bae2d1ea3d90b58c96687, 259fc621762b894d5a2166964db5fb6d9465799a2b670a1a6c1a25f2e412438a
- Visible text: February book ballot | Vote between three member nominations. | Parable of the Sower is leading the ballot for the next monthly discussion. | 3 nominations | Closes Jan 20 | 1 member vote | Leading title | Confirm the details, editable fields, final progress, and next step before saving. | Change vote | Ballot choice | Your vote will count once for Parable of the Sower and can be changed before the ballot closes. | Record vote | Community setup files | Neighborhood Book Club | February book ballot | February selection ballot | Compare nominated books, confirm your vote, and keep the chosen discussion book visible after voting. | Confirm the details, editable fields, final progress, and next step before saving. | Change vote | Ballot choice | Your vote will count once for Parable of the Sower and can be changed before the ballot closes. | 3 nominations | Closes Jan 20 | 1 member vote |...
- Required fix: Implementation/evidence remediation: make the completed vote state durable and specific, including selected title, voted status, whether the ballot remains open/changed, and organizer/aggregate continuation state, then recapture the workflow evidence.
- Ticket mode: `implementation-remediation`

### LLM-B25-WR-005 - major - Member Social Space / `platform-message-stream` / `member`
- Product doc: `docs/Product Docs V2/Community Examples/platform-social-product-experience.md`
- Sections: ## 6. Workflow-To-Surface Mapping, ## 7. Persona And State Matrix, ### B25 Semantic Interaction Models, ### B25 Card Surface Registry Mapping
- Screen rows: b25-v4-row-142-platform-message-stream-0, b25-v4-row-143-platform-message-stream-1, b25-v4-row-144-platform-message-stream-2
- Screenshots: /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_start.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_action.png, /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/../docs/Build Plan V2/Evidence/B16/screenshots/B16_ext_platform_social_platform-message-stream_complete.png
- Hashes: 663f2751f64a621a52b031203c8f5c4807db815e72ade6531db8cdeb6e4c5ac6, 8bab690cfab11dbdeaa6a2eedde654e5074a859eeb8501017cad7e4f85b93fcd, 42d8dad55ed9f88a5f1263b37126f9a0af9d39fe981bb41e62793654b7a8a2ed
- Visible text: Conversation | Sender and recipient | Maya Chen -> Jordan Lee, members of the same community. | Message body | Can you bring the sign-in sheets before the meetup? | Timestamp | Today 9:12 AM, unread until opened. | Actions | Reply, mute, archive, or block remain available. | Community message thread | Read sender, recipient, timestamp, message preview, unread receipt, reply option, mute, and archive controls. | Conversation actions | Reply keeps the thread member-scoped and preserves read/unread receipt. | Archive thread | Send message | Member tools | Useful actions for this community. | Member Social Space | Conversation | Sender and recipient | Maya Chen -> Jordan Lee, members of the same community. | Message body | Can you bring the sign-in sheets before the meetup? | Timestamp | Today 9:12 AM, unread until opened. | Actions | Reply, mute, archive, or block remain available. | Thr...
- Required fix: Implementation/evidence remediation: show a persistent message-thread result such as sent/received/read state, reply history, archive or mute state, and recipient/thread continuation state, then recapture the workflow screenshots.
- Ticket mode: `implementation-remediation`
