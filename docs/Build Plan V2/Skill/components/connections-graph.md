# Connections Graph

Use `CommunityConnectionsApi` for member-to-member invitation and block state. Extensions can suggest
connection actions, but Loom owns the graph and block enforcement.

## Extension Use

- Ask `canInvite` before rendering invite actions.
- Treat blocked paths as terminal for extension-initiated invitations.
- Use the graph instead of building a separate contact list for Loom members.

## Validation

- `vt_connections_invite-permission` proves invitation and blocked-path behavior.
- `ct_connections__invitation_blocked-path` is pending until invitation service exists.
