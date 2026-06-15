# Invitation Service

Use `CommunityInvitationApi` to create and revoke community invitations. Invitations must respect the
Connections Graph so blocked paths cannot be used to bypass member controls.

## Extension Use

- Check invite creation results before presenting acceptance links.
- Revoke stale or mistaken invitations through Loom APIs.
- Treat blocked-path errors as final unless the member changes connection state.

## Validation

- `vt_invitation_create-revoke` proves invitation lifecycle.
- `ct_connections__invitation_blocked-path` is unblocked and passes in A2.
- `ct_invitation__membership_accept` passes in A2.
