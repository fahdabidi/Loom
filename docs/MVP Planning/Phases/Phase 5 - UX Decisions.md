# Phase 5 - UX Decisions

Date: 2026-06-01

## Reference patterns applied

- Search/chat hybrid pattern: a focused question field, suggested prompt, and answer card rather than a generic full chat log.
- YouTube-style source preview: citations are compact chips tied to creator content and open a source detail sheet.
- WhatsApp-style clarity: the question and answer are visually direct, but creator provenance stays primary.
- Social feed controls: the summary-first agent appears as a compact feed preference toggle on the fan home.
- Trust-forward AI disclosure: confidence, cited segments, and source receipts are visible in the flow.

## Key implementation decisions

- Archive Q&A opens from the creator channel so the user understands which creator archive is being queried.
- The answer card shows a short answer first, then citation chips. Tapping a citation opens the exact returned segment and royalty basis.
- Receipt rows are shown below the answer so AI usage and source attribution are auditable without leaving the screen.
- The summary-first agent toggle lives on discovery, not inside the Q&A screen, because it affects ranking behavior rather than one answer.
- The summary-rank note states that the existing candidate set is unchanged and titles are deemphasized.

## Workflow walkthrough

- Fan opens Solar Sarah from discovery, then taps Ask archive on the channel page.
- The archive Q&A screen shows the creator context, AI policy disclosure, default suggested prompt, and Ask action.
- Asking returns a cited answer with compact source chips; no full transcript is displayed.
- Tapping a citation opens the source segment plus source-attribution royalty basis.
- The answer surface displays AI usage and source-attribution receipts.
- Back on discovery, enabling Summary-first agent reorders the current eligible feed candidates and updates the why sheet with summary and title-deemphasis evidence.

## Validation notes

- Focused Phase 5 integration tests passed for archive Q&A, summary-first ranking, and source royalty citation.
- Full emulator integration validation passed for Phases 0-5 together, 23/23 tests.
- The manual checkpoint launch screenshot shows the summary-first agent control integrated into the modern fan discovery surface.
