# Extension Runtime Bridge

Use `CommunityExtensionRuntimeApi` as the only bridge from extension code into Loom-owned APIs.

## Extension Use

- Start sessions with minimal requested permissions.
- Route API calls through the runtime bridge instead of importing service internals.
- Treat denied calls as validation failures in local-demo mode.

## Validation

- `vt_extension-runtime_session`, `vt_extension-runtime_bridge-call`, and `vt_extension-runtime_permission` prove session and permission behavior.
- `ct_role-policy__extension-runtime_effective-permission` proves role policy is the permission source.
