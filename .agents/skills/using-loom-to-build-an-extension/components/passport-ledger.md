# Passport Ledger

Use `CommunityPassportApi` when an extension needs a stable Loom member identity. Extensions do not
create private identity stores; they ask Loom to create or resolve a passport and then store only their
own extension-scoped references.

## Extension Use

- Call `createPassport` only through Loom-owned onboarding or initialization flows.
- Use `resolvePassport` before writing member-scoped extension data.
- Treat `passportId` as the join key; never ask for login credentials or session tokens.

## Validation

- `vt_passport-ledger_create-resolve` proves idempotent create, resolve, versioning, and audit linkage.
