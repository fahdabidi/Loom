# Moderation Case Service

Use `CommunityModerationApi` for policy-versioned safety review queues.

## Extension Use

- Attach the policy version used for the decision.
- Use transitions to escalate, resolve, or defer a case.
- Let incident creation handle certification impact for severe cases.

## Validation

- `vt_moderation_case-lifecycle` proves open and transition behavior.
