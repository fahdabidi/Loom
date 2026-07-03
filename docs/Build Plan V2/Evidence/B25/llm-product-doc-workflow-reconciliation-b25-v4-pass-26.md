# B25 Product Docs To Evidence Workflow Reconciliation - b25-v4-pass-26

- Decision: fail
- Fresh review: true
- App commit SHA: 6cc79e3
- Product docs reviewed: 12
- Screen rows reviewed: 195
- Screenshot hashes reviewed: 195
- Major reconciliation findings: 6

## Summary

Every B25-scoped Section 6 workflow ID is present in the current screenshot-backed evidence, and every captured B25 workflow maps back to a Product Docs V2 community product doc. The shell install flow is explicitly scoped out of B25 community screenshot reconciliation by its product doc.

The reconciliation still fails. Current evidence conflicts with Product Docs V2 surface, content, semantic interaction, and visual standards: repeated card-renderer surfaces cover all 65 B25 workflows, 56 workflows still expose review/spec-like copy, 14 workflows have duplicate screenshot proof across distinct states, and the current review records lifecycle gaps for 26 workflows.

## Communities Reviewed

| Community | Product doc | Status | Declared workflows | Implemented B25 workflows | Blocking gap groups |
| --- | --- | --- | ---: | ---: | ---: |
| Ad-Free Community | `docs/Product Docs V2/Community Examples/ad-off-product-experience.md` | fail | 6 | 6 | 3 |
| Camera Club | `docs/Product Docs V2/Community Examples/camera-club-product-experience.md` | fail | 3 | 3 | 4 |
| Cedar Commons HOA | `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` | fail | 7 | 7 | 4 |
| Chess Club | `docs/Product Docs V2/Community Examples/chess-club-product-experience.md` | fail | 3 | 3 | 2 |
| Data Portability Community | `docs/Product Docs V2/Community Examples/export-and-migration-product-experience.md` | fail | 9 | 9 | 3 |
| Garden Club | `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` | fail | 3 | 3 | 2 |
| Loom Communities shell | `docs/Product Docs V2/Community Examples/loom-communities-shell-product-experience.md` | pass | 0 | 0 | 0 |
| Masjid Nur | `docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md` | fail | 11 | 11 | 3 |
| Neighborhood Book Club | `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md` | fail | 7 | 7 | 3 |
| persona-role-inventory | `docs/Product Docs V2/Community Examples/persona-role-inventory-product-experience.md` | fail | 1 | 1 | 2 |
| Member Social Space | `docs/Product Docs V2/Community Examples/platform-social-product-experience.md` | fail | 8 | 8 | 4 |
| Riverside Youth Soccer | `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` | fail | 7 | 7 | 4 |

## Product Doc Rows Missing Evidence

None as complete B25-scoped workflow IDs. The shell `local-build-download-sideload-install` row is explicitly scoped out of this B25 screenshot reconciliation.

## Evidence Rows Missing Product Doc Coverage

None as complete workflow IDs. All 65 captured B25 workflow IDs are declared in Product Docs V2 Section 6 rows.

## Product Doc Sections To Update Before UI Remediation

- `cedar-commons-hoa-product-experience.md`: replace generic B25 semantic rows for `hoa-facility-reservation`, `hoa-committee-decision`, and `hoa-owner-notification` with domain-specific decisions, actions, alternate paths, results, and receiver states.
- `neighborhood-book-club-product-experience.md`: replace the generic `book-search-ai-digest` semantic row with search-specific cited-answer, follow-up, revise-query, save/share, stale-citation, and saved-result states.

## UI Or Evidence Gaps Where Docs Are Clear

- All 65 B25 workflows need domain-native surfaces instead of the repeated rounded-card renderer.
- The 56 workflows listed in `LLM-B25-WR-003` need production copy rather than review/spec/harness phrasing.
- The 14 workflows listed in `LLM-B25-WR-004` need distinct screenshots or merged evidence when the state is intentionally shared.
- The 26 workflows listed in `LLM-B25-WR-005` need visible entry, decision, primary action, alternate/change/reject path, persistent result, and receiver/continuation states.
- All 65 B25 workflows need Section 9 visual-standard remediation for hierarchy, title truncation, component variety, color variety, and scannability.

