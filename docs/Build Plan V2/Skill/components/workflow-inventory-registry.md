# Workflow Inventory Registry

Use `CommunityWorkflowInventoryApi` to register workflow descriptors and map workflows to phases,
owners, and tests. This is the Skill's index for what must be validated.

## Extension Use

- Register workflow IDs before generating workflow-specific tests.
- Link workflow descriptors to owner components and test IDs.
- Query by phase when assembling validation plans.

## Validation

- `vt_workflow-inventory_test-index` proves phase-based workflow indexing.
