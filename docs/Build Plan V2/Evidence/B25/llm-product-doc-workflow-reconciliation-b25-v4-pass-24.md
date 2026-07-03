# B25 Product Docs To Evidence Workflow Reconciliation - b25-v4-pass-24

**Decision:** fail
**Fresh review:** true
**App commit SHA:** afc8425

## Summary

Reviewed 12 community example product docs, 69 Section 6 workflow rows, 195 B25 screen rows, and 179 unique screenshot hashes for b25-v4-pass-24. The 68 B25-covered workflow/persona rows have screenshot coverage, but current pass-24 evidence has 7 major semantic lifecycle failures, and the Loom shell product doc is not reconcilable by current B25 evidence because it has no B25 semantic model or B25 coverage row.

## Communities Reviewed

| Community | Product doc | Section 6 rows | B25 implemented rows | Status |
| --- | --- | ---: | ---: | --- |
| Ad-Free Community | `docs/Product Docs V2/Community Examples/ad-off-product-experience.md` | 6 | 6 | `pass` |
| Camera Club | `docs/Product Docs V2/Community Examples/camera-club-product-experience.md` | 3 | 3 | `pass` |
| Cedar Commons HOA | `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md` | 7 | 7 | `fail` |
| Chess Club | `docs/Product Docs V2/Community Examples/chess-club-product-experience.md` | 3 | 3 | `pass` |
| Data Portability Community | `docs/Product Docs V2/Community Examples/export-and-migration-product-experience.md` | 9 | 9 | `fail` |
| Garden Club | `docs/Product Docs V2/Community Examples/garden-club-product-experience.md` | 3 | 3 | `pass` |
| Loom Communities shell | `docs/Product Docs V2/Community Examples/loom-communities-shell-product-experience.md` | 1 | 0 | `fail` |
| Masjid Nur | `docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md` | 13 | 11 | `pass` |
| Neighborhood Book Club | `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md` | 7 | 7 | `fail` |
| persona-role-inventory | `docs/Product Docs V2/Community Examples/persona-role-inventory-product-experience.md` | 2 | 1 | `pass` |
| Member Social Space | `docs/Product Docs V2/Community Examples/platform-social-product-experience.md` | 8 | 8 | `fail` |
| Riverside Youth Soccer | `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md` | 7 | 7 | `pass` |

## Product Doc Rows Missing Evidence

- `docs/Product Docs V2/Community Examples/loom-communities-shell-product-experience.md`: local-build-download-sideload-install

## Evidence Rows Missing Product Doc Coverage

None found among the 68 B25-covered workflow/persona rows; every captured workflow ID is present in a community product doc Section 6 row.

## Product Doc Sections That Must Be Updated

- `docs/Product Docs V2/Community Examples/loom-communities-shell-product-experience.md`: add `### B25 Semantic Interaction Models` for `local-build-download-sideload-install`, or move the shell flow out of this reconciliation scope and update gate inputs accordingly.

## UI / Implementation Gaps Against Product Docs

- `book-search-ai-digest` / `community-book-club-member` (Neighborhood Book Club): The product doc declares this workflow/persona as a B25 workflow and the semantic model requires a complete production lifecycle. Current pass-24 lifecycle evidence fails for missing group(s): concrete object/context. Required fix: Add visible domain data before the action: title/name, relevant dates/timing/amounts/audience/status/content, and the actor/receiver context needed for this workflow.
- `hoa-owner-notification` / `community-hoa-owner` (Cedar Commons HOA): The product doc declares this workflow/persona as a B25 workflow and the semantic model requires a complete production lifecycle. Current pass-24 lifecycle evidence fails for missing group(s): concrete object/context. Required fix: Add visible domain data before the action: title/name, relevant dates/timing/amounts/audience/status/content, and the actor/receiver context needed for this workflow.
- `platform-messages-entry` / `community-platform-social-member` (Member Social Space): The product doc declares this workflow/persona as a B25 workflow and the semantic model requires a complete production lifecycle. Current pass-24 lifecycle evidence fails for missing group(s): persistent result state. Required fix: Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona.
- `export-import-replay` / `community-export-migration-owner` (Data Portability Community): The product doc declares this workflow/persona as a B25 workflow and the semantic model requires a complete production lifecycle. Current pass-24 lifecycle evidence fails for missing group(s): persistent result state. Required fix: Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona.
- `platform-message-stream` / `community-platform-social-member` (Member Social Space): The product doc declares this workflow/persona as a B25 workflow and the semantic model requires a complete production lifecycle. Current pass-24 lifecycle evidence fails for missing group(s): persistent result state. Required fix: Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona.
- `export-protected-redaction` / `community-export-migration-owner` (Data Portability Community): The product doc declares this workflow/persona as a B25 workflow and the semantic model requires a complete production lifecycle. Current pass-24 lifecycle evidence fails for missing group(s): persistent result state. The workflow/persona scorecard also fails for this same workflow/persona pair. Required fix: Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona.
- `export-import-preview` / `community-export-migration-owner` (Data Portability Community): The product doc declares this workflow/persona as a B25 workflow and the semantic model requires a complete production lifecycle. Current pass-24 lifecycle evidence fails for missing group(s): persistent result state. Required fix: Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona.

## Ticket-Ready Findings