## Ticket-Ready Findings

| ID | Severity | Gap | Workflows | Screen rows | Required fix |
| --- | --- | --- | --- | ---: | --- |
| LLM-B25-WR-001 | major | product-doc-interaction-gap | book-search-ai-digest, hoa-committee-decision, hoa-facility-reservation, hoa-owner-notification | 12 | Update the B25 semantic interaction rows before UI remediation: hoa-facility-reservation must name facility reservation actions and conflict/change/cancel states; hoa-committee-decision must name approve/reject/request-changes/comment/history and owner receiver state; hoa-owner-notification must name edit notice, send notice, delivery/read/appeal or reope... |
| LLM-B25-WR-002 | major | surface-mismatch | ad-off-ad-suppression, ad-off-community-checkout, ad-off-entitlement-status, ad-off-member-checkout, ad-off-receipt-evidence, ad-off-settlement-utility, book-discussion-message, book-export-metadata, book-meeting-rsvp, book-nomination, book-search-ai-digest... | 195 | Replace the repeated card renderer with domain-native product surfaces per community: event detail/RSVP, feed/inbox/thread, donation/payment checkout, receipt/history, protected care request form, admin review queue, social connection guard, export/import wizard, and transfer status screens with visibly distinct layouts and content density. |
| LLM-B25-WR-003 | major | visible-proof-gap | ad-off-community-checkout, ad-off-member-checkout, book-discussion-message, book-export-metadata, book-meeting-rsvp, book-nomination, book-search-ai-digest, book-selection-publish, book-vote, chess-local-install-open, chess-match-result, chess-route-home, c... | 141 | Rewrite user-facing copy as domain product language. Remove review/spec/test phrasing and local package or persona-preview copy from production-facing screens. Put implementation metadata behind diagnostics, not in the primary community experience. |
| LLM-B25-WR-004 | major | visible-proof-gap | chess-local-install-open, chess-route-home, export-full-bundle, export-import-preview, export-import-replay, export-redacted-bundle, mosque-announcement, mosque-care-request, platform-message-stream, platform-messages-entry, wf_community-persona-aware-ux, w... | 27 | Recapture or redesign the affected workflows so every distinct workflow/persona/state has visibly distinct content, state, and lifecycle proof. If two rows intentionally share a surface, merge the evidence rather than claiming separate production states. |
| LLM-B25-WR-005 | major | product-doc-interaction-gap | ad-off-ad-suppression, ad-off-settlement-utility, book-search-ai-digest, export-checksum-evidence, export-import-preview, export-import-replay, export-protected-redaction, export-schema-listing, export-transfer-rollback, export-transfer-verification, gear-l... | 78 | For each affected workflow/persona pair, capture entry, decision, primary action, alternate/change/reject path, persistent result, receipt/history/status, and receiver/continuation states in visible UI. The member/receiver state must not reuse actor/composer copy. |
| LLM-B25-WR-006 | major | surface-mismatch | ad-off-ad-suppression, ad-off-community-checkout, ad-off-entitlement-status, ad-off-member-checkout, ad-off-receipt-evidence, ad-off-settlement-utility, book-discussion-message, book-export-metadata, book-meeting-rsvp, book-nomination, book-search-ai-digest... | 195 | Improve production visual hierarchy: shorter responsive app-bar titles or branded headers, more varied domain components, less oversized card stacking, clearer section density, and layouts that make primary decisions visible without excessive scroll. |

## Acceptance Gate

B25 cannot close on this reconciliation pass. Update the generic semantic product-doc rows first, remediate or recapture the affected UI/evidence, and rerun B25 until this artifact has zero blocker or major reconciliation findings.
