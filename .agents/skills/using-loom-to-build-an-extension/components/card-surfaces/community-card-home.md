# Community Card and Home Surface

## Supported Interactions

- Display installed community identity, logo/card image/hero image, category, role, membership state,
  unread counts, pinned announcement, next event, and sync/install status.
- Open the latest certified extension route.
- Surface safe fallbacks when branding is missing.
- Show disabled, revoked, update-required, offline, ad-off, and safety states.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.home.read` | Open community, read summary, see next actions. |
| Owner/admin | `community.surface.home.admin` | Inspect install/version/safety state and manage branding inputs. |
| Guest/prospect | `community.surface.home.preview` | See public card and join/install prompt. |

## Custom Experience Guidance

Use this surface as the first signal of the custom community. Customize display name, tagline,
category, accent color, logo, card image, hero image, role badge, pinned item, and next-action preview.
Do not replace shell-owned layout, safety indicators, messages/connections entry, ads, or card fallback
rules.

Example: a tennis club card should show "Saturday ladder matches", a next match time, member role, and
unread match invites rather than a generic "3 workflows" counter.

## API Support

Requires `CommunityHomeSurfaceApi`: `getHomeSummary`, `listPinnedItems`, `getInstallState`,
`getUnreadCounts`, `getNextEvent`, `getMembershipBadge`, `resolveBranding`, `syncInstallStatus`.
