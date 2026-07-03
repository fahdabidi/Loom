# Function Runtime

Use `CommunityFunctionRuntimeApi` only when config, rules, workflows, and jobs are insufficient.

## Extension Use

- Declare requested permissions before invoking functions.
- Keep functions sandboxed and input/output bounded.
- Do not use functions to bypass Loom API contracts.

## Validation

- `vt_function-runtime_sandbox-permission` proves sandbox permission enforcement.
