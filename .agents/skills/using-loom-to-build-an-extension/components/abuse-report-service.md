# Abuse Report Service

Use `CommunityAbuseReportApi` for member reports against content, messages, extensions, or users.

## Extension Use

- Treat report details as sensitive and audit them redacted.
- Create moderation cases from reports rather than mutating the reported content directly.
- Keep reporter identity scoped to trusted moderation views.

## Validation

- `vt_abuse-report_submit` proves redacted report audit behavior.
