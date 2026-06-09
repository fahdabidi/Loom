# Phase B1b - API Review

Status: Completed

## Scope

Hosted build, publish, discover, certify, and install workflow, validated through local registry,
certification, discovery, local backend, and App Shell fakes.

## Review Checklist

- Package manifest fields: `mode`, `publish.builderId`, `publish.signingScope`, `publish.packageId`,
  `publish.communityHandle`, and `publish.assetEvidencePresent`.
- App ID signing and artifact attestation: covered by `CommunityBuilderAppIdApi.registerBuilderApp`
  and `verifySigningScope`.
- Certification result and remediation shape: covered by `CommunityCertificationApi.validatePackage`.
- QR/handle payload: covered by `CommunityRegistryApi.resolveByHandleOrQr`.
- Latest certified version resolution: covered by `CommunityExtensionRegistryApi.resolveLatest`.
- Install grant and permission review: currently represented by package permissions plus local install
  import; future hosted OpenAPI should expose explicit install grants.
- Compatibility with B1a local package and initialization package contracts: B1b reuses the same
  local package/init package shape and adds publish metadata.

## OpenAPI Outputs

- `CommunityBuilderAppIdApi`, `CommunityCertificationApi`, `CommunityExtensionRegistryApi`,
  `CommunityRegistryApi`, and `CommunityPublicRegistryApi` cover the local hosted-publish stubs.
- Hosted OpenAPI still needs explicit endpoints for publish metadata upload, certification evidence
  upload, install grant acceptance, and latest-open route resolution.
- No external backend is required for the B1b gate; `wf_build-publish-discover-install` proves the
  local stub contract.

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
