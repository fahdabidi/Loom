# Loom Communities Shell Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Loom Communities shell |
| Community type | Platform shell / local demo host |
| Product promise | Help a user install, recognize, open, and manage local communities without seeing extension mechanics. |
| Brand cues | Clear Loom shell chrome, branded community cards, useful empty state, ad/messages/connections access. |
| What this must not feel like | Raw extension list, package-debug screen, workflow inventory, or file-loader test harness. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Owner/tester | Installs local package pairs | Add the first community, inspect cards, open the latest local community. | Package paths and errors must be clear without exposing unsafe internals. | Installed community appears as a branded card and opens into its own product home. |
| Member | Opens installed community | Choose the right community from recognizable identity and recent activity. | Shell must preserve messages, connections, ads/ad-off invariants. | Member recognizes the community and reaches the right role-specific surface. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Empty home | Explain that no communities are installed. | Owner/tester | Friendly empty state, install purpose, Add Community CTA. | Add Community |
| Installed communities | Show recognizable community cards. | Owner/member | Logo/icon, display name, tagline, current status, local badge if needed. | Open community |
| Local install | Validate extension/init package pair. | Owner/tester | Selected files, validation/import status, actionable errors. | Validate and install |
| Community tab shell | Keep Home and Messages visible while allowing community-defined tabs. | Member | tab labels/icons/order, pinned surfaces, unread state, selected tab. | Switch tab |
| Focused surface navigation | Navigate long sets of card surfaces without a flat workflow list. | Member | minimized/medium/expanded states, pinned surface, current focus, scroll position. | Expand surface |
| Community theme system | Make community cards and in-community surfaces feel branded but accessible. | Owner/member | color, typography role, icon/image, contrast validation. | Apply theme |

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Member | Home, Messages, Connections, Communities | recently used communities, unread messages, install/sync state | Shell cards use each community theme while preserving common title/detail/action typography. |
| Owner/builder | Home, Communities, Install, Evidence, Messages | local package loader, validation status, package details | Builder tabs expose local-demo evidence without making production members see harness language. |

## 4. Home Screen Requirements

The first shell screen must show either a polished empty state or useful community cards. It must not
show raw extension IDs, package implementation details, or test-only workflow labels as the primary UI.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Community card list | identity, tagline, status, recent activity cue | empty/installed/updated/error | add, open, retry | raw package list |
| Add Community flow | extension package, init package, validation/import result | waiting/validating/installed/error | browse, validate, install | debug path dump |
| Tabs/pinning/focus | Home + Messages, community tabs, assigned/pinned surfaces, minimized/medium/expanded states | default/customized/pinned/focused/expanded | switch tab, pin/unpin, expand/collapse | long global workflow list |
| Theme/customization | community card and surface theme tokens, bounded typography, imagery, contrast | valid/invalid/applied/fallback | preview theme, apply, reset | arbitrary unreadable styling |

## 6. Workflow-To-Surface Mapping

The Loom Communities shell is a platform host, not a community extension. B25 community screenshot
reconciliation should not treat the local package install flow as one of the community/example
workflows unless a future pass adds dedicated shell screenshot rows, workflow/persona scorecards, and
semantic lifecycle evidence for it.

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| _No B25 community screenshot workflow rows_ | _N/A_ | _N/A_ | _N/A_ | _N/A_ | Shell flow remains covered by B1a, B9, B10, and B11. |

## 6A. Platform Workflow Mapping Outside B25

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| local-build-download-sideload-install | Owner/tester | Add Community flow and installed card | package pair selected, import succeeds, branded card appears | Local backend import, App Shell open latest | B1a, B9, B10, B11; explicitly scoped out of B25 community screenshot reconciliation |
| app-shell-tabs-pinning-theme | Member | Community tab shell and focused surface navigation | Home + Messages tabs, custom tabs, pinned surface, minimized/medium/expanded behavior, applied theme tokens | App Shell navigation/theme/card surface APIs | B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| local-build-download-sideload-install | Owner/tester can add package pair | Member later sees installed card | Installed card readable | Add disabled while validating | Invalid packages show error and do not install |
| app-shell-tabs-pinning-theme | member switches tabs and expands focused surfaces | community surfaces render in assigned tabs with pinned items retained | inactive tabs/cards remain reachable/readable | invalid theme/tab config falls back safely | extensions cannot remove Home or Messages/Communication |

### B25 Scope Note

The shell local-install workflow is validated by B1a, B9, B10, and B11. It is not an owned B25
community/product-experience screenshot row unless a future pass explicitly adds shell screenshots,
screen rows, and semantic lifecycle scorecards for this workflow.

## 8. Content And Seed Data Requirements

Use distinct community names, logos/icons, taglines, local install status, actionable import errors,
tab labels/icons, pinned surfaces, focused-card states, and safe theme tokens.

## 9. Visual And Interaction Standard

The shell should feel calm and app-like: clear hierarchy, no overlapping FABs, card imagery or icons,
mobile-safe spacing, and immediate access to Messages and Connections.

The shell must support Home and Messages/Communication by default, optional community-defined tabs
such as Calendar/Documents/Teams/Giving/Marketplace, pinned card surfaces within tabs, minimized,
medium/in-focus, and expanded surface states, and bounded community theme tokens for community title,
detail, card-surface title, body, label, button, edit-text, badge, and metadata.

### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `local-build-download-sideload-install` | [community-card-home](../../CardSurfaces/community-card-home.md) | `CommunityRegistryApi` / `CommunityExtensionPackageApi` | select extension package, select initialization package, validate/import, render installed card, open local route | Demo shell renderer owns this flow; B25 community screenshot reconciliation treats it as out of scope unless shell evidence rows are added. |
| `app-shell-tabs-pinning-theme` | [app-shell-navigation-theming](../../CardSurfaces/app-shell-navigation-theming.md) | `CommunityAppShellNavigationApi` | Home + Messages tabs, custom tabs, surface assignment, pin/unpin, minimized/medium/expanded state, persisted focus, community theme validation, messages-tab state | Demo shell renderer must show tab navigation, pinned/focused/expanded surface behavior, theme tokens, and fixed Messages/Communication access. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical shell product experience. | Judge current shell evidence against this doc. | open |
