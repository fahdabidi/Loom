# Phase 23 - UX Decisions

## Reference Patterns Applied

Modern social search mixes native results with external references only when source ownership is obvious. Phase 23 uses compact source chips, a single ranked-results section, and a disclosure above the list so fans can see that their connected agent produced the ordering.

Search result lists in YouTube, Instagram, TikTok, and Facebook keep thumbnails prominent, titles close to media, and metadata below or beside the title. Loom follows that pattern with a thumbnail column, source chip row, title area, and concise rank reason.

## Title And Attribution Decisions

- Creator-owned results lead with the content summary so clickbait-prone titles do not dominate relevance.
- External results lead with the fan's AI accurate-match label, but the original external title remains visible underneath and unchanged.
- External source chips use the public source attribution, such as `YouTube`, to avoid implying Loom ownership.
- The disclosure states there are no ads, boosts, or paid placement in the AI-ranked result set.

## Workflow Walkthrough

1. The fan connects an AI search agent and YouTube source in settings.
2. The fan searches from Discovery using the same search field as the neutral path.
3. Discovery shows a "Ranked by your AI search agent" disclosure with the audit receipt.
4. Creator-owned and external results appear in one ranked list, with source chips and per-result rank reasons.
5. Tapping "Why ranked" opens a provenance sheet showing source attribution, title-safety handling, and why the item ranked.

## Implementation Tradeoffs

The result tile is a design-system component with primitive view fields rather than API models. That keeps `loom_design_system` independent from `loom_api_contracts` while letting Discovery map `AiSearchItem` faithfully.
