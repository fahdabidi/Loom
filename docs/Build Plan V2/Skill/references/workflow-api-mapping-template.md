# Workflow API Mapping Template

Use this template for each generated extension workflow.

## Workflow Summary

| Field | Value |
| --- | --- |
| Workflow ID | `<workflow-id>` |
| Persona | `<owner/member/admin/etc>` |
| Trigger | `<event/action>` |
| End state | `<validated end state>` |
| Functionality area | `<membership/events/payments/etc>` |

## Step Map

| Step | User/system action | Loom API | Extension schema | Rule/workflow/job/function | Event emitted/consumed | UI surface | Validation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `<action>` | `<Community*Api>` | `<schema or none>` | `<rule/job/etc>` | `<event or none>` | `<surface>` | `<test id>` |

## Permissions and Data

| Permission | Purpose | Fields | Data class | Consent | Retention/export |
| --- | --- | --- | --- | --- | --- |
| `<permission>` | `<purpose>` | `<fields>` | `<public/member/protected/payment>` | `<yes/no>` | `<policy>` |

## Validation Criteria

- Static package validation passes.
- Initialization package validation passes.
- Demo App Local Backend imports the workflow seed data.
- App Shell opens `local:<extension-id>@latest`.
- Every workflow-specific test passes.
- `validation-report.json` records `implemented=true`, `validated=true`, and `complete=true`.
