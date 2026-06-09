# Loom Communities Product Definition 10: Extension Platform

Status: Draft for review
Product area: 10 of 22 (Loom Communities / V2)
Source inputs: [Extensible Loom Product Definition 5-7](./Extensible%20Loom%20Product%20Definition.md#5-platform-architecture), [API Reference 2](./Extensible%20Loom%20API%20Reference.md#2-extension-platform-apis)
Predecessor: [Loom V1 Creator Plugins / Extensions / Campaign Layer](../Product%20Docs/10-creator-plugins-extensions-campaign-layer.md)

## 1. Product Definition

The extension platform is the core of V2. It lets a community run a custom experience without a custom
backend. An extension is an installable package containing a manifest, cards, routes, UI, data schemas,
permissions, rules, workflows, jobs, fixtures, tests, and optional sandboxed functions. It mounts into
the Main Loom App through the App Shell and drives backend behavior by composing stable Loom APIs.

Extensions own experience and domain logic. Loom owns identity, membership, roles, consent, payments,
protected data, ads, receipts, audit, certification, and export.

## 2. Scope

This area covers extension packages, manifests, surfaces, runtime bridge, permission model,
configuration, declarative rules, workflows, jobs, sandboxed functions, data schemas, event bus usage,
installation, update, rollback, uninstall, certification tiers, fixtures, tests, and export behavior.
The Skill that authors packages is Product 11; builder supply chain is Product 16; certification
governance is Product 19; App Shell rendering is Product 15.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Extension package | `loom.extension.json` plus UI, assets, schemas, rules, workflows, jobs, tests, and fixtures. | Custom apps become portable artifacts. | 11, 16, 19 |
| Runtime bridge | Permissioned session bridge for API calls, events, and UI context. | Extensions never receive raw credentials or direct DB access. | 05, 15 |
| Four backend levels | Config, declarative rules, workflows/jobs, and sandboxed functions. | Most vertical logic avoids bespoke services. | 08, 11 |
| Data schema store | Extension-defined entities stored, permissioned, audited, and exported by Loom. | Custom data does not create lock-in. | 14, 21 |
| Event bus integration | Extensions react to typed platform events. | Automation remains decoupled and testable. | Architecture V2 08 |
| Certification tiers | Risk-based validation from themes to functions/connectors/payments/minors. | Extension power grows with safety controls. | 17, 19 |
| Latest-on-open | Main App resolves latest certified version on community open. | Communities get fixes without manual installs. | 15, 16 |
| Required invariant lint | Packages must preserve App Shell nav, Messages, Connections, and ad surfaces. | Custom UX cannot remove platform obligations. | 09, 15 |

## 4. Extension Package Model

The locked package shape is two downloadable artifacts: a runtime extension package and an
initialization package.

```text
<extension-id>.loom-extension.zip
  loom.extension.json
  ui/
    cards/
    routes/
    assets/
    webview/
  assets/
    brand/
      extension-icon.png
      default-community-logo.png
      default-card-image.png
      default-hero-image.png
    images/
    icons/
    thumbnails/
  schemas/
  rules/
  workflows/
  jobs/
  functions/
  fixtures/
  tests/
  docs/
  signatures/
    manifest.hash
    build-attestation.json

<extension-id>.loom-init.zip
  loom.initialization.json
  seed/
    assets/
  fixtures/
  import-plan.json
```

The runtime package contains:

- Manifest: id, version, community type, surfaces, permissions, event subscriptions, risk tier, export
  behavior, compatibility, certification metadata, asset declarations, and card presentation defaults.
- UI: declarative cards/routes, bundled assets, and optional WebView mini-app bundle.
- Assets: extension icon, default community logo, default card image, default hero image, image/icon
  libraries, thumbnails, hashes, dimensions, and alt/decorative metadata.
- Backend declarations: config, rules, workflows, jobs, data schemas, and optional functions.
- Fixtures and tests: seed data, validation tests, workflow tests, and permission-negative tests.
- Documentation: owner install notes, member-facing data-use explanations, and export support.

The initialization package contains community-instance data:

- Community profile: display name, tagline, category, handle suggestion, locale/time zone defaults.
- Community branding: logo, card image, hero image, accent color, and image metadata.
- Seed data: spaces, initial roles, initial records, rules, workflows, jobs, and fixtures.
- Import plan: idempotency keys, import order, rollback expectations, and report fields.

The extension package provides defaults. The initialization package provides community-specific
personalization for a concrete installed community. Local-demo mode must not depend on remote images.

### 4.1 Card Presentation and Branding

Community cards are rendered by the Loom App Shell, not by arbitrary extension UI. Packages may provide
metadata and assets, but the shell owns card layout, badges, required controls, accessibility, and
fallbacks.

The card image priority is:

1. Community-specific `branding.cardImage` imported from `loom.initialization.json`.
2. Community-specific `branding.logo`.
3. Extension `assets.brand.defaultCardImage`.
4. Generated fallback from community initials, category, and accent color.

`loom.extension.json` must declare extension-level defaults:

```json
{
  "assets": {
    "extensionIcon": "assets/brand/extension-icon.png",
    "defaultCommunityLogo": "assets/brand/default-community-logo.png",
    "defaultCardImage": "assets/brand/default-card-image.png",
    "defaultHeroImage": "assets/brand/default-hero-image.png"
  },
  "cardPresentation": {
    "template": "standard-community-card",
    "titleSource": "community.displayName",
    "subtitleSource": "community.tagline",
    "imageSource": "community.branding.cardImage",
    "fallbackImage": "assets/brand/default-card-image.png"
  }
}
```

`loom.initialization.json` may override community instance branding:

```json
{
  "community": {
    "displayName": "Oak Street Book Club",
    "tagline": "Monthly reads and neighborhood discussions",
    "category": "book-club",
    "branding": {
      "logo": "seed/assets/oak-book-club-logo.png",
      "cardImage": "seed/assets/oak-book-club-card.png",
      "heroImage": "seed/assets/oak-book-club-hero.png",
      "accentColor": "#3E6B58"
    }
  }
}
```

## 5. Backend Extensibility Levels

| Level | Mechanism | Use for | Guardrail |
| --- | --- | --- | --- |
| 1 | Configuration | Dues amount, roster size, meeting cadence. | No code, owner editable. |
| 2 | Rules | Event-condition-action automation. | Mutations via Loom APIs only. |
| 3 | Workflows and jobs | Multi-step approvals, reminders, recurring invoices. | State machines are versioned and auditable. |
| 4 | Sandboxed functions | Scheduling, rankings, eligibility, complex calculations. | Higher certification tier and no raw data bypass. |

## 6. Product Experience Requirements

Owners should be able to install an extension, review requested permissions and surfaces, see risk tier,
approve or narrow permissions, run fixtures/previews, update to latest version, roll back if allowed,
and uninstall safely. Members should see what the extension does and what data it can access. Builders
should receive stable APIs, fakes, validators, and certification feedback.

## 7. User Stories

1. **As a builder**, I create a youth soccer extension using rules and workflows.
   End state: package validates without backend code.
2. **As an owner**, I approve only the extension permissions needed for my community.
   End state: install grant narrows runtime access.
3. **As a member**, I see data-use explanations before interacting with a form.
   End state: consent and policy govern access.
4. **As governance**, I reject a function that tries to bypass protected vault rules.
   End state: certification fails with actionable output.
5. **As an owner**, I export community data including extension-defined records.
   End state: export package includes schemas and records.

## 8. End-to-End Workflows

### Workflow 1: Build and publish extension

1. Builder or Skill generates manifest, UI, schemas, rules, workflows, tests, and documentation.
2. Local validator checks package structure, permissions, App Shell invariants, export behavior, and
   test fixtures.
3. Artifact is signed with App ID and build attestation.
4. Extension registry stores version and runs certification.
5. Approved package becomes discoverable or installable.

### Workflow 2: Owner installs extension

1. Owner selects extension from builder output, QR link, marketplace, or template.
2. Install screen shows surfaces, permissions, data classes, jobs, rules, functions, ad/nav effects,
   and risk tier.
3. Owner approves, narrows, or rejects permissions.
4. Runtime grant is stored and App Shell receives card/route registrations.
5. Latest certified version loads when members open the community.

### Workflow 3: Event-driven automation

1. Member performs action such as payment, RSVP, form submit, or comment.
2. Owning Loom service emits typed event.
3. Rule engine evaluates extension rules and starts workflow or job.
4. Workflow mutates platform services through contracts.
5. Audit, notifications, and receipts are emitted.

### Workflow 4: Update, rollback, uninstall, export

1. New package version is certified.
2. Owner is notified if permissions or risk tier changed.
3. App Shell loads latest approved version or stays pinned if policy requires.
4. Rollback disables incompatible rules/jobs.
5. Uninstall disables runtime, jobs, and rules; export remains available.

## 9. Cross-Area Requirements

- Extensions use Loom APIs only; no direct database, vault, payment, ad, or identity access.
- Every package must declare export behavior for custom schemas.
- Every package asset must be local, hashed, size-limited, format-limited, and declared in the package
  manifest before local-demo validation can pass.
- Community card branding is shell-rendered and follows the locked image priority above.
- Rules, workflows, jobs, and functions are versioned and auditable.
- Certification must test required App Shell structure and ad-surface invariants.
- Provider-neutral fakes must be available for all dependencies.

## 10. Prototype Implications

The MVP needs a package format, local validator, fake runtime bridge, extension registry, install grant,
card/route mounting, data schema store, rules, a basic workflow/job engine, test fixtures, and one
worked extension for each anchor vertical. Sandboxed functions can be limited to one or two certified
examples.

## 11. FAQ

**Is an extension a whole app?**
It is the custom experience inside the Main Loom App. It can feel like a vertical app, but it runs
through the App Shell and fixed Loom APIs.

**Can an extension choose not to support Messages or Connections?**
No. The App Shell owns required navigation; extensions can add vertical views but cannot remove them.

**Does an extension own its data?**
It owns schema and logic, but Loom stores, permissions, audits, and exports the records.

## 12. Open Questions

- How much WebView capability should MVP allow versus declarative cards?
- Which certification tier first permits sandboxed functions?
- How should paid extension marketplace flows be sequenced after MVP?
