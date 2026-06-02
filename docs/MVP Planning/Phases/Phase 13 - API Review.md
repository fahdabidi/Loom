# Phase 13 - API Review

## Scope

Phase 13 implements creator-side launch measurement and utility consoles: aggregate conversion analytics, public catalog import, ad-policy verification, creator archive-AI preview, and membership setup.

## APIs Reviewed

- `AudienceAnalyticsApi.getConversionFunnel` returns aggregate-only launch conversion stages and source counts. UI shows no per-fan rows or universal fan IDs.
- `ImportPublicMetadataApi.startImport/getImportJob/listImportedReferences` runs an idempotent public-metadata import and keeps rights basis/provenance visible.
- `ExternalAccountLinkApi.listExternalAccounts` provides the verified public account used for import provenance.
- `CreatorMetadataApi.setCreatorAdPolicy` saves allow/block categories, formats, and surfaces; `AdDecisionApi.decideAds` verifies downstream policy consumption.
- `CreatorMetadataApi.defineMembershipTiers/updateMonetizationManifest` and `EntitlementLedgerApi.registerMembershipTierDefinitions` save tier drafts and entitlement definitions as one creator workflow.
- `AiGatewayApi.askArchive` powers the creator preview and returns cited answers plus receipts.

## Boundary Findings

- Creator utility screens remain in their owning feature packages and do not import other feature packages.
- Shared funnel/chart/archive widgets live in `loom_design_system` and use simple view models.
- Demo app navigation imports each feature at the app-shell level only.
- All fake calls continue to go through typed API interfaces backed by local Drift/SQLite.

## Validation Evidence

- Focused analyzes passed for `loom_design_system`, `feature_creator_audience`, `feature_creator_ads`, `feature_creator_ai`, `feature_creator_monetization`, `feature_creator_publishing`, and `loom_demo`.
- Focused API test passed: `flutter test test/p13_creator_utility_api_test.dart`.
- Phase 13 integration tests were added for conversion funnel, catalog import, ad policy, creator AI preview, and membership setup. Device execution is pending WSL `adb devices` visibility.
