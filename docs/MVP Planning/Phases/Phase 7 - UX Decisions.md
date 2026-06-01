# Phase 7 - UX Decisions

## References Reviewed

Phase 7 followed the extracted social-app guidance already captured in the phase plan: YouTube/Instagram account privacy and creator tools, TikTok audience controls, Facebook/Meta ad preference and data access patterns, WhatsApp-style concise settings rows, and creator-dashboard audience insight patterns.

## Patterns Applied

- Fan data rights live behind a shield icon in the Fan App toolbar, matching familiar account/privacy utility placement.
- Consent requests use compact cards with creator name, purpose, requested fields, value exchange, and explicit approve/narrow/deny actions.
- Defaults and ad preferences use settings-row patterns so fan controls feel like account settings instead of developer switches.
- Creator audience uses a Studio-style panel: approved fan count, permission status, top aggregate categories, request action, and explicit approved-data query.
- Relationship controls are row-based and action-oriented: private direct contact and tombstone request each have one clear action.

## Key UX Decisions

- Keep fan data rights and creator audience in separate surfaces. The fan sees consent and receipts; the creator sees aggregate/approved audience state.
- Show the data grant purpose and value exchange directly in the request card so approval is tied to a clear benefit.
- Make "Narrow" a first-class action, not a hidden advanced setting, because data minimization is the core Phase 7 workflow.
- Show access receipts only after approved data is queried. This makes the receipt ledger match actual access, not attempted access.
- Put creator audience beside creator revenue as a Studio action so manual validation can jump directly to the data-for-value workflow.
- Use labels plus icons for consent/default controls in this phase because privacy decisions need higher clarity than icon-only controls.

## Workflow Walkthrough

1. Creator opens Audience from Creator Studio and sends a grant request for fan interest fields.
2. Fan opens Data rights from the Fan App toolbar.
3. Fan reviews the request card, approves it fully or narrows it to `interest_categories`.
4. Creator queries approved data; only approved fields render in the Audience panel and a receipt is emitted.
5. Fan returns to Data rights and can revoke the grant; future creator queries return no fields.
6. Fan can set category defaults, disable personalized ads, revoke direct contact, and request a relationship tombstone from the same dashboard.
7. Fan access receipts remain visible in the data dashboard after actual approved access.

## Tradeoffs

- The demo stores one active grant in widget state for immediate review feedback; persisted audit rows remain in Drift for API validation.
- Category defaults are demonstrated with the creator vertical rather than a broad category taxonomy UI. A richer taxonomy can be added after the real API defines it.
- The creator audience panel stays row/card based instead of chart-heavy so the privacy flow remains readable on a phone-sized emulator.

## Validation Notes

The Phase 7 validation path is covered in [Phase Validation Walkthrough](../Phase%20Validation%20Walkthrough.md). Manual validation can run Fan App Data rights and Creator Studio Audience while implementation proceeds to Phase 8.
