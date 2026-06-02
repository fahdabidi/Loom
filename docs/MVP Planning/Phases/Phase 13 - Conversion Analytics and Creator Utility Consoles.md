# Phase 13 — Conversion Analytics & Creator Utility Consoles

**Surface:** Creator Studio · **UX gate:** HIGH · **On green:** STOP for UX checkpoint, then AUTO → Phase 14
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 12. This phase completes creator-side launch measurement and
> single-player utility: conversion-yield analytics (**CE-S11**), catalog import UI, ad-policy console,
> creator-side archive-AI preview, and membership setup. It closes UX gaps **U5** and **U6**.

## 0. Prerequisite gate (validate Phase 12 done)
README gate + confirm capture links, starter packs, bulk-follow, and non-empty fan landing work on the emulator.
The conversion funnel must have real Phase 12 events to read.

## 1. Workflows & user stories in this phase
- **CE-S11 / conversion yield** — Creator sees audience reached → re-followed → member/premium as a
  compact visual funnel, with aggregate-only values.
- **CE-S2B / public catalog import** — Creator imports public metadata references and sees preview,
  validation, imported references, and provenance.
- **MISSING-S1 / creator ad-policy console** — Creator allows/blocks ad categories or brands; playback/ad
  decision consumes the latest version.
- **CE-W7 / creator-side archive-AI preview** — Creator can ask their own archive before fans arrive and see
  cited answers/source context.
- **MN-S* / membership setup console** — Creator edits membership tiers with preview, validation, and saved state.

## 2. Tools (WSL Ubuntu)
Standard set. No network. Any AI preview is fake/local through the existing AI Gateway fake.

## 2A. UX reference research & decision output
Before implementing this phase, review:
- YouTube Studio analytics: compact funnels/cards, audience/revenue summaries, and trend sparklines.
- Patreon insights and membership editors: tier cards, benefits, price validation, and preview states.
- YouTube Studio upload/import flows: multi-step import jobs, status, validation, and imported content preview.
- Creator ad/category controls from social/ads tools: category chips, allow/block lists, versioned save.
- Chat/search preview patterns for creator archive tools: question suggestions, cited answer cards, and source rows.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 13 specifics:
- Analytics must be aggregate-only and visually scannable: funnel card, mini bars, trend row, no per-fan rows.
- Import, ad policy, AI preview, and membership setup should be real Studio editors with preview + validation,
  not one-click success modules.
- Use sheets for long policy/provenance explanations; keep editors compact and repeatable.
- Save states must be clear and versioned where policy changes affect downstream playback/ads.
- Studio surfaces should feel consistent with Phase 11 Launch/Grow patterns.

Create [Phase 13 - UX Decisions.md](./Phase%2013%20-%20UX%20Decisions.md) with references, extracted
patterns, key UX/implementation decisions, and walkthroughs for analytics and each utility console.

## 3. APIs invoked & stubs to implement
Use Phase 10 typed clients and prior APIs:
- **Audience Analytics API:** conversion funnel and trend data.
- **Import Public Metadata API:** import job create/status/results.
- **Creator Metadata API:** ad policy, membership tiers, creator archive-AI permission.
- **Ad Decision API:** verify latest policy version is consumed downstream.
- **Premium No-Ad / Entitlement Ledger / Fan Wallet APIs:** premium/member counts for funnel.
- **AI Gateway API:** creator-side archive Q&A preview.
- **Content Host / Migration Export APIs:** imported references and export completeness regression where relevant.

## 4. Data storage (local store)
No new tables expected beyond Phase 10 unless Phase 13 finds a concrete gap. This phase writes:
- Public metadata import jobs/results.
- Ad-policy versions.
- Membership tier definitions.
- Creator-side AI preview usage/source-attribution receipts if the existing receipt model requires them.

Conversion analytics reads capture/follow/entitlement/premium state and should not persist per-fan analytics rows.

## 5. Source files & components to create/update
Design system:
- `core/loom_design_system/lib/components/studio/conversion_funnel_card.dart`
- `core/loom_design_system/lib/components/viz/funnel_chart.dart`
- `core/loom_design_system/lib/components/viz/mini_bar_chart.dart`
- Deepen existing or planned Studio components:
  - `studio/import_wizard.dart`
  - `studio/ad_policy_editor.dart`
  - `studio/monetization_editor.dart`
  - `studio/archive_ai_preview.dart`

Creator features:
- `feature_creator_revenue` or `feature_creator_audience`: add conversion-yield analytics screen/section.
- `feature_creator_publishing`: finish catalog import UI.
- `feature_creator_ads`: replace stub with ad-policy console.
- `feature_creator_ai`: replace stub with creator archive-AI preview.
- `feature_creator_monetization`: replace stub with membership tier setup.
- Update all touched `CHARTER.md` files.

## 6. API best-practice checks (phase-specific)
- Conversion funnel is aggregate-only and never exposes universal fan IDs or per-fan behavior.
- Import job is idempotent and paginated/bounded for imported references.
- Ad-policy edits are versioned and idempotent; ad decisions read the latest saved version.
- Membership tier saves are idempotent and validate price/name/benefit constraints.
- Creator AI preview produces cited answers and source attribution without bypassing archive policy.
- No screen over-fetches fields that are not displayed.

## 7. Component boundary / design checks
- Each creator feature remains isolated; no feature→feature imports.
- Shared charts/editors live in design system and do not import APIs.
- Feature view models map API DTOs to local display models.
- Stub packages become real feature packages with accurate charters.

## 8. Automated validation checks
README baseline plus:
- Unit tests for conversion-funnel aggregation and display model mapping.
- Widget tests for funnel/bar charts at phone widths.
- Unit/widget tests for import wizard states: idle, validating, importing, success, error.
- Unit tests for ad-policy versioning and playback/ad-decision policy consumption.
- Unit tests for membership editor validation and idempotent save.
- Unit tests for creator archive-AI preview permission and cited answer mapping.

## 9. Integration tests
- `it_p13_conversion_funnel` — After Phase 12 follows and a simulated purchase/premium event, creator sees
  reached → re-followed → member/premium aggregate funnel.
- `it_p13_catalog_import_console` — Creator imports public metadata references and sees imported provenance.
- `it_p13_ad_policy_console` — Creator blocks an ad category and fan playback/ad decision no longer serves it.
- `it_p13_creator_ai_preview` — Creator asks archive question and receives cited answer/source rows.
- `it_p13_membership_setup` — Creator creates/updates a tier and fan/member entitlement paths can read it.

## 10. Definition of done
Creator can measure launch conversion yield and use the catalog import, ad-policy, AI preview, and membership
consoles as real editors with preview and validation. UX gaps U5 and U6 are closed. All checks are green; debug APK
builds and launches on the emulator; [Phase 13 - API Review.md](./Phase%2013%20-%20API%20Review.md) and
[Phase 13 - UX Decisions.md](./Phase%2013%20-%20UX%20Decisions.md) are filed. Update the tracker with Phase 13
status, completion date, API review link/name, gate evidence, and commit SHA.

## 11. Next phase
After Phase 13 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 14 — UX Hardening and Physical Phone Validation.md](./Phase%2014%20-%20UX%20Hardening%20and%20Physical%20Phone%20Validation.md).**
