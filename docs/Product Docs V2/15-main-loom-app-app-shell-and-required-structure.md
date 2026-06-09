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
| Community cards | Installed communities appear as stable cards. | Members switch communities easily. | 04, 12 |
| Required nav panel | Every community exposes Messages and Connections from the shell. | Custom apps cannot hide core communication. | 12, 15 |
| Extension route host | Cards/routes/WebViews mount through typed shell contracts. | Custom UX remains governed. | 10 |
| Top ad banner | Shell-owned ad slot, suppressed only by valid ad-off policy. | Free backend funding is enforceable. | 09, 18 |
| Stream renderer | Renders messages, posts, documents, events, and injected ad items. | Extensions reuse consistent content primitives. | 09, 10 |
| Payment surface | Standard Loom-owned checkout, receipts, refund, and ad-off UI. | Extensions cannot spoof payments. | 08 |
| Consent and data controls | Members can see grants, access history, and export controls. | Data rights are reachable. | 14 |
| Latest certified version | App resolves the latest approved extension version on open. | Updates and revocations propagate. | 16, 19 |

## 4. Product Experience Requirements

Members should be able to install/add communities, switch between them, read messages, manage
connections, pay, search, see ads/ad-off state, respond to extension workflows, and control data grants
without learning which extension or provider powers each community. Owners should be confident that
all generated extensions still preserve the required structure.

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
3. App Shell downloads card, required surfaces, and latest certified package.
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
- Payment, consent, ad, protected-vault, and data-dashboard surfaces are shell-owned.
- Ads are present unless ad-off entitlement or sensitive-context exclusion applies.
- Latest extension version, revocation, and certification state must be checked on open.
- App-shell components have visual/interaction tests under Architecture V2 tenets.

## 8. Prototype Implications

The MVP must build the community-card grid, nav panel, Messages/Connections placeholders, stream
renderer, top ad banner, ad-off check, extension route host, payment surface stub, consent prompt, and
latest-version resolution.

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
