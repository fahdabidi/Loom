# Notification Service

Use `CommunityNotificationApi` for deduped local notification delivery. Extensions submit notification
intent; Loom owns delivery state and channel policy.

## Extension Use

- Provide a stable `dedupeKey` for retries.
- Keep notification content concise and non-sensitive.
- Use workflow-engine delivery contracts when A5 is built.

## Validation

- `vt_notification_deliver` proves deduped delivery and list lookup.
