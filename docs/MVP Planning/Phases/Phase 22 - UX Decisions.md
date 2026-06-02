# Phase 22 - UX Decisions

## Reference Patterns Applied

Settings from modern social apps keep integrations in account/profile areas, not in the main feed body. Phase 22 exposes AI search settings through the existing discovery toolbar tune action and returns through a compact back affordance.

Connected-service rows use a service icon, display label, status, and reversible switch. YouTube is presented as the currently simulated source; Twitch, Discord, blogs, and webpages are shown as modeled future sources.

AI agent connection uses an explicit connect sheet with provider selection and endpoint entry. This mirrors account-connection flows where users choose a provider, verify a target, and see connection status after saving.

## Privacy And Consent Copy

The settings surface includes a persistent query-egress disclosure before the connection controls. It states that the fan's selected agent receives query context and that production connectors would use scoped OAuth or token exchange.

## Workflow Decisions

- Agent connection is explicit and reversible: connect/reconnect button plus disconnect icon.
- Prefer-creator content is a visible fan default, not hidden ranking behavior.
- External sources must be globally enabled before individual sources matter.
- The screen renders loading, error, and empty states so reset or dependency failures do not produce a blank settings page.