| ID | Severity | Community | Workflow | Persona | Screen rows | Screenshot hashes | Required fix |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `LLM-B25-WR-001` | `major` | Neighborhood Book Club | `book-search-ai-digest` | `community-book-club-member` | b25-v4-row-037-book-search-ai-digest-0, b25-v4-row-038-book-search-ai-digest-1, b25-v4-row-039-book-search-ai-digest-2 | 084b20dbc594ada5e2a9360ee07e114af6546deba194234abcc25f19bd6e2c74, ee8f007e32b4e3ee9f0c35a82ec0af67bab604a2ffcc9930f761bbbfc843ce0f, a2a76009ad38d331bf3f4b4f8e114514be09f6287e39efd4fed6df68a7d88daf | Add visible domain data before the action: title/name, relevant dates/timing/amounts/audience/status/content, and the actor/receiver context needed for this workflow. |
| `LLM-B25-WR-002` | `major` | Cedar Commons HOA | `hoa-owner-notification` | `community-hoa-owner` | b25-v4-row-088-hoa-owner-notification-0, b25-v4-row-089-hoa-owner-notification-1, b25-v4-row-090-hoa-owner-notification-2 | 76e3f623980abc71cd9691b5be1bea67aca4f70b5f2590b1bd33f3efebdbe4c9, fb1f41cd434a6387406a76fa7f7dfa03b69e1f5a4d6970cd2b35363b63cdbe48, 8c91c548ee250c47aff31015426b3ce59021868824bb87ad15f93a346704d114 | Add visible domain data before the action: title/name, relevant dates/timing/amounts/audience/status/content, and the actor/receiver context needed for this workflow. |
| `LLM-B25-WR-003` | `major` | Member Social Space | `platform-messages-entry` | `community-platform-social-member` | b25-v4-row-115-platform-messages-entry-0, b25-v4-row-116-platform-messages-entry-1, b25-v4-row-117-platform-messages-entry-2 | 8dc4aeef3213bf0a18e723405be598d4fc3ad8fd65ae706a3e912334e30562a3, 99ccbc020cc33e61e28186080afe0ffe3ccff0495634f345adc6a3cfd7045e55, 87ae065ef3a38a51600dfffdbb0ca03463ef3d990325bff2dcde8547f4b3aef3 | Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona. |
| `LLM-B25-WR-004` | `major` | Data Portability Community | `export-import-replay` | `community-export-migration-owner` | b25-v4-row-130-export-import-replay-0, b25-v4-row-131-export-import-replay-1, b25-v4-row-132-export-import-replay-2 | 1f031f14addb25673082fcc5bb24a24fcaa2ca5a11f935e3f1878c553045aad4, cfb3479724b6e553f7f9b35805c2a1b0f24e51c0ff05465ed11c62b3c8ea850c, 09d3f1fdb9c14be522a4d8a1d82ae6f008336bd7646a524ea726776fa2efaef3 | Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona. |
| `LLM-B25-WR-005` | `major` | Member Social Space | `platform-message-stream` | `community-platform-social-member` | b25-v4-row-142-platform-message-stream-0, b25-v4-row-143-platform-message-stream-1, b25-v4-row-144-platform-message-stream-2 | 8dc4aeef3213bf0a18e723405be598d4fc3ad8fd65ae706a3e912334e30562a3, 99ccbc020cc33e61e28186080afe0ffe3ccff0495634f345adc6a3cfd7045e55, 87ae065ef3a38a51600dfffdbb0ca03463ef3d990325bff2dcde8547f4b3aef3 | Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona. |
| `LLM-B25-WR-006` | `major` | Data Portability Community | `export-protected-redaction` | `community-export-migration-owner` | b25-v4-row-154-export-protected-redaction-0, b25-v4-row-155-export-protected-redaction-1, b25-v4-row-156-export-protected-redaction-2 | c0fc01a627f15fb2ac2833a64095ac5b6edde547984662e2ae216b2c349a26ca, c978dd92bfeeb35d98ad5191907fb44d089f856349c227a0952883868c140ef6, 87a92a866735f922bac0df052979e8cf3c8389c45980e6618d285aaef1f0d64a | Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona. |
| `LLM-B25-WR-007` | `major` | Data Portability Community | `export-import-preview` | `community-export-migration-owner` | b25-v4-row-175-export-import-preview-0, b25-v4-row-176-export-import-preview-1, b25-v4-row-177-export-import-preview-2 | 1f031f14addb25673082fcc5bb24a24fcaa2ca5a11f935e3f1878c553045aad4, cfb3479724b6e553f7f9b35805c2a1b0f24e51c0ff05465ed11c62b3c8ea850c, 09d3f1fdb9c14be522a4d8a1d82ae6f008336bd7646a524ea726776fa2efaef3 | Add completion/result/receipt/history state and, for multi-persona or broadcast workflows, the receiver/read/continuation state visible to the next persona. |
| `LLM-B25-WR-008` | `major` | Loom Communities shell | `local-build-download-sideload-install` | `owner-tester` |  |  | Either add an explicit B25 semantic interaction model and B25 evidence/productDocCoverage rows for the shell workflow, or move the shell workflow to a clearly non-B25-scoped artifact and update the reconciliation gate inputs so every included community doc is reconcilable. |

## Reviewed Evidence

- Screen rows reviewed: 195
- Unique screenshot hashes reviewed: 179
- Evidence inputs: `docs/Build Plan V2/Tools/b25-product-doc-workflow-reconciliation-llm-gate.md`, `docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json`, `docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md`, `docs/Build Plan V2/Evidence/B25/workflow-persona-coverage-matrix.md`
