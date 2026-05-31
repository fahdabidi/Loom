# Phase 2 - UX Decisions

Date: 2026-05-31

## References Reviewed

Patterns were extracted from common creator and social publishing products: YouTube Studio upload flows, Instagram and TikTok post composers, Facebook/Meta creator tools, WhatsApp Channels-style broadcast setup, and compact SaaS creator dashboards.

## Patterns Applied

- Creator tools should feel like a work console: dense, status-led, and action-oriented rather than a basic form.
- Upload/publish flows put media preview first, then title and summary/description, then validation and publish actions.
- Advanced setup tasks work best as compact panels or progressive modules so the main publishing path stays visible.
- Policy and monetization controls should show saved state immediately after the write.
- Summary/description requirements should be enforced inline and server-side; the UI should make failure visible without sending the creator away from the composer.

## Key Decisions

- Phase 2 is entered from the completed Phase 1 creator onboarding screen with an `Open publishing setup` action, preserving the creator workflow continuity.
- The Studio surface is a single scrollable setup console with a dark header, status cards, a media-first composer, import, membership, ad policy, and AI panels.
- The composer includes an AI draft summary action because the required-summary rule is critical and creators need a fast way to produce an acceptable draft before publishing.
- The import, membership, ad-policy, and AI flows are compact one-action modules for the demo. They expose the essential payload/result without overbuilding multi-screen editors before manual validation.
- The app uses generated-looking media panels and Studio status cards instead of plain text-only rows so the surface reads more like a modern creator app.

## Workflow Walkthrough

1. Creator completes Phase 1 channel setup and accepts managed hosting.
2. Creator opens publishing setup and sees immediate readiness metrics: published items, membership tiers, and ad policy state.
3. Creator tests missing summary validation. The fake backend rejects the write with `summary_required`, and the composer shows the inline error.
4. Creator drafts a summary, publishes a video, and sees a manifest version success state.
5. Creator starts catalog import and gets an imported-reference success state once the async fake job completes.
6. Creator defines membership tiers; the UI reports entitlement definitions registered for later playback/wallet phases.
7. Creator saves ad policy and enables AI archive policy; both panels show persisted success states.

## Manual UX Validation Focus

- Does the Studio screen feel modern enough for a creator publishing workflow?
- Is the summary-required path clear and recoverable?
- Are membership, ad policy, import, and AI setup compact enough without feeling hidden?
- Should Phase 3 consume this screen as-is, or should any Phase 2 setup task become a deeper editor before discovery work begins?
