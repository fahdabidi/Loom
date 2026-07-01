# B25 LLM Vision Product UX Review - Pass 23

| Field | Value |
| --- | --- |
| Run ID | `b25-v4-pass-23` |
| Review type | `llm-vision-product-ux` |
| Fresh review | `true` |
| App commit SHA | `c6dfca9` |
| Status | `fail` |
| Blockers | `0` |
| Majors | `4` |
| Minors | `1` |
| Reviewed screen rows | `195` |

## Direct Question Answers

- `isUiModernEasyToUseEasyToNavigateVisuallyAppealingForTargetUsers`: **partial**. Many screens are modern mobile cards with readable hierarchy and clear actions, especially Garden Club, Soccer, Camera Club, Ad-Free, and several Masjid flows. The overall answer is not a full yes because Chess is thin/repeated, Data Portability repeats one wizard across distinct tasks, and Book Club has visible domain mismatches.
- `doesEachMainScreenFeelLikeRichCommunityProductRatherThanWorkflowValidationChecklistSurface`: **no**. Most community screens improved beyond checklist modals, but the Book Club AI digest is a generic Community activity card, Data Portability is largely the same wizard repeated with changed titles, and Chess Club repeats a thin home/match card shell.
- `doesEachWorkflowPersonaHaveDomainNativeContentEnoughContextCompleteLifecycleActionsStatuses`: **partial**. Coverage is broad and most workflows have entry/action/result states. The failing workflows lack sufficient domain-native content or have copied cross-domain labels, especially book-search-ai-digest, book-export-metadata, the portability utility workflows, and chess flows.
- `areLayoutOverlapClippingCrowdingWeakHierarchyThinContentGenericCardDefaultScaffoldModalChecklistRepeatedSurfaceProblemsAbsent`: **no**. No obvious pixel-level overlap or clipping was visible in the contact-sheet review, but thin-content, generic-card, one-note/repeated-surface problems remain visible in the failed workflows.
- `wouldFreshTargetUserUnderstandWhatToDoAndWhyWithoutTestWorkflowLanguage`: **partial**. Most target users would understand the main actions from the visible labels. Fresh users would be confused by generic Book Club AI digest language, Book Club export guardian/coach labels, repeated portability screens, and local persona-picker preview language if counted as production UI.

## Workflow/Persona Summary

| Status | Count |
| --- | ---: |
| `pass` | 51 |
| `partial` | 3 |
| `fail` | 14 |

Failed workflow/persona rows:
- `b25-wp-013-book-search-ai-digest-community-book-club-member` - Neighborhood Book Club / `book-search-ai-digest` / member: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-020-book-export-metadata-community-book-club-owner` - Neighborhood Book Club / `book-export-metadata` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-033-chess-local-install-open-community-chess-club-member` - Chess Club / `chess-local-install-open` / member: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-034-chess-route-home-community-chess-club-member` - Chess Club / `chess-route-home` / member: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-035-chess-match-result-community-chess-club-member` - Chess Club / `chess-match-result` / member: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-044-export-import-replay-community-export-migration-owner` - Data Portability Community / `export-import-replay` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-045-export-full-bundle-community-export-migration-owner` - Data Portability Community / `export-full-bundle` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-046-export-transfer-verification-community-export-migration-owner` - Data Portability Community / `export-transfer-verification` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-052-export-protected-redaction-community-export-migration-owner` - Data Portability Community / `export-protected-redaction` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-053-export-redacted-bundle-community-export-migration-owner` - Data Portability Community / `export-redacted-bundle` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-054-export-transfer-rollback-community-export-migration-owner` - Data Portability Community / `export-transfer-rollback` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-059-export-import-preview-community-export-migration-owner` - Data Portability Community / `export-import-preview` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-060-export-schema-listing-community-export-migration-owner` - Data Portability Community / `export-schema-listing` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.
- `b25-wp-061-export-checksum-evidence-community-export-migration-owner` - Data Portability Community / `export-checksum-evidence` / owner: Fresh screenshot review found a major domain-native surface or repeated-template issue for this workflow.

