# Phase B9 - API Review

## Scope

B9 closes the local-demo API gap where the loader accepted package paths but substituted a hardcoded
Book Club fixture during import. The Demo App must now call Local In-App Backend APIs that read the
selected local package pair and import the declared extension/community metadata.

## APIs Reviewed

| API or contract | Owner | B9 decision |
| --- | --- | --- |
| `LocalInAppBackend.validateLocalPackagePair` | local-in-app-backend | Keep suffix checks and add optional readable-file checks for real local installs. |
| `LocalInAppBackend.parseLocalPackagePair` | local-in-app-backend | New local-demo parser for selected package files; extracts extension summary, initialization summary, seed references, and branding. |
| `LocalInAppBackend.installLocalPackagePairFromFiles` | local-in-app-backend | New one-call path for Demo App local installs: validate, parse, load extension, import initialization package. |
| `LoomExtensionPackageSummary` | extension-package-validator | Consumed from selected package contents; required fields are `extensionId`, `displayName`, and `version`; permissions and assets are optional lists. |
| `LoomInitializationPackageSummary` | initialization-package-schema | Consumed from selected package contents; required fields are `communityId`, `communityName`, and matching `extensionId`; seed files and branding are optional. |
| Demo App Add Community loader | loom-communities-demo-app | Calls the file-backed backend API and surfaces validation/parse errors in the loader dialog. |

## Required Payload Fields

Extension package local-demo payload:

- `extensionId`
- `displayName`
- `version`
- `permissions`
- `assetIds` or `assets[].assetId`

Initialization package local-demo payload:

- `communityId`
- `communityName`
- `extensionId`
- `seedDataFiles`
- `cardAssetId` or `branding.cardAssetId`
- `logoAssetId` or `branding.logoAssetId`
- `heroImageAssetId` or `branding.heroImageAssetId`
- `accentColor` or `branding.accentColor`

## Validation Decisions

| Decision | Rationale | Covering test |
| --- | --- | --- |
| File suffix remains `.loom-extension.zip` and `.loom-init.zip`. | Keeps the package contract stable for both direct JSON test payloads and real zip packages. | `vt_fake-backend_local-package-pair-validation` |
| The local install path requires readable files. | The Demo App must fail on bad local paths instead of silently installing fixtures. | `vt_demo-app_local-loader-invalid-extension-error` |
| Extension and initialization `extensionId` must match. | Prevents loading one extension with another community's initialization payload. | `vt_fake-backend_parse-arbitrary-local-package-pair` |
| Branding imports from either top-level fields or `branding`. | Lets the Skill emit a clean initialization package while preserving earlier examples. | `vt_fake-backend_import-arbitrary-package-pair` |
| Zip manifest reading is supported. | Skill-generated local-demo zips can be loaded directly when they contain `loom.extension.json` or `loom.initialization.json`. | `vt_fake-backend_parse-arbitrary-zip-package-pair` |

## Open API Gaps

- Add checksum verification between package manifests and local asset files.
- Add package schema version enforcement and richer diagnostics for missing fields.
- Add source-map/debug artifact ingestion for Skill iteration runs.
