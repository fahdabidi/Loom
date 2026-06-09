# Build, Publish, Discover, Install

Mode: `real-backend-publish`, validated locally against the Demo Loom Communities App with Local
Backend and control-plane fakes.

## Purpose

Use this workflow when an owner wants an extension package that can later publish to a real Loom
Communities backend. The Skill still emits local downloadable artifacts, but the package must include
the fields required for builder signing, certification, registry publication, handle/QR discovery, and
latest-version install.

## Required Artifacts

- `loom.extension.json` with `mode: real-backend-publish`, permissions, asset manifest, and publish
  metadata.
- `loom.initialization.json` with local demo seed data so the same artifact can be validated without a
  hosted backend.
- Branding assets and evidence references for certification.
- Publish checklist: builder ID, signing scope, package ID, certification evidence, community handle,
  QR payload, and latest-open route.

## Implementation Steps

1. Build the same local package/init pair used by `local-demo`.
2. Add publish metadata: builder ID, signing scope, package ID, target community handle, and
   certification evidence.
3. Validate package and assets locally.
4. Register builder App ID and verify the signing scope through fakes.
5. Certify the package through the local certification fake.
6. Publish the certified version to the extension registry fake.
7. Resolve the community by handle and QR.
8. Import the init package into the local backend and open `local:<extensionId>@latest`.

## Validation

Primary workflow test: `wf_build-publish-discover-install`.

The test proves that real-backend publish mode can be validated without an external backend by using
the same package/init artifacts with local registry, certification, discovery, and App Shell fakes.

## Failure Ownership

- Package missing publish fields: `ai-skill-extension-builder`.
- Signing scope rejected: `builder-app-id-service`.
- Certification rejected: `certification-system`.
- Latest version unresolved: `extension-registry`.
- Handle or QR unresolved: `community-registry`.
- Install/open failure: `loom-communities-demo-app` or `app-shell-runtime`.
