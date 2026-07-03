# Role Policy Consent Engine

Use `CommunityRolePolicyApi` to answer whether an actor can perform a Loom-controlled operation.
Extensions declare required permissions and ask Loom for decisions; they do not interpret membership
roles directly.

## Extension Use

- Request the narrowest permission needed for a feature.
- Check `effectivePermission` before reading protected data or invoking restricted workflows.
- Record permission purpose in extension docs and initialization plans.

## Validation

- `vt_role-policy_effective-permission` proves grants produce deterministic permission decisions.
- `ct_role-policy__extension-runtime_effective-permission` is pending until the runtime exists.
