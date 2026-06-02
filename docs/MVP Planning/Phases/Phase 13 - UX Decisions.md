# Phase 13 - UX Decisions

## References Applied

- YouTube Studio analytics: compact funnel/card composition, source breakdowns, and quick refresh actions.
- Patreon membership editors: tier previews, benefits chips, price validation language, and saved entitlement state.
- YouTube Studio import flows: import status, provenance, imported-reference preview, and rights-basis visibility.
- Creator ad controls: allow/block category chips and immediate policy verification before trusting playback behavior.
- Archive/search preview tools: suggested creator-side question, cited answer block, and source rows.

## Key Decisions

- Conversion analytics use one aggregate funnel card with mini source bars and an explicit privacy notice instead of per-fan tables.
- Catalog import remains public-metadata only; the screen shows the verified external account and imported references with rights basis.
- The ad-policy console saves policy then immediately calls the ad decision API so creators can see the latest policy taking effect.
- The archive AI preview has one clear creator-side prompt and cited source rows, matching fan Q&A behavior without exposing extra fan state.
- Membership setup keeps validation and preview in one screen: save tiers, register entitlements, and render resulting tier cards.
- Studio dashboard buttons stay compact and operational, matching the Phase 11 launch/grow controls rather than adding a marketing-style landing page.

## Workflow Walkthrough

1. Creator opens Funnel and sees aggregate reached, re-followed, member, and premium stages with source-channel bars.
2. Creator opens Import, starts a public metadata job, and reviews imported references plus provenance.
3. Creator opens Ads, saves a policy block list, and sees downstream ad-decision verification.
4. Creator opens AI, asks the archive preview question, and reviews cited answer/source rows.
5. Creator opens Membership setup, saves tier drafts, and sees the saved tier cards and entitlement counts.
