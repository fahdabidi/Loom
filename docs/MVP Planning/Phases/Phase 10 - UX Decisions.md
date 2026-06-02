# Phase 10 - UX Decisions

## Reference Patterns Applied

- Link-in-bio and QR follow flows: persist creator handle, avatar, destination URL, QR payload, external links, and channel attribution so Phase 11 can render a credible launch hub.
- Bluesky-style starter packs: represent a source creator plus recommended creators, default-selected members, already-following state, and one idempotent bulk-follow action.
- YouTube Studio and Patreon analytics: expose a small aggregate conversion funnel with stage counts and source-channel attribution, avoiding per-fan identity leakage.
- YouTube, TikTok, Instagram, and Substack creator migration patterns: keep external account links as verified public-profile provenance, not as imported follower graphs.
- Creator-controlled ad products: store contextual ad decisions with a policy version and receipt provenance for impressions.

## Decisions

- Phase 10 intentionally implements data contracts and fakes only; primary fan/creator UX is deferred to Phases 11-14.
- Capture links are tokenized and channel-attributed so later screens can separate link-in-bio, social, email, QR, and live-callout performance.
- Link-in-bio pages are seeded for every creator because Phase 11 needs an immediately inspectable launch asset.
- Starter packs are seeded from the existing creator world instead of creating a separate recommendation ranking system.
- Public metadata import uses verified external account links and rights basis to keep provenance visible.
- Premium no-ad status is sourced from wallet/entitlement state and no-ad consumption is recorded separately for settlement provenance.

## Workflow Walkthrough

1. Creator creates or reuses a capture link with channel attribution.
2. Creator renders announcement copy or reads their link-in-bio launch page.
3. Fan resolves the capture link, sees the creator identity, and can re-follow.
4. Fan confirms a starter pack and the bulk-follow path dedupes existing follows.
5. Creator reads aggregate conversion stages without seeing raw fan rows.
6. Creator links and verifies external accounts, imports public metadata, and cross-posts a launch message.
7. Fan playback can request contextual ad decisions or record premium no-ad views with provenance.

## Implementation Notes

- Fakes are the API validation mechanism for this phase: every new surface is reachable through a typed app-shell resolver and the local store.
- Mutable launch state is resettable while seed templates/starter packs/external accounts are restored.
- Phase 11 should build the creator launch UI directly from these APIs rather than duplicating local state.
