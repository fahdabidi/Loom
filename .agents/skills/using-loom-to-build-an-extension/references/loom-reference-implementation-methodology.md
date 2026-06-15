# Loom Reference Implementation Methodology

Use this reference when the Skill needs to learn from existing Loom workflows before designing a new
extension.

## What To Learn

For each relevant Loom reference workflow, extract:

- the product intent and target personas
- the workflow trigger and end state
- the Loom-owned APIs used
- extension-owned schemas, rules, workflows, jobs, and optional functions
- events emitted and consumed
- App Shell surfaces and UX constraints
- sensitive data, consent, payment, audit, export, and moderation boundaries
- the validation tests that prove the workflow
- the UX and architecture rationale behind the implementation

## How To Explain Existing Workflows

For every reference workflow used as precedent, write:

| Field | Guidance |
| --- | --- |
| Workflow | Name and ID of the existing Loom workflow. |
| Why this workflow exists | Product problem and persona need. |
| Implementation shape | APIs, rules, events, jobs, UI surfaces, and fake-backend seed data. |
| UX rationale | Decisions from UX Decisions docs and observed patterns. |
| Architecture rationale | Tenets, ownership boundaries, contracts, events, and tests. |
| Transferable pattern | What a new extension should copy. |
| Non-transferable constraint | What is Loom/platform-specific and should not be copied into extension-owned code. |

## Reference Priority

1. Skill component and workflow guides for concise usage rules.
2. Product Docs V2 and Architecture V2 for why the platform works this way.
3. API/OpenAPI specs and Dart contracts for exact payloads.
4. Demo App tests and workflow tests for validation behavior.
5. UX Decisions docs for research patterns and UI tradeoffs.

Do not modify Loom APIs while creating an extension. Use existing APIs and identify gaps as questions
or future platform requests.
