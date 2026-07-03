# Messaging Stream Service

Use `CommunityMessagingApi` for direct/group messages and stream-ready message items. Extensions may
render message-derived surfaces through App Shell components later, but the service owns message data.

## Extension Use

- Send messages with idempotency keys.
- Use `renderStream` for display-ready stream items.
- Leave ad insertion to ad decision and stream renderer consumers.

## Validation

- `vt_messaging_stream-render` proves message-to-stream item projection.
- `vt_messaging_direct-group` proves threaded direct/group messages.
