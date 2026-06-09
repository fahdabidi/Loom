# Incident Service

Use `CommunityIncidentApi` for severe trust, safety, availability, or extension-certification events.

## Extension Use

- Create incidents for high-severity events that need audit or certification review.
- Use `targetPackageId` when an extension package may need certification action.
- Subscribe to emitted incident events rather than calling certification internals.

## Validation

- `vt_incident_create` proves incident creation and certification action metadata.
- `ct_incident__certification_revoke` proves revocation intent is exposed by contract.
