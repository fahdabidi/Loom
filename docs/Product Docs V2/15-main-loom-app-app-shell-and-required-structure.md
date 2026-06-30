# Loom Communities Product Definition 15: The Main Loom App, App Shell, and Required Structure

Status: Draft for review
Product area: 15 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [API Reference 1.5 and 4](./Extensible%20Loom%20API%20Reference.md)
Predecessor: [Loom V1 Fan Apps and App Ecosystem](../Product%20Docs/15-fan-apps-and-app-ecosystem.md)

## 1. Product Definition

The Main Loom App is the member-facing host for all communities. The App Shell is the enforced runtime
structure that loads communities and extensions while preserving platform trust boundaries: identity,
navigation, Messages, Connections, payments, ads, consent, receipts, and required safety surfaces.

Unlike V1, V2 does not lead with many third-party fan apps. The first product surface is one Main Loom
App that can host many custom community experiences.

## 2. Scope

This area covers app login, community cards, home, nav panel, Messages, Connections, stream renderer,
extension route mounting, top ad banner, in-stream ad item rendering, payment surface, consent prompts,
data dashboard entry points, update-to-latest behavior, offline/local cache basics, and certification
lint for required structure.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Community cards | Installed communities appear as stable shell-rendered cards using community branding, extension defaults, and safe fallbacks. | Members recognize and switch communities easily. | 04, 10, 12 |
| Required nav panel | Every community exposes Messages and Connections from the shell. | Custom apps cannot hide core communication. | 12, 15 |
| Extension route host | Cards/routes/WebViews mount through typed shell contracts. | Custom UX remains governed. | 10 |
| Top ad banner | Shell-owned ad slot, suppressed only by valid ad-off policy. | Free backend funding is enforceable. | 09, 18 |
| Stream renderer | Renders messages, posts, documents, events, and injected ad items. | Extensions reuse consistent content primitives. | 09, 10 |
| Payment surface | Standard Loom-owned checkout, receipts, refund, and ad-off UI. | Extensions cannot spoof payments. | 08 |
| Consent and data controls | Members can see grants, access history, and export controls. | Data rights are reachable. | 14 |
| Latest certified version | App resolves the latest approved extension version on open. | Updates and revocations propagate. | 16, 19 |

## 4. Product Experience Requirements

Members should be able to install/add communities, switch between them, recognize them by logo/card
image, read messages, manage connections, pay, search, see ads/ad-off state, respond to extension
workflows, and control data grants without learning which extension or provider powers each community.
Owners should be confident that all generated extensions still preserve the required structure.

Community cards are owned by the App Shell. Extensions and initialization packages can provide display
name, tagline, logo, card image, hero image, category, and accent color, but they cannot replace the
card layout or hide shell-owned controls, badges, membership state, ad-off state, or safety indicators.

Card image resolution follows this order:

1. Community-specific `branding.cardImage`.
2. Community-specific `branding.logo`.
3. Extension `defaultCardImage`.
4. Generated initials/category/accent-color fallback.

### 4.1 Production Card Surfaces

The Main Loom App must host reusable production card surfaces selected by extensions and rendered
inside App Shell constraints. The catalog in [../CardSurfaces/README.md](../CardSurfaces/README.md)
defines the supported families and the backend API support they require.
The product workflow requirements for every surface interaction are tracked in
[Card Surface Workflow and User Story Coverage](./Card%20Surface%20Workflow%20and%20User%20Story%20Coverage.md),
and the executable API contract is
[Community Card Surfaces OpenAPI](../API/OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml).

The App Shell should distinguish:

- shell-owned surfaces: community card/home, navigation, messages/connections entry, ads, payments,
  consent/data dashboard, install/update state;
- extension-selected production surfaces: announcement composer/feed, event RSVP, member meetups,
  volunteer signup, equipment loans, exchanges, nominations/votes, discussions, care requests,
  approvals, documents/facilities/roster, search/AI digest, export/transfer, forms, and inbox;
- fallback surfaces: generic form only when no richer card-surface family fits.

When a production surface family exists, the shell and validators should reject a primary workflow that
is represented only as a generic workflow card with a single action. The shell, fake backend, and B25
evidence must prove the entry state, editable/alternate actions, result state, receiver state,
disabled/unauthorized state, and recovery path required by the selected surface interactions.

## 5. User Stories

1. **As a member**, I open the Main Loom App and see all installed communities.
   End state: community cards resolve latest metadata and installed extension versions.
2. **As a member**, I always find Messages and Connections.
   End state: nav panel exposes both even if the extension renames or styles them.
3. **As a member**, I pay dues through a standard Loom surface.
   End state: extension never handles raw payment credentials.
4. **As governance**, I reject an extension that hides the top ad banner.
   End state: certification lint fails.
5. **As a member**, I open a QR link and add a community.
   End state: App Shell downloads metadata and presents join/install flow.

## 6. End-to-End Workflows

### Workflow 1: Add community to app

1. Member scans QR, opens invite, enters handle, or chooses search result.
2. Community registry resolves profile and installed extension.
3. App Shell resolves card metadata, branding assets, required surfaces, and latest certified package.
4. Member reviews join state, permissions, and data notes.
5. Community card appears in app.

### Workflow 2: Render extension route

1. Member taps community card or route.
2. App Shell resolves extension version, route, surface, member role, ad-off state, and data mode.
3. Runtime bridge starts a scoped session.
4. Extension renders declarative UI or WebView inside shell constraints.
5. Shell enforces nav panel, ad banner, payment/consent surfaces, and audit hooks.

### Workflow 3: Message and connection reachability

1. Member opens nav panel.
2. Shell shows Messages and Connections entries.
3. Messages entry opens community stream or direct/group messages.
4. Connections entry opens Passport-level connections and invite actions.
5. Extension can add shortcuts but cannot remove required entries.

## 7. Cross-Area Requirements

- App Shell owns required UI invariants; extensions mount inside it.
- App Shell validates selected card surfaces against the Card Surfaces catalog and required API
  contracts, including the executable
  [Community Card Surfaces OpenAPI](../API/OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml)
  and Product Docs V2 workflow/user-story coverage map.
- App Shell owns community-card rendering; extension/init package branding is input data only.
- Card assets must have local fallbacks and must pass size, format, hash, dimension, and accessibility
  metadata checks.
- Payment, consent, ad, protected-vault, and data-dashboard surfaces are shell-owned.
- Ads are present unless ad-off entitlement or sensitive-context exclusion applies.
- Latest extension version, revocation, and certification state must be checked on open.
- App-shell components have visual/interaction tests under Architecture V2 tenets.

## 8. Prototype Implications

The MVP must build the community-card grid with branding fallback behavior, nav panel,
Messages/Connections placeholders, stream renderer, top ad banner, ad-off check, extension route host,
payment surface stub, consent prompt, and latest-version resolution.

## 9. FAQ

**Can a generated extension make the app feel custom?**
Yes. It can own routes, cards, workflows, and domain UI, but not remove the platform shell.

**Are third-party apps still possible?**
Later, through certification. V2 starts with the Main Loom App to prove the extension platform and
required structure.

## 10. Open Questions

- How much offline behavior is required for MVP?
- Which UI primitives must be declarative before WebView is allowed?
- What app-shell theming can extensions control without hiding required surfaces?
