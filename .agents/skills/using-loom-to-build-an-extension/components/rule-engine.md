# Rule Engine

Use `CommunityRuleEngineApi` for declarative if-this-then-that extension behavior.

## Extension Use

- Prefer rules before jobs or functions.
- Keep actions explicit and route service calls through the runtime bridge.
- Trigger workflows asynchronously from events.

## Validation

- `vt_rule-engine_evaluate` and `vt_rule-engine_action` prove rule matching and action dispatch.
- `ct_event-bus__rule-engine_publish-replay` proves event-driven rule inputs.
