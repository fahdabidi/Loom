# Publishing Service

Use `CommunityPublishingApi` for community posts and announcements. Publishing depends on Loom role
policy and emits events for downstream search, stream rendering, and workflows.

## Extension Use

- Check `content.publish` through Loom policy before publishing.
- Choose `public` or `members` visibility deliberately.
- Use emitted post events instead of calling sibling services directly.

## Validation

- `vt_publishing_publish` proves permission-gated publish and event emission.
- `vt_publishing_visibility` proves member-only filtering.
