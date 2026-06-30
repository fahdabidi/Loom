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

## 4. Home Screen Requirements

The first shell screen must show either a polished empty state or useful community cards. It must not
show raw extension IDs, package implementation details, or test-only workflow labels as the primary UI.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Community card list | identity, tagline, status, recent activity cue | empty/installed/updated/error | add, open, retry | raw package list |
| Add Community flow | extension package, init package, validation/import result | waiting/validating/installed/error | browse, validate, install | debug path dump |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| local-build-download-sideload-install | Owner/tester | Add Community flow and installed card | package pair selected, import succeeds, branded card appears | Local backend import, App Shell open latest | B1a, B9, B10, B11, B25 shell rows |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| local install | Owner can add package pair | Member later sees installed card | Installed card readable | Add disabled while validating | Invalid packages show error and do not install |

## 8. Content And Seed Data Requirements

Use distinct community names, logos/icons, taglines, local install status, and actionable import errors.

## 9. Visual And Interaction Standard

The shell should feel calm and app-like: clear hierarchy, no overlapping FABs, card imagery or icons,
mobile-safe spacing, and immediate access to Messages and Connections.

### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `local-build-download-sideload-install` | [ad](../../CardSurfaces/ads-no-fill-ad-off.md) | `CommunityAdSurfaceApi` | ad decision, impression/click/no-fill, disclosure/ad-off, restore/receipt evidence | Demo renderer must select a domain-native surface for `ad` and LocalInAppBackend must expose/import the state for these interactions. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical shell product experience. | Judge current shell evidence against this doc. | open |
