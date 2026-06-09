# Public Registry Read Model

Use `CommunityPublicRegistryApi` for public discovery projections. It exposes trust state and basic
community metadata without exposing private membership or extension internals.

## Extension Use

- Project certified community state after registry/certification changes.
- Display public trust state in discovery surfaces.
- Keep private owner/member data out of public entries.

## Validation

- `vt_public-registry_status` proves trust-state projection.
- `ct_public-registry__app-shell_trust-state` remains pending until App Shell exists.