Partial workflow/persona rows:
- `b25-wp-062-wf-persona-role-inventory-capability-matrix-persona-role-inventory-admin` - persona-role-inventory / `wf_persona-role-inventory-capability-matrix` / admin: This appears to be a local persona/testing surface rather than production member UX.
- `b25-wp-063-wf-persona-role-inventory-capability-matrix-persona-role-inventory-member` - persona-role-inventory / `wf_persona-role-inventory-capability-matrix` / member: This appears to be a local persona/testing surface rather than production member UX.
- `b25-wp-064-wf-demo-app-persona-picker-community-mosque-member` - Masjid Nur / `wf_demo-app-persona-picker` / member: This appears to be a local persona/testing surface rather than production member UX.

## Findings

### B25-P23-VISION-MAJOR-001 - MAJOR - Book Club AI digest is a generic Community activity card, not a book search answer surface

Communities: Neighborhood Book Club
Workflows: `book-search-ai-digest`
Personas: member
Affected rows: `b25-v4-row-037-book-search-ai-digest-0`, `b25-v4-row-038-book-search-ai-digest-1`, `b25-v4-row-039-book-search-ai-digest-2`

Visible evidence: Rows 037-039 show the primary title "Community activity" with copy such as "Member task with visible state and next steps," "Review the community object," "Details ready," "Editable," and "State saved." The only book-club content appears below as an upcoming event, so the AI digest itself does not look like a book search, cited digest, or discussion research surface.

Issue: A fresh book-club member would not understand that this workflow is an AI/citation digest for books. The visible UI exposes a generic task scaffold instead of a domain-native search result or cited answer experience.

Reference pattern to copy: Use a search/AI answer detail pattern: visible query, book or discussion sources, cited snippets, answer summary, save/share controls, and a persistent result state tied to the book club.

Required UX change: Replace the generic Community activity cards with a book-specific digest screen for the searched title or discussion prompt. Show cited source rows, excerpt attribution, confidence/recency, and member actions such as save to discussion notes or ask a follow-up.

Acceptance criteria: Rows for book-search-ai-digest no longer contain "Community activity," "member task," or generic state labels; screenshots show a book-club query, cited answer content, source/citation metadata, and a clear saved/ready result state.

### B25-P23-VISION-MAJOR-002 - MAJOR - Book Club export metadata uses youth-sports protected-data language

Communities: Neighborhood Book Club
Workflows: `book-export-metadata`
Personas: owner
Affected rows: `b25-v4-row-058-book-export-metadata-0`, `b25-v4-row-059-book-export-metadata-1`, `b25-v4-row-060-book-export-metadata-2`

Visible evidence: Rows 058-060 are labeled Neighborhood Book Club but show export copy about "protected member or minor profile fields" and a chip labeled "Guardian/coach visibility." Those terms do not belong to the book-club export context.

Issue: The owner export flow appears to reuse a soccer/minor-data template. This breaks domain trust and makes it unclear what book-club data will actually be exported or redacted.

Reference pattern to copy: Use a data export wizard scoped to the actual community domain, with schema names and redaction labels that match the product.

Required UX change: Rewrite the Book Club export flow around nominations, votes, meeting RSVPs, discussion messages, reading schedule, member names/contact redaction, checksum, download, and audit history.

Acceptance criteria: Book Club export screenshots contain no guardian/coach/minor youth-sports labels and instead list book-club schemas, redaction preview, checksum, destination/download status, and owner-visible audit trail.

### B25-P23-VISION-MAJOR-003 - MAJOR - Data Portability workflows repeat the same wizard surface with insufficient task-specific detail

