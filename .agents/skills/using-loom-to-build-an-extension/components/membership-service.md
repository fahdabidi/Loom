# Membership Service

Use `CommunityMembershipApi` to request, approve, and inspect community membership state. Extensions
can initiate join workflows but Loom owns member state.

## Extension Use

- Call `requestJoin` when an owner-approved community requires membership review.
- Use `memberState` before showing member-only extension surfaces.
- Keep role/permission checks separate from membership existence.

## Validation

- `vt_membership_join-approval` proves request and approval transitions.
- `ct_invitation__membership_accept` and `ct_spaces__membership_space-join` pass in A2.
