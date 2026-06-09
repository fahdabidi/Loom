# Phase A2 - API Review

Status: Completed in A2

## Scope

Registry/control-plane APIs: community registry, spaces, membership, invitation, extension registry,
certification, public registry, workflow inventory, test manifest bridge.

## Review Checklist

- Handle/QR resolution shape.
- Community profile and branding shape used by App Shell cards.
- Space hierarchy and membership state transitions.
- Certification status and risk tier shape.
- Latest-version and revocation behavior.
- Manifest bridge fields for test status and staleness.

## OpenAPI Outputs

Record registry/control-plane spec additions and gaps, including community branding fields and asset
references consumed by App Shell card rendering.

## A2 Contract Additions

- `CommunityWorkflowInventoryApi`
- `CommunityTestManifestApi`
- `CommunityRegistryApi`
- `CommunitySpacesApi`
- `CommunityMembershipApi`
- `CommunityInvitationApi`
- `CommunityCertificationApi`
- `CommunityExtensionRegistryApi`
- `CommunityPublicRegistryApi`

These contracts are currently implemented as typed Dart contracts in
`app/packages/core/loom_api_contracts/lib/clients/community_registry_apis.dart` and in-memory fakes in
`app/packages/core/loom_fake_backend/lib/community_registry_fake.dart`.

## OpenAPI Follow-Ups

- Add HTTP/OpenAPI specs for community handle/QR resolution, branding, space nesting, join approvals,
  invitations, certification decisions, extension latest resolution, public trust-state projection, and
  manifest staleness.
- Keep App Shell consumer tests pending until A6.
- Keep extension runtime consumer tests pending until A5.

## Validation Evidence

- `vt_workflow-inventory_test-index`
- `vt_test-manifest_staleness`
- `vt_community-registry_discovery`
- `vt_community-registry_branding`
- `vt_spaces_nesting`
- `vt_membership_join-approval`
- `vt_invitation_create-revoke`
- `vt_extension-registry_resolve-latest`
- `vt_certification_validate-package`
- `vt_certification_asset-evidence`
- `vt_public-registry_status`
- Built-counterpart contract tests for certification, community registry, invitations, spaces, and the
  A1 connections/builder App ID providers.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
