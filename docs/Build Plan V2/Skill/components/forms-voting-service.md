# Forms Voting Service

Use `CommunityFormsVotingApi` for forms, sensitive field routing, and polls. Sensitive answers must be
routed into the protected vault, not stored in extension-visible answers.

## Extension Use

- Declare `sensitiveFields` before submitting forms.
- Store non-sensitive answers in form submissions.
- Use poll results for aggregate display only.

## Validation

- `vt_forms-voting_submit` proves protected-field routing.
- `vt_forms-voting_poll-results` proves aggregate poll counts.
- `ct_forms-voting__protected-vault_sensitive-fields` passes in A3.
