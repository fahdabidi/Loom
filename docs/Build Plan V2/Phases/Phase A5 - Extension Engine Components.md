# Phase A5 - Extension Engine Components

Layer: extension engine
Components: Extension Runtime Bridge, Rule Engine, Workflow Engine, Job Scheduler, Sandboxed Function
Runtime, Data Schema Store, Secrets/Connector Broker.
Depends on: A4b
Parallelism: one agent per component
Gate: engine validation and provider/consumer contract tests pass

## 0. Prerequisite Gate

- A4b complete and committed.
- All service-layer tests are current.
- Engine dependencies have fakes and contract tests.

## 1. Components in This Phase

| Component | Architecture source | Contract |
| --- | --- | --- |
| extension-runtime-bridge | [Arch 08](../../Architecture%20V2/08-extension-platform-runtime.md) | `CommunityExtensionRuntimeApi` |
| rule-engine | [Arch 08](../../Architecture%20V2/08-extension-platform-runtime.md) | `CommunityRuleEngineApi` |
| workflow-engine | [Arch 08](../../Architecture%20V2/08-extension-platform-runtime.md) | `CommunityWorkflowApi` |
| job-scheduler | [Arch 08](../../Architecture%20V2/08-extension-platform-runtime.md) | `CommunityJobSchedulerApi` |
| function-runtime | [Arch 08](../../Architecture%20V2/08-extension-platform-runtime.md) | `CommunityFunctionRuntimeApi` |
| data-schema-store | [Arch 08](../../Architecture%20V2/08-extension-platform-runtime.md) | `CommunityDataSchemaApi` |
| secrets-connector-broker | [Arch 08](../../Architecture%20V2/08-extension-platform-runtime.md) | `CommunitySecretsConnectorApi` |

## 2. Agent Assignment and Parallelism

Run one agent per component. Merge order:

1. Extension Runtime Bridge.
2. Data Schema Store.
3. Rule Engine.
4. Workflow Engine.
5. Job Scheduler.
6. Function Runtime.
7. Secrets/Connector Broker.

## 3. Per-Component Build Spec

Engine components call service, registry, and foundation contracts through fakes. They do not own
service data. All extension actions route through the Runtime Bridge and effective permission checks.

## 4. Basic Validation Tests

Required:

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

## 5. Consumer-Contract Tests Authored for Dependents

Author and register:

- `ct_extension-runtime__app-shell_session`
- `ct_extension-runtime__protected-vault_write`
- `ct_rule-engine__extension-runtime_action-dispatch`
- `ct_workflow-engine__case-task_transition`
- `ct_job-scheduler__rule-engine_trigger`
- `ct_data-schema-store__import-export_schema-enumeration`
- `ct_data-schema-store__search_indexability`

## 6. Cross-Component Test Gate

Run all engine validation tests, all consumed provider tests from A1-A4b, all unblocked contract tests
for A6 consumers where possible, and manifest gate.

## 7. Tenet-Adherence Checks

Verify the engine layer calls downward only. Events trigger rules/workflows asynchronously. Runtime is
the only extension bridge into Loom service APIs.

## 8. Skill Contribution

Add guides for runtime, rules, workflows, jobs, functions, schemas, and secrets/connectors. These are
the most important "beyond OpenAPI" guides: include recipes for config -> rules -> workflows -> jobs ->
functions and when not to use functions.

## 9. Manifest Update

Stamp A5 tests and resolve pending counterpart tests involving engine consumers/providers.

## 10. API Review

Create `Phase A5 - API Review.md`. Record OpenAPI specs for runtime, event bus interactions, rules,
workflows, jobs, functions, schemas, and secrets/connectors.

## 11. Definition of Done

A5 tests, regressions, manifest, Skill guides, API Review, tracker, and commit SHA complete.

## 12. Next Phase

Proceed to [Phase A6 - UX Components.md](./Phase%20A6%20-%20UX%20Components.md).