Communities: Data Portability Community
Workflows: `export-checksum-evidence`, `export-full-bundle`, `export-import-preview`, `export-import-replay`, `export-protected-redaction`, `export-redacted-bundle`, `export-schema-listing`, `export-transfer-rollback`, `export-transfer-verification`
Personas: owner
Affected rows: `b25-v4-row-130-export-import-replay-0`, `b25-v4-row-131-export-import-replay-1`, `b25-v4-row-132-export-import-replay-2`, `b25-v4-row-133-export-full-bundle-0`, `b25-v4-row-134-export-full-bundle-1`, `b25-v4-row-135-export-full-bundle-2`, `b25-v4-row-136-export-transfer-verification-0`, `b25-v4-row-137-export-transfer-verification-1`, `b25-v4-row-138-export-transfer-verification-2`, `b25-v4-row-154-export-protected-redaction-0`, `b25-v4-row-155-export-protected-redaction-1`, `b25-v4-row-156-export-protected-redaction-2`, `b25-v4-row-157-export-redacted-bundle-0`, `b25-v4-row-158-export-redacted-bundle-1`, `b25-v4-row-159-export-redacted-bundle-2`, `b25-v4-row-160-export-transfer-rollback-0`, `b25-v4-row-161-export-transfer-rollback-1`, `b25-v4-row-162-export-transfer-rollback-2`, `b25-v4-row-175-export-import-preview-0`, `b25-v4-row-176-export-import-preview-1`, `b25-v4-row-177-export-import-preview-2`, `b25-v4-row-178-export-schema-listing-0`, `b25-v4-row-179-export-schema-listing-1`, `b25-v4-row-180-export-schema-listing-2`, `b25-v4-row-181-export-checksum-evidence-0`, `b25-v4-row-182-export-checksum-evidence-1`, `b25-v4-row-183-export-checksum-evidence-2`

Visible evidence: Rows 130-183 all share nearly identical cards: "Scope, redaction, checksum, destination, and audit trail," "Portability wizard," "Checksum 9A7F-PORT," "Transfer rollback available," and "Guardian/coach visibility." Import replay, full export, transfer verification, protected redaction, rollback, schema listing, and checksum verification differ mostly by title.

Issue: The portability product reads like one repeated validation template, not a set of rich utility workflows. Owners cannot distinguish what is unique about import preview, transfer verification, rollback, schema listing, checksum evidence, or redacted bundle creation.

Reference pattern to copy: Use a production export/import wizard with distinct steps per task: source selection, schema table, redaction diff, transfer status timeline, checksum proof, rollback confirmation, and receipt/audit result.

Required UX change: Create differentiated layouts/content for each portability workflow. Import preview should show source package and conflicts; full/redacted bundles should show schema counts and destination; transfer verification should show provider status; rollback should show affected transfer and consequence; schema listing should show an actual schema table; checksum evidence should show hash/proof details.

Acceptance criteria: Each portability workflow screenshot has a distinct task-specific primary object, decision data, action, and result. The repeated generic copy/chips are removed or relegated to shared metadata, and no unrelated guardian/coach label appears unless the selected package actually contains that data.

### B25-P23-VISION-MAJOR-004 - MAJOR - Chess Club screens are thin and repeated rather than a rich club home and match-result experience

Communities: Chess Club
Workflows: `chess-local-install-open`, `chess-match-result`, `chess-route-home`
Personas: member
Affected rows: `b25-v4-row-097-chess-local-install-open-0`, `b25-v4-row-098-chess-local-install-open-1`, `b25-v4-row-099-chess-local-install-open-2`, `b25-v4-row-100-chess-route-home-0`, `b25-v4-row-101-chess-route-home-1`, `b25-v4-row-102-chess-route-home-2`, `b25-v4-row-103-chess-match-result-0`, `b25-v4-row-104-chess-match-result-1`, `b25-v4-row-105-chess-match-result-2`

Visible evidence: Rows 097-105 repeat the same brown card shell and repeated "Chess Club home" content. The local install and route home flows are visually indistinguishable, row 103 still shows "Local package details," and the match result action is mostly static text rather than a scoring/review surface with standings impact.

Issue: The chess experience is understandable but not rich enough for a production community surface. It feels like a renamed generic card stack and does not give players a real ladder, pairings, match-entry, correction, or standings workflow.

Reference pattern to copy: Use a sports/club home pattern with schedule/standings sections and a match result form/detail screen with players, score, correction path, standings delta, and next pairing.

Required UX change: Make the chess home a real club dashboard with tonight ladder, pairings, standings, and next match. Make match-result screens show score entry/review, opponent confirmation, dispute/correction, standings impact, and saved result history.

