# Event Bus

Use `CommunityEventBusApi` to publish typed events and replay them for downstream rules or workflows.
Extensions should prefer events over synchronous sibling-component calls.

## Extension Use

- Publish narrow events with a stable type, source component, subject ID, and string payload fields.
- Use replay only for deterministic rebuilds, rules, jobs, and workflow recovery.
- Keep payloads non-sensitive unless the event type is explicitly approved for protected data.

## Validation

- `vt_event-bus_publish` proves idempotent publish and typed replay.
- `ct_event-bus__rule-engine_publish-replay` is pending until the rule engine exists.
