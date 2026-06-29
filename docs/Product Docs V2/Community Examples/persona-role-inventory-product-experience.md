# Persona Role Inventory Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | persona-role-inventory |
| Community type | Demo app role/state validation surface |
| Product promise | Let builders and reviewers inspect how Loom community roles change available actions, receiver states, disabled states, and hidden/unauthorized behavior. |
| Brand cues | Clear QA/review utility, neutral shell styling, role capability matrix. |
| What this must not feel like | A raw checklist of workflow IDs or implementation metadata with no user-facing role/state meaning. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Extension Builder | Reviews generated extension roles and states. | Verify every persona can see only the correct actions and receiver states. | Must not expose protected data while validating states. | Builder understands role capability coverage and can fix gaps. |
| Product Reviewer | Reviews production-readiness evidence. | Confirm screenshots cover actor, receiver, read-only, disabled, hidden, and unauthorized states. | Review should stay evidence-based and screenshot-backed. | Reviewer can judge whether persona UX coverage is complete. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Role inventory overview | Summarize personas and role capabilities. | Builder/reviewer | persona name, role, available actions, hidden/disabled states. | Inspect persona |
| Capability matrix | Show action/state coverage by persona. | Reviewer | allowed, disabled, hidden, unauthorized, receiver state. | Verify coverage |
| Evidence detail | Link role/state rows to screenshots. | Reviewer | screenshot IDs, workflow/persona row IDs, verdict. | Open evidence |

## 4. Home Screen Requirements

The first persona-role-inventory screen must behave like a QA/product review dashboard: it should make
role coverage, persona differences, and remaining gaps visible. It must not be a generic workflow list.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Persona role matrix | persona, role, allowed actions, disabled actions, hidden actions, receiver states | complete/incomplete/failing | inspect, filter, verify | workflow cards without role meaning |
| Evidence detail | screenshot, hash, state, verdict, required fix | pass/fail/needs evidence | open evidence, assign remediation | abstract validation row |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| persona-role-inventory | builder/reviewer | Persona role matrix | role names, allowed/disabled/hidden states, coverage verdict | App shell role policy, permission rules | B23/B25 |
| persona-aware-ux | builder/reviewer | Evidence detail | actor/receiver screenshots and state descriptions | Role/policy/consent engine | B23/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| persona-role-inventory | builder inspects capability map | reviewer reads coverage | read-only evidence detail | unavailable actions marked hidden/disabled | unauthorized states shown as denied without protected data |

## 8. Content And Seed Data Requirements

Use concrete persona labels, role descriptions, action names, capability states, evidence row IDs, and
status language. Avoid exposing private fields or replacing role meaning with test-only workflow labels.

## 9. Visual And Interaction Standard

Use a dense but readable review dashboard with role/state hierarchy, filters, and evidence links. Avoid
thin checklist pages, raw JSON labels, or repeated generic cards.

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical persona-role-inventory product experience. | Judge role matrix and evidence detail against this doc. | open |
