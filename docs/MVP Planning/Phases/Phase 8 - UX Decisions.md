# Phase 8 - UX Decisions

## Reference Patterns Applied

- YouTube-style creator recommendations: lightweight disclosure near the recommended content, with details available on demand rather than blocking the feed.
- Instagram and TikTok campaign/giveaway patterns: visual card first, concise reward terms, and one obvious primary action.
- Facebook Groups/Page campaign patterns: status chips for entry and reward state so users can confirm what happened after tapping.
- WhatsApp Channels-style broadcast simplicity: creator-side campaign/recommendation builders use compact status and publish controls instead of dense admin tables.
- Existing Phase 7 consent language: sponsor data-for-value offers reuse the same purpose, field, value-exchange, and receipt vocabulary.

## Decisions

- Fan discovery now shows recommended content as a normal feed card with a `Recommended by` disclosure pill. This keeps the feed social and familiar while still making attribution visible.
- A receipt icon records qualified discovery without forcing a modal step. The receipt appears near the card after the action so validation does not require hunting through a ledger.
- Creator recommendations are handled in a Studio builder with publish-pick, publish-terms, and settle-referral actions. The layout mirrors other Studio panels: preview, status chips, then actions.
- Campaigns use a fan-facing `CampaignCard` with reward, entry state, optional sponsor offer, and clear CTAs for Enter, Issue reward, and Accept data offer.
- Sponsor data offers deliberately reuse Phase 7 consent approval and data-access receipt mechanics to avoid adding a behavioral-targeting path.

## Workflow Walkthrough

1. Creator opens Studio Recommendations, publishes the City Ferments recommendation, publishes referral terms, and can simulate a referral settlement.
2. Fan returns to discovery and sees the City Ferments card with a `Recommended by Solar Sarah` disclosure.
3. Fan records a discovery receipt from the card. The card stays in context and the receipt confirmation appears next to it.
4. Creator opens Studio Campaigns, creates the clean-energy giveaway, and attaches a Gridwise Home data-for-value offer.
5. Fan opens Campaigns, enters the giveaway, issues the demo reward, and can accept the sponsor offer.
6. Accepting the sponsor offer creates a Phase 7 grant approval and emits a DataAccessReceipt, keeping the data workflow consistent with the consent dashboard.

## Tradeoffs

- The Phase 8 fake uses in-process state for authored campaigns and recommendations to keep this phase focused on API shape and UX. Receipt and settlement evidence is persisted through the existing ledger path; full authored-object persistence is a Phase 9/export hardening candidate.
