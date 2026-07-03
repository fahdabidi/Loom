# Spaces Service

Use `CommunitySpacesApi` to model nested spaces inside a community. Extensions should attach routes,
forms, events, and documents to Loom spaces instead of inventing separate hierarchy tables.

## Extension Use

- Create root spaces first, then child spaces with `parentSpaceId`.
- Use `listSpaces` to populate navigation or scoped workflow targets.
- Do not use spaces for membership decisions; ask Membership and Role Policy.

## Validation

- `vt_spaces_nesting` proves parent/child space creation.
- `ct_spaces__membership_space-join` passes in A2.
