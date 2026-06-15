# Community Card

Use `CommunityCardProps` and `CommunityCardBranding` for installed community cards.

## Extension Use

- Provide display name, tagline, category, accent color, and alt text.
- Prefer community-specific card image, then logo, then extension default card image.
- Let the shell render the card instead of extension-owned arbitrary UI.

## Validation

- `vt_community-card_render-bind` and `vt_community-card_branding-priority` prove card binding and fallback order.
