# Phase A5 - API Review

Status: Completed in A5

## Scope

Extension engine APIs: runtime bridge, event bus use, rules, workflows, jobs, functions, data schemas,
secrets/connectors, extension package manifests, and initialization packages.

## Review Checklist

- Runtime session scope.
- Permission enforcement.
- Rule/action and workflow state-machine versioning.
- Job idempotency.
- Function sandbox limits.
- Schema export/index policy.
- Downloadable extension package shape.
- Locked package directory layout for `.loom-extension.zip`.
- Asset manifest fields, asset hashes, dimensions, allowed formats, file size limits, and alt/decorative metadata.
- Initialization package schema, idempotency key, import report, and rollback behavior.
- Locked package directory layout for `.loom-init.zip`.
- Community branding seed schema: logo, card image, hero image, accent color, fallback behavior.

## OpenAPI Outputs

Record extension-engine spec additions and gaps, including local package and initialization package
contracts used by B1a. Include package asset validation and initialization branding contracts.

## A5 Contract Additions

- `CommunityExtensionRuntimeApi`
- `CommunityRuleEngineApi`
- `CommunityWorkflowApi`
- `CommunityJobSchedulerApi`
- `CommunityFunctionRuntimeApi`
- `CommunityDataSchemaApi`
- `CommunitySecretsConnectorApi`
- `CommunityExtensionPackageApi`
- `CommunityInitializationPackageApi`

These contracts are currently implemented as typed Dart contracts in
`app/packages/core/loom_api_contracts/lib/clients/community_engine_apis.dart` and in-memory fakes in
`app/packages/core/loom_fake_backend/lib/community_engine_fake.dart`.

## Package Contracts

- `.loom-extension.zip` must include `loom.extension.json`, UI, assets, schemas, rules, workflows,
  jobs, docs, tests/fixtures, and signatures.
- `.loom-init.zip` must include `loom.initialization.json`, seed assets, fixtures, and an import plan.
- Asset manifests must include file path, hash, kind, dimensions, and alt/decorative metadata.
- Initialization packages must include handle, display name, logo, card image, hero image, accent
  color, and idempotency key.

## OpenAPI Follow-Ups

- Publish OpenAPI or JSON Schema specs for extension manifests, initialization packages, asset
  manifests, rule/workflow/job definitions, schema registration, connector secrets, and runtime session
  calls.
- Keep App Shell, Demo loader, and local in-app backend consumer contracts pending until A6/B1a.

## Validation Evidence

- `vt_extension-runtime_session`
- `vt_extension-runtime_bridge-call`
- `vt_extension-runtime_permission`
- `vt_rule-engine_evaluate`
- `vt_rule-engine_action`
- `vt_workflow-engine_start`
- `vt_workflow-engine_transition`
- `vt_job-scheduler_trigger`
- `vt_function-runtime_sandbox-permission`
- `vt_data-schema_register`
- `vt_data-schema_export-index`
- `vt_secrets-connector_scoped-secret`
- `vt_extension-package_downloadable-shape`
- `vt_extension-package_asset-manifest`
- `vt_extension-package_asset-policy`
- `vt_initialization-package_schema`
- `vt_initialization-package_idempotency`
- `vt_initialization-package_community-branding`

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