Acceptance criteria: Chess screenshots show distinct home, route/open, and match-result surfaces; no production screenshot shows "Local package details" as primary content; the match result flow includes concrete player/score controls, standings update, correction/dispute path, and saved result state.

### B25-P23-VISION-MINOR-001 - MINOR - Persona picker exposes local preview language in reviewed screenshots

Communities: Masjid Nur, persona-role-inventory
Workflows: `wf_demo-app-persona-picker`, `wf_persona-role-inventory-capability-matrix`
Personas: admin, member
Affected rows: `b25-v4-row-184-wf-persona-role-inventory-capability-matrix-0`, `b25-v4-row-185-wf-persona-role-inventory-capability-matrix-1`, `b25-v4-row-186-wf-demo-app-persona-picker-0`, `b25-v4-row-187-wf-demo-app-persona-picker-1`

Visible evidence: Rows 184-186 show a modal labeled "Choose persona" with copy "Preview the community experience for each member role." This is clearly a local testing/persona harness rather than normal member product language.

Issue: This is acceptable as a demo-app testing control, but it should not be counted as a production community screen for fresh target users.

Reference pattern to copy: Keep role switching in developer/demo controls and keep production member UI derived from signed-in identity, membership, and permissions.

Required UX change: Mark these rows as local harness-only or ensure the picker is hidden from production screenshots. If it remains in B25 evidence, classify it separately from product community surfaces.

Acceptance criteria: Production review rows do not require a target member to understand persona-picker/test preview language; any persona picker evidence is labeled harness-only and excluded from production UX pass claims.

## Reviewed Evidence

Reviewed all `195` screen rows from the current B25 evidence. Major-failing rows: `b25-v4-row-037-book-search-ai-digest-0`, `b25-v4-row-038-book-search-ai-digest-1`, `b25-v4-row-039-book-search-ai-digest-2`, `b25-v4-row-058-book-export-metadata-0`, `b25-v4-row-059-book-export-metadata-1`, `b25-v4-row-060-book-export-metadata-2`, `b25-v4-row-097-chess-local-install-open-0`, `b25-v4-row-098-chess-local-install-open-1`, `b25-v4-row-099-chess-local-install-open-2`, `b25-v4-row-100-chess-route-home-0`, `b25-v4-row-101-chess-route-home-1`, `b25-v4-row-102-chess-route-home-2`, `b25-v4-row-103-chess-match-result-0`, `b25-v4-row-104-chess-match-result-1`, `b25-v4-row-105-chess-match-result-2`, `b25-v4-row-130-export-import-replay-0`, `b25-v4-row-131-export-import-replay-1`, `b25-v4-row-132-export-import-replay-2`, `b25-v4-row-133-export-full-bundle-0`, `b25-v4-row-134-export-full-bundle-1`, `b25-v4-row-135-export-full-bundle-2`, `b25-v4-row-136-export-transfer-verification-0`, `b25-v4-row-137-export-transfer-verification-1`, `b25-v4-row-138-export-transfer-verification-2`, `b25-v4-row-154-export-protected-redaction-0`, `b25-v4-row-155-export-protected-redaction-1`, `b25-v4-row-156-export-protected-redaction-2`, `b25-v4-row-157-export-redacted-bundle-0`, `b25-v4-row-158-export-redacted-bundle-1`, `b25-v4-row-159-export-redacted-bundle-2`, `b25-v4-row-160-export-transfer-rollback-0`, `b25-v4-row-161-export-transfer-rollback-1`, `b25-v4-row-162-export-transfer-rollback-2`, `b25-v4-row-175-export-import-preview-0`, `b25-v4-row-176-export-import-preview-1`, `b25-v4-row-177-export-import-preview-2`, `b25-v4-row-178-export-schema-listing-0`, `b25-v4-row-179-export-schema-listing-1`, `b25-v4-row-180-export-schema-listing-2`, `b25-v4-row-181-export-checksum-evidence-0`, `b25-v4-row-182-export-checksum-evidence-1`, `b25-v4-row-183-export-checksum-evidence-2`.
