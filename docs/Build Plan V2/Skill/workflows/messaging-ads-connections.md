# Messaging, Ads, and Connections

Use this workflow when building an extension that interacts with Loom's shell-owned messaging,
connections, stream, and ad surfaces.

## Process

1. Treat Messages, Connections, and the top banner ad slot as shell-owned required surfaces.
2. Do not hide, replace, or route around the shell navigation panel from extension UI.
3. Use `CommunityMessagingApi` for direct or group message streams; render stream items through the
   shell stream contract.
4. Use `CommunityConnectionsApi` for invite/block policy and mirror blocked targets in connection UI
   affordances.
5. Use `CommunityAdDecisionApi` for top banner and in-stream eligibility; never hard-code ad fill.
6. Render in-stream ad items with `kind=ad` and `disclosure=Sponsored`.
7. Treat sensitive contexts as no-fill and avoid indexing or advertising against protected data.
8. Validate in the Demo Loom Communities App with Local Backend.

## Covering Test

- `wf_messaging-ads-connections`

## Gotchas

- No-fill is not a failure for required ad slots. Suppressing the slot is the failure.
- Extensions can add their own community-specific navigation, but must preserve shell Messages and
  Connections.
- Sponsored disclosure is part of the contract; visual styling cannot remove it.
